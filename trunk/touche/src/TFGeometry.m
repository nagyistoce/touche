//
//  TFGeometry.m
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

#import "TFGeometry.h"

#import "TFIncludes.h"

@implementation TFGeometry

+ (CGFloat)distanceBetweenPoint:(CGPoint)p0 andPoint:(CGPoint)p1
{
	return sqrt((p0.x - p1.x) * (p0.x - p1.x) + (p0.y - p1.y) * (p0.y - p1.y));
}

+ (CGFloat)dotProductBetweenVector:(CGPoint)p0 andVector:(CGPoint)p1
{
	return p0.x*p1.x + p0.y*p1.y;
}

+ (CGFloat)distanceBetweenPoint:(CGPoint)p andLineBetweenP0:(CGPoint)p0 andP1:(CGPoint)p1
{	
	CGFloat a = ABS((p1.x-p0.x)*(p0.y-p.y) - (p0.x-p.x)*(p1.y-p0.y));
	return a / [[self class] distanceBetweenPoint:p0 andPoint:p1];
}

+ (CGFloat)minimumDistanceFromEdgesOfPoint:(CGPoint)p insideBox:(CGRect)rect
{
	CGPoint p1, p2, p3;
	BOOL isLeft = NO;
	if (p.x > rect.origin.x + rect.size.width/2.0f) {
		p1 = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
		p2 = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y);
		isLeft = NO;
	} else {
		p1 = CGPointMake(rect.origin.x, rect.origin.y + rect.size.height);
		p2 = rect.origin;
		isLeft = YES;
	}
	
	BOOL isTop = NO;
	if (p.y > rect.origin.y + rect.size.height/2.0f) {
		p3 = CGPointMake(rect.origin.x + (isLeft ? rect.size.width : 0), rect.origin.y + rect.size.height);
		isTop = YES;
	} else {
		p3 = CGPointMake(rect.origin.x + (isLeft ? rect.size.width : 0), rect.origin.y);
		isTop = NO;
	}
	
	CGFloat d1, d2;
	d1 = [[self class] distanceBetweenPoint:p andLineBetweenP0:p1 andP1:p2];
	d2 = [[self class] distanceBetweenPoint:p andLineBetweenP0:(isTop ? p1 : p2) andP1:p3];
	
	return MIN(d1, d2);
}

+ (TFWindingDirection)windingDirectionOfVectorBetweenPoint:(CGPoint)p0 andPoint:(CGPoint)p1 relativeToBox:(CGRect)box
{
	CGPoint disp = CGPointMake(p1.x - p0.x, p1.y - p0.y);
	
	TFWindingDirection retval;
	if (p1.x <= box.origin.x + box.size.width/2.0f) {
		if (disp.y < 0)
			retval = TFWindingDirectionCCW;
		else if (disp.y > 0)
			retval = TFWindingDirectionCW;
		else if (p1.y <= box.origin.y + box.size.height/2.0f)
			retval = (disp.x > 0) ? TFWindingDirectionCCW : TFWindingDirectionCW;
		else
			retval = (disp.x < 0) ? TFWindingDirectionCCW : TFWindingDirectionCW;
	} else {
		if (disp.y > 0)
			retval = TFWindingDirectionCCW;
		else if (disp.y < 0)
			retval = TFWindingDirectionCW;
		else if (p1.y <= box.origin.y + box.size.height/2.0f)
			retval = (disp.x > 0) ? TFWindingDirectionCCW : TFWindingDirectionCW;
		else
			retval = (disp.x < 0) ? TFWindingDirectionCCW : TFWindingDirectionCW;
	}
	
	return retval;
}

@end
