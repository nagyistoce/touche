//
//  TFOpenGLQTCaptureView.m
//  Touché
//
//  Created by Georg Kaindl on 13/12/07.
//
//  Copyright (C) 2007 Georg Kaindl
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

#import "TFOpenGLQTCaptureView.h"

#import "TFIncludes.h"

@implementation TFOpenGLQTCaptureView

- (void)dealloc
{
	// capture session owner is responsible for disconnecting us before we're released...
	[_captureVideoPreviewOut release];
	
	[super dealloc];
}

- (id)initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat*)format
{
	if (nil == ([super initWithFrame:frameRect pixelFormat:format])) {
		[self release];
		return nil;
	}
	
	_captureVideoPreviewOut = [[QTCaptureVideoPreviewOutput alloc] init];

	return self;
}

- (void)addToQTCaptureSession:(QTCaptureSession*)captureSession
{
	[captureSession addOutput:_captureVideoPreviewOut error:NULL];
	[_captureVideoPreviewOut setVisualContext:_textureContext forConnection:[[_captureVideoPreviewOut connections] objectAtIndex:0]];
}

@end
