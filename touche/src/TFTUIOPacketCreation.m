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


BBOSCAddress* TFTUIOPC10CursorProfileAddress()
{
	static BBOSCAddress* tuioProfileAddress = nil;
	
	if (nil == tuioProfileAddress)
		tuioProfileAddress = [[BBOSCAddress alloc] initWithString:kTFTUIO10CursorProfileAddressString];
	
	return [[tuioProfileAddress retain] autorelease];
}

BBOSCAddress* TFTUIOPC11BlobsProfileAddress()
{
	static BBOSCAddress* tuioProfileAddress = nil;
	
	if (nil == tuioProfileAddress)
		tuioProfileAddress = [[BBOSCAddress alloc] initWithString:kTFTUIO11BlobProfileAddressString];
	
	return [[tuioProfileAddress retain] autorelease];
}

BBOSCAddress* TFTUIOPC11BlobProfileAddress()
{
	static BBOSCAddress* tuioProfileAddress = nil;
	
	if (nil == tuioProfileAddress)
		tuioProfileAddress = [[BBOSCAddress alloc] initWithString:kTFTUIO11BlobProfileAddressString];
	
	return [[tuioProfileAddress retain] autorelease];
}

BBOSCMessage* TFTUIOPC10CursorSourceMessage()
{
	static BBOSCMessage* sourceMsg = nil;
	
	if (nil == sourceMsg) {
		sourceMsg = [[BBOSCMessage alloc] initWithBBOSCAddress:TFTUIOPC10CursorProfileAddress()];
		
		NSString* appName = TFTUIOConstantsSourceName();
		if (nil != appName) {
			[sourceMsg attachArgument:[BBOSCArgument argumentWithString:kTFTUIO10SourceArgumentName]];
			[sourceMsg attachArgument:[BBOSCArgument argumentWithString:appName]];
		}
	}
	
	return [[sourceMsg retain] autorelease];
}

BBOSCMessage* TFTUIOPC11BlobSourceMessage()
{
	static BBOSCMessage* sourceMsg = nil;
	
	if (nil == sourceMsg) {
		sourceMsg = [[BBOSCMessage alloc] initWithBBOSCAddress:TFTUIOPC11BlobsProfileAddress()];
		
		NSString* appName = TFTUIOConstantsSourceName();
		if (nil != appName) {
			[sourceMsg attachArgument:[BBOSCArgument argumentWithString:kTFTUIO10SourceArgumentName]];
			[sourceMsg attachArgument:[BBOSCArgument argumentWithString:appName]];
		}
	}
	
	return [[sourceMsg retain] autorelease];
}

BBOSCMessage* TFTUIOPC10CursorFrameSequenceNumberMessageForFrameNumber(NSInteger frameNumber)
{
	BBOSCMessage* fseqMessage = [BBOSCMessage messageWithBBOSCAddress:TFTUIOPC10CursorProfileAddress()];
	[fseqMessage attachArgument:[BBOSCArgument argumentWithString:kTFTUIO10FrameSequenceNumberArgumentName]];
	[fseqMessage attachArgument:[BBOSCArgument argumentWithInt:frameNumber]];
	
	return fseqMessage;
}

BBOSCMessage* TFTUIOPC11BlobFrameSequenceNumberMessageForFrameNumber(NSInteger frameNumber)
{
	BBOSCMessage* fseqMessage = [BBOSCMessage messageWithBBOSCAddress:TFTUIOPC11BlobsProfileAddress()];
	[fseqMessage attachArgument:[BBOSCArgument argumentWithString:kTFTUIO10FrameSequenceNumberArgumentName]];
	[fseqMessage attachArgument:[BBOSCArgument argumentWithInt:frameNumber]];
	
	return fseqMessage;
}

BBOSCMessage* TFTUIOPC10CursorAliveMessageForBlobs(NSArray* blobs)
{
	BBOSCMessage* aliveMessage = [BBOSCMessage messageWithBBOSCAddress:TFTUIOPC10CursorProfileAddress()];
	[aliveMessage attachArgument:[BBOSCArgument argumentWithString:kTFTUIO10AliveArgumentName]];
	
	for (TFBlob* blob in blobs)
		[aliveMessage attachArgument:[blob tuio10AliveArgument]];
	
	return aliveMessage;
}

BBOSCMessage* TFTUIOPC11BlobAliveMessageForBlobs(NSArray* blobs)
{
	BBOSCMessage* aliveMessage = [BBOSCMessage messageWithBBOSCAddress:TFTUIOPC11BlobsProfileAddress()];
	[aliveMessage attachArgument:[BBOSCArgument argumentWithString:kTFTUIO10AliveArgumentName]];
	
	for (TFBlob* blob in blobs)
		[aliveMessage attachArgument:[blob tuio10AliveArgument]];
	
	return aliveMessage;
}

id TFTUIOPCBundleWithDataForTUIOVersion(TFTUIOVersion version,
										NSInteger frameNumber,
										NSArray* activeBlobs,
										NSArray* movedBlobs)
{
	id data = nil;

	switch(version) {
		case TFTUIOVersion1_0Cursors:
			data = TFTUIOPC10CursorBundleWithData(frameNumber, activeBlobs, movedBlobs);
			break;
		case TFTUIOVersion1_1Blobs:
			data = TFTUIOPC11BlobsBundleWithData(frameNumber, activeBlobs, movedBlobs);
			break;
		case TFTUIOVersion1_0CursorsAnd1_1Blobs: {
			id p1 = TFTUIOPC10CursorBundleWithData(frameNumber, activeBlobs, movedBlobs);
			id p2 = TFTUIOPC11BlobsBundleWithData(frameNumber, activeBlobs, movedBlobs);
			data = [NSArray arrayWithObjects:p1, p2, nil];
			break;
		}
	}
	
	return data;
}

BBOSCBundle* TFTUIOPC10CursorBundleWithData(NSInteger frameNumber,
									NSArray* activeBlobs,
									NSArray* movedBlobs)
{	
	BBOSCBundle* tuioBundle = [BBOSCBundle bundleWithTimestamp:[NSDate date]];
	[tuioBundle attachObject:TFTUIOPC10CursorSourceMessage()];
	
	for (TFBlob* blob in movedBlobs)
		[tuioBundle attachObject:[blob tuio10CursorSetMessageForCurrentState]];
	
	[tuioBundle attachObject:TFTUIOPC10CursorAliveMessageForBlobs(activeBlobs)];
	[tuioBundle attachObject:TFTUIOPC10CursorFrameSequenceNumberMessageForFrameNumber(frameNumber)];
	
	return tuioBundle;
}

BBOSCBundle* TFTUIOPC11BlobsBundleWithData(NSInteger frameNumber,
										   NSArray* activeBlobs,
										   NSArray* movedBlobs)
{
	BBOSCBundle* tuioBundle = [BBOSCBundle bundleWithTimestamp:[NSDate date]];
	[tuioBundle attachObject:TFTUIOPC11BlobSourceMessage()];
	
	for (TFBlob* blob in movedBlobs)
		[tuioBundle attachObject:[blob tuio11BlobSetMessageForCurrentState]];
	
	[tuioBundle attachObject:TFTUIOPC11BlobAliveMessageForBlobs(activeBlobs)];
	[tuioBundle attachObject:TFTUIOPC11BlobFrameSequenceNumberMessageForFrameNumber(frameNumber)];
	
	return tuioBundle;
}
