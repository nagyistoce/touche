//
//  TFTUIOPacketCreation.h
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

#import <Cocoa/Cocoa.h>

#import "TFTUIOConstants.h"


@class BBOSCAddress, BBOSCBundle, BBOSCMessage;

BBOSCAddress* TFTUIOPC10CursorProfileAddress();
BBOSCMessage* TFTUIOPC10CursorSourceMessage();
BBOSCMessage* TFTUIOPC10CursorFrameSequenceNumberMessageForFrameNumber(NSInteger frameNumber);
BBOSCMessage* TFTUIOPC10CursorAliveMessageForBlobs(NSArray* blobs);

BBOSCAddress* TFTUIOPC11BlobProfileAddress();
BBOSCMessage* TFTUIOPC11BlobSourceMessage();
BBOSCMessage* TFTUIOPC11BlobFrameSequenceNumberMessageForFrameNumber(NSInteger frameNumber);
BBOSCMessage* TFTUIOPC11BlobAliveMessageForBlobs(NSArray* blobs);

// returns a BBOSCPacket or an NSArray if multiple packets have to be sent for a given version
id TFTUIOPCBundleWithDataForTUIOVersion(TFTUIOVersion version,
										NSInteger frameNumber,
										NSArray* activeBlobs,
										NSArray* movedBlobs);

BBOSCBundle* TFTUIOPC10CursorBundleWithData(NSInteger frameNumber,
											NSArray* activeBlobs,
											NSArray* movedBlobs);

BBOSCBundle* TFTUIOPC11BlobsBundleWithData(NSInteger frameNumber,
										   NSArray* activeBlobs,
										   NSArray* movedBlobs);