//
//  GCKHUDTableView.m
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

#import "GCKHUDTableView.h"

#import "GCKHUDTableCell.h"


NSColor* rowColor, *alternateRowColor, *highlightColor;

@implementation GCKHUDTableView

+ (void)initialize
{
	rowColor			= [[NSColor colorWithCalibratedWhite:0.125 alpha:0.85] retain];
    alternateRowColor	= [[NSColor colorWithCalibratedWhite:0.155 alpha:0.85] retain];
	highlightColor		= [[NSColor colorWithCalibratedWhite:0.3 alpha:0.85] retain];
}

+ (Class)cellClass
{
	return [GCKHUDTableCell class];
}

- (void)drawBackgroundInClipRect:(NSRect)clipRect
{
	if ([self usesAlternatingRowBackgroundColors])
		[super drawBackgroundInClipRect:clipRect];
}

- (NSColor*)backgroundColor
{
	return rowColor;
}

// hack
- (NSArray*)_alternatingRowBackgroundColors
{
	return [NSArray arrayWithObjects:rowColor, alternateRowColor, nil];
}

// hack
- (NSColor*)_highlightColorForCell:(NSCell*)cell
{
	return nil;
}

- (void)highlightSelectionInClipRect:(NSRect)theClipRect
{
	NSRange	visibleRows = [self rowsInRect:theClipRect];
	NSIndexSet*	selectedRows = [self selectedRowIndexes];
	NSInteger row;
	
	NSColor* startColor = [NSColor colorWithCalibratedWhite:0.33 alpha:0.85];
	NSColor* endColor = [NSColor colorWithCalibratedWhite:0.275 alpha:0.85];
	NSGradient* gradient = [[NSGradient alloc] initWithStartingColor:startColor
														 endingColor:endColor];
	
    for (row = visibleRows.location; row < visibleRows.location + visibleRows.length; row++) {
		if ([selectedRows containsIndex:row]) {
			[NSGraphicsContext saveGraphicsState];
			[[NSGraphicsContext currentContext] setCompositingOperation:NSCompositeCopy];
			
			NSRect rowRect = [self rectOfRow:row];
			rowRect.size.height -= 1;
			
			[gradient drawInRect:rowRect angle:90];
			
			[NSGraphicsContext restoreGraphicsState];
		}
	}
	
	[gradient release];
}

- (void)addTableColumn:(NSTableColumn* )column
{
	[super addTableColumn:column];
	
	if ([[[column dataCell] className] isEqualToString:@"NSTextFieldCell"]) {
		GCKHUDTableCell* cell = [[GCKHUDTableCell alloc] init];
		[column setDataCell:cell];
		[cell release];
	}
}

@end
