//
//  TFTrackingClientHandlingController.m
//  Touché
//
//  Created by Georg Kaindl on 24/3/08.
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
//

#import "TFTrackingClientHandlingController.h"

#import "TFIncludes.h"
#import "TFTrackingServer.h"
#import "TFTrackingClient.h"
#import "TFServerTouchQueue.h"
#import "TFTrackingCommProtocols.h"

@implementation TFTrackingClientHandlingController

@synthesize client;
@synthesize isRunning;

- (id)init
{
	[self release];
	
	return nil;
}

- (void)dealloc
{
	if (isRunning) {
		NSError* error =
			[NSError errorWithDomain:TFErrorDomain
								code:TFErrorClientUnexpectedlyDisconnected
							userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
									  TFLocalizedString(@"TFClientUnexpectedlyDisconnectedErrorDesc", @"TFClientUnexpectedlyDisconnectedErrorDesc"),
										NSLocalizedDescriptionKey,
									  TFLocalizedString(@"TFClientUnexpectedlyDisconnectedErrorReason", @"TFClientUnexpectedlyDisconnectedErrorReason"),
										NSLocalizedFailureReasonErrorKey,
									  TFLocalizedString(@"TFClientUnexpectedlyDisconnectedErrorRecovery", @"TFClientUnexpectedlyDisconnectedErrorRecovery"),
										NSLocalizedRecoverySuggestionErrorKey,
									  [NSNumber numberWithInteger:NSUTF8StringEncoding],
										NSStringEncodingErrorKey,
									  nil]];

		[self disconnectWithError:error];
	}

	[_thread release];
	[_queue release];

	[client release];
	
	[super dealloc];
}

- (id)initWithClient:(TFTrackingClient*)theClient
{
	if (!(self = [super init])) {
		[self release];
		
		return nil;
	}
	
	_queue = [[TFServerTouchQueue alloc] init];
	_thread = [[NSThread alloc] initWithTarget:self
									  selector:@selector(forwardTouchesInThread)
										object:nil];
	client = [theClient retain];
	
	[_thread start];
	
	isRunning = YES;
	
	return self;
}

- (void)stop
{
	[_thread cancel];
	
	// enqueue a dummy object to wake the thread if necessary
	[self queueTouchesForForwarding:[NSDictionary dictionary]];
	
	isRunning = NO;
}

- (void)disconnectWithError:(NSError*)error
{
	if (isRunning)
		[client disconnectedByServerWithError:error];
	
	[self stop];
}

- (void)tellClientToQuit
{
	[client clientShouldQuit];
}

- (void)queueTouchesForForwarding:(NSDictionary*)touches
{
	// we do not add new objects to the queue if the client is slow in consuming them and still has more than 3
	// updates to consume. This way, we can avoid blocking when the mach queue between client and server gets full...
	if (isRunning && [_queue queueLength] < 6 && nil != touches) {
		[_queue queue:touches];
	}
}

- (void)forwardTouchesInThread
{
	NSAutoreleasePool* threadPool = [[NSAutoreleasePool alloc] init];
	NSDictionary *touches = nil;
	
	while (1) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
		touches = (NSDictionary*)[_queue dequeue];
		
		if ([_thread isCancelled]) {
			[pool release];
			break;
		}
		
		NSArray* arr = (NSArray*)[touches objectForKey:kEndedTouchesTrackingClientHandling];
		if (nil != arr)
			[client touchesEnded:[NSSet setWithArray:arr]];
		
		arr = (NSArray*)[touches objectForKey:kNewTouchesTrackingClientHandling];
		if (nil != arr)
			[client touchesBegan:[NSSet setWithArray:arr]];
		
		arr = (NSArray*)[touches objectForKey:kUpdatedTouchesTrackingClientHandling];
		if (nil != arr)
			[client touchesUpdated:[NSSet setWithArray:arr]];
		
		[pool release];
	}
	
	[threadPool release];
}

@end
