//
//  TFTUIOOSCSettingsController.m
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

#import "TFTUIOOSCSettingsController.h"

#import "TFLocalization.h"
#import "TFIPSocket.h"
#import "TFTUIOOSCTrackingDataDistributor.h"


#define	DEFAULT_HOST	(@"127.0.0.1")
#define DEFAULT_PORT	(@"3333")

NSString* tFTUIOPixelsForMotionPreferenceKey = @"tFTUIOPixelsForMotion";

@interface TFTUIOOSCSettingsController (PrivateMethods)
- (void)_addClientFromPanelThread;
@end

@implementation TFTUIOOSCSettingsController

@synthesize distributor;

+ (float)pixelsForBlobMotion
{
	return [[NSUserDefaults standardUserDefaults] floatForKey:tFTUIOPixelsForMotionPreferenceKey];
}

+ (void)bindPixelsForBlobMotionToObject:(id)object keyPath:(NSString*)keyPath
{
	if (nil != object && nil != keyPath) {
		[object bind:keyPath
			toObject:[NSUserDefaultsController sharedUserDefaultsController]
		 withKeyPath:[NSString stringWithFormat:@"values.%@", tFTUIOPixelsForMotionPreferenceKey]
			 options:nil];
	}
}

- (id)init
{
	if (nil != (self = [super initWithWindowNibName:@"TUIOOSCSettings"])) {
	}
	
	return self;
}

- (void)dealloc
{
	[distributor release];
	distributor = nil;
	
	[_addClientThread release];
	_addClientThread = nil;

	[super dealloc];
}

- (void)setDistributor:(TFTUIOOSCTrackingDataDistributor*)newDistributor
{
	if (distributor != newDistributor) {
		[distributor unbind:@"motionThreshold"];
		
		[[self class] bindPixelsForBlobMotionToObject:newDistributor keyPath:@"motionThreshold"];
		
		[distributor release];
		distributor = [newDistributor retain];
	}
}

- (IBAction)showAddClientPanel:(id)sender
{
	[_addClientPanel setShowsResizeIndicator:NO];
	
	if (!_addClientPanelShown) {
		[_addClientErrorLabel setHidden:YES];
	
		[_addClientHostField setStringValue:DEFAULT_HOST];
		[_addClientPortField setStringValue:DEFAULT_PORT];
		
		[_addClientHostField selectText:sender];
	}
	
	[_addClientPanel makeKeyAndOrderFront:sender];
}

- (IBAction)addClientFromPanel:(id)sender
{
	if (nil == _addClientThread) {
		_addClientThread = [[NSThread alloc] initWithTarget:self
												   selector:@selector(_addClientFromPanelThread)
													 object:nil];
		
		[_addClientThread start];
		[_addClientErrorLabel setHidden:YES];
		//[_addClientProgressIndicator startAnimation:sender];
	}
}

- (void)windowDidLoad
{
	[[self window] setShowsResizeIndicator:NO];
}

- (void)_addClientFromPanelThread
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	NSInteger port = [_addClientPortField intValue];
	NSString* host = [_addClientHostField stringValue];
	if(![TFIPSocket resolveName:host intoAddress:NULL]) {
		[_addClientErrorLabel setStringValue:TFLocalizedString(@"TFTUIOAddClientInvalidHost", @"TFTUIOAddClientInvalidHost")];
		[_addClientErrorLabel setHidden:NO];
	} else if (port <= 0 || port > 65535) {
		[_addClientErrorLabel setStringValue:TFLocalizedString(@"TFTUIOAddClientInvalidPort", @"TFTUIOAddClientInvalidPort")];
		[_addClientErrorLabel setHidden:NO];
	} else if (![distributor addTUIOClientAtHost:host port:port error:NULL]) {
		[_addClientErrorLabel setStringValue:TFLocalizedString(@"TFTUIOAddClientAlreadyExists", @"TFTUIOAddClientAlreadyExists")];
		[_addClientErrorLabel setHidden:NO];
	} else {
		[_addClientPanel performSelectorOnMainThread:@selector(orderOut:)
										  withObject:nil
									   waitUntilDone:NO];
	}
	
	/* [_addClientProgressIndicator performSelectorOnMainThread:@selector(stopAnimation:)
												  withObject:nil
											   waitUntilDone:NO]; */
	
	[_addClientThread release];
	_addClientThread = nil;
	[pool release];
}

#pragma mark -
#pragma mark NSWindow delegate

- (NSSize)windowWillResize:(NSWindow*)sender toSize:(NSSize)frameSize
{
	NSSize newSize = frameSize;

	if (sender == [self window] || sender == _addClientPanel)
		newSize = [sender frame].size;
	
	return newSize;
}

- (void)windowDidBecomeKey:(NSNotification*)notification
{
	NSWindow* window = [notification object];
	
	if (window == _addClientPanel) {
		_addClientPanelShown = YES;
	}
}

- (void)windowWillClose:(NSNotification*)notification
{
	NSWindow* window = [notification object];
	
	if (window == _addClientPanel) {
		_addClientPanelShown = NO;
	}
}

@end
