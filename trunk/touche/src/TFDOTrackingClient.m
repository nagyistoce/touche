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
//

#import "TFDOTrackingClient.h"

#import "TFIncludes.h"
#import "NSScreen+Extras.h"
#import "TFTrackingDataReceiver.h"

#define SERVER_REQUEST_TIMEOUT			((NSTimeInterval)3.0)

@interface TFDOTrackingClient (PrivateMethods)
- (void)_connectionDidDie;
@end

@implementation TFDOTrackingClient

@synthesize delegate, connected;

- (void)dealloc
{
	[self disconnect];
	connected = NO;
	
	[super dealloc];
}

- (id)init
{
	if (!(self = [super init])) {
		[self release];
		return nil;
	}
		
	return self;
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
	
	[[_server connectionForProxy] setRequestTimeout:SERVER_REQUEST_TIMEOUT];
	[_server setProtocolForProxy:@protocol(TFDOTrackingServerProtocol)];
	
	if (![_server registerClient:self withName:clientName error:error]) {
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
	[_server release];
	_server = nil;
	
	[_clientName release];
	_clientName = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	connected = NO;
}

- (void)_connectionDidDie:(NSNotification*)notification
{
	if (!self.isConnected)
		return;

	[_server release];
	_server = nil;
	connected = NO;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	if ([delegate respondsToSelector:@selector(serverConnectionHasDiedForClient:)])
		[delegate serverConnectionHasDiedForClient:self];
}

- (bycopy NSDictionary*)clientInfo
{
	NSDictionary* dict = nil;
	if ([delegate respondsToSelector:@selector(infoDictionaryForClient:)])
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

	if ([delegate respondsToSelector:@selector(clientShouldQuitByServerRequest:)])
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

- (oneway void)touchesBegan:(bycopy in NSSet*)touches
{
	if ([delegate respondsToSelector:@selector(touchesDidBegin:viaClient:)])
		[delegate touchesDidBegin:touches viaClient:self];
}

- (oneway void)touchesUpdated:(bycopy in NSSet*)touches
{
	if ([delegate respondsToSelector:@selector(touchesDidUpdate:viaClient:)])
		[delegate touchesDidUpdate:touches viaClient:self];
}

- (oneway void)touchesEnded:(bycopy in NSSet*)touches
{
	if ([delegate respondsToSelector:@selector(touchesDidEnd:viaClient:)])
		[delegate touchesDidEnd:touches viaClient:self];
}

- (BOOL)isAlive
{
	return YES;
}

- (oneway void)disconnectedByServerWithError:(bycopy in NSError*)error
{
	if ([delegate respondsToSelector:@selector(client:didGetDisconnectedWithError:)])
		[delegate client:self didGetDisconnectedWithError:error];
}

@end
