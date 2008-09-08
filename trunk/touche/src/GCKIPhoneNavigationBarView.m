//
//  GCKIPhoneNavigationBarView.m
//
//  Created by Georg Kaindl on 5/5/08.
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

#import "GCKIPhoneNavigationBarView.h"

#import "CGColorFromNSColor.h"
#import "CGColorRefColorSpaceConversions.h"
#import "NSView+Extras.h"

@interface GCKIPhoneNavigationBarView (NonPublicMethods)
- (void)_computeDerivedColors;
- (void)_freeDerivedColors;
- (void)_setDefaults;
@end

@implementation GCKIPhoneNavigationBarView

@synthesize baseColor;
@synthesize hasShadow;
@synthesize shadowPosition;
@synthesize hasTopDarkLine;

- (void)setBaseColor:(NSColor*)newColor
{
	[self _freeDerivedColors];
	[newColor retain];
	[baseColor release];
	baseColor = newColor;
	
	if (nil != baseColor)
		[self _computeDerivedColors];
}

- (void)dealloc
{
	self.baseColor = nil;

	[super dealloc];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self _setDefaults];
    }
    return self;
}

- (BOOL)isFlipped
{
	return YES;
}

- (void)drawRect:(NSRect)rect
{
	if (nil == _baseColorCG)
		return;
	
	rect = [self bounds];
	
	BOOL makeShadow = (hasShadow &&
					   ((shadowPosition != GCKIPhoneNavigationBarViewShadowPositionBoth && rect.size.height > 12.0f) ||
						(shadowPosition == GCKIPhoneNavigationBarViewShadowPositionBoth && rect.size.height > 24.0f)));
	BOOL topShadow = (shadowPosition == GCKIPhoneNavigationBarViewShadowPositionTop || shadowPosition == GCKIPhoneNavigationBarViewShadowPositionBoth);
	BOOL bottomShadow = (shadowPosition == GCKIPhoneNavigationBarViewShadowPositionBottom || shadowPosition == GCKIPhoneNavigationBarViewShadowPositionBoth);
	
	CGContextRef context = [self currentCGContext];
	
	if (makeShadow) {		
		if (topShadow) {
			rect.origin.y += 12.0f;
			rect.size.height -= 12.0f;
		}
		
		if (bottomShadow)
			rect.size.height -= 12.0f;
	}
		
	CGContextSaveGState(context);
	CGRect bottomRect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
	
	if (makeShadow && bottomShadow) {
		CGContextSetShadow(context, CGSizeMake(0.0f, -5.0f), 10.0f);
		bottomRect = CGRectMake(rect.origin.x-5.0f, rect.origin.y, rect.size.width+10.0f, rect.size.height);
	}
	
	CGContextSetFillColorWithColor(context, _bottomLineColor);
	CGContextFillRect(context, bottomRect);
	
	CGContextRestoreGState(context);
	
	if (hasTopDarkLine && makeShadow && topShadow) {
		bottomRect.origin.x -= 5.0f;
		bottomRect.size.width += 10.0f;
		CGContextSaveGState(context);		
		CGContextSetShadow(context, CGSizeMake(0.0f, 5.0f), 10.0f);		
		CGContextSetFillColorWithColor(context, _bottomLineColor);
		CGContextFillRect(context, bottomRect);
		CGContextRestoreGState(context);
	}
	
	if (hasTopDarkLine) {
		rect.origin.y += 1.0f;
		rect.size.height -= 1.0f;
	}
	
	CGContextSaveGState(context);
	
	CGRect topRect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height/2);
	
	if (!hasTopDarkLine && makeShadow && topShadow) {
		CGContextSetShadow(context, CGSizeMake(0.0f, 5.0f), 10.0f);
		topRect = CGRectMake(rect.origin.x-5.0f, rect.origin.y, rect.size.width+10.0f, rect.size.height/2);
	}
	
	CGContextSetFillColorWithColor(context, _topLineColor);
	CGContextFillRect(context, topRect);
	
	CGContextRestoreGState(context);
	
	CGPoint startPoint, endPoint;
	
	startPoint.x = rect.origin.x+rect.size.width/2;
	startPoint.y = rect.origin.y+rect.size.height/2;
	endPoint.x = rect.origin.x+rect.size.width/2;
	endPoint.y = rect.origin.y+rect.size.height-1.0f;

	CGContextDrawLinearGradient(context, _bottomGradient, startPoint, endPoint, 0);

	startPoint.x = rect.origin.x+rect.size.width/2;
	startPoint.y = rect.origin.y+1.0f;
	endPoint.x = rect.origin.x+rect.size.width/2;
	endPoint.y = rect.origin.y+rect.size.height/2;

	CGContextDrawLinearGradient(context, _topGradient, startPoint, endPoint, 0);
	
	CGContextFlush(context);
}

- (void)_setDefaults
{	
	self.baseColor = [NSColor colorWithCalibratedRed:.4275f green:.5176f blue:.6353f alpha:1.0f];
	self.hasShadow = NO;
	self.shadowPosition = GCKIPhoneNavigationBarViewShadowPositionBottom;
	self.hasTopDarkLine = NO;
}

- (void)_freeDerivedColors
{
	if (NULL != _baseColorCG) {
		CGColorRelease(_baseColorCG);
		_baseColorCG = NULL;
	}

	if (NULL != _topLineColor) {
		CGColorRelease(_topLineColor);
		_topLineColor = NULL;
	}
	
	if (NULL != _bottomLineColor) {
		CGColorRelease(_bottomLineColor);
		_bottomLineColor = NULL;
	}
	
	if (NULL != _topGradient) {
		CGGradientRelease(_topGradient);
		_topGradient = NULL;
	}
	
	if (NULL != _bottomGradient) {
		CGGradientRelease(_bottomGradient);
		_bottomGradient = nil;
	}
}

- (void)_computeDerivedColors
{
	[self _freeDerivedColors];
	
	_baseColorCG = CGColorCreateFromNSColor(baseColor);
	
	CGFloat lum = CGColorGetRGBLuminance(_baseColorCG);
	CGFloat fact = 1.0 + 2.7*ABS(lum - .571959);
	
	_topLineColor = CGColorCreateFromRGBColorWithLABOffset(_baseColorCG, 23.935089f*fact, 0.284225f, 10.066342f);
	_bottomLineColor = CGColorCreateFromRGBColorWithLABOffset(_baseColorCG, -38.742592f*fact, 0.638589f, 7.224721f);
	
	CGColorRef bottomGradientBottomColor =
		CGColorCreateFromRGBColorWithLABOffset(_baseColorCG, -6.598526f*fact, 0.239372f, -2.725481f);
	CGColorRef topGradientTopColor =
		CGColorCreateFromRGBColorWithLABOffset(_baseColorCG, 14.817841f*fact, 0.402272f, 5.96925f);
	CGColorRef topGradientBottomColor =
		CGColorCreateFromRGBColorWithLABOffset(_baseColorCG, 2.278397f*fact, -0.200182f, 1.234698f);
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	
	_bottomGradient = CGGradientCreateWithColors(colorSpace,
												 (CFArrayRef)[NSArray arrayWithObjects:(NSObject*)_baseColorCG,
															  (NSObject*)bottomGradientBottomColor,
															  nil],
												 NULL);
	
	_topGradient = CGGradientCreateWithColors(colorSpace,
											  (CFArrayRef)[NSArray arrayWithObjects:(NSObject*)topGradientTopColor,
														   (NSObject*)topGradientBottomColor,
														   nil],
											  NULL);
	
	CGColorSpaceRelease(colorSpace);
	CGColorRelease(bottomGradientBottomColor);
	CGColorRelease(topGradientTopColor);
	CGColorRelease(topGradientBottomColor);
}

#pragma mark -
#pragma mark Observing

- (NSArray*)keysAffectingDisplay
{
	return [NSArray arrayWithObjects:@"baseColor",
									@"hasShadow",
									@"shadowPosition",
									nil];
}

@end
