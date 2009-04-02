//
//  TFTUIOOSCSettingsController.h
//  Touché
//
//  Created by Georg Kaindl on 25/8/08.
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

#import <Cocoa/Cocoa.h>


@class TFTUIOOSCTrackingDataDistributor;

@interface TFTUIOOSCSettingsController : NSWindowController {
	TFTUIOOSCTrackingDataDistributor*	distributor;
	IBOutlet NSPanel*				_addClientPanel;
	IBOutlet NSTextField*			_addClientHostField;
	IBOutlet NSTextField*			_addClientPortField;
	IBOutlet NSTextField*			_addClientErrorLabel;
	IBOutlet NSProgressIndicator*	_addClientProgressIndicator;
	IBOutlet NSPopUpButton*			_addClientTUIOVersionPopup;
	
	BOOL							_addClientPanelShown;
	NSThread*						_addClientThread;
}

@property (nonatomic, retain) TFTUIOOSCTrackingDataDistributor* distributor;

+ (void)initialize;
+ (float)pixelsForBlobMotion;
+ (void)bindPixelsForBlobMotionToObject:(id)object keyPath:(NSString*)keyPath;

- (void)awakeFromNib;
- (id)init;
- (void)dealloc;

- (void)setDistributor:(TFTUIOOSCTrackingDataDistributor*)newDistributor;

- (IBAction)showAddClientPanel:(id)sender;
- (IBAction)addClientFromPanel:(id)sender;

- (void)windowDidLoad;

#pragma mark -
#pragma mark NSWindow delegate

- (NSSize)windowWillResize:(NSWindow*)sender toSize:(NSSize)frameSize;
- (void)windowDidBecomeKey:(NSNotification*)notification;
- (void)windowWillClose:(NSNotification*)notification;

@end
