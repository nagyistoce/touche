//
//  TFTrackingServer.h
//  Touché
//
//  Created by Georg Kaindl on 5/2/08.
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
#import "TFTrackingCommProtocols.h"

extern NSString* kNewTouchesTrackingClientHandling;
extern NSString* kUpdatedTouchesTrackingClientHandling;
extern NSString* kEndedTouchesTrackingClientHandling;

@interface TFTrackingServer : NSObject <TFTrackingServerProtocol> {
	NSConnection*			_listenConnection;
	NSMutableDictionary*	_clients;
	BOOL					_isRunning;
	id						delegate;
	
	NSThread*				_heartbeatThread;
}

@property (nonatomic, assign) id delegate;

- (BOOL)startServer:(NSString*)serviceName error:(NSError**)error;
- (void)stopServer;
- (void)askClientWithNameToQuit:(NSString*)clientName;

#pragma mark -
#pragma mark TFTrackingServerProtocol

- (BOOL)registerClient:(byref id)client withName:(bycopy NSString*)name error:(bycopy out NSError**)error;
- (void)unregisterClientWithName:(bycopy NSString*)name;

@end

@interface NSObject (TFTrackingServerDelegate)
- (void)clientConnectedWithName:(NSString*)clientName andInfoDictionary:(NSDictionary*)infoDict;
- (void)clientDiedWithName:(NSString*)clientName;
- (void)clientDisconnectedWithName:(NSString*)clientName;
@end
