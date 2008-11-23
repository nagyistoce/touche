//
//  TFTouchView.m
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

#import <QuartzCore/QuartzCore.h>

#import "TFTouchView.h"

#import "TFIncludes.h"
#import "NSImage-Extras.h"
#import "TFMiscPreferencesController.h"

@interface TFTouchView (NonPublicMethods)
- (NSImage*)_touchImageWithSize:(CGSize)size andColor:(NSColor*)color;
- (void)_timerRemoveLayer:(NSTimer*)timer;
- (void)_setupDefaults;
@end

@implementation TFTouchView

@synthesize touchAnimationSpeed;
@synthesize delegate;
@synthesize touchSize;

- (id)initWithFrame:(NSRect)frame
{
	if (!(self = [super initWithFrame:frame])) {
		[self release];
		return nil;
	}
	
	[self _setupDefaults];
	
	return self;
}

- (void)dealloc
{
	[touchSize release];
	touchSize = nil;
	
	[_touches release];
	_touches = nil;
	
	[_touchesLayer release];
	_touchesLayer = nil;
	
	[_cachedTouchImages release];
	_cachedTouchImages = nil;
	
	[super dealloc];
}

- (void)_setupDefaults
{	
	self.delegate = nil;
	self.touchAnimationSpeed = .5f;
	self.touchSize = [NSValue valueWithSize:NSMakeSize(50.0f, 50.0f)];
	if (nil != _touches)
		[_touches release];
		
	_touches = [[NSMutableDictionary alloc] init];
	_cachedTouchImages = [[NSMutableDictionary alloc] init];
	
	CALayer* rootLayer = [CALayer layer];
	
	rootLayer.backgroundColor = CGColorGetConstantColor(kCGColorBlack);
	rootLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
	
	[self setLayer:rootLayer];
	[self setWantsLayer:YES];
	
	if (_touchesLayer)
		[_touchesLayer release];
		
	_touchesLayer = [[CALayer layer] retain];
	_touchesLayer.frame = rootLayer.frame;
	
	[rootLayer addSublayer:_touchesLayer];
}

- (void)setTouchSize:(NSValue*)newSize
{
	if (nil == touchSize || ![newSize isEqualToValue:touchSize]) {
		[newSize retain];
		[touchSize release];
		touchSize = newSize;
		
		[_cachedTouchImages removeAllObjects];
	}
}

- (void)addTouchWithID:(id)ID atPosition:(CGPoint)pos
{
	[self addTouchWithID:ID atPosition:pos withColor:[NSColor whiteColor]];
}

- (void)addTouchWithID:(id)ID atPosition:(CGPoint)pos withColor:(NSColor*)color
{
	[self addTouchWithID:ID atPosition:pos withColor:color belowTouchWithID:nil];
}

- (void)addTouchWithID:(id)ID atPosition:(CGPoint)pos withColor:(NSColor*)color belowTouchWithID:(id)belowID
{
	if (nil == ID || nil != [_touches objectForKey:ID])
		return;
	
	CALayer* touchLayer = [CALayer layer];
	
	if ([TFMiscPreferencesController touchesShouldAnimate]) {
		CIFilter* blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
		[blurFilter setDefaults];
		[blurFilter setValue:[NSNumber numberWithFloat:1.0] forKey:@"inputRadius"];
		[blurFilter setName:@"blurFilter"];
		
		[touchLayer setFilters:[NSArray arrayWithObjects:blurFilter, nil]];
		
		CABasicAnimation* blurAnimation = [CABasicAnimation animation];
		blurAnimation.keyPath = @"filters.blurFilter.inputRadius";
		blurAnimation.fromValue = [NSNumber numberWithFloat:1.0f];
		blurAnimation.toValue = [NSNumber numberWithFloat:2.0f];
		blurAnimation.duration = 1.0f;
		blurAnimation.repeatCount = 1e100f;
		blurAnimation.autoreverses = YES;
		blurAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

		[touchLayer addAnimation:blurAnimation forKey:@"blurAnimation"];
		
		CABasicAnimation* pulseAnimation = [CABasicAnimation animation];
		pulseAnimation.keyPath = @"transform";
		pulseAnimation.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
		pulseAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.1f, 1.1f, 1.0f)];
		pulseAnimation.duration = 1.0f;
		pulseAnimation.repeatCount = 1e100f;
		pulseAnimation.autoreverses = YES;
		pulseAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
		
		[touchLayer addAnimation:pulseAnimation forKey:@"pulseAnimation"];
	}
	
	NSSize tSize = [touchSize sizeValue];
	
	CGImageRef cgImg = (CGImageRef)[_cachedTouchImages objectForKey:color];
	
	if (NULL == cgImg) {
		NSImage* img = [self _touchImageWithSize:NSSizeToCGSize(tSize) andColor:color];
		cgImg = [img cgImage];
				
		[_cachedTouchImages setObject:(id)cgImg forKey:color];
	}
		
	touchLayer.name = @"touchImage";
	touchLayer.bounds = CGRectMake(0.0f, 0.0f, tSize.width, tSize.height);
	touchLayer.contents = (id)cgImg;
	touchLayer.contentsGravity = kCAGravityCenter;
	touchLayer.position = pos;
	
	if (nil != belowID) {
		CALayer* topLayer = [_touches objectForKey:belowID];
		if (nil != topLayer)
			[_touchesLayer insertSublayer:touchLayer below:topLayer];
		else
			[_touchesLayer addSublayer:touchLayer];
	} else
		[_touchesLayer addSublayer:touchLayer];
		
	[_touches setObject:touchLayer forKey:ID];		
}

- (void)animateTouchWithID:(id)ID toPosition:(CGPoint)pos
{
	CALayer* touchLayer = [_touches objectForKey:ID];
	
	if (nil == touchLayer)
		return;
	
	[CATransaction begin];
	[CATransaction setValue:[NSNumber numberWithFloat:touchAnimationSpeed]
					 forKey:kCATransactionAnimationDuration];
	touchLayer.position = pos;
	[CATransaction commit];
}

- (void)moveTouchWithID:(id)ID toPosition:(CGPoint)pos
{
	CALayer* touchLayer = [_touches objectForKey:ID];
	
	if (nil == touchLayer)
		return;
	
	[CATransaction begin];
	[CATransaction setValue:[NSNumber numberWithFloat:0.0f]
					 forKey:kCATransactionAnimationDuration];
	touchLayer.position = pos;
	[CATransaction commit];
}

- (void)fadeInTouchWithID:(id)ID
{
	CALayer* touchLayer = [_touches objectForKey:ID];
	
	if (nil == touchLayer)
		return;
	
	CABasicAnimation* fadeTransformAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
	fadeTransformAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
	fadeTransformAnimation.toValue = [NSNumber numberWithFloat:1.0f];
	fadeTransformAnimation.duration = .7f;
	fadeTransformAnimation.repeatCount = 1.0f;
	fadeTransformAnimation.autoreverses = NO;
	fadeTransformAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	
	[touchLayer addAnimation:fadeTransformAnimation forKey:@"fadeTransformAnimation"];
}

- (void)removeTouchWithID:(id)ID
{
	CALayer* touchLayer = [_touches objectForKey:ID];
		
	if (nil != touchLayer) {
		[touchLayer removeFromSuperlayer];
		[_touches removeObjectForKey:ID];
	}
}

- (void)showText:(NSString*)text forSeconds:(NSTimeInterval)seconds
{
	CATextLayer* textLayer = [CATextLayer layer];
	
	textLayer.name = @"textLayer";
	textLayer.string = text;
	textLayer.font = @"Lucida-Grande";
	textLayer.fontSize = [touchSize sizeValue].height/1.5f;
	textLayer.alignmentMode = kCAAlignmentCenter;
	textLayer.foregroundColor = CGColorGetConstantColor(kCGColorWhite);
	textLayer.delegate = self;
	
	[textLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX
														relativeTo:@"superlayer"
														 attribute:kCAConstraintMidX]];
	[textLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidY
														relativeTo:@"superlayer"
														 attribute:kCAConstraintMidY]];
	
	[[self layer] insertSublayer:textLayer above:_touchesLayer];
	
	[NSTimer scheduledTimerWithTimeInterval:seconds
									 target:self
								   selector:@selector(_timerRemoveLayer:)
								   userInfo:textLayer
									repeats:NO];
}

- (void)clearText
{
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];

	for (CALayer* layer in [[self layer] sublayers])
		if ([layer.name isEqualToString:@"textLayer"])
			[layer removeFromSuperlayer];
	
	[CATransaction commit];
}

- (void)_timerRemoveLayer:(NSTimer*)timer
{
	CALayer* layer = [timer userInfo];
	
	[layer removeFromSuperlayer];
}

- (NSImage*)_touchImageWithSize:(CGSize)size andColor:(NSColor*)color
{
	NSSize touchCoreSize = NSMakeSize((7.0f/8.0f)*size.width, (7.0f/8.0f)*size.height);
	NSSize touchShineSize = NSMakeSize((4.0f/3.0f)*size.width, (4.0f/3.0f)*size.height);
	NSSize finalSize = NSMakeSize(2*size.width, 2*size.height);
	NSRect finalRect;
	finalRect.origin = NSZeroPoint;
	finalRect.size = finalSize;
	
	NSRect coreRect;
	coreRect.origin = NSZeroPoint;
	coreRect.size = touchCoreSize;
	
	NSImage* touchCoreImg = [[NSImage alloc] initWithSize:touchCoreSize];
	[touchCoreImg lockFocus];
	[color setFill];
	[[NSBezierPath bezierPathWithOvalInRect:coreRect] fill];
	[touchCoreImg unlockFocus];
	
	NSRect blurRect;
	blurRect.origin.x = (finalSize.width - touchShineSize.width)/2.0f;
	blurRect.origin.y = (finalSize.height - touchShineSize.height)/2.0f;
	blurRect.size = touchShineSize;
	
	NSImage* blurImage = [[NSImage alloc] initWithSize:finalSize];
	[blurImage lockFocus];
	[color setFill];
	[[NSBezierPath bezierPathWithOvalInRect:blurRect] fill];
	[blurImage unlockFocus];
	
	NSData* dataForBlurImage = [blurImage TIFFRepresentation];
	CIImage* ciBlurImage = [CIImage imageWithData:dataForBlurImage];
	
	CIFilter* blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
	[blurFilter setDefaults];
	NSNumber* inputRadius = [NSNumber numberWithFloat:blurRect.size.width/10.0f];
	[blurFilter setValue:inputRadius forKey:@"inputRadius"];
	[blurFilter setValue:ciBlurImage forKey:@"inputImage"];
	CIImage* ciBlurredImage = [blurFilter valueForKey:@"outputImage"];
	ciBlurredImage = [ciBlurredImage imageByCroppingToRect:NSRectToCGRect(finalRect)];
	
	NSImage* compositeImage = [[NSImage alloc] initWithSize:finalSize];
	[compositeImage lockFocus];
	
	[ciBlurredImage drawInRect:finalRect
					  fromRect:finalRect
					 operation:NSCompositeSourceOver
					  fraction:0.7];
	
	CGFloat coreXOffset = (finalSize.width - touchCoreSize.width)/2.0f;
	CGFloat coreYOffset = (finalSize.height - touchCoreSize.height)/2.0f;
	
	[touchCoreImg drawInRect:NSOffsetRect(coreRect, coreXOffset, coreYOffset)
					fromRect:coreRect
				   operation:NSCompositeSourceOver
					fraction:1.0];
	
	[compositeImage unlockFocus];
	
	[touchCoreImg release];
	[blurImage release];
	
	return [compositeImage autorelease];
}

- (void)keyDown:(NSEvent*)event
{
	if ([delegate respondsToSelector:@selector(keyWentDown:)])
		[delegate keyWentDown:[event characters]];
}

#pragma mark -
#pragma mark CALayer delegate

- (id<CAAction>)actionForLayer:(CALayer*)layer
						forKey:(NSString*)key
{
	CATransition* animation = nil;
	
	if ([layer.name isEqualToString:@"textLayer"] && ([key isEqualToString:kCAOnOrderOut] || [key isEqualToString:kCAOnOrderIn])) {
		animation = [CATransition animation];
		animation.type = kCATransitionFade;
		animation.duration = 1.0f;
		animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
	}
	
	return animation;
}

@end
