//
//  TFFlashXMLTUIOServer.m
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

#import "TFFlashXMLTUIOServer.h"

#import "TFError.h"
#import "TFLocalization.h"
#import "TFIPTCPSocket.h"


#define	SECONDS_IN_RUNLOOP	((NSTimeInterval)5.0)

@interface TFFlashXMLTUIOServer (PrivateMethods)
- (void)_socketThreadFunc;
@end

@implementation TFFlashXMLTUIOServer

@synthesize delegate;

+ (void)initialize
{
	[TFSocket ignoreBrokenPipes];
}

- (id)init
{
	[self release];
	
	return nil;
}

- (id)initWithPort:(UInt16)port andLocalAddress:(NSString*)localAddress error:(NSError**)error
{
	if (nil != (self = [super init])) {
		_socket = [[TFIPTCPSocket alloc] init];
		
		if (![_socket listenAt:localAddress onPort:port]) {
			if (NULL != error)
				*error = [NSError errorWithDomain:TFErrorDomain
											 code:TFErrorCouldNotCreateTUIOXMLFlashServer
										 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
												   [NSString stringWithFormat:TFLocalizedString(@"TFTUIOXMLFlashServerListenSocketErrorDescription",
																								@"TFTUIOXMLFlashServerListenSocketErrorDescription"),
																									(nil != localAddress) ? localAddress : TFLocalizedString(@"TFTUIOXMLFlashServerAnyAddressName",
																																							 @"TFTUIOXMLFlashServerAnyAddressName"),
																									port],
												   NSLocalizedDescriptionKey,
												   nil]];
			
			[self release];
			return nil;
		}
		
		_socket.delegate = self;
		
		_socketThread = [[NSThread alloc] initWithTarget:self
												selector:@selector(_socketThreadFunc)
												  object:nil];
		
		[_socketThread start];
	}
	
	return self;
}

- (void)dealloc
{
	[_socket release];
	_socket = nil;
	
	[_socketThread release];
	_socketThread = nil;
	
	[super dealloc];
}

- (void)invalidate
{
	[_socketThread cancel];
	[_socketThread release];
	_socketThread = nil;
	
	if (nil != _socket) {
		@synchronized (_socket) {
			[_socket close];
			[_socket autorelease];
			_socket = nil;
		}
	}
}

- (NSString*)sockHost
{
	return [_socket sockHostString];
}

- (UInt16)sockPort
{
	return [_socket sockPort];
}

- (void)_socketThreadFunc
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	TFIPTCPSocket* mySocket = [_socket retain];
	[mySocket scheduleOnRunLoop:[NSRunLoop currentRunLoop]];
	
	do {
		NSAutoreleasePool* innerPool = [[NSAutoreleasePool alloc] init];
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:SECONDS_IN_RUNLOOP]];
		[innerPool release];
	} while (![[NSThread currentThread] isCancelled]);	
	
	[mySocket release];	
	[pool release];
}

#pragma mark -
#pragma mark TFIPStreamSocket delegate

- (void)socket:(TFIPStreamSocket*)socket didAcceptConnectionWithSocket:(TFIPStreamSocket*)connectionSocket
{
	if ([delegate respondsToSelector:@selector(flashXmlTuioServerDidAcceptConnectionWithSocket:)])
		[delegate flashXmlTuioServerDidAcceptConnectionWithSocket:connectionSocket];
}

@end
