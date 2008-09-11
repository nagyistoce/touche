//
//  TFBlobCameraInputSource.m
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

#import "TFBlobCameraInputSource.h"

#import <Accelerate/Accelerate.h>

#import "TFIncludes.h"
#import "TFCapture.h"
#import "CIImage+MakeBitmaps.h"
#import "TFCameraInputFilterChain.h"
#import "TFRGBA8888BlobDetector.h"
#import "TFGrayscale8BlobDetector.h"
#import "TFOpenCVContourBlobDetector.h"
#import "TFThreadMessagingQueue.h"


#define	FILTERING_THREAD_PRIORITY			(0.95)
#define FRAME_PROCESSING_THREAD_PRIORITY	(0.9)

#define	NUM_PIXEL_BUFFER_FIELDS				(6)

@interface TFBlobCameraInputSource (NonPublicMethods)
- (void)_clearFreePixelBuffers;
- (void)_clearPixelBuffer:(NSArray*)buffer;
- (void)_resetBackgroundAcquisitionTiming;
- (void)_clearBackgroundForSubtraction;
- (BOOL)_shouldProcessThisFrame;
- (void)_updateBackgroundForSubtraction;
- (void)_filterAndDrawFramesThread;
- (void)_processPixelBuffersThread;
@end

@implementation TFBlobCameraInputSource

@synthesize filterChain;
@synthesize blobDetector;

- (id)init
{
	if (!(self = [super init])) {
		[self release];
		return nil;
	}
	
	_lastFrameSize = CGSizeMake(0.0f, 0.0f);
	_freePixelBuffers = [[NSMutableArray alloc] init];
		
	return self;
}

- (void)dealloc
{
	[self unloadWithError:nil];
	
	[self _clearFreePixelBuffers];
	
	[_freePixelBuffers release];
	_freePixelBuffers = nil;
	
	[super dealloc];
}

- (BOOL)loadWithConfiguration:(id)configuration error:(NSError**)error
{
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
	
	//NSDictionary* configDict = (NSDictionary*)configuration;
	
	// set up the filter chain
	
	TFCameraInputFilterChain* cameraFilterChain = [[TFCameraInputFilterChain alloc] init];
	
	if (nil == cameraFilterChain) {
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorCameraInputSourceCIFilterChainCreationFailed
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFCameraInputSourceCIFilterChainCreationErrorDesc", @"TFCameraInputSourceCIFilterChainCreationErrorDesc"),
												NSLocalizedDescriptionKey,
											   TFLocalizedString(@"TFCameraInputSourceCIFilterChainCreationErrorReason", @"TFCameraInputSourceCIFilterChainCreationErrorReason"),
												NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFCameraInputSourceCIFilterChainCreationErrorRecovery", @"TFCameraInputSourceCIFilterChainCreationErrorRecovery"),
												NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
												NSStringEncodingErrorKey,
											   nil]];
		
		return NO;
	}
	
	filterChain = cameraFilterChain;
	
	// set up the blob detector
	
	TFOpenCVContourBlobDetector* opencvDetector = [[TFOpenCVContourBlobDetector alloc] init];
	
	if (nil == opencvDetector) {
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorCameraInputSourceOpenCVBlobDetectorCreationFailed
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFCameraInputSourceOpenCVDetectorCreationErrorDesc", @"TFCameraInputSourceOpenCVDetectorCreationErrorDesc"),
												NSLocalizedDescriptionKey,
											   TFLocalizedString(@"TFCameraInputSourceOpenCVDetectorCreationErrorReason", @"TFCameraInputSourceOpenCVDetectorCreationErrorReason"),
												NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFCameraInputSourceOpenCVDetectorCreationErrorRecovery", @"TFCameraInputSourceOpenCVDetectorCreationErrorRecovery"),
												NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
												NSStringEncodingErrorKey,
											   nil]];
		
		return NO;
	}
	
	blobDetector = opencvDetector;
		
	if ([blobDetector isKindOfClass:[TFRGBA8888BlobDetector class]]) {
		_colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	} else if ([blobDetector isKindOfClass:[TFGrayscale8BlobDetector class]]) {
		_colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericGray);
	}
	
	_workingColorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGBLinear);
		
	if (NULL != error)
		*error = nil;
	
	return YES;
}

- (BOOL)unloadWithError:(NSError**)error
{
	if (NULL != error)
		*error = nil;

	@synchronized (filterChain) {
		[filterChain release];
		filterChain = nil;
	}
	
	@synchronized (blobDetector) {
		[blobDetector release];
		blobDetector = nil;
	}
	
	if (NULL != _colorSpace) {
		CGColorSpaceRelease(_colorSpace);
		_colorSpace = NULL;
	}
	
	if (NULL != _workingColorSpace) {
		CGColorSpaceRelease(_workingColorSpace);
		_workingColorSpace = NULL;
	}
	
	[self _clearFreePixelBuffers];
	
	BOOL success = [self stopProcessing:error];
	
	return success;
}

- (BOOL)startProcessing:(NSError**)error
{
	if (NULL != error)
		*error = nil;

	[self _resetBackgroundAcquisitionTiming];
	[self _clearFreePixelBuffers];
	
	BOOL success = [[self captureObject] startCapturing:error];
	
	if (success)
		success = [super startProcessing:error];
	
	if (success) {
		if (nil == _filteringQueue && nil == _filteringThread) {
			_filteringQueue = [[TFThreadMessagingQueue alloc] init];
			
			_filteringThread = [[NSThread alloc] initWithTarget:self
													   selector:@selector(_filterAndDrawFramesThread)
														 object:nil];
			
			[_filteringThread start];
		}
	
		if (nil == _processingQueue && nil == _processingThread) {
			_processingQueue = [[TFThreadMessagingQueue alloc] init];
			
			_processingThread = [[NSThread alloc] initWithTarget:self
														selector:@selector(_processPixelBuffersThread)
														  object:nil];
			[_processingThread start];
		}
	}
	
	return success;
}

- (BOOL)isProcessing
{
	return [[self captureObject] isCapturing];
}

- (BOOL)stopProcessing:(NSError**)error
{
	BOOL success = NO;

	if ([self isProcessing]) {
		success = [[self captureObject] stopCapturing:error];
		
		if (success)
			success = [super stopProcessing:error];
		
		if (nil != _processingQueue && nil != _processingThread) {
			[_processingThread cancel];
			[_processingThread release];
			_processingThread = nil;
			
			// wake the delivering thread if necessary
			[_processingQueue enqueue:[NSArray array]];
			[_processingQueue release];
			_processingQueue = nil;
		}
		
		if (nil != _filteringQueue && nil != _filteringThread) {
			[_filteringThread cancel];
			[_filteringThread release];
			_filteringThread = nil;
			
			// wake the filtering thread if necessary
			[_filteringQueue enqueue:[NSArray array]];
			[_filteringQueue release];
			_filteringQueue = nil;
		}
	}
	
	return success;
}

- (BOOL)hasFilterStages
{
	return YES;
}

- (CIImage*)currentRawImageForStage:(NSInteger)filterStage
{
	CIImage* img;
	
	@synchronized (filterChain) {
		img = [filterChain currentImageForStage:filterStage];
	}
	
	return img;
}

- (void)_clearPixelBuffer:(NSArray*)buffer
{
	if ([buffer count] == NUM_PIXEL_BUFFER_FIELDS) {
		CGContextRef context = (CGContextRef)[buffer objectAtIndex:0];
		CIContext* ciContext = [buffer objectAtIndex:1];
		void* buf = [[buffer objectAtIndex:2] pointerValue];
		
		if ([NSNull null] != (id)context)
			CGContextRelease(context);
		
		if ([NSNull null] != (id)ciContext)
			[ciContext release];
		
		if (NULL != buf)
			free(buf);		
	}
}

- (void)_clearFreePixelBuffers
{
	NSArray* allBuffers = [NSArray arrayWithArray:_freePixelBuffers];
	
	for (NSArray* buffer in allBuffers)
		[self _clearPixelBuffer:buffer];
	
	[_freePixelBuffers removeAllObjects];
}

- (void)_updateBackgroundForSubtraction
{
	if ([filterChain isKindOfClass:[TFCameraInputFilterChain class]])
		[(TFCameraInputFilterChain*)filterChain updateBackgroundForSubtraction];
}

- (void)_clearBackgroundForSubtraction
{
	if ([filterChain isKindOfClass:[TFCameraInputFilterChain class]])
		[(TFCameraInputFilterChain*)filterChain clearBackground];
}

- (void)_resetBackgroundAcquisitionTiming
{
	if ([filterChain isKindOfClass:[TFCameraInputFilterChain class]])
		[(TFCameraInputFilterChain*)filterChain resetBackgroundAcquisitionTiming];
}

- (void)_filterAndDrawFramesThread
{
	NSAutoreleasePool* outerPool = [[NSAutoreleasePool alloc] init];
	TFThreadMessagingQueue* filteringQueue = [_filteringQueue retain];
	TFThreadMessagingQueue* processingQueue = [_processingQueue retain];
	
	[NSThread setThreadPriority:FILTERING_THREAD_PRIORITY];
	
	while (YES) {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		
		CIImage* capturedFrame = [filteringQueue dequeue];
		
		if ([[NSThread currentThread] isCancelled]) {
			[pool release];
			break;
		}
		
		if (![filteringQueue isEmpty] || ![self _shouldProcessThisFrame] || ![capturedFrame isKindOfClass:[CIImage class]]) {
			[pool release];
			continue;
		}
		
		CGSize frameSize = [capturedFrame extent].size;
		CIImage* img = nil;
		BOOL renderFiltersOnCPU = YES;
		
		if (frameSize.width != _lastFrameSize.width || frameSize.height != _lastFrameSize.height) {
			_lastFrameSize.width = frameSize.width;
			_lastFrameSize.height = frameSize.height;
			
			[self _clearFreePixelBuffers];
			
			// if the frame size changed, we need to acquire a new BG image immediately!
			[self _clearBackgroundForSubtraction];
			[self _resetBackgroundAcquisitionTiming];
		}
		
		@synchronized(filterChain) {
			img = [filterChain apply:capturedFrame];
			renderFiltersOnCPU =
			[filterChain isKindOfClass:[TFCIFilterChain class]] ?
				[(TFCIFilterChain*)filterChain renderOnCPU] : YES;
		}
		
		if (_lastFrameRenderOnCPU != renderFiltersOnCPU)
			[self _clearFreePixelBuffers];
		
		_lastFrameRenderOnCPU = renderFiltersOnCPU;
		
		if (!blobTrackingEnabled) {
			[self _updateBackgroundForSubtraction];
			
			if (_delegateHasDidDetectBlobs)
				[delegate blobInputSource:self didDetectBlobs:[NSArray array]];
			
			[pool release];
			continue;
		}
			
		NSArray* pixelBuffer = nil;
		CIContext* ciContext = nil;
		CGContextRef cgContext = NULL;
		void* imgBuffer = NULL;
		size_t rowBytes = 0;
				
		@synchronized(_freePixelBuffers) {
			if ([_freePixelBuffers count] > 0) {
				pixelBuffer = [[_freePixelBuffers objectAtIndex:0] retain];
				[_freePixelBuffers removeObjectAtIndex:0];
				
				cgContext = (CGContextRef)[pixelBuffer objectAtIndex:0];
				ciContext = [pixelBuffer objectAtIndex:1];
				imgBuffer = [[pixelBuffer objectAtIndex:2] pointerValue];
				rowBytes = [[pixelBuffer objectAtIndex:3] unsignedIntValue];
			}
		}
		
		if ([blobDetector isKindOfClass:[TFRGBA8888BlobDetector class]]) {
			imgBuffer = [img createPremultipliedRGBA8888BitmapWithColorSpace:_colorSpace
														   workingColorSpace:_workingColorSpace
																	rowBytes:&rowBytes
																	  buffer:imgBuffer
															cgContextPointer:&cgContext
															ciContextPointer:&ciContext
																 renderOnCPU:renderFiltersOnCPU];

		} else if ([blobDetector isKindOfClass:[TFGrayscale8BlobDetector class]]) {
			imgBuffer = [img createGrayscaleBitmapWithColorSpace:_colorSpace
											   workingColorSpace:_workingColorSpace
														rowBytes:&rowBytes
														  buffer:imgBuffer
												cgContextPointer:&cgContext
												ciContextPointer:&ciContext
													 renderOnCPU:renderFiltersOnCPU];
		}
		
		if (nil == pixelBuffer) {
			pixelBuffer = [[NSArray alloc] initWithObjects:
													(id)cgContext,
													 ciContext,
													 [NSValue valueWithPointer:imgBuffer],
													 [NSNumber numberWithUnsignedInt:rowBytes],
													 [NSValue valueWithSize:NSSizeFromCGSize(frameSize)],
													 [NSNumber numberWithBool:renderFiltersOnCPU],
													 nil];
		}
		
		[processingQueue enqueue:pixelBuffer];
		[pixelBuffer release];
		
		[pool release];
	}
	
	[filteringQueue release];
	[processingQueue release];
	[outerPool release];
}

- (void)_processPixelBuffersThread
{
	NSAutoreleasePool* outerPool = [[NSAutoreleasePool alloc] init];
	
	TFThreadMessagingQueue* processingQueue = [_processingQueue retain];
	
	[NSThread setThreadPriority:FRAME_PROCESSING_THREAD_PRIORITY];
	
	while (YES) {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		
		NSArray* pixelBuffer = [processingQueue dequeue];
		
		if ([[NSThread currentThread] isCancelled]) {
			[pool release];
			break;
		}
		
		if (![processingQueue isEmpty] || [pixelBuffer count] != NUM_PIXEL_BUFFER_FIELDS) {
			[pool release];
			continue;
		}
		
		void* buf = [[pixelBuffer objectAtIndex:2] pointerValue];
		size_t rowBytes = [[pixelBuffer objectAtIndex:3] unsignedIntValue];
		NSSize size = [[pixelBuffer objectAtIndex:4] sizeValue];
			
		if ([blobDetector isKindOfClass:[TFRGBA8888BlobDetector class]]) {
			[(TFRGBA8888BlobDetector*)blobDetector setRGBA8888ImageBuffer:buf
																	width:size.width
																   height:size.height
																 rowBytes:rowBytes];
		} else if ([blobDetector isKindOfClass:[TFGrayscale8BlobDetector class]]) {
			[(TFGrayscale8BlobDetector*)blobDetector setGrayscale8ImageBuffer:buf
																		width:size.width
																	   height:size.height
																	 rowBytes:rowBytes];
		}
		
		NSArray* blobs = nil;
		@synchronized (blobDetector) {
			[blobDetector detectBlobs:NULL ignoreErrors:YES];
			blobs = [NSArray arrayWithArray:[blobDetector detectedBlobs]];
		}
		
		if (0 == [blobs count])
			[self _updateBackgroundForSubtraction];
				
		if (_delegateHasDidDetectBlobs)
			[_deliveryQueue enqueue:blobs];
		
		// re-use the buffer if the framesize or "render on cpu" haven't changed
		if (size.width == _lastFrameSize.width &&
			size.height == _lastFrameSize.height &&
			_lastFrameRenderOnCPU == [[pixelBuffer objectAtIndex:5] boolValue]) {
			@synchronized(_freePixelBuffers) {
				[_freePixelBuffers addObject:pixelBuffer];
			}
		} else {
			[self _clearPixelBuffer:pixelBuffer];
		}
		
		[pool release];
	}
	
	while (![processingQueue isEmpty]) {
		NSArray* buffer = [processingQueue dequeue];
		[self _clearPixelBuffer:buffer];
	}
	
	[processingQueue release];
	
	[outerPool release];
}

- (TFCapture*)captureObject
{
	return nil;
}

- (CGSize)currentCaptureResolution
{
	return [[self captureObject] frameSize];
}

- (BOOL)changeCaptureResolution:(CGSize)newSize error:(NSError**)error
{
	BOOL success = YES;
	if (![[self captureObject] setFrameSize:newSize error:error])
		success = NO;
	
	return success;
}

- (BOOL)supportsCaptureResolution:(CGSize)size
{
	return [[self captureObject] supportsFrameSize:size];
}

- (BOOL)isReady:(NSString**)notReadyReason;
{
	if (NULL != notReadyReason)
		*notReadyReason = nil;
	
	return ([self captureObject] != nil);
}

#pragma mark -
#pragma mark TFCapture delegate

- (CGColorSpaceRef)wantedCIImageColorSpaceForCapture:(TFCapture*)capture
{
	return _workingColorSpace;
}

- (void)capture:(TFCapture*)capture didCaptureFrame:(CIImage*)capturedFrame
{
	if (capture == [self captureObject] && nil != capturedFrame)
		[_filteringQueue enqueue:capturedFrame];
}

@end
