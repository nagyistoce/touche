//
//  TFCalibrationController.h
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

#import <Cocoa/Cocoa.h>

#import "TFFullscreenController.h"

@class TFDOTrackingClient;
@class TFTouchView;
@class TFCalibrationPoint;

@interface TFCalibrationController : TFFullscreenController {
	IBOutlet TFTouchView*	_touchView;
	
	BOOL					isCalibrating;
	id						delegate;
	
	TFDOTrackingClient*		_trackingClient;
	NSArray*				_points;
	NSEnumerator*			_pointsEnumerator;
	TFCalibrationPoint*		_currentPoint;
	BOOL					_waitForNewTouch;
	id						_touchKey;
	id						_firstTouchLabel;
	NSMutableArray*			_savedPointTouches;
}

@property (assign) id delegate;
@property (readonly) BOOL isCalibrating;

- (void)startCalibrationWithPoints:(NSArray*)calibrationPoints;

@end

@interface NSObject (TFCalibrationControllerDelegate)
- (void)calibrationCanceledByUser;
- (void)calibrationCanceledWithError:(NSError*)error;
- (void)didCalibrateWithPoints:(NSArray*)calibrationPoints;
@end
