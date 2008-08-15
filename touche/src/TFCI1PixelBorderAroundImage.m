//
//  TFCI1PixelBorderAroundImage.m
//  Touché
//
//  Created by Georg Kaindl on 18/12/07.
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

#import "TFCI1PixelBorderAroundImage.h"

#import "TFIncludes.h"

static CIKernel*	tFCI1PixelBorderAroundImage = nil;

@implementation TFCI1PixelBorderAroundImage

+ (void)initialize
{
	[CIFilter registerFilterName:@"TFCI1PixelBorderAroundImage"
					 constructor:self
				 classAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
						TFLocalizedString(@"1PixelBorderFilterName", @"1-pixel border around an image"),
								  kCIAttributeFilterDisplayName,
						[NSArray arrayWithObjects:
							kCICategoryVideo, kCICategoryStylize,
							kCICategoryStillImage, kCICategoryInterlaced,
							kCICategoryNonSquarePixels,
							nil], kCIAttributeFilterCategories,
					nil]
				];
}

- (void)dealloc
{
	[super dealloc];
}

- (id)init
{
	if (nil == (self = [super init])) {
		[self release];
		return nil;
	}

	if (nil == tFCI1PixelBorderAroundImage) {
		NSString*	kernelCode = [NSString stringWithContentsOfFile:
			[[NSBundle bundleForClass:[self class]]
				pathForResource:@"TFCI1PixelBorderAroundImage" ofType:@"cikernel"]];
		
		NSArray *kernels = [CIKernel kernelsWithString:kernelCode];
		
		tFCI1PixelBorderAroundImage = [[kernels objectAtIndex:0] retain];
	}
	
	return self;
}

+ (CIFilter *)filterWithName: (NSString *)name
{
	CIFilter  *filter = [[self alloc] init];
		
	return [filter autorelease];
}

- (NSDictionary*)customAttributes
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSDictionary dictionaryWithObjectsAndKeys:
			[CIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0],	kCIAttributeDefault,
			nil],														@"inputBorderColor",
			[NSDictionary dictionaryWithObjectsAndKeys:
			 [CIImage class],					kCIAttributeClass,
			 nil],								@"inputImage",
		nil];
}

- (CIImage*)outputImage
{
	CISampler *src = [CISampler samplerWithImage:inputImage options:
						[NSDictionary dictionaryWithObjectsAndKeys:kCISamplerFilterNearest, kCISamplerFilterMode, nil]];
	CGRect e = [inputImage extent];
	
	return [self apply:tFCI1PixelBorderAroundImage, src, inputBorderColor, [CIVector vectorWithX:e.origin.x Y:e.origin.y Z:e.size.width W:e.size.height],
					kCIApplyOptionDefinition, [src definition], nil];
}

@end
