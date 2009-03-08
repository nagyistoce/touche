//
//  AppDelegate.h
//  TouchsmartTUIO
//
//  Created by Georg Kaindl on 25/2/09.
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
