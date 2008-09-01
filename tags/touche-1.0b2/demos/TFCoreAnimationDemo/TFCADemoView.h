//
//  TFCADemoView.h
//  TFCoreAnimationDemo
//
//  Created by Georg Kaindl on 21/5/08.
//  Copyright 2008 Georg Kaindl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CALayer;
@class TFTouchLabelObjectAssociator;
@class TFCATouchIndicationLayer;
@class TFZoomPinchRecognizer;
@class TFTapRecognizer;

@interface TFCADemoView : NSView {
	CGFloat							pixelsPerCentimeter;

	CALayer*						_imagesLayer;
	NSMutableDictionary*			_operations;
	TFTouchLabelObjectAssociator*	_trackedTouches;
	TFCATouchIndicationLayer*		_touchIndicatorLayer;
	TFZoomPinchRecognizer*			_zoomRecognizer;
	TFTapRecognizer*				_tapRecognizer;
	
	BOOL							_isSetUp;
}

@property (nonatomic, assign) CGFloat pixelsPerCentimeter;

- (void)addImageNamed:(NSString*)name withCenterAt:(NSPoint)center scaledWidth:(CGFloat)scaledWidth;

- (void)handleNewTouches:(NSSet*)touches;
- (void)handleUpdatedTouches:(NSSet*)touches;
- (void)handleEndedTouches:(NSSet*)touches;

@end
