//
//  TFBlobSize.h
//  Touché
//
//  Created by Georg Kaindl on 18/12/07.
//  Copyright 2007 Georg Kaindl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TFBlobSize : NSObject <NSCopying, NSCoding> {
	float		width, height;
}

@property (assign) float width;
@property (assign) float height;

+ (id)sizeWithWidth:(float)wi height:(float)h;

- (id)initWithWidth:(float)w height:(float)h;

@end
