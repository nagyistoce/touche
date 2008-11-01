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
	[_gaussianBlur release];
	_gaussianBlur = nil;
	
	[super dealloc];
}

- (id)init
{
	if (nil == (self = [super init])) {
		[self release];
		return nil;
	}
	
	_gaussianBlur = [[CIFilter filterWithName:@"CIGaussianBlur"] retain];
	[_gaussianBlur setDefaults];
	
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
	
	if (isEnabled) {
		[_gaussianBlur setValue:inputRadius forKey:@"inputRadius"];
		[_gaussianBlur setValue:inputImage forKey:@"inputImage"];
		outImg = [_gaussianBlur valueForKey:@"outputImage"];
	}
	
	return outImg;
}

@end
