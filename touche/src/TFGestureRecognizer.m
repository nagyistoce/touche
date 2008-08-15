//
//  TFGestureRecognizer.m
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

#import "TFGestureRecognizer.h"

#import "TFIncludes.h"
#import "TFGestureInfo.h"

@implementation TFGestureRecognizer

@synthesize userInfo;

- (void)dealloc
{
	[_recognizedGestures release];
	_recognizedGestures = nil;
	
	[userInfo release];
	userInfo = nil;
	
	[super dealloc];
}

- (id)init
{
	if (!(self = [super init])) {
		[self release];
		return nil;
	}
	
	_recognizedGestures = [[NSMutableDictionary alloc] init];
	userInfo = nil;
	
	return self;
}

- (NSDictionary*)recognizedGestures
{
	return [NSDictionary dictionaryWithDictionary:_recognizedGestures];
}

- (void)clearRecognizedGestures
{
	[_recognizedGestures removeAllObjects];
}

- (void)clearRecognizedGesturesOfType:(TFGestureType)type andSubtype:(TFGestureSubtype)subtype
{
	for (id key in [_recognizedGestures allKeys]) {
		TFGestureInfo* info = [_recognizedGestures objectForKey:key];
		
		if ((TFGestureTypeAny == type || type == info.type) && (TFGestureSubtypeAny == subtype || subtype == info.subtype))
			[_recognizedGestures removeObjectForKey:key];
	}
}

- (BOOL)wantsNewTouches
{
	return NO;
}

- (BOOL)wantsUpdatedTouches
{
	return NO;
}

- (BOOL)wantsEndedTouches
{
	return NO;
}

- (BOOL)tracksOverMultipleFrames
{
	return NO;
}

- (void)processNewTouches:(NSSet*)touches
{
}

- (void)processUpdatedTouches:(NSSet*)touches
{
}

- (void)processEndedTouches:(NSSet*)touches
{
}

@end
