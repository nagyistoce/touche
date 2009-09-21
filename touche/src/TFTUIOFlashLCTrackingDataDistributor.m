//
//  TFTUIOFlashLCTrackingDataDistributor.m
//  Touché
//
//  Created by Georg Kaindl on 18/3/09.
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

#import "TFTUIOFlashLCTrackingDataDistributor.h"

#include <ctype.h>

#import <BBOSC/BBOSCBundle.h>

#import "TFFlashLCSHMEM.h"
#import "TFTUIOPacketCreation.h"
#import "TFTUIOFlashLCTrackingDataReceiver.h"


#define	DEFAULT_RECEIVER_CONNECTION_NAME	(@"_OscDataStream")
#define	DEFAULT_RECEIVER_METHOD_NAME		(@"receiveOscData")

#define NEW_RECEIVERS_POLL_INTERVAL			((NSTimeInterval)1.0)
#define	RECEIVERS_BUF_SIZE					(8192)

#if defined(WINDOWS)
#define NSStringToCString(str)	([(str) cString])
#else
#define NSStringToCString(str)	([(str) cStringUsingEncoding:NSASCIIStringEncoding])
#endif

// non-zero if yes, otherwise zero
int _TFTUIOFlashLCReceiverNameBelongsToConnection(const char* receiverName, const char* connectionName);

@interface TFTUIOFlashLCTrackingDataDistributor (PrivateMethods)
- (void)_disconnectLC;
- (void)_pollForNewReceivers;
@end

@implementation TFTUIOFlashLCTrackingDataDistributor

@synthesize receiverConnectionName, receiverMethodName;

- (id)init
{
	return [self initWithReceiverConnectionName:DEFAULT_RECEIVER_CONNECTION_NAME];
}

- (id)initWithReceiverConnectionName:(NSString*)aReceiverConnectionName
{
	return [self initWithReceiverConnectionName:aReceiverConnectionName
						  andReceiverMethodName:nil];
}

- (id)initWithReceiverConnectionName:(NSString*)aReceiverConnectionName
			   andReceiverMethodName:(NSString*)aReceiverMethodName
{
	if (nil != (self = [super init])) {
		if (nil == aReceiverConnectionName)
			aReceiverConnectionName = [NSString stringWithString:DEFAULT_RECEIVER_CONNECTION_NAME];
		if (nil == aReceiverMethodName)
			aReceiverMethodName = [NSString stringWithString:DEFAULT_RECEIVER_METHOD_NAME];
		
		receiverConnectionName = [aReceiverConnectionName copy];
		receiverMethodName = [aReceiverMethodName copy];		
	}
	
	return self;
}

- (void)setReceiverConnectionName:(NSString*)newName
{
	if (nil != newName && ![newName isEqualToString:self->receiverConnectionName]) {
		[self->receiverConnectionName release];
		self->receiverConnectionName = [newName retain];
		
		TFLCSChangeListenerName(_lcConnection, NSStringToCString(self->receiverConnectionName));		
	}
}

- (void)setReceiverMethodName:(NSString*)newName
{
	if (nil != newName && ![newName isEqualToString:self->receiverMethodName]) {
		[self->receiverMethodName release];
		self->receiverMethodName = [newName retain];
		
		TFLCSChangeListenerName(_lcConnection, NSStringToCString(self->receiverMethodName));		
	}
}

- (void)dealloc
{
	[self _disconnectLC];

	[receiverConnectionName release];
	receiverConnectionName = nil;
	
	[receiverMethodName release];
	receiverMethodName = nil;
	
	[_receiverPollingThread release];
	_receiverPollingThread = nil;
	
	[_receiverNames release];
	_receiverNames = nil;
	
	[super dealloc];
}

- (BOOL)startDistributorWithObject:(id)obj error:(NSError**)error
{	
	if (NULL == _lcConnection) {
#if defined(WINDOWS)
		_lcConnection = TFLCSConnect([receiverConnectionName cString],
									 [receiverMethodName cString],
#else
		_lcConnection = TFLCSConnect([receiverConnectionName cStringUsingEncoding:NSASCIIStringEncoding],
									 [receiverMethodName cStringUsingEncoding:NSASCIIStringEncoding],
#endif
									 NULL,
									 NULL);
	}
		
	// TODO: report a proper error.
	if (NULL == _lcConnection)
		return NO;
	
	if (nil == _receiverPollingThread) {
		_receiverPollingThread = [[NSThread alloc] initWithTarget:self
														 selector:@selector(_pollForNewReceivers)
														   object:nil];
		[_receiverPollingThread start];
	}
	
	if (nil == _receiverNames)
		_receiverNames = [[NSMutableArray alloc] init];
	
	return [super startDistributorWithObject:obj error:error];
}

- (void)stopDistributor
{
	[_receiverPollingThread cancel];
	[_receiverPollingThread release];
	_receiverPollingThread = nil;
	
	[_receiverNames release];
	_receiverNames = nil;
	
	[self _disconnectLC];
	
	@synchronized(_receivers) {
		for (TFTrackingDataReceiver* receiver in [_receivers allValues]) {
			[[receiver retain] autorelease];
			[_receivers removeObjectForKey:receiver.receiverID];
			
			if ([delegate respondsToSelector:@selector(trackingDataDistributor:receiverDidDisconnect:)])
				[delegate trackingDataDistributor:self receiverDidDisconnect:receiver];
		}
	}
	
	[super stopDistributor];
}

- (BOOL)canAskReceiversToQuit
{
	return NO;
}

- (void)distributeTUIODataWithLivingTouches:(NSArray*)livingTouches
							   movedTouches:(NSArray*)movedTouches
								frameNumber:(NSUInteger)frameNumber
{
	BBOSCBundle* tuioBundles[TFTUIOVersionCount];
	memset(tuioBundles, 0, sizeof(BBOSCBundle*)*TFTUIOVersionCount);
	
	@synchronized (_receivers) {
		for (TFTUIOFlashLCTrackingDataReceiver* receiver in [_receivers allValues]) {
			TFTUIOVersion version = receiver.tuioVersion;
			if (nil == tuioBundles[version])
				tuioBundles[version] = TFTUIOPCBundleWithDataForTUIOVersion(version,
																			frameNumber,
																			livingTouches,
																			movedTouches);
			
			[receiver consumeTrackingData:tuioBundles[version]];
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

- (void)_pollForNewReceivers
{
	char buf[RECEIVERS_BUF_SIZE];
	NSAutoreleasePool* outerPool = [[NSAutoreleasePool alloc] init];
	
	while (![[NSThread currentThread] isCancelled]) {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
		int numConnections = TFLCSGetConnectedConnectionNames(_lcConnection, buf, 8192);
				
		NSMutableArray* stillExistingConnectionNames = [NSMutableArray array];
		if (numConnections > 0) {
			int i=0;
			char* p = &buf[0];
			const char* recName = [receiverConnectionName cStringUsingEncoding:NSASCIIStringEncoding];
			
			for (i; (char)0 != *p && i < numConnections; i++) {
				if (_TFTUIOFlashLCReceiverNameBelongsToConnection(recName, p)) {
#if defined(WINDOWS)
					NSString* connectionName = [NSString stringWithCString:p];
#else
					NSString* connectionName = [NSString stringWithCString:p encoding:NSASCIIStringEncoding];
#endif
					
					[stillExistingConnectionNames addObject:connectionName];
					
					BOOL alreadyKnown = NO;
					@synchronized(_receiverNames) {
						alreadyKnown = [_receiverNames containsObject:connectionName];
					}
					
					if (alreadyKnown)
						continue;
					
					[_receiverNames addObject:connectionName];
					
					TFTUIOFlashLCTrackingDataReceiver* receiver =
						[[TFTUIOFlashLCTrackingDataReceiver alloc] initWithConnectionName:connectionName
																			andMethodName:receiverMethodName];
					
					if (nil == [_receivers objectForKey:receiver.receiverID] && nil != receiver) {
						receiver.owningDistributor = self;
						receiver.tuioVersion = self.defaultTuioVersion;
						
						@synchronized (_receivers) {
							[_receivers setObject:receiver forKey:receiver.receiverID];
						}
												
						if ([delegate respondsToSelector:@selector(trackingDataDistributor:receiverDidConnect:)])
							[delegate trackingDataDistributor:self receiverDidConnect:receiver];
					}
					
					[receiver release];
				}
				
				p += strlen(p) + 1;
			}
		}
		
		@synchronized(_receiverNames) {
			for (NSString* connectionName in [[_receiverNames copy] autorelease]) {
				if (![stillExistingConnectionNames containsObject:connectionName]) {
					@synchronized (_receivers) {
						NSString* clientKey = [NSString stringWithFormat:TFTUIOFlashLCTrackingDataReceiverIDFormat,
																			connectionName];
																			
						TFTUIOFlashLCTrackingDataReceiver* client = [_receivers objectForKey:clientKey];
					
						if (nil != client && self == client.owningDistributor) {
							[[client retain] autorelease];
							[_receivers removeObjectForKey:client.receiverID];
							
							if ([delegate respondsToSelector:@selector(trackingDataDistributor:receiverDidDisconnect:)])
								[delegate trackingDataDistributor:self receiverDidDisconnect:client];
						}
					}
				
					[_receiverNames removeObject:connectionName];
				}
			}
		}
	
		[NSThread sleepForTimeInterval:NEW_RECEIVERS_POLL_INTERVAL];
		
		[pool release];
	}
	
	[outerPool release];
}

@end

int _TFTUIOFlashLCReceiverNameBelongsToConnection(const char* receiverName, const char* connectionName)
{
	int rv = 0;
	int recLen = strlen(receiverName);
	if (0 == strncmp(receiverName, connectionName, recLen)) {
		if (recLen < strlen(connectionName)) {
			const char* p = connectionName + recLen;
			
			while (*p != (char)0) {
				if (!isdigit((int)*p))
					goto done;
				p++;
			}
		}
		
		rv = 1;
	}

done:	
	return rv;
}
