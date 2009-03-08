//
//	Pseudo CFSocket
//
//  Created by Georg Kaindl on 25/2/09.
//
//  Copyright (C) 2009 Georg Kaindl
//
//  This file is part of Touchsmart TUIO.
//
//  Touchsmart TUIO is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as
//  published by the Free Software Foundation, either version 3 of
//  the License, or (at your option) any later version.
//
//  Touchsmart TUIO is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public
//  License along with Touchsmart TUIO. If not, see <http://www.gnu.org/licenses/>.
//

#import <Cocoa/Cocoa.h>

#import <Foundation/NSSelectInputSource.h>

#if defined(WINDOWS)
#import <winsock.h>
#else
#import <sys/socket.h>
#endif

typedef NSInputSource NSRunLoopSource;

typedef struct {
	NSSelectInputSource*		runloopSource;

	CFSocketRef					socket;
	CFSocketCallBack			callback;
	CFSocketContext				context;
	CFOptionFlags				flags;
	CFOptionFlags				enabledCallbacks;
	Boolean						isConnecting;
} _CFSocketDataStruct;

@interface _CFSocketData : NSObject {
	_CFSocketDataStruct	data;
}

- (void)dealloc;
- (_CFSocketDataStruct*)data;

// NSSelectInputSource delegate
-(void)selectInputSource:(NSSelectInputSource*)inputSource selectEvent:(unsigned)selectEvent;
@end

@implementation _CFSocketData

- (void)dealloc
{
	[data.runloopSource invalidate];
	[data.runloopSource release];
	data.runloopSource = nil;
	
	if (data.context.release)
		data.context.release(data.context.info);
	data.context.info = nil;
	
	[super dealloc];
}

- (_CFSocketDataStruct*)data
{
	return &data;
}

-(void)selectInputSource:(NSSelectInputSource *)inputSource selectEvent:(unsigned)selectEvent
{	
	if (selectEvent & NSSelectReadEvent) {
		if (data.enabledCallbacks & kCFSocketReadCallBack) {
			data.callback(data.socket, kCFSocketReadCallBack, NULL, NULL, data.context.info);
		
			if (0 == data.flags & kCFSocketAutomaticallyReenableReadCallBack)
				CFSocketDisableCallBacks(data.socket, kCFSocketReadCallBack);
		} else
			CFSocketDisableCallBacks(data.socket, kCFSocketReadCallBack);
	}
	
	if (selectEvent & NSSelectWriteEvent) {
		if (data.isConnecting && (data.enabledCallbacks & kCFSocketConnectCallBack)) {
			data.callback(data.socket, kCFSocketConnectCallBack, NULL, NULL, data.context.info);
			CFSocketDisableCallBacks(data.socket, kCFSocketConnectCallBack);
		} else if (data.enabledCallbacks & kCFSocketWriteCallBack) {
			data.callback(data.socket, kCFSocketWriteCallBack, NULL, NULL, data.context.info);
		
			if (0 == data.flags & kCFSocketAutomaticallyReenableWriteCallBack)
				CFSocketDisableCallBacks(data.socket, kCFSocketWriteCallBack);
		} else
			CFSocketDisableCallBacks(data.socket, kCFSocketWriteCallBack);
		
		data.isConnecting = NO;
	}
}
@end

void CFSocketPrivateAdjustSelectInputSourceCallbacks(CFSocketRef self, _CFSocketDataStruct* s);

static NSMutableDictionary* _cfSocketDataDict = nil;

#define	SOCKETDATA(socket)	((_CFSocketDataStruct*)[(_CFSocketData*)([_cfSocketDataDict objectForKey:[NSNumber numberWithInt:[(NSSocket*)self fileDescriptor]]]) data])


CFSocketRef CFSocketCreateWithNative(CFAllocatorRef allocator,
									CFSocketNativeHandle native,
									CFOptionFlags enabledCallbacks,
									CFSocketCallBack callback,
									const CFSocketContext *context)
{
	NSSocket* socket = [[NSSocket alloc] initWithFileDescriptor:native];
	
	if (nil != socket) {
		_CFSocketData* d = [[_CFSocketData alloc] init];
		_CFSocketDataStruct* s = [d data];
		s->socket = (CFSocketRef)socket;
		s->callback = callback;
		s->enabledCallbacks = enabledCallbacks;
		s->flags = kCFSocketCloseOnInvalidate;
		memcpy(&s->context, context, sizeof(CFSocketContext));
				
		if (s->context.retain)
			s->context.retain(s->context.info);
						
		if (nil == _cfSocketDataDict)
			_cfSocketDataDict = [[NSMutableDictionary alloc] init];
		
		[_cfSocketDataDict setObject:d forKey:[NSNumber numberWithInt:[socket fileDescriptor]]];
		[d release];
	}
	
	return (CFSocketRef)socket;
}

CFSocketNativeHandle CFSocketGetNative(CFSocketRef self)
{
	return [(NSSocket*)self fileDescriptor];
}

CFOptionFlags CFSocketGetSocketFlags(CFSocketRef self)
{
	CFOptionFlags flags = 0;
	
	_CFSocketDataStruct* s = SOCKETDATA(self);
	if (nil != s)
		flags = s->flags;
	
	return flags;
}

void CFSocketSetSocketFlags(CFSocketRef self, CFOptionFlags flags)
{
	_CFSocketDataStruct* s = SOCKETDATA(self);
	if (nil != s)
		s->flags = flags;
}

CFRunLoopSourceRef CFSocketCreateRunLoopSource(CFAllocatorRef allocator, CFSocketRef self, CFIndex order)
{
	CFRunLoopSourceRef runloopSource = nil;
	
	_CFSocketDataStruct* s = SOCKETDATA(self);
	if (nil != s) {
		if (nil == s->runloopSource) {
			s->runloopSource = [[NSSelectInputSource alloc] initWithSocket:(NSSocket*)self];
			[s->runloopSource setDelegate:[_cfSocketDataDict objectForKey:[NSNumber numberWithInt:[(NSSocket*)self fileDescriptor]]]];
			
			CFSocketEnableCallBacks(self, s->enabledCallbacks);
		}
		
		runloopSource = (CFRunLoopSourceRef)s->runloopSource;
		
		CFSocketPrivateAdjustSelectInputSourceCallbacks(self, s);
	}

	// we're a create-function, so we need to return a retained object.
	return (CFRunLoopSourceRef)[(NSSelectInputSource*)runloopSource retain];
}

CFSocketError CFSocketConnectToAddress(CFSocketRef self, CFDataRef address, CFTimeInterval timeout)
{
	// TODO: timeout is currently ignored
	const struct sockaddr* addr = [(NSData*)address bytes];
	
	CFSocketError err = kCFSocketSuccess;
	if (0 > connect([(NSSocket*)self fileDescriptor], addr, sizeof(struct sockaddr)))
		err = kCFSocketError;
	else {
		_CFSocketDataStruct* s = SOCKETDATA(self);
		s->isConnecting = YES;
		CFSocketPrivateAdjustSelectInputSourceCallbacks(self, s);
	}
	
	return err;
}

void CFSocketPrivateAdjustSelectInputSourceCallbacks(CFSocketRef self, _CFSocketDataStruct* s)
{
	unsigned eventMask = 0;
	if ((s->enabledCallbacks & kCFSocketConnectCallBack && s->isConnecting) ||
		s->enabledCallbacks & kCFSocketWriteCallBack)
		eventMask |= NSSelectWriteEvent;
	if (s->enabledCallbacks & kCFSocketReadCallBack ||
		s->enabledCallbacks & kCFSocketAcceptCallBack)
		eventMask |= NSSelectReadEvent;
	
	[s->runloopSource setSelectEventMask:eventMask];
}

void CFSocketDisableCallBacks(CFSocketRef self, CFOptionFlags flags)
{
	_CFSocketDataStruct* s = SOCKETDATA(self);
	
	if (nil != s)
		s->enabledCallbacks &= ~flags;
	
	CFSocketPrivateAdjustSelectInputSourceCallbacks(self, s);
}

void CFSocketEnableCallBacks(CFSocketRef self, CFOptionFlags flags)
{
	_CFSocketDataStruct* s = SOCKETDATA(self);
	
	if (nil != s)
		s->enabledCallbacks |= flags;
	
	CFSocketPrivateAdjustSelectInputSourceCallbacks(self, s);
}

void CFSocketInvalidate(CFSocketRef self)
{
	NSInteger fd = [(NSSocket*)self fileDescriptor];
	
	_CFSocketDataStruct* s = SOCKETDATA(self);
	if (nil != s) {
		if (nil != s->runloopSource) {
			[s->runloopSource setDelegate:nil];
			[s->runloopSource invalidate];
			[s->runloopSource autorelease];
			s->runloopSource = nil;
		}
		
		if (s->flags & kCFSocketCloseOnInvalidate)
			[(NSSocket*)self close];
		
		if (s->context.release)
			s->context.release(s->context.info);
	}
	
	id sockData = [_cfSocketDataDict objectForKey:[NSNumber numberWithInt:fd]];
	[[sockData retain] autorelease];
	
	[_cfSocketDataDict removeObjectForKey:[NSNumber numberWithInt:fd]];
}