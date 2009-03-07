//
//  TFIPDatagramSocket.m
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

#import "TFIPDatagramSocket.h"


@interface TFIPDatagramSocket (PrivateMethods)
- (BOOL)_receiveDatagrams;
- (BOOL)_sendDatagrams;
@end


@implementation TFIPDatagramSocket

- (id)init
{
	if (nil != (self = [super init])) {
		_inQueue = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (void)dealloc
{
	[_inQueue release];
	_inQueue = nil;
	
	[_outQueue release];
	_outQueue = nil;
	
	[super dealloc];
}

- (void)setDelegate:(id)newDelegate
{
	[super setDelegate:newDelegate];
	
	_datagramDelegateCapabilities.delegateHasReadWriteError =
		[delegate respondsToSelector:@selector(socketHadReadWriteError:)];
}

- (BOOL)isConnectionOriented
{
	return NO;
}

- (BOOL)connectTo:(in_addr_t)addr port:(in_port_t)port
{
	_socketConnected = ([super connectTo:addr port:port]);
	
	if (_socketConnected) {
		[self getPeerName:&self->_peerSA];
		[_inQueue removeAllObjects];
	}
	
	return _socketConnected;
}

- (BOOL)setPeer:(NSString*)name onPort:(in_port_t)port
{
	if (0 == port)
		return NO;
	
	if (![self cfSocketCreated])
		if (![self open])
			return NO;
	
	in_addr_t addr = htonl(INADDR_ANY);
	if (nil != name && ![self resolveName:name intoAddress:&addr])
		return NO;
	
	return [self connectTo:addr port:port];
}

- (size_t)recvfrom:(void*)bytes length:(size_t)length endpoint:(NSData**)sockAddr
{
	size_t rv = 0;
	
	if (0 <= [_inQueue count]) {
		NSMutableArray* packetQueue = nil;
		NSData* sA;
		
		if (NULL != sockAddr) {
			packetQueue = [_inQueue objectForKey:*sockAddr];
		}
		
		if (nil == packetQueue) {
			sA = [[[_inQueue allKeys] objectAtIndex:0] retain];
			packetQueue = [_inQueue objectForKey:sA];
		} else
			sA = [*sockAddr retain];
		
		NSMutableData* inBuffer = [packetQueue objectAtIndex:0];
		
		size_t amountToRead = MIN(length, [inBuffer length]);
		[inBuffer getBytes:bytes length:amountToRead];
		[inBuffer replaceBytesInRange:NSMakeRange(0, amountToRead) withBytes:NULL length:0];
		
		if (0 >= [inBuffer length])
			[packetQueue removeObjectAtIndex:0];
		
		if (0 >= [packetQueue count])
			[_inQueue removeObjectForKey:sA];
		
		if (NULL != sockAddr)
			*sockAddr = sA;
		
		_availDataCount -= amountToRead;
		
		[sA autorelease];
		rv = amountToRead;
	}
	
	return rv;
}

- (void)sendto:(const void*)bytes length:(size_t)length endpoint:(NSData*)sockAddr
{
	if (NULL != bytes && 0 < length && (nil != sockAddr || [self isConnected])) {
		if (nil == _outQueue)
			_outQueue = [[NSMutableDictionary alloc] init];
	
		if (nil == sockAddr)
			sockAddr = [NSData dataWithBytes:&self->_peerSA length:sizeof(struct sockaddr_in)];
	
		NSMutableArray* packetQueue = [_outQueue objectForKey:sockAddr];
		if (nil == packetQueue) {
			packetQueue = [[NSMutableArray alloc] initWithCapacity:1];
			[_outQueue setObject:packetQueue forKey:sockAddr];
			[packetQueue release];
		}
		
		NSData* outBuffer = [[NSMutableData alloc] initWithBytes:bytes length:length];
		[packetQueue addObject:outBuffer];
		[outBuffer release];
						
		(void)[self _sendDatagrams];
	}
}

- (NSData*)receiveDataFromEndpoint:(NSData**)sockAddr
{
	return [self receiveDataOfLength:(size_t)[self availableBytes] fromEndpoint:sockAddr];
}

- (NSData*)receiveDataOfLength:(size_t)length fromEndpoint:(NSData**)sockAddr
{
	NSData* data = nil;
	
	if (0 < length) {
		size_t amountToRead = MIN(length, [self availableBytes]);
		unsigned char buf[amountToRead];
		
		if (NULL != buf) {
			size_t amountRead = [self recvfrom:buf length:amountToRead endpoint:sockAddr];
			data = [NSData dataWithBytes:buf length:amountRead];
		}
	}
	
	return data;
}

- (size_t)receiveOntoData:(NSMutableData*)data fromEndpoint:(NSData**)sockAddr
{
	return [self receiveOntoData:data length:[self availableBytes] fromEndpoint:sockAddr];
}

- (size_t)receiveOntoData:(NSMutableData*)data length:(size_t)length fromEndpoint:(NSData**)sockAddr
{
	size_t beforeLength = [data length];
	[data appendData:[self receiveDataOfLength:length fromEndpoint:sockAddr]];
	return [data length] - beforeLength;
}

- (NSString*)receiveStringFromEndpoint:(NSData**)sockAddr
{
	return [self receiveStringWithEncoding:NSUTF8StringEncoding fromEndpoint:sockAddr];
}

- (NSString*)receiveStringWithEncoding:(NSStringEncoding)encoding fromEndpoint:(NSData**)sockAddr
{
	NSString* string = nil;
	NSData* data = [self receiveDataFromEndpoint:sockAddr];
	if (nil != data)
		string = [[[NSString alloc] initWithData:data encoding:encoding] autorelease];
	return string;
}

- (size_t)receiveOntoString:(NSMutableString*)str fromEndpoint:(NSData**)sockAddr
{
	return [self receiveOntoString:str encoding:NSUTF8StringEncoding fromEndpoint:sockAddr];
}

- (size_t)receiveOntoString:(NSMutableString*)str encoding:(NSStringEncoding)encoding fromEndpoint:(NSData**)sockAddr
{
	size_t beforeLength = [str length];
	[str appendString:[self receiveStringWithEncoding:encoding fromEndpoint:sockAddr]];
	return [str length] - beforeLength;
}

- (void)sendData:(NSData*)data toEndpoint:(NSData*)sockAddr
{
	[self sendto:[data bytes] length:[data length] endpoint:sockAddr];
}

- (void)sendString:(NSString*)string toEndpoint:(NSData*)sockAddr
{
	[self sendString:string encoding:NSUTF8StringEncoding toEndpoint:sockAddr];
}

- (void)sendString:(NSString*)string encoding:(NSStringEncoding)encoding toEndpoint:(NSData*)sockAddr
{
	const char* bytes = [string cStringUsingEncoding:encoding];
	size_t len = strlen(bytes) + 1; // + 1, because we'll send the 0-termination too.
		
	[self sendData:[NSData dataWithBytes:bytes length:len] toEndpoint:sockAddr];
}

- (void)handleConnectCallbackWithData:(const void*)data
{
	// we will never get this callback on a datagram socket, so do nothing
}

- (void)handleReadCallbackWithData:(const void*)data
{
	[self handleAvailableData];
}

- (void)handleWriteCallbackWithData:(const void*)data
{
	[self handleWritableState];
}

- (void)handleAvailableData
{
	BOOL dataRead = [self _receiveDatagrams];
	
	if (dataRead && _delegateCapabilities.delegateHasDataAvailable)
		[delegate socket:self dataIsAvailableWithLength:_availDataCount];
}

- (void)handleWritableState
{
	(void)[self _sendDatagrams];
}

- (void)handleSocketError
{
	if (_datagramDelegateCapabilities.delegateHasReadWriteError)
		[delegate socketHadReadWriteError:self];
}

- (BOOL)_receiveDatagrams
{
	BOOL success = NO;
	size_t availableBytes = [self availableBytes];
	
	if (availableBytes > 0) {
		struct sockaddr_in sockAddr;
		unsigned char bytes[availableBytes];
		
		if (NULL != bytes) {
			int bytesRead = [self receiveIntoBytes:bytes
											length:availableBytes
									  fromSockAddr:&sockAddr];
			
			
			if (0 < bytesRead) {
				success = YES;
				_availDataCount += _availDataCount;
				
				NSData* sA = [NSData dataWithBytes:&sockAddr length:sizeof(struct sockaddr_in)];
				NSMutableArray* packetQueue = [_inQueue objectForKey:sA];
				if (nil == packetQueue) {
					packetQueue = [[NSMutableArray alloc] initWithCapacity:1];
					[_inQueue setObject:packetQueue forKey:sA];
					[packetQueue release];
				}
				
				NSMutableData* inBuffer = [[NSMutableData alloc] initWithBytes:bytes length:(NSUInteger)bytesRead];
				[packetQueue addObject:inBuffer];
				[inBuffer release];
			} else if (0 > bytesRead) {
				if (EAGAIN != _lastErrorCode && EWOULDBLOCK != _lastErrorCode)
					[self handleSocketError];
			}
		}
	}
	
	return success;
}

- (BOOL)_sendDatagrams
{
	BOOL success = NO;
	
	if (0 < [_outQueue count]) {
		NSData* sA = [[_outQueue allKeys] objectAtIndex:0];
		NSMutableArray* packetQueue = [_outQueue objectForKey:sA];
		NSMutableData* outBuffer = [packetQueue objectAtIndex:0];
		
		int amountSent = [self sendBytes:[outBuffer bytes]
								  length:[outBuffer length]
							  toSockAddr:(const struct sockaddr_in*)[sA bytes]];
				
		if (0 <= amountSent) {
			success = YES;
			
			if (0 < amountSent) {
				[outBuffer replaceBytesInRange:NSMakeRange(0, amountSent) withBytes:NULL length:0];
				if (0 >= [outBuffer length])
					[packetQueue removeObjectAtIndex:0];
				
				if (0 >= [packetQueue count])
					[_outQueue removeObjectForKey:sA];
				
				if (_delegateCapabilities.delegateHasDataSent)
					[delegate socket:self didSendDataOfLength:(NSUInteger)amountSent];
			}
		} else {
			if (EWOULDBLOCK != _lastErrorCode)
				[self handleSocketError];
		}
	}
	
	return success;
}

@end
