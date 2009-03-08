//
//  TSTouchInputSource.m
//  TouchsmartTUIO
//
//  Created by Georg Kaindl on 27/2/09.
//
//  Copyright (C) 2009 Georg Kaindl
//
//  This file is part of Touchsmart TUIO.
//
//  Touchsmart TUIO is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as
//  published by the Free Software Foundation, either version 3 of
//  the License, or (at your option) any later version.
//
//  Touchsmart TUIO is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public
//  License along with Touchsmart TUIO. If not, see <http://www.gnu.org/licenses/>.
//

#import "TSTouchInputSource.h"


NSString*	kTISSenderName					= @"SenderName";
NSString*	kTISSenderProductID				= @"SenderProductID";
NSString*	kTISSenderModel					= @"SenderModel";
NSString*	kTISSenderSerialNumber			= @"SenderSerialNumber";
NSString*	kTISSenderVersion				= @"SenderVersion";
NSString*	kTISSenderFirmwareVersion		= @"SenderFirmwareVersion";

@implementation TSTouchInputSource

@synthesize delegate;

+ (void)cleanUp
{
}

- (id)init
{
	if (nil != (self = [super init])) {
	}
	
	return self;
}

- (void)dealloc
{
	delegate = nil;
	
	[_senderInfoDict release];
	_senderInfoDict = nil;
	
	[super dealloc];
}

- (BOOL)isReceivingTouchData
{
	return NO;
}

- (void)invalidate
{
}

- (NSDictionary*)currentSenderInfo
{
	return nil;
}

- (NSArray*)currentLabelizedTouches
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

@end
