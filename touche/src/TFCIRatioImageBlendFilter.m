//
//  TFCIRatioImageBlendFilter.m
//  Touché
//
//  Created by Georg Kaindl on 31/1/08.
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

#import "TFCIRatioImageBlendFilter.h"

#import "TFIncludes.h"

static CIKernel* tFCIRatioImageBlendFilter = nil;

@implementation TFCIRatioImageBlendFilter

- (NSNumber*)inputRatio
{
	return [[inputRatio copy] autorelease];
}

- (void)setInputRatio:(NSNumber*)newVal
{
	float newRatio = [newVal floatValue];

	[newVal retain];
	[inputRatio release];

	if (newRatio > 1.0f)
		inputRatio = [[NSNumber alloc] initWithFloat:1.0f];
	else if (newRatio < 0.0f)
		inputRatio = [[NSNumber alloc] initWithFloat:0.0f];
	else
		inputRatio = [newVal copy];
	
	[newVal release];
}

+ (void)initialize
{
	[CIFilter registerFilterName:@"TFCIRatioImageBlendFilter"
					 constructor:self
				 classAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
								  TFLocalizedString(@"RatioImageBlendFilterName", @"Blends two pictures by combining according pixels from both with a given ratio."),
								  kCIAttributeFilterDisplayName,
								  [NSArray arrayWithObjects:
								   kCICategoryVideo, kCICategoryStylize,
								   kCICategoryStillImage, kCICategoryInterlaced,
								   kCICategoryNonSquarePixels, kCICategoryCompositeOperation,
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
	
	if (nil == tFCIRatioImageBlendFilter) {
		NSString*	kernelCode = [NSString stringWithContentsOfFile:
								  [[NSBundle bundleForClass:[self class]]
								   pathForResource:@"TFCIRatioImageBlendFilter" ofType:@"cikernel"]
														 encoding:NSUTF8StringEncoding
															error:NULL];
		
		NSArray *kernels = [CIKernel kernelsWithString:kernelCode];
		
		tFCIRatioImageBlendFilter = [[kernels objectAtIndex:0] retain];
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
			 [NSNumber numberWithDouble: 0.0],	kCIAttributeMin,
			 [NSNumber numberWithDouble: 1.0],	kCIAttributeMax,
			 [NSNumber numberWithDouble: 0.0],	kCIAttributeSliderMin,
			 [NSNumber numberWithDouble: 1.0],	kCIAttributeSliderMax,
			 [NSNumber numberWithDouble: 0.5],	kCIAttributeDefault,
			 kCIAttributeTypeScalar,			kCIAttributeType,
			 nil],								@"inputRatio",
			 
			[NSDictionary dictionaryWithObjectsAndKeys:
			 [CIImage class],					kCIAttributeClass,
			 nil],								@"inputImage",
			 
			[NSDictionary dictionaryWithObjectsAndKeys:
			[CIImage class],					kCIAttributeClass,
			 nil],								@"inputImage2",
		nil];
}

- (CIImage*)outputImage
{
	if (nil == inputImage2)
		return inputImage;
	else if (nil == inputImage)
		return inputImage2;
	
	CGRect img1Extent = [inputImage extent];
	CGRect img2Extent = [inputImage2 extent];
	
	if (img1Extent.size.width != img2Extent.size.width || img1Extent.size.height != img2Extent.size.height)
		return inputImage;
	
	CISampler *src1 = [CISampler samplerWithImage:inputImage options:
					  [NSDictionary dictionaryWithObjectsAndKeys:kCISamplerFilterNearest, kCISamplerFilterMode, nil]];
	
	CISampler *src2 = [CISampler samplerWithImage:inputImage2 options:
					 [NSDictionary dictionaryWithObjectsAndKeys:kCISamplerFilterNearest, kCISamplerFilterMode, nil]];
	
	return [self apply:tFCIRatioImageBlendFilter, src1, src2, inputRatio, kCIApplyOptionDefinition, [src1 definition], nil];
}

@end
