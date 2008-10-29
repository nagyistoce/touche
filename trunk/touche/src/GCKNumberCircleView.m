//
//  GCKNumberCircleView.m
//
//  Created by Georg Kaindl on 6/5/08.
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

#import "GCKNumberCircleView.h"

#import "CGColorFromNSColor.h"
#import "NSView+Extras.h"

@interface GCKNumberCircleView (NonPublicMethods)
- (void)_setDefaults;
- (NSUInteger)_numberDigitsLength;
- (CGFloat)_fontSizeForLength:(NSUInteger)length;
@end

@implementation GCKNumberCircleView

@synthesize number;
@synthesize circleLineWidth;
@synthesize fontStrokeWidth;
@synthesize shadowSize;
@synthesize shadowBlur;
@synthesize backgroundColor;
@synthesize circleFillColor;
@synthesize circleStrokeColor;
@synthesize fontStrokeColor;
@synthesize fontFillColor;
@synthesize shadowColor;

- (void)dealloc
{
	[shadowSize release];
	shadowSize = nil;
	
	[backgroundColor release];
	backgroundColor = nil;
	
	[circleFillColor release];
	circleFillColor = nil;
	
	[circleStrokeColor release];
	circleStrokeColor = nil;
	
	[fontStrokeColor release];
	fontStrokeColor = nil;
	
	[fontFillColor release];
	fontFillColor = nil;
	
	[shadowColor release];
	shadowColor = nil;
	
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
	rect = [self bounds];

	const char* numStr = [[NSString stringWithFormat:@"%d\n", self.number]
						  cStringUsingEncoding:NSMacOSRomanStringEncoding];
	const NSUInteger numLen = [self _numberDigitsLength];
	
	float fontSize = [self _fontSizeForLength:numLen];
	
	CGColorRef csColor = CGColorCreateFromNSColor(circleStrokeColor);
	CGColorRef cfColor = CGColorCreateFromNSColor(circleFillColor);
	CGColorRef fsColor = CGColorCreateFromNSColor(fontStrokeColor);
	CGColorRef ffColor = CGColorCreateFromNSColor(fontFillColor);
	CGColorRef shColor = CGColorCreateFromNSColor(shadowColor);
	
	CGContextRef context = [self currentCGContext];
	
	BOOL hasShadow = NO;
	
	CGSize sSize = NSSizeToCGSize([shadowSize sizeValue]);
	if (sSize.width > 0) {
		rect.size.width -= sSize.width+1.0f;
		hasShadow = YES;
	}
	
	if (sSize.height > 0) {
		rect.size.height -= sSize.height+1.0f;
		hasShadow = YES;
	}
	
	float w = rect.size.width;
	float h = rect.size.height;
	
	CGContextSaveGState(context);
	CGContextSetFillColorWithColor(context, cfColor);
	CGContextAddEllipseInRect(context, CGRectInset(NSRectToCGRect(rect), circleLineWidth, circleLineWidth));
	CGContextFillPath(context);
	CGContextRestoreGState(context);
	
	float txtScale = fontSize/29.0f;
	
	CGContextSaveGState(context);
	CGAffineTransform textTransform = CGAffineTransformMakeScale(txtScale, -txtScale);
	CGContextSetTextMatrix(context, textTransform);
	CGContextSelectFont(context, "Helvetica-Bold", 40, kCGEncodingMacRoman);
	CGContextSetCharacterSpacing(context, 0.0f);
	CGContextSetLineWidth(context, fontStrokeWidth);
	CGContextSetStrokeColorWithColor(context, fsColor);
	CGContextSetFillColorWithColor(context, ffColor);
	
	if (hasShadow && CGColorGetAlpha(cfColor) <= 0.0f)
		CGContextSetShadowWithColor(context, CGSizeMake(sSize.width, -sSize.height), shadowBlur, shColor);
	
	CGPoint beforeTextPos = CGContextGetTextPosition(context);
	
	CGContextSetTextDrawingMode(context, kCGTextInvisible);
	CGContextShowText(context, numStr, numLen);
	
	CGPoint afterTextPos = CGContextGetTextPosition(context);
	
	CGFloat textWidth = afterTextPos.x - beforeTextPos.x;
	
	CGContextSetTextDrawingMode(context, kCGTextFillStroke);
	CGContextShowTextAtPoint(context,
							 (w-textWidth)/2,
							 (h+fontSize)/2,
							 numStr,
							 numLen);
	
	CGContextRestoreGState(context);
	
	CGContextSaveGState(context);
	CGContextSetStrokeColorWithColor(context, csColor);
	CGContextSetLineWidth(context, circleLineWidth);
	if (hasShadow)
		CGContextSetShadowWithColor(context, CGSizeMake(sSize.width, -sSize.height), shadowBlur, shColor);
	CGContextAddEllipseInRect(context, CGRectInset(NSRectToCGRect(rect), circleLineWidth/2, circleLineWidth/2));
	CGContextStrokePath(context);
	CGContextRestoreGState(context);
	
	CGColorRelease(csColor);
	CGColorRelease(cfColor);
	CGColorRelease(fsColor);
	CGColorRelease(ffColor);
	CGColorRelease(shColor);
}

- (void)_setDefaults
{
	self.number = 1;
	self.circleLineWidth = 5.0f;
	self.fontStrokeWidth = 0.0f;
	self.shadowSize = [NSValue valueWithSize:NSMakeSize(0.0f, 0.0f)];
	self.shadowBlur = 1.0f;
	
	self.backgroundColor = [NSColor colorWithCalibratedRed:1.0f green:1.0f blue:1.0f alpha:0.0f];
	self.circleFillColor = [NSColor colorWithCalibratedRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
	self.circleStrokeColor = [NSColor colorWithCalibratedRed:.6f green:.6f blue:.6f alpha:1.0f];
	self.fontStrokeColor = [NSColor colorWithCalibratedRed:.7f green:.7f blue:.7f alpha:1.0f];
	self.fontFillColor = [NSColor colorWithCalibratedRed:.6f green:.6f blue:.6f alpha:1.0f];
	self.shadowColor = [NSColor colorWithCalibratedRed:0.0f green:0.0f blue:0.0f alpha:0.5f];
}

- (NSUInteger)_numberDigitsLength
{
	float n = (float)self.number;
	NSUInteger c = 1;
	
	while ((n /= 10.0f) >= 1.0f)
		c++;
	
	return c;
}

- (CGFloat)_fontSizeForLength:(NSUInteger)length
{
	CGSize sSize = NSSizeToCGSize([shadowSize sizeValue]);
	CGFloat ySize =
	[self bounds].size.height - 2*circleLineWidth - sSize.height - ((sSize.height > 0.0f) ? 1.0f : 0.0f);
	
	switch (length) {
		case 1:
			return 0.675f*ySize;
		case 2:
			return 0.5f*ySize;
		case 3:
			return 0.35*ySize;
		case 4:
			return 0.275*ySize;
		default:
			return 0.1*ySize;
	}
	
	return 0.0f;
}

#pragma mark -
#pragma mark Observing

- (NSArray*)keysAffectingDisplay
{
	return [NSArray arrayWithObjects:@"number",
			@"circleLineWidth",
			@"fontStrokeWidth",
			@"shadowSize",
			@"shadowBlur",
			@"backgroundColor",
			@"circleFillColor",
			@"circleStrokeColor",
			@"fontStrokeColor",
			@"fontFillColor",
			@"shadowColor",
			nil];
}

@end
