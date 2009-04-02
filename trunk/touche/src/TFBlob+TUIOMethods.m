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
#import "TFBlobLabel.h"
#import "TFBlobPoint.h"
#import "TFBlobBox.h"
#import "TFBlobSize.h"


@implementation TFBlob (TUIOMethods)

- (void)getTuio10CursorSetMessageForCurrentStateWithSessionID:(NSInteger*)sessionID
													positionX:(float*)xPos
													positionY:(float*)yPos
													  motionX:(float*)xDelta
													  motionY:(float*)yDelta
												 acceleration:(float*)accel
{	
	NSSize screenSize = [[TFScreenPreferencesController screen] frame].size;

	if (NULL != sessionID)
		*sessionID = self->label.intLabel;
		
	if (NULL != xPos)
		*xPos = self->center.x/screenSize.width;
	// Touché uses Quartz-style coordinates with the origin at the bottom left,
	// but TUIO has the origin in the upper left, meaning that we need to invert
	// the y coordinate here.
	if (NULL != yPos)
		*yPos = (1.0f - self->center.y/screenSize.height);
	
	float xD, yD, a;
	if (self.isUpdate) {
		NSTimeInterval secsSinceLast = self->createdAt - self->previousCreatedAt;
		
		xD = ((self->center.x - self->previousCenter.x)/screenSize.width) / secsSinceLast;
		// like the position, we need to invert the yDelta
		yD = -((self->center.y - self->previousCenter.y)/screenSize.height) / secsSinceLast;
		
		float xAccel = (self->acceleration.x/screenSize.width) / secsSinceLast;
		// we don't need to invert y accel here, since we're just interested into the vec length anyway
		float yAccel = (self->acceleration.y/screenSize.height) / secsSinceLast;
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

- (void)getTuio11BlobSetMessageForCurrentStateWithSessionID:(NSInteger*)sessionID
												  positionX:(float*)xPos
												  positionY:(float*)yPos
													  angle:(float*)angle
													  width:(float*)width
													 height:(float*)height
													   area:(float*)pArea
													motionX:(float*)xDelta
													motionY:(float*)yDelta
											  motionAngular:(float*)aDelta
											   acceleration:(float*)accel
										 motionAcceleration:(float*)aAccel
{
	[self getTuio10CursorSetMessageForCurrentStateWithSessionID:sessionID
													  positionX:xPos
													  positionY:yPos
														motionX:xDelta
														motionY:yDelta
												   acceleration:accel];
	
	NSSize screenSize = [[TFScreenPreferencesController screen] frame].size;
	NSTimeInterval secsSinceLast = self->createdAt - self->previousCreatedAt;
	
	if (NULL != angle)
		*angle = self->orientedBoundingBox.angle;
	
	if (NULL != width)
		*width = self->orientedBoundingBox.size.width / screenSize.width;
	
	if (NULL != height)
		*height = self->orientedBoundingBox.size.height / screenSize.height;
	
	if (NULL != pArea)
		*pArea = self->area / (screenSize.height * screenSize.width);
	
	if (NULL != aDelta)
		*aDelta = self->orientedBoundingBox.angularMotion / secsSinceLast;
	
	if (NULL != aAccel)
		*aAccel = self->orientedBoundingBox.angularAcceleration / secsSinceLast;
}

@end
