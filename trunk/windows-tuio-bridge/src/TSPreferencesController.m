//
//  TSPreferencesController.m
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

#import "TSPreferencesController.h"

#import "TFFlashXMLTUIOTrackingDataDistributor.h"
#import "TFTUIOOSCTrackingDataDistributor.h"
#import "TFIPSocket.h"


#define CHANGE_OK_LABEL_SHOWN_TIME		((NSTimeInterval)1.0)

NSString* PrefKeyPixelsForMotion		= @"PixelsForMotion";
NSString* PrefKeyFPS					= @"FramesPerSecond";
NSString* PrefKeyFlashXMLServerPort		= @"FlashXMLServerPort";
NSString* PrefKeyOSCTargetHost			= @"OSCTargetHost";
NSString* PrefKeyOSCTargetPort			= @"OSCTargetPort";

@interface TSPreferencesController (PrivateMethods)
- (void)_changeClientFromPanelThread;
- (void)_changeClientComplete:(NSError*)error;
- (void)_changeClientCompleteHideLabelTimerFired:(NSTimer*)timer;
@end

@implementation TSPreferencesController

@synthesize flashXMLDistributor, oscDistributor;

+ (void)registerDefaults
{
	NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
	NSString* path = [[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"];
	NSDictionary* defaultsDict = [NSDictionary dictionaryWithContentsOfFile:path];
	
	[userDefaults registerDefaults:defaultsDict];
}

- (id)init
{
	if (nil != (self = [super initWithWindowNibName:@"Preferences"])) {
	}
	
	return self;
}

- (void)dealloc
{
	[flashXMLDistributor release];
	flashXMLDistributor = nil;
	
	[oscDistributor release];
	oscDistributor = nil;
	
	@synchronized (_changeOSCClientThread) {
		[_changeOSCClientThread autorelease];
		_changeOSCClientThread = nil;
	}
	
	[_changeOSCCompleteLabelHideTimer invalidate];
	[_changeOSCCompleteLabelHideTimer release];
	_changeOSCCompleteLabelHideTimer = nil;
	
	[_changeXMLCompleteLabelHideTimer invalidate];
	[_changeXMLCompleteLabelHideTimer release];
	_changeXMLCompleteLabelHideTimer = nil;
	
	[super dealloc];
}

- (IBAction)showWindow:(id)sender
{
	NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
	
	[super showWindow:sender];
	
	[flashXMLServerPortField setIntValue:IntegerPrefKey(userDefaults, PrefKeyFlashXMLServerPort)];
	[oscHostField setStringValue:[userDefaults objectForKey:PrefKeyOSCTargetHost]];
	[oscPortField setIntValue:IntegerPrefKey(userDefaults, PrefKeyOSCTargetPort)];
	
	[oscChangeCompleteLabel setStringValue:@""];
	[flashXMLChangeCompleteLabel setStringValue:@""];
}

- (IBAction)changeFlashXMLServerPort:(id)sender
{
	NSUserDefaults* standardDefaults = [NSUserDefaults standardUserDefaults];
	UInt16 currentPort = IntegerPrefKey(standardDefaults, PrefKeyFlashXMLServerPort);
	UInt16 newPort = [flashXMLServerPortField intValue];
	
	if (currentPort != newPort) {
		NSError* error = nil;
		if (![flashXMLDistributor changeServerPortTo:newPort localAddress:nil error:&error]) {
			[NSApp presentError:error
				 modalForWindow:[self window]
					   delegate:nil
			 didPresentSelector:nil
					contextInfo:NULL];
			
			[flashXMLServerPortField setIntValue:currentPort];
		} else {
			[standardDefaults setInteger:newPort forKey:PrefKeyFlashXMLServerPort];
			
			[_changeXMLCompleteLabelHideTimer invalidate];
			[_changeXMLCompleteLabelHideTimer release];

			[flashXMLChangeCompleteLabel setStringValue:NSLocalizedString(@"OK", @"OK")];
			
			_changeXMLCompleteLabelHideTimer =
			[[NSTimer scheduledTimerWithTimeInterval:CHANGE_OK_LABEL_SHOWN_TIME
											  target:self
											selector:@selector(_changeFlashXMLCompleteHideLabelTimerFired:)
											userInfo:nil
											 repeats:NO] retain];
		}
	}
}

- (IBAction)commitOSCTargetChange:(id)sender
{
	NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
	
	BOOL doIt = NO;
	@synchronized (_changeOSCClientThread) {
		doIt =	(nil == _changeOSCClientThread) &&
				([oscPortField intValue] != IntegerPrefKey(userDefaults, PrefKeyOSCTargetPort) ||
				 ![[oscHostField stringValue] isEqualToString:[userDefaults objectForKey:PrefKeyOSCTargetHost]]);
	}
	
	if (doIt) {
		[_changeOSCCompleteLabelHideTimer invalidate];
		[_changeOSCCompleteLabelHideTimer release];
		_changeOSCCompleteLabelHideTimer = nil;
	
		[oscCommitButton setEnabled:NO];
	
		_changeOSCClientThread = [[NSThread alloc] initWithTarget:self
														 selector:@selector(_changeClientFromPanelThread)
														   object:nil];
		[_changeOSCClientThread start];
	}
}

#pragma mark -
#pragma mark Private Methods

- (void)_changeClientFromPanelThread
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
	NSString* errorString = nil;
	
	NSInteger port = [oscPortField intValue];
	NSString* host = [oscHostField stringValue];
	
	// remove previous client this way...
	[oscDistributor stopDistributor];
	[oscDistributor startDistributorWithObject:nil error:NULL];
	
	if(![TFIPSocket resolveName:host intoAddress:NULL]) {
		errorString = NSLocalizedString(@"TFTUIOAddClientInvalidHost", @"TFTUIOAddClientInvalidHost");
	} else if (port <= 0 || port > 65535) {
		errorString = NSLocalizedString(@"TFTUIOAddClientInvalidPort", @"TFTUIOAddClientInvalidPort");
	} else if (![oscDistributor addTUIOClientAtHost:host port:port error:NULL]) {
		errorString = NSLocalizedString(@"TFTUIOAddClientAlreadyExists", @"TFTUIOAddClientAlreadyExists");
	} else {
		// success! update the preferences!		
		[userDefaults setObject:host forKey:PrefKeyOSCTargetHost];
		[userDefaults setInteger:port forKey:PrefKeyOSCTargetPort];
	}
	
	NSError* error = nil;
	if (nil != errorString) {
		// try adding the previous host again...
		[oscDistributor addTUIOClientAtHost:[userDefaults objectForKey:PrefKeyOSCTargetHost]
									   port:IntegerPrefKey(userDefaults, PrefKeyOSCTargetPort)
									  error:NULL];
		
		[oscHostField setStringValue:[userDefaults objectForKey:PrefKeyOSCTargetHost]];
		[oscPortField setIntValue:IntegerPrefKey(userDefaults, PrefKeyOSCTargetPort)];
		
		// report the error
		error = [NSError errorWithDomain:APP_ERROR_DOMAIN
									code:-1
								userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
														errorString, NSLocalizedDescriptionKey,
														nil]];
	}
	
	@synchronized (_changeOSCClientThread) {
		[_changeOSCClientThread autorelease];
		_changeOSCClientThread = nil;
	}
	
	[self performSelectorOnMainThread:@selector(_changeClientComplete:)
						   withObject:error
						waitUntilDone:NO];
	
	[pool release];
}

- (void)_changeClientComplete:(NSError*)error
{
	if (nil != error) {
		[NSApp presentError:error
			 modalForWindow:[self window]
				   delegate:nil
		 didPresentSelector:nil
				contextInfo:NULL];
	} else {
		[oscChangeCompleteLabel setStringValue:NSLocalizedString(@"OK", @"OK")];
		
		[_changeOSCCompleteLabelHideTimer invalidate];
		_changeOSCCompleteLabelHideTimer =
			[[NSTimer scheduledTimerWithTimeInterval:CHANGE_OK_LABEL_SHOWN_TIME
											  target:self
											selector:@selector(_changeClientCompleteHideLabelTimerFired:)
											userInfo:nil
											 repeats:NO] retain];
	}

	[oscCommitButton setEnabled:YES];
}

- (void)_changeClientCompleteHideLabelTimerFired:(NSTimer*)timer
{
	[_changeOSCCompleteLabelHideTimer invalidate];
	[_changeOSCCompleteLabelHideTimer release];
	_changeOSCCompleteLabelHideTimer = nil;
	
	[oscChangeCompleteLabel setStringValue:@""];
}

- (void)_changeFlashXMLCompleteHideLabelTimerFired:(NSTimer*)timer
{
	[_changeXMLCompleteLabelHideTimer invalidate];
	[_changeXMLCompleteLabelHideTimer release];
	_changeXMLCompleteLabelHideTimer = nil;
	
	[flashXMLChangeCompleteLabel setStringValue:@""];
}

@end
