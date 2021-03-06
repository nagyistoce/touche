//
//  TFCI3x3DilationFilter.m
//  Touche
//
//  Created by Georg Kaindl on 10/6/08.
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

#import "TFCI3x3DilationFilter.h"

#import "TFIncludes.h"


static NSArray*	tFCI3x3DilationFilterKernels = nil;

@implementation TFCI3x3DilationFilter

+ (void)initialize
{
	[CIFilter registerFilterName:@"TFCI3x3DilationFilter"
					 constructor:self
				 classAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
								  TFLocalizedString(@"3x3DilationName", @"3x3DilationName"),
								  kCIAttributeFilterDisplayName,
								  [NSArray arrayWithObjects:
								   kCICategoryVideo, kCICategoryReduction,
								   kCICategoryStylize, kCICategoryStillImage,
								   kCICategoryInterlaced, kCICategoryNonSquarePixels,
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
	
	if (nil == tFCI3x3DilationFilterKernels) {
		NSString*	kernelCode = [NSString stringWithContentsOfFile:
								  [[NSBundle bundleForClass:[self class]]
								   pathForResource:@"TFCI3x3DilationFilter" ofType:@"cikernel"]
														 encoding:NSUTF8StringEncoding
															error:NULL];
		
		tFCI3x3DilationFilterKernels = [[CIKernel kernelsWithString:kernelCode] retain];
		
		for (CIKernel* kernel in tFCI3x3DilationFilterKernels)
			[kernel setROISelector:@selector(regionOf:destRect:)];
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
			 [NSNumber numberWithFloat:0.0f],	kCIAttributeMin,
			 [NSNumber numberWithFloat:100.0f],	kCIAttributeMax,
			 [NSNumber numberWithFloat:0.0f],	kCIAttributeSliderMin,
			 [NSNumber numberWithFloat:100.0f],	kCIAttributeSliderMax,
			 [NSNumber numberWithFloat:1.0f],	kCIAttributeDefault,
			 kCIAttributeType,					kCIAttributeTypeCount,
			 kCIAttributeTypeScalar,			kCIAttributeType,
			 nil],								@"inputPasses",
			 
			[NSDictionary dictionaryWithObjectsAndKeys:
			 [NSNumber numberWithFloat:TFCI3x3DilationFilterShapeTypeMin],	kCIAttributeMin,
			 [NSNumber numberWithFloat:TFCI3x3DilationFilterShapeTypeMax],	kCIAttributeMax,
			 [NSNumber numberWithFloat:TFCI3x3DilationFilterShapeTypeMin],	kCIAttributeSliderMin,
			 [NSNumber numberWithFloat:TFCI3x3DilationFilterShapeTypeMax],	kCIAttributeSliderMax,
			 [NSNumber numberWithFloat:TFCI3x3DilationFilterShapeSquare],	kCIAttributeDefault,
			 kCIAttributeTypeInteger,			kCIAttributeType,
			 nil],								@"inputShapeType",
			 
			[NSDictionary dictionaryWithObjectsAndKeys:
			 [CIImage class],					kCIAttributeClass,
			 nil],								@"inputImage",
			
			nil];
}

- (CGRect)regionOf:(int)samplerIndex destRect:(CGRect)r
{
	return CGRectInset(r, -1.0f, -1.0f);
}

- (CIImage*)outputImage
{
	CISampler* sampler = nil;
	CIImage* img = inputImage;
	int c = [inputPasses intValue];
	TFCI3x3DilationFilterShapeType t = [inputShapeType intValue];
	CIKernel* kernel = [tFCI3x3DilationFilterKernels objectAtIndex:t];
		
	while (c-- > 0) {
		sampler = [CISampler samplerWithImage:img options:
				   [NSDictionary dictionaryWithObjectsAndKeys:kCISamplerFilterNearest, kCISamplerFilterMode,
					kCISamplerWrapClamp, kCISamplerWrapMode,
					nil]];
		
		img = [self apply:kernel, sampler, kCIApplyOptionDefinition, [CIFilterShape shapeWithRect:[img extent]], nil];
	}
	
	return img;
}

@end
