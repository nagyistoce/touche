//
//  TFTrackingDataReceiver.h
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

#import "TFTrackingDataReceiverInfoDictKeys.h"


@class TFTrackingDataDistributor;

@interface TFTrackingDataReceiver : NSObject {
@protected
	BOOL							active, connected;
	NSString*						receiverID;
	TFTrackingDataDistributor*		owningDistributor;
	NSDictionary*					infoDictionary;
}

@property (readonly, getter=isActive) BOOL active;
@property (readonly, getter=isConnected) BOOL connected;
@property (readonly) NSString* receiverID;
@property (assign) TFTrackingDataDistributor* owningDistributor;
@property (readonly) NSDictionary* infoDictionary;

- (void)receiverShouldQuit;
- (void)consumeTrackingData:(id)trackingData;

- (NSMenu*)contextualMenuForReceiver;

#pragma mark -
#pragma mark NSCopying protocol

- (id)copyWithZone:(NSZone *)zone;

@end
