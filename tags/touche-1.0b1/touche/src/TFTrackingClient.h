//
//  TFTrackingClient.h
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

extern NSString* kToucheTrackingClientInfoName;
extern NSString* kToucheTrackingClientInfoHumanReadableName;
extern NSString* kToucheTrackingClientInfoVersion;
extern NSString* kToucheTrackingClientInfoIcon;

@interface TFTrackingClient : NSObject <TFTrackingClientProtocol> {
	id			delegate;

	id			_server;
	BOOL		isConnected;
	NSString*	_clientName;
}

@property (assign) id delegate;
@property (readonly) BOOL isConnected;

- (BOOL)connectWithName:(NSString*)clientName;
- (BOOL)connectWithName:(NSString*)clientName error:(NSError**)error;
- (BOOL)connectWithName:(NSString*)clientName serviceName:(NSString*)serviceName server:(NSString*)serverName error:(NSError**)error;
- (void)disconnect;

- (NSScreen*)screen;
- (CGFloat)screenPixelsPerCentimeter;
- (CGFloat)screenPixelsPerInch;

@end

@interface NSObject (TFTrackingClientDelegate)
- (void)client:(TFTrackingClient*)client didGetDisconnectedWithError:(NSError*)error;
- (void)serverConnectionHasDiedForClient:(TFTrackingClient*)client;
- (NSDictionary*)infoDictionaryForClient:(TFTrackingClient*)client;
- (BOOL)clientShouldQuitByServerRequest:(TFTrackingClient*)client;
- (void)touchesDidBegin:(NSSet*)touches viaClient:(TFTrackingClient*)client;
- (void)touchesDidUpdate:(NSSet*)touches viaClient:(TFTrackingClient*)client;
- (void)touchesDidEnd:(NSSet*)touches viaClient:(TFTrackingClient*)client;
@end
