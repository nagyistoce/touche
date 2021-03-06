//
//  TFBlobBox.m
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

#import "TFBlobBox.h"

#import "TFIncludes.h"
#import "TFBlobPoint.h"
#import "TFBlobSize.h"

@implementation TFBlobBox

@synthesize origin;
@synthesize size;
@synthesize angle;
@synthesize angularMotion;
@synthesize angularAcceleration;

- (void)dealloc
{
	[origin release];
	[size release];
	
	[super dealloc];
}

- (id)init
{
	return [self initWithOrigin:nil size:nil];
}

- (id)initWithOrigin:(TFBlobPoint*)o size:(TFBlobSize*)s
{
	return [self initWithOrigin:o
						   size:s
						  angle:0.0];
}

- (id)initWithOrigin:(TFBlobPoint*)o size:(TFBlobSize*)s angle:(double)anAngle
{
	if (!(self = [super init])) {
		[self release];
		return nil;
	}
	
	if (nil != o)
		origin = [o retain];
	else
		origin = [[TFBlobPoint alloc] init];
	
	if (nil != s)
		size = [s retain];
	else
		size = [[TFBlobSize alloc] init];
	
	self->angle = anAngle;
	self->angularMotion = 0.0;
	self->angularAcceleration = 0.0;
	
	return self;
}

#pragma mark -
#pragma mark NSCopying protocol

- (id)copyWithZone:(NSZone *)zone
{
	TFBlobBox* aCopy = NSCopyObject(self, 0, zone);
	
	aCopy->origin = [self->origin copy];
	aCopy->size = [self->size copy];
	
	return aCopy;
}

#pragma mark -
#pragma mark NSCoding protocol

- (id)initWithCoder:(NSCoder *)coder
{
	TFBlobPoint* originC	= [coder decodeObject];
	TFBlobSize* sizeC		= [coder decodeObject];
	
	double a, am, aa;
	[coder decodeValueOfObjCType:@encode(double) at:&a];
	[coder decodeValueOfObjCType:@encode(double) at:&am];
	[coder decodeValueOfObjCType:@encode(double) at:&aa];
	
	self = [self initWithOrigin:originC size:sizeC angle:a];
	
	self->angularMotion = am;
	self->angularAcceleration = aa;
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{	
	[coder encodeObject:origin];
	[coder encodeObject:size];
	[coder encodeValueOfObjCType:@encode(double) at:&angle];
	[coder encodeValueOfObjCType:@encode(double) at:&angularMotion];
	[coder encodeValueOfObjCType:@encode(double) at:&angularAcceleration];
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
