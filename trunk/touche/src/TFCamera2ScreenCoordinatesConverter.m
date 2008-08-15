//
//  TFCamera2ScreenCoordinatesConverter.m
//  Touché
//
//  Created by Georg Kaindl on 28/12/07.
//
//  Copyright (C) 2007 Georg Kaindl
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

#import "TFCamera2ScreenCoordinatesConverter.h"

#import "TFIncludes.h"
#import "TFBlob.h"
#import "TFBlobPoint.h"
#import "TFBlobSize.h"
#import "TFBlobBox.h"

@interface TFCamera2ScreenCoordinatesConverter (NonPublicMethods)
- (void)_recordError:(NSError*)error intoArrayAt:(NSMutableArray**)array;
@end

@implementation TFCamera2ScreenCoordinatesConverter

@synthesize delegate;
@synthesize screenWidth;
@synthesize screenHeight;
@synthesize cameraWidth;
@synthesize cameraHeight;
@synthesize transformsBoundingBox;
@synthesize transformsEdgeVertices;

- (void)dealloc
{
	[super dealloc];
}

- (id)init
{
	return [self initWithScreenSize:CGSizeMake(0, 0) andCameraSize:CGSizeMake(0, 0)];
}

- (id)initWithScreenSize:(CGSize)screenSize andCameraSize:(CGSize)cameraSize
{
	if (!(self = [super init])) {
		[self release];
		return nil;
	}
	
	self.delegate = nil;
	
	self.screenWidth = screenSize.width;
	self.screenHeight = screenSize.height;
	
	self.cameraWidth = cameraSize.width;
	self.cameraHeight = cameraSize.height;
	
	self.transformsBoundingBox	= NO;
	self.transformsEdgeVertices	= NO;
	
	return self;
}

- (BOOL)transformPointFromCameraToScreen:(TFBlobPoint*)point error:(NSError**)error
{
	TFThrowMethodNotImplementedException();
	
	if (NULL != error)
		*error = nil;
		
	return NO;
}

- (BOOL)isCalibrated
{
	TFThrowMethodNotImplementedException();
	
	return NO;
}

- (NSArray*)screenPointsForCalibration
{
	TFThrowMethodNotImplementedException();
	
	return nil;
}

- (BOOL)calibrateWithPoints:(NSArray*)points errors:(NSArray**)errors
{
	TFThrowMethodNotImplementedException();
	
	if (NULL != errors)
		*errors = nil;
	
	return NO;
}

- (NSData*)specificSerializedCalibrationData
{	
	return nil;
}

- (BOOL)loadSpecificSerializedCalibrationData:(NSData*)calibrationData error:(NSError**)error
{	
	return YES;
}

- (NSData*)serializedCalibrationData
{
	NSData* specificData = [self specificSerializedCalibrationData];
	
	return [NSArchiver archivedDataWithRootObject:[NSArray arrayWithObjects:
												   [NSNumber numberWithFloat:screenWidth],
												   [NSNumber numberWithFloat:screenHeight],
												   [NSNumber numberWithFloat:cameraWidth],
												   [NSNumber numberWithFloat:cameraHeight],
												   specificData,
												  nil]];
}

- (BOOL)shouldLoadScreenAndCameraDimensionsFromSerializedData
{
	return YES;
}

- (BOOL)loadSerializedCalibrationData:(NSData*)calibrationData error:(NSError**)error
{
	NSError* invalidCalibrationError =
			[NSError errorWithDomain:TFErrorDomain
								code:TFErrorCam2ScreenInvalidCalibrationData
							userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
									  TFLocalizedString(@"TFCam2ScreenInvalidCalibrationDataErrorDesc", @"TFCam2ScreenInvalidCalibrationDataErrorDesc"),
										NSLocalizedDescriptionKey,
									  TFLocalizedString(@"TFCam2ScreenInvalidCalibrationDataErrorReason", @"TFCam2ScreenInvalidCalibrationDataErrorReason"),
										NSLocalizedFailureReasonErrorKey,
									  TFLocalizedString(@"TFCam2ScreenInvalidCalibrationDataErrorRecovery", @"TFCam2ScreenInvalidCalibrationDataErrorRecovery"),
										NSLocalizedRecoverySuggestionErrorKey,
									  [NSNumber numberWithInteger:NSUTF8StringEncoding],
										NSStringEncodingErrorKey,
									  nil]];

	BOOL specificDataLoadedSuccessfully = YES;
	NSArray* unarchivedData = [NSUnarchiver unarchiveObjectWithData:calibrationData];
	
	if (![unarchivedData isKindOfClass:[NSArray class]]) {
		if (NULL != error)
			*error = invalidCalibrationError;
			
		return NO;
	}
	
	NSArray* arrayData = (NSArray*)unarchivedData;
	
	if ([arrayData count] < 4 || [arrayData count] > 5) {
		if (NULL != error)
			*error = invalidCalibrationError;

		return NO;
	}
	
	if ([self shouldLoadScreenAndCameraDimensionsFromSerializedData]) {
		// this should probably be error checked, too, but whatever...
		screenWidth = [[arrayData objectAtIndex:0] floatValue];
		screenHeight = [[arrayData objectAtIndex:1] floatValue];
		cameraWidth = [[arrayData objectAtIndex:2] floatValue];
		cameraHeight = [[arrayData objectAtIndex:3] floatValue];
	}

	if ([arrayData count] > 4) {
		id specificData = [arrayData objectAtIndex:4];
		
		if (![specificData isKindOfClass:[NSData class]]) {
			if (NULL != error)
				*error = invalidCalibrationError;

			return NO;
		}
		
		specificDataLoadedSuccessfully = [self loadSpecificSerializedCalibrationData:(NSData*)specificData error:error];
	}
	
	return specificDataLoadedSuccessfully;
}

- (BOOL)transformBlobsFromCameraToScreen:(NSArray*)blobs errors:(NSArray**)errors
{
	NSError* error;
	NSMutableArray* errCollection = nil;

	for (TFBlob* blob in blobs) {
		if (![self transformPointFromCameraToScreen:blob.center error:&error])
			[self _recordError:error intoArrayAt:&errCollection];
		
		if (![self transformPointFromCameraToScreen:blob.previousCenter error:&error])
			[self _recordError:error intoArrayAt:&errCollection];
		
		if (transformsBoundingBox) {
			TFBlobPoint* topLeftCorner = blob.boundingBox.origin;
			TFBlobPoint* bottomRightCorner =
				[TFBlobPoint pointWithX:blob.boundingBox.origin.x + blob.boundingBox.size.width
									  Y:blob.boundingBox.origin.y + blob.boundingBox.size.height];
			
			if (![self transformPointFromCameraToScreen:topLeftCorner error:&error])
				[self _recordError:error intoArrayAt:&errCollection];
			
			if (![self transformPointFromCameraToScreen:bottomRightCorner error:&error])
				[self _recordError:error intoArrayAt:&errCollection];
			
			// we need to look at the transformed positions of the two points defining the transformed
			// bounding box in order to compute the correct dimensions for the transformed box
			float minX = MIN(topLeftCorner.x, bottomRightCorner.x);
			float maxX = MAX(topLeftCorner.x, bottomRightCorner.x);
			float minY = MIN(topLeftCorner.y, bottomRightCorner.y);
			float maxY = MAX(topLeftCorner.y, bottomRightCorner.y);
			
			blob.boundingBox.origin.x = minX;
			blob.boundingBox.origin.y = minY;
			blob.boundingBox.size.width = maxX-minX;
			blob.boundingBox.size.height = maxY-minY;
		}
		
		if (transformsEdgeVertices) {
			for (TFBlobPoint* p in blob.edgeVertices)
				if (![self transformPointFromCameraToScreen:p error:&error])
					[self _recordError:error intoArrayAt:&errCollection];
		}
	}
	
	if (NULL != errors) {
		if (nil != errCollection)
			*errors = [NSArray arrayWithArray:errCollection];
		else
			*errors = nil;
	}
	
	return (nil == errCollection);
}

- (void)_recordError:(NSError*)error intoArrayAt:(NSMutableArray**)array
{
	if (nil == *array)
		*array = [NSMutableArray array];
	
	if (nil != error)
		[*array addObject:error];
}

@end
