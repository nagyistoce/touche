//
//  TFAlignedMalloc.m
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

#import "TFAlignedMalloc.h"

#import "TFIncludes.h"

NSMutableDictionary* TFAlignedMallocAddressDict = nil;

@interface TFAlignedMalloc (PrivateMethods)
+ (void)_storeMallocedAddress:(void*)addr forAlignedAddress:(void*)aAddr;
@end

@implementation TFAlignedMalloc

+ (void*)closestLowerAddressRelativeTo:(void*)ptr beingAlignedAtMultipleOf:(NSUInteger)alignment
{
	return (void*)(((ptrdiff_t)ptr) & ~(alignment-1)); 
}

+ (void*)closestHigherAddressRelativeTo:(void*)ptr beingAlignedAtMultipleOf:(NSUInteger)alignment
{
	return (void*)(((ptrdiff_t)ptr + (ptrdiff_t)(alignment-1)) & ~(alignment-1)); 
}

+ (void*)malloc:(size_t)size alignedAtMultipleOf:(NSUInteger)alignment
{
	void* mem = malloc(alignment + size);
	void* alignedMem = [[self class] closestHigherAddressRelativeTo:mem beingAlignedAtMultipleOf:alignment];
	[[self class] _storeMallocedAddress:mem forAlignedAddress:alignedMem];
		
	return alignedMem;
}

+ (void)free:(void*)p
{
	NSValue* key = [NSValue valueWithPointer:p];
	NSValue* mem = [TFAlignedMallocAddressDict objectForKey:key];
	
	if (nil != mem) {
		free([mem pointerValue]);
		[TFAlignedMallocAddressDict removeObjectForKey:key];
	}
}

+ (void)_storeMallocedAddress:(void*)addr forAlignedAddress:(void*)aAddr
{
	if (nil == TFAlignedMallocAddressDict)
		TFAlignedMallocAddressDict = [[NSMutableDictionary alloc] init];
	
	[TFAlignedMallocAddressDict setObject:[NSValue valueWithPointer:addr]
								   forKey:[NSValue valueWithPointer:aAddr]];
}

@end
