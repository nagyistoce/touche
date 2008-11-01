//
//  TFBlobSize.m
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

#import "TFBlobSize.h"

#import "TFIncludes.h"

@implementation TFBlobSize

@synthesize width;
@synthesize height;

+ (id)sizeWithWidth:(float)w height:(float)h
{
	return [[[[self class] alloc] initWithWidth:w height:h] autorelease];
}

- (id)init
{
	return [self initWithWidth:0 height:0];
}

- (id)initWithWidth:(float)w height:(float)h
{
	if (!(self = [super init])) {
		[self release];
		return nil;
	}
	
	width = w;
	height = h;
	
	return self;
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
		[coder decodeValueOfObjCType:@encode(float) at:&width];
		[coder decodeValueOfObjCType:@encode(float) at:&height];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{	
	[coder encodeValueOfObjCType:@encode(float) at:&width];
	[coder encodeValueOfObjCType:@encode(float) at:&height];
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
