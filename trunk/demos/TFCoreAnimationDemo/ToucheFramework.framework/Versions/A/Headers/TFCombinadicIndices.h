//
//  TFCombinadicIndices.h
//  Touché
//
//  Created by Georg Kaindl on 23/5/08.
//  Copyright 2008 Georg Kaindl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TFCombinadicIndices : NSObject {
	NSUInteger		numElementsInSet;
	NSUInteger		numElementsToSelect;
	BOOL			isExhausted;
	
	NSUInteger*		_slots;
	NSInteger		_numCombinations;
}

@property (readonly) NSUInteger numElementsInSet;
@property (readonly) NSUInteger numElementsToSelect;
@property (readonly) BOOL isExhausted;

+ (id)combinadicWithElementsToSelect:(NSUInteger)numElements fromSetWithPower:(NSUInteger)setPower;

- (id)initWithElementsToSelect:(NSUInteger)numElements fromSetWithPower:(NSUInteger)setPower;
- (const NSUInteger*)nextCombination;
- (NSInteger)numCombinations;
- (void)reset;

@end
