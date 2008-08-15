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

#define DEFAULT_FPS	((float)30.0f)

@interface TFBlobInputSource (NonPublicMethods)
- (BOOL)_shouldProcessThisFrame;
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
	TFThrowMethodNotImplementedException();
	
	if (NULL != error)
		*error = nil;
	
	return NO;
}

- (BOOL)stopProcessing:(NSError**)error
{
	TFThrowMethodNotImplementedException();
	
	if (NULL != error)
		*error = nil;
	
	return NO;
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

@end
