//
//  TFDOTrackingDataReceiver.h
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

#import "TFTrackingDataReceiver.h"


@class TFDOTrackingClient;
@class TFThreadMessagingQueue;

@interface TFDOTrackingDataReceiver : TFTrackingDataReceiver {
@protected
	TFDOTrackingClient*		client;
	BOOL					running;

	NSMenu*					_contextualMenu;

	UInt64					_sequenceNumber;
	TFThreadMessagingQueue*	_queue;
	NSThread*				_thread;
}

@property (readonly) TFDOTrackingClient* client;
@property (readonly, getter=isRunning) BOOL running;

+ (NSString*)localNameForClientName:(NSString*)string;

- (void)receiverShouldQuit;
- (NSMenu*)contextualMenuForReceiver;
- (void)consumeTrackingData:(id)trackingData;

- (id)initWithClient:(TFDOTrackingClient*)theClient;
- (void)disconnectWithError:(NSError*)error;

- (void)stop;

@end
