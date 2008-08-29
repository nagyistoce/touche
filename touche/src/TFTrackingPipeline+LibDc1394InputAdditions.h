//
//  TFTrackingPipeline+LibDc1394InputAdditions.h
//  Touché
//
//  Created by Georg Kaindl on 15/5/08.
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

#import <Cocoa/Cocoa.h>

#import "TFTrackingPipeline.h"

extern NSString* libDc1394CameraUniqueIdPrefKey;
extern NSString* libdc1394CaptureCameraResolutionPrefKey;

@interface TFTrackingPipeline (LibDc1394InputAdditions)

- (BOOL)libdc1394FeatureSupportsAutoMode:(NSInteger)feature;
- (BOOL)libDc1394FeatureInAutoMode:(NSInteger)feature;
- (void)setLibDc1394Feature:(NSInteger)feature toAutoMode:(BOOL)val;
- (BOOL)libDc1394FeatureIsMutable:(NSInteger)feature;
- (float)valueForLibDc1394Feature:(NSInteger)feature;
- (void)setLibDc1394Feature:(NSInteger)feature toValue:(float)val;
- (NSNumber*)currentPreferencesLibDc1394CameraUUID;
- (NSNumber*)_defaultLibDc1394CameraUniqueID;
- (BOOL)libdc1394CameraConnectedWithGUID:(NSNumber*)guid;
- (CGSize)_defaultResolutionForLibDc1394CameraWithUniqueId:(NSNumber*)uid;
- (BOOL)_libDc1394CameraWithUniqueId:(NSNumber*)uid supportsResolution:(CGSize)resolution;
- (BOOL)_changeLibDc1394CameraToCameraWithUniqueId:(NSNumber*)uniqueId error:(NSError**)error;

@end