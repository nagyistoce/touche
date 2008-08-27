//
//  TFBlobInputSource.m
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

#import "TFBlobInputSource.h"

#import "TFIncludes.h"
#import "TFThreadMessagingQueue.h"


#define DEFAULT_FPS	((float)30.0f)

@interface TFBlobInputSource (NonPublicMethods)
- (BOOL)_shouldProcessThisFrame;
- (void)_deliverBlobsThread;
@end

@implementation TFBlobInputSource

@synthesize delegate;
@synthesize blobTrackingEnabled;
@synthesize maximumFramesPerSecond;

- (id)init
{
	if (!(self = [super init])) {
		[self release];
		return nil;
	}
	
	delegate = nil;
	blobTrackingEnabled = YES;
	_lastCapturedFrame = nil;
	
	maximumFramesPerSecond	= DEFAULT_FPS;
	
	return self;
}

- (void)dealloc
{
	[_lastCapturedFrame release];
	_lastCapturedFrame = nil;
	
	[super dealloc];
}

- (void)setDelegate:(id)newDelegate
{
	delegate = newDelegate;
	
	// cache for performance reasons
	_delegateHasDidDetectBlobs = [delegate respondsToSelector:@selector(blobInputSource:didDetectBlobs:)];
}

- (BOOL)loadWithConfiguration:(id)configuration error:(NSError**)error
{
	TFThrowMethodNotImplementedException();
	
	if (NULL != error)
		*error = nil;
	
	return NO;
}

- (BOOL)unloadWithError:(NSError**)error
{
	TFThrowMethodNotImplementedException();
		
	if (NULL != error)
		*error = nil;
	
	return NO;
}

- (BOOL)isReady:(NSString**)notReadyReason;
{
	TFThrowMethodNotImplementedException();
	
	if (NULL != notReadyReason)
		*notReadyReason = nil;
	
	return NO;
}

- (BOOL)isProcessing
{
	TFThrowMethodNotImplementedException();
	
	return NO;
}

- (BOOL)startProcessing:(NSError**)error
{
	if (NULL != error)
		*error = nil;
	
	if (nil == _deliveryQueue && nil == _deliveryThread) {
		_deliveryQueue = [[TFThreadMessagingQueue alloc] init];
		
		_deliveryThread = [[NSThread alloc] initWithTarget:self
													selector:@selector(_deliverBlobsThread)
													  object:nil];
		[_deliveryThread start];
	}
	
	return YES;
}

- (BOOL)stopProcessing:(NSError**)error
{	
	if (NULL != error)
		*error = nil;

	if (nil != _deliveryQueue && nil != _deliveryThread) {
		[_deliveryThread cancel];
		[_deliveryThread release];
		_deliveryThread = nil;
		
		// wake the delivering thread if necessary
		[_deliveryQueue enqueue:[NSArray array]];
		[_deliveryQueue release];
		_deliveryQueue = nil;
	}
	
	return YES;
}

- (CGSize)currentCaptureResolution
{
	TFThrowMethodNotImplementedException();
	
	return CGSizeMake(0.0f, 0.0f);
}

- (BOOL)changeCaptureResolution:(CGSize)newSize error:(NSError**)error;
{
	TFThrowMethodNotImplementedException();
	
	if (NULL != error)
		*error = nil;
	
	return NO;
}

- (BOOL)supportsCaptureResolution:(CGSize)size
{
	TFThrowMethodNotImplementedException();
	
	return NO;
}

- (BOOL)hasFilterStages
{
	TFThrowMethodNotImplementedException();

	return NO;
}

- (CIImage*)currentRawImageForStage:(NSInteger)filterStage
{
	TFThrowMethodNotImplementedException();
	
	return nil;
}

- (BOOL)_shouldProcessThisFrame
{
	NSDate* now = [NSDate date];
	if (nil == _lastCapturedFrame || [now timeIntervalSinceDate:_lastCapturedFrame] > (NSTimeInterval)(1.0f/maximumFramesPerSecond)) {
		[_lastCapturedFrame release];
		_lastCapturedFrame = [now retain];
		
		return YES;
	}
	
	return NO;
}

- (void)_deliverBlobsThread
{
	NSAutoreleasePool* outerPool = [[NSAutoreleasePool alloc] init];
	
	TFThreadMessagingQueue* deliveryQueue = [_deliveryQueue retain];
	
	while (YES) {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		
		NSArray* blobs = [deliveryQueue dequeue];
		
		if ([[NSThread currentThread] isCancelled]) {
			[pool release];
			break;
		}
		
		if (![deliveryQueue isEmpty])
			continue;
				
		if ([blobs isKindOfClass:[NSArray class]] && _delegateHasDidDetectBlobs)
			[delegate blobInputSource:self didDetectBlobs:blobs];
		
		[pool release];
	}
		
	[deliveryQueue release];
		
	[outerPool release];
}

@end
