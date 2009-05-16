//
//  TFCIHighpassFilter.m
//  Touche
//
//  Created by Georg Kaindl on 28/4/09.
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

#import "TFCIHighpassFilter.h"

#import "TFIncludes.h"
#import "TFCIBlurFilter.h"


static CIKernel*	tfSubtractKernel = nil;

@implementation TFCIHighpassFilter
@synthesize enabled;

+ (void)initialize
{
	[CIFilter registerFilterName:@"TFCIHighpassFilter"
					 constructor:self
				 classAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
								  TFLocalizedString(@"HighpassName", @"HighpassName"),
								  kCIAttributeFilterDisplayName,
								  [NSArray arrayWithObjects:
								   kCICategoryColorAdjustment, kCICategoryColorEffect,
								   kCICategoryVideo, kCICategoryReduction,
								   kCICategoryStillImage,
								   kCICategoryInterlaced, kCICategoryNonSquarePixels,
								   nil], kCIAttributeFilterCategories,
								  nil]
	 ];	 
}

- (void)dealloc
{
	[self->_blurFilter release];
	self->_blurFilter = nil;
	
	[super dealloc];
}

- (id)init
{
	if (nil == (self = [super init])) {
		[self release];
		return nil;
	}
	
	if (nil == tfSubtractKernel) {
		NSString*	kernelCode = [NSString stringWithContentsOfFile:
								  [[NSBundle bundleForClass:[self class]]
								   pathForResource:@"TFCIBackgroundSubtractionFilter" ofType:@"cikernel"]];
		
		tfSubtractKernel = [[[CIKernel kernelsWithString:kernelCode] objectAtIndex:0] retain];		
	}
	
	self->_blurFilter = [[CIFilter filterWithName:@"TFCIBlurFilter"] retain];
	[self->_blurFilter setDefaults];
	
	self.enabled = NO;
	
	[self setDefaults];
	
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
			 [CIImage class],					kCIAttributeClass,
			 nil],								@"inputImage",
			
			[NSDictionary dictionaryWithObjectsAndKeys:
			 [NSNumber numberWithDouble: 0.0],	kCIAttributeMin,
			 [NSNumber numberWithDouble: 50.0],	kCIAttributeMax,
			 [NSNumber numberWithDouble: 0.0],	kCIAttributeSliderMin,
			 [NSNumber numberWithDouble: 50.0],	kCIAttributeSliderMax,
			 [NSNumber numberWithDouble: 10.0],	kCIAttributeDefault,
			 kCIAttributeTypeScalar,			kCIAttributeType,
			 nil],								@"inputRadius",
			
			nil];
}

- (CIImage*)outputImage
{
	CIImage* outputImage = self->inputImage;
		
	if (self->enabled) {
		CIImage* blurredImage = [(TFCIBlurFilter*)self->_blurFilter blurImage:self->inputImage
																	   withBlurRadius:[inputRadius doubleValue]];
				
		CISampler* blurredSampler = [CISampler samplerWithImage:blurredImage options:
										[NSDictionary dictionaryWithObjectsAndKeys:kCISamplerFilterNearest,
																				   kCISamplerFilterMode,
																				   nil]];
		
		CISampler* originalSampler = [CISampler samplerWithImage:inputImage options:
									  [NSDictionary dictionaryWithObjectsAndKeys:kCISamplerFilterNearest,
																				 kCISamplerFilterMode,
																				 nil]];
		
		outputImage = [self apply:tfSubtractKernel, originalSampler, blurredSampler,
								kCIApplyOptionDefinition, [originalSampler definition], nil];
	}
	
	return outputImage;
}

@end
