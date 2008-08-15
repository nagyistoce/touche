//
//  TFZoomPinchRecognizer.m
//  Touché
//
//  Created by Georg Kaindl on 24/5/08.
//
//  Copyright (C) 2008 Georg Kaindl
//
//  This file is part of Touché.
//
//  Touché is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as
//  published by the Free Software Foundation, either version 3 of
//  the License, or (at your option) any later version.
//
//  Touché is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public
//  License along with Touché. If not, see <http://www.gnu.org/licenses/>.
//
//

#import "TFZoomPinchRecognizer.h"

#import <Accelerate/Accelerate.h>

#import "TFIncludes.h"
#import "TFCombinadicIndices.h"
#import "TFGeometry.h"
#import "TFLabeledTouchSet.h"
#import "TFGestureInfo.h"
#import "TFAlignedMalloc.h"
#import "TFBlob.h"
#import "TFBlobPoint.h"

#define	DEFAULT_ANGLE_TOLERANCE		(pi/4.0f)
#define DEFAULT_MIN_DISTANCE		(10.0f)

NSString* TFZoomPinchRecognizerParamPixels = @"TFZoomPinchRecognizerParamPixels";
NSString* TFZoomPinchRecognizerParamAngle = @"TFZoomPinchRecognizerParamAngle";

@implementation TFZoomPinchRecognizer

@synthesize angleTolerance;
@synthesize minDistance;

- (id)init {
	if (!(self = [super init])) {
		[self release];
		return nil;
	}
	
	angleTolerance = DEFAULT_ANGLE_TOLERANCE;
	minDistance = DEFAULT_MIN_DISTANCE;
	
	return self;
}

- (BOOL)wantsUpdatedTouches
{
	return YES;
}

- (void)processUpdatedTouches:(NSSet*)touches
{
	[self clearRecognizedGestures];
	
	NSUInteger numTouches = [touches count];
	
	if (numTouches <= 1)
		return;
	
	NSArray* touchArray = [touches allObjects];
	TFCombinadicIndices* indices = [TFCombinadicIndices combinadicWithElementsToSelect:2 fromSetWithPower:numTouches];
	
	int i;
	NSUInteger lengths[7];
	lengths[0] = [indices numCombinations];
	for (i=1; i<7; i++)
		lengths[i] = lengths[i-1] + lengths[0];
	
	float* A = (float*)[TFAlignedMalloc malloc:(sizeof(float)*8*lengths[0]) alignedAtMultipleOf:16];
	
	if (NULL == A)
		return;
	
	const NSUInteger* ind = NULL;
	for (i=0; (NULL != (ind = [indices nextCombination])); i++) {
		TFBlob* t1 = (TFBlob*)[touchArray objectAtIndex:ind[0]];
		TFBlob* t2 = (TFBlob*)[touchArray objectAtIndex:ind[1]];
		
		A[i] = t1.center.x - t1.previousCenter.x;
		A[i+lengths[0]] = t1.center.y - t1.previousCenter.y;
		A[i+lengths[1]] = t2.center.x - t2.previousCenter.x;
		A[i+lengths[2]] = t2.center.y - t2.previousCenter.y;
	}
	
	// compute vector magnitudes (first the t1's, then the t2's)
	vDSP_vdist(A, 1,
			   &A[lengths[0]], 1,
			   &A[lengths[3]], 1,
			   lengths[0]);
	vDSP_vdist(&A[lengths[1]], 1,
			   &A[lengths[2]], 1,
			   &A[lengths[4]], 1,
			   lengths[0]);
	
	// normalize the vectors by dividing the x and y components by the magnitudes
	vDSP_vdiv(&A[lengths[3]], 1,
			  A, 1,
			  &A[lengths[5]], 1,
			  lengths[0]);
	vDSP_vdiv(&A[lengths[3]], 1,
			  &A[lengths[0]], 1,
			  &A[lengths[6]], 1,
			  lengths[0]);
	vDSP_vdiv(&A[lengths[4]], 1,
			  &A[lengths[1]], 1,
			  A, 1,
			  lengths[0]);
	vDSP_vdiv(&A[lengths[4]], 1,
			  &A[lengths[2]], 1,
			  &A[lengths[0]], 1,
			  lengths[0]);
	
	// compute the scalar products
	vDSP_vmma(&A[lengths[5]], 1,
			  A, 1,
			  &A[lengths[6]], 1,
			  &A[lengths[0]], 1,
			  &A[lengths[1]], 1,
			  lengths[0]);
	
	vFloat* dotProducts = (vFloat*)[TFAlignedMalloc closestLowerAddressRelativeTo:&A[lengths[1]]
														 beingAlignedAtMultipleOf:16];
	for (i=0; i<MAX(2, (lengths[0]+4)/4); i++)
		dotProducts[i] = vacosf(dotProducts[i]);
		
	[indices reset];
	float* angles = &A[lengths[1]];
	for (i=0; (NULL != (ind = [indices nextCombination])); i++) {	
		if ((pi - angles[i]) > angleTolerance)
			continue;
	
		TFBlob* t1 = (TFBlob*)[touchArray objectAtIndex:ind[0]];
		TFBlob* t2 = (TFBlob*)[touchArray objectAtIndex:ind[1]];
		
		CGFloat distPrevious = [TFGeometry distanceBetweenPoint:CGPointMake(t1.previousCenter.x, t1.previousCenter.y)
													   andPoint:CGPointMake(t2.previousCenter.x, t2.previousCenter.y)];
		CGFloat distNow = [TFGeometry distanceBetweenPoint:CGPointMake(t1.center.x, t1.center.y)
												  andPoint:CGPointMake(t2.center.x, t2.center.y)];
		
		CGFloat distDist = distNow - distPrevious;
		
		if (ABS(distDist) < minDistance)
			continue;
				
		TFGestureInfo* info = [TFGestureInfo infoWithType:TFGestureTypeZoomPinch];
		info.subtype = (distDist < 0) ? TFGestureSubtypePinch : TFGestureSubtypeZoom;
		info.userInfo = self.userInfo;
		info.parameters = [NSDictionary dictionaryWithObjectsAndKeys:
						   [NSNumber numberWithFloat:ABS(distDist)], TFZoomPinchRecognizerParamPixels,
						   [NSNumber numberWithFloat:angles[i]], TFZoomPinchRecognizerParamAngle,
						   nil];
		
		TFLabeledTouchSet* set = [TFLabeledTouchSet setWithSet:[NSSet setWithObjects:t1, t2, nil]];
		[_recognizedGestures setObject:info forKey:set];
	}
	
	[TFAlignedMalloc free:A];	
}


@end
