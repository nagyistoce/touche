//
//  GCKHUDTableCell.m
//  Touché
//
//  Created by Georg Kaindl on 28/3/09.
//
//  Copyright (C) 2009 Georg Kaindl
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

#import "GCKHUDTableCell.h"


@implementation GCKHUDTableCell

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if (![[self title] isEqualToString:@""])
	{
		NSColor *textColor;
		
		if (!self.isHighlighted)
			textColor = [NSColor colorWithCalibratedWhite:(198.0f / 255.0f) alpha:1];
		else
			textColor = [NSColor whiteColor];
		
		NSMutableDictionary *attributes = [[[NSMutableDictionary alloc] init] autorelease];
		[attributes addEntriesFromDictionary:[[self attributedStringValue] attributesAtIndex:0 effectiveRange:NULL]];
		[attributes setObject:textColor forKey:NSForegroundColorAttributeName];
		[attributes setObject:[NSFont systemFontOfSize:11] forKey:NSFontAttributeName];
		
		NSAttributedString* string = [[NSAttributedString alloc] initWithString:[self title]
																	 attributes:attributes];
		[self setAttributedStringValue:string];
		[string release];
	}
	
	cellFrame.size.width -= 1;
	cellFrame.origin.x += 1;
	
	[super drawInteriorWithFrame:cellFrame inView:controlView];
}

@end
