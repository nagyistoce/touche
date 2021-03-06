//
//  TFOpenGLView.m
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

#import "TFOpenGLView.h"

#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>

#import "TFIncludes.h"


@interface TFOpenGLView (NonPublicMethods)
- (CIContext*)_currentCIContext;
- (CIImage*)_processImage:(CIImage*)inputImage;
- (void)_drawAdditionalOpenGLStuffWithOrigin:(CGPoint)origin pictureSize:(CGSize)pictureSize viewSize:(CGSize)viewSize;
@end

static CVReturn TFOpenGLViewCallback(CVDisplayLinkRef displayLink, 
									 const CVTimeStamp *inNow, 
									 const CVTimeStamp *inOutputTime, 
									 CVOptionFlags flagsIn, 
									 CVOptionFlags *flagsOut, 
									 void *displayLinkContext)
{
	return [(TFOpenGLView *)displayLinkContext drawFrameForTimeStamp:inOutputTime];	
}

@implementation TFOpenGLView

+ (NSOpenGLPixelFormat*)defaultPixelFormat
{	
	static NSOpenGLPixelFormat* pixelFormat = nil;
	
	if (nil == pixelFormat) {
		static const NSOpenGLPixelFormatAttribute attr[] = {
			NSOpenGLPFAAccelerated,
			NSOpenGLPFANoRecovery,
			NSOpenGLPFADoubleBuffer,
			NSOpenGLPFAColorSize, 32,
			NSOpenGLPFAAllowOfflineRenderers,
			0
		};
				
		pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:(void*)&attr];
	}
	
	return pixelFormat;
}

- (void)dealloc
{
	[self clearCIContext];
	
	[_ciContext release];
	_ciContext = nil;
	
	[_ciimage release];
	_ciimage = nil;
	
	if (NULL != _colorSpace) {
		CGColorSpaceRelease(_colorSpace);
		_colorSpace = NULL;
	}
	
	if (NULL != _workingColorSpace) {
		CGColorSpaceRelease(_workingColorSpace);
		_workingColorSpace = NULL;
	}

	if (_displayLink) {
		[self stopDisplayLink];
        CVDisplayLinkRelease(_displayLink);
        _displayLink = NULL;
    }

	[super dealloc];
}

- (id)initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat*)format
{
	if (nil == ([super initWithFrame:frameRect pixelFormat:format])) {
		[self release];
		return nil;
	}
	
	_ciContext = nil;
	_ciimage = nil;
	_curDisplay = CGMainDisplayID();
	_needsReshape = YES;
	
	_colorSpace = NULL;
	_workingColorSpace = NULL;
	
	return self;
}

- (BOOL)isOpaque
{
	return YES;
}

- (void)prepareOpenGL
{
	glDisable(GL_ALPHA_TEST);
	glDisable(GL_DEPTH_TEST);
	glDisable(GL_SCISSOR_TEST);
	glDisable(GL_BLEND);
	glDisable(GL_DITHER);
	glDisable(GL_CULL_FACE);
	glDisable(GL_LIGHTING);
	glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
	glDepthMask(GL_FALSE);
	glStencilMask (0);
	glHint(GL_TRANSFORM_HINT_APPLE, GL_FASTEST);
	glClearColor(0.2f, 0.2f, 0.2f, 1.0f);
	
	// turn v-sync off for better performance
	GLint swapInterval = 0;
	[[self openGLContext] setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];
	
	_needsReshape = YES;
}

- (void)reshape
{ 	
	_needsReshape = YES;
}

// override this in a subclass to process a frame before displaying it
- (CIImage*)_processImage:(CIImage*)inputImage
{
	return inputImage;
}

// override this in a subclass to draw additional OpenGL stuff after the frame is rendered
- (void)_drawAdditionalOpenGLStuffWithOrigin:(CGPoint)origin pictureSize:(CGSize)pictureSize viewSize:(CGSize)viewSize
{
}

- (CIContext*)_currentCIContext
{
	if (nil == _ciContext) {
		[[self openGLContext] makeCurrentContext];
		
		NSOpenGLPixelFormat* pixelFormat = [self pixelFormat];
		if (nil == pixelFormat)
			pixelFormat = [[self class] defaultPixelFormat];
		
		_ciContext = [[CIContext contextWithCGLContext:(CGLContextObj)CGLGetCurrentContext()
										   pixelFormat:(CGLPixelFormatObj)[pixelFormat CGLPixelFormatObj]
											   options:[NSDictionary dictionaryWithObjectsAndKeys:
														(NULL != (id)_colorSpace ? (id)_colorSpace : (id)[NSNull null]), kCIContextOutputColorSpace,
														(NULL != (id)_workingColorSpace ? (id)_workingColorSpace : (id)[NSNull null]), kCIContextWorkingColorSpace, nil]] retain];
		
	}
	
	return _ciContext;
}

- (void)clearCIContext
{
	if (nil != _ciContext) {
		[_ciContext clearCaches];
		[_ciContext reclaimResources];
		[_ciContext release];
		_ciContext = nil;
	}
}

- (void)render
{
	@synchronized(self) {
		[[self openGLContext] makeCurrentContext];

		if (nil != _ciimage) {
			CGRect		imageRect;

			CIImage* image = [self _processImage:_ciimage];
			imageRect = [image extent];
			
			NSRect frame = [self frame];
			NSRect bounds = [self bounds];
		
			glClear(GL_COLOR_BUFFER_BIT);
			
			if (_needsReshape) {
				float minX, minY, maxX, maxY;
								
				minX = NSMinX(bounds);
				minY = NSMinY(bounds);
				maxX = NSMaxX(bounds);
				maxY = NSMaxY(bounds);
				
				// we don't stretch, instead, we letterbox if necessary.
				float longSide = MAX(imageRect.size.width, imageRect.size.height);
				float longFSide = (longSide == imageRect.size.width) ? frame.size.width : frame.size.height;
				_zoomX = _zoomY = longSide / longFSide;
				
				float scaledWidth = imageRect.size.width / _zoomX;
				float scaledHeight = imageRect.size.height / _zoomY;
				_tx = round(((maxX - minX) - scaledWidth)/2.0);
				_ty = round(((maxY - minY) - scaledHeight)/2.0);
				
				if (NSIsEmptyRect([self visibleRect]))
					glViewport(0, 0, 1, 1);
				else
					glViewport(_tx, _ty, frame.size.width, frame.size.height);
				
				glMatrixMode(GL_MODELVIEW);
				glLoadIdentity();
				glMatrixMode(GL_PROJECTION);
				glLoadIdentity();
				gluOrtho2D(minX*_zoomX,
						   maxX*_zoomX,
						   minY*_zoomY,
						   maxY*_zoomY);
				
				glClear(GL_COLOR_BUFFER_BIT);
				
				_needsReshape = NO;
			}
					
			CGPoint imgOriginOnGLFrame = CGPointMake(0.0f, 0.0f);
			
			[[self _currentCIContext] drawImage:image
										atPoint:imgOriginOnGLFrame
									   fromRect:imageRect];
									   			
			// invert y-axis so that 0,0 is in the top left corner (as expected)
			glPushMatrix();
			glTranslatef(0.0f, (frame.size.height - _ty)*_zoomY, 0.0f);
			glScaled(1.0, -1.0, 1.0);
			// take care of any letterboxing...
			glTranslatef(_tx * _zoomX, _ty * _zoomY, 0);
						
			[self _drawAdditionalOpenGLStuffWithOrigin:imgOriginOnGLFrame
										   pictureSize:imageRect.size
											  viewSize:CGSizeMake(frame.size.width, frame.size.height)];
			
			glPopMatrix();
		}
		
		[[self openGLContext] flushBuffer];
		
		[NSOpenGLContext clearCurrentContext];
	}
}

- (CVReturn)drawFrameForTimeStamp:(const CVTimeStamp*)timeStamp
{
	// Do nothing. A subclass should get the frame for the timestamp here
	// and save it into _ciimage
	return kCVReturnSuccess;
}

- (void)setCurrentDisplay:(CGDirectDisplayID)displayID
{
	if (_curDisplay != displayID) {
		if (NULL != _displayLink)
			CVDisplayLinkSetCurrentCGDisplay(_displayLink, displayID);
		
		_curDisplay = displayID;
	}
}

- (BOOL)displayLinkIsRunning
{
	return (NULL != _displayLink && CVDisplayLinkIsRunning(_displayLink));
}

- (BOOL)startDisplayLink
{
	if (![self displayLinkIsRunning]) {	
		CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);
		if (NULL != _displayLink) {
			CVDisplayLinkSetCurrentCGDisplay(_displayLink, _curDisplay);
			CVDisplayLinkSetOutputCallback(_displayLink, &TFOpenGLViewCallback, self);
						
			return (kCVReturnSuccess == CVDisplayLinkStart(_displayLink));
		}
	}
	
	return NO;
}

- (BOOL)stopDisplayLink
{
	if (NULL != _displayLink && [self displayLinkIsRunning]) {
		BOOL rv = (kCVReturnSuccess == CVDisplayLinkStop(_displayLink));
		CVDisplayLinkRelease(_displayLink);
		_displayLink = NULL;
		
		@synchronized(self) {
			[_ciimage release];
			_ciimage = nil;
		
			[_ciContext clearCaches];
			[_ciContext reclaimResources];
			
			// we should re-use the cicontext as long as possible, since those are
			// prone to leaking memory until Apple finally fixes them...
			//[self clearCIContext];
		}
		
		return rv;
	}
	
	return false;
}

@end
