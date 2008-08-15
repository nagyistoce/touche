//
//  TFCalibrationPoint.h
//  Touché
//
//  Created by Georg Kaindl on 30/12/07.
//
//  Copyright (C) 2007 Georg Kaindl
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

#import <Cocoa/Cocoa.h>


@interface TFCalibrationPoint : NSObject {
	float	screenX, screenY;
	float	cameraX, cameraY;
}

@property (assign) float screenX;
@property (assign) float screenY;
@property (assign) float cameraX;
@property (assign) float cameraY;

+ (id)pointWithScreenX:(float)sX screenY:(float)sY;
+ (id)pointWithScreenX:(float)sX screenY:(float)sY cameraX:(float)cX cameraY:(float)cY;

- (id)initWithScreenX:(float)sX screenY:(float)sY;
- (id)initWithScreenX:(float)sX screenY:(float)sY cameraX:(float)cX cameraY:(float)cY;

- (BOOL)isCalibrated;

@end
