//
//  TFLabeledTouchSet.h
//  Touché
//
//  Created by Georg Kaindl on 24/5/08.
//  Copyright 2008 Georg Kaindl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TFBlob;
@class TFLabeledTouchSet;

@interface TFLabeledTouchSet : NSObject <NSFastEnumeration, NSCopying> {
	NSSet*			_set;
	NSUInteger		_hash;
	BOOL			_hashComputed;
}

+ (id)setWithSet:(NSSet*)set;

- (id)initWithSet:(NSSet*)set;

// determinate in the sense that it will return any touch, but ALWAYS
// the same touch for the same set (same set = contains touches with
// the same labels)
- (TFBlob*)anyDeterminateTouch;
- (NSArray*)allTouches;

- (NSSet*)set;
- (NSUInteger)count;

- (BOOL)isEqualToTouchSet:(TFLabeledTouchSet*)other;

@end
