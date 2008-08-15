//
//  GCKIPhoneNavigationBarLabelView.m
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

#import "GCKIPhoneNavigationBarLabelView.h"

#import "CGColorFromNSColor.h"
#import "NSView+Extras.h"

@interface GCKIPhoneNavigationBarLabelView (NonPublicMethods)
- (void)_setDefaults;
@end

@implementation GCKIPhoneNavigationBarLabelView

@synthesize string;
@synthesize fontName;
@synthesize fontSize;
@synthesize fontStrokeWidth;
@synthesize textAlignX;
@synthesize textAlignY;
@synthesize shadowSize;
@synthesize shadowBlur;
@synthesize shadowColor;
@synthesize fontFillColor;
@synthesize fontStrokeColor;

- (void)dealloc
{
	self.string = nil;
	self.fontName = nil;
	self.shadowSize = nil;
	self.shadowColor = nil;
	self.fontFillColor = nil;
	self.fontStrokeColor = nil;
	
	[super dealloc];
}

- (id)initWithFrame:(NSRect)frame
{
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

	CGContextRef context = [self currentCGContext];
	
	const char* str = [string cStringUsingEncoding:NSMacOSRomanStringEncoding];
	unsigned strLen = strlen(str);
	
	CGColorRef fsColor = CGColorCreateFromNSColor(fontStrokeColor);
	CGColorRef ffColor = CGColorCreateFromNSColor(fontFillColor);
	CGColorRef shColor = CGColorCreateFromNSColor(shadowColor);
	
	CGContextSaveGState(context);
	CGAffineTransform textTransform = CGAffineTransformMakeScale(1.0f, -1.0f);
	CGContextSetTextMatrix(context, textTransform);
	
	CGContextSelectFont(context, [fontName UTF8String], fontSize, kCGEncodingMacRoman);
	CGContextSetCharacterSpacing(context, 0.0f);
	CGContextSetLineWidth(context, fontStrokeWidth);
	CGContextSetStrokeColorWithColor(context, fsColor);
	CGContextSetFillColorWithColor(context, ffColor);
	
	CGSize sSize = NSSizeToCGSize([shadowSize sizeValue]);
	if (sSize.width != 0 || sSize.height != 0)
		CGContextSetShadowWithColor(context, CGSizeMake(sSize.width, -sSize.height), shadowBlur, shColor);
	
	CGPoint beforeTextPos = CGContextGetTextPosition(context);
	
	CGContextSetTextDrawingMode(context, kCGTextInvisible);
	CGContextShowText(context, str, strLen);
	
	CGPoint afterTextPos = CGContextGetTextPosition(context);
	
	CGFloat textWidth = afterTextPos.x - beforeTextPos.x;
	CGFloat textHeight = fontSize;
	
	CGFloat w = rect.size.width;
	CGFloat h = rect.size.height;
	CGFloat xPos, yPos;
	switch(textAlignX) {
		case GCKIPhoneNavigationBarLabelViewTextAlignCenter:
			xPos = (w-textWidth)/2.0f;
			break;
		case GCKIPhoneNavigationBarLabelViewTextAlignRight:
			xPos = w-textWidth;
			break;
		default:
			xPos = 0.0f;
			break;
	}
	
	switch(textAlignY) {
		case GCKIPhoneNavigationBarLabelViewTextAlignCenter:
			yPos = (h+textHeight/2.0)/2.0;
			break;
		case GCKIPhoneNavigationBarLabelViewTextAlignBottom:
			yPos = h-textHeight/2.0;
			break;
		default:
			yPos = textHeight;
	}
	
	CGContextSetTextDrawingMode(context, kCGTextFillStroke);
	CGContextShowTextAtPoint(context,
							 xPos,
							 yPos,
							 str,
							 strLen);
	
	CGContextRestoreGState(context);
	
	CGColorRelease(fsColor);
	CGColorRelease(ffColor);
	CGColorRelease(shColor);
}

- (void)_setDefaults
{
	self.string = @"GCKObservingForDisplayView";
	self.fontName = @"Helvetica-Bold";
	self.fontSize = 20.0f;
	self.fontStrokeWidth = 0.0f;
	self.textAlignX = GCKIPhoneNavigationBarLabelViewTextAlignLeft;
	self.textAlignY = GCKIPhoneNavigationBarLabelViewTextAlignTop;
	self.shadowSize = [NSValue valueWithSize:NSMakeSize(0.0f, -1.0f)];
	self.shadowBlur = 0.0f;
	self.shadowColor = [NSColor colorWithCalibratedRed:.0f green:.0f blue:.0f alpha:.4f];
	self.fontFillColor = [NSColor whiteColor];
	self.fontStrokeColor = [NSColor whiteColor];
}

#pragma mark -
#pragma mark Observing

- (NSArray*)keysAffectingDisplay
{
	return [NSArray arrayWithObjects:
			@"string",
			@"fontName",
			@"fontSize",
			@"fontStrokeWidth",
			@"textAlignX",
			@"textAlignY",
			@"shadowSize",
			@"shadowBlur",
			@"shadowColor",
			@"fontStrokeColor",
			@"fontFillColor",
			nil];
}

@end
