//
//  TFFlashXMLTUIOTrackingDataDistributor.h
//  Touché
//
//  Created by Georg Kaindl on 6/9/08.
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

#import <Foundation/Foundation.h>

#import "TFTUIOTrackingDataDistributor.h"


@class TFFlashXMLTUIOServer, TFFlashXMLTUIOTrackingDataReceiver, TFIPStreamSocket;

extern NSString* kTFFlashXMLTUIOTrackingDataDistributorLocalAddress;
extern NSString* kTFFlashXMLTUIOTrackingDataDistributorPort;

@interface TFFlashXMLTUIOTrackingDataDistributor : TFTUIOTrackingDataDistributor {
@protected
	TFFlashXMLTUIOServer*			_server;
	NSString*						_localAddr;
	UInt16							_port;
}

- (id)init;
- (void)dealloc;

- (BOOL)startDistributorWithObject:(id)obj error:(NSError**)error;
- (void)stopDistributor;

- (BOOL)canAskReceiversToQuit;

- (void)disconnectTUIOReceiver:(TFFlashXMLTUIOTrackingDataReceiver*)receiver connectionDidDie:(BOOL)connectionDied;

- (void)distributeTUIODataWithLivingTouches:(NSArray*)livingTouches
							   movedTouches:(NSArray*)movedTouches
								frameNumber:(NSUInteger)frameNumber;

#pragma mark -
#pragma mark TFFlashXMLTUIOServer delegate

- (void)flashXmlTuioServerDidAcceptConnectionWithSocket:(TFIPStreamSocket*)socket;

@end
