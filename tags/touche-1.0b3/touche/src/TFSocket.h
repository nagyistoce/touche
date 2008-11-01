//
//  TFSocket.h
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

#import <Cocoa/Cocoa.h>


@class TFSocket;

@interface NSObject (TFSocketDelegate)
- (void)socket:(TFSocket*)socket dataIsAvailableWithLength:(NSUInteger)dataLength;
- (void)socket:(TFSocket*)socket didSendDataOfLength:(NSUInteger)dataLength;
@end


@interface TFSocket : NSObject {
	id						delegate;

@protected
	CFSocketRef				_cfSocketRef;
	CFRunLoopSourceRef		_cfRunLoopSourceRef;
	
	struct {
		unsigned int delegateHasDataAvailable:1;
		unsigned int delegateHasDataSent:1;
	} _delegateCapabilities;
}

@property (nonatomic, assign) id delegate;

+ (id)socket;

+ (void)ignoreBrokenPipes;

- (id)init;
- (void)dealloc;

- (void)setDelegate:(id)newDelegate;

- (BOOL)createCFSocketWithNativeHandle:(CFSocketNativeHandle)socket;
- (BOOL)cfSocketCreated;
- (CFSocketNativeHandle)nativeSocketHandle;

- (int)socketFlags;
- (BOOL)setSocketFlags:(int)flags;
- (BOOL)setSocketFlag:(int)flag;
- (BOOL)unsetSocketFlag:(int)flag;

- (BOOL)scheduleOnCurrentRunLoop;
- (BOOL)scheduleOnRunLoop:(NSRunLoop*)inRunLoop;
- (void)unscheduleFromRunLoop;

- (void)handleConnectCallbackWithData:(const void*)data;
- (void)handleReadCallbackWithData:(const void*)data;
- (void)handleWriteCallbackWithData:(const void*)data;

@end
