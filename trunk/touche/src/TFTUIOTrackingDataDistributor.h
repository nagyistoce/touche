//
//  TFTUIOTrackingDataDistributor.h
//  Touche
//
//  Created by Georg Kaindl on 6/9/08.
//  Copyright 2008 Georg Kaindl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TFTrackingDataDistributor.h"


@class TFThreadMessagingQueue;


@interface TFTUIOTrackingDataDistributor : TFTrackingDataDistributor {
	float					motionThreshold;

@protected
	NSThread*				_thread;
	TFThreadMessagingQueue*	_queue;
	
	NSMutableDictionary*	_blobPositions;	// blob label => position
}

@property (nonatomic, assign) float motionThreshold;

- (id)init;
- (void)dealloc;

- (BOOL)startDistributorWithObject:(id)obj error:(NSError**)error;
- (void)stopDistributor;

- (void)distributeTrackingDataDictionary:(NSDictionary*)trackingDict;

- (void)distributeTUIODataWithLivingTouches:(NSArray*)livingTouches
							   movedTouches:(NSArray*)movedTouches
								frameNumber:(NSUInteger)frameNumber;

@end
