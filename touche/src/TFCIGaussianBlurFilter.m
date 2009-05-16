//
//  TFCIGaussianBlurFilter.m
//  Touche
//
//  Created by Georg Kaindl on 14/7/08.
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

#import "TFCIGaussianBlurFilter.h"

#import "TFLocalization.h"


typedef enum {
	TFBlurTypeGaussian,
	TFBlurTypeCheat
} _TFBlurType;

@implementation TFCIGaussianBlurFilter

@synthesize isEnabled;

+ (void)initialize
{
	[CIFilter registerFilterName:@"TFCIGaussianBlurFilter"
					 constructor:self
				 classAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
								  TFLocalizedString(@"GaussianFilterName", @"Gaussian Blur"),
								  kCIAttributeFilterDisplayName,
								  [NSArray arrayWithObjects:
								   kCICategoryVideo, kCICategoryBlur,
								   kCICategoryStillImage, kCICategoryNonSquarePixels,
								   nil], kCIAttributeFilterCategories,
								  nil]
	 ];
}

- (void)dealloc
{
	[_blurFilter release];
	_blurFilter = nil;
	
	[super dealloc];
}

- (id)init
{
	if (nil == (self = [super init])) {
		[self release];
		return nil;
	}
	
	// CICheatBlur is fast, but unofficial, so we try to instantiate it, but if that
	// fails, we fall back to a regular public CIGaussianBlur.
	self->_blurFilter = [[CIFilter filterWithName:@"CICheatBlur"] retain];
	self->_blurType = TFBlurTypeCheat;
	
	if (nil == _blurFilter) {
		self->_blurFilter = [[CIFilter filterWithName:@"CIGaussianBlur"] retain];
		self->_blurType = TFBlurTypeGaussian;
	}
	
	[self->_blurFilter setDefaults];
	
	self->_blurRadiusMultiplier = 1.0;
	switch (self->_blurType) {
		case TFBlurTypeCheat:
			self->_blurRadiusMultiplier = 1.5;
			break;
		default:
			self->_blurRadiusMultiplier = 1.0;
			break;
	}
	
	self->_prevRadius = -1.0;
	
	return self;
}

+ (CIFilter *)filterWithName:(NSString *)name
{
	CIFilter  *filter = [[self alloc] init];
	
	return [filter autorelease];
}

- (NSDictionary*)customAttributes
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			
			[NSDictionary dictionaryWithObjectsAndKeys:
			 [NSNumber numberWithDouble:0.0],		kCIAttributeMin,
			 [NSNumber numberWithDouble:20.0],		kCIAttributeMax,
			 [NSNumber numberWithDouble:0.0],		kCIAttributeSliderMin,
			 [NSNumber numberWithDouble:20.0],		kCIAttributeSliderMax,
			 [NSNumber numberWithDouble:0.0],		kCIAttributeDefault,
			 [NSNumber numberWithDouble:0.0],		kCIAttributeIdentity,
			 kCIAttributeTypeScalar,			kCIAttributeType,
			 nil],								@"inputRadius",
			
			[NSDictionary dictionaryWithObjectsAndKeys:
			 [CIImage class],					kCIAttributeClass,
			 nil],								@"inputImage",
			
			nil];
}

- (CIImage*)outputImage
{
	CIImage* outImg = inputImage;
	
	if (isEnabled)
		outImg = [self blurImage:inputImage withBlurRadius:[inputRadius doubleValue]];
	
	return outImg;
}

// it's faster to call this directly rather than to use the filter approach, so we
// provide this method for performance reasons
- (CIImage*)blurImage:(CIImage*)image withBlurRadius:(double)radius
{
	CIImage* outImg = nil;
	
	if (radius != self->_prevRadius || self->_prevRadius < 0.0) {
		NSString* key = nil;
		switch(self->_blurType) {
			case TFBlurTypeCheat:
				key = @"inputAmount";
				// CICheatBlur crashes when the amount is 0
				if (radius < 0.01)
					radius = 0.01;
				break;
			case TFBlurTypeGaussian:
				key = @"inputRadius";
				break;
			default:
				break;
		}
		
		if (nil != key)
			[_blurFilter setValue:[NSNumber numberWithDouble:radius * self->_blurRadiusMultiplier] forKey:key];
		
		self->_prevRadius = radius;			
	}
	
	[_blurFilter setValue:image forKey:@"inputImage"];
	outImg = [_blurFilter valueForKey:@"outputImage"];

	return outImg;
}

@end
