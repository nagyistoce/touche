//
//  TFBlobPoint.m
//  Touché
//
//  Created by Georg Kaindl on 18/12/07.
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

#import "TFBlobPoint.h"

#import "TFIncludes.h"

@implementation TFBlobPoint

@synthesize x;
@synthesize y;

+ (id)point
{
	return [[[[self class] alloc] init] autorelease];
}

+ (id)pointWithX:(float)xPos Y:(float)yPos
{
	return [[[[self class] alloc] initWithX:xPos Y:yPos] autorelease];
}

- (id)init
{
	return [self initWithX:0 Y:0];
}

- (id)initWithX:(float)xPos Y:(float)yPos
{
	if (!(self = [super init])) {
		[self release];
		return nil;
	}
	
	x = xPos;
	y = yPos;
	
	return self;
}

- (float)vectorLength
{
	return hypot(x, y);
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
		[coder decodeValueOfObjCType:@encode(float) at:&x];
		[coder decodeValueOfObjCType:@encode(float) at:&y];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{	
	[coder encodeValueOfObjCType:@encode(float) at:&x];
	[coder encodeValueOfObjCType:@encode(float) at:&y];
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
