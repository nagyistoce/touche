//
//  TFTrackingPipeline+QTInputAdditions.m
//  Touché
//
//  Created by Georg Kaindl on 23/4/08.
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

#import "TFTrackingPipeline+QTInputAdditions.h"

#import "TFIncludes.h"
#import "TFQTKitCapture.h"
#import "TFBlobQuicktimeKitInputSource.h"

NSString* qtCaptureDeviceUniqueIdPrefKey = @"qtCaptureDeviceUniqueIdPrefKey";
NSString* qtCaptureCameraResolutionPrefKey = @"qtCaptureCameraResolutionPrefKey";


@implementation TFTrackingPipeline (QTInputAddtions)

- (NSString*)_defaultQTVideoDeviceUniqueID
{
	return [TFQTKitCapture defaultCaptureDeviceUniqueId];
}

- (NSString*)currentPreferencesQTDeviceUUID
{
	return [[NSUserDefaults standardUserDefaults]
			stringForKey:qtCaptureDeviceUniqueIdPrefKey];
}

- (BOOL)_changeQTCaptureDeviceToDeviceWithUniqueId:(NSString*)uniqueId error:(NSError**)error
{
	@synchronized(_blobInput) {		
		if ([[_blobInput class] isEqual:[TFBlobQuicktimeKitInputSource class]]) {
			TFQTKitCapture* qtkitCapture = ((TFBlobQuicktimeKitInputSource*)_blobInput).qtKitCapture;
			
			if (![qtkitCapture setCaptureDeviceWithUniqueId:uniqueId error:error]) {
				return NO;
			}
		
			return YES;
		}
	}
	
	if (NULL != error)
		*error = [NSError errorWithDomain:TFErrorDomain
									 code:TFErrorTrackingPipelineInputIsNotQTKitSource
								 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
										   TFLocalizedString(@"TFTrackingPipelineInputIsNotQTSourceErrorDesc", @"TFTrackingPipelineInputIsNotQTSourceErrorDesc"),
											NSLocalizedDescriptionKey,
										   TFLocalizedString(@"TFTrackingPipelineInputIsNotQTSourceErrorReason", @"TFTrackingPipelineInputIsNotQTSourceErrorReason"),
											NSLocalizedFailureReasonErrorKey,
										   TFLocalizedString(@"TFTrackingPipelineInputIsNotQTSourceErrorRecovery", @"TFTrackingPipelineInputIsNotQTSourceErrorRecovery"),
											NSLocalizedRecoverySuggestionErrorKey,
										   [NSNumber numberWithInteger:NSUTF8StringEncoding],
											NSStringEncodingErrorKey,
										   nil]];
	
	return NO;
}

@end
