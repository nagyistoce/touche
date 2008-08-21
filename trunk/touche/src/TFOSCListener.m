//
//  TFOSCListener.m
//  Touché
//
//  Created by Georg Kaindl on 21/8/08.
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

#import "TFOSCListener.h"

#import "TFIPUDPSocket.h"


#define	DEFAULT_PORT		(4556)

@implementation TFOSCListener

@synthesize delegate;

- (id)init
{
	return [self initWithPort:DEFAULT_PORT];
}

- (id)initWithPort:(UInt16)port
{
	return [self initWithPort:port andLocalAddress:nil];
}

- (id)initWithPort:(UInt16)port andLocalAddress:(NSString*)localAddress
{
	if (nil != (self = [super init])) {
		_socket = [[TFIPUDPSocket alloc] init];
		
		if (![_socket listenAt:localAddress onPort:port]) {
			[self release];
			self = nil;
		}
		
		_socket.delegate = self;
	}
	
	return self;
}

- (id)initWithPort:(UInt16)port andLocalDevice:(NSString*)localDevice
{
	return [self initWithPort:port andLocalAddress:localDevice];
}

- (void)dealloc
{
	[_socket release];
	_socket = nil;
	
	[super dealloc];
}

- (void)setDelegate:(id)newDelegate
{
	delegate = newDelegate;
	
	_delegateHasDispatchMethod = [delegate respondsToSelector:@selector(oscListener:didReceiveOSCPacket:from:)];
}

#pragma mark -
#pragma mark TFIPUDPSocket delegate

- (void)socket:(TFSocket*)socket dataIsAvailableWithLength:(NSUInteger)dataLength
{
	if (socket == _socket) {
		NSData* fromAddr = nil;
		NSData* packet = [_socket receiveDataFromEndpoint:&fromAddr];
		
		// since OSC/UDP apparently doesn't have a "size" field, we have to be faithful that the
		// packet we received actually encapsulates a complete OSC message or bundle...
		if (_delegateHasDispatchMethod)
			[delegate oscListener:self didReceiveOSCPacket:packet from:fromAddr];
	}
}

@end
