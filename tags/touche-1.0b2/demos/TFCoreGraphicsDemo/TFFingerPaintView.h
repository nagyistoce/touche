//
//  TFFingerPaintView.h
//  TFCoreGraphicsDemo
//
//  Created by Georg Kaindl on 24/5/08.
//  Copyright 2008 Georg Kaindl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TFTouchLabelObjectAssociator;

@interface TFFingerPaintView : NSView {
	CGFloat							brushSize;

	CGContextRef					_context;
	TFTouchLabelObjectAssociator*	_cgLayers;
	CGLayerRef						_layer;
	NSGradient*						_bgGradient;
	BOOL							_isSetUp;
}

@property (nonatomic, assign) CGFloat brushSize;

- (void)setupContext;

- (void)handleNewTouches:(NSSet*)touches;
- (void)handleUpdatedTouches:(NSSet*)touches;
- (void)handleEndedTouches:(NSSet*)touches;

@end
