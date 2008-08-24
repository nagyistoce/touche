//
//  TFTUIOTrackingDataDistributor.m
//  Touché
//
//  Created by Georg Kaindl on 24/8/08.
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

#import <BBOSC/BBOSCPacket.h>
#import <BBOSC/BBOSCBundle.h>

#import "TFBlob.h"
#import "TFBlobLabel.h"
#import "TFBlobPoint.h"
#import "TFThreadMessagingQueue.h"
#import "TFTUIOServer.h"
#import "TFTUIOTrackingDataReceiver.h"


#define	DEFAULT_MOTION_THRESHOLD	(5.0f)

@interface TFTUIOTrackingDataDistributor (PrivateMethods)
- (void)_distributionThread;
@end

@implementation TFTUIOTrackingDataDistributor

@synthesize motionThreshold;

- (id)init
{
	if (nil != (self = [super init])) {
		_blobPositions = [[NSMutableDictionary alloc] init];
		_queue = [[TFThreadMessagingQueue alloc] init];
		
		_thread = [[NSThread alloc] initWithTarget:self
										  selector:@selector(_distributionThread)
											object:nil];
		[_thread start];
		
		self.motionThreshold = DEFAULT_MOTION_THRESHOLD;
	}
	
	return self;
}

- (void)dealloc
{
	[_thread cancel];
	
	// queue a dummy to wake up the thread
	[_queue enqueue:[NSDictionary dictionary]];
	
	[_thread release];
	_thread = nil;
	
	[_queue release];
	_queue = nil;
	
	[_server release];
	_server = nil;
	
	[_blobPositions release];
	_blobPositions = nil;
	
	[super dealloc];
}

- (BOOL)startDistributorWithObject:(id)obj error:(NSError**)error
{
	_server = [[TFTUIOServer alloc] initWithPort:0 andLocalAddress:nil error:error];
	_server.delegate = self;
	
	return (nil != _server);
}

- (void)stopDistributor
{
	[_server release];
	_server = nil;
}

- (BOOL)canAskReceiversToQuit
{
	return YES;
}

- (void)distributeTrackingDataDictionary:(NSDictionary*)trackingDict
{
	[_queue enqueue:trackingDict];
}

- (BOOL)addTUIOClientAtHost:(NSString*)host port:(UInt16)port error:(NSError**)error
{
	BOOL success = NO;
	TFTUIOTrackingDataReceiver* receiver = [[TFTUIOTrackingDataReceiver alloc] initWithHost:host
																					   port:port
																					  error:error];
	
	if (nil != [_receivers objectForKey:receiver.receiverID]) {
		// TODO: report error that this address is already being served TUIO data
	} else if (nil != receiver) {
		receiver.owningDistributor = self;
		
		@synchronized (_receivers) {
			[_receivers setObject:receiver forKey:receiver.receiverID];
		}
		
		if ([delegate respondsToSelector:@selector(trackingDataDistributor:receiverDidConnect:)])
			[delegate trackingDataDistributor:self receiverDidConnect:receiver];
		
		success = YES;
	}
	
	[receiver release];
	
	return success;
}

- (void)removeTUIOClient:(TFTUIOTrackingDataReceiver*)client
{
	if (client.owningDistributor == self && nil != [_receivers objectForKey:client.receiverID]) {
		@synchronized (_receivers) {
			[[client retain] autorelease];
			[_receivers removeObjectForKey:client.receiverID];
			
			if ([delegate respondsToSelector:@selector(trackingDataDistributor:receiverDidDisconnect:)])
				[delegate trackingDataDistributor:self receiverDidDisconnect:client];
		}
	}
}

- (void)sendTUIOPacket:(BBOSCPacket*)packet toEndpoint:(NSData*)sockAddr
{
	if (nil != packet && nil != sockAddr)
		[_server sendOSCPacket:packet to:sockAddr];
}

- (void)_distributionThread
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSDictionary *touches = nil;
	NSUInteger frameSequenceNumber = 0;
	
	while (YES) {
		NSAutoreleasePool* innerPool = [[NSAutoreleasePool alloc] init];
		
		touches = (NSDictionary*)[_queue dequeue];
		
		if ([[NSThread currentThread] isCancelled]) {
			[innerPool release];
			[pool release];
			break;
		}
				
		NSArray* newTouches = (NSArray*)[touches objectForKey:kToucheTrackingDistributorDataNewTouchesKey];
		NSArray* updatedTouches = (NSArray*)[touches objectForKey:kToucheTrackingDistributorDataUpdatedTouchesKey];
		
		NSMutableArray* activeTouches = [NSMutableArray arrayWithArray:newTouches];
		[activeTouches addObjectsFromArray:updatedTouches];
		
		NSMutableArray* movedTouches = [NSMutableArray array];
		
		[movedTouches addObjectsFromArray:newTouches];
		for (TFBlob* blob in newTouches) {
			[_blobPositions setObject:blob.center forKey:blob.label];
		}
		
		float minDistance = self.motionThreshold;
		for (TFBlob* blob in updatedTouches) {
			TFBlobPoint* lastPosition = [_blobPositions objectForKey:blob.label];
			if (minDistance <= [blob.center distanceFromBlobPoint:lastPosition]) {
				[_blobPositions setObject:blob.center forKey:blob.label];
				[movedTouches addObject:blob];
			}
		}
		
		BBOSCBundle* tuioBundle = [TFTUIOServer tuioBundleForFrameNumber:frameSequenceNumber
															 activeBlobs:activeTouches
															  movedBlobs:movedTouches];
		
		@synchronized (_receivers) {
			for (TFTUIOTrackingDataReceiver* receiver in [_receivers allValues])
				[receiver consumeTrackingData:tuioBundle];
		}
		
		frameSequenceNumber++;
		
		[innerPool release];
	}
	
	[pool release];
}

@end
