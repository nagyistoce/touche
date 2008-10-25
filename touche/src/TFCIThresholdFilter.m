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

static CIKernel*	tfThresholdKernelFilter = nil;

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

	if (nil == tfThresholdKernelFilter) {
		NSString*	kernelCode = [NSString stringWithContentsOfFile:
			[[NSBundle bundleForClass:[self class]]
				pathForResource:@"TFCIThresholdFilter" ofType:@"cikernel"]];
		
		NSArray *kernels = [CIKernel kernelsWithString:kernelCode];
		
		tfThresholdKernelFilter = [[kernels objectAtIndex:0] retain];
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
			[NSNumber numberWithDouble: 0.0],	kCIAttributeMin,
			[NSNumber numberWithDouble: 1.0],	kCIAttributeMax,
			[NSNumber numberWithDouble: 0.0],	kCIAttributeSliderMin,
			[NSNumber numberWithDouble: 1.0],	kCIAttributeSliderMax,
			[NSNumber numberWithDouble: 0.8],	kCIAttributeDefault,
			kCIAttributeTypeScalar,				kCIAttributeType,
			nil],								@"inputThreshold",
			
		[NSDictionary dictionaryWithObjectsAndKeys:
			[CIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0],	kCIAttributeDefault,
			nil],														@"inputLowColor",
		
		[NSDictionary dictionaryWithObjectsAndKeys:
			[CIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0],	kCIAttributeDefault,
			nil],														@"inputHighColor",
	
		nil];
}

- (CIImage*)outputImage
{
	CISampler *src = [CISampler samplerWithImage:inputImage options:
						[NSDictionary dictionaryWithObjectsAndKeys:kCISamplerFilterNearest, kCISamplerFilterMode, nil]];
	
	return [self apply:tfThresholdKernelFilter, src, inputLowColor, inputHighColor,
					inputThreshold, kCIApplyOptionDefinition, [src definition], nil];
}

@end
