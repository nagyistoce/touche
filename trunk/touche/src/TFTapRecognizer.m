//
//  TFTapRecognizer.m
//  Touche
//
//  Created by Georg Kaindl on 2/6/08.
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

#import "TFTapRecognizer.h"

#import <Accelerate/Accelerate.h>

#import "TFIncludes.h"
#import "TFBlob.h"
#import "TFBlobPoint.h"
#import "TFGestureInfo.h"
#import "TFLabeledTouchSet.h"
#import "TFTouchLabelObjectAssociator.h"
#import "TFAlignedMalloc.h"
#import "TFGestureConstants.h"

#define	DEFAULT_MAX_TAP_TIME		((NSTimeInterval)1.0)
#define DEFAULT_MAX_TAP_DISTANCE	(50.0f)

NSString* TFTapRecognizerParamTapCount	= @"TFTapRecognizerParamTapCount";

@interface TFTapRecognizer (PrivateMethods)
- (TFGestureInfo*)_touchDownWithTapCount:(NSNumber*)tapCount;
- (void)_removeTimedOutTaps;
@end

@implementation TFTapRecognizer

@synthesize maxTapTime;
@synthesize maxTapDistance;

- (void)dealloc
{
	[_touchesToTaps release];
	_touchesToTaps = nil;
	
	[_labelTapCounts release];
	_labelTapCounts = nil;
	
	[super dealloc];
}

- (id)init
{
	if (!(self = [super init])) {
		[self release];
		
		return nil;
	}
	
	_touchesToTaps = [[NSMutableDictionary alloc] init];
	_labelTapCounts = [[TFTouchLabelObjectAssociator alloc] init];
	
	maxTapTime = DEFAULT_MAX_TAP_TIME;
	maxTapDistance = DEFAULT_MAX_TAP_DISTANCE;
	
	return self;
}

- (BOOL)wantsNewTouches
{
	return YES;
}

- (BOOL)wantsEndedTouches
{
	return YES;
}

- (BOOL)tracksOverMultipleFrames
{
	return YES;
}

- (void)processNewTouches:(NSSet*)touches
{
	[self _removeTimedOutTaps];
	[self clearRecognizedGesturesOfType:TFGestureTypeTap andSubtype:TFGestureSubtypeTapDown];
	
	NSArray*	blobs				= [touches allObjects];
	NSArray*	previousBlobs		= [_touchesToTaps allKeys];
	NSUInteger	numBlobs			= [touches count];
	NSUInteger	numOldBlobs			= [previousBlobs count];
	NSUInteger	numCombinations		= numBlobs * numOldBlobs;
	NSUInteger	twoNumCombinations	= (numCombinations << 1);
	NSUInteger	threeNumCombinations = (numCombinations * 3);
	NSUInteger	fourNumCombinations	= (twoNumCombinations << 1);
		
	float* A = [TFAlignedMalloc malloc:(sizeof(float)*twoNumCombinations*3)
				   alignedAtMultipleOf:16];
	vDSP_Length* IC = [TFAlignedMalloc malloc:(sizeof(vDSP_Length)*twoNumCombinations)
						  alignedAtMultipleOf:16];
	
	if (NULL == A)
		return;
	
	NSUInteger i;
	for (i=0; i<numCombinations; i++) {
		A[i] = ((TFBlob*)[previousBlobs objectAtIndex:i%numOldBlobs]).center.x;
		A[twoNumCombinations+i] = ((TFBlob*)[blobs objectAtIndex:i/numOldBlobs]).center.x;
		A[i+numCombinations] = ((TFBlob*)[previousBlobs objectAtIndex:i%numOldBlobs]).center.y;
		A[threeNumCombinations+i] = ((TFBlob*)[blobs objectAtIndex:i/numOldBlobs]).center.y;
		IC[i] = i;
	}
	
	vDSP_vpythg(A, 1,
				A+numCombinations, 1,
				A+twoNumCombinations, 1,
				A+threeNumCombinations, 1,
				A+fourNumCombinations, 1,
				numCombinations);
	
	vDSP_vsorti(A+fourNumCombinations, IC, NULL, numCombinations, 1);
	
	BOOL oldBlobMatched[numOldBlobs], newBlobMatched[numBlobs];
	memset(oldBlobMatched, (char)NO, sizeof(BOOL)*numOldBlobs);
	memset(newBlobMatched, (char)NO, sizeof(BOOL)*numBlobs);
		
	for (i=0; i<numCombinations; i++) {
		NSInteger curOldIndex	= IC[i]%numOldBlobs;
		NSInteger curIndex		= IC[i]/numOldBlobs;
		
		if (oldBlobMatched[curOldIndex] || newBlobMatched[curIndex] || *(A+fourNumCombinations+IC[i]) > maxTapDistance)
			continue;
		
		TFBlob* oldBlob = [previousBlobs objectAtIndex:curOldIndex];
		TFBlob* newBlob = [blobs objectAtIndex:curIndex];
	
		NSUInteger tapCount = [[_touchesToTaps objectForKey:oldBlob] unsignedIntValue] + 1;
		[_touchesToTaps removeObjectForKey:oldBlob];
			
		oldBlobMatched[curOldIndex] = YES;
		newBlobMatched[curIndex] = YES;

		NSNumber* tapCountNumber = [NSNumber numberWithUnsignedInt:tapCount];
		
		TFGestureInfo* info = [self _touchDownWithTapCount:tapCountNumber];
		TFLabeledTouchSet* set = [TFLabeledTouchSet setWithSet:[NSSet setWithObject:newBlob]];
		[_recognizedGestures setObject:info forKey:set];
		
		[_labelTapCounts setObject:tapCountNumber forLabel:newBlob.label];
	}

	NSNumber* oneTapCount = [NSNumber numberWithUnsignedInt:1];
	for (i=0; i<numBlobs; i++) {
		if (newBlobMatched[i])
			continue;
		
		TFBlob* blob = [blobs objectAtIndex:i];
		TFGestureInfo* info = [self _touchDownWithTapCount:oneTapCount];
		TFLabeledTouchSet* set = [TFLabeledTouchSet setWithSet:[NSSet setWithObject:blob]];
		[_recognizedGestures setObject:info forKey:set];
		
		[_labelTapCounts setObject:oneTapCount forLabel:blob.label];
	}
		
	[TFAlignedMalloc free:A];
	[TFAlignedMalloc free:IC];
}

- (void)processEndedTouches:(NSSet*)touches
{
	[self clearRecognizedGesturesOfType:TFGestureTypeTap andSubtype:TFGestureSubtypeTapUp];
	
	NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
	
	for (TFBlob* touch in touches) {
		NSNumber* tapCount = [[_labelTapCounts objectForLabel:touch.label] retain];
		
		if (nil == tapCount || (now - touch.trackedSince) > maxTapTime) {
			[tapCount release];
			continue;
		}

		TFGestureInfo* info = [TFGestureInfo infoWithType:TFGestureTypeTap];
		info.subtype = TFGestureSubtypeTapUp;
		info.userInfo = self.userInfo;
		info.parameters = [NSDictionary dictionaryWithObjectsAndKeys:
						   tapCount, TFTapRecognizerParamTapCount,
						   nil];
		
		TFLabeledTouchSet* set = [TFLabeledTouchSet setWithSet:[NSSet setWithObject:touch]];
		[_recognizedGestures setObject:info forKey:set];
	
		[_touchesToTaps setObject:tapCount forKey:touch];
		[tapCount release];
	}
}

- (NSInteger)tapCountForLabel:(TFBlobLabel*)label
{
	NSNumber* tapCount = [_labelTapCounts objectForLabel:label];
	
	if (nil == tapCount)
		return -1;
	
	return [tapCount integerValue];
}

- (void)_removeTimedOutTaps
{
	NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];

	for (TFBlob* touch in [_touchesToTaps allKeys]) {
		if (now - touch.trackedSince > maxTapTime)
			[_touchesToTaps removeObjectForKey:touch];
	}
}

- (TFGestureInfo*)_touchDownWithTapCount:(NSNumber*)tapCount
{
	TFGestureInfo* info = [TFGestureInfo infoWithType:TFGestureTypeTap];
	info.subtype = TFGestureSubtypeTapDown;
	info.userInfo = self.userInfo;
	info.parameters = [NSDictionary dictionaryWithObjectsAndKeys:
					   tapCount, TFTapRecognizerParamTapCount,
					   nil];
	
	return info;
}

@end
