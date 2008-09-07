//
//  TFIPStreamSocket.h
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

#import <netinet/in.h>


@class TFIPStreamSocket;

@interface NSObject (TFIPStreamSocketDelegate)
- (void)socket:(TFIPStreamSocket*)socket didAcceptConnectionWithSocket:(TFIPStreamSocket*)connectionSocket;
- (void)socket:(TFIPStreamSocket*)socket connectionAttemptDidTimeOutAfter:(NSTimeInterval)timeInterval;
- (void)socketConnectionAttemptFailed:(TFIPStreamSocket*)socket;
- (void)socketDidEstablishConnection:(TFIPStreamSocket*)socket;
- (void)socketGotDisconnected:(TFIPStreamSocket*)socket;
@end

@interface TFIPStreamSocket : TFIPSocket {
@protected
	NSMutableData*			_outBuffer;
	NSMutableData*			_inBuffer;
	NSTimer*				_connectionTimer;
	
	int						_connectionErrorCode;
	
	struct {
		unsigned int delegateHasConnectionTimeout:1;
		unsigned int delegateHasGotDisconnected:1;
		unsigned int delegateHasConnectionFailed:1;
		unsigned int delegateHasConnectionAccepted:1;
		unsigned int delegateHasConnectionEstablished:1;
	} _streamDelegateCapabilities;
}

- (id)init;
- (void)dealloc;

- (void)setDelegate:(id)newDelegate;

- (BOOL)isConnectionOriented;

- (BOOL)connectTo:(in_addr_t)addr port:(in_port_t)port;
- (BOOL)connectTo:(in_addr_t)addr port:(in_port_t)port timeout:(NSTimeInterval)timeout;
- (TFIPStreamSocket*)acceptConnection;

// Convenience. Connect a stream socket with a single method call.
// Name can be an IP address string, a DNS name or a local device name.
// For finer configuration granularity, use the socket function wrappers
// above. 
- (BOOL)connectTo:(NSString*)name onPort:(in_port_t)port;

- (size_t)read:(void *)bytes length:(size_t)length;
- (void)write:(const void*)bytes length:(size_t)length;

// convenience methods
- (NSData*)readData;
- (NSData*)readDataOfLength:(size_t)length;
- (size_t)readOntoData:(NSMutableData*)data;
- (size_t)readOntoData:(NSMutableData*)data length:(size_t)length;
- (NSString*)readString;
- (NSString*)readStringWithEncoding:(NSStringEncoding)encoding;
- (size_t)readOntoString:(NSMutableString*)str;
- (size_t)readOntoString:(NSMutableString*)str encoding:(NSStringEncoding)encoding;

- (void)writeData:(NSData*)data;
- (void)writeString:(NSString*)string;
- (void)writeString:(NSString*)string encoding:(NSStringEncoding)encoding;

- (int)connectionErrorCode;
- (BOOL)connectionWasRefused; // convenience method

- (void)handleConnectCallbackWithData:(const void*)data;
- (void)handleReadCallbackWithData:(const void*)data;
- (void)handleWriteCallbackWithData:(const void*)data;

// subclasses can override these for customized behavior
- (void)handleAvailableData;
- (void)handleConnectionEstablished;
- (void)handleConnectionFailed;
- (void)handleDisconnection;
- (void)handleNewConnection;
- (void)handleWritableState;

@end
