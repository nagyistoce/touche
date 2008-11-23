//
//  GCKGradientOverlayView.m
//  Touché
//
//  Created by Georg Kaindl on 23/11/08.
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

#import "GCKGradientOverlayView.h"


@implementation GCKGradientOverlayView

- (void)dealloc
{
	[_gradient release];
	_gradient = nil;
	
	[super dealloc];
}

- (void)drawRect:(NSRect)rect
{
	if (nil == _gradient)
		_gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0.91 alpha:1.0]
												  endingColor:[NSColor colorWithDeviceWhite:0.91 alpha:0.1]];

	NSRect superBounds = [[self superview] bounds];
	NSRect frame = [self frame];
	CGFloat angle = (frame.origin.y >= superBounds.size.height/2.0) ? -90.0 : 90.0;
	
	[_gradient drawInRect:[self bounds] angle:angle];
}

@end
