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
#import "TFTUIOPacketCreation.h"
#import "TFScreenPreferencesController.h"
#import "TFTUIOOSCServer.h"
#import "TFBlobLabel.h"


@implementation TFBlob (TUIOOSCMethods)

- (BBOSCArgument*)tuio10AliveArgument
{
	return [BBOSCArgument argumentWithInt:self.label.intLabel];
}

- (BBOSCArgument*)tuio11AliveArgument
{
	return [BBOSCArgument argumentWithInt:self.label.intLabel];
}

- (BBOSCMessage*)tuio10CursorSetMessageForCurrentState
{
	BBOSCMessage* setMsg = [BBOSCMessage messageWithBBOSCAddress:TFTUIOPC10CursorProfileAddress()];
	[setMsg attachArgument:[BBOSCArgument argumentWithString:kTFTUIO10SetArgumentName]];
	
	// s		sessionID, float
	// x,y		position, float
	// X,Y		motion, float
	// a		acceleration, float
	
	NSInteger s;
	float x, y, X, Y, a;
	
	[self getTuio10CursorSetMessageForCurrentStateWithSessionID:&s
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

- (BBOSCMessage*)tuio11BlobSetMessageForCurrentState
{
	BBOSCMessage* setMsg = [BBOSCMessage messageWithBBOSCAddress:TFTUIOPC11BlobProfileAddress()];
	[setMsg attachArgument:[BBOSCArgument argumentWithString:kTFTUIO10SetArgumentName]];
	
	// s		sessionID, float
	// x,y		position, float
	// a		oriented bounding box angle, float
	// w, h		oriented bounding box width & height after inverse rotation, floar
	// f		area, float
	// X,Y		motion, float
	// A		oriented bounding box angular motion, float
	// m		acceleration, float
	// r		oriented bounding box angular acceleration, float
	
	NSInteger s;
	float x, y, X, Y, m, a, w, h, f, A, r;
	
	[self getTuio11BlobSetMessageForCurrentStateWithSessionID:&s
													positionX:&x
													positionY:&y
														angle:&a
														width:&w
													   height:&h
														 area:&f
													  motionX:&X
													  motionY:&Y
												motionAngular:&A
												 acceleration:&m
										   motionAcceleration:&r];
	
	[setMsg attachArgument:[BBOSCArgument argumentWithInt:s]];
	[setMsg attachArgument:[BBOSCArgument argumentWithFloat:x]];
	[setMsg attachArgument:[BBOSCArgument argumentWithFloat:y]];
	[setMsg attachArgument:[BBOSCArgument argumentWithFloat:a]];
	[setMsg attachArgument:[BBOSCArgument argumentWithFloat:w]];
	[setMsg attachArgument:[BBOSCArgument argumentWithFloat:h]];
	[setMsg attachArgument:[BBOSCArgument argumentWithFloat:f]];
	[setMsg attachArgument:[BBOSCArgument argumentWithFloat:X]];
	[setMsg attachArgument:[BBOSCArgument argumentWithFloat:Y]];
	[setMsg attachArgument:[BBOSCArgument argumentWithFloat:A]];
	[setMsg attachArgument:[BBOSCArgument argumentWithFloat:m]];
	[setMsg attachArgument:[BBOSCArgument argumentWithFloat:r]];
	
	return setMsg;
}

@end
