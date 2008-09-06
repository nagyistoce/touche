//
//  TFTUIOOSCServer.h
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

#import <Cocoa/Cocoa.h>

#import "TFOSCServer.h"


@class TFTUIOOSCServer;

@interface NSObject (TFTUIOOSCServerDelegate)
- (void)tuioServer:(TFTUIOOSCServer*)server networkErrorDidOccur:(NSError*)error;
@end

@class BBOSCAddress, BBOSCBundle, BBOSCMessage, TFIPDatagramSocket, TFIPUDPSocket;

@interface TFTUIOOSCServer : TFOSCServer {
	NSThread*		_socketThread;
}

+ (BBOSCAddress*)tuioProfileAddress;
+ (BBOSCMessage*)tuioSourceMessage;
+ (BBOSCMessage*)tuioFrameSequenceNumberMessageForFrameNumber:(NSInteger)frameNumber;
+ (BBOSCMessage*)tuioAliveMessageForBlobs:(NSArray*)blobs;
+ (BBOSCBundle*)tuioBundleForFrameNumber:(NSInteger)frameNumber
							 activeBlobs:(NSArray*)activeBlobs
							  movedBlobs:(NSArray*)movedBlobs;

- (id)initWithPort:(UInt16)port andLocalAddress:(NSString*)localAddress error:(NSError**)error;
- (void)dealloc;

- (void)invalidate;

#pragma mark -
#pragma mark TFIPDatagramSocket delegate

- (void)socketHadReadWriteError:(TFIPDatagramSocket*)socket;

@end
