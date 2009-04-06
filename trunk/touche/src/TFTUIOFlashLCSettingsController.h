//
//  TFTUIOFlashLCSettingsController.h
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

#import <Cocoa/Cocoa.h>


@class TFTUIOFlashLCTrackingDataDistributor;

@interface TFTUIOFlashLCSettingsController : NSWindowController {
	TFTUIOFlashLCTrackingDataDistributor*	distributor;
	
	IBOutlet NSTextField*		_connectionNameField;
	IBOutlet NSTextField*		_connectionMethodField;
	IBOutlet NSTextField*		_connectionNameAlternateLabel;
	IBOutlet NSPopUpButton*		_defaultTuioVersionPopup;
}

@property (nonatomic, retain) TFTUIOFlashLCTrackingDataDistributor* distributor;

- (void)setDistributor:(TFTUIOFlashLCTrackingDataDistributor*)newDistributor;

- (id)init;
- (void)dealloc;

- (void)showWindow:(id)sender;

#pragma mark -
#pragma mark NSTextField Delegate

- (void)controlTextDidChange:(NSNotification*)aNotification;
@end
