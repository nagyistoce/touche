//
//  TFCameraInputPreviewView.h
//  Touché
//
//  Created by Georg Kaindl on 13/12/07.
//  Copyright 2007 Georg Kaindl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TFOpenGLQTCaptureView.h"

@class TFCameraInputFilterChain;

@interface TFCameraInputPreviewView : TFOpenGLQTCaptureView {
	TFCameraInputFilterChain*		_filterChain;
}

@end
