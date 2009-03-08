//
//  AppDelegate.h
//  TouchsmartTUIO
//
//  Created by Georg Kaindl on 25/2/09.
//  Copyright 2009 Georg Kaindl. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class TSTouchInputSource;
@class TSPreferencesController;
@class TFBlobLabelizer;
@class TFTrackingDataDistributionCenter;

@interface AppDelegate : NSObject {
	NSDictionary*				_deviceInfoDict;

	IBOutlet NSTableView*		_deviceInfoTableView;

	TSTouchInputSource*			_inputSource;
	TSPreferencesController*	_preferencesController;
	
	TFBlobLabelizer*					_labelizer;
	TFTrackingDataDistributionCenter*	_distributionCenter;
	
	NSTimeInterval					_updateInterval;
	NSThread*						_updateThread;
}

- (id)init;
- (void)dealloc;

- (void)awakeFromNib;

- (IBAction)showPreferences:(id)sender;

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context;

#pragma mark -
#pragma mark NSApplication delegate

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification;
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication*)sender;
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)sender;

#pragma mark -
#pragma mark TSTouchInputSource delegate

- (void)touchInputSource:(TSTouchInputSource*)source senderInfoDidChange:(NSDictionary*)senderInfoDict;

#pragma mark -
#pragma mark NSTableDataSource informal protocol

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;

#pragma mark -
#pragma mark NSTableView delegate

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex;

@end
