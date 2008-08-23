//
//  TFCalibrationController.m
//  Touché
//
//  Created by Georg Kaindl on 28/3/08.
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

#import "TFCalibrationController.h"

#define TRACKINGCLIENT_NAME			(@"TFCalibrationController")
#define CALIBRATION_MIN_BLOB_AGE	((NSTimeInterval).5)

#import "TFIncludes.h"
#import "TFTouchView.h"
#import "TFCalibrationPoint.h"
#import "TFDOTrackingClient.h"
#import "TFBlob.h"
#import "TFBlobPoint.h"

@interface TFCalibrationController (NonPublicMethods)
- (void)_calibrateNextPoint;
- (void)_cleanup;
- (void)_cancelCalibrationByUserRequest;
- (void)_stopCalibration;
@end

@implementation TFCalibrationController

@synthesize delegate;
@synthesize isCalibrating;

- (void)dealloc
{
	[self _cleanup];
	
	[_currentPoint release];
	_currentPoint = nil;
	
	if (nil != _touchKey)
		[_touchView removeTouchWithID:_touchKey];
	
	[_firstTouchLabel release];
	_firstTouchLabel = nil;
	
	[_savedPointTouches release];
	_savedPointTouches = nil;
	
	[super dealloc];
}

- (void)_cleanup
{
	[_touchKey release];
	_touchKey = nil;
	[_points release];
	_points = nil;
	[_pointsEnumerator release];
	_pointsEnumerator = nil;
	
	[_savedPointTouches removeAllObjects];
}

- (void)startCalibrationWithPoints:(NSArray*)calibrationPoints
{
	NSError* error;
	
	if (isCalibrating)
		return;
	
	_trackingClient = [[TFDOTrackingClient alloc] init];
	_trackingClient.delegate = self;
	_touchView.delegate = self;
	
	if (![_trackingClient connectWithName:TRACKINGCLIENT_NAME serviceName:nil server:nil error:&error]) {
		[_trackingClient release];
		_trackingClient = nil;
		
		if ([delegate respondsToSelector:@selector(calibrationController:canceledWithError:)])
			[delegate calibrationController:self canceledWithError:error];
		
		return;
	}
	
	isCalibrating = YES;
	
	CGFloat screenSizePerCentimeter = [_trackingClient screenPixelsPerCentimeter];
	_touchView.touchSize = [NSValue valueWithSize:NSMakeSize(screenSizePerCentimeter*1.5,
															 screenSizePerCentimeter*1.5f)];
		
	[_firstTouchLabel release];
	_firstTouchLabel = nil;
	
	_waitForNewTouch = NO;
	
	self.hidesMouseCursor = ([[NSScreen screens] count] <= 1);
	if (![self goFullscreenWithView:_touchView onScreen:[_trackingClient screen]]) {
		[self _stopCalibration];

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
		
		if ([delegate respondsToSelector:@selector(calibrationController:canceledWithError:)])
			[delegate calibrationController:self canceledWithError:error];
		
		return;
	}
	
	NSSortDescriptor *ascendingX = [[NSSortDescriptor alloc] initWithKey:@"screenX" ascending:YES];
	NSSortDescriptor *descendingY = [[NSSortDescriptor alloc] initWithKey:@"screenY" ascending:NO];
	
	NSArray* sortedPoints =
		[calibrationPoints sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descendingY, ascendingX, nil]];
	
	[ascendingX release];
	[descendingY release];
	
	[_points release];
	_points = [sortedPoints retain];
	
	[_pointsEnumerator release];
	_pointsEnumerator = [[_points objectEnumerator] retain];
	
	if (nil == _savedPointTouches)
		_savedPointTouches = [[NSMutableArray alloc] init];
	else
		[_savedPointTouches removeAllObjects];
	
	[_touchView showText:TFLocalizedString(@"TFCalibrationControllerStartInfo", @"TFCalibrationControllerStartInfo")
			  forSeconds:5.0];
	
	[self _calibrateNextPoint];
}

- (void)_calibrateNextPoint
{
	_currentPoint = [[_pointsEnumerator nextObject] retain];
	
	if (nil == _currentPoint) {
		[self _stopCalibration];
	
		if ([delegate respondsToSelector:@selector(calibrationController:didCalibrateWithPoints:)])
			[delegate calibrationController:self didCalibrateWithPoints:_points];
		
		[self _cleanup];
		return;
	}

	// if we haven't started yet, we need to add a "touch" to the view first...
	if (nil == _touchKey) {
		_touchKey = [[NSNumber numberWithInt:1] retain];
		[_touchView addTouchWithID:_touchKey atPosition:CGPointMake(_currentPoint.screenX, _currentPoint.screenY)];
	} else {
		[_touchView animateTouchWithID:_touchKey toPosition:CGPointMake(_currentPoint.screenX, _currentPoint.screenY)];
	}
}

- (void)_stopCalibration
{
	if (!isCalibrating)
		return;
	
	[_trackingClient disconnect];
	_trackingClient.delegate = nil;
	[_trackingClient release];
	_trackingClient = nil;
	
	[_touchView removeTouchWithID:_touchKey];
	[_touchView clearText];
	
	for (id key in _savedPointTouches)
		[_touchView removeTouchWithID:key];
	[_savedPointTouches removeAllObjects];
	
	[self quitFullscreen];
	
	isCalibrating = NO;
}

- (void)_cancelCalibrationByUserRequest
{
	if (isCalibrating) {
		[self _stopCalibration];
		[self _cleanup];
		
		if ([delegate respondsToSelector:@selector(calibrationCanceledByUser:)])
			[delegate calibrationCanceledByUser:self];
	}
}

#pragma mark -
#pragma mark Delegate methods for TFTouchView

- (void)keyWentDown:(NSString*)characters
{
	unichar c = [characters characterAtIndex:0];
	if (27 == c) {
		// 27 should reliably be the escape key's character...
		[self _cancelCalibrationByUserRequest];
	}
}

#pragma mark -
#pragma mark Delegate methods for TFTrackingClient

- (BOOL)clientShouldQuitByServerRequest:(TFDOTrackingClient*)client
{
	[self _cancelCalibrationByUserRequest];
	
	return NO;
}

- (NSDictionary*)infoDictionaryForClient:(TFDOTrackingClient*)client
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			TFLocalizedString(@"TFCalibrationControllerHumandReadableName", @"Touché Calibration Tool"),
				kToucheTrackingReceiverInfoHumanReadableName,
			nil];
}

- (void)touchesDidBegin:(NSSet*)touches viaClient:(TFDOTrackingClient*)client
{
	if (nil == _firstTouchLabel) {
		TFBlob* firstTouch = (TFBlob*)[touches anyObject];
		_firstTouchLabel = [firstTouch.label retain];
	}
}

- (void)touchesDidUpdate:(NSSet*)touches viaClient:(TFDOTrackingClient*)client
{
	if (nil == _firstTouchLabel)
		return;
	
	for (TFBlob* blob in touches) {
		if ([blob.label isEqual:_firstTouchLabel]) {
			NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
			
			if (now - blob.trackedSince > CALIBRATION_MIN_BLOB_AGE) {
				if (nil != _currentPoint && !_waitForNewTouch) {
					_waitForNewTouch = YES;
				
					_currentPoint.cameraX = blob.center.x;
					_currentPoint.cameraY = blob.center.y;
					
					id key = [_currentPoint description];
					[_touchView addTouchWithID:key
									atPosition:CGPointMake(_currentPoint.screenX, _currentPoint.screenY)
									 withColor:[NSColor colorWithCalibratedRed:1.0f green:0.3f blue:0.3 alpha:1.0]
							  belowTouchWithID:_touchKey];
					[_touchView fadeInTouchWithID:key];
					
					[_savedPointTouches addObject:key];
					
					[_currentPoint release];
					_currentPoint = nil;
					
					[self _calibrateNextPoint];
				}
			}
			
			break;
		}
	}
}

- (void)touchesDidEnd:(NSSet*)touches viaClient:(TFDOTrackingClient*)client
{
	if (nil == _firstTouchLabel)
		return;
	
	for (TFBlob* blob in touches) {
		if ([blob.label isEqual:_firstTouchLabel]) {
			[_firstTouchLabel release];
			_firstTouchLabel = nil;
			
			_waitForNewTouch = NO;
			
			break;
		}
	}
}

@end
