//
//  TFTrackingDataDistributor.h
//  Touché
//
//  Created by Georg Kaindl on 22/8/08.
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


extern NSString* kToucheTrackingDistributorDataNewTouchesKey;
extern NSString* kToucheTrackingDistributorDataUpdatedTouchesKey;
extern NSString* kToucheTrackingDistributorDataEndedTouchesKey;

@class TFTrackingDataDistributor, TFTrackingDataReceiver;

@interface NSObject (TFTrackingDataDistributorDelegate)
- (void)trackingDataDistributor:(TFTrackingDataDistributor*)distributor
			 receiverDidConnect:(TFTrackingDataReceiver*)receiver;
- (void)trackingDataDistributor:(TFTrackingDataDistributor*)distributor 
				 receiverDidDie:(TFTrackingDataReceiver*)receiver;
- (void)trackingDataDistributor:(TFTrackingDataDistributor*)distributor
		  receiverDidDisconnect:(TFTrackingDataReceiver*)receiver;
// TODO: distributor should be able to report an error object
@end

@interface TFTrackingDataDistributor : NSObject {
@protected
	id						delegate;
	NSMutableDictionary*	_receivers;		// receiverID => receiver
}

@property (nonatomic, assign) id delegate;

- (id)init;
- (void)dealloc;

- (BOOL)startDistributorWithObject:(id)obj error:(NSError**)error;
- (void)stopDistributor;

- (BOOL)canAskReceiversToQuit;
- (void)askReceiverToQuit:(TFTrackingDataReceiver*)receiver;
- (void)distributeTrackingDataDictionary:(NSDictionary*)trackingDict;

@end
