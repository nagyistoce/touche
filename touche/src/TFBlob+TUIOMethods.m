//
//  TFBlob+TUIOMethods.m
//  Touche
//
//  Created by Georg Kaindl on 21/8/08.
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

#import <BBOSC/BBOSCArgument.h>
#import <BBOSC/BBOSCMessage.h>

#import "TFScreenPreferencesController.h"
#import "TFTUIOServer.h"
#import "TFBlobPoint.h"
#import "TFBlobLabel.h"


@implementation TFBlob (TUIOMethods)

- (BBOSCArgument*)tuioAliveArgument
{
	return [BBOSCArgument argumentWithInt:self.label.intLabel];
}

- (BBOSCMessage*)tuioSetMessageForCurrentState
{
	BBOSCMessage* setMsg = [BBOSCMessage messageWithBBOSCAddress:[TFTUIOServer tuioProfileAddress]];
	[setMsg attachArgument:[BBOSCArgument argumentWithString:@"set"]];
	
	// s		sessionID, float
	// x,y		position, float
	// X,Y		motion, float
	// a		acceleration, float
	
	[setMsg attachArgument:[BBOSCArgument argumentWithInt:self.label.intLabel]];
	
	NSSize screenSize = [[TFScreenPreferencesController screen] frame].size;
	float xPos = self.center.x/screenSize.width;
	// Touché uses Quartz-style coordinates with the origin at the bottom left,
	// but TUIO has the origin in the upper left, meaning that we need to invert
	// the y coordinate here.
	float yPos = (1.0f - self.center.y/screenSize.height);
	[setMsg attachArgument:[BBOSCArgument argumentWithFloat:xPos]];
	[setMsg attachArgument:[BBOSCArgument argumentWithFloat:yPos]];
	
	NSTimeInterval secsSinceLast = self.createdAt - self.previousCreatedAt;
	
	float xDelta = ((self.center.x - self.previousCenter.x)/screenSize.width) / secsSinceLast;
	// like the position, we need to invert the yDelta
	float yDelta = -((self.center.y - self.previousCenter.y)/screenSize.height) / secsSinceLast;
	[setMsg attachArgument:[BBOSCArgument argumentWithFloat:xDelta]];
	[setMsg attachArgument:[BBOSCArgument argumentWithFloat:yDelta]];
	
	float xAccel = (self.acceleration.x/screenSize.width) / secsSinceLast;
	// we don't need to invert y accel here, since we're just interested into the vec length anyway
	float yAccel = (self.acceleration.y/screenSize.height) / secsSinceLast;
	[setMsg attachArgument:[BBOSCArgument argumentWithFloat:hypot(xAccel, yAccel)]];
	
	return setMsg;
}

@end
