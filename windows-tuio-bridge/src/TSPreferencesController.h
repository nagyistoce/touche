//
//  TSPreferencesController.h
//  TouchsmartTUIO
//
//  Created by Georg Kaindl on 25/02/09.
//
//  Copyright (C) 2009 Georg Kaindl
//
//  This file is part of Touchsmart TUIO.
//
//  Touchsmart TUIO is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as
//  published by the Free Software Foundation, either version 3 of
//  the License, or (at your option) any later version.
//
//  Touchsmart TUIO is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public
//  License along with Touchsmart TUIO. If not, see <http://www.gnu.org/licenses/>.
//

#import <Cocoa/Cocoa.h>


extern NSString* PrefKeyPixelsForMotion;
extern NSString* PrefKeyFPS;
extern NSString* PrefKeyFlashXMLServerPort;
extern NSString* PrefKeyOSCTargetHost;
extern NSString* PrefKeyOSCTargetPort;

@class TFFlashXMLTUIOTrackingDataDistributor;
@class TFTUIOOSCTrackingDataDistributor;

@interface TSPreferencesController : NSWindowController {
	IBOutlet NSTextField*		flashXMLServerPortField;
	IBOutlet NSTextField*		oscHostField;
	IBOutlet NSTextField*		oscPortField;
	IBOutlet NSButton*			oscCommitButton;
	IBOutlet NSTextField*		oscChangeCompleteLabel;
	IBOutlet NSTextField*		flashXMLChangeCompleteLabel;
	
	TFFlashXMLTUIOTrackingDataDistributor*	flashXMLDistributor;
	TFTUIOOSCTrackingDataDistributor*		oscDistributor;
	
	NSThread*	_changeOSCClientThread;
	NSTimer*	_changeOSCCompleteLabelHideTimer;
	NSTimer*	_changeXMLCompleteLabelHideTimer;
}

@property (retain) TFFlashXMLTUIOTrackingDataDistributor* flashXMLDistributor;
@property (retain) TFTUIOOSCTrackingDataDistributor* oscDistributor;

+ (void)registerDefaults;

- (id)init;
- (void)dealloc;

- (IBAction)showWindow:(id)sender;

- (IBAction)changeFlashXMLServerPort:(id)sender;
- (IBAction)commitOSCTargetChange:(id)sender;

@end
