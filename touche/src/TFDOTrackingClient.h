//
//  TFDOTrackingClient.h
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
#import "TFDOTrackingCommProtocols.h"
#import "TFTrackingDataReceiverInfoDictKeys.h"

@interface TFDOTrackingClient : NSObject <TFDOTrackingClientProtocol> {
	id			delegate;

@protected
	BOOL		connected;
	float		minimumMotionDistanceForUpdate;
	NSThread*	deliveryThread;
	
	NSString*	_clientName;
	id			_server;
	
	UInt64					_expectedSequenceNumber;
	NSMutableDictionary*	_orderingQueue;
	
	NSMutableDictionary*	_blobPositions;	// blob label => blob
	
	struct {
		unsigned int hasDidGetDisconnected:1;
		unsigned int hasServerConnectionDied:1;
		unsigned int hasInfoDictionary:1;
		unsigned int hasShouldQuitByServerRequest:1;
		unsigned int hasTouchesDidBegin:1;
		unsigned int hasTouchesDidUpdate:1;
		unsigned int hasTouchesDidEnd:1;
	} _delegateCapabilities;
}

@property (assign) id delegate;
@property (readonly, getter=isConnected) BOOL connected;
@property (retain) NSThread* deliveryThread;
@property (assign) float minimumMotionDistanceForUpdate;

- (void)setDelegate:(id)newDelegate;

- (BOOL)connectWithName:(NSString*)clientName;
- (BOOL)connectWithName:(NSString*)clientName error:(NSError**)error;
- (BOOL)connectWithName:(NSString*)clientName serviceName:(NSString*)serviceName server:(NSString*)serverName error:(NSError**)error;
- (void)disconnect;

- (NSScreen*)screen;
- (CGFloat)screenPixelsPerCentimeter;
- (CGFloat)screenPixelsPerInch;

@end

@interface NSObject (TFDOTrackingClientDelegate)
- (void)client:(TFDOTrackingClient*)client didGetDisconnectedWithError:(NSError*)error;
- (void)serverConnectionHasDiedForClient:(TFDOTrackingClient*)client;
- (NSDictionary*)infoDictionaryForClient:(TFDOTrackingClient*)client;
- (BOOL)clientShouldQuitByServerRequest:(TFDOTrackingClient*)client;
- (void)touchesDidBegin:(NSSet*)touches viaClient:(TFDOTrackingClient*)client;
- (void)touchesDidUpdate:(NSSet*)touches viaClient:(TFDOTrackingClient*)client;
- (void)touchesDidEnd:(NSSet*)touches viaClient:(TFDOTrackingClient*)client;
@end
