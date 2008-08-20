//
//  TFIPDatagramSocket.h
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

#import "TFIPSocket.h"


@class TFIPDatagramSocket;

@interface NSObject (TFIPDatagramSocketDelegate)
- (void)socketHadReadWriteError:(TFIPDatagramSocket*)socket;
@end

@interface TFIPDatagramSocket : TFIPSocket {
@protected
	NSMutableDictionary*		_inQueue;
	NSMutableDictionary*		_outQueue;
	NSUInteger					_availDataCount;
	
	struct {
		unsigned int delegateHasReadWriteError:1;
	} _datagramDelegateCapabilities;
}

- (id)init;
- (void)dealloc;

- (void)setDelegate:(id)newDelegate;

- (BOOL)isConnectionOriented;

- (BOOL)connectTo:(in_addr_t)addr port:(in_port_t)port;

// Convenience. Associate a datagram socket with a single method call.
// Name can be an IP address string, a DNS name or a local device name.
// For finer configuration granularity, use the socket function wrappers
// above. 
- (BOOL)setPeer:(NSString*)name onPort:(in_port_t)port;

- (size_t)recvfrom:(void*)bytes length:(size_t)length endpoint:(NSData**)sockAddr;
- (void)sendto:(const void*)bytes length:(size_t)length endpoint:(NSData*)sockAddr;

// convenience methods
- (NSData*)receiveDataFromEndpoint:(NSData**)sockAddr;
- (NSData*)receiveDataOfLength:(size_t)length fromEndpoint:(NSData**)sockAddr;
- (size_t)receiveOntoData:(NSMutableData*)data fromEndpoint:(NSData**)sockAddr;
- (size_t)receiveOntoData:(NSMutableData*)data length:(size_t)length fromEndpoint:(NSData**)sockAddr;
- (NSString*)receiveStringFromEndpoint:(NSData**)sockAddr;
- (NSString*)receiveStringWithEncoding:(NSStringEncoding)encoding fromEndpoint:(NSData**)sockAddr;
- (size_t)receiveOntoString:(NSMutableString*)str fromEndpoint:(NSData**)sockAddr;
- (size_t)receiveOntoString:(NSMutableString*)str encoding:(NSStringEncoding)encoding fromEndpoint:(NSData**)sockAddr;

- (void)sendData:(NSData*)data toEndpoint:(NSData*)sockAddr;
- (void)sendString:(NSString*)string toEndpoint:(NSData*)sockAddr;
- (void)sendString:(NSString*)string encoding:(NSStringEncoding)encoding toEndpoint:(NSData*)sockAddr;

- (void)handleConnectCallbackWithData:(const void*)data;
- (void)handleReadCallbackWithData:(const void*)data;
- (void)handleWriteCallbackWithData:(const void*)data;

- (void)handleAvailableData;
- (void)handleWritableState;
- (void)handleSocketError;

@end
