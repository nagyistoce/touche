//
//  TFTUIOTrackingDataDistributor.h
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

#import <Cocoa/Cocoa.h>

#import "TFTrackingDataDistributor.h"
#import "TFTUIOConstants.h"


@class TFThreadMessagingQueue;

@interface TFTUIOTrackingDataDistributor : TFTrackingDataDistributor {
	float					motionThreshold;
	TFTUIOVersion			defaultTuioVersion;

@protected
	NSThread*				_thread;
	TFThreadMessagingQueue*	_queue;
	
	NSMutableDictionary*	_blobPositions;	// blob label => position
}

@property (nonatomic, assign) float motionThreshold;
@property (nonatomic, assign) TFTUIOVersion defaultTuioVersion;

- (id)init;
- (void)dealloc;

- (BOOL)startDistributorWithObject:(id)obj error:(NSError**)error;
- (void)stopDistributor;

- (void)distributeTrackingDataDictionary:(NSDictionary*)trackingDict;

- (void)distributeTUIODataWithLivingTouches:(NSArray*)livingTouches
							   movedTouches:(NSArray*)movedTouches
								frameNumber:(NSUInteger)frameNumber;

@end
