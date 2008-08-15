//
//  TFZoomPinchRecognizer.h
//  Touché
//
//  Created by Georg Kaindl on 24/5/08.
//  Copyright 2008 Georg Kaindl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TFGestureRecognizer.h"

extern NSString* TFZoomPinchRecognizerParamPixels;
extern NSString* TFZoomPinchRecognizerParamAngle;

@interface TFZoomPinchRecognizer : TFGestureRecognizer {
	float		angleTolerance;
	float		minDistance;
}

@property (nonatomic, assign) float angleTolerance;
@property (nonatomic, assign) float minDistance;

@end
