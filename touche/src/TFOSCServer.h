//
//  TFOSCServer.h
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

#import <Cocoa/Cocoa.h>


@class TFOSCServer;

@interface NSObject (TFOSCServerDelegate)
- (void)oscServer:(TFOSCServer*)server didReceiveOSCPacket:(NSData*)packet from:(NSData*)framAddr;
@end

@class TFIPUDPSocket, TFSocket, BBOSCPacket;

@interface TFOSCServer : NSObject {
@protected
	id					delegate;
	BOOL				_delegateHasDispatchMethod;
	TFIPUDPSocket*		_socket;
}

@property (nonatomic, assign) id delegate;

- (id)init;
- (id)initWithPort:(UInt16)port;
- (id)initWithPort:(UInt16)port andLocalAddress:(NSString*)localAddress; // designated initializer
- (id)initWithPort:(UInt16)port andLocalDevice:(NSString*)localDevice;

- (void)setDelegate:(id)newDelegate;

- (void)sendOSCPacket:(BBOSCPacket*)packet to:(NSData*)sockAddr; // sockAddr = struct sockaddr_in within NSData

#pragma mark -
#pragma mark TFIPUDPSocket delegate

- (void)socket:(TFSocket*)socket dataIsAvailableWithLength:(NSUInteger)dataLength;

@end
