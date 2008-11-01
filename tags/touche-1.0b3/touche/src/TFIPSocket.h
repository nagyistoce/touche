//
//  TFIPSocket.h
//  Touché
//
//  Created by Georg Kaindl on 18/8/08.
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

#import <netinet/in.h>

#import "TFSocket.h"


@interface TFIPSocket : TFSocket {
@protected	
	int						_sockType;
	BOOL					_socketBound, _socketConnected, _socketListening;
	int						_lastErrorCode;
	struct sockaddr_in		_peerSA;
}

@property (nonatomic, readonly, getter=isBound) BOOL _socketBound;
@property (nonatomic, readonly, getter=isConnected) BOOL _socketConnected;
@property (nonatomic, readonly, getter=isListening) BOOL _socketListening;

// name can be an IP address string or a DNS name.
+ (BOOL)resolveName:(NSString*)name intoAddress:(in_addr_t*)addrPtr;
+ (NSString*)stringFromIPAddress:(in_addr_t)addr;
+ (NSString*)stringFromSocketAddress:(struct sockaddr_in*)sockAddr;

- (id)init;
- (void)dealloc;

- (BOOL)isConnectionOriented;

- (BOOL)bindToPort:(in_port_t)inPort atAddress:(in_addr_t)inAddr;
- (BOOL)close;
- (BOOL)connectTo:(in_addr_t)addr port:(in_port_t)port;
- (BOOL)open;
- (BOOL)listenWithMaxPendingConnections:(int)maxPendingConnections;
- (BOOL)listenOnPort:(in_port_t)inPort
		   atAddress:(in_addr_t)inAddr
maxPendingConnections:(NSUInteger)maxPendingConnections;

// name can be an IP address string, a DNS name or a local device name.
- (BOOL)resolveName:(NSString*)name intoAddress:(in_addr_t*)addrPtr;

// Convenience. Set up server sockets with a single method call.
// Name can be an IP address string, a DNS name or a local device name.
// For finer configuration granularity, use the socket function wrappers
// above. 
- (BOOL)listenAt:(NSString*)name onPort:(in_port_t)port;

- (BOOL)getPeerName:(struct sockaddr_in *)sockAddr;
- (BOOL)getSockName:(struct sockaddr_in *)sockAddr;

// Convenience
- (NSString*)peerNameString;
- (NSString*)sockNameString;
- (NSString*)peerHostString;
- (NSString*)sockHostString;
- (UInt16)peerPort;
- (UInt16)sockPort;

- (size_t)availableBytes;
- (int)receiveIntoBytes:(void*)bytes
				 length:(size_t)length
		   fromSockAddr:(struct sockaddr_in*)sockAddr;
- (int)sendBytes:(const void*)bytes
		  length:(size_t)length
	  toSockAddr:(const struct sockaddr_in*)sockAddr;

- (int)lastErrorCode; // errno

// subclasses can override these for customized behavior
- (void)handleAvailableData;
- (void)handleConnectionEstablished;
- (void)handleConnectionFailed;
- (void)handleDisconnection;
- (void)handleNewConnection;
- (void)handleWritableState;

@end
