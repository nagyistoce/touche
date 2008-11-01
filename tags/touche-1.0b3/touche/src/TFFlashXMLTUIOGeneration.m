//
//  TFFlashXMLTUIOGeneration.m
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

#import "TFFlashXMLTUIOGeneration.h"

#import "TFTUIOConstants.h"
#import "TFBlobLabel.h"
#import "TFBlob+TUIOMethods.h"


#define SECONDS_FROM_NTPEPOC_TO_COCOA_REFDATE 1543503872
#define TWO_POW_32 (4294967296.0)

NSString* TFFlashXMLTUIOEnvelope(NSString* localAddress, UInt16 port)
{
	NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];	
	UInt32 seconds = trunc(now);
	double fract = now - seconds;
	
	seconds += SECONDS_FROM_NTPEPOC_TO_COCOA_REFDATE;
	UInt32 fractional = (UInt32)(fract * TWO_POW_32);
	UInt64 timestamp = (((UInt64)seconds) << 32) | fractional;
	
	NSString* envelope = [NSString stringWithFormat:
							@"<OSCPACKET ADDRESS=\"%@\" PORT=\"%hu\" TIME=\"%qu\">"
							@"%%@"
							@"</OSCPACKET>",
								localAddress,
								port,
								timestamp];
	
	return envelope;
}

NSString* TFFlashXMLTUIOSourceMessage()
{
	static NSString* sourceMsg = nil;
	
	if (nil == sourceMsg) {
		NSString* appName = TFTUIOConstantsSourceName();
		if (nil == appName)
			appName = @"";
	
		sourceMsg = [[NSString alloc] initWithFormat:
					 @"<MESSAGE NAME=\"%@\">"
					 @"<ARGUMENT TYPE=\"s\" VALUE=\"%@\" />"
					 @"<ARGUMENT TYPE=\"s\" VALUE=\"%@\" />"
					 @"</MESSAGE>",
					 kTFTUIOProfileAddressString,
					 kTFTUIOSourceArgumentName,
					 appName];
	}
	
	return [[sourceMsg retain] autorelease];
}

NSString* TFFlashXMLTUIOAliveMessage(NSArray* blobs)
{
	NSMutableString* aliveMsg = [NSMutableString stringWithFormat:
								 @"<MESSAGE NAME=\"%@\">"
								 @"<ARGUMENT TYPE=\"s\" VALUE=\"%@\" />",
								 kTFTUIOProfileAddressString,
								 kTFTUIOAliveArgumentName];
	
	for (TFBlob* blob in blobs)
		[aliveMsg appendString:[blob flashXmlTuioAliveArgument]];
	
	[aliveMsg appendString:@"</MESSAGE>"];
	
	return aliveMsg;
}

NSString* TFFlashXMLTUIOFrameSequenceMessage(NSUInteger frameSequenceNumber)
{
	static NSString* fseqMsg = nil;
	
	if (nil == fseqMsg)
		fseqMsg = [[NSString alloc] initWithFormat:
				   @"<MESSAGE NAME=\"%@\">"
				   @"<ARGUMENT TYPE=\"s\" VALUE=\"%@\" />"
				   @"<ARGUMENT TYPE=\"i\" VALUE=\"%%u\" />"
				   @"</MESSAGE>",
				   kTFTUIOProfileAddressString,
				   kTFTUIOFrameSequenceNumberArgumentName];
	
	return [NSString stringWithFormat:fseqMsg, frameSequenceNumber];
}

NSString* TFFlashXMLTUIOBundle(NSArray* activeBlobs, NSArray* movingBlobs, NSString* host, UInt16 port, NSUInteger fseq)
{
	NSMutableString* bundle = [NSMutableString stringWithString:TFFlashXMLTUIOSourceMessage()];
	
	for (TFBlob* blob in movingBlobs)
		[bundle appendString:[blob flashXmlTuioSetMessage]];
	
	[bundle appendString:TFFlashXMLTUIOAliveMessage(activeBlobs)];
	[bundle appendString:TFFlashXMLTUIOFrameSequenceMessage(fseq)];
	
	return [NSString stringWithFormat:TFFlashXMLTUIOEnvelope(host, port), bundle];
}


@implementation TFBlob (TFFlashXMLTUIOGeneration)

- (NSString*)flashXmlTuioAliveArgument
{
	return [NSString stringWithFormat:
			@"<ARGUMENT TYPE=\"i\" VALUE=\"%d\" />", self.label.intLabel];
}

- (NSString*)flashXmlTuioSetMessage
{
	NSInteger s;
	float x, y, X, Y, a;
	
	// s		sessionID, float
	// x,y		position, float
	// X,Y		motion, float
	// a		acceleration, float
	
	[self getTuioDataForCurrentStateWithSessionID:&s
										positionX:&x
										positionY:&y
										  motionX:&X
										  motionY:&Y
									 acceleration:&a];
	
	return [NSString stringWithFormat:
			@"<MESSAGE NAME=\"%@\">"
			@"<ARGUMENT TYPE=\"s\" VALUE=\"%@\" />"
			@"<ARGUMENT TYPE=\"i\" VALUE=\"%d\" />"
			@"<ARGUMENT TYPE=\"f\" VALUE=\"%f\" />"
			@"<ARGUMENT TYPE=\"f\" VALUE=\"%f\" />"
			@"<ARGUMENT TYPE=\"f\" VALUE=\"%f\" />"
			@"<ARGUMENT TYPE=\"f\" VALUE=\"%f\" />"
			@"<ARGUMENT TYPE=\"f\" VALUE=\"%f\" />"
			@"</MESSAGE>",
			kTFTUIOProfileAddressString,
			kTFTUIOSetArgumentName,
			s, x, y, X, Y, a];
}

@end
