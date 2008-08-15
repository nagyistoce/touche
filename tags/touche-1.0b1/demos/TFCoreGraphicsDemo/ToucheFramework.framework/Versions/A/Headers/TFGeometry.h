//
//  TFGeometry.h
//  Touché
//
//  Created by Georg Kaindl on 22/5/08.
//  Copyright 2008 Georg Kaindl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
	TFWindingDirectionCW = 1,
	TFWindingDirectionCCW
} TFWindingDirection;

@interface TFGeometry : NSObject {
}

+ (CGFloat)distanceBetweenPoint:(CGPoint)p0 andPoint:(CGPoint)p1;
+ (CGFloat)dotProductBetweenVector:(CGPoint)p0 andVector:(CGPoint)p1;
+ (CGFloat)distanceBetweenPoint:(CGPoint)p andLineBetweenP0:(CGPoint)p0 andP1:(CGPoint)p1;
+ (CGFloat)minimumDistanceFromEdgesOfPoint:(CGPoint)p insideBox:(CGRect)rect;
+ (TFWindingDirection)windingDirectionOfVectorBetweenPoint:(CGPoint)p0 andPoint:(CGPoint)p1 relativeToBox:(CGRect)box;

@end
