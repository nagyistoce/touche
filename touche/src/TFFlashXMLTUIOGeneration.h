//
//  TFFlashXMLTUIOGeneration.h
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

#import "TFTUIOConstants.h"
#import "TFBlob.h"

NSString* TFFlashXMLTUIOBundleForTUIOVersion(TFTUIOVersion version,
											 NSArray* activeBlobs,
											 NSArray* movingBlobs,
											 NSString* host,
											 UInt16 port,
											 NSUInteger fseq);
NSString* TFFlashXMLTUIOEnvelope(NSString* localAddress, UInt16 port);

NSString* TFFlashXMLTUIO10CursorSourceMessage();
NSString* TFFlashXMLTUIO10CursorAliveMessage(NSArray* blobs);
NSString* TFFlashXMLTUIO10CursorFrameSequenceMessage(NSUInteger frameSequenceNumber);
NSString* TFFlashXMLTUIO10CursorBundle(NSArray* activeBlobs, NSArray* movingBlobs, NSString* host, UInt16 port, NSUInteger fseq);

NSString* TFFlashXMLTUIO11BlobSourceMessage();
NSString* TFFlashXMLTUIO11BlobAliveMessage(NSArray* blobs);
NSString* TFFlashXMLTUIO11BlobFrameSequenceMessage(NSUInteger frameSequenceNumber);
NSString* TFFlashXMLTUIO11BlobBundle(NSArray* activeBlobs, NSArray* movingBlobs, NSString* host, UInt16 port, NSUInteger fseq);


@interface TFBlob (TFFlashXMLTUIOGeneration)
- (NSString*)flashXmlTuio10CursorAliveArgument;
- (NSString*)flashXmlTuio10CursorSetMessage;

- (NSString*)flashXmlTuio11BlobAliveArgument;
- (NSString*)flashXmlTuio11BlobSetMessage;
@end