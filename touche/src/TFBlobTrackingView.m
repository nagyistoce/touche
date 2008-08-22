//
//  TFBlobTrackingView.m
//  Touché
//
//  Created by Georg Kaindl on 19/12/07.
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

#import "TFBlobTrackingView.h"

#import "TFIncludes.h"
#import "TFBlob.h"
#import "TFBlobLabel.h"
#import "TFBlobBox.h"
#import "TFBlobPoint.h"
#import "TFBlobSize.h"

@interface TFBlobTrackingView (NonPublicMethods)
- (void)_drawEllipse:(CGPoint)center size:(CGSize)size color:(NSColor*)color;
@end

@implementation TFBlobTrackingView

@synthesize blobs;

- (void)setBlobs:(NSArray *)array
{
	@synchronized(self) {
		[array retain];
		[blobs release];
		blobs = array;
	}
}

- (void)setDelegate:(id)newDelegate
{
	[super setDelegate:newDelegate];
	
	// cache for performance reasons
	_delegateHasBlobsForTimestamp = [delegate respondsToSelector:@selector(cameraBlobsForTimestamp:)];
}

- (void)dealloc
{
	[blobs release];
	
	[super dealloc];
}

- (id)initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat*)format
{
	if (nil == ([super initWithFrame:frameRect pixelFormat:format])) {
		[self release];
		return nil;
	}
	
	blobs = nil;
	
	return self;
}

- (void)_drawEllipse:(CGPoint)center size:(CGSize)size color:(NSColor*)color
{
	CGFloat r, g, b, a;
	r = a = 1.0f;	// default color is solid red
	g = b = 0.0f;
	
	if (nil != color)
		[color getRed:&r green:&g blue:&b alpha:&a];
	
	CGFloat xRadius = size.width/2;
	CGFloat yRadius = size.height/2;
	
	glColor4f(r, g, b, a);
	glBegin(GL_TRIANGLE_FAN);
	
	NSUInteger i;
	for (i=0; i < 360; i++)
	{
		float degInRad = i*(M_PI/180);
		glVertex2f(center.x+cos(degInRad)*xRadius, center.y+sin(degInRad)*yRadius);
	}
	
	glEnd();
}

- (void)_drawAdditionalOpenGLStuffWithOrigin:(CGPoint)origin pictureSize:(CGSize)pictureSize viewSize:(CGSize)viewSize
{
	if (nil == blobs)
		return;
	
	for (TFBlob *blob in blobs) {
		NSColor* color = nil;
	
		switch(blob.label.intLabel % 11) {
			case 0:
				color = [NSColor colorWithDeviceRed:0.0 green:1.0 blue:0.0 alpha:0.8];
				break;
			case 1:
				color = [NSColor colorWithDeviceRed:1.0 green:0.0 blue:0.0 alpha:0.8];
				break;
			case 2:
				color = [NSColor colorWithDeviceRed:0.0 green:0.0 blue:1.0 alpha:0.8];
				break;
			case 3:
				color = [NSColor colorWithDeviceRed:1.0 green:1.0 blue:0.0 alpha:0.8];
				break;
			case 4:
				color = [NSColor colorWithDeviceRed:0.0 green:1.0 blue:1.0 alpha:0.8];
				break;
			case 5:
				color = [NSColor colorWithDeviceRed:.5 green:0.5 blue:1.0 alpha:0.8];
				break;
			case 6:
				color = [NSColor colorWithDeviceRed:1.0 green:0.5 blue:.5 alpha:0.8];
				break;
			case 7:
				color = [NSColor colorWithDeviceRed:.5 green:1.0 blue:.5 alpha:0.8];
				break;
			case 8:
				color = [NSColor colorWithDeviceRed:.7 green:.7 blue:.7 alpha:0.8];
				break;
			case 9:
				color = [NSColor colorWithDeviceRed:.4 green:.8 blue:.9 alpha:0.8];
				break;
			default:
				color = [NSColor colorWithDeviceRed:1.0 green:0.0 blue:1.0 alpha:0.8];
				break;
		}
	
		[self _drawEllipse:CGPointMake(origin.x + blob.center.x, origin.y + blob.center.y)
					  size:CGSizeMake(blob.boundingBox.size.width, blob.boundingBox.size.height)
					  color:color];
	}
}

- (CVReturn)drawFrameForTimeStamp:(const CVTimeStamp*)timeStamp
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	if (_delegateHasBlobsForTimestamp) {
		NSArray* newBlobs = [delegate cameraBlobsForTimestamp:timeStamp];
		[self setBlobs:newBlobs];
	}
	
	[pool release];
	
	return [super drawFrameForTimeStamp:timeStamp];
}

@end
