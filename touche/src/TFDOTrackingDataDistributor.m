//
//  TFDOTrackingServer.m
//  Touché
//
//  Created by Georg Kaindl on 5/2/08.
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

#import "TFDOTrackingDataDistributor.h"

#import "TFIncludes.h"
#import "TFBlob.h"
#import "TFDOTrackingDataReceiver.h"
#import "TFScreenPreferencesController.h"
#import "TFDOTrackingClient.h"
#import "NSScreen+Extras.h"

#define HEARTBEAT_INTERVAL		((NSTimeInterval)10.0)
#define CLIENT_REQUEST_TIMEOUT	((NSTimeInterval)3.0)

@interface TFDOTrackingDataDistributor (PrivateMethods)
- (void)_cleanupClient:(NSString*)clientName;
- (void)_connectionDidDie:(NSNotification*)notification;
- (void)_pingClientsThread;
@end

@implementation TFDOTrackingDataDistributor

- (void)dealloc
{
	[self stopDistributor];
	
	[super dealloc];
}

- (id)init
{
	if (!(self = [super init])) {
		[self release];
		return nil;
	}
	
	_listenConnection = nil;
	_isRunning = NO;
	
	return self;
}

- (BOOL)startDistributorWithObject:(id)obj error:(NSError**)error
{
	if (_isRunning) {
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorServerIsAlreadyRunning
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFServerIsAlreadyRunningErrorDesc", @"TFServerIsAlreadyRunningErrorDesc"),
											   NSLocalizedDescriptionKey,
											   TFLocalizedString(@"TFServerIsAlreadyRunningErrorReason", @"TFServerIsAlreadyRunningErrorReason"),
											   NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFServerIsAlreadyRunningErrorRecovery", @"TFServerIsAlreadyRunningErrorRecovery"),
											   NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
											   NSStringEncodingErrorKey,
											   nil]];

		return NO;
	}
	
	NSString* serviceName;
	if (nil == obj || ![obj isKindOfClass:[NSString class]])
		serviceName = DEFAULT_SERVICE_NAME;
	else
		serviceName = (NSString*)obj;
	
	_listenConnection = [[NSConnection alloc] init];
	[_listenConnection setRootObject:self];
	[_listenConnection setDelegate:self];
	[_listenConnection enableMultipleThreads];
	
	if (![_listenConnection registerName:serviceName]) {
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorServerCouldNotRegisterItself
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFServerIsAlreadyRunningErrorDesc", @"TFServerIsAlreadyRunningErrorDesc"),
												NSLocalizedDescriptionKey,
											   TFLocalizedString(@"TFServerIsAlreadyRunningErrorReason", @"TFServerIsAlreadyRunningErrorReason"),
												NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFServerIsAlreadyRunningErrorRecovery", @"TFServerIsAlreadyRunningErrorRecovery"),
												NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
												NSStringEncodingErrorKey,
											   nil]];
		
		return NO;
	}
	
	_isRunning = YES;
	
	_receivers = [[NSMutableDictionary alloc] init];
	_heartbeatThread = [[NSThread alloc] initWithTarget:self
											   selector:@selector(_pingClientsThread)
												 object:nil];
	[_heartbeatThread start];
	
	return YES;
}

- (void)stopDistributor
{
	if (!_isRunning)
		return;

	[_heartbeatThread cancel];
	[_heartbeatThread release];
	_heartbeatThread = nil;
	
	[_listenConnection release];
	_listenConnection = nil;
	
	@synchronized (_receivers) {
		NSError* error = [NSError errorWithDomain:TFErrorDomain
											 code:TFErrorClientDisconnectedSinceServerWasStopped
										 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
												   TFLocalizedString(@"TFClientDisconnectedSinceServerWasStoppedErrorDesc", @"TFClientDisconnectedSinceServerWasStoppedErrorDesc"),
												   NSLocalizedDescriptionKey,
												   TFLocalizedString(@"TFClientDisconnectedSinceServerWasStoppedErrorReason", @"TFClientDisconnectedSinceServerWasStoppedErrorReason"),
												   NSLocalizedFailureReasonErrorKey,
												   TFLocalizedString(@"TFClientDisconnectedSinceServerWasStoppedErrorRecovery", @"TFClientDisconnectedSinceServerWasStoppedErrorRecovery"),
												   NSLocalizedRecoverySuggestionErrorKey,
												   [NSNumber numberWithInteger:NSUTF8StringEncoding],
												   NSStringEncodingErrorKey,
												   nil]];;
	
		for (NSString* name in _receivers)
			[(TFDOTrackingDataReceiver*)[_receivers objectForKey:name] disconnectWithError:error];
	
		[_receivers release];
		_receivers = nil;
	}
	
	_isRunning = NO;
}

- (BOOL)canAskReceiversToQuit
{
	return YES;
}

- (void)askReceiverToQuit:(TFTrackingDataReceiver*)receiver
{
	if (receiver.owningDistributor == self)
		[receiver receiverShouldQuit];
}

- (void)distributeTrackingDataDictionary:(NSDictionary*)trackingDict
{	
	@synchronized(_receivers) {
		for (TFDOTrackingDataReceiver* receiver in [_receivers allValues])
			[receiver consumeTrackingData:trackingDict];
	}
}

- (void)_connectionDidDie:(NSNotification*)notification
{
	NSConnection* deadCon = [notification object];
	
	NSString* deadName = nil;
	@synchronized(_receivers) {
		for (NSString* name in _receivers) {
			TFDOTrackingDataReceiver* receiver = [_receivers objectForKey:name];
			if ([[(id)receiver.client connectionForProxy] isEqual:deadCon]) {
				deadName = name;
				break;
			}
		}
	}
	
	if (nil != deadName) {
		[self _cleanupClient:deadName];
		
		if ([delegate respondsToSelector:@selector(clientDiedWithName:)])
			[delegate clientDiedWithName:deadName];
	}
}

- (void)_pingClientsThread
{
	NSAutoreleasePool* threadPool = [[NSAutoreleasePool alloc] init];

	while (![_heartbeatThread isCancelled]) {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
		NSMutableArray* deadNames = [NSMutableArray array];
		@synchronized(_receivers) {
			for (NSString* name in _receivers) {
				TFDOTrackingDataReceiver* receiver = [_receivers objectForKey:name];
				BOOL isAlive = NO;
				@try {
					isAlive = [receiver.client isAlive];
				}
				@catch (NSException * e) {
					isAlive = NO;
				}
				
				if (!isAlive)
					[deadNames addObject:name];
			}
		}
		
		for (NSString* name in deadNames) {
			[self _cleanupClient:name];
			
			if ([delegate respondsToSelector:@selector(clientDiedWithName:)])
				[delegate clientDiedWithName:name];
		}
		
		[NSThread sleepForTimeInterval:HEARTBEAT_INTERVAL];
		
		[pool release];
	}
	
	[threadPool release];
}

- (void)_cleanupClient:(NSString*)clientName
{
	@synchronized(_receivers) {
		TFDOTrackingDataReceiver* receiver =
			(TFDOTrackingDataReceiver*)[_receivers objectForKey:clientName];
		[receiver stop];
		
		[_receivers removeObjectForKey:clientName];
	}
}

#pragma mark -
#pragma mark Implementation of TFTrackingServerProtocol

- (BOOL)registerClient:(byref id)client withName:(bycopy NSString*)name error:(bycopy out NSError**)error
{
	if (NULL != error)
		*error = nil;

	name = [TFDOTrackingDataReceiver localNameForClientName:name];

	if (nil == client || nil == name) {
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorClientRegisteredWithInvalidArguments
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFClientRegisteredWithInvalidArgsErrorDesc", @"TFClientRegisteredWithInvalidArgsErrorDesc"),
												NSLocalizedDescriptionKey,
											   TFLocalizedString(@"TFClientRegisteredWithInvalidArgsErrorReason", @"TFClientRegisteredWithInvalidArgsErrorReason"),
												NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFClientRegisteredWithInvalidArgsErrorRecovery", @"TFClientRegisteredWithInvalidArgsErrorRecovery"),
												NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
											   NSStringEncodingErrorKey,
											   nil]];
	
		return NO;
	}

	if ([[_receivers allKeys] containsObject:name]) {
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorClientServerNameRegistrationFailed
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFClientServerNameRegistrationErrorDesc", @"TFClientServerNameRegistrationErrorDesc"),
											   NSLocalizedDescriptionKey,
											   [NSString stringWithFormat:TFLocalizedString(@"TFClientServerNameRegistrationErrorReason", @"TFClientServerNameRegistrationErrorReason"),
												name],
											   NSLocalizedFailureReasonErrorKey,
											   [NSString stringWithFormat:TFLocalizedString(@"TFClientServerNameRegistrationErrorRecovery", @"TFClientServerNameRegistrationErrorRecovery"),
												name],
											   NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
											   NSStringEncodingErrorKey,
											   nil]];

		return NO;
	}
	
	[client setProtocolForProxy:@protocol(TFDOTrackingClientProtocol)];
	[[client connectionForProxy] setRequestTimeout:CLIENT_REQUEST_TIMEOUT];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(_connectionDidDie:)
												 name:NSConnectionDidDieNotification
											   object:[client connectionForProxy]];
		
	TFDOTrackingDataReceiver* receiver =
			[[TFDOTrackingDataReceiver alloc] initWithClient:client];
	
	@synchronized(_receivers) {
		[_receivers setObject:receiver forKey:receiver.receiverID];
	}
	
	[receiver release];
	
	/* if ([delegate respondsToSelector:@selector(clientConnectedWithName:andInfoDictionary:)])
		[delegate clientConnectedWithName:name andInfoDictionary:infoDict]; */
		
	return YES;
}

- (void)unregisterClientWithName:(bycopy NSString*)name
{
	BOOL wasRemoved = NO;
	name = [TFDOTrackingDataReceiver localNameForClientName:name];
	
	@synchronized(_receivers) {
		if ([[_receivers allKeys] containsObject:name]) {
			[self _cleanupClient:name];
			wasRemoved = YES;
		}
	}
	
	if (wasRemoved && [delegate respondsToSelector:@selector(clientDisconnectedWithName:)])
		[delegate clientDisconnectedWithName:name];
}

- (CGDirectDisplayID)screenId
{
	return [[TFScreenPreferencesController screen] directDisplayID];
}

- (CGFloat)screenPixelsPerCentimeter
{
	return [TFScreenPreferencesController screenPixelsPerCentimeter];
}

- (CGFloat)screenPixelsPerInch
{
	return [TFScreenPreferencesController screenPixelsPerInch];
}

@end
