//
//  TFIPStreamSocket.m
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

#import "TFIPStreamSocket.h"


#define DEFAULT_CONNECT_TIMEOUT	(5.0)

@interface TFIPStreamSocket (PrivateMethods)
- (id)_initWithConnectedNativeHandle:(CFSocketNativeHandle)bsdSocket;
- (void)_connectTimeoutFired:(NSTimer*)timer;
- (BOOL)_readFromSocket;
- (BOOL)_writeToSocket;
@end

@implementation TFIPStreamSocket

- (id)init
{
	if (nil != (self = [super init])) {
		_inBuffer = [[NSMutableData alloc] init];
	}
	
	return self;
}

- (void)dealloc
{
	[_inBuffer release];
	_inBuffer = nil;
	
	[_outBuffer release];
	_outBuffer = nil;
	
	[_connectionTimer invalidate];
	[_connectionTimer release];
	_connectionTimer = nil;
	
	[super dealloc];
}

- (void)setDelegate:(id)newDelegate
{
	[super setDelegate:newDelegate];
	
	_streamDelegateCapabilities.delegateHasConnectionTimeout =
		[delegate respondsToSelector:@selector(socket:connectionAttemptDidTimeOutAfter:)];
	
	_streamDelegateCapabilities.delegateHasConnectionFailed =
		[delegate respondsToSelector:@selector(socketConnectionAttemptFailed:)];
	
	_streamDelegateCapabilities.delegateHasGotDisconnected =
		[delegate respondsToSelector:@selector(socketGotDisconnected:)];
	
	_streamDelegateCapabilities.delegateHasConnectionAccepted =
		[delegate respondsToSelector:@selector(socket:didAcceptConnectionWithSocket:)];
	
	_streamDelegateCapabilities.delegateHasConnectionEstablished = 
		[delegate respondsToSelector:@selector(socketDidEstablishConnection:)];
}

- (BOOL)isConnectionOriented
{
	return YES;
}

- (BOOL)connectTo:(in_addr_t)addr port:(in_port_t)port
{
	return [self connectTo:addr port:port timeout:0];
}

- (BOOL)connectTo:(in_addr_t)addr port:(in_port_t)port timeout:(NSTimeInterval)timeout
{
	if (nil != _connectionTimer)
		return NO;
	
	BOOL success = [super connectTo:addr port:port];
	
	if (success) {
		[_inBuffer setLength:0];
		
		if (0 < timeout)
			_connectionTimer = [[NSTimer scheduledTimerWithTimeInterval:timeout
																 target:self
															   selector:@selector(_connectTimeoutFired:)
															   userInfo:nil
																repeats:NO] retain];
	}
	
	return success;
}

- (TFIPStreamSocket*)acceptConnection
{	
	CFSocketNativeHandle bsdSocket = [self nativeSocketHandle];
	if (bsdSocket < 0)
		return nil;
	
	struct sockaddr_in socketAddress;
	socklen_t socketAddressSize = sizeof(socketAddress);
	
	CFSocketNativeHandle socketDescriptor =
	accept(bsdSocket, (struct sockaddr*)&socketAddress, &socketAddressSize);
	
	if (socketDescriptor < 0)
		return nil;
	
	TFSocket* newSocket = [[[self class] alloc] _initWithConnectedNativeHandle:socketDescriptor];
	
	if(nil == newSocket)
		(void)close(socketDescriptor);
	
	return [newSocket autorelease];
}

- (BOOL)connectTo:(NSString*)name onPort:(in_port_t)port
{
	if (0 == port)
		return NO;

	if (![self cfSocketCreated])
		if (![self open])
			return NO;
	
	in_addr_t addr = htonl(INADDR_ANY);
	if (nil != name && ![self resolveName:name intoAddress:&addr])
		return NO;
	
	return [self connectTo:addr port:port timeout:DEFAULT_CONNECT_TIMEOUT];
}

- (size_t)read:(void *)bytes length:(size_t)length
{	
	if(0 == [_inBuffer length])
		return 0;
	
	size_t amountToRead = MIN(length, [_inBuffer length]);
	
	[_inBuffer getBytes:bytes length:amountToRead];
	[_inBuffer replaceBytesInRange:NSMakeRange(0, amountToRead) withBytes:NULL length:0];
	
	return amountToRead;
}

- (NSData*)readData
{
	return [self readDataOfLength:[_inBuffer length]];
}

- (NSData*)readDataOfLength:(size_t)length
{
	NSData* data = nil;
	
	if (0 < [_inBuffer length]) {
		size_t amountToRead = MIN(length, [_inBuffer length]);
		
		data = [NSData dataWithBytes:[_inBuffer bytes] length:amountToRead];
		
		[_inBuffer replaceBytesInRange:NSMakeRange(0, amountToRead) withBytes:NULL length:0];
	}
	
	return data;
}

- (size_t)readOntoData:(NSMutableData*)data
{
	return [self readOntoData:data length:[_inBuffer length]];
}

- (size_t)readOntoData:(NSMutableData*)data length:(size_t)length
{
	size_t amountToRead = 0;
	
	if (0 < [_inBuffer length]) {
		amountToRead = MIN(length, [_inBuffer length]);
		
		[data appendBytes:[_inBuffer bytes] length:amountToRead];
		[_inBuffer replaceBytesInRange:NSMakeRange(0, amountToRead) withBytes:NULL length:0];
	}
	
	return amountToRead;
}

- (NSString*)readString
{
	return [self readStringWithEncoding:NSUTF8StringEncoding];
}

- (NSString*)readStringWithEncoding:(NSStringEncoding)encoding
{
	NSString* string = nil;
	
	if (0 < [_inBuffer length]) {	
		string = [[[NSString alloc] initWithData:_inBuffer encoding:encoding] autorelease];
		[_inBuffer setLength:0];
	}
	
	return string;
}

- (size_t)readOntoString:(NSMutableString*)str
{
	return [self readOntoString:str encoding:NSUTF8StringEncoding];
}

- (size_t)readOntoString:(NSMutableString*)str encoding:(NSStringEncoding)encoding
{
	size_t amountRead = 0;
	
	NSString* newStr = [self readStringWithEncoding:encoding];
	if (nil != newStr) {
		[str appendString:newStr];
		amountRead = [newStr length];
	}
	
	return amountRead;
}

- (void)write:(const void*)bytes length:(size_t)length
{
	if (0 != length && NULL != bytes && [self isConnected]) {
		if(nil == _outBuffer)
			_outBuffer = [[NSMutableData alloc] initWithCapacity:length];
		
		[_outBuffer appendBytes:bytes length:length];
		
		(void)[self _writeToSocket];
	}
}

- (void)writeData:(NSData*)data
{
	[self write:[data bytes] length:[data length]];
}

- (void)writeString:(NSString*)string
{
	[self writeString:string encoding:NSUTF8StringEncoding];
}

- (void)writeString:(NSString*)string encoding:(NSStringEncoding)encoding
{
	const char* bytes = [string cStringUsingEncoding:encoding];
	size_t len = strlen(bytes) + 1; // + 1, because we'll send the 0-termination too.
	
	[self writeData:[NSData dataWithBytes:bytes length:len]];
}

- (int)connectionErrorCode
{
	return _connectionErrorCode;
}

- (BOOL)connectionWasRefused
{
	return (ECONNREFUSED == _connectionErrorCode);
}

- (void)handleConnectCallbackWithData:(const void*)data
{
	// this is for TCP
	// if inData != 0, it's a pointer to an errno style erro code
	if (nil != data) {
		_connectionErrorCode = *(int*)data;
		_lastErrorCode = *(int*)data;
		[self handleConnectionFailed];
	} else 
		[self handleConnectionEstablished];
}

- (void)handleReadCallbackWithData:(const void*)data
{
	// If the CFSocketRef is in a listening state, we have a new connection.
	// If not, data is available on the socket.
	if ([self isListening])
		[self handleNewConnection];
	else
		[self handleAvailableData];
}

- (void)handleWriteCallbackWithData:(const void*)data
{
	[self handleWritableState];
}

- (void)handleAvailableData
{	
	NSUInteger curDataLen = [_inBuffer length];
	
	(void)[self _readFromSocket];

	if ([_inBuffer length] > curDataLen && _delegateCapabilities.delegateHasDataAvailable)
		[delegate socket:self dataIsAvailableWithLength:[_inBuffer length]];
}

- (void)handleConnectionEstablished
{	
	_socketConnected = YES;
	(void)[self getPeerName:&self->_peerSA];
	
	if(_streamDelegateCapabilities.delegateHasConnectionEstablished)
		[delegate socketDidEstablishConnection:self];
	
	// Attempt to write any data that has already been added to our outgoing buffer
	[self _writeToSocket];
}

- (void)handleConnectionFailed
{
	[self close];
	
	if (_streamDelegateCapabilities.delegateHasConnectionFailed)
		[delegate socketConnectionAttemptFailed:self];
}

- (void)handleDisconnection
{
	[self close];
	
	if (_streamDelegateCapabilities.delegateHasGotDisconnected)
		[delegate socketGotDisconnected:self];
}

- (void)handleNewConnection
{
	TFIPStreamSocket* connectionSocket;
	
	while (nil != (connectionSocket = [self acceptConnection])) {
		if (_streamDelegateCapabilities.delegateHasConnectionAccepted)	
			[delegate socket:self didAcceptConnectionWithSocket:connectionSocket];
	}
}

- (void)handleWritableState
{
	(void)[self _writeToSocket];
}

- (id)_initWithConnectedNativeHandle:(CFSocketNativeHandle)bsdSocket
{
	if(nil != (self = [self init])) {		
		[self createCFSocketWithNativeHandle:bsdSocket];
		
		if (![self cfSocketCreated]) {
			[self release];
			self = nil;
		} else {
			_socketConnected = YES;
			(void)[self getPeerName:&self->_peerSA]; 
		}
	}
	
	return self;
}

- (void)_connectTimeoutFired:(NSTimer*)timer
{
	if (timer == _connectionTimer) {
		NSTimeInterval timeout = [timer timeInterval];
		[_connectionTimer release];
		_connectionTimer = nil;
	
		if (_streamDelegateCapabilities.delegateHasConnectionTimeout)
			[delegate socket:self connectionAttemptDidTimeOutAfter:timeout];
	}
}

- (BOOL)_readFromSocket
{
	BOOL success = NO;
	size_t availableBytes = [self availableBytes];
	
	if (availableBytes > 0) {
		unsigned char bytes[availableBytes];
		
		if (NULL != bytes) {
			int bytesRead = [self receiveIntoBytes:bytes
											length:availableBytes
									  fromSockAddr:NULL];
			
			
			if(0 < bytesRead) {
				success = YES;
				
				[_inBuffer appendBytes:bytes length:(NSUInteger)bytesRead];
			} else if (0 == bytesRead) {
				// we've been disconnected
				[self handleDisconnection];
			} else {
				// amountRead < 0
				if (EAGAIN != _lastErrorCode && EWOULDBLOCK != _lastErrorCode)
					// if we can't read for any other reason than no data available,
					// assume we were disconnected
					[self handleDisconnection];
			}
		}
	} else {
		// if we got called, even though there's nothing to read, we've been disconnected
		[self handleDisconnection];
	}
	
	return success;
}

- (BOOL)_writeToSocket
{
	BOOL success = NO;

	if ([self isConnected] && 0 < [_outBuffer length]) {
		int amountSent = [self sendBytes:[_outBuffer bytes]
								  length:[_outBuffer length]
							  toSockAddr:&self->_peerSA];
		
		if (0 > amountSent && EWOULDBLOCK != _lastErrorCode) {
			[self handleDisconnection];
		} else {
			success = YES;
			
			[_outBuffer replaceBytesInRange:NSMakeRange(0, amountSent) withBytes:NULL length:0];
			
			if (_delegateCapabilities.delegateHasDataSent)
				[delegate socket:self didSendDataOfLength:(NSUInteger)amountSent];
		}
	}
	
	return success;
}

@end
