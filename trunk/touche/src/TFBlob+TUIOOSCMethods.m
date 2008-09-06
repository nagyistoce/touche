//
//  TFBlob+TUIOOSCMethods.m
//  Touché
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

#import "TFBlob+TUIOOSCMethods.h"

#import <BBOSC/BBOSCArgument.h>
#import <BBOSC/BBOSCMessage.h>

#import "TFBlob+TUIOMethods.h"
#import "TFTUIOConstants.h"
#import "TFScreenPreferencesController.h"
#import "TFTUIOOSCServer.h"
#import "TFBlobLabel.h"


@implementation TFBlob (TUIOOSCMethods)

- (BBOSCArgument*)tuioAliveArgument
{
	return [BBOSCArgument argumentWithInt:self.label.intLabel];
}

- (BBOSCMessage*)tuioSetMessageForCurrentState
{
	BBOSCMessage* setMsg = [BBOSCMessage messageWithBBOSCAddress:[TFTUIOOSCServer tuioProfileAddress]];
	[setMsg attachArgument:[BBOSCArgument argumentWithString:kTFTUIOSetArgumentName]];
	
	// s		sessionID, float
	// x,y		position, float
	// X,Y		motion, float
	// a		acceleration, float
	
	NSInteger s;
	float x, y, X, Y, a;
	
	[self getTuioDataForCurrentStateWithSessionID:&s
										positionX:&x
										positionY:&y
										  motionX:&X
										  motionY:&Y
									 acceleration:&a];
	
	[setMsg attachArgument:[BBOSCArgument argumentWithInt:s]];
	[setMsg attachArgument:[BBOSCArgument argumentWithFloat:x]];
	[setMsg attachArgument:[BBOSCArgument argumentWithFloat:y]];
	[setMsg attachArgument:[BBOSCArgument argumentWithFloat:X]];
	[setMsg attachArgument:[BBOSCArgument argumentWithFloat:Y]];
	[setMsg attachArgument:[BBOSCArgument argumentWithFloat:a]];
	
	return setMsg;
}

@end
