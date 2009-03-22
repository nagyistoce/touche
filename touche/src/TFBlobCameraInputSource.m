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
#import "TFPerformanceTimer.h"


#define	FILTERING_THREAD_PRIORITY			(0.95)
#define FRAME_PROCESSING_THREAD_PRIORITY	(0.9)

#define	NUM_PIXEL_BUFFER_FIELDS				(6)

@interface TFBlobCameraInputSource (NonPublicMethods)
- (void)_clearFreeBitmapCreationContexts;
- (void)_clearBitmapCreationContext:(id)contextValue;
- (NSValue*)_reusableContextValueForCIImage:(CIImage*)ciimage
						 renderFiltersOnCPU:(BOOL)renderFiltersOnCPU
						 frameSizeDidChange:(BOOL*)frameSizeDidChange;
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
	
	_bitmapCreationContexts = [[NSMutableArray alloc] init];
	_freeBitmapCreationContexts = [[NSMutableArray alloc] init];
		
	return self;
}

- (void)dealloc
{
	[self unloadWithError:nil];
	
	[self _clearFreeBitmapCreationContexts];
	
	[_bitmapCreationContexts release];
	_bitmapCreationContexts = nil;
	
	[_freeBitmapCreationContexts release];
	_freeBitmapCreationContexts = nil;
	
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
	
	_filterChainIsCameraInputFilterChain = [filterChain isKindOfClass:[TFCameraInputFilterChain class]];
	
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
	
	[self _clearFreeBitmapCreationContexts];
	
	BOOL success = [self stopProcessing:error];
	
	return success;
}

- (BOOL)startProcessing:(NSError**)error
{
	if (NULL != error)
		*error = nil;

	[self _resetBackgroundAcquisitionTiming];
	[self _clearFreeBitmapCreationContexts];
	
	BOOL success = [[self captureObject] startCapturing:error];
	
	if (success)
		success = [super startProcessing:error];
	
	if (success) {
		BOOL startFilteringThread = NO;
		if (nil == _filteringQueue && nil == _filteringThread) {
			_filteringQueue = [[TFThreadMessagingQueue alloc] init];
			
			_filteringThread = [[NSThread alloc] initWithTarget:self
													   selector:@selector(_filterAndDrawFramesThread)
														 object:nil];
			
			startFilteringThread = YES;
		}
	
		if (nil == _processingQueue && nil == _processingThread) {
			_processingQueue = [[TFThreadMessagingQueue alloc] init];
			
			_processingThread = [[NSThread alloc] initWithTarget:self
														selector:@selector(_processPixelBuffersThread)
														  object:nil];
			
			[_processingThread start];
		}
		
		if (startFilteringThread)
			[_filteringThread start];
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

- (CGColorSpaceRef)ciColorSpace
{
	CGColorSpaceRef rv = NULL;
	
	@synchronized(_bitmapCreationContexts) {
		if ([_bitmapCreationContexts count] > 0) {
			NSValue* contextValue = [_bitmapCreationContexts objectAtIndex:0];
			rv = CIImageBitmapsCIOutputColorSpaceForContext([contextValue pointerValue]);
			
			if ([NSNull null] == (id)rv)
				rv = NULL;
		}
	}
	
	return rv;
}

- (CGColorSpaceRef)ciWorkingColorSpace
{
	CGColorSpaceRef rv = NULL;
	
	@synchronized(_bitmapCreationContexts) {
		if ([_bitmapCreationContexts count] > 0) {
			NSValue* contextValue = [_bitmapCreationContexts objectAtIndex:0];
			rv = CIImageBitmapsCIWorkingColorSpaceForContext([contextValue pointerValue]);
			
			if ([NSNull null] == (id)rv)
				rv = NULL;
		}
	}
	
	return rv;
}

- (void)_clearBitmapCreationContext:(id)contextValue
{
	if ([contextValue isKindOfClass:[NSValue class]]) {
		void* context = [(NSValue*)contextValue pointerValue];
		CIImageBitmapsReleaseContext(context);
	}
}

- (void)_clearFreeBitmapCreationContexts
{	
	for (id contextValue in _freeBitmapCreationContexts)
		[self _clearBitmapCreationContext:contextValue];
	
	[_freeBitmapCreationContexts removeAllObjects];
}

- (NSValue*)_reusableContextValueForCIImage:(CIImage*)ciimage
						 renderFiltersOnCPU:(BOOL)renderFiltersOnCPU
						 frameSizeDidChange:(BOOL*)frameSizeDidChange
{
	NSValue* contextValue = nil;
	
	if (NULL != frameSizeDidChange)
		*frameSizeDidChange = NO;
	
	@synchronized (_freeBitmapCreationContexts) {
		while (nil == contextValue && [_freeBitmapCreationContexts count] > 0) {
			contextValue = [[_freeBitmapCreationContexts objectAtIndex:0] retain];
			[_freeBitmapCreationContexts removeObjectAtIndex:0];
			
			void* context = [contextValue pointerValue];
			if (!CIImageBitmapsContextMatchesBitmapSize(context, [ciimage extent].size) ||
				renderFiltersOnCPU != CIImageBitmapsContextRendersOnCPU(context)) {
				[self _clearBitmapCreationContext:contextValue];
				[contextValue release];
				contextValue = nil;
				
				if (NULL != frameSizeDidChange)
					*frameSizeDidChange = YES;
			}
		}
	}
	
	// no suitable context found for reuse, so we make a new one...
	if (nil == contextValue) {
		void* context = NULL;
	
		if ([blobDetector isKindOfClass:[TFRGBA8888BlobDetector class]])
			context = CIImageBitmapsCreateContextForPremultipliedRGBA8(ciimage, renderFiltersOnCPU);
		else if ([blobDetector isKindOfClass:[TFGrayscale8BlobDetector class]])
			context = CIImageBitmapsCreateContextForGrayscale8(ciimage, renderFiltersOnCPU);
		
		CIImageBitmapsSetContextDeterminesFastestRenderingDynamically(context, YES);
		
		contextValue = [[NSValue valueWithPointer:context] retain];		
	}
		
	return [contextValue autorelease];
}

- (void)_updateBackgroundForSubtraction
{
	if (_filterChainIsCameraInputFilterChain)
		@synchronized (filterChain) {
			[(TFCameraInputFilterChain*)filterChain updateBackgroundForSubtraction];
		}
}

- (void)_clearBackgroundForSubtraction
{
	if (_filterChainIsCameraInputFilterChain)
		@synchronized (filterChain) {
			[(TFCameraInputFilterChain*)filterChain clearBackground];
		}
}

- (void)_resetBackgroundAcquisitionTiming
{
	if (_filterChainIsCameraInputFilterChain)
		@synchronized (filterChain) {
			[(TFCameraInputFilterChain*)filterChain resetBackgroundAcquisitionTiming];
		}
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
		
		if (![filteringQueue isEmpty] ||
			![self _shouldProcessThisFrame] ||
			![capturedFrame isKindOfClass:[CIImage class]]) {
			[pool release];
			continue;
		}
		
		CIImage* img = nil;
		BOOL renderFiltersOnCPU = YES;
		NSValue* contextValue = nil;
		
		@synchronized(filterChain) {
			img = [filterChain apply:capturedFrame];
			renderFiltersOnCPU =
					[filterChain isKindOfClass:[TFCIFilterChain class]] ?
						[(TFCIFilterChain*)filterChain renderOnCPU] : YES;
		}
		
		BOOL frameSizeDidChange = NO;
		contextValue = [self _reusableContextValueForCIImage:img
										  renderFiltersOnCPU:renderFiltersOnCPU
										  frameSizeDidChange:&frameSizeDidChange];
		
		// if the frame size changed, we need to acquire a new BG image immediately!
		if (frameSizeDidChange) {
			[self _clearBackgroundForSubtraction];
			[self _resetBackgroundAcquisitionTiming];
		}
		
		if (!blobTrackingEnabled) {
			[self _updateBackgroundForSubtraction];
			
			if (_delegateHasDidDetectBlobs)
				[delegate blobInputSource:self didDetectBlobs:[NSArray array]];
			
			[pool release];
			continue;
		}
		
		TFPMStartTimer(TFPerformanceTimerFilterRendering);

		(void)[img bitmapDataWithBitmapCreationContext:[contextValue pointerValue]];
		
		TFPMStopTimer(TFPerformanceTimerFilterRendering);
		
		[processingQueue enqueue:contextValue];
		
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
		
		NSValue* contextValue = [processingQueue dequeue];
		
		if ([[NSThread currentThread] isCancelled]) {
			[pool release];
			break;
		}
		
		if (![processingQueue isEmpty] || ![contextValue isKindOfClass:[NSValue class]]) {
			[pool release];
			continue;
		}
		
		CIImageBitmapData bitmapData =
				CIImageBitmapsCurrentBitmapDataForContext([contextValue pointerValue]);
			
		[blobDetector setImageBuffer:bitmapData.data
							   width:bitmapData.width
							  height:bitmapData.height
							rowBytes:bitmapData.rowBytes];
		
		NSArray* blobs = nil;
		@synchronized (blobDetector) {
			[blobDetector detectBlobs:NULL ignoreErrors:YES];
			blobs = [NSArray arrayWithArray:[blobDetector detectedBlobs]];
		}
		
		if (0 == [blobs count])
			[self _updateBackgroundForSubtraction];
				
		if (_delegateHasDidDetectBlobs)
			[_deliveryQueue enqueue:blobs];
		
		// reuse the bitmap creation context
		@synchronized (_freeBitmapCreationContexts) {
			[_freeBitmapCreationContexts addObject:contextValue];
		}
		
		[pool release];
	}
	
	while (![processingQueue isEmpty]) {
		id contextValue = [processingQueue dequeue];
		[self _clearBitmapCreationContext:contextValue];
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
	return [self ciWorkingColorSpace];
}

- (void)capture:(TFCapture*)capture didCaptureFrame:(CIImage*)capturedFrame
{
	if (capture == [self captureObject] && nil != capturedFrame)
		[_filteringQueue enqueue:capturedFrame];
}

@end
