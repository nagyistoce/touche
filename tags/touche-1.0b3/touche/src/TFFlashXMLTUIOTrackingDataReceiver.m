//
//  TFFlashXMLTUIOTrackingDataReceiver.m
//  Touché
//
//  Created by Georg Kaindl on 6/9/08.
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

#import "TFFlashXMLTUIOTrackingDataReceiver.h"

#import "TFLocalization.h"
#import "TFIPStreamSocket.h"
#import "TFIPTCPSocket.h"
#import "TFFlashXMLTUIOTrackingDataDistributor.h"


#define SECONDS_IN_RUNLOOP	((NSTimeInterval)5.0)

@interface TFFlashXMLTUIOTrackingDataReceiver (PrivateMethods)
- (void)_socketThreadFunc;
@end

@implementation TFFlashXMLTUIOTrackingDataReceiver

- (id)init
{
	[self release];
	
	return nil;
}

- (id)initWithConnectedSocket:(TFIPStreamSocket*)socket
{
	if (![socket isConnected]) {
		[self release];
		return nil;
	}
	
	if (nil != (self = [super init])) {
		connected = YES;
				
		_socket = [socket retain];
		_socket.delegate = self;
		
		// set the tcp no delay flag, so that we can send as fast as possible
		if ([socket isKindOfClass:[TFIPTCPSocket class]])
			[(TFIPTCPSocket*)socket setTCPNoDelay:YES];
		
		_socketThread = [[NSThread alloc] initWithTarget:self
												selector:@selector(_socketThreadFunc)
												  object:nil];
		
		[_socketThread start];
				
		NSString* peerName = [_socket peerNameString];
		receiverID = [[NSString alloc] initWithFormat:@"%@:TUIO:FLASH:XML-SOCKET", peerName];
		
		NSString* versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
		if (nil == versionString)
			versionString = TFLocalizedString(@"unknown", @"unknown");
		
		infoDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
						  receiverID,
						  kToucheTrackingReceiverInfoName,
						  [NSString stringWithFormat:
						   TFLocalizedString(@"TFTUIOXMLFlashClientName", @"TFTUIOXMLFlashClientName"), peerName],
						  kToucheTrackingReceiverInfoHumanReadableName,
						  versionString,
						  kToucheTrackingReceiverInfoVersion,
						  [NSImage imageNamed:@"flash-image"],
						  kToucheTrackingReceiverInfoIcon,
						  nil];
	}
	
	return self;
}

- (void)dealloc
{	
	[_socketThread release];
	_socketThread = nil;

	[_socket release];
	_socket = nil;
	
	[super dealloc];
}

- (void)receiverShouldQuit
{
	[_socketThread cancel];
	[_socketThread release];
	_socketThread = nil;
	
	_socket.delegate = nil;
	[_socket close];
	[_socket release];
	_socket = nil;
	
	if (!_connectionDidDie)
		[(TFFlashXMLTUIOTrackingDataDistributor*)self.owningDistributor disconnectTUIOReceiver:self
																			  connectionDidDie:NO];
}

// trackingData is an NSString which represents the XML fragment to send
- (void)consumeTrackingData:(id)trackingData
{
	if ([trackingData isKindOfClass:[NSString class]])
		[_socket writeString:(NSString*)trackingData encoding:NSUTF8StringEncoding];
}

- (void)_socketThreadFunc
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	TFIPStreamSocket* mySocket = [_socket retain];
	[mySocket scheduleOnRunLoop:[NSRunLoop currentRunLoop]];
	
	do {
		NSAutoreleasePool* innerPool = [[NSAutoreleasePool alloc] init];
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:SECONDS_IN_RUNLOOP]];
		[innerPool release];
	} while (![[NSThread currentThread] isCancelled]);	
	
	[mySocket close];
	[mySocket release];	
	[pool release];
}

#pragma mark -
#pragma mark TFSocket delegate

// we don't expect to receive any data, so we just throw it away
- (void)socket:(TFSocket*)socket dataIsAvailableWithLength:(NSUInteger)dataLength
{
	if (socket == _socket) {
		(void)[_socket readData];
	}
}

#pragma mark -
#pragma mark TFIPStreamSocket delegate

- (void)socketGotDisconnected:(TFIPStreamSocket*)socket
{
	if (socket == _socket && [self.owningDistributor isKindOfClass:[TFFlashXMLTUIOTrackingDataDistributor class]]) {
		_connectionDidDie = YES;
	
		[(TFFlashXMLTUIOTrackingDataDistributor*)self.owningDistributor disconnectTUIOReceiver:self
																			  connectionDidDie:YES];
	}
}

@end
