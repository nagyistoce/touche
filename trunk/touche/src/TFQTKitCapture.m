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
#import "TFPerformanceTimer.h"

#import "TFCapturePixelFormatConversions.h"

#if defined(_USES_IPP_)
#import <ipp.h>
#import <ippi.h>
#endif


#define DEFAULT_LATENCY_FRAMEDROP_THRESHOLD		(0.5)

typedef enum {
	TFQTKitCaptureFormatConversionNone,
	TFQTKitCaptureFormatConversionTheImagingSourceUVCMono8
} TFQTKitCaptureFormatConversion;

typedef struct _TFQTKitCaptureFormatConversionTheImagingSourceUVCMono8Context {
	CVPixelBufferPoolRef	pixelBufferPool;
	void* tmpBuf;
	int tmpBufRowBytes, width, height, camwidth, camheight, finalwidth, finalheight;
} TFQTKitCaptureFormatConversionTheImagingSourceUVCMono8Context;

// forward declaration, since this requires QT 7.6.1
@interface QTCaptureDecompressedVideoOutput (ForwardDeclaration)
- (void)setMinimumVideoFrameInterval:(NSTimeInterval)minimumVideoFrameInterval;
@end

@interface TFQTKitCapture (PixelFormatConversions)
- (CVPixelBufferRef)_formatConvertImageBuffer:(CVImageBufferRef)src;
- (CIImage*)_formatConvertCIImage:(CIImage*)image;
- (void)_updateFormatConversionContext;
- (void)_freeFormatConversionContext;
@end

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

	[self _freeFormatConversionContext];

	[session release];
	session = nil;
	[deviceInput release];
	deviceInput = nil;
	[videoOut release];
	videoOut = nil;
		
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
	
	self->_formatConversionScaleType = TFQTKitCaptureFormatConversionScaleTypeSquish;
		
	return self;
}

- (CGSize)frameSize
{
	CGSize size;
	
	switch (self->_formatConversion) {
		case TFQTKitCaptureFormatConversionTheImagingSourceUVCMono8: {
			if (NULL != self->_formatConversionContext) {
				TFQTKitCaptureFormatConversionTheImagingSourceUVCMono8Context* ctx = self->_formatConversionContext;
			
				size = CGSizeMake(ctx->finalwidth, ctx->finalheight);
			}
			
			break;
		}
		
		default: {
			NSDictionary* pixAttr = [videoOut pixelBufferAttributes];

			if (nil != pixAttr)
				size = CGSizeMake(
					[[pixAttr valueForKey:(id)kCVPixelBufferWidthKey] floatValue],
					[[pixAttr valueForKey:(id)kCVPixelBufferHeightKey] floatValue]
				);
			else {
				NSSize s = [[[[[deviceInput connections] objectAtIndex:0] formatDescription]
								attributeForKey:QTFormatDescriptionVideoCleanApertureDisplaySizeAttribute] sizeValue];
				size = NSSizeToCGSize(s);
			}
			
			if (0.0 == size.width || 0.0 == size.height)
				size = self->_lastCIImageSize;
		}
	}
	
	return size;
}

- (BOOL)setFrameSize:(CGSize)size error:(NSError**)error
{
	switch (self->_formatConversion) {
		case TFQTKitCaptureFormatConversionTheImagingSourceUVCMono8: {
			if (NULL != self->_formatConversionContext) {
				TFQTKitCaptureFormatConversionTheImagingSourceUVCMono8Context* ctx = self->_formatConversionContext;
				
				ctx->finalwidth = size.width;
				ctx->finalheight = size.height;
			}
			
			break;
		}
		
		default: {
			BOOL wasRunning = [self isCapturing];
			
			if (![self stopCapturing:error])
				return NO;
			
			[videoOut setPixelBufferAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
													[NSNumber numberWithFloat:size.width], (id)kCVPixelBufferWidthKey,
													[NSNumber numberWithFloat:size.height], (id)kCVPixelBufferHeightKey,
													nil]];
			
			[self _updateFormatConversionContext];
			
			if (wasRunning) {
				if (![self startCapturing:error])
					return NO;
			}
		}
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
	
	// for some reason, enumerating the formats like this causes a slight drop in CPU usage during capturing
	for (QTFormatDescription* fd in [newDevice formatDescriptions])
		(void)[fd localizedFormatSummary];

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
	
	[self _updateFormatConversionContext];
		
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

	TFPMStartTimer(TFPerformanceTimerCIImageAcquisition);
	
	if (_delegateCapabilities.hasDidCaptureFrame) {
		CVPixelBufferRef pixelBuffer = videoFrame;
	
		if (TFQTKitCaptureFormatConversionNone != self->_formatConversion)
			pixelBuffer = [self _formatConvertImageBuffer:videoFrame];
	
		CIImage* image = nil;
				
		if (_delegateCapabilities.hasWantedCIImageColorSpace) {
			id colorSpace = (id)[delegate wantedCIImageColorSpaceForCapture:self];
			if (nil == colorSpace)
				colorSpace = [NSNull null];
						
			image = [CIImage imageWithCVImageBuffer:pixelBuffer
											options:[NSDictionary dictionaryWithObject:colorSpace
																				forKey:kCIImageColorSpace]];
		} else
			image = [CIImage imageWithCVImageBuffer:pixelBuffer];
				
		if (TFQTKitCaptureFormatConversionNone != self->_formatConversion)
			image = [self _formatConvertCIImage:image];
		
		self->_lastCIImageSize = [image extent].size;
		
		[_frameQueue enqueue:image];
								
		if (TFQTKitCaptureFormatConversionNone != self->_formatConversion)
			CVPixelBufferRelease(pixelBuffer);
	}
	
	TFPMStopTimer(TFPerformanceTimerCIImageAcquisition);
}

- (void)setMaximumFramerate:(float)frameRate
{
	if (0.0f < frameRate && [videoOut respondsToSelector:@selector(setMinimumVideoFrameInterval:)])
		[(id)videoOut setMinimumVideoFrameInterval:(1.0f / frameRate)];
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

#pragma mark -
#pragma mark Format Conversions

- (CVPixelBufferRef)_formatConvertImageBuffer:(CVImageBufferRef)src
{
	CVPixelBufferRef dest = src;
	
	switch (self->_formatConversion) {
		case TFQTKitCaptureFormatConversionTheImagingSourceUVCMono8: {
			TFQTKitCaptureFormatConversionTheImagingSourceUVCMono8Context* ctx =
				(TFQTKitCaptureFormatConversionTheImagingSourceUVCMono8Context*)self->_formatConversionContext;
			
			CVReturn err = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, ctx->pixelBufferPool, &dest);
			
			if (kCVReturnSuccess != err) {
				// TODO: report error
			}
			
			err = CVPixelBufferLockBaseAddress(src, 0);
			
			if (kCVReturnSuccess != err) {
				// TODO: report error
			}
			
			err = CVPixelBufferLockBaseAddress(dest, 0);
			
			if (kCVReturnSuccess != err) {
				// TODO: report error
			}
						
			unsigned char* srcAddr = CVPixelBufferGetBaseAddress(src);
			unsigned char* destAddr = CVPixelBufferGetBaseAddress(dest);
						
			TFCapturePixelFormatConvertMono8toARGB8(srcAddr,
													CVPixelBufferGetBytesPerRow(src),
													destAddr,
													CVPixelBufferGetBytesPerRow(dest),
													ctx->tmpBuf,
													ctx->tmpBufRowBytes,
													ctx->width,
													ctx->height);
			
			err = CVPixelBufferUnlockBaseAddress(src, 0);
			
			if (kCVReturnSuccess != err) {
				// TODO: report error
			}
			
			err = CVPixelBufferUnlockBaseAddress(dest, 0);
			
			if (kCVReturnSuccess != err) {
				// TODO: report error
			}
			
			break;
		}
		
		default:
			CVPixelBufferRetain(dest);
			break;
	}
	
	return dest;
}

- (CIImage*)_formatConvertCIImage:(CIImage*)image
{
	CIImage* img = image;
	
	switch (self->_formatConversion) {
		case TFQTKitCaptureFormatConversionTheImagingSourceUVCMono8: {
			TFQTKitCaptureFormatConversionTheImagingSourceUVCMono8Context* ctx = self->_formatConversionContext;
			
			switch(self->_formatConversionScaleType) {
				case TFQTKitCaptureFormatConversionScaleTypeSquish: {
					float sx = (float)ctx->finalwidth / (float)ctx->width;
					float sy = (float)ctx->finalheight / (float)ctx->height;
					
					CGAffineTransform t1 = CGAffineTransformMakeScale(sx, sy);
					img = [img imageByApplyingTransform:t1];
										
					CGRect r = CGRectMake(0, 0, ctx->finalwidth, ctx->finalheight);
					img = [img imageByCroppingToRect:r];
				
					break;
				}
				
				case TFQTKitCaptureFormatConversionScaleTypeCrop:
				default: {			
					float s = (float)ctx->finalheight / (float)ctx->height;
					
					CGAffineTransform t1 = CGAffineTransformMakeScale(s, s);
					img = [img imageByApplyingTransform:t1];
					
					CGSize ss = CGSizeApplyAffineTransform([image extent].size, t1);
					
					CGRect r = CGRectMake((ss.width - ctx->finalwidth)/2.0, 0, ctx->finalwidth, ctx->finalheight);
					img = [img imageByCroppingToRect:r];
					
					break;
				}
			}
			
			break;
		}
		
		default:
			break;
	}
	
	return img;
}

- (void)_updateFormatConversionContext
{
	[self _freeFormatConversionContext];
	
	CGSize frameSize = [self frameSize];
	
	if (0 == frameSize.width || 0 == frameSize.height)
		return;
	
	TFQTKitCaptureFormatConversion conversion = TFQTKitCaptureFormatConversionNone;
	
	// Determine whether we need a format conversion
	NSString* modelID = [[deviceInput device] modelUniqueID];
	
	// TheImagingSource DMM 21AUC03-ML USB Monochrome CMOS camera
	if ([modelID isEqualToString:@"UVC Camera VendorID_6558 ProductID_33282"])
		conversion = TFQTKitCaptureFormatConversionTheImagingSourceUVCMono8;
				
	switch (conversion) {
		case TFQTKitCaptureFormatConversionTheImagingSourceUVCMono8: {
			TFQTKitCaptureFormatConversionTheImagingSourceUVCMono8Context* ctx =
				malloc(sizeof(TFQTKitCaptureFormatConversionTheImagingSourceUVCMono8Context));
			
			if (NULL == ctx) {
				// TODO: report error
			}
			
			// this is what the mono picture will be at
			ctx->width = 744;
			ctx->height = 480;
			
			// this is what the input misinterpreted by QT as YUV4:2:2 has
			ctx->camwidth = 372;
			ctx->camheight = 480;
			
			// this is what the user requested
			ctx->finalwidth = frameSize.width;
			ctx->finalheight = frameSize.height;
			
			NSDictionary* poolAttr = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithUnsignedInt:k32ARGBPixelFormat], (id)kCVPixelBufferPixelFormatTypeKey,
									  [NSNumber numberWithUnsignedInt:ctx->width], (id)kCVPixelBufferWidthKey,
									  [NSNumber numberWithUnsignedInt:ctx->height], (id)kCVPixelBufferHeightKey,
									  [NSNumber numberWithUnsignedInt:32], (id)kCVPixelBufferBytesPerRowAlignmentKey,
									  nil]; 
			
			CVReturn err = CVPixelBufferPoolCreate(kCFAllocatorDefault, NULL, (CFDictionaryRef)poolAttr, &ctx->pixelBufferPool);
			if (kCVReturnSuccess != err) {
				// TODO: report error
			}
			
			self->_formatConversionContext = ctx;

#if defined(_USES_IPP_)			
			ctx->tmpBuf = ippiMalloc_8u_C1(ctx->width,
										   ctx->height,
										   &ctx->tmpBufRowBytes);
#else
			ctx->tmpBufRowBytes = TFCapturePixelFormatOptimalRowBytesForWidthAndBytesPerPixel(ctx->width, 1);
			ctx->tmpBuf = malloc(ctx->height * ctx->tmpBufRowBytes);
#endif
			
			if (NULL == ctx->tmpBuf) {
				// TODO: report error
			}
			
			[videoOut setPixelBufferAttributes:nil];
						
			self->_formatConversionContext = ctx;
		}
		
		default:
			break;
	}
	
	self->_formatConversion = conversion;
}

- (void)_freeFormatConversionContext
{
	switch (self->_formatConversion) {
		case TFQTKitCaptureFormatConversionTheImagingSourceUVCMono8: {
			if (NULL != self->_formatConversionContext) {
				TFQTKitCaptureFormatConversionTheImagingSourceUVCMono8Context* ctx = self->_formatConversionContext;
				if (NULL != ctx->pixelBufferPool)
					CVPixelBufferPoolRelease(ctx->pixelBufferPool);
				if (NULL != ctx->tmpBuf)
#if defined(_USES_IPP_)
					ippiFree(ctx->tmpBuf);
#else
					free(ctx->tmpBuf);
#endif
				
				[videoOut setPixelBufferAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
													[NSNumber numberWithFloat:ctx->finalwidth], (id)kCVPixelBufferWidthKey,
													[NSNumber numberWithFloat:ctx->finalheight], (id)kCVPixelBufferHeightKey,
													nil]];
			}
			break;
		}
		
		default:
			break;
	}
	
	if (NULL != self->_formatConversionContext)
		free(self->_formatConversionContext);
	
	self->_formatConversion = TFQTKitCaptureFormatConversionNone;
}

@end
