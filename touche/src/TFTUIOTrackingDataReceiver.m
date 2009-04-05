//
//  TFTUIOTrackingDataReceiver.h
//  Touché
//
//  Created by Georg Kaindl on 4/4/09.
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

#import "TFTUIOTrackingDataReceiver.h"

#import "TFIncludes.h"
#import "TFTrackingDataDistributor.h"


@interface TFTUIOTrackingDataReceiver (PrivateMethods)
- (void)_disconnectReceiverClicked:(id)sender;
- (void)_tuioVersionChanged:(id)sender;
@end

@implementation TFTUIOTrackingDataReceiver

@synthesize tuioVersion;

- (id)init
{
	if (nil != (self = [super init])) {
		self->tuioVersion = TFTUIOVersionDefault;
		self->_contextualMenu = nil;
	}
	
	return self;
}

- (void)dealloc
{
	[self->_contextualMenu release];
	self->_contextualMenu = nil;
	
	[self->_tuioVersionMenu release];
	self->_tuioVersionMenu = nil;
	
	[super dealloc];
}

- (NSMenu*)contextualMenuForReceiver
{
	if (nil == _contextualMenu) {
		_contextualMenu = [[super contextualMenuForReceiver] retain];
		
		if (nil == _contextualMenu)
			_contextualMenu = [[NSMenu alloc] init];
		
		NSMenuItem* item = nil;
	
		if ([self.owningDistributor canAskReceiversToQuit]) {
			item = [[NSMenuItem alloc] initWithTitle:TFLocalizedString(@"DisconnectClient", @"DisconnectClient")
											  action:nil
									   keyEquivalent:[NSString string]];
			[item setTarget:self];
			[item setAction:@selector(_disconnectReceiverClicked:)];
			[_contextualMenu addItem:item];
			[item release];
		}
		
		_tuioVersionMenu = [TFTUIOVersionSelectionMenu() retain];
		[_tuioVersionMenu setDelegate:self];
		
		for (NSMenuItem* versionItem in [_tuioVersionMenu itemArray]) {
			[versionItem setTarget:self];
			[versionItem setAction:@selector(_tuioVersionChanged:)];
		}
								
		item = [[NSMenuItem alloc] initWithTitle:[_tuioVersionMenu title]
										  action:NULL
								   keyEquivalent:[NSString string]];
		
		[item setSubmenu:_tuioVersionMenu];
		[_contextualMenu addItem:item];		
		[item release];
	}
	
	return _contextualMenu;
}

#pragma mark -
#pragma mark NSMenu delegate

- (void)menuNeedsUpdate:(NSMenu *)menu
{	
	if (self->_tuioVersionMenu == menu) {
		for (NSMenuItem* versionItem in [_tuioVersionMenu itemArray]) {
			NSInteger state = ([versionItem tag] == self->tuioVersion) ? NSOnState : NSOffState;
			[versionItem setState:state];
		}
	}
}

#pragma mark -
#pragma mark Private Methods

- (void)_disconnectReceiverClicked:(id)sender
{
	TFTrackingDataDistributor* distributor = self.owningDistributor;
	
	if ([distributor canAskReceiversToQuit])
		[distributor askReceiverToQuit:self];
}

- (void)_tuioVersionChanged:(id)sender
{
	self.tuioVersion = [(NSMenuItem*)sender tag];
}

@end
