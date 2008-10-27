//
//  TFFullscreenController.m
//  Touché
//
//  Created by Georg Kaindl on 28/3/08.
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
//

#import "TFFullscreenController.h"

#import "TFIncludes.h"
#import "NSScreen+Extras.h"

@interface TFFullscreenController (NonPublicMethods)
- (void)_setup;
@end

@implementation TFFullscreenController

@synthesize hidesMouseCursor;
@synthesize isFullscreen;
@synthesize screen;

- (id)init
{
	if (!(self = [super init])) {
		[self release];
		
		return nil;
	}
	
	[self _setup];
	
	return self;
}

- (void)_setup
{
	isFullscreen = NO;
	screen = nil;
	hidesMouseCursor = NO;
	_didHideMouseCursor = NO;
}

- (void)dealloc
{
	[self quitFullscreen];
	[screen release];
	screen = nil;
	[_fullscreenView release];
	_fullscreenView = nil;
	
	[super dealloc];
}

- (BOOL)goFullscreenWithView:(NSView*)view onDisplayWithID:(CGDirectDisplayID)displayID
{
	return [self goFullscreenWithView:view onScreen:[NSScreen screenWithDisplayID:displayID]];
}

- (BOOL)goFullscreenWithView:(NSView*)view onScreen:(NSScreen*)scr
{
	int windowLevel;
	
	if (isFullscreen)
		return YES;
		
	if (nil == scr || nil == view)
		return NO;
	
	CGDirectDisplayID dID = [scr directDisplayID];
	
	windowLevel = CGShieldingWindowLevel();
	NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithInt:windowLevel+1], @"NSFullScreenModeWindowLevel",
							 [NSNumber numberWithBool:NO], @"NSFullScreenModeAllScreens", nil];
	
	isFullscreen = [view enterFullScreenMode:scr withOptions:options];
	
	if (hidesMouseCursor) {
		CGDisplayHideCursor([scr directDisplayID]);
		_didHideMouseCursor = YES;			
	}
	
	[screen release];
	screen = [scr retain];
	
	[_fullscreenView release];
	_fullscreenView = [view retain];
	
	_displayID = dID;
	
	return isFullscreen;
}

- (BOOL)quitFullscreen
{
	if (!isFullscreen)
		return YES;
	
	[_fullscreenView performSelectorOnMainThread:@selector(exitFullScreenModeWithOptions:)
									  withObject:nil
								   waitUntilDone:NO];
	
	if (_didHideMouseCursor) {
		CGDisplayShowCursor([screen directDisplayID]);
		_didHideMouseCursor = NO;
	}
	
	[screen release];
	screen = nil;
	
	[_fullscreenView release];
	_fullscreenView = nil;
	
	isFullscreen = NO;
	
	return YES;
}

@end
