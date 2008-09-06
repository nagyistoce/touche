//
//  TFTUIOOSCTrackingDataDistributor.m
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

#import "TFTUIOOSCTrackingDataDistributor.h"

#import <BBOSC/BBOSCPacket.h>
#import <BBOSC/BBOSCBundle.h>

#import "TFThreadMessagingQueue.h"
#import "TFTUIOOSCServer.h"
#import "TFTUIOOSCTrackingDataReceiver.h"


@implementation TFTUIOOSCTrackingDataDistributor

- (id)init
{
	if (nil != (self = [super init])) {
	}
	
	return self;
}

- (void)dealloc
{
	[_server release];
	_server = nil;
	
	[super dealloc];
}

- (BOOL)startDistributorWithObject:(id)obj error:(NSError**)error
{	
	if (nil == _server) {
		_server = [[TFTUIOOSCServer alloc] initWithPort:0 andLocalAddress:nil error:error];
		_server.delegate = self;
	}
	
	return [super startDistributorWithObject:obj error:error];
}

- (void)stopDistributor
{
	[_server release];
	_server = nil;
	
	[super stopDistributor];
}

- (BOOL)canAskReceiversToQuit
{
	return YES;
}

- (BOOL)addTUIOClientAtHost:(NSString*)host port:(UInt16)port error:(NSError**)error
{
	BOOL success = NO;
	TFTUIOOSCTrackingDataReceiver* receiver = [[TFTUIOOSCTrackingDataReceiver alloc] initWithHost:host
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

- (void)removeTUIOClient:(TFTUIOOSCTrackingDataReceiver*)client
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

- (void)distributeTUIODataWithLivingTouches:(NSArray*)livingTouches
							   movedTouches:(NSArray*)movedTouches
								frameNumber:(NSUInteger)frameNumber
{
	BBOSCBundle* tuioBundle = [TFTUIOOSCServer tuioBundleForFrameNumber:frameNumber
															activeBlobs:livingTouches
															 movedBlobs:movedTouches];
	
	@synchronized (_receivers) {
		for (TFTUIOOSCTrackingDataReceiver* receiver in [_receivers allValues])
			[receiver consumeTrackingData:tuioBundle];
	}
}

@end
