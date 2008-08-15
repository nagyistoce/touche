//
//  TFGestureInfo
//  Touché
//
//  Created by Georg Kaindl on 22/5/08.
//  Copyright 2008 Georg Kaindl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TFGestureConstants.h"

@interface TFGestureInfo : NSObject {
	TFGestureType		type;
	TFGestureSubtype	subtype;
	NSDictionary*		parameters;
	NSTimeInterval		createdAt;
	id					userInfo;
}

@property (nonatomic, assign) TFGestureType type;
@property (nonatomic, assign) TFGestureSubtype subtype;
@property (nonatomic, retain) NSDictionary* parameters;
@property (readonly) NSTimeInterval createdAt;
@property (nonatomic, retain) id userInfo;

- (id)initWithType:(TFGestureType)t;
- (id)initWithType:(TFGestureType)t andSubtype:(TFGestureSubtype)st;
- (id)initWithType:(TFGestureType)t andSubtype:(TFGestureSubtype)st andParameters:(NSDictionary*)params;

+ (id)info;
+ (id)infoWithType:(TFGestureType)t;
+ (id)infoWithType:(TFGestureType)t andSubtype:(TFGestureSubtype)st;
+ (id)infoWithType:(TFGestureType)t andSubtype:(TFGestureSubtype)st andParameters:(NSDictionary*)params;

@end
