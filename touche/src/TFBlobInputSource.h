//
//  TFBlobInputSource.h
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

#import <Cocoa/Cocoa.h>


/*	This class represents a blob input source. Subclasses should implement the
 *	functions.
 *
 *	When blob are detected, they should be enqueued in _deliveryQueue and NOT delivered to the
 *	delegate directly.
 *
 *	When overriding startProcessing: and stopProcessing:, be sure to call the super-implementation.
 */

@class TFThreadMessagingQueue;

@interface TFBlobInputSource : NSObject {
	id			delegate;
	BOOL		blobTrackingEnabled;
	float		maximumFramesPerSecond;
	
	NSDate*		_lastCapturedFrame;
	BOOL		_delegateHasDidDetectBlobs;
	
	NSThread*					_deliveryThread;
	TFThreadMessagingQueue*		_deliveryQueue;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) BOOL blobTrackingEnabled;
@property (nonatomic, assign) float maximumFramesPerSecond;

- (void)setDelegate:(id)newDelegate;

- (BOOL)loadWithConfiguration:(id)configuration error:(NSError**)error;
- (BOOL)unloadWithError:(NSError**)error;

- (BOOL)isReady:(NSString**)notReadyReason;
- (BOOL)isProcessing;
- (BOOL)startProcessing:(NSError**)error;
- (BOOL)stopProcessing:(NSError**)error;

- (CGSize)currentCaptureResolution;
- (BOOL)changeCaptureResolution:(CGSize)newSize error:(NSError**)error;
- (BOOL)supportsCaptureResolution:(CGSize)size;

- (BOOL)hasFilterStages;
- (NSDictionary*)filterStages;
- (CIImage*)currentRawImageForStage:(NSInteger)filterStage;

- (CGColorSpaceRef)ciColorSpace;
- (CGColorSpaceRef)ciWorkingColorSpace;

@end

@interface NSObject (TFBlobInputSourceDelegate)
- (void)blobInputSource:(TFBlobInputSource*)inputSource didBecomeUnavailableWithError:(NSError*)error;
- (void)blobInputSourceDidBecomeAvailableAgain:(TFBlobInputSource*)inputSource;
- (void)blobInputSource:(TFBlobInputSource*)inputSource willNotBecomeReadyWithError:(NSError*)error;
- (void)blobInputSourceDidBecomeReady:(TFBlobInputSource*)inputSource;
- (void)blobInputSource:(TFBlobInputSource*)inputSource didDetectBlobs:(NSArray*)detectedBlobs;
@end
