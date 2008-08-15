//
//  TFGestureInfo.m
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

#import "TFGestureInfo.h"

#import "TFIncludes.h"

@implementation TFGestureInfo

@synthesize type;
@synthesize subtype;
@synthesize parameters;
@synthesize createdAt;
@synthesize userInfo;

- (void)dealloc
{
	[userInfo release];
	userInfo = nil;
	
	[parameters release];
	parameters = nil;
	
	[super dealloc];
}

- (id)init
{
	return [self initWithType:TFGestureTypeAny];
}

- (id)initWithType:(TFGestureType)t
{
	return [self initWithType:t andSubtype:TFGestureSubtypeAny];
}

- (id)initWithType:(TFGestureType)t andSubtype:(TFGestureSubtype)st
{
	return [self initWithType:t andSubtype:st andParameters:nil];
}

- (id)initWithType:(TFGestureType)t andSubtype:(TFGestureSubtype)st andParameters:(NSDictionary*)params
{
	if (!(self = [super init])) {
		[self release];
		return nil;
	}
	
	self.type = t;
	self.subtype = st;
	self.parameters = params;
	createdAt = [NSDate timeIntervalSinceReferenceDate];
	userInfo = nil;
	
	return self;
}

+ (id)info
{
	return [[[[self class] alloc] init] autorelease];
}

+ (id)infoWithType:(TFGestureType)t
{
	return [[[[self class] alloc] initWithType:t] autorelease];
}

+ (id)infoWithType:(TFGestureType)t andSubtype:(TFGestureSubtype)st
{
	return [[[[self class] alloc] initWithType:t andSubtype:st] autorelease];
}

+ (id)infoWithType:(TFGestureType)t andSubtype:(TFGestureSubtype)st andParameters:(NSDictionary*)params
{
	return [[[[self class] alloc] initWithType:t andSubtype:st andParameters:params] autorelease];
}

@end