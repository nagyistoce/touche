//
//  TFTUIOPacketCreation.m
//  Touché
//
//  Created by Georg Kaindl on 17/3/09.
//
//  Copyright (C) 2009 Georg Kaindl
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

#import "TFTUIOPacketCreation.h"

#import <BBOSC/BBOSCAddress.h>
#import <BBOSC/BBOSCArgument.h>
#import <BBOSC/BBOSCBundle.h>
#import <BBOSC/BBOSCMessage.h>

#import "TFTUIOConstants.h"
#import "TFBlob.h"
#import "TFBlob+TUIOOSCMethods.h"


BBOSCAddress* TFTUIOPCProfileAddress()
{
	static BBOSCAddress* tuioProfileAddress = nil;
	
	if (nil == tuioProfileAddress)
		tuioProfileAddress = [[BBOSCAddress alloc] initWithString:kTFTUIOProfileAddressString];
	
	return [[tuioProfileAddress retain] autorelease];
}

BBOSCMessage* TFTUIOPCSourceMessage()
{
	static BBOSCMessage* sourceMsg = nil;
	
	if (nil == sourceMsg) {
		sourceMsg = [[BBOSCMessage alloc] initWithBBOSCAddress:TFTUIOPCProfileAddress()];
		
		NSString* appName = TFTUIOConstantsSourceName();
		if (nil != appName) {
			[sourceMsg attachArgument:[BBOSCArgument argumentWithString:kTFTUIOSourceArgumentName]];
			[sourceMsg attachArgument:[BBOSCArgument argumentWithString:appName]];
		}
	}
	
	return [[sourceMsg retain] autorelease];
}

BBOSCMessage* TFTUIOPCFrameSequenceNumberMessageForFrameNumber(NSInteger frameNumber)
{
	BBOSCMessage* fseqMessage = [BBOSCMessage messageWithBBOSCAddress:TFTUIOPCProfileAddress()];
	[fseqMessage attachArgument:[BBOSCArgument argumentWithString:kTFTUIOFrameSequenceNumberArgumentName]];
	[fseqMessage attachArgument:[BBOSCArgument argumentWithInt:frameNumber]];
	
	return fseqMessage;
}

BBOSCMessage* TFTUIOPCAliveMessageForBlobs(NSArray* blobs)
{
	BBOSCMessage* aliveMessage = [BBOSCMessage messageWithBBOSCAddress:TFTUIOPCProfileAddress()];
	[aliveMessage attachArgument:[BBOSCArgument argumentWithString:kTFTUIOAliveArgumentName]];
	
	for (TFBlob* blob in blobs)
		[aliveMessage attachArgument:[blob tuioAliveArgument]];
	
	return aliveMessage;
}

BBOSCBundle* TFTUIOPCBundleWithData(NSInteger frameNumber,
									NSArray* activeBlobs,
									NSArray* movedBlobs)
{
	BBOSCBundle* tuioBundle = [BBOSCBundle bundleWithTimestamp:[NSDate date]];
	[tuioBundle attachObject:TFTUIOPCSourceMessage()];
	
	for (TFBlob* blob in movedBlobs)
		[tuioBundle attachObject:[blob tuioSetMessageForCurrentState]];
	
	[tuioBundle attachObject:TFTUIOPCAliveMessageForBlobs(activeBlobs)];
	[tuioBundle attachObject:TFTUIOPCFrameSequenceNumberMessageForFrameNumber(frameNumber)];
	
	return tuioBundle;
}
