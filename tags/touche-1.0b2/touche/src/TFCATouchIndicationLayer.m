//
//  TFCATouchIndicationLayer.m
//  Touché
//
//  Created by Georg Kaindl on 23/5/08.
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

#import "TFCATouchIndicationLayer.h"

#import <QuartzCore/QuartzCore.h>
#import <QuartzCore/CoreAnimation.h>

#define TFTouch TFBlob

#import "TFIncludes.h"
#import "TFBlob.h"
#import "TFBlobLabel.h"
#import "TFBlobPoint.h"

@interface TFCATouchIndicationLayer (PrivateMethods)
- (CALayer*)_touchIndicatorLayer;
@end

@implementation TFCATouchIndicationLayer

@synthesize layer;
@synthesize indicatorDiameter;
@synthesize indicatorColor;

- (void)dealloc
{
	[self removeAllTouches];

	[layer removeFromSuperlayer];
	[layer release];
	layer = nil;
	
	[_touches release];
	_touches = nil;
	
	CGColorRelease((CGColorRef)indicatorColor);
	indicatorColor = nil;
	
	[super dealloc];
}

- (id)init
{
	return [self initWithLayer:nil];
}

- (id)initWithLayer:(CALayer*)l
{
	if (!(self = [super init])) {
		[self release];
		return nil;
	}
	
	self.layer = l;
	self.indicatorDiameter = 30.0f;
	self.indicatorColor = (id)CGColorGetConstantColor(kCGColorWhite);
	
	_touches = [[NSMutableDictionary alloc] init];
	
	return self;
}

- (void)processNewTouches:(NSSet*)touches
{
	for (TFTouch* touch in touches) {
		CALayer* touchIndicator = [self _touchIndicatorLayer];
	
		[_touches setObject:touchIndicator forKey:touch.label];
		[layer addSublayer:touchIndicator];
		[CATransaction begin];
		[CATransaction setValue:[NSNumber numberWithFloat:0.0f]
						 forKey:kCATransactionAnimationDuration];
		touchIndicator.position = CGPointMake(touch.center.x, touch.center.y);
		[CATransaction commit];
	}
}

- (void)processUpdatedTouches:(NSSet*)touches
{
	for (TFTouch* touch in touches) {
		CALayer* touchIndicator = [_touches objectForKey:touch.label];
		
		[CATransaction begin];
		[CATransaction setValue:[NSNumber numberWithFloat:0.0f]
						 forKey:kCATransactionAnimationDuration];
		touchIndicator.position = CGPointMake(touch.center.x, touch.center.y);
		[CATransaction commit];
	}
}

- (void)processEndedTouches:(NSSet*)touches
{
	for (TFTouch* touch in touches) {
		CALayer* touchIndicator = [_touches objectForKey:touch.label];
		[touchIndicator removeFromSuperlayer];
		[_touches removeObjectForKey:touch.label];
	}
}

- (void)removeAllTouches
{
	for (id touch in _touches) {
		CALayer* l = [_touches objectForKey:touch];
		[l removeFromSuperlayer];
		[_touches removeObjectForKey:touch];
	}
}

- (CALayer*)_touchIndicatorLayer
{
	CALayer* ti = [CALayer layer];
	ti.backgroundColor = (CGColorRef)indicatorColor;
	ti.opacity = 0.5;
	ti.bounds = CGRectMake(0, 0, indicatorDiameter, indicatorDiameter);
	ti.cornerRadius = indicatorDiameter/2.0f;
	
	return ti;
}

@end
