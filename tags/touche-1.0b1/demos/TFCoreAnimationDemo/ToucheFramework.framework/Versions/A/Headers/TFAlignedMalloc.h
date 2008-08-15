//
//  TFAlignedMalloc.h
//  Touché
//
//  Created by Georg Kaindl on 24/5/08.
//  Copyright 2008 Georg Kaindl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TFAlignedMalloc : NSObject {
}

+ (void*)closestLowerAddressRelativeTo:(void*)ptr beingAlignedAtMultipleOf:(NSUInteger)alignment;
+ (void*)closestHigherAddressRelativeTo:(void*)ptr beingAlignedAtMultipleOf:(NSUInteger)alignment;
+ (void*)malloc:(size_t)size alignedAtMultipleOf:(NSUInteger)alignment;
+ (void)free:(void*)p;

@end
