//
//  TSTouchInputSource.m
//  TouchsmartTUIO
//
//  Created by Georg Kaindl on 27/2/09.
//  Copyright 2009 Georg Kaindl. All rights reserved.
//

#import "TSTouchInputSource.h"


NSString*	kTISSenderName					= @"SenderName";
NSString*	kTISSenderProductID				= @"SenderProductID";
NSString*	kTISSenderModel					= @"SenderModel";
NSString*	kTISSenderSerialNumber			= @"SenderSerialNumber";
NSString*	kTISSenderVersion				= @"SenderVersion";
NSString*	kTISSenderFirmwareVersion		= @"SenderFirmwareVersion";

@implementation TSTouchInputSource

@synthesize delegate;

+ (void)cleanUp
{
}

- (id)init
{
	if (nil != (self = [super init])) {
	}
	
	return self;
}

- (void)dealloc
{
	delegate = nil;
	
	[_senderInfoDict release];
	_senderInfoDict = nil;
	
	[super dealloc];
}

- (BOOL)isReceivingTouchData
{
	return NO;
}

- (void)invalidate
{
}

- (NSDictionary*)currentSenderInfo
{
	return nil;
}

- (NSArray*)currentLabelizedTouches
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

@end
