//
//  TFBlobBox.h
//  Touché
//
//  Created by Georg Kaindl on 18/12/07.
//  Copyright 2007 Georg Kaindl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TFBlobPoint;
@class TFBlobSize;

@interface TFBlobBox : NSObject <NSCopying, NSCoding> {
	TFBlobPoint*		origin;
	TFBlobSize*			size;
}

@property (retain) TFBlobPoint* origin;
@property (retain) TFBlobSize* size;

- (id)initWithOrigin:(TFBlobPoint*)o size:(TFBlobSize*)s;

@end
