//
//  TFBlobWiiRemoteInputSource.m
//  Touché
//
//  Created by Georg Kaindl on 29/4/08.
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

#import "TFBlobWiiRemoteInputSource.h"

#import <WiiRemote/WiiRemote.h>
#import <WiiRemote/WiiRemoteDiscovery.h>

#import "TFIncludes.h"
#import "TFThreadMessagingQueue.h"
#import "TFBlob.h"
#import "TFBlobPoint.h"
#import "TFBlobBox.h"
#import "TFBlobSize.h"

// keep this at 1.0f, unless you are just playing with it
#define FULLSIZE_TO_DRAWNSIZE_RATIO		(1.0f)

enum {
	TFBlobWiiRemoteInputSourceStateNotYetLoaded	= 0,
	TFBlobWiiRemoteInputSourceStateDiscovering	= 1,
	TFBlobWiiRemoteInputSourceStateConnecting	= 2,
	TFBlobWiiRemoteInputSourceStateConnected	= 3
};

@interface TFBlobWiiRemoteInputSource (NonPublicMethods)
- (NSImage*)_emptyFrameNSImage;
- (void)_startWiiRemoteDiscovery;
- (void)_freeResources;
- (BOOL)_shouldProcessThisFrame;
@end

@implementation TFBlobWiiRemoteInputSource

- (id)init
{
	if (!(self = [super init])) {
		[self release];
		return nil;
	}
	
	_currentBlobs = [[NSMutableArray alloc] init];
	_state = TFBlobWiiRemoteInputSourceStateNotYetLoaded;
	_isProcessing = NO;
	_didBecomeUnavailable = NO;
	_wasProcessingBeforeBecomingUnavailable = NO;
	_wiiDiscoveryStartRetval = kIOReturnSuccess;
	
	_emptyFrame = [[CIImage imageWithData:[[self _emptyFrameNSImage] TIFFRepresentation]] retain];
	
	return self;
}

- (void)dealloc
{
	delegate = nil;
	
	@synchronized(self) {
		[_wiiDiscovery setDelegate:nil];
		[_wiiRemote setDelegate:nil];
	}
	
	[self performSelectorOnMainThread:@selector(_freeResources)
						   withObject:nil
						waitUntilDone:YES];
	
	@synchronized (_currentBlobs) {
		[_currentBlobs release];
		_currentBlobs = nil;
	}
	
	[_emptyFrame release];
	_emptyFrame = nil;
	
	[super dealloc];
}

- (void)_freeResources
{
	[_wiiDiscovery setDelegate:nil];
	[_wiiDiscovery stop];
	[_wiiDiscovery close];
	[_wiiDiscovery release];
	_wiiDiscovery = nil;
	
	[_wiiRemote setDelegate:nil];
	[_wiiRemote closeConnection];
	[_wiiRemote release];
	_wiiRemote = nil;
}

- (void)_startWiiRemoteDiscovery
{
	_wiiDiscoveryStartRetval = [_wiiDiscovery start];
}

- (BOOL)loadWithConfiguration:(id)configuration error:(NSError**)error
{	
	if (NULL != error)
		*error = nil;

	@try {
		_wiiDiscovery = [[WiiRemoteDiscovery alloc] init];
	}
	@catch (NSException* e) {
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorWiiRemoteDiscoveryThrewException
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFErrorWiiRemoteDiscoveryThrewExceptionErrorDesc", @"TFErrorWiiRemoteDiscoveryThrewExceptionErrorDesc"),
											   NSLocalizedDescriptionKey,
											   [NSString stringWithFormat:TFLocalizedString(@"TFErrorWiiRemoteDiscoveryThrewExceptionErrorReason", @"TFErrorWiiRemoteDiscoveryThrewExceptionErrorReason"), [e reason]],
											   NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFErrorWiiRemoteDiscoveryThrewExceptionErrorRecovery", @"TFErrorWiiRemoteDiscoveryThrewExceptionErrorRecovery"),
											   NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
											   NSStringEncodingErrorKey,
											   nil]];
		
		return NO;
	}
	
	if (nil == _wiiDiscovery) {
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorWiiRemoteDiscoveryCreationFailed
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFWiiRemoteDiscoveryCreationErrorDesc", @"TFWiiRemoteDiscoveryCreationErrorDesc"),
												NSLocalizedDescriptionKey,
											   TFLocalizedString(@"TFWiiRemoteDiscoveryCreationErrorReason", @"TFWiiRemoteDiscoveryCreationErrorReason"),
												NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFWiiRemoteDiscoveryCreationErrorRecovery", @"TFWiiRemoteDiscoveryCreationErrorRecovery"),
												NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
												NSStringEncodingErrorKey,
											   nil]];
		
		return NO;
	}
	
	[_wiiDiscovery setDelegate:self];
	[self performSelectorOnMainThread:@selector(_startWiiRemoteDiscovery)
						   withObject:nil
						waitUntilDone:YES];
	
	if (_wiiDiscoveryStartRetval != kIOReturnSuccess) {
		[_wiiDiscovery setDelegate:nil];
		[_wiiDiscovery release];
		_wiiDiscovery = nil;
		
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorWiiRemoteDiscoveryStartupFailed
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFWiiRemoteDiscoveryStartupErrorDesc", @"TFWiiRemoteDiscoveryStartupErrorDesc"),
												NSLocalizedDescriptionKey,
											   [NSString stringWithFormat:TFLocalizedString(@"TFWiiRemoteDiscoveryStartupErrorReason", @"TFWiiRemoteDiscoveryStartupErrorReason"),
												_wiiDiscoveryStartRetval],
												NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFWiiRemoteDiscoveryStartupErrorRecovery", @"TFWiiRemoteDiscoveryStartupErrorRecovery"),
												NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
												NSStringEncodingErrorKey,
											   nil]];		
		return NO;
	}
	
	@synchronized(self) {
		_state = TFBlobWiiRemoteInputSourceStateDiscovering;
	}
	
	return YES;
}

- (BOOL)unloadWithError:(NSError**)error
{	
	BOOL success = [self stopProcessing:error];
	
	[self performSelectorOnMainThread:@selector(_freeResources)
						   withObject:nil
						waitUntilDone:YES];
	
	@synchronized(self) {
		_state = TFBlobWiiRemoteInputSourceStateNotYetLoaded;
	}
	
	return success;
}

- (BOOL)isReady:(NSString**)notReadyReason
{
	@synchronized(self) {
		BOOL isReady = (_state == TFBlobWiiRemoteInputSourceStateConnected);
		
		if (!isReady && NULL != notReadyReason) {
			switch (_state) {
				case TFBlobWiiRemoteInputSourceStateNotYetLoaded:
					*notReadyReason = [NSString stringWithString:
										TFLocalizedString(@"WiiRemoteNotYetInitialized",
														@"Wii Remote support has not been initialized yet. Please try again later!"
										)];
					break;
				case TFBlobWiiRemoteInputSourceStateDiscovering:
					*notReadyReason = [NSString stringWithString:
									   TFLocalizedString(@"WiiRemoteDiscovering",
														 @"Trying to discover a Wii Remote. Please hold down the 1 and 2 buttons simultaneously in order to have your Wii Remote be discovered!"
														 )];
					break;
				case TFBlobWiiRemoteInputSourceStateConnecting:
					*notReadyReason = [NSString stringWithString:
									   TFLocalizedString(@"WiiRemoteConnecting",
														 @"A connection with the Wii Remote is currently being establied. Please try again later!"
														 )];
					break;
				default:
					*notReadyReason = nil;
					break;
			}
		} else if (NULL != notReadyReason)
			*notReadyReason = nil;
		
		return isReady;
	}
	
	return NO; // shut up, compiler...
}

- (BOOL)isProcessing
{
	return _isProcessing;
}

- (BOOL)startProcessing:(NSError**)error
{
	NSString* errorReason;
	
	if ([self isProcessing])
		return YES;
	
	if ([self isReady:&errorReason]) {
		[_wiiRemote setIRSensorEnabled:YES];
		_isProcessing = [super startProcessing:error];
	}
	
	if (!_isProcessing && NULL != error)
		*error = [NSError errorWithDomain:TFErrorDomain
									 code:TFErrorWiiRemoteStartProcessingFailed
								 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
										   TFLocalizedString(@"TFWiiRemoteStartProcessingErrorDesc", @"TFWiiRemoteStartProcessingErrorDesc"),
											NSLocalizedDescriptionKey,
										   [NSString stringWithFormat:TFLocalizedString(@"TFWiiRemoteStartProcessingErrorReason", @"TFWiiRemoteStartProcessingErrorReason"),
											errorReason],
											NSLocalizedFailureReasonErrorKey,
										   TFLocalizedString(@"TFWiiRemoteStartProcessingErrorRecovery", @"TFWiiRemoteStartProcessingErrorRecovery"),
											NSLocalizedRecoverySuggestionErrorKey,
										   [NSNumber numberWithInteger:NSUTF8StringEncoding],
											NSStringEncodingErrorKey,
										   nil]];
	
	return _isProcessing;
}

- (BOOL)stopProcessing:(NSError**)error
{
	if (![self isProcessing])
		return YES;

	[_wiiRemote setIRSensorEnabled:NO];
	_isProcessing = NO;
	
	return [super stopProcessing:error];
}

- (CGSize)currentCaptureResolution
{
	return CGSizeMake(1024.0f, 768.0f);
}

- (BOOL)changeCaptureResolution:(CGSize)newSize error:(NSError**)error
{
	if (newSize.width == 1024.0f && newSize.height == 768.0f)
		return YES;

	if (NULL != error)
		*error = [NSError errorWithDomain:TFErrorDomain
									 code:TFErrorWiiRemoteResolutionChangeFailed
								 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
										   TFLocalizedString(@"TFWiiRemoteResolutionChangeErrorDesc", @"TFWiiRemoteResolutionChangeErrorDesc"),
											NSLocalizedDescriptionKey,
										   TFLocalizedString(@"TFWiiRemoteResolutionChangeErrorReason", @"TFWiiRemoteResolutionChangeErrorReason"),
											NSLocalizedFailureReasonErrorKey,
										   TFLocalizedString(@"TFWiiRemoteResolutionChangeErrorRecovery", @"TFWiiRemoteResolutionChangeErrorRecovery"),
											NSLocalizedRecoverySuggestionErrorKey,
										   [NSNumber numberWithInteger:NSUTF8StringEncoding],
											NSStringEncodingErrorKey,
										   nil]];

	return NO;
}

// The Wii remote doesn't support changing the resolution, but is fixed at 1024x768, we return NO for anything
// except that 
- (BOOL)supportsCaptureResolution:(CGSize)size
{
	if (size.width == 1024.0f && size.height == 768.0f)
		return YES;
	
	return NO;
}

- (CGColorSpaceRef)ciColorSpace
{
	return NULL;
}

- (CGColorSpaceRef)ciWorkingColorSpace
{
	return NULL;
}

- (NSImage*)_emptyFrameNSImage
{
	NSSize frameSize = NSSizeFromCGSize([self currentCaptureResolution]);
	NSSize drawnSize = NSMakeSize(frameSize.width/FULLSIZE_TO_DRAWNSIZE_RATIO,
								  frameSize.height/FULLSIZE_TO_DRAWNSIZE_RATIO);
	
	NSImage* frame = [[NSImage alloc] initWithSize:drawnSize];
	[frame lockFocus];
	[[NSColor colorWithCalibratedRed:.3f green:.3f blue:.3f alpha:1.0f] setFill];
	[NSBezierPath fillRect:NSMakeRect(0.0f, 0.0f, drawnSize.width, drawnSize.height)];
	[frame unlockFocus];
	
	return [frame autorelease];
}

- (BOOL)hasFilterStages
{
	return NO;
}

- (CIImage*)currentRawImageForStage:(NSInteger)filterStage
{	
	@synchronized (_currentBlobs) {
		if ([_currentBlobs count] <= 0)
			return _emptyFrame;
	}

	NSImage* frame = [self _emptyFrameNSImage];
	[frame lockFocus];
	
	[[NSColor whiteColor] setFill];
	@synchronized(_currentBlobs) {
		for (NSValue* val in _currentBlobs) {
			NSRect r = [val rectValue];
			r.origin.x /= FULLSIZE_TO_DRAWNSIZE_RATIO;
			r.origin.y /= FULLSIZE_TO_DRAWNSIZE_RATIO;
			r.size.width /= FULLSIZE_TO_DRAWNSIZE_RATIO;
			r.size.height /= FULLSIZE_TO_DRAWNSIZE_RATIO;
			[[NSBezierPath bezierPathWithOvalInRect:r] fill];
		}
	}
	
	[frame unlockFocus];
	
	return [CIImage imageWithData:[frame TIFFRepresentation]];
}

#pragma mark -
#pragma mark WiiRemoteDiscovery delegate

- (void)willStartWiimoteConnections
{
	@synchronized(self) {
		_state = TFBlobWiiRemoteInputSourceStateConnecting;
	}
}

- (void)WiiRemoteDiscovered:(WiiRemote*)wiimote
{
	[_wiiDiscovery performSelectorOnMainThread:@selector(stop) withObject:nil waitUntilDone:NO];
	[_wiiDiscovery setDelegate:nil];
	
	_wiiRemote = [wiimote retain];
	[_wiiRemote setDelegate:self];
	[_wiiRemote setLEDEnabled1:YES enabled2:NO enabled3:NO enabled4:NO];

	@synchronized(self) {
		_state = TFBlobWiiRemoteInputSourceStateConnected;
	}
	
	if (_didBecomeUnavailable) {
		_didBecomeUnavailable = NO;
		
		if (_wasProcessingBeforeBecomingUnavailable)
			[self startProcessing:NULL];
		
		if ([delegate respondsToSelector:@selector(blobInputSourceDidBecomeAvailableAgain:)])
			[delegate blobInputSourceDidBecomeAvailableAgain:self];
	} else {
		if ([delegate respondsToSelector:@selector(blobInputSourceDidBecomeReady:)])
			[delegate blobInputSourceDidBecomeReady:self];
	}
}

- (void)WiiRemoteDiscoveryError:(int)code
{
	NSError* error =  [NSError errorWithDomain:TFErrorDomain
										  code:TFErrorWiiRemoteDiscoveryFailed
									  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
												TFLocalizedString(@"TFWiiRemoteDiscoveryErrorDesc", @"TFWiiRemoteDiscoveryErrorDesc"),
													NSLocalizedDescriptionKey,
												[NSString stringWithFormat:TFLocalizedString(@"TFWiiRemoteDiscoveryErrorReason", @"TFWiiRemoteDiscoveryErrorReason"),
												 code],
													NSLocalizedFailureReasonErrorKey,
												TFLocalizedString(@"TFWiiRemoteDiscoveryErrorRecovery", @"TFWiiRemoteDiscoveryErrorRecovery"),
													NSLocalizedRecoverySuggestionErrorKey,
												[NSNumber numberWithInteger:NSUTF8StringEncoding],
													NSStringEncodingErrorKey,
												nil]];
	
	if ([delegate respondsToSelector:@selector(blobInputSource:willNotBecomeReadyWithError:)])
		[delegate blobInputSource:self willNotBecomeReadyWithError:error];
}

#pragma mark -
#pragma mark WiiRemote delegate

- (void)rawIRData:(IRData[4])irData
{
	if (![self _shouldProcessThisFrame])
		return;

	@synchronized(_currentBlobs) {
		[_currentBlobs removeAllObjects];
	}
	
	NSMutableArray* blobs = [NSMutableArray array];
	CGSize frameSize = [self currentCaptureResolution];
	
	int i = 0;
	for (i=0; i<4; i++) {
		if (0x0f != irData[i].s) {
			float estimatedSize = (16-irData[i].s)*3.5f;
					
			@synchronized(_currentBlobs) {
				[_currentBlobs addObject:
					[NSValue valueWithRect:NSMakeRect(irData[i].x - estimatedSize/2.0,
													  (frameSize.height - irData[i].y) - estimatedSize/2.0,
													  estimatedSize,
													  estimatedSize)]];
			}
			
			if (blobTrackingEnabled) {
				TFBlob* blob = [TFBlob blob];
				blob.center.x					= irData[i].x;
				blob.center.y					= irData[i].y;
				blob.boundingBox.origin.x		= irData[i].x - estimatedSize/2;
				blob.boundingBox.origin.y		= irData[i].y - estimatedSize/2;
				blob.boundingBox.size.width		= estimatedSize;
				blob.boundingBox.size.height	= estimatedSize;
				
				blob.edgeVertices = [NSArray arrayWithObjects:
									 [TFBlobPoint pointWithX:irData[i].x Y:(irData[i].y - estimatedSize/2)],
									 [TFBlobPoint pointWithX:(irData[i].x + estimatedSize/2) Y:irData[i].y],
									 [TFBlobPoint pointWithX:irData[i].x Y:(irData[i].y + estimatedSize/2)],
									 [TFBlobPoint pointWithX:(irData[i].x - estimatedSize/2) Y:irData[i].y],
									 nil];
			
				[blobs addObject:blob];
			}
		}
	}
	
	
	if (blobTrackingEnabled && _delegateHasDidDetectBlobs)
		[_deliveryQueue enqueue:blobs];
}

- (void)wiiRemoteDisconnected:(IOBluetoothDevice*)device
{
	@synchronized(self) {
		_wasProcessingBeforeBecomingUnavailable = _isProcessing;
		_didBecomeUnavailable = YES;

		if ([self isProcessing])
			[self stopProcessing:NULL];

		_state = TFBlobWiiRemoteInputSourceStateDiscovering;
		
		[_wiiRemote autorelease];
		_wiiRemote = nil;
		
		[self performSelectorOnMainThread:@selector(_startWiiRemoteDiscovery)
							   withObject:nil
							waitUntilDone:YES];
		[_wiiDiscovery setDelegate:self];
	}
	
	NSError* error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorWiiRemoteDisconnectedUnexpectedly
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFWiiRemoteDisconnectedErrorDesc", @"TFWiiRemoteDisconnectedErrorDesc"),
												NSLocalizedDescriptionKey,
											   TFLocalizedString(@"TFWiiRemoteDisconnectedErrorReason", @"TFWiiRemoteDisconnectedErrorReason"),
												NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFWiiRemoteDisconnectedErrorRecovery", @"TFWiiRemoteDisconnectedErrorRecovery"),
												NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
												NSStringEncodingErrorKey,
											   nil]];

	if ([delegate respondsToSelector:@selector(blobInputSource:didBecomeUnavailableWithError:)])
		[delegate blobInputSource:self didBecomeUnavailableWithError:error];
}

// we don't need those, but they aren't correctly wrapped into respondsToSelector in the framework, so it's here to prevent exceptions
- (void)accelerationChanged:(WiiAccelerationSensorType) type accX:(unsigned short) accX accY:(unsigned short) accY accZ:(unsigned short) accZ
{
}

- (void)buttonChanged:(WiiButtonType)type isPressed:(BOOL)isPressed
{
}

@end
