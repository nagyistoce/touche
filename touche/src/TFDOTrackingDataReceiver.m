//
//  TFDOTrackingDataReceiver.m
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

#import "TFDOTrackingDataReceiver.h"

#import "TFIncludes.h"
#import "TFDOTrackingClient.h"
#import "TFTrackingDataDistributor.h"
#import "TFThreadMessagingQueue.h"
#import "TFDOTrackingCommProtocols.h"


@interface TFDOTrackingDataReceiver (PrivateMethods)
- (void)_forwardTouchesInThread;
- (NSDictionary*)_fetchDistantObjectsInInfoDict:(NSDictionary*)infoDict;
@end

@implementation TFDOTrackingDataReceiver

@synthesize client, running;

+ (NSString*)localNameForClientName:(NSString*)name
{
	return [name stringByAppendingString:@":DO"];
}

- (id)init
{
	[self release];
	
	return nil;
}

- (void)dealloc
{
	if (self.isRunning) {
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
	_thread = nil;
	
	[_queue release];
	_queue = nil;

	NSConnection* clientConnection = [(id)client connectionForProxy];
	[clientConnection invalidate];

	[client release];
	client = nil;
	
	[super dealloc];
}

- (id)initWithClient:(TFDOTrackingClient*)theClient
{
	if (!(self = [super init])) {
		[self release];
		
		return nil;
	}
	
	_queue = [[TFThreadMessagingQueue alloc] init];
	_thread = [[NSThread alloc] initWithTarget:self
									  selector:@selector(_forwardTouchesInThread)
										object:nil];
	client = [theClient retain];
	
	infoDictionary = [[self _fetchDistantObjectsInInfoDict:[client clientInfo]] retain];
	connected = YES;
	receiverID = [[[self class] localNameForClientName:[infoDictionary objectForKey:kToucheTrackingReceiverInfoName]]
					retain];
	
	[_thread start];
	
	NSConnection* connection = [(id)client connectionForProxy];
	[connection runInNewThread];
	[connection removeRunLoop:[NSRunLoop currentRunLoop]];
		
	running = YES;
	
	return self;
}

- (void)receiverShouldQuit
{
	[client clientShouldQuit];
}

- (void)consumeTrackingData:(id)trackingData
{
	// we do not add new objects to the queue if the client is slow in consuming them and still has more than 3
	// updates to consume. This way, we can avoid blocking when the mach queue between client and server gets full...
	if (self.isRunning && [_queue queueLength] < 6 && nil != trackingData) {
		[_queue enqueue:trackingData];
	}
}

- (void)stop
{
	[_thread cancel];
	
	// enqueue a dummy object to wake the thread if necessary
	[self consumeTrackingData:[NSDictionary dictionary]];
	
	running = NO;
}

- (void)disconnectWithError:(NSError*)error
{
	if (self.isRunning)
		[client disconnectedByServerWithError:error];
	
	[self stop];
}

- (void)_forwardTouchesInThread
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSDictionary *touches = nil;
	
	while (YES) {
		NSAutoreleasePool* innerPool = [[NSAutoreleasePool alloc] init];

		touches = (NSDictionary*)[_queue dequeue];
		
		if ([[NSThread currentThread] isCancelled]) {
			[innerPool release];
			[pool release];
			break;
		}
		
		NSArray* arr = (NSArray*)[touches objectForKey:kToucheTrackingDistributorDataEndedTouchesKey];
		if (nil != arr)
			[client touchesEnded:[NSSet setWithArray:arr]];
		
		arr = (NSArray*)[touches objectForKey:kToucheTrackingDistributorDataNewTouchesKey];
		if (nil != arr)
			[client touchesBegan:[NSSet setWithArray:arr]];
		
		arr = (NSArray*)[touches objectForKey:kToucheTrackingDistributorDataUpdatedTouchesKey];
		if (nil != arr)
			[client touchesUpdated:[NSSet setWithArray:arr]];
		
		[innerPool release];
	}
	
	[pool release];
}

- (NSDictionary*)_fetchDistantObjectsInInfoDict:(NSDictionary*)infoDict
{
	NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary:infoDict];
	
	// since NSImage appears not to support bycopy, we "fetch" it manually here by replacing
	// the NSDistantObject proxy to it with a copy based on its TIFFRepresentation
	NSImage* icon = [infoDict objectForKey:kToucheTrackingReceiverInfoIcon];
	if (nil != icon) {
		icon = [[NSImage alloc] initWithData:[icon TIFFRepresentation]];
		[dict setObject:icon forKey:kToucheTrackingReceiverInfoIcon];
		[icon release];
	}
	
	return [NSDictionary dictionaryWithDictionary:dict];
}

@end
