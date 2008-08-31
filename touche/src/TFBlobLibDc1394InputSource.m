//
//  TFBlobLibDc1394InputSource.m
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

#import "TFBlobLibDc1394InputSource.h"

#import "TFIncludes.h"
#import "TFLibDC1394Capture.h"

NSString* tfBlobLibDc1394InputSourceConfItemCameraUniqueID = @"tfBlobLibDc1394InputSourceConfItemCameraUniqueID";
NSString* tfBlobLibDc1394InputSourceConfItemCameraResolutionX = @"tfBlobLibDc1394InputSourceConfItemCameraResolutionX";
NSString* tfBlobLibDc1394InputSourceConfItemCameraResolutionY = @"tfBlobLibDc1394InputSourceConfItemCameraResolutionY";

@implementation TFBlobLibDc1394InputSource

@synthesize dcCapture;

- (void)dealloc
{
	if ([dcCapture isCapturing])
		[dcCapture stopCapturing:NULL];
	
	[dcCapture release];
	dcCapture = nil;
	
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
	
	dcCapture = [[TFLibDC1394Capture alloc] initWithCameraUniqueId:[configuration objectForKey:tfBlobLibDc1394InputSourceConfItemCameraUniqueID]
					error:error];
		
	if (nil == dcCapture)	
		return NO;
	
	dcCapture.delegate = self;
	
	NSNumber* camWidth = (NSNumber*)[configDict objectForKey:tfBlobLibDc1394InputSourceConfItemCameraResolutionX];
	NSNumber* camHeight = (NSNumber*)[configDict objectForKey:tfBlobLibDc1394InputSourceConfItemCameraResolutionY];
	
	if (nil != camWidth && nil != camHeight) {
		if(![self changeCaptureResolution:CGSizeMake([camWidth floatValue], [camHeight floatValue])
									error:error])
			return NO;
	}
	
	[dcCapture setMinimumFramerate:maximumFramesPerSecond];
	
	if (NULL != error)
		*error = nil;
	
	return YES;
}

- (BOOL)unloadWithError:(NSError**)error
{	
	if (![super unloadWithError:error])
		return NO;
	
	[dcCapture release];
	dcCapture = nil;
	
	return YES;
}

- (TFCapture*)captureObject
{
	return dcCapture;
}

- (BOOL)changeCaptureResolution:(CGSize)newSize error:(NSError**)error
{
	BOOL success = YES;
	if (![dcCapture setFrameSize:newSize error:error])
		success = NO;
	
	return success;
}

- (void)setMaximumFramesPerSecond:(float)newVal
{
	if (newVal != maximumFramesPerSecond) {
		maximumFramesPerSecond = newVal;
		[dcCapture setMinimumFramerate:maximumFramesPerSecond];
	}
}

@end
