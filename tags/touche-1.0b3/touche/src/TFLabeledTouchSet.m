//
//  TFLabeledTouchSet.m
//  Touché
//
//  Created by Georg Kaindl on 24/5/08.
//
//  Copyright (C) 2008 Georg Kaindl
//
//  This file is part of Touché.
//
//  Touché is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as
//  published by the Free Software Foundation, either version 3 of
//  the License, or (at your option) any later version.
//
//  Touché is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public
//  License along with Touché. If not, see <http://www.gnu.org/licenses/>.
//
//

#import "TFLabeledTouchSet.h"

#import "TFIncludes.h"
#import "TFBlob.h"
#import "TFBlobLabel.h"

static int TFLabeledTouchSet_compInt(const void* i, const void* j);

@implementation TFLabeledTouchSet

- (void)dealloc
{
	[_set release];
	_set = nil;
	
	[super dealloc];
}

- (id)init
{
	return [self initWithSet:[NSSet set]];
}

- (id)initWithSet:(NSSet*)set
{
	if (!(self = [super init])) {
		[self release];
		return nil;
	}
	
	_set = [set retain];
	_hashComputed = NO;
	
	return self;
}

+ (id)setWithSet:(NSSet*)set
{
	return [[[[self class] alloc] initWithSet:set] autorelease];
}

- (TFBlob*)anyDeterminateTouch
{
	TFBlob* selectedTouch = nil;
	
	for (TFBlob* touch in _set) {
		if (nil == selectedTouch || selectedTouch.label.intLabel > touch.label.intLabel)
			selectedTouch = touch;
	}
	
	return selectedTouch;
}

- (NSArray*)allTouches
{
	return [_set allObjects];
}

- (NSUInteger)count
{
	return [_set count];
}

- (NSSet*)set
{
	return [NSSet setWithSet:_set];
}

#pragma mark -
#pragma mark NSFastEnumeration protocol

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state 
								  objects:(id *)stackbuf 
									count:(NSUInteger)len
{
	return [_set countByEnumeratingWithState:state
									 objects:stackbuf
									   count:len];
}

#pragma mark -
#pragma mark NSCopying protocol

- (id)copyWithZone:(NSZone *)zone
{
	TFLabeledTouchSet* aCopy = NSCopyObject(self, 0, zone);
	
	aCopy->_set = [[NSSet alloc] initWithSet:_set];
	
	return aCopy;
}

#pragma mark -
#pragma mark Equality of TouchSets

- (BOOL)isEqual:(id)other
{
	if (self == other)
		return YES;
	
	if (nil == other)
		return NO;
	
	if ([other isKindOfClass:[self class]])
		return [self isEqualToTouchSet:other];
	else if ([other isKindOfClass:[NSSet class]])
		return [_set isEqualToSet:other];
	
	return [self isEqual:other];
}

- (BOOL)isEqualToTouchSet:(TFLabeledTouchSet*)other
{
	return ([other count] == [self count] && [other hash] == [self hash]);
}

- (NSUInteger)hash
{
	if (_hashComputed)
		return _hash;

	_hashComputed = YES;

	if (0 == [_set count]) {
		_hash = NSUIntegerMax;
		return _hash;
	}

	int i, l, n[[_set count]];
	i = 0;
	l = [_set count];
	for (TFBlob* touch in _set)
		n[i++] = touch.label.intLabel;

	qsort(n, l, sizeof(int), TFLabeledTouchSet_compInt);
	NSUInteger acc = n[0];
	// iteratively use the cantor pairing function to compute a "hash"
	for (i=1; i<l; i++)
		acc = 0.5*(acc + n[i])*(acc + n[i] + 1) + n[i];
	
	_hash = acc;
	return _hash;
}

@end

static int TFLabeledTouchSet_compInt(const void* i, const void* j)
{
	return *(int*)i - *(int*)j;
}