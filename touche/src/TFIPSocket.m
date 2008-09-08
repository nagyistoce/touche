//
//  TFIPSocket.m
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

#import "TFIPSocket.h"

#import <arpa/inet.h>
#import <sys/socket.h>
#import <sys/time.h>
#import <sys/ioctl.h>
#import <net/if.h>
#import <fcntl.h>
#import <netdb.h>
#import <unistd.h>
#import <net/route.h>
#import <errno.h>


#define DEFAULT_NUM_PENDING_CONNECTIONS (6)

@implementation TFIPSocket

@synthesize _socketBound, _socketConnected, _socketListening;

+ (BOOL)resolveName:(NSString*)name intoAddress:(in_addr_t*)addrPtr
{
	in_addr_t			addr;
	struct in_addr		inAddr;
	const char*			nameString = [name cStringUsingEncoding:NSASCIIStringEncoding];
	BOOL				success = NO;
	
	// try these steps:
	//   1) if it's an address in a.b.c.d form, parse it and return
	//   2) if it's not an address, try to resolve it via DNS
	//   3) fail
	if (0 < inet_aton(nameString, &inAddr)) {
		addr = inAddr.s_addr;
		success = YES;
	} else {
		struct hostent*	hostEntity;
		
		hostEntity = gethostbyname(nameString);
		if(NULL != hostEntity) {
			struct sockaddr_in	sAddr;
			
			bcopy((char*)hostEntity->h_addr, (char*)&sAddr.sin_addr, hostEntity->h_length);
			addr = sAddr.sin_addr.s_addr;
			success = YES;
		}
	}
	
	if (NULL != addrPtr)
		*addrPtr = addr;
	
	return success;
}

+ (NSString*)stringFromIPAddress:(in_addr_t)addr
{
	struct in_addr inAddr;
	inAddr.s_addr = addr;
	
	char* addrStr = inet_ntoa(inAddr);
	return [NSString stringWithCString:addrStr encoding:NSASCIIStringEncoding];
}

+ (NSString*)stringFromSocketAddress:(struct sockaddr_in*)sockAddr
{
	NSString* str = nil;
	
	if (NULL != sockAddr) {
		str = [NSString stringWithFormat:@"%@:%u",
					[self stringFromIPAddress:sockAddr->sin_addr.s_addr],
					ntohs(sockAddr->sin_port)];
	}
	
	return str;
}

- (id)init
{
	if (nil != (self = [super init])) {
		_sockType = -1;		
	}
	
	return self;
}

- (void)dealloc
{	
	[super dealloc];
}

- (BOOL)isConnectionOriented
{
	[self doesNotRecognizeSelector:_cmd];
	return NO;
}

- (BOOL)close
{
	BOOL success = YES;
	
	[self unscheduleFromRunLoop];
	
	if ([self cfSocketCreated]) {
		CFSocketNativeHandle bsdSocket = [self nativeSocketHandle];
		
		if (-1 < bsdSocket)
			success = (-1 < close(bsdSocket));
		
		CFSocketInvalidate(_cfSocketRef);
		CFRelease(_cfSocketRef);
		_cfSocketRef = NULL;
	}
	
	_socketConnected = _socketListening = _socketBound = NO;
	
	return success;
}

- (BOOL)open
{
	if(![self cfSocketCreated]) {
		CFSocketNativeHandle bsdSocket = socket(AF_INET, (int)_sockType, 0);
		
		if(bsdSocket < 0)
			return NO;
		
		if (![self createCFSocketWithNativeHandle:bsdSocket]) {
			(void)close(bsdSocket);
			
			return NO;
		}
	}
	
	return [self cfSocketCreated];
}

- (BOOL)bindToPort:(in_port_t)inPort atAddress:(in_addr_t)inAddr
{	
	if (![self cfSocketCreated] || [self isConnected] || [self isListening] || [self isBound])
		return NO;
	
	CFSocketNativeHandle bsdSocket = [self nativeSocketHandle];
	if(bsdSocket < 0)
		return NO;
	
	// Set SO_REUSEADDR so we can reuse the address immediately
	int socketOptionFlag = 1;
	int result = setsockopt(bsdSocket, SOL_SOCKET, SO_REUSEADDR, &socketOptionFlag,
							(socklen_t)sizeof(socketOptionFlag));
	
	if (result < 0)
		return NO;
	
	struct sockaddr_in socketAddress;
	bzero(&socketAddress, sizeof(socketAddress));
	socketAddress.sin_family = PF_INET;
	socketAddress.sin_addr.s_addr = inAddr;
	socketAddress.sin_port = htons(inPort);
	
	result = bind(bsdSocket, (struct sockaddr*)&socketAddress, (socklen_t)sizeof(socketAddress));
	if(result < 0) {
		NSLog(@"errno: %d\n", errno);
		return NO;
	}
	
	_socketBound = YES;
	
	return YES;	
}

- (BOOL)connectTo:(in_addr_t)addr port:(in_port_t)port
{
	BOOL success = NO;

	if([self cfSocketCreated] && (![self isConnected] || ![self isConnectionOriented]) && ![self isListening]) {
		struct sockaddr_in socketAddress;
	
		bzero(&socketAddress, sizeof(socketAddress));
		socketAddress.sin_addr.s_addr = addr;
		socketAddress.sin_family = PF_INET;
		socketAddress.sin_port = htons(port);
		
		// we connect using CFSocketConntectToAddress than via connect() on the native handle, so that
		// we get the callback properly when the connection is made.
		NSData* socketAddressData = [NSData dataWithBytes:(void*)&socketAddress length:sizeof(socketAddress)];
		int socketError = CFSocketConnectToAddress(_cfSocketRef, (CFDataRef)socketAddressData, -1.0);
		
		success = (socketError != kCFSocketSuccess);
	}
	
	return YES;
}

- (BOOL)listenOnPort:(in_port_t)inPort
		   atAddress:(in_addr_t)inAddr
maxPendingConnections:(NSUInteger)maxPendingConnections
{	
	if (![self cfSocketCreated] || [self isConnected] || [self isListening])
		return NO;
	
	if (![self isBound] && ![self bindToPort:inPort atAddress:inAddr])
		return NO;
	
	// we only need to call listen() for connection-oriented protocols 
	if ([self isConnectionOriented] && ![self listenWithMaxPendingConnections:maxPendingConnections])
		return NO;
	
	return YES;
}

- (BOOL)listenWithMaxPendingConnections:(int)maxPendingConnections
{	
	if(![self cfSocketCreated] || ![self isBound] || [self isConnected] || [self isListening])
		return NO;
	
	CFSocketNativeHandle bsdSocket = [self nativeSocketHandle];
	if(bsdSocket < 0)
		return NO;
	
	int result = listen(bsdSocket, maxPendingConnections);
	if(result < 0)
		return NO;
	
	_socketListening = YES;
	
	return YES;
}

- (BOOL)resolveName:(NSString*)name intoAddress:(in_addr_t*)addrPtr
{
	in_addr_t			addr;
	
	// try these steps:
	//	 1) Try the class method (which tries numeric IPs and DNS name)
	//   2) if it's neither address nor hostname, interpret it as local network interface
	//   3) fail

	if (![[self class] resolveName:name intoAddress:&addr]) {
		struct ifreq ifr;
		struct sockaddr_in *sin;
		const char*	nameString = [name cStringUsingEncoding:NSASCIIStringEncoding];
		
		bzero(&ifr, sizeof(struct ifreq));
		strncpy(ifr.ifr_name, nameString, sizeof(ifr.ifr_name));
		
		sin = (struct sockaddr_in *)&ifr.ifr_addr;
		sin->sin_family = AF_INET;
		
		if (ioctl([self nativeSocketHandle], SIOCGIFADDR, (char *)&ifr) < 0)
			return NO;
		
		*sin = *((struct sockaddr_in*)&ifr.ifr_addr);
		
		addr = sin->sin_addr.s_addr;
	}
	
	if (NULL != addrPtr)
		*addrPtr = addr;
	
	return YES;
}

- (BOOL)listenAt:(NSString*)name onPort:(in_port_t)port
{
	if (![self cfSocketCreated])
		if (![self open])
			return NO;
	
	in_addr_t addr = htonl(INADDR_ANY);
	if (nil != name && ![self resolveName:name intoAddress:&addr])
		return NO;
	
	return ([self listenOnPort:port atAddress:addr maxPendingConnections:DEFAULT_NUM_PENDING_CONNECTIONS]);
}

- (BOOL)connectTo:(NSString*)name atPort:(in_port_t)port
{
	if (![self cfSocketCreated])
		if (![self open])
			return NO;
	
	in_addr_t addr;
	if (nil == name || ![self resolveName:name intoAddress:&addr])
		return NO;
	
	return [self connectTo:addr port:port];
}

- (BOOL)getPeerName:(struct sockaddr_in *)sockAddr
{
	CFSocketNativeHandle bsdSocket = [self nativeSocketHandle];
	if(bsdSocket < 0 || NULL == sockAddr)
		return NO;
	
	socklen_t addressLength = sizeof(struct sockaddr_in);
	return (getpeername(bsdSocket, (struct sockaddr*)sockAddr, &addressLength) >= 0);
}

- (BOOL)getSockName:(struct sockaddr_in *)sockAddr
{
	CFSocketNativeHandle bsdSocket = [self nativeSocketHandle];
	if(bsdSocket < 0 || NULL == sockAddr)
		return NO;
	
	socklen_t addressLength = sizeof(struct sockaddr_in);
	return (getsockname(bsdSocket, (struct sockaddr*)sockAddr, &addressLength) >= 0);
}

- (NSString*)peerNameString
{
	NSString* str = nil;
	struct sockaddr_in sockAddr;
	
	if ([self getPeerName:&sockAddr])
		str = [[self class] stringFromSocketAddress:&sockAddr];
	
	return str;
}

- (NSString*)sockNameString
{
	NSString* str = nil;
	struct sockaddr_in sockAddr;
	
	if ([self getSockName:&sockAddr])
		str = [[self class] stringFromSocketAddress:&sockAddr];
	
	return str;
}

- (NSString*)peerHostString
{
	NSString* str = nil;
	struct sockaddr_in sockAddr;
	
	if ([self getPeerName:&sockAddr])
		str = [[self class] stringFromIPAddress:sockAddr.sin_addr.s_addr];
	
	return str;
}

- (NSString*)sockHostString
{
	NSString* str = nil;
	struct sockaddr_in sockAddr;
	
	if ([self getSockName:&sockAddr])
		str = [[self class] stringFromIPAddress:sockAddr.sin_addr.s_addr];
	
	return str;
}

- (UInt16)peerPort
{
	UInt16 port = 0;
	struct sockaddr_in sockAddr;
	
	if ([self getPeerName:&sockAddr])
		port = ntohs(sockAddr.sin_port);
	
	return port;
}

- (UInt16)sockPort
{
	UInt16 port = 0;
	struct sockaddr_in sockAddr;
	
	if ([self getSockName:&sockAddr])
		port = ntohs(sockAddr.sin_port);
	
	return port;
}

- (int)lastErrorCode
{
	return _lastErrorCode;
}

- (void)handleAvailableData
{	
	[self doesNotRecognizeSelector:_cmd];
}

- (void)handleConnectionEstablished
{	
	[self doesNotRecognizeSelector:_cmd];
}

- (void)handleConnectionFailed
{
	[self doesNotRecognizeSelector:_cmd];
}

- (void)handleDisconnection
{
	[self doesNotRecognizeSelector:_cmd];
}

- (void)handleNewConnection
{
	[self doesNotRecognizeSelector:_cmd];
}

- (void)handleWritableState
{
	[self doesNotRecognizeSelector:_cmd];
}

- (size_t)availableBytes
{
	CFSocketNativeHandle bsdSocket = [self nativeSocketHandle];
	if (bsdSocket < 0)
		return NO;
	
	size_t bytesAvailable = 0;
	if (ioctl(bsdSocket, FIONREAD, &bytesAvailable) == -1) {
		if (errno == EINVAL)
			bytesAvailable = -1;
		else
			bytesAvailable = 0;
	}
	
	return bytesAvailable;
}

- (int)receiveIntoBytes:(void*)bytes
				 length:(size_t)length
		   fromSockAddr:(struct sockaddr_in*)sockAddr
{	
	if (NULL == bytes || 0 == length)
		return 0;
	
	size_t bytesAvailable = [self availableBytes];
	size_t bufLen = (size_t)((0 == bytesAvailable) ? 1 : MIN(bytesAvailable, length));
	
	CFSocketNativeHandle bsdSocket = [self nativeSocketHandle];
	if (bsdSocket < 0)
		return 0;
	
	socklen_t sockLen = 0;
	if (NULL != sockAddr) {
		sockLen = sizeof(struct sockaddr);
		memset(sockAddr, 0, (size_t)sockLen);
	}
	
	int amountRead =
		recvfrom(bsdSocket, bytes, bufLen, 0, (struct sockaddr*)sockAddr, &sockLen);
	
	if (0 > amountRead)
		_lastErrorCode = errno;
	
	return amountRead;
}

- (int)sendBytes:(const void*)bytes
		  length:(size_t)length
	  toSockAddr:(const struct sockaddr_in*)sockAddr
{
	if (NULL == bytes || 0 == length)
		return 0;
	
	CFSocketNativeHandle bsdSocket = [self nativeSocketHandle];
	if (bsdSocket < 0)
		return 0;
	
	socklen_t sockLen = 0;
	if (NULL != sockAddr)
		sockLen = sizeof(struct sockaddr_in);
	
	int amountSent = sendto(bsdSocket, bytes, length, 0, (const struct sockaddr*)sockAddr, sockLen);
	if (length == amountSent) {
		// We managed to write the entire outgoing buffer to the socket
		// Disable the write callback for now since we don't need to know when we are writable again for now
		CFSocketDisableCallBacks(_cfSocketRef, kCFSocketWriteCallBack);
	} else if (0 <= amountSent) {
		// We managed to write some of our buffer to the socket
		// Enable the write callback on our CFSocketRef so we know when the socket is writable again
		CFSocketEnableCallBacks(_cfSocketRef, kCFSocketWriteCallBack);
	} else if (EWOULDBLOCK == errno) {
		// No data has actually been written here
		amountSent = 0;
		_lastErrorCode = errno;
		
		// Enable the write callback on our CFSocketRef so we know when the socket is writable again
		CFSocketEnableCallBacks(_cfSocketRef, kCFSocketWriteCallBack);
	} else {
		// Disable the write callback
		CFSocketDisableCallBacks(_cfSocketRef, kCFSocketWriteCallBack);
		
		_lastErrorCode = errno;
	}
	
	return amountSent;
}

@end
