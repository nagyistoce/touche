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
- (void)_drawBlobBoundingRect:(CGRect)rect lineWidth:(CGFloat)lineWidth color:(NSColor*)color;
- (void)_drawEllipse:(CGPoint)center size:(CGSize)size color:(NSColor*)color;
- (void)_drawDigitalNumber:(NSUInteger)number
				   atPoint:(CGPoint)p
			 segmentLength:(CGFloat)segmentLength
				   spacing:(CGFloat)spacing
					 color:(NSColor*)color;
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
	_delegateHasBlobsForTimestamp = [delegate respondsToSelector:@selector(blobTrackingView:cameraBlobsForTimestamp:)];
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

- (void)_drawBlobBoundingRect:(CGRect)rect lineWidth:(CGFloat)lineWidth color:(NSColor*)color
{
	CGFloat r, g, b, a;
	r = a = b = 1.0f;	// default color is solid magenta
	g = 0.0f;
	
	if (nil != color)
		[color getRed:&r green:&g blue:&b alpha:&a];
	
	glColor4f(r, g, b, a);
	glLineWidth(lineWidth);

	glBegin(GL_LINE_LOOP);

	glVertex2f(CGRectGetMinX(rect), CGRectGetMinY(rect));
	glVertex2f(CGRectGetMinX(rect), CGRectGetMaxY(rect));
	glVertex2f(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
	glVertex2f(CGRectGetMaxX(rect), CGRectGetMinY(rect));
	
	glEnd();
}

// not used at the moment
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
	//glBegin(GL_LINE_LOOP);
	
	NSUInteger i;
	for (i=0; i < 360; i++)
	{
		float degInRad = i*(M_PI/180);
		glVertex2f(center.x+cos(degInRad)*xRadius, center.y+sin(degInRad)*yRadius);
	}
		
	glEnd();
}

- (void)_drawDigitalNumber:(NSUInteger)number
				   atPoint:(CGPoint)p
			 segmentLength:(CGFloat)segmentLength
				   spacing:(CGFloat)spacing
					 color:(NSColor*)color
{
	static NSUInteger segments[10][7] = {
		{1, 1, 1, 0, 1, 1, 1},		// 0
		{0, 0, 1, 0, 0, 1, 0},		// 1
		{1, 0, 1, 1, 1, 0, 1},		// 2
		{1, 0, 1, 1, 0, 1, 1},		// 3
		{0, 1, 1, 1, 0, 1, 0},		// 4
		{1, 1, 0, 1, 0, 1, 1},		// 5
		{1, 1, 0, 1, 1, 1, 1},		// 6
		{1, 0, 1, 0, 0, 1, 0},		// 7
		{1, 1, 1, 1, 1, 1, 1},		// 8
		{1, 1, 1, 1, 0, 1, 0}		// 9
	};
	
	CGFloat r, g, b, a;
	r = a = b = 1.0f;	// default color is solid magenta
	g = 0.0f;
	
	if (nil != color)
		[color getRed:&r green:&g blue:&b alpha:&a];
	
	CGFloat lineWidth = MAX(1.0f, segmentLength/4.0f);
		
	glColor4f(r, g, b, a);
	glLineWidth(lineWidth);
	
	int f = 1;
	while (f*10 <= number)
		f *= 10;
	
	while (f > 0) {
		int x = number/f;
		number -= x*f;
		
		NSUInteger* s = segments[x];
		int i=0;
		for (i; i<7; i++) {
			if (s[i]) {
				CGPoint s, e;
			
				switch(i) {
					case 0:
						s = CGPointMake(p.x, p.y - 2*segmentLength);
						e = CGPointMake(p.x + segmentLength, p.y - 2*segmentLength);
						break;
					case 1:
						s = CGPointMake(p.x, p.y - 2*segmentLength);
						e = CGPointMake(p.x, p.y - segmentLength);
						break;
					case 2:
						s = CGPointMake(p.x + segmentLength, p.y - 2*segmentLength);
						e = CGPointMake(p.x + segmentLength, p.y - segmentLength);
						break;
					case 3:
						s = CGPointMake(p.x, p.y - segmentLength);
						e = CGPointMake(p.x + segmentLength, p.y - segmentLength);
						break;
					case 4:
						s = CGPointMake(p.x, p.y - segmentLength);
						e = CGPointMake(p.x, p.y);
						break;
					case 5:
						s = CGPointMake(p.x + segmentLength, p.y - segmentLength);
						e = CGPointMake(p.x + segmentLength, p.y);
						break;
					case 6:
						s = CGPointMake(p.x, p.y);
						e = CGPointMake(p.x + segmentLength, p.y);
						break;
				}
			
				glBegin(GL_LINES);
					glVertex2f(s.x, s.y);
					glVertex2f(e.x, e.y);
				glEnd();
			}
		}
		
		p.x += segmentLength + spacing;
		f /= 10;
	}
}

- (void)_drawAdditionalOpenGLStuffWithOrigin:(CGPoint)origin pictureSize:(CGSize)pictureSize viewSize:(CGSize)viewSize
{
	if (nil == blobs)
		return;
	
	CGFloat lineWidth = ceil(MAX(1.0f, viewSize.width/320.0f));
	CGFloat	numSegmentLength = ceil(viewSize.width/240.0f);
	CGFloat numSpacing = ceil(numSegmentLength/2.0);
	
	for (TFBlob *blob in blobs) {
		[self _drawBlobBoundingRect:CGRectMake(blob.boundingBox.origin.x,
											   blob.boundingBox.origin.y,
											   blob.boundingBox.size.width,
											   blob.boundingBox.size.height)
						  lineWidth:lineWidth
							  color:nil];
		
		if (numSegmentLength >= 2.0f) {
			int l = 0;
			NSInteger intLabel = blob.label.intLabel;
			do {
				l++;
				intLabel /= 10;
			} while (intLabel > 0);
			
			CGPoint p = CGPointMake(blob.boundingBox.origin.x - (l-1)*numSpacing - l*numSegmentLength,
									blob.boundingBox.origin.y - numSegmentLength);
			
			[self _drawDigitalNumber:blob.label.intLabel
							 atPoint:p
					   segmentLength:numSegmentLength
							 spacing:numSpacing
							   color:nil];
		}
	}	
}

- (CVReturn)drawFrameForTimeStamp:(const CVTimeStamp*)timeStamp
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	if (_delegateHasBlobsForTimestamp) {
		NSArray* newBlobs = [delegate blobTrackingView:self cameraBlobsForTimestamp:timeStamp];
		[self setBlobs:newBlobs];
	}
	
	[pool release];
	
	return [super drawFrameForTimeStamp:timeStamp];
}

@end
