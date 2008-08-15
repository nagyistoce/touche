//
//  GCKPlatinumView.m
//
//  Created by Georg Kaindl on 7/5/08.
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

#import "GCKPlatinumView.h"


@implementation GCKPlatinumView

- (void)dealloc
{
	[_bgGradient release];
	_bgGradient = nil;
	
	[super dealloc];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
	if (_bgGradient == nil) {
		_bgGradient = [[NSGradient alloc]
					   initWithStartingColor:[NSColor colorWithCalibratedWhite:1.0f alpha:1.0f]
					   endingColor:[NSColor colorWithCalibratedWhite:.8f alpha:1.0f]];
	}
	
	[_bgGradient drawInRect:[self bounds] angle:-90.0];
}

@end
