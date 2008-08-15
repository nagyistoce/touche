//
//  TFBlobPoint.h
//  Touché
//
//  Created by Georg Kaindl on 18/12/07.
//  Copyright 2007 Georg Kaindl. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TFBlobPoint : NSObject <NSCopying, NSCoding> {
	float		x, y;
}

@property (assign) float x;
@property (assign) float y;

+ (id)point;
+ (id)pointWithX:(float)xPos Y:(float)yPos;

- (id)initWithX:(float)xPos Y:(float)yPos;

@end
