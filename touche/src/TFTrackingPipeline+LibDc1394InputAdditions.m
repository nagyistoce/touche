//
//  TFTrackingPipeline+LibDc1394InputAdditions.m
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

#import "TFTrackingPipeline+LibDc1394InputAdditions.h"

#import "TFIncludes.h"
#import "TFLibDC1394Capture.h"
#import "TFBlobLibDc1394InputSource.h"

NSString* TFLibDc1394CameraDidChangeNotification = @"TFLibDc1394CameraDidChangeNotification";

NSString* libDc1394CameraUniqueIdPrefKey = @"libDc1394CameraUniqueIdPrefKey";
NSString* libdc1394CaptureCameraResolutionPrefKey = @"libdc1394CaptureCameraResolutionPrefKey";

@implementation TFTrackingPipeline (LibDc1394InputAdditions)

- (NSNumber*)_defaultLibDc1394CameraUniqueID
{
	return [TFLibDC1394Capture defaultCameraUniqueId];
}

- (BOOL)libdc1394CameraConnectedWithGUID:(NSNumber*)guid
{
	return [TFLibDC1394Capture cameraConnectedWithGUID:guid];
}

- (CGSize)_defaultResolutionForLibDc1394CameraWithUniqueId:(NSNumber*)uid
{
	return [TFLibDC1394Capture defaultResolutionForCameraWithUniqueId:uid];
}

- (BOOL)_libDc1394CameraWithUniqueId:(NSNumber*)uid supportsResolution:(CGSize)resolution
{
	return [TFLibDC1394Capture cameraWithUniqueId:uid supportsResolution:resolution];
}

- (NSNumber*)currentPreferencesLibDc1394CameraUUID
{
	return [[NSUserDefaults standardUserDefaults]
			objectForKey:libDc1394CameraUniqueIdPrefKey];
}

- (BOOL)_changeLibDc1394CameraToCameraWithUniqueId:(NSNumber*)uniqueId error:(NSError**)error
{
	TFLibDC1394Capture* dcCapture = nil;
	BOOL success = NO;
	
	@synchronized(_blobInput) {		
		if ([[_blobInput class] isEqual:[TFBlobLibDc1394InputSource class]]) {
			dcCapture = ((TFBlobLibDc1394InputSource*)_blobInput).dcCapture;
			
			if (![dcCapture setCameraToCameraWithUniqueId:uniqueId error:error]) {
				return NO;
			}
			
			success = YES;
		}
	}
	
	if (success) {
		[[NSNotificationCenter defaultCenter] postNotificationName:TFLibDc1394CameraDidChangeNotification
															object:dcCapture];
		
		return YES;
	}
	
	if (NULL != error)
		*error = [NSError errorWithDomain:TFErrorDomain
									 code:TFErrorTrackingPipelineInputIsNotLibDc1394Source
								 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
										   TFLocalizedString(@"TFTrackingPipelineInputIsNotLibDc1394SourceErrorDesc", @"TFTrackingPipelineInputIsNotLibDc1394SourceErrorDesc"),
											NSLocalizedDescriptionKey,
										   TFLocalizedString(@"TFTrackingPipelineInputIsNotLibDc1394SourceErrorReason", @"TFTrackingPipelineInputIsNotLibDc1394SourceErrorReason"),
											NSLocalizedFailureReasonErrorKey,
										   TFLocalizedString(@"TFTrackingPipelineInputIsNotLibDc1394SourceErrorRecovery", @"TFTrackingPipelineInputIsNotLibDc1394SourceErrorRecovery"),
											NSLocalizedRecoverySuggestionErrorKey,
										   [NSNumber numberWithInteger:NSUTF8StringEncoding],
											NSStringEncodingErrorKey,
										   nil]];	
	return NO;
}

- (BOOL)libdc1394FeatureSupportsAutoMode:(NSInteger)feature
{
	if ([_blobInput isKindOfClass:[TFBlobLibDc1394InputSource class]]) {
		TFLibDC1394Capture* dcCapture = (TFLibDC1394Capture*)[(TFBlobLibDc1394InputSource*)_blobInput captureObject];
		return [dcCapture featureSupportsAutoMode:feature];
	}
	
	return NO;
}

- (BOOL)libDc1394FeatureInAutoMode:(NSInteger)feature
{
	if ([_blobInput isKindOfClass:[TFBlobLibDc1394InputSource class]]) {
		TFLibDC1394Capture* dcCapture = (TFLibDC1394Capture*)[(TFBlobLibDc1394InputSource*)_blobInput captureObject];
		return [dcCapture featureInAutoMode:feature];
	}
	
	return NO;
}

- (void)setLibDc1394Feature:(NSInteger)feature toAutoMode:(BOOL)val
{
	if ([_blobInput isKindOfClass:[TFBlobLibDc1394InputSource class]]) {
		TFLibDC1394Capture* dcCapture = (TFLibDC1394Capture*)[(TFBlobLibDc1394InputSource*)_blobInput captureObject];
		[dcCapture setFeature:feature toAutoMode:val];
	}
}

- (BOOL)libDc1394FeatureIsMutable:(NSInteger)feature
{
	if ([_blobInput isKindOfClass:[TFBlobLibDc1394InputSource class]]) {
		TFLibDC1394Capture* dcCapture = (TFLibDC1394Capture*)[(TFBlobLibDc1394InputSource*)_blobInput captureObject];
		return [dcCapture featureIsMutable:feature];
	}
	
	return NO;
}

- (float)valueForLibDc1394Feature:(NSInteger)feature
{
	if ([_blobInput isKindOfClass:[TFBlobLibDc1394InputSource class]]) {
		TFLibDC1394Capture* dcCapture = (TFLibDC1394Capture*)[(TFBlobLibDc1394InputSource*)_blobInput captureObject];
		return [dcCapture valueForFeature:feature];
	}
	
	return 0.0f;
}

- (void)setLibDc1394Feature:(NSInteger)feature toValue:(float)val
{
	if ([_blobInput isKindOfClass:[TFBlobLibDc1394InputSource class]]) {
		TFLibDC1394Capture* dcCapture = (TFLibDC1394Capture*)[(TFBlobLibDc1394InputSource*)_blobInput captureObject];
		[dcCapture setFeature:feature toValue:val];
	}
}

@end
