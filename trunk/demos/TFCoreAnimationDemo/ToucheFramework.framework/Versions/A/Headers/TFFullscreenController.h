//
//  TFFullscreenController.h
//  Touché
//
//  Created by Georg Kaindl on 28/3/08.
//  Copyright 2008 Georg Kaindl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TFFullscreenController : NSViewController {
	CGDirectDisplayID	_displayID;
	NSView*				_fullscreenView;
	BOOL				hidesMouseCursor;
	BOOL				isFullscreen;
	NSScreen*			screen;
	BOOL				_didHideMouseCursor;
}

@property (nonatomic, assign) BOOL hidesMouseCursor;
@property (readonly) BOOL isFullscreen;
@property (readonly) NSScreen* screen;

- (BOOL)goFullscreenWithView:(NSView*)view onScreen:(NSScreen*)screen;
- (BOOL)goFullscreenWithView:(NSView*)view onDisplayWithID:(CGDirectDisplayID)displayID;
- (BOOL)quitFullscreen;

@end

