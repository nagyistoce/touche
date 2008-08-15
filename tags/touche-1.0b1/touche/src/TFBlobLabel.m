//
//  TFBlobLabel.m
//  Touché
//
//  Created by Georg Kaindl on 20/12/07.
//
//  Copyright (C) 2007 Georg Kaindl
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

#import "TFBlobLabel.h"

#import "TFIncludes.h"

#define		NIL_LABEL_VAL		((NSInteger)(-1))

@implementation TFBlobLabel

@synthesize intLabel;
@synthesize isNew;

+ (id)labelWithInteger:(NSInteger)label
{
	return [[[[self class] alloc] initWithInteger:label] autorelease];
}

- (id)init
{
	return [self initWithInteger:NIL_LABEL_VAL];
}

- (id)initWithInteger:(NSInteger)label
{
	if (!(self = [super init])) {
		[self release];
		return nil;
	}
	
	intLabel = label;
	isNew = NO;
	
	return self;
}

- (BOOL)isEqual:(id)other
{
	if (self == other)
		return YES;
	
	if (nil == other || ![other isKindOfClass:[self class]])
		return NO;
	
	return [self isEqualToLabel:other];
}

- (NSUInteger)hash
{
	return (NSUInteger)intLabel;
}

- (BOOL)isEqualToLabel:(TFBlobLabel*)other
{
	return ([other intLabel] == [self intLabel]);
}

- (BOOL)isNilLabel
{
	return (NIL_LABEL_VAL == intLabel);
}

#pragma mark -
#pragma mark NSCopying protocol

- (id)copyWithZone:(NSZone *)zone
{
	return NSCopyObject(self, 0, zone);
}

#pragma mark -
#pragma mark NSCoding protocol

- (id)initWithCoder:(NSCoder *)coder
{
	self = [self init];
	
	if (nil != self) {
		[coder decodeValueOfObjCType:@encode(NSInteger) at:&intLabel];
		[coder decodeValueOfObjCType:@encode(BOOL) at:&isNew];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{	
	[coder encodeValueOfObjCType:@encode(NSInteger) at:&intLabel];
	[coder encodeValueOfObjCType:@encode(BOOL) at:&isNew];
}

#pragma mark -
#pragma mark NSPortCoder specifics

- (id)replacementObjectForPortCoder:(NSPortCoder *)encoder
{
	if ([encoder isByref])
		return [super replacementObjectForPortCoder:encoder];
	
	return self;
}

@end
