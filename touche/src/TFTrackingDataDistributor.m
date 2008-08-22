//
//  TFTrackingDataDistributor.m
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

#import "TFTrackingDataDistributor.h"


NSString* kToucheTrackingDistributorDataNewTouchesKey			= @"ToucheTrackingDataNewTouches";
NSString* kToucheTrackingDistributorDataUpdatedTouchesKey		= @"ToucheTrackingDataUpdatedTouches";
NSString* kToucheTrackingDistributorDataEndedTouchesKey			= @"ToucheTrackingDataEndedTouches";

@implementation TFTrackingDataDistributor

@synthesize delegate;

- (id)init
{
	if (nil != (self = [super init])) {
		_receivers = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (void)dealloc
{
	[_receivers release];
	_receivers = nil;

	[super dealloc];
}

- (BOOL)startDistributorWithObject:(id)obj error:(NSError**)error
{
	[self doesNotRecognizeSelector:_cmd];
	return NO;
}

- (void)stopDistributor
{
	[self doesNotRecognizeSelector:_cmd];
}

- (BOOL)canAskReceiversToQuit
{
	[self doesNotRecognizeSelector:_cmd];
	return NO;
}

- (void)askReceiverToQuit:(TFTrackingDataReceiver*)receiver
{
	[self doesNotRecognizeSelector:_cmd];
}

- (void)distributeTrackingDataDictionary:(NSDictionary*)trackingDict
{
	[self doesNotRecognizeSelector:_cmd];
}

@end
