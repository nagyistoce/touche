//
//  TFTrackingClient.h
//  Touché
//
//  Created by Georg Kaindl on 5/2/08.
//  Copyright 2008 Georg Kaindl. All rights reserved.
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
