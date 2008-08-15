//
//  TFTouchLabelObjectAssociator.h
//  Touché
//
//  Created by Georg Kaindl on 22/5/08.
//  Copyright 2008 Georg Kaindl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TFBlobLabel;

@interface TFTouchLabelObjectAssociator : NSObject {
	NSMutableDictionary*	_dict;
}

- (void)setObject:(id)obj forLabel:(TFBlobLabel*)label;
- (id)objectForLabel:(TFBlobLabel*)label;
- (void)removeObjectForLabel:(TFBlobLabel*)label;
- (NSSet*)allLabels;
- (NSSet*)allObjects;

- (NSSet*)labelsForObject:(id)obj;
- (NSSet*)labelsForObject:(id)obj intersectingSet:(NSSet*)set;
- (NSSet*)touchesForObject:(id)obj intersectingSetOfTouches:(NSSet*)set;

@end

#undef TFTouchLabel
