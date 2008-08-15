//
//  TFScreenPrefsMeasureView.m
//  Touché
//
//  Created by Georg Kaindl on 17/5/08.
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

#import "TFScreenPrefsMeasureView.h"

#import "TFIncludes.h"

@implementation TFScreenPrefsMeasureView

@synthesize thickness;
@synthesize color;

- (void)dealloc
{
	self.color = nil;
	
	[super dealloc];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		self.color = [NSColor colorWithCalibratedWhite:.5f alpha:1.0f];
		self.thickness = 6.0f;
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
    rect = [self bounds];
	
	NSRect lineRect = rect;
	lineRect.origin.y += rect.size.height/2.0f - thickness/2.0;
	lineRect.size.height = thickness;
	
	[color setFill];
	[NSBezierPath fillRect:lineRect];
	
	NSRect capRect = rect;
	capRect.size.width = thickness;
	
	[NSBezierPath fillRect:capRect];
	
	capRect.origin.x += rect.size.width - thickness;
	
	[NSBezierPath fillRect:capRect];
}

- (CGFloat)currentWidth
{
	return [self bounds].size.width;
}

- (NSArray*)keysAffectingDisplay
{
	return [NSArray arrayWithObjects:@"thickness", @"color", nil];
}

@end
