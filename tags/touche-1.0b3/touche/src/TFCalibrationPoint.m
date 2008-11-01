//
//  TFCalibrationPoint.m
//  Touché
//
//  Created by Georg Kaindl on 30/12/07.
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

#import "TFCalibrationPoint.h"

#import "TFIncludes.h"

@implementation TFCalibrationPoint

@synthesize screenX;
@synthesize screenY;
@synthesize cameraX;
@synthesize cameraY;

+ (id)pointWithScreenX:(float)sX screenY:(float)sY
{
	return [[[[self class] alloc] initWithScreenX:sX screenY:sY] autorelease];
}

+ (id)pointWithScreenX:(float)sX screenY:(float)sY cameraX:(float)cX cameraY:(float)cY
{
	return [[[[self class] alloc] initWithScreenX:sX screenY:sY cameraX:cX cameraY:cY] autorelease];
}

- (id)init
{
	return [self initWithScreenX:-1.0f screenY:-1.0f];
}

- (id)initWithScreenX:(float)sX screenY:(float)sY
{
	return [self initWithScreenX:sX screenY:sY cameraX:-1.0f cameraY:-1.0f];
}

- (id)initWithScreenX:(float)sX screenY:(float)sY cameraX:(float)cX cameraY:(float)cY
{
	if (!(self = [super init])) {
		[self release];
		return nil;
	}
	
	screenX = sX;
	screenY = sY;
	cameraX = cX;
	cameraY = cY;
	
	return self;
}

- (BOOL)isCalibrated
{
	return (screenX >= 0.0f && screenY >= 0.0f && cameraX >= 0.0f && cameraY >= 0.0f);
}

@end
