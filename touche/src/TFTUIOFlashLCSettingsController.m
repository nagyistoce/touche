//
//  TFTUIOFlashLCSettingsController.m
//  Touché
//
//  Created by Georg Kaindl on 5/4/09.
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

#import "TFTUIOFlashLCSettingsController.h"

#import "TFTUIOConstants.h"
#import "TFTUIOFlashLCTrackingDataDistributor.h"


NSString* _TFTUIOFlashLCSettingsControllerConnectionNamePrefKey		= @"tFTUIOFlashLCSettingsControllerConnectionName";
NSString* _TFTUIOFlashLCSettingsControllerConnectionMethodPrefKey	= @"tFTUIOFlashLCSettingsControllerConnectionMethod";
NSString* _TFTUIOFlashLCSettingsControllerDefaultTUIOVersionPrefKey	= @"tFTUIOFlashLCSettingsControllerDefaultTUIOVersion";
NSString* _TFTUIOFlashLCSettingsControllerPixelsForMotionPrefKey	= @"tFTUIOFlashLCSettingsControllerPixelsForMotion";

@interface TFTUIOFlashLCSettingsController (PrivateMethods)
- (void)_updateAlternateConnectionNamesLabel:(NSString*)newName;
@end

@implementation TFTUIOFlashLCSettingsController

@synthesize distributor;

- (id)init
{
	if (nil != (self = [super initWithWindowNibName:@"TUIOFlashLCSettings"])) {
	}
	
	return self;
}

- (void)dealloc
{
	[self->distributor release];
	self->distributor = nil;
	
	[super dealloc];
}

- (void)setDistributor:(TFTUIOFlashLCTrackingDataDistributor*)newDistributor
{
	if (newDistributor != self->distributor) {
		[distributor unbind:@"motionThreshold"];
		[distributor unbind:@"defaultTuioVersion"];
		[distributor unbind:@"receiverConnectionName"];
		[distributor unbind:@"receiverMethodName"];
		
		[newDistributor bind:@"motionThreshold"
					toObject:[NSUserDefaultsController sharedUserDefaultsController]
				 withKeyPath:[NSString stringWithFormat:@"values.%@", _TFTUIOFlashLCSettingsControllerPixelsForMotionPrefKey]
					 options:nil];
		
		[newDistributor bind:@"defaultTuioVersion"
					toObject:[NSUserDefaultsController sharedUserDefaultsController]
				 withKeyPath:[NSString stringWithFormat:@"values.%@", _TFTUIOFlashLCSettingsControllerDefaultTUIOVersionPrefKey]
					 options:nil];
		
		[newDistributor bind:@"receiverConnectionName"
					toObject:[NSUserDefaultsController sharedUserDefaultsController]
				 withKeyPath:[NSString stringWithFormat:@"values.%@", _TFTUIOFlashLCSettingsControllerConnectionNamePrefKey]
					 options:nil];
		
		[newDistributor bind:@"receiverMethodName"
					toObject:[NSUserDefaultsController sharedUserDefaultsController]
				 withKeyPath:[NSString stringWithFormat:@"values.%@", _TFTUIOFlashLCSettingsControllerConnectionMethodPrefKey]
					 options:nil];
		
		[distributor release];
		self->distributor = [newDistributor retain];
	}
}

- (void)showWindow:(id)sender
{
	[self _updateAlternateConnectionNamesLabel:nil];
	
	[super showWindow:sender];
}

- (void)windowDidLoad
{
	[[self window] setShowsResizeIndicator:NO];

	[self _updateAlternateConnectionNamesLabel:nil];
	
	[_defaultTuioVersionPopup setMenu:TFTUIOVersionSelectionMenu()];
	[_defaultTuioVersionPopup bind:@"selectedTag"
						  toObject:[NSUserDefaultsController sharedUserDefaultsController]
					   withKeyPath:[NSString stringWithFormat:@"values.%@",
										_TFTUIOFlashLCSettingsControllerDefaultTUIOVersionPrefKey]
						   options:nil];
}

#pragma mark -
#pragma mark NSTextField Delegate

- (void)controlTextDidChange:(NSNotification*)aNotification
{
	NSTextField* textField = [aNotification object];
	
	if (textField == _connectionNameField || textField == _connectionMethodField) {
		NSMutableCharacterSet* nonAsciiSet = [NSMutableCharacterSet characterSetWithRange:NSMakeRange(0, 128)];
		[nonAsciiSet formIntersectionWithCharacterSet:[NSCharacterSet alphanumericCharacterSet]];
		[nonAsciiSet addCharactersInString:@"_"];
		[nonAsciiSet invert];
		
		NSString* val = [textField stringValue];
		
		NSRange range = [val rangeOfCharacterFromSet:nonAsciiSet];
		while (NSNotFound != range.location) {
			val = [val stringByReplacingCharactersInRange:range withString:@""];
			range = [val rangeOfCharacterFromSet:nonAsciiSet];
		}
	
		if (textField == _connectionNameField) {
			if (![val hasPrefix:@"_"])
				val = [NSString stringWithFormat:@"_%@", val];
			
			[self _updateAlternateConnectionNamesLabel:val];
		}
		
		[textField setStringValue:val];
	}
}

#pragma mark -
#pragma mark Private Methods

- (void)_updateAlternateConnectionNamesLabel:(NSString*)newName
{
	if (nil == newName)
		newName = [[NSUserDefaults standardUserDefaults] objectForKey:_TFTUIOFlashLCSettingsControllerConnectionNamePrefKey];
	
	NSString* str = [NSString stringWithFormat:@"Multiple clients can connect by appending digits to the connection name, like %@1, %@2 and so on.",
					 newName, newName];
	
	[_connectionNameAlternateLabel setStringValue:str];
}

@end
