//
//  TFSocket.m
//  Touché
//
//  Created by Georg Kaindl on 17/8/08.
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

#import "TFSocket.h"

#import <fcntl.h>
#import <signal.h>

#if defined(WINDOWS)
#import <winsock.h>
#endif

static void _tfSocketCallback(CFSocketRef socketRef,
							  CFSocketCallBackType callbackType,
							  CFDataRef address,
							  const void* data,
							  void* context);

@interface TFSocket (PrivateMethods)
- (int)_flagsForSocket:(CFSocketNativeHandle)socket;
- (BOOL)_setFlags:(int)flags forSocket:(CFSocketNativeHandle)socket;
@end

@implementation TFSocket

@synthesize delegate;

+ (id)socket
{
	return [[[self alloc] init] autorelease];
}

+ (void)ignoreBrokenPipes
{
#if !defined(WINDOWS)
	signal(SIGPIPE, SIG_IGN);
#endif
}

- (id)init
{
	if (nil != (self = [super init])) {
	}
	
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (void)setDelegate:(id)newDelegate
{
	delegate = newDelegate;
	
	_delegateCapabilities.delegateHasDataAvailable =
		[delegate respondsToSelector:@selector(socket:dataIsAvailableWithLength:)];
	
	_delegateCapabilities.delegateHasDataSent =
		[delegate respondsToSelector:@selector(socket:didSendDataOfLength:)];
}

- (CFSocketNativeHandle)nativeSocketHandle
{
	if (![self cfSocketCreated])
		return (CFSocketNativeHandle)-1;
	
	return CFSocketGetNative(_cfSocketRef);
}

- (BOOL)scheduleOnCurrentRunLoop
{
	return [self scheduleOnRunLoop:[NSRunLoop currentRunLoop]];
}

- (BOOL)scheduleOnRunLoop:(NSRunLoop*)inRunLoop
{	
	if(![self cfSocketCreated] || NULL != _cfRunLoopSourceRef)
		return NO;
	
	CFRunLoopRef runloop = (CFRunLoopRef)[inRunLoop getCFRunLoop];
	if(NULL == runloop)
		return NO;
	
	_cfRunLoopSourceRef = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _cfSocketRef, 0);
	if(NULL == _cfRunLoopSourceRef)
		return NO;
	
	CFRunLoopAddSource(runloop, _cfRunLoopSourceRef, kCFRunLoopDefaultMode);
	
	return YES;
}

- (void)unscheduleFromRunLoop
{
	if (![self cfSocketCreated] || NULL == _cfSocketRef)
		return;
	
	if (NULL == _cfRunLoopSourceRef || !CFRunLoopSourceIsValid(_cfRunLoopSourceRef))
		return;
	
	CFRunLoopSourceInvalidate(_cfRunLoopSourceRef);
	CFRelease(_cfRunLoopSourceRef);
	
	_cfRunLoopSourceRef = NULL;
}

- (BOOL)cfSocketCreated
{
	return (NULL != _cfSocketRef);
}

- (BOOL)createCFSocketWithNativeHandle:(CFSocketNativeHandle)socket
{
	BOOL success = NO;
	
	CFSocketContext socketContext;
	memset(&socketContext, 0, sizeof(socketContext));
	socketContext.info = self;
	
	CFOptionFlags socketCallbacks = (kCFSocketConnectCallBack | kCFSocketReadCallBack);
	
	int socketFlags = [self _flagsForSocket:socket];
	if (socketFlags >= 0) {
#if defined(WINDOWS)
		unsigned long iMode=1;
		if (SOCKET_ERROR != ioctlsocket(socket, FIONBIO, &iMode)) {
#else
		if ([self _setFlags:(socketFlags | O_NONBLOCK) forSocket:socket]) {
#endif
			_cfSocketRef = CFSocketCreateWithNative(kCFAllocatorDefault,
													socket,
													socketCallbacks,
													&_tfSocketCallback,
													&socketContext);

			if (NULL != _cfSocketRef) {
				CFOptionFlags socketOptions = kCFSocketAutomaticallyReenableReadCallBack;
				CFSocketSetSocketFlags(_cfSocketRef, socketOptions);
				
				success = YES;
			}
		}
	}
	
	return success;
}

- (int)socketFlags
{
	return [self _flagsForSocket:[self nativeSocketHandle]];
}

- (BOOL)setSocketFlags:(int)flags
{
	return [self _setFlags:flags forSocket:[self nativeSocketHandle]];
}

- (BOOL)setSocketFlag:(int)flag
{
	int flags = [self socketFlags];
	return [self setSocketFlags:(flags | flag)];
}

- (BOOL)unsetSocketFlag:(int)flag
{
	int flags = [self socketFlags];
	return [self setSocketFlags:(flags & (~flag))];
}

- (void)handleConnectCallbackWithData:(const void*)data
{
	[self doesNotRecognizeSelector:_cmd];
}

- (void)handleReadCallbackWithData:(const void*)data
{
	[self doesNotRecognizeSelector:_cmd];
}

- (void)handleWriteCallbackWithData:(const void*)data
{
	[self doesNotRecognizeSelector:_cmd];
}

- (int)_flagsForSocket:(CFSocketNativeHandle)socket
{
#if defined(WINDOWS)
	return 0;
#else
	int flags = fcntl(socket, F_GETFL, 0);
	
	return (flags >= 0) ? flags : 0;
#endif
}

- (BOOL)_setFlags:(int)flags forSocket:(CFSocketNativeHandle)socket
{
#if defined(WINDOWS)
	return NO;
#else
	return (fcntl(socket, F_SETFL, flags) != -1);
#endif
}


@end

static void _tfSocketCallback(CFSocketRef socketRef,
							  CFSocketCallBackType callbackType,
							  CFDataRef address,
							  const void* data,
							  void* context)
{	
	TFSocket* socket = (TFSocket*)context;
	
	if (nil == socket)
		return;
	
	switch(callbackType) {
		case kCFSocketConnectCallBack:
			[socket handleConnectCallbackWithData:data];
			break;
			
		case kCFSocketReadCallBack:
			[socket handleReadCallbackWithData:data];
			break;
			
		case kCFSocketWriteCallBack:
			[socket handleWriteCallbackWithData:data];
			break;
			
		default:
			break;
	}
}
