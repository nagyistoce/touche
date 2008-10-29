//
//  TFFingerPaintView.m
//  TFCoreGraphicsDemo
//
//  Created by Georg Kaindl on 24/5/08.
//  Copyright 2008 Georg Kaindl. All rights reserved.
//

#import "TFFingerPaintView.h"
#import <ToucheFramework/ToucheFramework.h>

@interface TFFingerPaintView (PrivateMethods)
- (void)_setupDefaults;
@end

#define BRUSH_COLOR				1.0f, 1.0f, 1.0f, 1.0f
#define	BRUSH_ALPHA				(0.5f)
#define DEFAULT_BRUSH_SIZE		(20.0f)

@implementation TFFingerPaintView

@synthesize brushSize;

- (void)dealloc
{
	CGContextRelease(_context);
	_context = nil;
	
	[_cgLayers release];
	_cgLayers = nil;
	
	[_bgGradient release];
	_bgGradient = nil;
	
	[super dealloc];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		[self _setupDefaults];
    }
    return self;
}

- (void)setBrushSize:(CGFloat)size
{
	brushSize = size;
	CGContextSetLineWidth(_context, size);
}

- (void)drawRect:(NSRect)rect
{	
	if (nil == _bgGradient) {
		_bgGradient = [[NSGradient alloc]
						initWithColors:[NSArray arrayWithObjects:[NSColor blackColor],
																[NSColor colorWithCalibratedRed:.361f
																						  green:.337f
																						   blue:.42f
																						  alpha:1.0f],
																nil]];
	}
	
	// draw the background
	[_bgGradient drawInRect:[self bounds] angle:-90.0f];
	
	CGRect bounds = NSRectToCGRect([self bounds]);
	CGContextRef viewContext = [[NSGraphicsContext currentContext] graphicsPort];
	
	// draw the old strokes
	CGImageRef image = CGBitmapContextCreateImage(_context);
	CGContextDrawImage(viewContext, bounds, image);
	CGImageRelease(image);
	
	// set transparency. this way, we can see the old strokes shine through the ones currently being
	// drawn by the user.
	CGContextSetAlpha(viewContext, BRUSH_ALPHA);
	
	// draw each of the current touch layers.
	NSSet* allLayers = [_cgLayers allObjects];
	for (id layerId in allLayers) {
		CGLayerRef layer = (CGLayerRef)layerId;
		CGContextDrawLayerInRect(viewContext, bounds, layer);
	}
}

- (void)_setupDefaults
{
	if (_isSetUp)
		return;
	
	_isSetUp = YES;
	
	brushSize = DEFAULT_BRUSH_SIZE;
	_cgLayers = [[TFTouchLabelObjectAssociator alloc] init];
	
	[self setupContext];
}

- (void)setupContext
{
	CGContextRelease(_context);

	// Create an offscreen CG context to paint into... Note that we use the device color space here: Since
	// we don't optimize our drawing at all for this demo app, performance would be atrocious if a colorspace
	// conversion would happen on every redraw.
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	_context = CGBitmapContextCreate(NULL,
									 self.frame.size.width,
									 self.frame.size.height,
									 8,
									 4 * self.frame.size.width,
									 colorSpace,
									 kCGImageAlphaPremultipliedFirst);
	CGColorSpaceRelease(colorSpace);
	
	CGLayerRelease(_layer);
	
	CGLayerRef layer = CGLayerCreateWithContext(_context, NSSizeToCGSize(self.frame.size), NULL);
	CGContextRef context = CGLayerGetContext(layer);
	CGContextSetLineWidth(context, brushSize);
	CGContextSetLineCap(context, kCGLineCapRound);
	CGContextSetRGBStrokeColor(context, BRUSH_COLOR);
}

- (BOOL)isOpaque
{
	return YES;
}

// For each new touch, we create a CGLayer to draw into, associate it with the touch label and store it.
// Then, we treat each new touch like an updated one, i.e. we draw it. Therefore, we set the previous
// center position to the position of the current one, since the previousCenter property is undefined in
// touches handed over in touchesDidBegin:.
- (void)handleNewTouches:(NSSet*)touches
{
	for (TFTouch* touch in touches) {
		CGLayerRef layer = CGLayerCreateWithContext(_context, NSSizeToCGSize(self.frame.size), NULL);
		CGContextRef context = CGLayerGetContext(layer);
		CGContextSetLineWidth(context, brushSize);
		CGContextSetLineCap(context, kCGLineCapRound);
		CGContextSetRGBStrokeColor(context, BRUSH_COLOR);
		
		[_cgLayers setObject:(id)layer forLabel:touch.label];
		CGLayerRelease(layer);
		
		touch.previousCenter = touch.center;
	}
	
	[self handleUpdatedTouches:touches];
}

// We simply draw a line segment between the last known center position and the current one. Note that
// we do not have to do a coordinate system conversion since we're running in fullscreen mode anyway.
- (void)handleUpdatedTouches:(NSSet*)touches
{
	for (TFTouch* touch in touches) {
		CGLayerRef layer = (CGLayerRef)[_cgLayers objectForLabel:touch.label];
		CGContextRef c = CGLayerGetContext(layer);
		
		// No coordinate system conversion necessary, since we're running fullscreen
		NSPoint curPos = NSMakePoint(touch.center.x, touch.center.y);
		NSPoint lastPos = NSMakePoint(touch.previousCenter.x, touch.previousCenter.y);
	
		// Draw the line segment into the layer for this touch
		CGContextBeginPath(c);
		CGContextMoveToPoint(c, lastPos.x, lastPos.y);
		CGContextAddLineToPoint(c, curPos.x, curPos.y);
		CGContextStrokePath(c);
	}
	
	// if we had some touches, redraw the view, so that the user can see the lines while drawing on
	// the touchscreen...
	if ([touches count] > 0)
		[self setNeedsDisplay:YES];
}

// We merge the ended touch's layer with the main image and remove the layer from the associative store.
- (void)handleEndedTouches:(NSSet*)touches
{
	CGRect bounds = NSRectToCGRect([self bounds]);

	for (TFTouch* touch in touches) {
		CGLayerRef layer = (CGLayerRef)[_cgLayers objectForLabel:touch.label];
		
		CGContextSetAlpha(_context, BRUSH_ALPHA);
		CGContextDrawLayerInRect(_context, bounds, layer);
						
		[_cgLayers removeObjectForLabel:touch.label];
	}
	
	if ([touches count] > 0)
		[self setNeedsDisplay:YES];
}

#pragma mark -
#pragma mark Event handling

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)becomeFirstResponder
{
	return YES;
}

// if the user presses the escape key, we quit...
- (void)keyDown:(NSEvent*)event
{
	unichar c = [[event characters] characterAtIndex:0];
	if (27 == c) {
		[NSApp terminate:self];
	}
}

@end
