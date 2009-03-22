//
//  TFTUIOFlashLCTrackingDataReceiver.m
//  Touché
//
//  Created by Georg Kaindl on 19/3/09.
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

#import "TFTUIOFlashLCTrackingDataReceiver.h"

#import <BBOSC/BBOSCPacket.h>

#import "TFFlashLCSHMEM.h"
#import "TFIncludes.h"


NSString* TFTUIOFlashLCTrackingDataReceiverIDFormat = @"%@:TUIO:OSC:FlashLC";

@interface TFTUIOFlashLCTrackingDataReceiver (PrivateMethods)
- (void)_disconnectLC;
@end

@implementation TFTUIOFlashLCTrackingDataReceiver

- (id)init
{
	[self release];
	
	return nil;
}

- (id)initWithConnectionName:(NSString*)connectionName
			   andMethodName:(NSString*)methodName
{
	if (nil == connectionName || nil == methodName) {
		[self release];
		return nil;
	}
	
	if (nil != (self = [super init])) {
		_connectionName = [connectionName copy];
		_connectionMethod = [methodName copy];
		
		_lcConnection = TFLCSConnect([_connectionName cStringUsingEncoding:NSASCIIStringEncoding],
									 [_connectionMethod cStringUsingEncoding:NSASCIIStringEncoding],
									 (void*)NULL,
									 (void*)NULL);
		
		if (NULL == _lcConnection) {
			[self release];
			return nil;
		}
		
		connected = YES;
		
		receiverID = [[NSString alloc] initWithFormat:TFTUIOFlashLCTrackingDataReceiverIDFormat, _connectionName];
		
		NSString* versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
		if (nil == versionString)
			versionString = TFLocalizedString(@"unknown", @"unknown");
		
		infoDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
						  receiverID,
						  kToucheTrackingReceiverInfoName,
						  [NSString stringWithFormat:
						   TFLocalizedString(@"TFTUIOFlashLCClientName", @"TFTUIOFlashLCClientName"), _connectionName],
						  kToucheTrackingReceiverInfoHumanReadableName,
						  versionString,
						  kToucheTrackingReceiverInfoVersion,
						  [NSImage imageNamed:@"tuio-image"],
						  kToucheTrackingReceiverInfoIcon,
						  nil];
	}
	
	return self;
}

- (void)dealloc
{
	[self _disconnectLC];
	
	[_connectionName release];
	_connectionName = nil;
	
	[_connectionMethod release];
	_connectionMethod = nil;
	
	[super dealloc];
}

- (void)receiverShouldQuit
{
	// Do nothing.
}

- (void)consumeTrackingData:(id)trackingData
{
	if ([trackingData isKindOfClass:[BBOSCPacket class]]) {
		NSData* packetData = [(BBOSCPacket*)trackingData packetizedData];
		
		int len = [packetData length];
		if (0 < len) {
			TFLCSSendByteArray(_lcConnection, [packetData bytes], len);
		}		
	}
}

- (void)_disconnectLC
{
	if (NULL != _lcConnection) {
		TFLCSDisconnect(_lcConnection);
		_lcConnection = NULL;
	}
}

@end
