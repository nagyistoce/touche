//
//  TFCIThresholdFilter.m
//  Touché
//
//  Created by Georg Kaindl on 14/12/07.
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

#import "TFCIThresholdFilter.h"

#import "TFIncludes.h"

static NSArray*	tfThresholdKernelFilters = nil;

@implementation TFCIThresholdFilter

+ (void)initialize
{
	[CIFilter registerFilterName:@"TFCIThresholdFilter"
					 constructor:self
				 classAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
						TFLocalizedString(@"ThresholdName", @"Thresholding filter (luminance or color distance)"),
								  kCIAttributeFilterDisplayName,
						[NSArray arrayWithObjects:
							kCICategoryColorAdjustment, kCICategoryColorEffect,
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

	if (nil == tfThresholdKernelFilters) {
		NSString*	kernelCode = [NSString stringWithContentsOfFile:
			[[NSBundle bundleForClass:[self class]]
				pathForResource:@"TFCIThresholdFilter" ofType:@"cikernel"]];
		
		tfThresholdKernelFilters = [[CIKernel kernelsWithString:kernelCode] retain];		
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
			 [CIImage class],					kCIAttributeClass,
			 nil],								@"inputImage",

		[NSDictionary dictionaryWithObjectsAndKeys:
		 [CIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0],	kCIAttributeDefault,
		 nil],														@"inputLowColor",
		
		[NSDictionary dictionaryWithObjectsAndKeys:
		 [CIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0],	kCIAttributeDefault,
		 nil],														@"inputHighColor",

		[NSDictionary dictionaryWithObjectsAndKeys:
		 [NSNumber numberWithFloat:TFCIThresholdFilterTypeMin],	kCIAttributeMin,
		 [NSNumber numberWithFloat:TFCIThresholdFilterTypeMax],	kCIAttributeMax,
		 [NSNumber numberWithFloat:TFCIThresholdFilterTypeMin],	kCIAttributeSliderMin,
		 [NSNumber numberWithFloat:TFCIThresholdFilterTypeMax],	kCIAttributeSliderMax,
		 [NSNumber numberWithFloat:TFCIThresholdFilterTypeLuminance], kCIAttributeDefault,
		 kCIAttributeTypeInteger,			kCIAttributeType,
		 nil],								@"inputMethodType",

		[NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithDouble: 0.0],	kCIAttributeMin,
			[NSNumber numberWithDouble: 1.0],	kCIAttributeMax,
			[NSNumber numberWithDouble: 0.0],	kCIAttributeSliderMin,
			[NSNumber numberWithDouble: 1.0],	kCIAttributeSliderMax,
			[NSNumber numberWithDouble: 0.8],	kCIAttributeDefault,
			kCIAttributeTypeScalar,				kCIAttributeType,
			nil],								@"inputLuminanceThreshold",
		
		[NSDictionary dictionaryWithObjectsAndKeys:
		 [CIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0],	kCIAttributeDefault,
		 nil],														@"inputTargetColor",

		[NSDictionary dictionaryWithObjectsAndKeys:
		 [NSNumber numberWithDouble: 0.0],	kCIAttributeMin,
		 [NSNumber numberWithDouble: 1.0],	kCIAttributeMax,
		 [NSNumber numberWithDouble: 0.0],	kCIAttributeSliderMin,
		 [NSNumber numberWithDouble: 1.0],	kCIAttributeSliderMax,
		 [NSNumber numberWithDouble: 0.1],	kCIAttributeDefault,
		 kCIAttributeTypeScalar,				kCIAttributeType,
		 nil],								@"inputColorDistanceThreshold",
		
		nil];
}

- (CIImage*)outputImage
{
	TFCIThresholdFilterType filterType = [inputMethodType integerValue];
	
	if (TFCIThresholdFilterTypeMin > filterType || TFCIThresholdFilterTypeMax < filterType)
		return inputImage;

	CISampler *src = [CISampler samplerWithImage:inputImage options:
						[NSDictionary dictionaryWithObjectsAndKeys:kCISamplerFilterNearest, kCISamplerFilterMode, nil]];
	
	CIImage* outputImage = inputImage;
	
	switch (filterType) {
		case TFCIThresholdFilterTypeLuminance: {
			CIKernel* kernel = [tfThresholdKernelFilters objectAtIndex:0];
			
			outputImage = [self apply:kernel, src, inputLowColor, inputHighColor,
									inputLuminanceThreshold, kCIApplyOptionDefinition, [src definition], nil];
			
			break;
		}
		
		case TFCIThresholdFilterTypeColorDistance: {
			CIKernel* kernel = [tfThresholdKernelFilters objectAtIndex:1];
			
			// 1.7321 = sqrt(3) = the max. RGB distance possible
			NSNumber* threshold = [NSNumber numberWithFloat:1.7321*[inputColorDistanceThreshold floatValue]];
			
			outputImage = [self apply:kernel, src, inputLowColor, inputHighColor, inputTargetColor,
						   threshold, kCIApplyOptionDefinition, [src definition], nil];
			
			break;
		}
	}
	
	return outputImage;
}

@end
