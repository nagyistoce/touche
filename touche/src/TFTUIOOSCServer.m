//
//  TFTUIOOSCServer.m
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

#import "TFTUIOOSCServer.h"

#import "TFIPUDPSocket.h"


#define SECONDS_IN_RUNLOOP		((NSTimeInterval)5.0)

@interface TFTUIOOSCServer (PrivateMethods)
- (void)_socketThreadFunc;
@end

@implementation TFTUIOOSCServer

// we override this, since we aren't actually supposed to listen on a well-defined port
- (id)initWithPort:(UInt16)port andLocalAddress:(NSString*)localAddress error:(NSError**)error
{
	if (nil != (self = [super initWithPort:0 andLocalAddress:nil error:error])) {
		[_socket release];
		_socket = [[TFIPUDPSocket alloc] init];
		
		if (![_socket open]) {
			// TODO: set error appropriately
			[_socket release];
			_socket = nil;
			
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

- (void)_socketThreadFunc
{	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	TFIPUDPSocket* mySocket = [_socket retain];
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
#pragma mark TFIPDatagramSocket delegate

- (void)socketHadReadWriteError:(TFIPDatagramSocket*)socket
{
	// TODO: report that there was an error, i.e. provide a sensible NSError object
	if ([delegate respondsToSelector:@selector(tuioOscServer:networkErrorDidOccur:)])
		[delegate tuioOscServer:self networkErrorDidOccur:nil];
}

@end
