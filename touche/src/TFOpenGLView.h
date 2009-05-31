//
//  TFOpenGLView.h
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

#import <Cocoa/Cocoa.h>
#import <QuickTime/QuickTime.h>
#import <QTKit/QTKit.h>
#import <QuartzCore/QuartzCore.h>

@interface TFOpenGLView : NSOpenGLView {
	CIImage*				_ciimage;
	CIContext*				_ciContext;
	CGDirectDisplayID		_curDisplay;
	CVDisplayLinkRef		_displayLink;
	CGColorSpaceRef			_colorSpace;
	CGColorSpaceRef			_workingColorSpace;
	BOOL					_needsReshape;
	float					_zoomX, _zoomY, _tx, _ty;
}

- (CVReturn)drawFrameForTimeStamp:(const CVTimeStamp*)timeStamp;

- (void)clearCIContext;

- (void)setCurrentDisplay:(const CGDirectDisplayID)displayID;

- (BOOL)displayLinkIsRunning;
- (BOOL)startDisplayLink;
- (BOOL)stopDisplayLink;

- (void)render;

@end
