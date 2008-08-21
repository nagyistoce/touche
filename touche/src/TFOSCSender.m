//
//  TFOSCSender.m
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

#import "TFOSCSender.h"

#import <BBOSC/BBOSCPacket.h>

#import "TFIPUDPSocket.h"


@implementation TFOSCSender

- (id)init
{
	if (nil != (self = [super init])) {
		_socket = [[TFIPUDPSocket alloc] init];
	}
	
	return self;
}

- (void)dealloc
{
	[_socket release];
	_socket = nil;
	
	[super dealloc];
}

- (BOOL)setPeerName:(NSString*)name port:(UInt16)port
{
	BOOL success = NO;
	
	if (![_socket isConnected])
		success = [_socket setPeer:name onPort:port];
	
	return success;
}

- (void)sendOSCPacket:(BBOSCPacket*)packet to:(NSData*)sockAddr
{
	NSData* packetData = [packet packetizedData];
	
	if (0 < [packetData length])
		[_socket sendData:packetData toEndpoint:sockAddr];
}

@end
