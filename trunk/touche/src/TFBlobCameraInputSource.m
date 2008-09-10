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


#define FRAME_PROCESSING_THREAD_PRIORITY	(0.9)

@interface TFBlobCameraInputSource (NonPublicMethods)
- (void)_clearDrawingContexts;
- (void)_resetBackgroundAcquisitionTiming;
- (void)_clearBackgroundForSubtraction;
- (BOOL)_shouldProcessThisFrame;
- (void)_updateBackgroundForSubtraction;
- (void)_processFramesThread;
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
	
	// will be automatically allocated upon the first pass
	_imgBuffer = NULL;
	
	_rowBytes = 0;
	_lastFrameSize = CGSizeMake(0.0f, 0.0f);
		
	return self;
}

- (void)dealloc
{
	[self unloadWithError:nil];
	
	[self _clearDrawingContexts];
		
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

	if (NULL != _imgBuffer) {
		free(_imgBuffer);
		_imgBuffer = NULL;
	}
	
	if (NULL != _colorSpace) {
		CGColorSpaceRelease(_colorSpace);
		_colorSpace = NULL;
	}
	
	if (NULL != _workingColorSpace) {
		CGColorSpaceRelease(_workingColorSpace);
		_workingColorSpace = NULL;
	}
	
	[self _clearDrawingContexts];
	
	BOOL success = [self stopProcessing:error];
	
	return success;
}

- (BOOL)startProcessing:(NSError**)error
{
	if (NULL != error)
		*error = nil;

	[self _resetBackgroundAcquisitionTiming];
	[self _clearDrawingContexts];
	
	BOOL success = [[self captureObject] startCapturing:error];
	
	if (success)
		success = [super startProcessing:error];
	
	if (success) {
		if (nil == _processingQueue && nil == _processingThread) {
			_processingQueue = [[TFThreadMessagingQueue alloc] init];
			
			_processingThread = [[NSThread alloc] initWithTarget:self
														selector:@selector(_processFramesThread)
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

- (void)_clearDrawingContexts
{
	if (NULL != _bitmapContext) {
		CGContextRelease(_bitmapContext);
		_bitmapContext = NULL;
	}
	
	[_ciContext release];
	_ciContext = nil;
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

- (void)_processFramesThread
{
	NSAutoreleasePool* outerPool = [[NSAutoreleasePool alloc] init];
	
	TFThreadMessagingQueue* processingQueue = [_processingQueue retain];
	
	[NSThread setThreadPriority:FRAME_PROCESSING_THREAD_PRIORITY];
	
	while (YES) {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		
		CIImage* capturedFrame = [processingQueue dequeue];
		
		if ([[NSThread currentThread] isCancelled]) {
			[pool release];
			break;
		}
		
		if (![processingQueue isEmpty]) {
			[pool release];
			continue;
		}
		
		if (![self _shouldProcessThisFrame] || ![capturedFrame isKindOfClass:[CIImage class]]) {
			[pool release];
			continue;
		}
		
		@synchronized (self) {	
			CGSize frameSize = [capturedFrame extent].size;
			
			if (frameSize.width != _lastFrameSize.width || frameSize.height != _lastFrameSize.height) {
				_lastFrameSize.width = frameSize.width;
				_lastFrameSize.height = frameSize.height;
				
				if (NULL != _imgBuffer) {
					free(_imgBuffer);
					_imgBuffer = NULL;
				}
				
				_rowBytes = 0;
				
				[self _clearDrawingContexts];
				
				// if the frame size changed, we need to acquire a new BG image immediately!
				[self _clearBackgroundForSubtraction];
				[self _resetBackgroundAcquisitionTiming];
			}
			
			CIImage* img = nil;
			BOOL renderFiltersOnCPU = YES;
			@synchronized(filterChain) {
				img = [filterChain apply:capturedFrame];
				renderFiltersOnCPU =
				[filterChain isKindOfClass:[TFCIFilterChain class]] ?
					[(TFCIFilterChain*)filterChain renderOnCPU] : YES;
			}
			
			if (_lastFrameRenderOnCPU != renderFiltersOnCPU)
				[self _clearDrawingContexts];
			
			_lastFrameRenderOnCPU = renderFiltersOnCPU;
			
			if (!blobTrackingEnabled) {
				[self _updateBackgroundForSubtraction];
				
				if (_delegateHasDidDetectBlobs)
					[delegate blobInputSource:self didDetectBlobs:[NSArray array]];
					
				[pool release];
				continue;
			}
			
			if ([blobDetector isKindOfClass:[TFRGBA8888BlobDetector class]]) {
				_imgBuffer = [img createPremultipliedRGBA8888BitmapWithColorSpace:_colorSpace
																workingColorSpace:_workingColorSpace
																		 rowBytes:&_rowBytes
																		   buffer:_imgBuffer
																 cgContextPointer:&_bitmapContext
																 ciContextPointer:&_ciContext
																	  renderOnCPU:renderFiltersOnCPU];
				
				[(TFRGBA8888BlobDetector*)blobDetector setRGBA8888ImageBuffer:_imgBuffer
																		width:frameSize.width
																	   height:frameSize.height
																	 rowBytes:_rowBytes];
			} else if ([blobDetector isKindOfClass:[TFGrayscale8BlobDetector class]]) {
				_imgBuffer = [img createGrayscaleBitmapWithColorSpace:_colorSpace
													workingColorSpace:_workingColorSpace
															 rowBytes:&_rowBytes
															   buffer:_imgBuffer
													 cgContextPointer:&_bitmapContext
													 ciContextPointer:&_ciContext
														  renderOnCPU:renderFiltersOnCPU];
				
				[(TFGrayscale8BlobDetector*)blobDetector setGrayscale8ImageBuffer:_imgBuffer
																			width:frameSize.width
																		   height:frameSize.height
																		 rowBytes:_rowBytes];
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
		}
		
		[pool release];
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
		[_processingQueue enqueue:capturedFrame];
}

@end
