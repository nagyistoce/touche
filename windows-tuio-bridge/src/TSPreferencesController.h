//
//  TSPreferencesController.h
//  TouchsmartTUIO
//
//  Created by Georg Kaindl on 25/02/09.
//  Copyright 2009 Georg Kaindl. All rights reserved.
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
