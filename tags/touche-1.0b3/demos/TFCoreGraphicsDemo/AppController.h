//
//  AppController.h
//  TFCoreGraphicsDemo
//
//  Created by Georg Kaindl on 24/5/08.
//  Copyright 2008 Georg Kaindl. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ToucheFramework/ToucheFramework.h>

@interface AppController : TFFullscreenController {
	TFTrackingClient*		_trackingClient;
}

@end
