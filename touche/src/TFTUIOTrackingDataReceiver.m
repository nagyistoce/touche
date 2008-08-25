//
//  TFTUIOTrackingDataReceiver.m
//  Touché
//
//  Created by Georg Kaindl on 24/8/08.
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

#import "TFTUIOTrackingDataReceiver.h"

#import <BBOSC/BBOSCPacket.h>

#import "TFIncludes.h"
#import "TFLocalization.h"
#import "TFTUIOTrackingDataDistributor.h"


@implementation TFTUIOTrackingDataReceiver

- (id)init
{
	return [self initWithHost:@"127.0.0.1" port:3333 error:NULL];
}

- (id)initWithHost:(NSString*)host port:(UInt16)port error:(NSError**)error
{
	in_addr_t inAddr;
	
	if (nil == host || 0 == port || ![TFIPSocket resolveName:host intoAddress:&inAddr]) {
		// TODO: report error
		[self release];
		return nil;
	}

	if (nil != (self = [super init])) {
		connected = YES;
		
		receiverID = [[NSString alloc] initWithFormat:@"%@:%d:TUIO:OSC:UDP", host, port];

		NSString* versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
		if (nil == versionString)
			versionString = TFLocalizedString(@"unknown", @"unknown");
			
		infoDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
								receiverID,
								kToucheTrackingReceiverInfoName,
								[NSString stringWithFormat:
									TFLocalizedString(@"TFTUIOClientName", @"TFTUIOClientName"), host, port],
								kToucheTrackingReceiverInfoHumanReadableName,
								versionString,
								kToucheTrackingReceiverInfoVersion,
								[NSImage imageNamed:@"tuio-image"],
								kToucheTrackingReceiverInfoIcon,
								nil];
		
		struct sockaddr_in peer;
		memset(&peer, 0, sizeof(struct sockaddr_in));
		peer.sin_family = PF_INET;
		peer.sin_addr.s_addr = inAddr;
		peer.sin_port = htons(port);
		
		_peerSA = [[NSData alloc] initWithBytes:&peer length:sizeof(struct sockaddr_in)];
	}
	
	return self;
}

- (void)dealloc
{
	[_peerSA release];
	_peerSA = nil;

	[super dealloc];
}

- (void)receiverShouldQuit
{
	TFTUIOTrackingDataDistributor* distributor = (TFTUIOTrackingDataDistributor*)self.owningDistributor;
	[distributor removeTUIOClient:self];
}

// trackingData is of type BBOSCPacket*
- (void)consumeTrackingData:(id)trackingData
{
	if ([trackingData isKindOfClass:[BBOSCPacket class]]) {
		TFTUIOTrackingDataDistributor* distributor = (TFTUIOTrackingDataDistributor*)self.owningDistributor;
		[distributor sendTUIOPacket:trackingData toEndpoint:self->_peerSA];
	}
}

@end
