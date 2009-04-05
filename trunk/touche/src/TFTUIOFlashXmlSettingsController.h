//
//  TFTUIOFlashXmlSettingsController.h
//  Touché
//
//  Created by Georg Kaindl on 8/9/08.
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


@class TFFlashXMLTUIOTrackingDataDistributor;

@interface TFTUIOFlashXmlSettingsController : NSWindowController {
	TFFlashXMLTUIOTrackingDataDistributor*	distributor;
	
	IBOutlet NSTextField*					_serverPortField;
	IBOutlet NSPopUpButton*					_defaultTuioVersionPopup;
}

@property (nonatomic, retain) TFFlashXMLTUIOTrackingDataDistributor* distributor;

+ (float)pixelsForBlobMotion;
+ (void)bindPixelsForBlobMotionToObject:(id)object keyPath:(NSString*)keyPath;
+ (void)bindDefaultTuioVersionToObject:(id)object keyPath:(NSString*)keyPath;

+ (UInt16)serverPort;
+ (NSString*)serverAddress;

- (id)init;
- (void)dealloc;

- (void)setDistributor:(TFFlashXMLTUIOTrackingDataDistributor*)newDistributor;

- (void)windowDidLoad;
- (void)showWindow:(id)sender;

- (IBAction)changeServerInterfaceSetting:(id)sender;
- (IBAction)changeServerPort:(id)sender;

- (IBAction)openFlashOptions:(id)sender;

#pragma mark -
#pragma mark NSWindow delegate

- (NSSize)windowWillResize:(NSWindow*)sender toSize:(NSSize)frameSize;

#pragma mark -
#pragma mark NSControl delegate

- (BOOL)control:(NSControl*)control didFailToFormatString:(NSString*)string errorDescription:(NSString*)error;

@end
