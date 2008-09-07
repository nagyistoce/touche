//
//  TFFlashXMLTUIOTrackingDataDistributor.m
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

#import "TFFlashXMLTUIOTrackingDataDistributor.h"

#import "TFFlashXMLTUIOGeneration.h"
#import "TFFlashXMLTUIOServer.h"
#import "TFFlashXMLTUIOTrackingDataReceiver.h"


#define	DEFAULT_PORT	(3000)

NSString* kTFFlashXMLTUIOTrackingDataDistributorLocalAddress	= @"kTFFlashXMLTUIOTrackingDataDistributorLocalAddress";
NSString* kTFFlashXMLTUIOTrackingDataDistributorPort			= @"kTFFlashXMLTUIOTrackingDataDistributorPort";

@implementation TFFlashXMLTUIOTrackingDataDistributor

- (id)init
{
	if (nil != (self = [super init])) {
	}
	
	return self;
}

- (void)dealloc
{
	[_localAddr release];
	_localAddr = nil;
	
	[_server release];
	_server = nil;
	
	[super dealloc];
}

- (BOOL)startDistributorWithObject:(id)obj error:(NSError**)error
{	
	NSString* localAddress = nil;
	NSNumber* portNum = nil;
	
	if ([obj isKindOfClass:[NSDictionary class]]) {
		NSDictionary* dict = (NSDictionary*)obj;
		
		localAddress = [dict objectForKey:kTFFlashXMLTUIOTrackingDataDistributorLocalAddress];
		portNum = [dict objectForKey:kTFFlashXMLTUIOTrackingDataDistributorPort];
	}
	
	UInt16 port = (nil != portNum) ? [portNum unsignedShortValue] : DEFAULT_PORT;
	
	if (nil == _server) {
		_server = [[TFFlashXMLTUIOServer alloc] initWithPort:port
											 andLocalAddress:localAddress
													   error:error];
		
		[_localAddr release];
		_localAddr = [[_server sockHost] copy];
		_port = [_server sockPort];
		
		_server.delegate = self;
	}
	
	if (nil == _server)
		return NO;
	
	return [super startDistributorWithObject:obj error:error];
}

- (void)stopDistributor
{
	[_server invalidate];
	[_server release];
	_server = nil;
	
	[super stopDistributor];
}

- (BOOL)canAskReceiversToQuit
{
	return YES;
}

- (void)disconnectTUIOReceiver:(TFFlashXMLTUIOTrackingDataReceiver*)receiver connectionDidDie:(BOOL)connectionDied
{
	if (receiver.owningDistributor == self && nil != [_receivers objectForKey:receiver.receiverID]) {
		@synchronized (_receivers) {
			[[receiver retain] autorelease];
			[_receivers removeObjectForKey:receiver.receiverID];
			
			[receiver receiverShouldQuit];
			
			if (!connectionDied && [delegate respondsToSelector:@selector(trackingDataDistributor:receiverDidDisconnect:)])
				[delegate trackingDataDistributor:self receiverDidDisconnect:receiver];
			else if ([delegate respondsToSelector:@selector(trackingDataDistributor:receiverDidDie:)])
				[delegate trackingDataDistributor:self receiverDidDie:receiver];
		}
	}
}

- (void)distributeTUIODataWithLivingTouches:(NSArray*)livingTouches
							   movedTouches:(NSArray*)movedTouches
								frameNumber:(NSUInteger)frameNumber
{
	NSString* flashXmlTuioMsg = TFFlashXMLTUIOBundle(livingTouches, movedTouches, _localAddr, _port, frameNumber);

	@synchronized (_receivers) {
		for (TFTrackingDataReceiver* receiver in [_receivers allValues])
			[receiver consumeTrackingData:flashXmlTuioMsg];
	}
}

#pragma mark -
#pragma mark TFFlashXMLTUIOServer delegate

- (void)flashXmlTuioServerDidAcceptConnectionWithSocket:(TFIPStreamSocket*)socket
{	
	TFFlashXMLTUIOTrackingDataReceiver* receiver = [[TFFlashXMLTUIOTrackingDataReceiver alloc] initWithConnectedSocket:socket];
	
	if (nil == [_receivers objectForKey:receiver.receiverID] && nil != receiver) {
		receiver.owningDistributor = self;
		
		@synchronized (_receivers) {
			[_receivers setObject:receiver forKey:receiver.receiverID];
		}
		
		if ([delegate respondsToSelector:@selector(trackingDataDistributor:receiverDidConnect:)])
			[delegate trackingDataDistributor:self receiverDidConnect:receiver];
	}
	
	[receiver release];
}

@end
