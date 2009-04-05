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


#define TWO_POW_32 (4294967296.0)

NSString* TFFlashXMLTUIOBundleForTUIOVersion(TFTUIOVersion version,
											 NSArray* activeBlobs,
											 NSArray* movingBlobs,
											 NSString* host,
											 UInt16 port,
											 NSUInteger fseq)
{
	id rv = nil;
	
	switch (version) {
		case TFTUIOVersion1_0Cursors:
			rv = TFFlashXMLTUIO10CursorBundle(activeBlobs, movingBlobs, host, port, fseq);
			break;
		
		case TFTUIOVersion1_1Blobs:
			rv = TFFlashXMLTUIO11BlobBundle(activeBlobs, movingBlobs, host, port, fseq);
			break;
		
		case TFTUIOVersion1_0CursorsAnd1_1Blobs: {
			NSString* p1 = TFFlashXMLTUIO10CursorBundle(activeBlobs, movingBlobs, host, port, fseq);
			NSString* p2 = TFFlashXMLTUIO11BlobBundle(activeBlobs, movingBlobs, host, port, fseq);
			rv = [NSString stringWithFormat:@"%@%@", p1, p2];
			break;
		}
	}
	
	return rv;
}

NSString* TFFlashXMLTUIOEnvelope(NSString* localAddress, UInt16 port)
{
	NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];	
	UInt32 seconds = trunc(now);
	double fract = now - seconds;
	
	seconds += TFTUIOTimeIntervalBetweenCocoaAndNTPRefDate();
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

#pragma mark -
#pragma mark TUIO 1.0 Cursor Profile

NSString* TFFlashXMLTUIO10CursorSourceMessage()
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
					 kTFTUIO10CursorProfileAddressString,
					 kTFTUIO10SourceArgumentName,
					 appName];
	}
	
	return [[sourceMsg retain] autorelease];
}

NSString* TFFlashXMLTUIO10CursorAliveMessage(NSArray* blobs)
{
	NSMutableString* aliveMsg = [NSMutableString stringWithFormat:
								 @"<MESSAGE NAME=\"%@\">"
								 @"<ARGUMENT TYPE=\"s\" VALUE=\"%@\" />",
								 kTFTUIO10CursorProfileAddressString,
								 kTFTUIO10AliveArgumentName];
	
	for (TFBlob* blob in blobs)
		[aliveMsg appendString:[blob flashXmlTuio10CursorAliveArgument]];
	
	[aliveMsg appendString:@"</MESSAGE>"];
	
	return aliveMsg;
}

NSString* TFFlashXMLTUIO10CursorFrameSequenceMessage(NSUInteger frameSequenceNumber)
{
	static NSString* fseqMsg = nil;
	
	if (nil == fseqMsg)
		fseqMsg = [[NSString alloc] initWithFormat:
				   @"<MESSAGE NAME=\"%@\">"
				   @"<ARGUMENT TYPE=\"s\" VALUE=\"%@\" />"
				   @"<ARGUMENT TYPE=\"i\" VALUE=\"%%u\" />"
				   @"</MESSAGE>",
				   kTFTUIO10CursorProfileAddressString,
				   kTFTUIO10FrameSequenceNumberArgumentName];
	
	return [NSString stringWithFormat:fseqMsg, frameSequenceNumber];
}

NSString* TFFlashXMLTUIO10CursorBundle(NSArray* activeBlobs, NSArray* movingBlobs, NSString* host, UInt16 port, NSUInteger fseq)
{
	NSMutableString* bundle = [NSMutableString stringWithString:TFFlashXMLTUIO10CursorSourceMessage()];
	
	for (TFBlob* blob in movingBlobs)
		[bundle appendString:[blob flashXmlTuio10CursorSetMessage]];
	
	[bundle appendString:TFFlashXMLTUIO10CursorAliveMessage(activeBlobs)];
	[bundle appendString:TFFlashXMLTUIO10CursorFrameSequenceMessage(fseq)];
	
	return [NSString stringWithFormat:TFFlashXMLTUIOEnvelope(host, port), bundle];
}

#pragma mark -
#pragma mark TUIO 1.1 Blob Profile

NSString* TFFlashXMLTUIO11BlobSourceMessage()
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
					 kTFTUIO11BlobProfileAddressString,
					 kTFTUIO10SourceArgumentName,
					 appName];
	}
	
	return [[sourceMsg retain] autorelease];
}

NSString* TFFlashXMLTUIO11BlobAliveMessage(NSArray* blobs)
{
	NSMutableString* aliveMsg = [NSMutableString stringWithFormat:
								 @"<MESSAGE NAME=\"%@\">"
								 @"<ARGUMENT TYPE=\"s\" VALUE=\"%@\" />",
								 kTFTUIO11BlobProfileAddressString,
								 kTFTUIO10AliveArgumentName];
	
	for (TFBlob* blob in blobs)
		[aliveMsg appendString:[blob flashXmlTuio11BlobAliveArgument]];
	
	[aliveMsg appendString:@"</MESSAGE>"];
	
	return aliveMsg;
}

NSString* TFFlashXMLTUIO11BlobFrameSequenceMessage(NSUInteger frameSequenceNumber)
{
	static NSString* fseqMsg = nil;
	
	if (nil == fseqMsg)
		fseqMsg = [[NSString alloc] initWithFormat:
				   @"<MESSAGE NAME=\"%@\">"
				   @"<ARGUMENT TYPE=\"s\" VALUE=\"%@\" />"
				   @"<ARGUMENT TYPE=\"i\" VALUE=\"%%u\" />"
				   @"</MESSAGE>",
				   kTFTUIO11BlobProfileAddressString,
				   kTFTUIO10FrameSequenceNumberArgumentName];
	
	return [NSString stringWithFormat:fseqMsg, frameSequenceNumber];
}

NSString* TFFlashXMLTUIO11BlobBundle(NSArray* activeBlobs, NSArray* movingBlobs, NSString* host, UInt16 port, NSUInteger fseq)
{
	NSMutableString* bundle = [NSMutableString stringWithString:TFFlashXMLTUIO11BlobSourceMessage()];
	
	for (TFBlob* blob in movingBlobs)
		[bundle appendString:[blob flashXmlTuio11BlobSetMessage]];
	
	[bundle appendString:TFFlashXMLTUIO11BlobAliveMessage(activeBlobs)];
	[bundle appendString:TFFlashXMLTUIO11BlobFrameSequenceMessage(fseq)];
	
	return [NSString stringWithFormat:TFFlashXMLTUIOEnvelope(host, port), bundle];
}

#pragma mark -
#pragma mark TFBlob extensions

@implementation TFBlob (TFFlashXMLTUIOGeneration)

- (NSString*)flashXmlTuio10CursorAliveArgument
{
	return [NSString stringWithFormat:
			@"<ARGUMENT TYPE=\"i\" VALUE=\"%d\" />", self.label.intLabel];
}

- (NSString*)flashXmlTuio10CursorSetMessage
{
	NSInteger s;
	float x, y, X, Y, a;
	
	// s		sessionID, float
	// x,y		position, float
	// X,Y		motion, float
	// a		acceleration, float
	
	[self getTuio10CursorSetMessageForCurrentStateWithSessionID:&s
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
			kTFTUIO10CursorProfileAddressString,
			kTFTUIO10SetArgumentName,
			s, x, y, X, Y, a];
}

- (NSString*)flashXmlTuio11BlobAliveArgument
{
	return [NSString stringWithFormat:
			@"<ARGUMENT TYPE=\"i\" VALUE=\"%d\" />", self.label.intLabel];
}

- (NSString*)flashXmlTuio11BlobSetMessage
{
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
	
	return [NSString stringWithFormat:
			@"<MESSAGE NAME=\"%@\">"
			@"<ARGUMENT TYPE=\"s\" VALUE=\"%@\" />"
			@"<ARGUMENT TYPE=\"i\" VALUE=\"%d\" />"
			@"<ARGUMENT TYPE=\"f\" VALUE=\"%f\" />"
			@"<ARGUMENT TYPE=\"f\" VALUE=\"%f\" />"
			@"<ARGUMENT TYPE=\"f\" VALUE=\"%f\" />"
			@"<ARGUMENT TYPE=\"f\" VALUE=\"%f\" />"
			@"<ARGUMENT TYPE=\"f\" VALUE=\"%f\" />"
			@"<ARGUMENT TYPE=\"f\" VALUE=\"%f\" />"
			@"<ARGUMENT TYPE=\"f\" VALUE=\"%f\" />"
			@"<ARGUMENT TYPE=\"f\" VALUE=\"%f\" />"
			@"<ARGUMENT TYPE=\"f\" VALUE=\"%f\" />"
			@"<ARGUMENT TYPE=\"f\" VALUE=\"%f\" />"
			@"<ARGUMENT TYPE=\"f\" VALUE=\"%f\" />"
			@"</MESSAGE>",
			kTFTUIO11BlobProfileAddressString,
			kTFTUIO10SetArgumentName,
			s, x, y, a, w, h, f, X, Y, A, m, r];
}

@end
