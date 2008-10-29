//
//  AppController.m
//  TFCoreGraphicsDemo
//
//  Created by Georg Kaindl on 24/5/08.
//  Copyright 2008 Georg Kaindl. All rights reserved.
//

#import "AppController.h"
#import "TFFingerPaintView.h"

#define TRACKINGCLIENT_NAME			(@"TFCoreGraphicsDemo")
#define	BRUSH_SIZE_IN_CENTIMETERS	(1.0f)
#define	MIN_MOTION_FOR_UPDATE_IN_CM	(.5f)

@implementation AppController

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Creating the tracking client and setting ourselves as delegate
	_trackingClient = [[TFTrackingClient alloc] init];
	// Always set the delegate before trying to connect to the server, since connectWithName already
	// accesses delegate methods!
	_trackingClient.delegate = self;
	
	// Try to connect to the Touché tracker. Note that the given name must be unique: For each name,
	// only one client can be connected at a time. If you want multiple instances of your program
	// to be connected at once, you need to add some sort of UUID to the name that is unique for each
	// instance.
	NSError* error = nil;
	if (![_trackingClient connectWithName:TRACKINGCLIENT_NAME
									error:&error]) {
		[_trackingClient release];
		_trackingClient = nil;
		
		[[NSAlert alertWithError:error] runModal];
		[NSApp terminate:self];
	}
	
	// make sure the delegate methods are called on the main thread, since we are drawing.
	_trackingClient.deliveryThread = [NSThread mainThread];
	
	// Query the tracking client for the screen we should use for going fullscreen
	NSScreen* theScreen = [_trackingClient screen];
	
	// Now let's go fullscreen with our custom view
	self.hidesMouseCursor = ([[NSScreen screens] count] <= 1);;
	[self goFullscreenWithView:[self view] onScreen:theScreen];
	
	// Get the pixels per centimeter
	CGFloat ppcm = [_trackingClient screenPixelsPerCentimeter];
	
	// we don't need to re-paint any touch that moved for less than a threshold.
	_trackingClient.minimumMotionDistanceForUpdate = MIN_MOTION_FOR_UPDATE_IN_CM*ppcm;
	
	// Set up our painting view
	TFFingerPaintView* paintView = (TFFingerPaintView*)[self view];
	paintView.brushSize = BRUSH_SIZE_IN_CENTIMETERS*ppcm;
	[paintView setupContext];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication*)sender
{
	// Before we shut down, we disconnect from the server gracefully. This is the recommended
	// way of shutting down the connection to the server.
	[_trackingClient disconnect];
	
	return NSTerminateNow;
}

#pragma mark -
#pragma mark TFTrackingClient delegate methods

// Make sure that we send reasonable information about ourselves to the tracking server.
// For a list of all supported keys, see TFTrackingClient.h.
// Note that you do not need to create this method, as the framework supplies reasonable defaults otherwise.
- (NSDictionary*)infoDictionaryForClient:(TFTrackingClient*)client
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			@"Touché Core Graphics Demo", kToucheTrackingReceiverInfoHumanReadableName,
			nil];
}

// This is called when the server requests the client to quit. Usually, this means that the multitouch
// application itself should quit too, but this might not always be the case. In our demo app, we follow
// the server's request and quit by returning YES. If you want to handle the request differently, do
// whatever you want in the delegate method and then return NO. By the way, YES is the default, so if
// you want your app to quit on the request, you do not need to implement this method at all.
- (BOOL)clientShouldQuitByServerRequest:(TFTrackingClient*)client
{
	return YES;
}

// This is called if we get disconnected unexpectedly.
// Usually, it would make sense to try to reconnect here, but we simply display the error and quit in
// this demo app.
- (void)client:(TFTrackingClient*)client didGetDisconnectedWithError:(NSError*)error
{
	[self quitFullscreen];
	
	NSAlert* alert = [NSAlert alertWithError:error];
	[alert runModal];
	
	[NSApp terminate:self];
}

// This is called if the server connection suddenly dies (i.e. the server has crashed)
// Usually, it would make sense to try to reconnect here, but we simply display an error and quit in
// this demo app.
- (void)serverConnectionHasDiedForClient:(TFTrackingClient*)client
{
	[self quitFullscreen];
	
	NSAlert* alert = [NSAlert alertWithMessageText:@"Connection to the server died!"
									 defaultButton:@"Ok"
								   alternateButton:nil
									   otherButton:nil
						 informativeTextWithFormat:@"The server is no longer available!"];
	[alert runModal];
	
	[NSApp terminate:self];
}

// Called when new touches are discovered.
- (void)touchesDidBegin:(NSSet*)touches viaClient:(TFTrackingClient*)client
{
	[(TFFingerPaintView*)[self view] handleNewTouches:touches];
}

// Called when known touches are updated.
- (void)touchesDidUpdate:(NSSet*)touches viaClient:(TFTrackingClient*)client
{
	[(TFFingerPaintView*)[self view] handleUpdatedTouches:(NSSet*)touches];
}

// Called when known touches disappear.
- (void)touchesDidEnd:(NSSet*)touches viaClient:(TFTrackingClient*)client
{
	[(TFFingerPaintView*)[self view] handleEndedTouches:touches];
}

@end
