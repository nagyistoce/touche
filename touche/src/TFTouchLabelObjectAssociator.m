//
//  TFTouchLabelObjectAssociator.m
//  Touché
//
//  Created by Georg Kaindl on 22/5/08.
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

#import "TFTouchLabelObjectAssociator.h"

#import "TFIncludes.h"
#import "TFBlobLabel.h"
#import "TFBlob.h"

@implementation TFTouchLabelObjectAssociator

- (void)dealloc
{
	[_dict release];
	_dict = nil;
	
	[super dealloc];
}

- (id)init
{
	if (!(self = [super init])) {
		[self release];
		return nil;
	}
	
	_dict = [[NSMutableDictionary alloc] init];
	
	return self;
}

- (void)setObject:(id)obj forLabel:(TFBlobLabel*)label
{
	[_dict setObject:obj forKey:label];
}

- (id)objectForLabel:(TFBlobLabel*)label
{
	return [_dict objectForKey:label];
}

- (void)removeObjectForLabel:(TFBlobLabel*)label
{
	[_dict removeObjectForKey:label];
}

- (NSSet*)allLabels
{
	return [NSSet setWithArray:[_dict allKeys]];
}

- (NSSet*)allObjects
{
	return [NSSet setWithArray:[_dict allValues]];
}

- (NSSet*)labelsForObject:(id)obj
{
	NSArray* keys = [_dict allKeysForObject:obj];
	if (nil == keys)
		return [NSSet set];

	return [NSSet setWithArray:keys];
}

- (NSSet*)labelsForObject:(id)obj intersectingSet:(NSSet*)set
{
	NSArray* keys = [_dict allKeysForObject:obj];
	if (nil == keys)
		return [NSSet set];
	
	NSMutableSet* objSet = [NSMutableSet setWithArray:keys];
	
	objSet = [NSMutableSet setWithSet:objSet];
	[objSet intersectSet:set];
	return [NSSet setWithSet:objSet];
}

- (NSSet*)touchesForObject:(id)obj intersectingSetOfTouches:(NSSet*)set
{
	NSMutableSet* tmpSet = [NSMutableSet set];
	for (TFBlob* touch in set)
		[tmpSet addObject:touch.label];
	
	[tmpSet intersectSet:[self labelsForObject:obj]];
	NSMutableSet* wantedTouches = [NSMutableSet set];
	for (TFBlob* touch in set)
		if ([tmpSet containsObject:touch.label])
			[wantedTouches addObject:touch];
	
	return [NSSet setWithSet:wantedTouches];
}

@end
