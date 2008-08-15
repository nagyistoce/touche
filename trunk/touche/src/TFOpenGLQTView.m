//
//  TFOpenGLQTView.m
//  Touché
//
//  Created by Georg Kaindl on 7/1/08.
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

#import "TFOpenGLQTView.h"

#import "TFIncludes.h"

@implementation TFOpenGLQTView

- (void)dealloc
{
	if (_videoFrame) {
    	CVOpenGLTextureRelease(_videoFrame);
        _videoFrame = NULL;
    }

	if (_textureContext) {
		CFRelease(_textureContext);
		_textureContext = NULL;
    }
	
	[super dealloc];
}

- (id)initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat*)format
{
	if (nil == ([super initWithFrame:frameRect pixelFormat:format])) {
		[self release];
		return nil;
	}
	
	_textureContext = NULL;
	_videoFrame = NULL;
	
	return self;
}

- (void)prepareOpenGL
{
	[super prepareOpenGL];
	
	QTOpenGLTextureContextCreate(kCFAllocatorDefault,
								 [[self openGLContext] CGLContextObj],
                                 (CGLPixelFormatObj)[[self pixelFormat] CGLPixelFormatObj],
                                 NULL,
                                 &_textureContext);
}

- (CVReturn)drawFrameForTimeStamp:(const CVTimeStamp*)timeStamp
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	if (NULL != _textureContext && QTVisualContextIsNewImageAvailable(_textureContext, timeStamp)) {
		if (NULL != _videoFrame) {
        	CVOpenGLTextureRelease(_videoFrame);
        	_videoFrame = NULL;
        }
        
		OSStatus status = QTVisualContextCopyImageForTime(_textureContext, NULL, timeStamp, &_videoFrame);
		
		if ((noErr == status) && (NULL != _videoFrame)) {
			@synchronized(self) {
				if (nil != _ciimage)
					[_ciimage release];
				
				_ciimage = [[CIImage imageWithCVImageBuffer:_videoFrame] retain];
			}
			
        	[self render];
		}
	}
	
    [pool release];
	
	QTVisualContextTask(_textureContext);
	
	return kCVReturnSuccess;
}

@end
