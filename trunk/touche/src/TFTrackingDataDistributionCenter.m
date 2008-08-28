//
//  TFTrackingDataDistributionCenter.m
//  Touché
//
//  Created by Georg Kaindl on 22/8/08.
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

#import "TFTrackingDataDistributionCenter.h"

#import "TFTrackingDataReceiverInfoDictKeys.h"
#import "TFTrackingDataDistributor.h"
#import "TFBlob.h"
#import "TFThreadMessagingQueue.h"


@interface TFTrackingDataDistributionCenter (PrivateMethods)
- (void)_distributeTouchDataThread;
- (void)_handleTrackingDataDistributionForActiveBlobs:(NSArray*)activeBlobs inactiveBlobs:(NSArray*)inactiveBlobs;
@end


@implementation TFTrackingDataDistributionCenter

- (id)init
{
	if (nil != (self = [super init])) {
		_distributors = [[NSMutableSet alloc] init];
		_blobQueue = [[TFThreadMessagingQueue alloc] init];
		
		_thread = [[NSThread alloc] initWithTarget:self
										  selector:@selector(_distributeTouchDataThread)
											object:nil];
		
		[_thread start];
	}
	
	return self;
}

- (void)dealloc
{
	[_distributors release];
	_distributors = nil;
	
	[_blobQueue release];
	_blobQueue = nil;
	
	[super dealloc];
}

- (void)addDistributor:(TFTrackingDataDistributor*)distributor
{
	if (nil != distributor) {
		@synchronized(_distributors) {
			[_distributors addObject:distributor];
		}
	}
}

- (void)distributeTrackingDataForActiveBlobs:(NSArray*)activeBlobs inactiveBlobs:(NSArray*)inactiveBlobs
{
	id activeB = (nil != activeBlobs) ? (id)activeBlobs : (id)[NSNull null];
	id inactiveB = (nil != inactiveBlobs) ? (id)inactiveBlobs : (id)[NSNull null];
	
	[_blobQueue enqueue:[NSArray arrayWithObjects:activeB, inactiveB, nil]];
}

- (void)invalidate
{
	[_thread cancel];
	// enqueue a dummy object to wake the thread
	[_blobQueue enqueue:[NSArray array]];
	
	[_thread release];
	_thread = nil;
	
	[self stopAllDistributors];
}

- (void)stopAllDistributors
{
	@synchronized (_distributors) {
		for (TFTrackingDataDistributor* distributor in _distributors) {
			@synchronized (distributor) {
				[distributor stopDistributor];
			}
		}
	}
}

- (void)_distributeTouchDataThread
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSArray* blobData = nil;
	
	while (YES) {
		NSAutoreleasePool* innerPool = [[NSAutoreleasePool alloc] init];
		
		blobData = (NSArray*)[_blobQueue dequeue];
		
		if ([[NSThread currentThread] isCancelled]) {
			[innerPool release];
			break;
		}
		
		if ([blobData count] == 2)
			[self _handleTrackingDataDistributionForActiveBlobs:[blobData objectAtIndex:0]
												  inactiveBlobs:[blobData objectAtIndex:1]];
		
		[innerPool release];
	}
	
	[pool release];
}

- (void)_handleTrackingDataDistributionForActiveBlobs:(NSArray*)activeBlobs inactiveBlobs:(NSArray*)inactiveBlobs
{
	NSMutableDictionary* blobDict = [NSMutableDictionary dictionary];
	if ([NSNull null] != (id)inactiveBlobs && [inactiveBlobs count] > 0)
		[blobDict setObject:inactiveBlobs forKey:kToucheTrackingDistributorDataEndedTouchesKey];
	
	NSMutableArray* newTouches = [NSMutableArray array];
	NSMutableArray* updatedTouches = [NSMutableArray array];
	
	if ([NSNull null] != (id)activeBlobs) {
		for (TFBlob* blob in activeBlobs) {
			if (blob.isUpdate)
				[updatedTouches addObject:blob];
			else
				[newTouches addObject:blob];
		}
	}
	
	if ([newTouches count] > 0)
		[blobDict setObject:[NSArray arrayWithArray:newTouches] forKey:kToucheTrackingDistributorDataNewTouchesKey];
	
	if ([updatedTouches count] > 0)
		[blobDict setObject:[NSArray arrayWithArray:updatedTouches] forKey:kToucheTrackingDistributorDataUpdatedTouchesKey];
	
	NSDictionary* touches = [NSDictionary dictionaryWithDictionary:blobDict];
	
	@synchronized(_distributors) {
		for (TFTrackingDataDistributor* distributor in _distributors) {
			@synchronized (distributor) {
				[distributor distributeTrackingDataDictionary:touches];
			}
		}
	}
}

@end
