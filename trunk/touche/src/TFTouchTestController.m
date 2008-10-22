//
//  TFTouchTestController.m
//  Touché
//
//  Created by Georg Kaindl on 26/4/08.
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

#import "TFTouchTestController.h"

#import "TFIncludes.h"
#import "TFDOTrackingClient.h"
#import "TFTouchView.h"
#import "TFBlob.h"
#import "TFBlobLabel.h"
#import "TFBlobPoint.h"

#define TRACKINGCLIENT_NAME		(@"TFTouchTestController")
#define TOUCH_DOWN_VOLUME		(1.0f)
#define TOUCH_UP_VOLUME			(0.5f)

@interface TFTouchTestController (NonPublicMethods)
- (NSColor*)_claimFreeColorForBlobLabelNumber:(NSNumber*)labelNumber;
- (void)_cleanupBlobs;
- (void)_endTestByUserRequest;
- (void)_freeColorForBlobLabelNumber:(NSNumber*)labelNumber;
- (void)_stopTest;
@end

@implementation TFTouchTestController

@synthesize isRunning;
@synthesize delegate;

- (void)dealloc
{
	[_freeColors release];
	_freeColors = nil;
	
	[_touchesAndColors release];
	_touchesAndColors = nil;
	
	[super dealloc];
}

- (void)startTest
{
	if (isRunning)
		return;

	NSError* error;
	
	_trackingClient = [[TFDOTrackingClient alloc] init];
	_trackingClient.delegate = self;
	
	if (![_trackingClient connectWithName:TRACKINGCLIENT_NAME serviceName:nil server:nil error:&error]) {
		[_trackingClient release];
		_trackingClient = nil;
		
		if ([delegate respondsToSelector:@selector(touchTestController:failedWithError:)])
			[delegate touchTestController:self failedWithError:error];
		
		return;
	}
	
	_touchView.delegate = self;
	
	CGFloat screenSizePerCentimeter = [_trackingClient screenPixelsPerCentimeter];
	_touchView.touchSize = [NSValue valueWithSize:NSMakeSize(screenSizePerCentimeter*1.5,
															 screenSizePerCentimeter*1.5f)];
	
	isRunning = YES;
	
	srandomdev();
	
	if (nil == _freeColors) {
		_freeColors = [[NSMutableArray alloc] initWithObjects:
					   [NSColor colorWithCalibratedRed:.6f green:.6f blue:1.0f alpha:1.0f],
					   [NSColor colorWithCalibratedRed:.616f green:.831f blue:.961f alpha:1.0f],
					   [NSColor colorWithCalibratedRed:.996f green:0.0f blue:0.0f alpha:1.0f],
					   [NSColor colorWithCalibratedRed:.231f green:.863f blue:.568f alpha:1.0f],
					   [NSColor colorWithCalibratedRed:.886f green:.271f blue:1.0f alpha:1.0f],
					   [NSColor colorWithCalibratedRed:.98f green:.886f blue:.506f alpha:1.0f],
					   [NSColor colorWithCalibratedRed:0.0f green:.698f blue:0.0f alpha:1.0f],
					   [NSColor colorWithCalibratedRed:.902f green:1.0f blue:0.0f alpha:1.0f],
					   [NSColor colorWithCalibratedRed:.49f green:.659f blue:.329f alpha:1.0f],
					   [NSColor colorWithDeviceRed:1.0f green:0.0f blue:.808f alpha:1.0f],
					   [NSColor whiteColor],
					   [NSColor colorWithCalibratedRed:.7f green:.7f blue:.7f alpha:1.0],
					   nil];
	}
	
	if (nil == _touchesAndColors)
		_touchesAndColors = [[NSMutableDictionary alloc] init];
	
	self.hidesMouseCursor = ([[NSScreen screens] count] <= 1);;
	if (![self goFullscreenWithView:_touchView onScreen:[_trackingClient screen]]) {
		[self _stopTest];
	
		error = [NSError errorWithDomain:TFErrorDomain
									code:TFErrorCouldNotEnterFullscreen
								userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
										  TFLocalizedString(@"TFCouldNotEnterFullscreenErrorDesc", @"TFCouldNotEnterFullscreenErrorDesc"),
										  NSLocalizedDescriptionKey,
										  TFLocalizedString(@"TFCouldNotEnterFullscreenErrorReason", @"TFCouldNotEnterFullscreenErrorReason"),
										  NSLocalizedFailureReasonErrorKey,
										  TFLocalizedString(@"TFCouldNotEnterFullscreenErrorRecovery", @"TFCouldNotEnterFullscreenErrorRecovery"),
										  NSLocalizedRecoverySuggestionErrorKey,
										  [NSNumber numberWithInteger:NSUTF8StringEncoding],
										  NSStringEncodingErrorKey,
										  nil]];
		
		if ([delegate respondsToSelector:@selector(touchTestController:failedWithError:)])
			[delegate touchTestController:self failedWithError:error];
			
		return;
	}
	
	[_touchView showText:TFLocalizedString(@"TFTouchTestControllerStartInfo", @"TFTouchTestControllerStartInfo")
			  forSeconds:5.0];
}

- (void)_stopTest
{
	if (!isRunning)
		return;

	[self quitFullscreen];
	[self _cleanupBlobs];
	[_touchView clearText];
	
	[_trackingClient disconnect];
	_trackingClient.delegate = nil;
	[_trackingClient release];
	_trackingClient = nil;
	
	isRunning = NO;
}

- (NSColor*)_claimFreeColorForBlobLabelNumber:(NSNumber*)labelNumber
{	
	if ([_freeColors count] <= 0)
		return nil;
	
	NSInteger r = random()%[_freeColors count];
	NSColor* color = (NSColor*)[_freeColors objectAtIndex:r];
	
	[_touchesAndColors setObject:color forKey:labelNumber];
	[_freeColors removeObject:color];
	
	return color;
}

- (void)_freeColorForBlobLabelNumber:(NSNumber*)labelNumber
{
	NSColor* color = [_touchesAndColors objectForKey:labelNumber];
	if (nil != color) {
		[_freeColors addObject:color];
		[_touchesAndColors removeObjectForKey:labelNumber];
	}
}

- (void)_cleanupBlobs
{
	if (nil != _touchesAndColors) {
		NSArray* keys = [_touchesAndColors allKeys];
		for (id key in keys) {
			[_touchView removeTouchWithID:key];
			[self _freeColorForBlobLabelNumber:key];
		}
	}
}

- (void)_endTestByUserRequest
{
	if (isRunning) {
		[self _stopTest];
		
		if ([delegate respondsToSelector:@selector(touchTestEndedByUser:)])
			[delegate touchTestEndedByUser:self];
	}
}

#pragma mark -
#pragma mark Delegate methods for TFTouchView

- (void)keyWentDown:(NSString*)characters
{
	unichar c = [characters characterAtIndex:0];
	if (27 == c) {
		// 27 should reliably be the escape key's character...
		[self _endTestByUserRequest];
	}
}

#pragma mark -
#pragma mark Delegate methods for TFDOTrackingClient

- (BOOL)clientShouldQuitByServerRequest:(TFDOTrackingClient*)client
{
	[self _endTestByUserRequest];
	
	return NO;
}

- (NSDictionary*)infoDictionaryForClient:(TFDOTrackingClient*)client
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			TFLocalizedString(@"TFTouchTestControllerHumandReadableName", @"Touché Touch Test Application"),
				kToucheTrackingReceiverInfoHumanReadableName,
			nil];
}

- (void)touchesDidBegin:(NSSet*)touches viaClient:(TFDOTrackingClient*)client
{
	for (TFBlob* blob in touches) {
		NSNumber* labelNumber = [NSNumber numberWithInt:[blob.label intLabel]];
		NSColor* color = [self _claimFreeColorForBlobLabelNumber:labelNumber];
		if (nil != color) {
			@synchronized(_touchView) {
				[_touchView addTouchWithID:labelNumber
								atPosition:CGPointMake(blob.center.x, blob.center.y)
								 withColor:color];
			}
		}
	}
	
	NSSound* sound = [NSSound soundNamed:@"touchdown"];
	[sound setVolume:TOUCH_DOWN_VOLUME];
	[sound play];
}

- (void)touchesDidUpdate:(NSSet*)touches viaClient:(TFDOTrackingClient*)client
{
	for (TFBlob* blob in touches) {
		@synchronized(_touchView) {
			[_touchView moveTouchWithID:[NSNumber numberWithInt:[blob.label intLabel]]
							 toPosition:CGPointMake(blob.center.x, blob.center.y)];
		}
	}
}

- (void)touchesDidEnd:(NSSet*)touches viaClient:(TFDOTrackingClient*)client
{
	for (TFBlob* blob in touches) {
		NSNumber* labelNumber = [NSNumber numberWithInt:[blob.label intLabel]];
		@synchronized(_touchView) {
			[_touchView removeTouchWithID:labelNumber];
		}
		[self _freeColorForBlobLabelNumber:labelNumber];
	}
		
	NSSound* sound = [NSSound soundNamed:@"touchup"];
	[sound setVolume:TOUCH_UP_VOLUME];
	[sound play];
}

@end
