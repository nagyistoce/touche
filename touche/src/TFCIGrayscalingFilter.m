//
//  TFCIGrayscalingFilter.m
//  Touche
//
//  Created by Georg Kaindl on 17/6/08.
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

#import "TFCIGrayscalingFilter.h"

#import "TFIncludes.h"


static NSArray*	tfCIGrayscalingFilterKernels = nil;

@implementation TFCIGrayscalingFilter

@synthesize isEnabled;

+ (void)initialize
{
	[CIFilter registerFilterName:@"TFCIGrayscalingFilter"
					 constructor:self
				 classAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
								  TFLocalizedString(@"GrayscalingFilterName", @"GrayscalingFilterName"),
								  kCIAttributeFilterDisplayName,
								  [NSArray arrayWithObjects:
								   kCICategoryReduction, kCICategoryColorEffect,
								   kCICategoryVideo, kCICategoryStylize,
								   kCICategoryStillImage, kCICategoryNonSquarePixels,
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
	
	if (nil == tfCIGrayscalingFilterKernels) {
		NSString*	kernelCode = [NSString stringWithContentsOfFile:
								  [[NSBundle bundleForClass:[self class]]
								   pathForResource:@"TFCIGrayscalingFilter" ofType:@"cikernel"]
														 encoding:NSUTF8StringEncoding
															error:NULL];
		
		NSArray *kernels = [CIKernel kernelsWithString:kernelCode];
		tfCIGrayscalingFilterKernels = [kernels retain];
	}
	
	isEnabled = NO;
	
	return self;
}

+ (CIFilter *)filterWithName:(NSString*)name
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
			 [NSNumber numberWithFloat:TFCIGrayscalingFilterMethodTypeMin],	kCIAttributeMin,
			 [NSNumber numberWithFloat:TFCIGrayscalingFilterMethodTypeMax],	kCIAttributeMax,
			 [NSNumber numberWithFloat:TFCIGrayscalingFilterMethodTypeMin],	kCIAttributeSliderMin,
			 [NSNumber numberWithFloat:TFCIGrayscalingFilterMethodTypeMax],	kCIAttributeSliderMax,
			 [NSNumber numberWithFloat:TFCIGrayscalingFilterMethodTypeMinComponent], kCIAttributeDefault,
			 kCIAttributeTypeInteger,			kCIAttributeType,
			 nil],								@"inputMethodType",			
			nil];
}

- (CIImage*)outputImage
{
	if (!isEnabled || nil == inputImage)
		return inputImage;
	
	CIKernel* kernel = nil;
	switch ([inputMethodType intValue]) {
		case TFCIGrayscalingFilterMethodTypeMinComponent:
			kernel = [tfCIGrayscalingFilterKernels objectAtIndex:0];
			break;
		case TFCIGrayscalingFilterMethodTypeComponentProduct:
			kernel = [tfCIGrayscalingFilterKernels objectAtIndex:1];
			break;
		case TFCIGrayscalingFilterMethodTypeComponentProductSquared:
			kernel = [tfCIGrayscalingFilterKernels objectAtIndex:2];
			break;
		default:
			break;
	}
	
	if (nil == kernel)
		return inputImage;
	
	CISampler *src = [CISampler samplerWithImage:inputImage options:
					  [NSDictionary dictionaryWithObjectsAndKeys:kCISamplerFilterNearest, kCISamplerFilterMode, nil]];
	
	return [self apply:kernel, src, kCIApplyOptionDefinition, [src definition], nil];
}

@end
