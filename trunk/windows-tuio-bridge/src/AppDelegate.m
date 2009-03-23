//
//  AppDelegate.m
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

#import "AppDelegate.h"

#import "TSTouchInputSource.h"

#if defined(WINDOWS)
#import "TSNextwindowTouchInputSource.h"
#endif

#import "TSBlobLabelizer.h"
#import "TSPreferencesController.h"

#import "TFBlob.h"
#import "TFBlobLabel.h"
#import "TFBlobPoint.h"
#import "TFScreenPreferencesController.h"
#import "TFTrackingDataDistributionCenter.h"
#import "TFTUIOOSCTrackingDataDistributor.h"
#import "TFFlashXMLTUIOTrackingDataDistributor.h"
#import "TFTUIOFlashLCTrackingDataDistributor.h"

#define	DEFAULT_MOTION_THRESHOLD	(3.0)

#define DEVICE_TABLE_LABEL_COLUMN_ID		(@"labels")
#define DEVICE_TABLE_DATA_COLUMN_ID			(@"data")

@interface AppDelegate (PrivateMethods)
- (void)_distributionThread;
@end

NSString* TSLocalizedLabelForDeviceInfoKey(NSString* deviceInfoKey);

@implementation AppDelegate

- (id)init
{
	if (nil != (self = [super init])) {
	}
	
	return self;
}

- (void)dealloc
{
	[_deviceInfoDict release];
	_deviceInfoDict = nil;
	
	[_preferencesController release];
	_preferencesController = nil;
	
	@synchronized (_distributionCenter) {
		[_distributionCenter stopAllDistributors];
		[_distributionCenter invalidate];
		[_distributionCenter release];
		_distributionCenter = nil;
	}
	
#if defined(WINDOWS)
	[[NSUserDefaultsController sharedUserDefaultsController]
			removeObserver:self
				forKeyPath:[NSString stringWithFormat:@"values.%@", PrefKeyFPS]];
#else
	[[NSUserDefaults standardUserDefaults]
			removeObserver:self
				forKeyPath:PrefKeyFPS];
#endif
	
	[super dealloc];
}

- (void)awakeFromNib
{
	[TSPreferencesController registerDefaults];
	
	[_deviceInfoTableView setDataSource:self];
	[_deviceInfoTableView setDelegate:self];
}

- (IBAction)showPreferences:(id)sender
{	
	[_preferencesController showWindow:sender];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context
{	
	if ([object isEqual:[NSUserDefaultsController sharedUserDefaultsController]]) {
		if ([keyPath hasSuffix:PrefKeyFPS]) {
			NSTimeInterval t = (NSTimeInterval)[[change objectForKey:NSKeyValueChangeNewKey] doubleValue];
			if (t > 0)
				_updateInterval = 1.0/(NSTimeInterval)[[change objectForKey:NSKeyValueChangeNewKey] doubleValue];			
		}
	}
}

#pragma mark -
#pragma mark NSApplication delegate

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification
{	
	NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
	
	_preferencesController = [[TSPreferencesController alloc] init];
	
	_distributionCenter = [[TFTrackingDataDistributionCenter alloc] init];
	
	TFTUIOOSCTrackingDataDistributor* tuioDistributor = [[TFTUIOOSCTrackingDataDistributor alloc] init];
	[tuioDistributor startDistributorWithObject:nil error:NULL];
	tuioDistributor.motionThreshold = DEFAULT_MOTION_THRESHOLD;
	
	_preferencesController.oscDistributor = tuioDistributor;
	
	[tuioDistributor bind:@"motionThreshold"
				 toObject:[NSUserDefaultsController sharedUserDefaultsController]
			  withKeyPath:[NSString stringWithFormat:@"values.%@", PrefKeyPixelsForMotion]
				  options:nil];
	
	tuioDistributor.delegate = self;
	
	[_distributionCenter addDistributor:tuioDistributor];
	[tuioDistributor release];
	
	NSDictionary* flashXmlConfig = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSNull null], kTFFlashXMLTUIOTrackingDataDistributorLocalAddress,
									[userDefaults objectForKey:PrefKeyFlashXMLServerPort], kTFFlashXMLTUIOTrackingDataDistributorPort,
									nil];
	TFFlashXMLTUIOTrackingDataDistributor* flashDistributor = [[TFFlashXMLTUIOTrackingDataDistributor alloc] init];
	BOOL flashSuccess = [flashDistributor startDistributorWithObject:(id)flashXmlConfig error:NULL];
	flashDistributor.delegate = self;
	
	_preferencesController.flashXMLDistributor = flashDistributor;
	
	[flashDistributor bind:@"motionThreshold"
				  toObject:[NSUserDefaultsController sharedUserDefaultsController]
			   withKeyPath:[NSString stringWithFormat:@"values.%@", PrefKeyPixelsForMotion]
				   options:nil];
	
	if (!flashSuccess) {
		NSAlert* errorAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"SetupFlashXMLSocketError", @"SetupFlashXMLSocketError")
											  defaultButton:NSLocalizedString(@"Alright", @"Alright")
											alternateButton:nil
												otherButton:nil
								  informativeTextWithFormat:[NSString stringWithFormat:NSLocalizedString(@"SetupFlashXMLSocketErrorDesc", @"SetupFlashXMLSocketErrorDesc"),
															 IntegerPrefKey(userDefaults, PrefKeyFlashXMLServerPort)]];
		
		[errorAlert runModal];
	}
	
	[_distributionCenter addDistributor:flashDistributor];
	[flashDistributor release];
	
	// flash LocalConnection distributor
	TFTUIOFlashLCTrackingDataDistributor* flashLCDistributor = [[TFTUIOFlashLCTrackingDataDistributor alloc] init];
	flashLCDistributor.delegate = self;
	
	[flashLCDistributor startDistributorWithObject:nil error:NULL];
	
	[_distributionCenter addDistributor:flashLCDistributor];
	[flashLCDistributor release];
	
	// add the TUIO target
	if (![tuioDistributor addTUIOClientAtHost:[userDefaults objectForKey:PrefKeyOSCTargetHost]
										 port:IntegerPrefKey(userDefaults, PrefKeyOSCTargetPort)
										error:NULL]) {
		NSAlert* errorAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"SetupTUIOTargetError", @"SetupTUIOTargetError")
											  defaultButton:NSLocalizedString(@"Alright", @"Alright")
											alternateButton:nil
												otherButton:nil
								  informativeTextWithFormat:[NSString stringWithFormat:NSLocalizedString(@"SetupTUIOTargetErrorDesc", @"SetupTUIOTargetErrorDesc"),
															 [userDefaults objectForKey:PrefKeyOSCTargetHost],
															 IntegerPrefKey(userDefaults, PrefKeyOSCTargetPort)]];
		
		[errorAlert runModal];
	}
	
	_labelizer = [[TSBlobLabelizer alloc] init];
		
	// Set up the distribution thread
	_updateInterval = 1.0/(NSTimeInterval)FloatPrefKey(userDefaults, PrefKeyFPS);
		
	_updateThread = [[NSThread alloc] initWithTarget:self
											selector:@selector(_distributionThread)
											  object:nil];
	[_updateThread start];
	
	// add observers. I'd usually bind to [NSUserDefaults sharedUserDefaults] directly, but
	// Cocotron doesn't like this, so I'm binding to the shared user defaults controller instead.
#if defined(WINDOWS)
	[[NSUserDefaultsController sharedUserDefaultsController]
				addObserver:self
				 forKeyPath:[NSString stringWithFormat:@"values.%@", PrefKeyFPS]
					options:NSKeyValueObservingOptionNew
					context:NULL];
#else
	[[NSUserDefaults standardUserDefaults]
				addObserver:self
				 forKeyPath:PrefKeyFPS
					options:NSKeyValueObservingOptionNew
					context:NULL];
#endif
	
	// Set up the touch input device
#if defined(WINDOWS)
	_inputSource = [[TSNextwindowTouchInputSource alloc] init];
#endif

	_inputSource.delegate = self;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication*)sender
{	
	[_updateThread cancel];
	[_updateThread release];
	_updateThread = nil;

	[_inputSource invalidate];
	[_inputSource release];
	_inputSource = nil;

#if defined(WINDOWS)
	[TSNextwindowTouchInputSource cleanUp];
#endif
	
	return NSTerminateNow;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)sender
{
    return YES;
}

#pragma mark -
#pragma mark TSTouchInputSource delegate

- (void)touchInputSource:(TSTouchInputSource*)source senderInfoDidChange:(NSDictionary*)senderInfoDict
{
	[senderInfoDict retain];
	[_deviceInfoDict release];
	_deviceInfoDict = senderInfoDict;
	
	[_deviceInfoTableView performSelectorOnMainThread:@selector(reloadData)
										   withObject:nil
										waitUntilDone:NO];
}

#pragma mark -
#pragma mark NSTableDataSource informal protocol

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if (aTableView == _deviceInfoTableView)
		return 5;
	
	return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	id retval = nil;
	
	if (aTableView == _deviceInfoTableView)	{
		static NSArray* sortOrder = nil;
		
		if (nil == sortOrder)
			sortOrder = [[NSArray alloc] initWithObjects:
						 kTISSenderName,
						 kTISSenderSerialNumber,
						 kTISSenderFirmwareVersion,
						 kTISSenderModel,
						 kTISSenderProductID,
						 nil
			];
			
		id colID = [aTableColumn identifier];
		if (0 <= rowIndex && rowIndex < [sortOrder count]) {
			id key = [sortOrder objectAtIndex:rowIndex];
		
			if ([colID isEqual:DEVICE_TABLE_LABEL_COLUMN_ID])
				retval = TSLocalizedLabelForDeviceInfoKey(key);
			else if ([colID isEqual:DEVICE_TABLE_DATA_COLUMN_ID]) {
				retval = [_deviceInfoDict objectForKey:key];
			
				if (nil == retval) {
					if ([key isEqual:kTISSenderName])
						retval = NSLocalizedString(@"NoDevice", @"NoDevice");
					else
						retval = NSLocalizedString(@"N/A", @"N/A");
				}
			}
		}			
	}
	
	return retval;
}

#pragma mark -
#pragma mark NSTableView delegate

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
	return !(aTableView == _deviceInfoTableView);
}

#pragma mark -
#pragma mark Private Methods

- (void)_distributionThread
{
	NSAutoreleasePool* outerPool = [[NSAutoreleasePool alloc] init];
	
	while (![[NSThread currentThread] isCancelled]) {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
										
		NSTimeInterval before = [NSDate timeIntervalSinceReferenceDate];
				
		if ([_inputSource isReceivingTouchData]) {
			/* NSSize screenSize = [[TFScreenPreferencesController screen] frame].size;
			
			NSMutableArray* receivedTouches = [NSMutableArray arrayWithCapacity:10];
			
			TFBlob* blob = [TFBlob blob];
			blob.center.x = rand() % (long)screenSize.width;
			blob.center.y = rand() % (long)screenSize.height;
			blob.label = [TFBlobLabel labelWithInteger:rand()];
			[receivedTouches addObject:blob]; */
			
			NSArray* receivedTouches = [_inputSource currentLabelizedTouches];
			NSArray* matchedTouches, *unmatchedTouches;
						
			@synchronized (_labelizer) {
				matchedTouches = [_labelizer labelizeBlobs:receivedTouches
											unmatchedBlobs:&unmatchedTouches
											ignoringErrors:YES
													 error:NULL];
			}
			
			if ([matchedTouches count] > 0 || [unmatchedTouches count] > 0) {
				@synchronized (_distributionCenter) {
					[_distributionCenter distributeTrackingDataForActiveBlobs:matchedTouches
																inactiveBlobs:unmatchedTouches];
				}
			}
		}
				
		NSTimeInterval after = [NSDate timeIntervalSinceReferenceDate];
		NSTimeInterval t = _updateInterval - (after - before);
				
		if (t > 0.0)
			[NSThread sleepForTimeInterval:t];

		[pool release];
	}
	
	[outerPool release];
}

@end

NSString* TSLocalizedLabelForDeviceInfoKey(NSString* deviceInfoKey)
{
	NSString* rv = deviceInfoKey;
	
	if ([deviceInfoKey isEqualToString:kTISSenderName])
		rv = NSLocalizedString(@"SenderNameLabel", @"SenderNameLabel");
	else if ([deviceInfoKey isEqualToString:kTISSenderSerialNumber])
		rv = NSLocalizedString(@"SenderSerialNumberLabel", @"SenderSerialNumberLabel");
	else if ([deviceInfoKey isEqualToString:kTISSenderFirmwareVersion])
		rv = NSLocalizedString(@"SenderFirmwareVersionLabel", @"SenderFirmwareVersionLabel");
	else if ([deviceInfoKey isEqualToString:kTISSenderModel])
		rv = NSLocalizedString(@"SenderModel", @"SenderModel");
	else if ([deviceInfoKey isEqualToString:kTISSenderProductID])
		rv = NSLocalizedString(@"SenderProductID", @"SenderProductID");
	
	return rv;
}
