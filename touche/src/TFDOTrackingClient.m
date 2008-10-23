//
//  TFDOTrackingClient.m
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

#import "TFDOTrackingClient.h"

#import "TFIncludes.h"
#import "NSScreen+Extras.h"
#import "TFTrackingDataReceiver.h"

#define RESTART_AFTER_DROPPED_TOUCHES_THRESH		(5)
#define SERVER_REQUEST_TIMEOUT						((NSTimeInterval)3.0)

@interface TFDOTrackingClient (PrivateMethods)
- (void)_connectionDidDie;
- (void)_distributeBeginningTouches:(NSSet*)beginningTouches
					 updatedTouches:(NSSet*)updatedTouches
					   endedTouches:(NSSet*)endedTouches;
@end

@implementation TFDOTrackingClient

@synthesize delegate, connected;

- (void)dealloc
{
	[self disconnect];
	connected = NO;
	
	[_orderingQueue release];
	_orderingQueue = nil;
	
	[super dealloc];
}

- (id)init
{
	if (!(self = [super init])) {
		[self release];
		return nil;
	}
	
	_expectedSequenceNumber = 0;
	_orderingQueue = [[NSMutableDictionary alloc] init];
		
	return self;
}

- (void)setDelegate:(id)newDelegate
{
	delegate = newDelegate;
	
	_delegateCapabilities.hasDidGetDisconnected =
		[delegate respondsToSelector:@selector(client:didGetDisconnectedWithError:)];
	
	_delegateCapabilities.hasInfoDictionary =
		[delegate respondsToSelector:@selector(infoDictionaryForClient:)];
	
	_delegateCapabilities.hasServerConnectionDied =
		[delegate respondsToSelector:@selector(serverConnectionHasDiedForClient:)];
	
	_delegateCapabilities.hasShouldQuitByServerRequest =
		[delegate respondsToSelector:@selector(clientShouldQuitByServerRequest:)];
	
	_delegateCapabilities.hasTouchesDidBegin =
		[delegate respondsToSelector:@selector(touchesDidBegin:viaClient:)];
	
	_delegateCapabilities.hasTouchesDidUpdate =
		[delegate respondsToSelector:@selector(touchesDidUpdate:viaClient:)];
	
	_delegateCapabilities.hasTouchesDidEnd =
		[delegate respondsToSelector:@selector(touchesDidEnd:viaClient:)];
}

- (BOOL)connectWithName:(NSString*)clientName
{
	return [self connectWithName:clientName error:nil];
}

- (BOOL)connectWithName:(NSString*)clientName error:(NSError**)error
{
	return [self connectWithName:clientName
					 serviceName:nil
						  server:nil
						   error:error];
}

- (BOOL)connectWithName:(NSString*)clientName serviceName:(NSString*)serviceName server:(NSString*)serverName error:(NSError**)error
{
	if (self.isConnected) {
		[self disconnect];
	}
	
	_expectedSequenceNumber = 0;
	[_orderingQueue removeAllObjects];
	
	if (nil != _clientName)
		[_clientName release];
	
	_clientName = [clientName retain];
	
	if (nil == serviceName)
		serviceName = [NSString stringWithString:DEFAULT_SERVICE_NAME];

	_server = [NSConnection rootProxyForConnectionWithRegisteredName:serviceName
																host:serverName];
	
	if (nil == _server) {
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorClientServerConnectionRefused
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFClientServerConnectionRefusedErrorDesc", @"TFClientServerConnectionRefusedErrorDesc"),
												NSLocalizedDescriptionKey,
											   TFLocalizedString(@"TFClientServerConnectionRefusedErrorReason", @"TFClientServerConnectionRefusedErrorReason"),
												NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFClientServerConnectionRefusedErrorRecovery", @"TFClientServerConnectionRefusedErrorRecovery"),
												NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
												NSStringEncodingErrorKey,
											   nil]];
		
		return NO;
	}
	
	NSConnection* connection = [_server connectionForProxy];
	[connection setRequestTimeout:SERVER_REQUEST_TIMEOUT];
	[connection setReplyTimeout:SERVER_REQUEST_TIMEOUT];
	[connection runInNewThread];
	[connection removeRunLoop:[NSRunLoop currentRunLoop]];
	
	[_server setProtocolForProxy:@protocol(TFDOTrackingServerProtocol)];
	
	if (![_server registerClient:self withName:clientName error:error]) {
		[connection invalidate];
		[_server release];
		_server = nil;
		
		return NO;
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(_connectionDidDie:)
												 name:NSConnectionDidDieNotification
											   object:[_server connectionForProxy]];
	
	connected = YES;
	
	return YES;
}

- (void)disconnect
{
	if (!self.isConnected)
		return;
		
	[_server unregisterClientWithName:_clientName];
	
	[[_server connectionForProxy] invalidate];
	
	[_server release];
	_server = nil;
	
	[_clientName release];
	_clientName = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	connected = NO;
	
	_expectedSequenceNumber = 0;
	[_orderingQueue removeAllObjects];
}

- (void)_connectionDidDie:(NSNotification*)notification
{
	if (!self.isConnected)
		return;

	[_server release];
	_server = nil;
	connected = NO;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	if (_delegateCapabilities.hasServerConnectionDied)
		[delegate serverConnectionHasDiedForClient:self];
}

- (bycopy NSDictionary*)clientInfo
{
	NSDictionary* dict = nil;
	if (_delegateCapabilities.hasInfoDictionary)
		dict = [delegate infoDictionaryForClient:self];
	
	NSMutableDictionary* infoDict = (nil != dict) ? [NSMutableDictionary dictionaryWithDictionary:dict] :
													[NSMutableDictionary dictionaryWithCapacity:4];
	
	if (nil == [infoDict objectForKey:kToucheTrackingReceiverInfoHumanReadableName])
		[infoDict setObject:[NSString stringWithString:_clientName] forKey:kToucheTrackingReceiverInfoHumanReadableName];
	if (nil == [infoDict objectForKey:kToucheTrackingReceiverInfoVersion]) {
		NSString* versionString = nil;
		
		if (nil != delegate) {
			 NSBundle* bundle = [NSBundle bundleForClass:[delegate class]];
			 
			 NSString* bundleVer = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
			 NSString* shortVerStr = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
			 
			 versionString = (nil == shortVerStr) ? bundleVer : shortVerStr;
		}
		
		if (nil == versionString)
			versionString = [NSString stringWithString:TFLocalizedString(@"unknown", @"unknown")];
		
		[infoDict setObject:versionString forKey:kToucheTrackingReceiverInfoVersion];
	}
	if (nil == [infoDict objectForKey:kToucheTrackingReceiverInfoIcon]) {
		NSString* appBundlePath = [[NSBundle bundleForClass:[delegate class]] bundlePath];
		NSImage* appIcon = [[NSWorkspace sharedWorkspace] iconForFile:appBundlePath];
		if (nil != appIcon)
			[infoDict setObject:appIcon forKey:kToucheTrackingReceiverInfoIcon];
	}
	
	[infoDict setObject:[NSString stringWithString:_clientName] forKey:kToucheTrackingReceiverInfoName];

	return [NSDictionary dictionaryWithDictionary:infoDict];
}

- (oneway void)clientShouldQuit
{
	BOOL shouldQuit = YES;

	if (_delegateCapabilities.hasShouldQuitByServerRequest)
		shouldQuit = [delegate clientShouldQuitByServerRequest:self];

	if (shouldQuit) {
		[self disconnect];
		[[NSApplication sharedApplication] terminate:nil];
	}
}

- (NSScreen*)screen
{
	NSScreen* scr =  [NSScreen screenWithDisplayID:[_server screenId]];
	
	if (nil == scr)
		scr = [NSScreen mainScreen];
	
	return scr;
}

- (CGFloat)screenPixelsPerCentimeter
{
	return [_server screenPixelsPerCentimeter];
}

- (CGFloat)screenPixelsPerInch
{
	return [_server screenPixelsPerInch];
}

- (oneway void)deliverBeginningTouches:(bycopy in NSArray*)beginningTouches
						updatedTouches:(bycopy in NSArray*)updatedTouches
						  endedTouches:(bycopy in NSArray*)endedTouches
						sequenceNumber:(UInt64)sequenceNumber

{
	@synchronized(_server) {
		if (_expectedSequenceNumber > sequenceNumber)
			return;	// drop old duplicates
		else if (_expectedSequenceNumber < sequenceNumber &&
				 (sequenceNumber - _expectedSequenceNumber) < RESTART_AFTER_DROPPED_TOUCHES_THRESH) {
			NSArray* el = [NSArray arrayWithObjects:
						   (nil != beginningTouches ? [NSSet setWithArray:beginningTouches] : [NSNull null]),
						   (nil != updatedTouches ? [NSSet setWithArray:updatedTouches] : [NSNull null]),
						   (nil != endedTouches ? [NSSet setWithArray:endedTouches] : [NSNull null]),
						   nil];
		
			[_orderingQueue setObject:el forKey:[NSNumber numberWithUnsignedLongLong:sequenceNumber]];			
		} else {
			if (sequenceNumber != _expectedSequenceNumber) {
				// apparently, a message was dropped and not just delivered late. we handle this by delivering
				// all queued messages in order and then continuing as normal
				
				if ([_orderingQueue count] > 0) {
					NSArray* sortedSequenceNumbers =
						[[_orderingQueue allKeys] sortedArrayUsingSelector:@selector(compare:)];
					
					for (NSNumber* queuedSeqNum in sortedSequenceNumbers) {
						if ([queuedSeqNum longLongValue] < sequenceNumber) {
							NSArray* el = [[[_orderingQueue objectForKey:queuedSeqNum] retain] autorelease];
							
							[self _distributeBeginningTouches:[el objectAtIndex:0]
											   updatedTouches:[el objectAtIndex:1]
												 endedTouches:[el objectAtIndex:2]];
							
							[_orderingQueue removeObjectForKey:queuedSeqNum];
						}
					}
				}
				
				_expectedSequenceNumber = sequenceNumber;
			}
		
			[self _distributeBeginningTouches:(nil != beginningTouches ? [NSSet setWithArray:beginningTouches] : nil)
							   updatedTouches:(nil != updatedTouches ? [NSSet setWithArray:updatedTouches] : nil)
								 endedTouches:(nil != endedTouches ? [NSSet setWithArray:endedTouches] : nil)];
			
			_expectedSequenceNumber++;
			
			while([_orderingQueue count] > 0) {
				NSNumber* key = [NSNumber numberWithUnsignedLongLong:_expectedSequenceNumber];
				NSArray* el = [[[_orderingQueue objectForKey:key] retain] autorelease];
				
				if (nil == el)
					break;
								
				[self _distributeBeginningTouches:[el objectAtIndex:0]
								   updatedTouches:[el objectAtIndex:1]
									 endedTouches:[el objectAtIndex:2]];
				
				[_orderingQueue removeObjectForKey:key];
				
				_expectedSequenceNumber++;
			}
		}
	}
}

- (BOOL)isAlive
{
	return YES;
}

- (oneway void)disconnectedByServerWithError:(bycopy in NSError*)error
{
	if (_delegateCapabilities.hasDidGetDisconnected)
		[delegate client:self didGetDisconnectedWithError:error];
}

- (void)_distributeBeginningTouches:(NSSet*)beginningTouches
					 updatedTouches:(NSSet*)updatedTouches
					   endedTouches:(NSSet*)endedTouches
{
	@synchronized(self) {
		if (_delegateCapabilities.hasTouchesDidEnd && nil != endedTouches && [NSNull null] != (id)endedTouches)
			[delegate touchesDidEnd:endedTouches
						  viaClient:self];
		
		if (_delegateCapabilities.hasTouchesDidBegin && nil != beginningTouches  && [NSNull null] != (id)beginningTouches)
			[delegate touchesDidBegin:beginningTouches
							viaClient:self];
		
		if (_delegateCapabilities.hasTouchesDidUpdate && nil != updatedTouches  && [NSNull null] != (id)updatedTouches)
			[delegate touchesDidUpdate:updatedTouches
							 viaClient:self];
	}
}

@end
