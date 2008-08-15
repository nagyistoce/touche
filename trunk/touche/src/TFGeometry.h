//
//  TFGeometry.h
//  Touché
//
//  Created by Georg Kaindl on 22/5/08.
//
//  Copyright (C) 2008 Georg Kaindl
//
//  This file is part of Touché.
//
//  Touché is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as
//  published by the Free Software Foundation, either version 3 of
//  the License, or (at your option) any later version.
//
//  Touché is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public
//  License along with Touché. If not, see <http://www.gnu.org/licenses/>.
//
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
