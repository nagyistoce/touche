//
//  TFCamera2ScreenCoordinatesConverter.h
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

#import <Cocoa/Cocoa.h>

@class TFBlobPoint;
@class TFCalibrationPoint;

@interface TFCamera2ScreenCoordinatesConverter : NSObject {
	float		screenWidth, screenHeight;
	float		cameraWidth, cameraHeight;
	
	id			delegate;
	
	BOOL		transformsBoundingBox;
	BOOL		transformsEdgeVertices;
}

@property (assign) id delegate;
@property (assign) float screenWidth;
@property (assign) float screenHeight;
@property (assign) float cameraWidth;
@property (assign) float cameraHeight;
@property (assign) BOOL transformsBoundingBox;
@property (assign) BOOL transformsEdgeVertices;

- (id)initWithScreenSize:(CGSize)screenSize andCameraSize:(CGSize)cameraSize;
- (BOOL)transformBlobsFromCameraToScreen:(NSArray*)blobs errors:(NSArray**)errors;
- (BOOL)isCalibrated;
- (NSData*)serializedCalibrationData;
- (BOOL)loadSerializedCalibrationData:(NSData*)calibrationData error:(NSError**)error;

// implement these in subclasses
- (BOOL)shouldLoadScreenAndCameraDimensionsFromSerializedData;
- (NSArray*)screenPointsForCalibration;
- (BOOL)calibrateWithPoints:(NSArray*)points errors:(NSArray**)errors;
- (NSData*)specificSerializedCalibrationData;
- (BOOL)loadSpecificSerializedCalibrationData:(NSData*)calibrationData error:(NSError**)error;
- (BOOL)transformPointFromCameraToScreen:(TFBlobPoint*)point error:(NSError**)error;

@end

@interface NSObject (TFCamera2ScreenCoordinatesConverterDelegate)
- (void)calibrationDidBecomeNecessary;
@end
