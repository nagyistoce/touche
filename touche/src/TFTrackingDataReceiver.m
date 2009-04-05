//
//  TFTrackingDataReceiver.m
//  Touché
//
//  Created by Georg Kaindl on 22/8/08.
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

#import "TFTrackingDataReceiver.h"


@implementation TFTrackingDataReceiver

@synthesize active, connected, receiverID, owningDistributor, infoDictionary;

- (id)init
{
	if (nil != (self = [super init])) {
		active = YES;
	}
	
	return self;
}

- (void)dealloc
{
	[receiverID release];
	receiverID = nil;
	
	[infoDictionary release];
	infoDictionary = nil;
	
	[super dealloc];
}

- (void)receiverShouldQuit
{
	[self doesNotRecognizeSelector:_cmd];
}

- (void)consumeTrackingData:(id)trackingData
{
	[self doesNotRecognizeSelector:_cmd];
}

- (NSMenu*)contextualMenuForReceiver
{
	return nil;
}

#pragma mark -
#pragma mark NSCopying protocol

- (id)copyWithZone:(NSZone*)zone
{
	return [self retain];
}

@end
