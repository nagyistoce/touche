//
//  TFTUIOFlashXmlSettingsController.m
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

#import "TFTUIOFlashXmlSettingsController.h"

#import "TFError.h"
#import "TFLocalization.h"
#import "TFTUIOConstants.h"
#import "TFFlashXMLTUIOTrackingDataDistributor.h"


#define	FLASH_OPTIONS_URL	(@"http://www.macromedia.com/support/documentation/en/flashplayer/help/settings_manager04.html")

NSString* tFTUIOFlashXmlPixelsForMotionThresholdKey = @"tFTUIOFlashXmlPixelsForMotionThreshold";
NSString* tFTUIOFlashXmlDefaultTuioVersionKey = @"tFTUIOFlashXmlDefaultTuioVersion";
NSString* tFTUIOFlashXmlServerPortKey = @"tFTUIOFlashXmlServerPort";
NSString* tFTUIOFlashXmlServerLocalAddressTagKey = @"tFTUIOFlashXmlServerLocalAddressTag";

@interface TFTUIOFlashXmlSettingsController (PrivateMethods)
+ (NSString*)_localAddressForTag:(NSInteger)tag;
@end

@implementation TFTUIOFlashXmlSettingsController

@synthesize distributor;

+ (float)pixelsForBlobMotion
{
	return [[NSUserDefaults standardUserDefaults] floatForKey:tFTUIOFlashXmlPixelsForMotionThresholdKey];
}

+ (void)bindPixelsForBlobMotionToObject:(id)object keyPath:(NSString*)keyPath
{
	if (nil != object && nil != keyPath) {
		[object bind:keyPath
			toObject:[NSUserDefaultsController sharedUserDefaultsController]
		 withKeyPath:[NSString stringWithFormat:@"values.%@", tFTUIOFlashXmlPixelsForMotionThresholdKey]
			 options:nil];
	}
}

+ (void)bindDefaultTuioVersionToObject:(id)object keyPath:(NSString*)keyPath
{
	if (nil != object && nil != keyPath) {
		[object bind:keyPath
			toObject:[NSUserDefaultsController sharedUserDefaultsController]
		 withKeyPath:[NSString stringWithFormat:@"values.%@", tFTUIOFlashXmlDefaultTuioVersionKey]
			 options:nil];
	}
}

+ (UInt16)serverPort
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:tFTUIOFlashXmlServerPortKey];
}

+ (NSString*)serverAddress
{
	NSString* addr = [self _localAddressForTag:[[NSUserDefaults standardUserDefaults] integerForKey:tFTUIOFlashXmlServerLocalAddressTagKey]];
	
	return (nil != addr) ? addr : (NSString*)[NSNull null];
}

- (id)init
{
	if (nil != (self = [super initWithWindowNibName:@"TUIOFlashXMLSettings"])) {		
	}
	
	return self;
}

- (void)dealloc
{
	[distributor release];
	distributor = nil;
	
	[super dealloc];
}

- (void)setDistributor:(TFFlashXMLTUIOTrackingDataDistributor*)newDistributor
{
	if (distributor != newDistributor) {
		[distributor unbind:@"motionThreshold"];
		[distributor unbind:@"defaultTuioVersion"];
		
		[[self class] bindPixelsForBlobMotionToObject:newDistributor keyPath:@"motionThreshold"];
		[[self class] bindDefaultTuioVersionToObject:newDistributor keyPath:@"defaultTuioVersion"];
		
		[distributor release];
		distributor = [newDistributor retain];
	}
}

- (void)windowDidLoad
{
	[[self window] setShowsResizeIndicator:NO];
	
	[_defaultTuioVersionPopup setMenu:TFTUIOVersionSelectionMenu()];
	[_defaultTuioVersionPopup bind:@"selectedTag"
						  toObject:[NSUserDefaultsController sharedUserDefaultsController]
					   withKeyPath:[NSString stringWithFormat:@"values.%@", tFTUIOFlashXmlDefaultTuioVersionKey]
						   options:nil];
}

- (void)showWindow:(id)sender
{
	[super showWindow:sender];

	[_serverPortField setIntValue:
		[[NSUserDefaults standardUserDefaults] integerForKey:tFTUIOFlashXmlServerPortKey]];
}

- (IBAction)changeServerInterfaceSetting:(id)sender
{
	NSMatrix* matrix = (NSMatrix*)sender;
	NSInteger tag = [[matrix selectedCell] tag];
	
	NSString* addr = [[self class] _localAddressForTag:tag];
	
	UInt16 port = [[NSUserDefaults standardUserDefaults] integerForKey:tFTUIOFlashXmlServerPortKey];
	[distributor changeServerPortTo:port localAddress:addr error:NULL];
}

- (IBAction)changeServerPort:(id)sender
{
	NSUserDefaults* standardDefaults = [NSUserDefaults standardUserDefaults];
	UInt16 currentPort = [standardDefaults integerForKey:tFTUIOFlashXmlServerPortKey];
	UInt16 newPort = [_serverPortField intValue];
	
	if (currentPort != newPort) {
		NSError* error = nil;
		if (![distributor changeServerPortTo:newPort localAddress:nil error:&error]) {
			[NSApp presentError:error
				 modalForWindow:[self window]
					   delegate:nil
			 didPresentSelector:nil
					contextInfo:NULL];
			
			[_serverPortField setIntValue:currentPort];
		} else 
			[standardDefaults setInteger:newPort forKey:tFTUIOFlashXmlServerPortKey];
	}
}

- (IBAction)openFlashOptions:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:FLASH_OPTIONS_URL]];
}

+ (NSString*)_localAddressForTag:(NSInteger)tag
{
	NSString* addr = nil;
	
	switch (tag) {
		case 1:
			addr = @"127.0.0.1";
			break;
	}
	
	return addr;
}

#pragma mark -
#pragma mark NSWindow delegate

- (NSSize)windowWillResize:(NSWindow*)sender toSize:(NSSize)frameSize
{
	NSSize newSize = frameSize;
	
	if (sender == [self window])
		newSize = [sender frame].size;
	
	return newSize;
}

#pragma mark -
#pragma mark NSControl delegate

- (BOOL)control:(NSControl*)control didFailToFormatString:(NSString*)string errorDescription:(NSString*)error
{
	[control abortEditing];

	NSError* err = [NSError errorWithDomain:TFErrorDomain
									   code:TFErrorUnknown
								   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											 TFLocalizedString(@"TFTUIOXMLFlashPortFormatError",
															   @"TFTUIOXMLFlashPortFormatError"), NSLocalizedDescriptionKey,
											 nil]];
	
	[NSApp presentError:err
		 modalForWindow:[self window]
			   delegate:nil
	 didPresentSelector:nil
			contextInfo:NULL];
	
	return NO;
}

@end
