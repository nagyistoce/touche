//
//  TFCADemoView.m
//  TFCoreAnimationDemo
//
//  Created by Georg Kaindl on 21/5/08.
//  Copyright 2008 Georg Kaindl. All rights reserved.
//

#import "TFCADemoView.h"
#import <QuartzCore/QuartzCore.h>
#import <QuartzCore/CoreAnimation.h>
#import <ToucheFramework/ToucheFramework.h>

#define MOTION_DISPLACEMENT_TO_ROTATION_ANGLE_DEGREES_FACTOR	(.3f)
#define ROTATION_AREA_BORDER_CENTIMETER_WIDTH					(1.0f)

#define ZOOM_RECOGNIZER_ANGLE_TOLERANCE							(pi/4.0f)
#define ZOOM_RECOGNIZER_MIN_PIXEL_DISTANCE						(pixelsPerCentimeter/6.0f)
#define ZOOM_SCREEN_PIXELS_TO_SCALE_FACTOR						(pixelsPerCentimeter/5000.0f)

#define TAP_RECOGNIZER_MAX_TAP_TIME								((NSTimeInterval).5)
#define TAP_RECOGNIZER_MAX_DISTANCE								(pixelsPerCentimeter*2.5f)

#define	DOUBLE_TAP_ZOOMED_WIDTH									(pixelsPerCentimeter*20.0f)
#define	DOUBLE_TAP_MINIMIZED_WIDTH								(pixelsPerCentimeter*4.0f)

// You can define your own enum's to use them in TFGestureInfo as either type or subtype, but
// be sure to start at TFGestureTypeMax+1 in order not to conflict with the values defined by the
// framework
typedef enum {
	TouchOperationDrag = TFGestureTypeMax+1,
	TouchOperationRotate
} touchOperation;

@interface TFCADemoView (PrivateMethods)
- (void)_handleDoubleTapOnLayer:(CALayer*)layer;
- (void)_setDefaults;
- (CALayer*)_imageLayerWithName:(NSString*)name;
@end

@implementation TFCADemoView

@synthesize pixelsPerCentimeter;

- (void)setPixelsPerCentimeter:(CGFloat)newVal
{
	if (pixelsPerCentimeter != newVal) {
		pixelsPerCentimeter = newVal;
		_touchIndicatorLayer.indicatorDiameter = newVal;
		_zoomRecognizer.minDistance = ZOOM_RECOGNIZER_MIN_PIXEL_DISTANCE;
		_tapRecognizer.maxTapDistance = TAP_RECOGNIZER_MAX_DISTANCE;
	}
}

- (void)awakeFromNib
{
	[self _setDefaults];
}

- (void)dealloc
{
	[_imagesLayer removeFromSuperlayer];
	[_imagesLayer release];
	_imagesLayer = nil;
	
	[_touchIndicatorLayer release];
	_touchIndicatorLayer = nil;
	
	[_operations release];
	_operations = nil;
	
	[super dealloc];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self _setDefaults];
    }
    return self;
}

// We add an image with a given name and a width we want to scale it to.
- (void)addImageNamed:(NSString*)name withCenterAt:(NSPoint)center scaledWidth:(CGFloat)scaledWidth
{
	CALayer* layer = [self _imageLayerWithName:name];
	
	CGFloat scale = scaledWidth / layer.frame.size.width;
	CATransform3D scaleTransform = CATransform3DMakeScale(scale, scale, 1.0f);
	
	layer.name = name;
	layer.position = NSPointToCGPoint(center);
	layer.transform = scaleTransform;
	layer.opaque = YES;
	
	[_imagesLayer addSublayer:layer];
}

// When a new touch happens, we look to see if it happens to fall onto any of our image layers. If yes, we
// associate the layer with this touch label.
// Also, we bring the layer to the front of the rendering stack.
// Finally, we distinguish between two types of "gestures" that we defined ourselves: Hitting the image around
// the middle of it will drag it, hitting it near the image edges enables the user to rotate the image. Thusly, we
// look at where the layer is hit exactly and associate a TFGestureInfo denoting the selected operation with the
// touch label.
- (void)handleNewTouches:(NSSet*)touches
{
	[_touchIndicatorLayer processNewTouches:touches];
	[_tapRecognizer processNewTouches:touches];

	for (TFTouch* touch in touches) {	
		CGPoint hit = CGPointMake(touch.center.x, touch.center.y);
		CALayer* layer = [_imagesLayer hitTest:hit];
		if (nil != layer.name) {		
			[CATransaction begin];
			[CATransaction setValue:(id)kCFBooleanTrue  
							 forKey:kCATransactionDisableActions];
			// bring this layer to the front
			[_imagesLayer insertSublayer:layer above:[[_imagesLayer sublayers] lastObject]];
			[CATransaction commit];
			
			// if this touch has an even tap count > 2, we zoom or minimize the image (depending on its current state),
			// but take no further action
			NSInteger tapCount = [_tapRecognizer tapCountForLabel:touch.label];
			if (2 <= tapCount && 0 == tapCount%2) {
				[self _handleDoubleTapOnLayer:layer];
				continue;
			}
			
			// now let's find out where exactly this touch happened within the image. If it has its center
			// at a maximum of 1cm from the image edges, this is a "rotate" operation, otherwise, it's a
			// "drag" operation...
			CGPoint convertedHit = [layer convertPoint:hit fromLayer:_imagesLayer];
			
			// Get the minimum distance from the edges
			CGFloat minDist = [TFGeometry minimumDistanceFromEdgesOfPoint:convertedHit insideBox:[layer bounds]];
			
			TFGestureInfo* opInfo = [TFGestureInfo info];
			if (minDist <= ROTATION_AREA_BORDER_CENTIMETER_WIDTH*pixelsPerCentimeter)
				opInfo.type = TouchOperationRotate;
			else
				opInfo.type = TouchOperationDrag;
			
			[_trackedTouches setObject:layer forLabel:touch.label];
			[_operations setObject:opInfo forKey:touch.label];
		}
	}
}

// For each layer, we check which updated touches are associated with it conveniently by using a set intersection
// operation. Next, we use a gesture recognizer to see if a zoom/pinch gesture is being made. If yes, we zoom the
// image. If there's no zoom/pinch gesture happening, we do the operation that we assigned to this touch when it
// was first encountered (in handleNewTouches:)
- (void)handleUpdatedTouches:(NSSet*)touches
{
	[_touchIndicatorLayer processUpdatedTouches:touches];

	for (CALayer* layer in [_trackedTouches allObjects]) {
		NSSet* layerTouches = [_trackedTouches touchesForObject:layer intersectingSetOfTouches:touches];
				
		[_zoomRecognizer processUpdatedTouches:layerTouches];
		NSDictionary* zoomGestures = [_zoomRecognizer recognizedGestures];
		[_zoomRecognizer clearRecognizedGestures];
				
		if ([zoomGestures count] > 0) {
			TFLabeledTouchSet* zoomTouches = [[zoomGestures allKeys] objectAtIndex:0];
			TFGestureInfo* zoomGesture = [zoomGestures objectForKey:zoomTouches];
															
			if (TFGestureTypeZoomPinch == zoomGesture.type) {
				CGFloat factor = [[zoomGesture.parameters objectForKey:TFZoomPinchRecognizerParamPixels] floatValue];
				factor *= (TFGestureSubtypePinch == zoomGesture.subtype) ? -1.0f : 1.0f;
				factor *= ZOOM_SCREEN_PIXELS_TO_SCALE_FACTOR;
																																				
				CATransform3D transform = CATransform3DScale(layer.transform, 1.0f+factor, 1.0f+factor, 1.0);
				
				[CATransaction begin];
				[CATransaction setValue:[NSNumber numberWithFloat:0.0f]
								 forKey:kCATransactionAnimationDuration];
				layer.transform = transform;
				[CATransaction commit];
			}
		} else if ([layerTouches count] == 1) {
			TFTouch* touch = [[TFLabeledTouchSet setWithSet:layerTouches] anyDeterminateTouch];
						
			TFGestureInfo* opInfo = [_operations objectForKey:touch.label];
			switch (opInfo.type) {
				case TouchOperationDrag: {
					CGPoint pos = layer.position;
					pos.x += touch.center.x - touch.previousCenter.x;
					pos.y += touch.center.y - touch.previousCenter.y;
					
					[CATransaction begin];
					[CATransaction setValue:[NSNumber numberWithFloat:0.0f]
									 forKey:kCATransactionAnimationDuration];
					layer.position = pos;
					[CATransaction commit];
					break;
				}
				case TouchOperationRotate: {
					CGPoint tC = [layer convertPoint:CGPointMake(touch.center.x, touch.center.y) fromLayer:_imagesLayer];
					CGPoint tO = [layer convertPoint:CGPointMake(touch.previousCenter.x, touch.previousCenter.y) fromLayer:_imagesLayer];
					
					TFWindingDirection r =
						[TFGeometry windingDirectionOfVectorBetweenPoint:tO andPoint:tC relativeToBox:[layer bounds]];
					
					CGFloat xDist = ABS(touch.center.x - touch.previousCenter.x);
					CGFloat yDist = ABS(touch.center.y - touch.previousCenter.y);
					CGFloat degAngle = (xDist + yDist) * ((r == TFWindingDirectionCCW) ? 1.0 : -1.0) *
											MOTION_DISPLACEMENT_TO_ROTATION_ANGLE_DEGREES_FACTOR;
					CGFloat radAngle = pi/180.0f * degAngle;
					CATransform3D transform = CATransform3DRotate(layer.transform, radAngle, 0.0f, 0.0f, 1.0f);
					
					[CATransaction begin];
					[CATransaction setValue:[NSNumber numberWithFloat:0.0f]
									 forKey:kCATransactionAnimationDuration];
					layer.transform = transform;
					[CATransaction commit];
					break;
				}
			}
		}
	}
}

// When a touch disappears, we remove it from our internal stores.
- (void)handleEndedTouches:(NSSet*)touches
{
	[_touchIndicatorLayer processEndedTouches:touches];
	[_tapRecognizer processEndedTouches:touches];

	for (TFTouch* touch in touches) {
		[_operations removeObjectForKey:touch.label];
		[_trackedTouches removeObjectForLabel:touch.label];
	}
}

- (void)_setDefaults
{
	if (_isSetUp)
		return;
	
	_isSetUp = YES;
	
	// setting up our internal data structures and the zoom/pinch gesture recognizer
	_operations = [[NSMutableDictionary alloc] init];
	_trackedTouches = [[TFTouchLabelObjectAssociator alloc] init];
	_zoomRecognizer = [[TFZoomPinchRecognizer alloc] init];
	_zoomRecognizer.angleTolerance = ZOOM_RECOGNIZER_ANGLE_TOLERANCE;
	_zoomRecognizer.minDistance = ZOOM_RECOGNIZER_MIN_PIXEL_DISTANCE;
	_tapRecognizer = [[TFTapRecognizer alloc] init];
	_tapRecognizer.maxTapTime = TAP_RECOGNIZER_MAX_TAP_TIME;
	_tapRecognizer.maxTapDistance = TAP_RECOGNIZER_MAX_DISTANCE;
	
	CALayer* rootLayer = [CALayer layer];
	rootLayer.backgroundColor = CGColorGetConstantColor(kCGColorBlack);
	
	[self setLayer:rootLayer];
	[self setWantsLayer:YES];
	
	_imagesLayer = [[CALayer layer] retain];
	_imagesLayer.frame = rootLayer.frame;
	
	// TFCATouchIndicationLayer is a simple class that we can create with a CALayer. It'll show nice "touch
	// points" for each touch, much like Apple's iPhone Simulator. This is convenient for testing.
	CALayer* indicatorLayer = [CALayer layer];
	indicatorLayer.frame = rootLayer.frame;
	_touchIndicatorLayer = [[TFCATouchIndicationLayer alloc] initWithLayer:indicatorLayer];
	
	[rootLayer addSublayer:_imagesLayer];
	[rootLayer insertSublayer:indicatorLayer above:_imagesLayer];
}

- (CALayer*)_imageLayerWithName:(NSString*)name
{
	CALayer* layer = [CALayer layer];
	
	NSImage* image = [NSImage imageNamed:name];
	CGImageRef imageRef = NULL;
    CGImageSourceRef sourceRef;
	
    sourceRef = CGImageSourceCreateWithData((CFDataRef)[image TIFFRepresentation], NULL);
    if(sourceRef) {
        imageRef = CGImageSourceCreateImageAtIndex(sourceRef, 0, NULL);
        CFRelease(sourceRef);
    }
	
	layer.contents = (id)imageRef;
	CGImageRelease(imageRef);
	
	CGRect frame = layer.frame;
	frame.size = NSSizeToCGSize([image size]);
	layer.frame = frame;
		
    return layer;
}

- (void)_handleDoubleTapOnLayer:(CALayer*)layer
{
	CGRect rect = [layer frame];
	
	CGFloat newWidth = DOUBLE_TAP_ZOOMED_WIDTH;
	if (rect.size.width >= DOUBLE_TAP_ZOOMED_WIDTH)
		newWidth = DOUBLE_TAP_MINIMIZED_WIDTH;
	
	CGFloat scaleFactor = newWidth / rect.size.width;
	CATransform3D scale = CATransform3DScale(layer.transform, scaleFactor, scaleFactor, 1.0);
	
	[CATransaction begin];
	[CATransaction setValue:[NSNumber numberWithFloat:0.3f]
					 forKey:kCATransactionAnimationDuration];
	layer.transform = scale;
	[CATransaction commit];
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
