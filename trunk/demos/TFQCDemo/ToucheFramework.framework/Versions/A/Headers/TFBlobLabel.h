//
//  TFBlobLabel.h
//  Touché
//
//  Created by Georg Kaindl on 20/12/07.
//  Copyright 2007 Georg Kaindl. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TFBlobLabel : NSObject <NSCopying, NSCoding> {
	NSInteger	intLabel;
	BOOL		isNew;
}

@property (assign) NSInteger intLabel;
@property (assign) BOOL isNew;

+ (id)labelWithInteger:(NSInteger)label;

- (id)initWithInteger:(NSInteger)label;

- (BOOL)isNilLabel;
- (BOOL)isEqualToLabel:(TFBlobLabel*)other;

@end
