//
//  AppController.m
//  TFQCDemo
//
//  Created by Georg Kaindl on 19/5/08.
//  Copyright Georg Kaindl 2008 . All rights reserved.
//

#import "AppController.h"

#define TRACKINGCLIENT_NAME	(@"TFQCDemo")
#define X_POS_KEY			(@"xPos%d")
#define Y_POS_KEY			(@"yPos%d")

static const NSUInteger numFlares = 10;

@interface AppController (PrivateMethods)
- (void)_hideFlare:(NSInteger)flare;
- (void)_positionFlare:(NSInteger)flare atPoint:(NSPoint)p;
- (void)_positionFlare:(NSInteger)flare forTouch:(TFTouch*)touch;
@end

@implementation AppController
 
- (void)awakeFromNib
{
	if(![qcView loadCompositionFromFile:[[NSBundle mainBundle] pathForResource:@"flares" ofType:@"qtz"]]) {
		NSLog(@"Could not load composition");
	}
		
	_freeFlares = [[NSMutableArray alloc] init];
	_assignedFlares = [[NSMutableDictionary alloc] init];
	
	int i;
	for (i=0; i<numFlares; i++)
		[_freeFlares addObject:[NSNumber numberWithInt:i]];

	// initialize the random number generator
	srandomdev();
}

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
	
	// Query the tracking client for the screen we should use for going fullscreen
	NSScreen* theScreen = [_trackingClient screen];
		
	// Store the screen size, since we will need it later
	_screenSize = [theScreen frame].size;
	CGFloat ppcm = [_trackingClient screenPixelsPerCentimeter];
	
	// Now let's go fullscreen with our QCView
	self.hidesMouseCursor = ([[NSScreen screens] count] <= 1);
	[self goFullscreenWithView:qcView onScreen:theScreen];
	
	// Start the Quartz Composition renderer
	[qcView startRendering];
	
	// Now we'll set some size values based on the screen size and screen resolution we got from the server.
	[qcView setValue:[NSNumber numberWithFloat:(ppcm/1500.0f)] forInputKey:@"maxParticleSize"];
	[qcView setValue:[NSNumber numberWithFloat:(ppcm/2800.0f)] forInputKey:@"minParticleSize"];
	[qcView setValue:[NSNumber numberWithFloat:(ppcm/70.0f)] forInputKey:@"maxParticleVelocity"];
	[qcView setValue:[NSNumber numberWithFloat:-(ppcm/70.0f)] forInputKey:@"minParticleVelocity"];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication*)sender
{
	// Before we shut down, we disconnect from the server gracefully. This is the recommended
	// way of shutting down the connection to the server.
	[_trackingClient disconnect];
	
	return NSTerminateNow;
}

- (void)_hideFlare:(NSInteger)flare
{
	[self _positionFlare:flare atPoint:NSMakePoint(100000.f, 100000.f)];
}

- (void)_positionFlare:(NSInteger)flare atPoint:(NSPoint)p
{
	NSString* xKey = [NSString stringWithFormat:X_POS_KEY, flare];
	NSString* yKey = [NSString stringWithFormat:Y_POS_KEY, flare];
	
	[qcView setValue:[NSNumber numberWithFloat:p.x] forInputKey:xKey];
	[qcView setValue:[NSNumber numberWithFloat:p.y] forInputKey:yKey];
}

- (void)_positionFlare:(NSInteger)flare forTouch:(TFTouch*)touch
{	
	// convert from screen coordinates to QC coordinates for the given screen size
	NSPoint p = [touch centerQCCoordinatesForViewSize:_screenSize];
		
	[self _positionFlare:flare atPoint:p];
}

#pragma mark -
#pragma mark TFTrackingClient delegate methods

// Make sure that we send reasonable information about ourselves to the tracking server.
// For a list of all supported keys, see TFTrackingClient.h.
// Note that you do not need to create this method, as the framework supplies reasonable defaults otherwise.
- (NSDictionary*)infoDictionaryForClient:(TFTrackingClient*)client
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			@"Touché Quartz Composition Demo", kToucheTrackingReceiverInfoHumanReadableName,
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

// NOTE: We use a lock in the following 3 delegate methods since they might be called concurrently
// by the tracker. Thusly, we need to use proper locking to shield our globals against concurrent
// access and race conditions...

// Called when new touches are discovered.
// We use this delegate method to assign a random free flare to the new touch label
// and move it to the position of the touch
- (void)touchesDidBegin:(NSSet*)touches viaClient:(TFTrackingClient*)client
{
	for (TFTouch* touch in touches) {
		@synchronized(self) {
			int numFreeFlares = [_freeFlares count];
			if (0 == numFreeFlares)
				return;
											
			NSInteger p = random()%numFreeFlares;
			NSNumber* flare = (NSNumber*)[_freeFlares objectAtIndex:p];
			[_assignedFlares setObject:flare forKey:touch.label];
			[_freeFlares removeObjectAtIndex:p];
			
			[self _positionFlare:[flare intValue] forTouch:touch];
		}
	}
}

// Called when known touches are updated.
// We simply move the touches to the new position here
- (void)touchesDidUpdate:(NSSet*)touches viaClient:(TFTrackingClient*)client
{
	for (TFTouch* touch in touches) {
		@synchronized(self) {
			NSNumber* flare = [_assignedFlares objectForKey:touch.label];
			
			[self _positionFlare:[flare intValue] forTouch:touch];
		}
	}
}

// Called when known touches disappear.
// We remove a known touch here by positioning it outside the the visible area of the QCView
// and free its assigned flare, so that it can be reused by other touches.
- (void)touchesDidEnd:(NSSet*)touches viaClient:(TFTrackingClient*)client
{
	for (TFTouch* touch in touches) {
		@synchronized(self) {
			NSNumber* flare = [_assignedFlares objectForKey:touch.label];
			[_freeFlares addObject:flare];
			[_assignedFlares removeObjectForKey:touch.label];

			[self _hideFlare:[flare intValue]];
		}
	}
}

@end
