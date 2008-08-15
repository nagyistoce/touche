//
//  TFBlobQuicktimeKitInputSource.m
//  Touché
//
//  Created by Georg Kaindl on 21/4/08.
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

#import "TFBlobQuicktimeKitInputSource.h"

#import "TFIncludes.h"
#import "TFQTKitCapture.h"

NSString*	tfBlobQuicktimeKitInputSourceConfItemCameraUniqueID = @"tfBlobQuicktimeKitInputSourceConfItemCameraUniqueID";
NSString*	tfBlobQuicktimeKitInputSourceConfItemCameraResolutionX = @"tfBlobQuicktimeKitInputSourceConfItemCameraResolutionX";
NSString*	tfBlobQuicktimeKitInputSourceConfItemCameraResolutionY = @"tfBlobQuicktimeKitInputSourceConfItemCameraResolutionY";

@implementation TFBlobQuicktimeKitInputSource

@synthesize qtKitCapture;

- (void)dealloc
{
	if ([qtKitCapture isCapturing])
		[qtKitCapture stopCapturing:NULL];
	
	[qtKitCapture release];
	qtKitCapture = nil;
	
	[super dealloc];
}

- (id)init
{
	if (!(self = [super init])) {
		[self release];
		return nil;
	}
	
	return self;
}

- (BOOL)loadWithConfiguration:(id)configuration error:(NSError**)error
{
	if (![super loadWithConfiguration:configuration error:error])
		return NO;
	
	if (nil == configuration || ![configuration isKindOfClass:[NSDictionary class]]) {
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorInputSourceInvalidArguments
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFInputSourceArgumentsErrorDesc", @"TFInputSourceArgumentsErrorDesc"),
												NSLocalizedDescriptionKey,
											   TFLocalizedString(@"TFInputSourceArgumentsErrorReason", @"TFInputSourceArgumentsErrorReason"),
												NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFInputSourceArgumentsErrorRecovery", @"TFInputSourceArgumentsErrorRecovery"),
												NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
												NSStringEncodingErrorKey,
											   nil]];

		return NO;
	}
	
	NSDictionary* configDict = (NSDictionary*)configuration;
	
	qtKitCapture =
		[[TFQTKitCapture alloc] initWithUniqueDeviceId:(NSString*)[configDict objectForKey:tfBlobQuicktimeKitInputSourceConfItemCameraUniqueID]
												 error:error];
	
	if (nil == qtKitCapture)
		return NO;
	
	qtKitCapture.delegate = self;
	
	NSNumber* camWidth = (NSNumber*)[configDict objectForKey:tfBlobQuicktimeKitInputSourceConfItemCameraResolutionX];
	NSNumber* camHeight = (NSNumber*)[configDict objectForKey:tfBlobQuicktimeKitInputSourceConfItemCameraResolutionY];
	
	if (nil != camWidth && nil != camHeight) {
		if(![self changeCaptureResolution:CGSizeMake([camWidth floatValue], [camHeight floatValue])
								error:error])
			return NO;
	}
	
	if (NULL != error)
		*error = nil;
	
	return YES;
}

- (BOOL)unloadWithError:(NSError**)error
{	
	if (![super unloadWithError:error])
		return NO;
	
	[qtKitCapture release];
	qtKitCapture = nil;
	
	return YES;
}

- (TFCapture*)captureObject
{
	return qtKitCapture;
}

@end
