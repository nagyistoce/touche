//
//  TSNextwindowTouchInputSource.h
//  TouchsmartTUIO
//
//  Created by Georg Kaindl on 27/2/09.
//  Copyright 2009 Georg Kaindl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TSTouchInputSource.h"

#import <NWMultiTouch.h>

@interface TSNextwindowTouchInputSource : TSTouchInputSource {
	NSMutableDictionary*	_displayInfoDict;
	void*					_lastDevice;
}

+ (void)initialize;
+ (void)cleanUp;
+ (id)sharedSource;

- (id)init;
- (void)dealloc;

- (BOOL)isReceivingTouchData;

- (NSArray*)currentLabelizedTouches;

@end
