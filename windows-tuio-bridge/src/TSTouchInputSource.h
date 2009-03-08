//
//  TSTouchInputSource.h
//  TouchsmartTUIO
//
//  Created by Georg Kaindl on 27/2/09.
//  Copyright 2009 Georg Kaindl. All rights reserved.
//

#import <Cocoa/Cocoa.h>


extern NSString*	kTISSenderName;
extern NSString*	kTISSenderProductID;
extern NSString*	kTISSenderModel;
extern NSString*	kTISSenderSerialNumber;
extern NSString*	kTISSenderFirmwareVersion;

@interface TSTouchInputSource : NSObject {
	id					delegate;

	NSDictionary*		_senderInfoDict;
}

@property (assign) id delegate;

// this will be called before the program exits. The class should clean up any shared resources
// here, such as driver handles, etc.
+ (void)cleanUp;

- (id)init;
- (void)dealloc;

- (void)invalidate;
- (BOOL)isReceivingTouchData;

- (NSDictionary*)currentSenderInfo;

- (NSArray*)currentLabelizedTouches;

@end

@interface NSObject (TSTouchInputSourceDelegate)
- (void)touchInputSource:(TSTouchInputSource*)source senderInfoDidChange:(NSDictionary*)senderInfoDict;
@end
