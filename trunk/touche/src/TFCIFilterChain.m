//
//  TFCIFilterChain.m
//  Touché
//
//  Created by Georg Kaindl on 15/12/07.
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

#import "TFCIFilterChain.h"

#import "TFIncludes.h"
#import "TFCIColorInversionFilter.h"
#import "TFCILuminanceThresholdFilter.h"
#import "TFCI1PixelBorderAroundImage.h"
#import "TFCIBackgroundSubtractionFilter.h"
#import "TFCIGaussianBlurFilter.h"
#import "TFCIContrastStretchFilter.h"
#import "TFCIGrayscalingFilter.h"
#import "TFCI3x3ErosionFilter.h"
#import "TFCI3x3DilationFilter.h"
#import "TFCIMorphologicalOpenWith3x3ShapeFilter.h"
#import "TFCIMorphologicalCloseWith3x3ShapeFilter.h"

@implementation TFCIFilterChain

@synthesize filters;
@synthesize renderOnCPU;

+ (void)initialize
{
	// register our custom core image filters:
	// this will call their +initialize method, which will do the registration
	[TFCILuminanceThresholdFilter class];
	[TFCI1PixelBorderAroundImage class];
	[TFCIBackgroundSubtractionFilter class];
	[TFCIGaussianBlurFilter class];
	[TFCIColorInversionFilter class];
	[TFCIContrastStretchFilter class];
	[TFCIGrayscalingFilter class];
	[TFCI3x3ErosionFilter class];
	[TFCI3x3DilationFilter class];
	[TFCIMorphologicalOpenWith3x3ShapeFilter class];
	[TFCIMorphologicalCloseWith3x3ShapeFilter class];
}

- (void)dealloc
{
	@synchronized (self) {
		[filters release];
		filters = nil;
	}
	
	[super dealloc];
}

- (id)init
{
	if (!(self = [super init])) {
		[self release];
		return nil;
	}
	
	filters = [[NSMutableArray alloc] init];
	renderOnCPU = YES;
		
	return self;
}

- (void)addFilter:(CIFilter *)filter
{
	if (nil == filter)
		return;
	
	[filters addObject:filter];
}

- (CIImage*)apply:(CIImage*)inputImage
{
	if (nil == inputImage)
		return nil;
	
	NSUInteger filterCount = [filters count];
	
	if (filterCount <= 0)
		return inputImage;
		
	[[filters objectAtIndex:0] setValue:inputImage forKey:@"inputImage"];
	
	NSUInteger i;
	for (i=1; i<filterCount; i++) {
		[[filters objectAtIndex:i] setValue:[[filters objectAtIndex:i-1] valueForKey:@"outputImage"]
									  forKey:@"inputImage"];
	}
	
	return [[filters lastObject] valueForKey:@"outputImage"];
}

@end
