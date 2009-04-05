//
//  TFTUIOTrackingDataDistributor.m
//  Touché
//
//  Created by Georg Kaindl on 6/9/08.
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

#import "TFTUIOTrackingDataDistributor.h"

#import "TFThreadMessagingQueue.h"
#import "TFBlob.h"
#import "TFBlobLabel.h"
#import "TFBlobPoint.h"


#define	DEFAULT_MOTION_THRESHOLD	(5.0f)

@interface TFTUIOTrackingDataDistributor (PrivateMethods)
- (void)_distributionThread;
@end

@implementation TFTUIOTrackingDataDistributor

@synthesize motionThreshold, defaultTuioVersion;

- (id)init
{
	if (nil != (self = [super init])) {
		self.motionThreshold = DEFAULT_MOTION_THRESHOLD;
		self.defaultTuioVersion = TFTUIOVersionDefault;
	}
	
	return self;
}

- (void)dealloc
{
	[self stopDistributor];
	
	[super dealloc];
}

- (BOOL)startDistributorWithObject:(id)obj error:(NSError**)error
{
	if (nil == _blobPositions && nil == _queue && nil == _thread) {
		_blobPositions = [[NSMutableDictionary alloc] init];
		_queue = [[TFThreadMessagingQueue alloc] init];
		
		_thread = [[NSThread alloc] initWithTarget:self
										  selector:@selector(_distributionThread)
											object:nil];
		[_thread start];
	}
	
	return YES;
}

- (void)stopDistributor
{
	[_thread cancel];
	
	// queue a dummy to wake up the thread
	[_queue enqueue:[NSDictionary dictionary]];
	
	[_thread release];
	_thread = nil;
	
	[_queue release];
	_queue = nil;
	
	[_blobPositions release];
	_blobPositions = nil;
}

- (void)distributeTrackingDataDictionary:(NSDictionary*)trackingDict
{
	BOOL hasReceivers = NO;
	
	@synchronized(_receivers) {
		hasReceivers = [_receivers count] > 0;
	}
	
	if (hasReceivers)
		[_queue enqueue:trackingDict];
}

- (void)distributeTUIODataWithLivingTouches:(NSArray*)livingTouches
							   movedTouches:(NSArray*)movedTouches
								frameNumber:(NSUInteger)frameNumber
{
	[self doesNotRecognizeSelector:_cmd];
}

- (void)_distributionThread
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	TFThreadMessagingQueue* queue = [_queue retain];
	NSDictionary *touches = nil;
	NSUInteger frameSequenceNumber = 0;
	
	while (YES) {
		NSAutoreleasePool* innerPool = [[NSAutoreleasePool alloc] init];
		
		touches = (NSDictionary*)[queue dequeue];
		
		if ([[NSThread currentThread] isCancelled]) {
			[innerPool release];
			break;
		}
		
		NSArray* newTouches = (NSArray*)[touches objectForKey:kToucheTrackingDistributorDataNewTouchesKey];
		NSArray* updatedTouches = (NSArray*)[touches objectForKey:kToucheTrackingDistributorDataUpdatedTouchesKey];
		NSArray* endedTouches = (NSArray*)[touches objectForKey:kToucheTrackingDistributorDataEndedTouchesKey];
		
		NSMutableArray* activeTouches = [NSMutableArray arrayWithArray:newTouches];
		[activeTouches addObjectsFromArray:updatedTouches];
		
		NSMutableArray* movedTouches = [NSMutableArray array];
		
		for (TFBlob* blob in endedTouches)
			[_blobPositions removeObjectForKey:blob.label];
		
		[movedTouches addObjectsFromArray:newTouches];
		for (TFBlob* blob in newTouches) {
			[_blobPositions setObject:blob.center forKey:blob.label];
		}
		
		float minDistance = self.motionThreshold;
		for (TFBlob* blob in updatedTouches) {
			TFBlobPoint* lastPosition = [_blobPositions objectForKey:blob.label];
			if (nil == lastPosition || minDistance <= [blob.center distanceFromBlobPoint:lastPosition]) {
				[_blobPositions setObject:blob.center forKey:blob.label];
				[movedTouches addObject:blob];
			}
		}
		
		[self distributeTUIODataWithLivingTouches:activeTouches
									 movedTouches:movedTouches
									  frameNumber:frameSequenceNumber];
		
		frameSequenceNumber++;
		
		[innerPool release];
	}
	
	[queue release];
	
	[pool release];
}

@end
