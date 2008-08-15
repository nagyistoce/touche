//
//  TFTapRecognizer.h
//  Touche
//
//  Created by Georg Kaindl on 2/6/08.
//  Copyright 2008 Georg Kaindl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TFGestureRecognizer.h"

extern NSString* TFTapRecognizerParamTapCount;

@class TFBlobLabel;
@class TFTouchLabelObjectAssociator;

@interface TFTapRecognizer : TFGestureRecognizer {
	NSTimeInterval				maxTapTime;
	float						maxTapDistance;

	NSMutableDictionary*			_touchesToTaps;
	NSMutableArray*					_inactiveBlobs;
	TFTouchLabelObjectAssociator*	_labelTapCounts;
}

@property (nonatomic, assign) NSTimeInterval maxTapTime;
@property (nonatomic, assign) float maxTapDistance;

- (NSInteger)tapCountForLabel:(TFBlobLabel*)label;

@end
