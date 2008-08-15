//
//  TFTrackingServer.m
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

#import "TFTrackingServer.h"

#import "TFIncludes.h"
#import "TFBlob.h"
#import "TFTrackingClientHandlingController.h"
#import "TFScreenPreferencesController.h"
#import "TFTrackingClient.h"
#import "NSScreen+Extras.h"

#define HEARTBEAT_INTERVAL		((NSTimeInterval)10.0)
#define CLIENT_REQUEST_TIMEOUT	((NSTimeInterval)3.0)

NSString* kNewTouchesTrackingClientHandling =		@"newTouches";
NSString* kUpdatedTouchesTrackingClientHandling =	@"updatedTouches";
NSString* kEndedTouchesTrackingClientHandling =		@"endedTouches";

@interface TFTrackingServer (NonPublicMethods)
- (void)_cleanupClient:(NSString*)clientName;
- (void)_connectionDidDie:(NSNotification*)notification;
- (NSDictionary*)_fetchDistantObjectsInClientInfoDict:(NSDictionary*)infoDictionary;
- (void)_pingClientsThread;
@end

@implementation TFTrackingServer

@synthesize delegate;

- (void)dealloc
{
	[self stopServer];
	
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

- (BOOL)startServer:(NSString*)serviceName error:(NSError**)error
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
	
	if (nil == serviceName)
		serviceName = DEFAULT_SERVICE_NAME;
	
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
	
	_clients = [[NSMutableDictionary alloc] init];
	_heartbeatThread = [[NSThread alloc] initWithTarget:self
											   selector:@selector(_pingClientsThread)
												 object:nil];
	[_heartbeatThread start];
	
	return YES;
}

- (void)stopServer
{
	if (!_isRunning)
		return;

	[_heartbeatThread cancel];
	[_heartbeatThread release];
	_heartbeatThread = nil;
	
	[_listenConnection release];
	_listenConnection = nil;
	
	@synchronized (_clients) {
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
	
		for (NSString* name in _clients)
			[(TFTrackingClientHandlingController*)[_clients objectForKey:name] disconnectWithError:error];
	
		[_clients release];
		_clients = nil;
	}
	
	_isRunning = NO;
}

- (void)askClientWithNameToQuit:(NSString*)clientName
{
	TFTrackingClientHandlingController* c = [_clients objectForKey:clientName];
	if (nil != c)
		[c tellClientToQuit];
}

- (void)_connectionDidDie:(NSNotification*)notification
{
	NSConnection* deadCon = [notification object];
	
	NSString* deadName = nil;
	@synchronized(_clients) {
		for (NSString* name in _clients) {
			TFTrackingClientHandlingController* controller = [_clients objectForKey:name];
			if ([[(id)controller.client connectionForProxy] isEqual:deadCon]) {
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
		@synchronized(_clients) {
			for (NSString* name in _clients) {
				TFTrackingClientHandlingController* controller = [_clients objectForKey:name];
				BOOL isAlive = NO;
				@try {
					isAlive = [controller.client isAlive];
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
	@synchronized(_clients) {
		TFTrackingClientHandlingController* controller =
			(TFTrackingClientHandlingController*)[_clients objectForKey:clientName];
		[controller stop];
		
		[_clients removeObjectForKey:clientName];
	}
}

- (NSDictionary*)_fetchDistantObjectsInClientInfoDict:(NSDictionary*)infoDictionary
{
	NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary:infoDictionary];
	
	// since NSImage appears not to support bycopy, we "fetch" it manually here by replacing
	// the NSDistantObject proxy to it with a copy based on its TIFFRepresentation
	NSImage* icon = [infoDictionary objectForKey:kToucheTrackingClientInfoIcon];
	if (nil != icon) {
		icon = [[NSImage alloc] initWithData:[icon TIFFRepresentation]];
		[dict setObject:icon forKey:kToucheTrackingClientInfoIcon];
		[icon release];
	}
	
	return [NSDictionary dictionaryWithDictionary:dict];
}

#pragma mark -
#pragma mark Implementation of TFTrackingServerProtocol

- (BOOL)registerClient:(byref id)client withName:(bycopy NSString*)name error:(bycopy out NSError**)error
{
	if (NULL != error)
		*error = nil;

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

	if ([[_clients allKeys] containsObject:name]) {
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
	
	[client setProtocolForProxy:@protocol(TFTrackingClientProtocol)];
	[[client connectionForProxy] setRequestTimeout:CLIENT_REQUEST_TIMEOUT];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(_connectionDidDie:)
												 name:NSConnectionDidDieNotification
											   object:[client connectionForProxy]];
		
	TFTrackingClientHandlingController* controller = [[TFTrackingClientHandlingController alloc] initWithClient:client];
	
	@synchronized(_clients) {
		[_clients setObject:controller forKey:name];
	}
	
	[controller release];
	
	NSDictionary* infoDict = [client clientInfo];
	infoDict = [self _fetchDistantObjectsInClientInfoDict:infoDict];
	
	if ([delegate respondsToSelector:@selector(clientConnectedWithName:andInfoDictionary:)])
		[delegate clientConnectedWithName:name andInfoDictionary:infoDict];
		
	return YES;
}

- (void)unregisterClientWithName:(bycopy NSString*)name
{
	BOOL wasRemoved = NO;
	
	@synchronized(_clients) {
		if ([[_clients allKeys] containsObject:name]) {
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

#pragma mark -
#pragma mark Delegate methods for TFTrackingPipeline

- (void)didFindBlobs:(NSArray*)blobs unmatchedBlobs:(NSArray*)unmatchedBlobs
{
	NSMutableDictionary* blobDict = [NSMutableDictionary dictionary];
	if (nil != unmatchedBlobs && [unmatchedBlobs count] > 0)
		[blobDict setObject:unmatchedBlobs forKey:kEndedTouchesTrackingClientHandling];
	
	NSMutableArray* newTouches = [NSMutableArray array];
	NSMutableArray* updatedTouches = [NSMutableArray array];
	
	for (TFBlob* blob in blobs) {
		if (blob.isUpdate)
			[updatedTouches addObject:blob];
		else
			[newTouches addObject:blob];
	}
	
	if ([newTouches count] > 0)
		[blobDict setObject:[NSArray arrayWithArray:newTouches] forKey:kNewTouchesTrackingClientHandling];
	
	if ([updatedTouches count] > 0)
		[blobDict setObject:[NSArray arrayWithArray:updatedTouches] forKey:kUpdatedTouchesTrackingClientHandling];
	
	NSDictionary* touches = [NSDictionary dictionaryWithDictionary:blobDict];
	
	@synchronized(_clients) {
		for (TFTrackingClientHandlingController* tchc in [_clients allValues])
			[tchc queueTouchesForForwarding:touches];
	}
}

@end
