//
//  TFGestureRecognizer.h
//  Touché
//
//  Created by Georg Kaindl on 24/5/08.
//  Copyright 2008 Georg Kaindl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TFGestureConstants.h"

@interface TFGestureRecognizer : NSObject {
	NSMutableDictionary*	_recognizedGestures;
	id						userInfo;
}

@property (nonatomic, retain) id userInfo;

- (NSDictionary*)recognizedGestures;
- (void)clearRecognizedGestures;
- (void)clearRecognizedGesturesOfType:(TFGestureType)type andSubtype:(TFGestureSubtype)subtype;

- (void)processNewTouches:(NSSet*)touches;
- (void)processUpdatedTouches:(NSSet*)touches;
- (void)processEndedTouches:(NSSet*)touches;

- (BOOL)wantsNewTouches;
- (BOOL)wantsUpdatedTouches;
- (BOOL)wantsEndedTouches;

- (BOOL)tracksOverMultipleFrames;

@end
