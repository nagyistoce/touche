//
//  TFBlob+TUIOMethods.m
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

#import "TFBlob+TUIOMethods.h"

#import "TFScreenPreferencesController.h"
#import "TFBlobPoint.h"
#import "TFBlobLabel.h"


@implementation TFBlob (TUIOMethods)

- (void)getTuioDataForCurrentStateWithSessionID:(NSInteger*)sessionID
									  positionX:(float*)xPos
									  positionY:(float*)yPos
										motionX:(float*)xDelta
										motionY:(float*)yDelta
								   acceleration:(float*)accel
{	
	NSSize screenSize = [[TFScreenPreferencesController screen] frame].size;

	if (NULL != sessionID)
		*sessionID = self.label.intLabel;
		
	if (NULL != xPos)
		*xPos = self.center.x/screenSize.width;
	// Touché uses Quartz-style coordinates with the origin at the bottom left,
	// but TUIO has the origin in the upper left, meaning that we need to invert
	// the y coordinate here.
	if (NULL != yPos)
		*yPos = (1.0f - self.center.y/screenSize.height);
	
	float xD, yD, a;
	if (self.isUpdate) {
		NSTimeInterval secsSinceLast = self.createdAt - self.previousCreatedAt;
		
		xD = ((self.center.x - self.previousCenter.x)/screenSize.width) / secsSinceLast;
		// like the position, we need to invert the yDelta
		yD = -((self.center.y - self.previousCenter.y)/screenSize.height) / secsSinceLast;
		
		float xAccel = (self.acceleration.x/screenSize.width) / secsSinceLast;
		// we don't need to invert y accel here, since we're just interested into the vec length anyway
		float yAccel = (self.acceleration.y/screenSize.height) / secsSinceLast;
		a = hypot(xAccel, yAccel);
	} else {
		// if this blob is new (i.e. not an update), we set the motion vector and acceleration to 0.0.
		xD = yD = a = 0.0f;
	}

	if (NULL != xDelta)
		*xDelta = xD;
	
	if (NULL != yDelta)
		*yDelta = yD;
	
	if (NULL != accel)
		*accel = a;
}

@end
