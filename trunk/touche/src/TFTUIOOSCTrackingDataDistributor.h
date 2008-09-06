//
//  TFTUIOOSCTrackingDataDistributor.h
//  Touché
//
//  Created by Georg Kaindl on 24/8/08.
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

#import "TFTrackingDataDistributor.h"


@class TFTUIOOSCServer, TFTUIOOSCTrackingDataReceiver, TFThreadMessagingQueue, BBOSCPacket;

@interface TFTUIOOSCTrackingDataDistributor : TFTrackingDataDistributor {
	float					motionThreshold;

@protected
	TFTUIOOSCServer*		_server;
	NSThread*				_thread;
	TFThreadMessagingQueue*	_queue;
	
	NSMutableDictionary*	_blobPositions;	// blob label => position
}

@property (nonatomic, assign) float motionThreshold;

- (id)init;
- (void)dealloc;

- (BOOL)startDistributorWithObject:(id)obj error:(NSError**)error;
- (void)stopDistributor;

- (BOOL)canAskReceiversToQuit;
- (void)distributeTrackingDataDictionary:(NSDictionary*)trackingDict;

- (BOOL)addTUIOClientAtHost:(NSString*)host port:(UInt16)port error:(NSError**)error;
- (void)removeTUIOClient:(TFTUIOOSCTrackingDataReceiver*)client;

- (void)sendTUIOPacket:(BBOSCPacket*)packet toEndpoint:(NSData*)sockAddr;

@end
