//
//  TFTrackingDataReceiverCell.m
//  Touché
//
//  Created by Georg Kaindl on 9/5/08.
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

#import "TFTrackingDataReceiverCell.h"

#import "TFIncludes.h"
#import "TFTrackingDataReceiver.h"
#import "TFTrackingDataDistributor.h"


#define	PADDINGX			((CGFloat)12.0f)
#define PADDINGY			((CGFloat)6.0f)
#define PADDINGYTITLE		((CGFloat)4.0f)
#define PADDINGXTITLE		((CGFloat)10.0f)
#define PADDINGYVERSION		((CGFloat)2.0f)

@interface TFTrackingDataReceiverCell (NonPublicMethods)
- (void)_setDefaults;
- (NSRect)_iconRectForFrame:(NSRect)frame;
- (NSRect)_nameRectForFrame:(NSRect)frame
				 nameString:(NSAttributedString*)nameString
		 relativeToIconRect:(NSRect)iconRect;
- (NSRect)_versionRectForFrame:(NSRect)frame
				 versionString:(NSAttributedString*)versionString
			relativeToNameRect:(NSRect)nameRect;
- (NSImage*)_icon;
- (NSAttributedString*)_attributedNameWithColor:(NSColor*)color;
- (NSAttributedString*)_attributedVersionWithColor:(NSColor*)color;
- (NSAttributedString*)_attributedString:(NSString*)string
						  withAttributes:(NSMutableDictionary*)attr
								andColor:(NSColor*)color;
- (void)_receiverShouldQuitClicked:(id)sender;
- (NSDictionary*)_receiverInfoDict;
@end

@implementation TFTrackingDataReceiverCell

- (void)awakeFromNib
{
	[self _setDefaults];
}

- (void)dealloc
{
	[_nameAttributes release];
	_nameAttributes = nil;
	
	[_versionAttributes release];
	_versionAttributes = nil;
	
	[super dealloc];
}

- (id)init
{
	if (!(self = [super init])) {
		[self release];
		return nil;
	}
	
	return self;
}

- (void)_setDefaults
{		
	NSMutableParagraphStyle* pStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[pStyle setLineBreakMode:NSLineBreakByTruncatingTail];
	
	_nameAttributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
					   pStyle, NSParagraphStyleAttributeName,
					   [NSFont systemFontOfSize:14.0], NSFontAttributeName,
					   nil];
	_versionAttributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
						  pStyle, NSParagraphStyleAttributeName,
						  [NSFont systemFontOfSize:9.0], NSFontAttributeName,
						  nil];
	
	[pStyle release];
		
	NSMenu* menu = [[NSMenu alloc] init];
	
	NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:TFLocalizedString(@"TellClientToQuit", @"TellClientToQuit")
												  action:nil
										   keyEquivalent:[NSString string]];
	[item setTarget:self];
	[item setAction:@selector(_receiverShouldQuitClicked:)];
	[menu addItem:item];
	[item release];
	
	[self setMenu:menu];
	
	[menu release];
}

- (void)drawInteriorWithFrame:(NSRect)frame inView:(NSView *)controlView
{
	NSImage* icon = [self _icon];
	NSRect iconFrame = [self _iconRectForFrame:frame];
	
	[icon drawInRect:iconFrame
			fromRect:NSZeroRect
		   operation:NSCompositeSourceOver
			fraction:1.0f];
			
	NSAttributedString* name = [self _attributedNameWithColor:nil];
	NSRect nameRect = [self _nameRectForFrame:frame nameString:name relativeToIconRect:iconFrame];
	[name drawInRect:nameRect];
	
	NSAttributedString* version = [self _attributedVersionWithColor:[NSColor colorWithCalibratedWhite:.6f alpha:1.0f]];
	NSRect versionRect = [self _versionRectForFrame:frame versionString:version relativeToNameRect:nameRect];
	[version drawInRect:versionRect];
}

- (BOOL)acceptsFirstResponder
{
	return NO;
}

- (NSAttributedString*)_attributedNameWithColor:(NSColor*)color
{
	return [self _attributedString:[[self _receiverInfoDict] objectForKey:kToucheTrackingReceiverInfoHumanReadableName]
					withAttributes:_nameAttributes
						  andColor:color];
}

- (NSAttributedString*)_attributedVersionWithColor:(NSColor*)color
{
	NSString* versionString = [NSString stringWithFormat:@"%@ %@",
							   TFLocalizedString(@"Version", @"Version"),
							   [[self _receiverInfoDict] objectForKey:kToucheTrackingReceiverInfoVersion]];
	
	return [self _attributedString:versionString
					withAttributes:_versionAttributes
						  andColor:color];
}

- (NSAttributedString*)_attributedString:(NSString*)string
						  withAttributes:(NSMutableDictionary*)attr
								andColor:(NSColor*)color
{
	if (nil == color)
		color = [NSColor controlTextColor];
		
	[attr setObject:color forKey:NSForegroundColorAttributeName];
	
	return [[[NSAttributedString alloc] initWithString:string attributes:attr] autorelease];
}

- (NSImage*)_icon
{
	NSImage* icon = (NSImage*)[[self _receiverInfoDict] valueForKey:kToucheTrackingReceiverInfoIcon];
	[icon setFlipped:YES];
	[icon setScalesWhenResized:YES];
		
	return icon;
}

- (NSRect)_iconRectForFrame:(NSRect)frame
{
	frame.origin.x += PADDINGX;
	frame.origin.y += PADDINGY;
	frame.size.height -= 2*PADDINGY;
	frame.size.width = frame.size.height;
	
	return frame;
}

- (NSRect)_nameRectForFrame:(NSRect)frame
				 nameString:(NSAttributedString*)nameString
		 relativeToIconRect:(NSRect)iconRect
{
	NSRect nameRect = iconRect;
	nameRect.origin.x += nameRect.size.width + PADDINGXTITLE;
	nameRect.origin.y += PADDINGYTITLE;
	nameRect.size = [nameString size];
	
	nameRect.size.width = MIN(nameRect.size.width,
							   (NSMaxX(frame) - PADDINGX - nameRect.origin.x));
	
	return nameRect;
}

- (NSRect)_versionRectForFrame:(NSRect)frame
				 versionString:(NSAttributedString*)versionString
			relativeToNameRect:(NSRect)nameRect
{
	NSRect versionRect = nameRect;
	versionRect.origin.y += versionRect.size.height + PADDINGYVERSION;
	versionRect.size = [versionString size];
	
	versionRect.size.width = MIN(versionRect.size.width,
							  (NSMaxX(frame) - PADDINGX - versionRect.origin.x));
	
	return versionRect;
}

- (void)_receiverShouldQuitClicked:(id)sender
{
	TFTrackingDataReceiver* receiver = (TFTrackingDataReceiver*)[self objectValue];
	TFTrackingDataDistributor* distributor = receiver.owningDistributor;
	
	if ([distributor canAskReceiversToQuit])
		[distributor askReceiverToQuit:receiver];
}

- (NSDictionary*)_receiverInfoDict
{
	return [(TFTrackingDataReceiver*)[self objectValue] infoDictionary];
}

#pragma mark -
#pragma mark NSCopying protocol

- (id)copyWithZone:(NSZone *)zone
{
	TFTrackingDataReceiverCell* aCopy = [super copyWithZone:zone];
	
	aCopy->_nameAttributes = [_nameAttributes copy];
	aCopy->_versionAttributes = [_versionAttributes copy];
	
	return aCopy;
}

@end
