//
//  AppController.h
//  TFCoreAnimationDemo
//
//  Created by Georg Kaindl on 21/5/08.
//  Copyright 2008 Georg Kaindl. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ToucheFramework/ToucheFramework.h>

@interface AppController : TFFullscreenController {
	TFTrackingClient*		_trackingClient;
	NSMutableDictionary*	_operations;
}

@end
