//
//  AppController.h
//  TFQCDemo
//
//  Created by Georg Kaindl on 19/5/08.
//  Copyright Georg Kaindl 2008 . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import <ToucheFramework/ToucheFramework.h>

@interface AppController : TFFullscreenController 
{
    IBOutlet QCView*		qcView;
	
	TFTrackingClient*		_trackingClient;
	
	NSSize					_screenSize;
	NSMutableArray*			_freeFlares;
	NSMutableDictionary*	_assignedFlares;
}

@end
