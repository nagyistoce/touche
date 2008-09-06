//
//  TFTUIOTrackingDataDistributor.m
//  Touche
//
//  Created by Georg Kaindl on 6/9/08.
//  Copyright 2008 Georg Kaindl. All rights reserved.
//

#import "TFTUIOTrackingDataDistributor.h"

#import "TFThreadMessagingQueue.h"
#import "TFBlob.h"
#import "TFBlobLabel.h"
#import "TFBlobPoint.h"


#define	DEFAULT_MOTION_THRESHOLD	(5.0f)

@interface TFTUIOTrackingDataDistributor (PrivateMethods)
- (void)_distributionThread;
@end

@implementation TFTUIOTrackingDataDistributor

@synthesize motionThreshold;

- (id)init
{
	if (nil != (self = [super init])) {
		self.motionThreshold = DEFAULT_MOTION_THRESHOLD;
	}
	
	return self;
}

- (void)dealloc
{
	[self stopDistributor];
	
	[super dealloc];
}

- (BOOL)startDistributorWithObject:(id)obj error:(NSError**)error
{
	if (nil == _blobPositions && nil == _queue && nil == _thread) {
		_blobPositions = [[NSMutableDictionary alloc] init];
		_queue = [[TFThreadMessagingQueue alloc] init];
		
		_thread = [[NSThread alloc] initWithTarget:self
										  selector:@selector(_distributionThread)
											object:nil];
		[_thread start];
	}
	
	return YES;
}

- (void)stopDistributor
{
	[_thread cancel];
	
	// queue a dummy to wake up the thread
	[_queue enqueue:[NSDictionary dictionary]];
	
	[_thread release];
	_thread = nil;
	
	[_queue release];
	_queue = nil;
	
	[_blobPositions release];
	_blobPositions = nil;
}

- (void)distributeTrackingDataDictionary:(NSDictionary*)trackingDict
{
	[_queue enqueue:trackingDict];
}

- (void)distributeTUIODataWithLivingTouches:(NSArray*)livingTouches
							   movedTouches:(NSArray*)movedTouches
								frameNumber:(NSUInteger)frameNumber
{
	[self doesNotRecognizeSelector:_cmd];
}

- (void)_distributionThread
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	TFThreadMessagingQueue* queue = [_queue retain];
	NSDictionary *touches = nil;
	NSUInteger frameSequenceNumber = 0;
	
	while (YES) {
		NSAutoreleasePool* innerPool = [[NSAutoreleasePool alloc] init];
		
		touches = (NSDictionary*)[queue dequeue];
		
		if ([[NSThread currentThread] isCancelled]) {
			[innerPool release];
			break;
		}
		
		NSArray* newTouches = (NSArray*)[touches objectForKey:kToucheTrackingDistributorDataNewTouchesKey];
		NSArray* updatedTouches = (NSArray*)[touches objectForKey:kToucheTrackingDistributorDataUpdatedTouchesKey];
		
		NSMutableArray* activeTouches = [NSMutableArray arrayWithArray:newTouches];
		[activeTouches addObjectsFromArray:updatedTouches];
		
		NSMutableArray* movedTouches = [NSMutableArray array];
		
		[movedTouches addObjectsFromArray:newTouches];
		for (TFBlob* blob in newTouches) {
			[_blobPositions setObject:blob.center forKey:blob.label];
		}
		
		float minDistance = self.motionThreshold;
		for (TFBlob* blob in updatedTouches) {
			TFBlobPoint* lastPosition = [_blobPositions objectForKey:blob.label];
			if (minDistance <= [blob.center distanceFromBlobPoint:lastPosition]) {
				[_blobPositions setObject:blob.center forKey:blob.label];
				[movedTouches addObject:blob];
			}
		}
		
		[self distributeTUIODataWithLivingTouches:activeTouches
									 movedTouches:movedTouches
									  frameNumber:frameSequenceNumber];
		
		frameSequenceNumber++;
		
		[innerPool release];
	}
	
	[queue release];
	
	[pool release];
}

@end
