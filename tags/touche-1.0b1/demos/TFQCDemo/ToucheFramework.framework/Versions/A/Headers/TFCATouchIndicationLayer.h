//
//  TFCATouchIndicationLayer.h
//  Touché
//
//  Created by Georg Kaindl on 23/5/08.
//  Copyright 2008 Georg Kaindl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CALayer;

@interface TFCATouchIndicationLayer : NSObject {
	CALayer*				layer;
	CGFloat					indicatorDiameter;
	id						indicatorColor;
	NSMutableDictionary*	_touches;
}

@property (nonatomic, retain) CALayer* layer;
@property (nonatomic, assign) CGFloat indicatorDiameter;
@property (nonatomic, retain) id indicatorColor;

- (id)initWithLayer:(CALayer*)l;

- (void)processNewTouches:(NSSet*)touches;
- (void)processUpdatedTouches:(NSSet*)touches;
- (void)processEndedTouches:(NSSet*)touches;

- (void)removeAllTouches;

@end
