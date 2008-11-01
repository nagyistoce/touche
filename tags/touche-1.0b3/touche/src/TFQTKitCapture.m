//
//  TFQTKitCapture.m
//  Touché
//
//  Created by Georg Kaindl on 4/1/08.
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

#import <QuartzCore/QuartzCore.h>

#import "TFQTKitCapture.h"
#import "TFIncludes.h"
#import "TFThreadMessagingQueue.h"


#define DEFAULT_LATENCY_FRAMEDROP_THRESHOLD		(0.5)

@implementation TFQTKitCapture

@synthesize session;
@synthesize deviceInput;
@synthesize videoOut;
@synthesize framedropLatencyThreshold;

- (void)dealloc
{	
	[self stopCapturing:NULL];
	
	QTCaptureDevice* device = [deviceInput device];
	if ([device isOpen])
		[device close];

	[session release];
	[deviceInput release];
	[videoOut release];
	
	[super dealloc];
}

- (id)init
{
	return [self initWithDevice:nil error:NULL];
}

- (id)initWithUniqueDeviceId:(NSString*)deviceId
{
	return [self initWithUniqueDeviceId:deviceId error:NULL];
}

- (id)initWithUniqueDeviceId:(NSString*)deviceId error:(NSError**)error
{
	if (nil == deviceId)
		deviceId = [[self class] defaultCaptureDeviceUniqueId];

	QTCaptureDevice* dev = [QTCaptureDevice deviceWithUniqueID:deviceId];
	if (nil == dev) {
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorQTKitCaptureFailedToCreateWithUniqueID
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFQTKitCreationFromUIDErrorDesc", @"TFQTKitCreationFromUIDErrorDesc"),
												NSLocalizedDescriptionKey,
											   [NSString stringWithFormat:TFLocalizedString(@"TFQTKitCreationFromUIDErrorReason", @"TFQTKitCreationFromUIDErrorReason"),
												deviceId],
												NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFQTKitCreationFromUIDErrorRecovery", @"TFQTKitCreationFromUIDErrorRecovery"),
												NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
												NSStringEncodingErrorKey,
											   nil]];

		[self release];
		return nil;
	}

	return [self initWithDevice:dev error:error];
}

- (id)initWithDevice:(QTCaptureDevice*)device
{
	return [self initWithDevice:device error:NULL];
}

- (id)initWithDevice:(QTCaptureDevice*)device error:(NSError**)error
{
	if (!(self = [super init])) {
		[self release];
		return nil;
	}
	
	if (NULL != error)
		*error = nil;
	
	framedropLatencyThreshold = DEFAULT_LATENCY_FRAMEDROP_THRESHOLD;

	NSError* err;

	session = [[QTCaptureSession alloc] init];
	
	if (nil == device)
		device = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];
		
	if (![self setCaptureDevice:device error:&err]) {
		if (NULL != error)
			*error = err;
		
		[self release];
		return nil;
	}
	
	videoOut = [[QTCaptureDecompressedVideoOutput alloc] init];
	
	[videoOut setDelegate:self];
	if (![session addOutput:videoOut error:&err]) {
		if (NULL != error)
			*error = err;
		
		[self release];
		return nil;
	}
		
	return self;
}

- (CGSize)frameSize
{
	NSDictionary* pixAttr = [videoOut pixelBufferAttributes];

	return CGSizeMake(
		[[pixAttr valueForKey:(id)kCVPixelBufferWidthKey] floatValue],
		[[pixAttr valueForKey:(id)kCVPixelBufferHeightKey] floatValue]
	);
}

- (BOOL)setFrameSize:(CGSize)size error:(NSError**)error
{
	BOOL wasRunning = [self isCapturing];
	
	if (![self stopCapturing:error])
		return NO;
		
	[videoOut setPixelBufferAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
											[NSNumber numberWithFloat:size.width], (id)kCVPixelBufferWidthKey,
                                            [NSNumber numberWithFloat:size.height], (id)kCVPixelBufferHeightKey,
                                           // [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32ARGB], (id)kCVPixelBufferPixelFormatTypeKey,
                                            nil]];
	
	if (wasRunning) {
		if (![self startCapturing:error])
			return NO;
	}
	
	return YES;
}

// since QTKit sets the hardware resolution to the nearest match and then happily scales the frames to
// whichever size we want, we return YES for any reasonable resolution
- (BOOL)supportsFrameSize:(CGSize)size
{
	if (size.width > 0.0f && size.height > 0.0f)
		return YES;
	
	return NO;
}

- (QTCaptureDevice*)captureDevice
{
	return [deviceInput device];
}

- (BOOL)setCaptureDevice:(QTCaptureDevice*)newDevice error:(NSError**)error
{
	if (NULL != error)
		*error = nil;
	
	NSError* err;
	
	if (nil == newDevice) {
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorQTKitCaptureDeviceSetToNil
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFQTKitCaptureDeviceSetToNilErrorDesc", @"TFQTKitCaptureDeviceSetToNilErrorDesc"),
												NSLocalizedDescriptionKey,
											   TFLocalizedString(@"TFQTKitCaptureDeviceSetToNilErrorReason", @"TFQTKitCaptureDeviceSetToNilErrorReason"),
												NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFQTKitCaptureDeviceSetToNilErrorRecovery", @"TFQTKitCaptureDeviceSetToNilErrorRecovery"),
												NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
												NSStringEncodingErrorKey,
											   nil]];

		return NO;
	}

	BOOL wasRunning = [self isCapturing];
	
	if (![self stopCapturing:error])
		return NO;

	// if there's already a deviceInput active, we need to free the resources first
	if (nil != deviceInput) {
		[session removeInput:deviceInput];
	
		QTCaptureDevice* oldDevice = [deviceInput device];
		if ([oldDevice isOpen])
			[oldDevice close];
		
		[deviceInput release];
		deviceInput = nil;
	}
	
	if (![newDevice open:&err]) {
		if (NULL != error)
			*error = err;
		
		return NO;
	}
	
	deviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:newDevice];
	
	if (nil == self.deviceInput) {
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorQTKitCaptureDeviceInputCouldNotBeCreated
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFQTKitDeviceInputCreationErrorDesc", @"TFQTKitDeviceInputCreationErrorDesc"),
												NSLocalizedDescriptionKey,
											   TFLocalizedString(@"TFQTKitDeviceInputCreationErrorReason", @"TFQTKitDeviceInputCreationErrorReason"),
												NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFQTKitDeviceInputCreationErrorRecovery", @"TFQTKitDeviceInputCreationErrorRecovery"),
												NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
												NSStringEncodingErrorKey,
											   nil]];

		return NO;
	}
	
	if (![session addInput:deviceInput error:&err]) {
		if (NULL != error)
			*error = err;
		
		return NO;
	}
		
	if (wasRunning) {
		if (![self startCapturing:error])
			return NO;
	}
	
	return YES;
}

- (NSString*)captureDeviceUniqueId
{
	return [[deviceInput device] uniqueID];
}

- (BOOL)setCaptureDeviceWithUniqueId:(NSString*)deviceId error:(NSError**)error
{
	QTCaptureDevice* device = [QTCaptureDevice deviceWithUniqueID:deviceId];
	
	if (nil == device) {
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorQTKitCaptureDeviceWithUIDNotFound
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFQTKitDeviceWithUIDNotFoundErrorDesc", @"TFQTKitDeviceWithUIDNotFoundErrorDesc"),
												NSLocalizedDescriptionKey,
											   [NSString stringWithFormat:TFLocalizedString(@"TFQTKitDeviceWithUIDNotFoundErrorReason", @"TFQTKitDeviceWithUIDNotFoundErrorReason"),
												deviceId],
												NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFQTKitDeviceWithUIDNotFoundErrorRecovery", @"TFQTKitDeviceWithUIDNotFoundErrorRecovery"),
												NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
												NSStringEncodingErrorKey,
											   nil]];

		return NO;
	}
	
	return [self setCaptureDevice:device error:error];
}

- (BOOL)isCapturing
{
	return [session isRunning];
}

- (BOOL)startCapturing:(NSError**)error
{
	BOOL success = YES;
	
	if (NULL != error)
		*error = nil;

	if (![session isRunning]) {
		[session startRunning];
		success = [super startCapturing:error];
	}
		
	return success;
}

- (BOOL)stopCapturing:(NSError**)error
{
	BOOL success = YES;
	
	if (NULL != error)
		*error = nil;

	if ([session isRunning]) {
		[session stopRunning];
		
		success = [super stopCapturing:error];
	}
	
	return success;
}

- (void)captureOutput:(QTCaptureOutput*)captureOutput didOutputVideoFrame:(CVImageBufferRef)videoFrame withSampleBuffer:(QTSampleBuffer *)sampleBuffer fromConnection:(QTCaptureConnection *)connection
{
	uint64_t ht = CVGetCurrentHostTime(), iht = [[sampleBuffer attributeForKey:QTSampleBufferHostTimeAttribute] unsignedLongLongValue];
	double freq = CVGetHostClockFrequency(), hts = ht/freq, ihts = iht/freq;
		
	// If the frame latency has grown larger than the cutoff threshold, we drop the frame. 
	if (hts > ihts + framedropLatencyThreshold)
		return;

	if (_delegateCapabilities.hasDidCaptureFrame) {
		CIImage* image = nil;
		
		if (_delegateCapabilities.hasWantedCIImageColorSpace)
			image = [CIImage imageWithCVImageBuffer:videoFrame
											options:[NSDictionary dictionaryWithObject:(id)[delegate wantedCIImageColorSpaceForCapture:self]
																				forKey:kCIImageColorSpace]];
		else
			image = [CIImage imageWithCVImageBuffer:videoFrame];
		
		[_frameQueue enqueue:image];
	}
}

+ (NSDictionary*)connectedDevicesNamesAndIds
{
	NSMutableDictionary *retVal = [NSMutableDictionary dictionary];

	NSArray* devs = [QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeVideo];
	
	for (QTCaptureDevice* dev in devs)
		[retVal setObject:[dev localizedDisplayName] forKey:[dev uniqueID]];
	
	return [NSDictionary dictionaryWithDictionary:retVal];
}

+ (QTCaptureDevice*)defaultCaptureDevice
{
	return [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];
}

+ (NSString*)defaultCaptureDeviceUniqueId
{
	return [[self defaultCaptureDevice] uniqueID];
}

+ (BOOL)deviceConnectedWithID:(NSString*)deviceID
{
	return [[QTCaptureDevice deviceWithUniqueID:deviceID] isConnected];
}

@end
