//
//  TFBlob+TUIOMethods.h
//  Touché
//
//  Created by Georg Kaindl on 7/9/08.
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

#import <Foundation/Foundation.h>

#import "TFBlob.h"


@interface TFBlob (TUIOMethods)

- (void)getTuio10CursorSetMessageForCurrentStateWithSessionID:(NSInteger*)sessionID
													positionX:(float*)xPos
													positionY:(float*)yPos
													  motionX:(float*)xDelta
													  motionY:(float*)yDelta
												 acceleration:(float*)accel;

- (void)getTuio11BlobSetMessageForCurrentStateWithSessionID:(NSInteger*)sessionID
												  positionX:(float*)xPos
												  positionY:(float*)yPos
													  angle:(float*)angle
													  width:(float*)width
													 height:(float*)height
													   area:(float*)area
													motionX:(float*)xDelta
													motionY:(float*)yDelta
											  motionAngular:(float*)aDelta
											   acceleration:(float*)accel
										 motionAcceleration:(float*)aAccel;

@end
