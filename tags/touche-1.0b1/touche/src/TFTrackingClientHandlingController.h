//
//  TFTrackingClientHandlingController.h
//  Touché
//
//  Created by Georg Kaindl on 24/3/08.
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
//

#import <Cocoa/Cocoa.h>

@class TFTrackingClient;
@class TFServerTouchQueue;

@interface TFTrackingClientHandlingController : NSObject {
	TFTrackingClient*		client;
	BOOL					isRunning;

	TFServerTouchQueue*		_queue;
	NSThread*				_thread;
}

@property (readonly) TFTrackingClient* client;
@property (readonly) BOOL isRunning;

- (id)initWithClient:(TFTrackingClient*)theClient;
- (void)tellClientToQuit;
- (void)disconnectWithError:(NSError*)error;

- (void)queueTouchesForForwarding:(NSDictionary*)touches;
- (void)forwardTouchesInThread;
- (void)stop;

@end
