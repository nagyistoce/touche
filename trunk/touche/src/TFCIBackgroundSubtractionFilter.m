//
//  TFCIBackgroundSubtractionFilter.m
//  Touché
//
//  Created by Georg Kaindl on 9/1/08.
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

#import "TFCIBackgroundSubtractionFilter.h"
#import "TFCIRatioImageBlendFilter.h"

#import "TFIncludes.h"

#define	FORCED_BGIMAGE_AFTER_FRAMES		(30.0f)

static NSArray* tFCIBackgroundSubtractionFilters = nil;

@implementation TFCIBackgroundSubtractionFilter

@synthesize isEnabled;
@synthesize useBlending;
@synthesize blendingRatio;
@synthesize forceBackgroundPictureAfterEnabling;
@synthesize forceNextBackgroundPictureUpdate;
@synthesize allowBackgroundPictureUpdate;
@synthesize doSmartSubtraction;
@synthesize smartSubtractionLuminanceThreshold;

- (void)setIsEnabled:(BOOL)newVal
{
	if (newVal != isEnabled) {
		isEnabled = newVal;
		
		_framesProcessedSinceEnabled = 0.0f;
	}
}

- (void)setBlendingRatio:(CGFloat)newRatio
{
	if (newRatio > 1.0f)
		blendingRatio = 1.0f;
	else if (newRatio < 0.0f)
		blendingRatio = 0.0f;
	else
		blendingRatio = newRatio;
	
	@synchronized (self) {
		[_blendingFilter setValue:[NSNumber numberWithFloat:blendingRatio] forKey:@"inputRatio"];
	}
}

- (void)assignBackgroundImage:(CIImage*)newImage
{
	if (!isEnabled || (!forceNextBackgroundPictureUpdate && !allowBackgroundPictureUpdate && nil != [_backgroundAccumulator image]))
		return;
	
	forceNextBackgroundPictureUpdate = NO;

	@synchronized(self) {
		CIImage* oldImage = [_backgroundAccumulator image];

		if (useBlending && nil != oldImage &&
				[oldImage extent].size.height == [newImage extent].size.height &&
				[oldImage extent].size.width == [newImage extent].size.width) {
							
			[_blendingFilter setValue:newImage forKey:@"inputImage"];
			[_blendingFilter setValue:oldImage forKey:@"inputImage2"];
			
			[_backgroundAccumulator clear];
			[_backgroundAccumulator setImage:[_blendingFilter valueForKey:@"outputImage"]];
		} else {
			if (nil != oldImage && [oldImage extent].size.height == [newImage extent].size.height &&
				[oldImage extent].size.width == [newImage extent].size.width) {
					[_backgroundAccumulator clear];
					[_backgroundAccumulator setImage:newImage];
			} else {
				[_backgroundAccumulator release];
				_backgroundAccumulator = [[CIImageAccumulator alloc] initWithExtent:[newImage extent] format:kCIFormatARGB8];
				[_backgroundAccumulator setImage:newImage];
			}
		}
	}
}

- (void)clearBackgroundImage
{
	@synchronized (self) {
		[_backgroundAccumulator clear];
		[_backgroundAccumulator release];
		_backgroundAccumulator = nil;
	}
}

+ (void)initialize
{
	// initialize the blending filter
	[TFCIRatioImageBlendFilter class];

	[CIFilter registerFilterName:@"TFCIBackgroundSubtractionFilter"
					 constructor:self
				 classAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
								  TFLocalizedString(@"BackgroundSubtractionName", @"Subtracts a backround from an image, ignoring alpha and capping each result pixel at 0,0,0"),
								  kCIAttributeFilterDisplayName,
								  [NSArray arrayWithObjects:
								   kCICategoryVideo, kCICategoryStylize,
								   kCICategoryReduction, kCICategoryStylize,
								   kCICategoryStillImage, kCICategoryInterlaced,
								   kCICategoryNonSquarePixels,
								   nil], kCIAttributeFilterCategories,
								  nil]
	 ];
}

- (void)dealloc
{
	[_blendingFilter release];
	[_backgroundAccumulator release];
	
	[super dealloc];
}

- (id)init
{
	if (nil == (self = [super init])) {
		[self release];
		return nil;
	}
	
	if (nil == tFCIBackgroundSubtractionFilters) {
		NSString*	kernelCode = [NSString stringWithContentsOfFile:
								  [[NSBundle bundleForClass:[self class]]
								   pathForResource:@"TFCIBackgroundSubtractionFilter" ofType:@"cikernel"]
														 encoding:NSUTF8StringEncoding
															error:NULL];
		
		tFCIBackgroundSubtractionFilters = [[CIKernel kernelsWithString:kernelCode] retain];
	}
	
	isEnabled = NO;
	useBlending = NO;
	forceBackgroundPictureAfterEnabling = YES;
	allowBackgroundPictureUpdate = YES;
	doSmartSubtraction = NO;
	smartSubtractionLuminanceThreshold = .4f;
	
	_blendingFilter = [CIFilter filterWithName:@"TFCIRatioImageBlendFilter"];
	[_blendingFilter setDefaults];
	[_blendingFilter retain];
	
	blendingRatio = [[_blendingFilter valueForKey:@"inputRatio"] floatValue];
	
	_backgroundAccumulator = nil;
	_framesProcessedSinceEnabled = 0.0f;
	
	return self;
}

+ (CIFilter *)filterWithName:(NSString *)name
{
	CIFilter  *filter = [[self alloc] init];
	
	return [filter autorelease];
}

- (CIImage*)outputImage
{	
	CIImage* retval = nil;
	
	@synchronized(self) {	
		if (isEnabled)
			_framesProcessedSinceEnabled++;
		
		CIImage* bgImage = [_backgroundAccumulator image];
		
		if (forceBackgroundPictureAfterEnabling && isEnabled && nil == bgImage &&
			_framesProcessedSinceEnabled > FORCED_BGIMAGE_AFTER_FRAMES)
			[self assignBackgroundImage:inputImage];
				
		if (!isEnabled || nil == bgImage)
			return inputImage;
						
		CGRect imgExtent = [inputImage extent];
		CGRect bgExtent = [bgImage extent];
		
		if (imgExtent.size.width != bgExtent.size.width || imgExtent.size.height != bgExtent.size.height)
			return inputImage;
		
		CISampler *src = [CISampler samplerWithImage:inputImage options:
						  [NSDictionary dictionaryWithObjectsAndKeys:kCISamplerFilterNearest, kCISamplerFilterMode, nil]];
		
		CISampler *bg = [CISampler samplerWithImage:bgImage options:
						  [NSDictionary dictionaryWithObjectsAndKeys:kCISamplerFilterNearest, kCISamplerFilterMode, nil]];
		
		if (doSmartSubtraction) {
			CIKernel* filterKernel = [tFCIBackgroundSubtractionFilters objectAtIndex:1];
			NSNumber* threshold = [NSNumber numberWithFloat:smartSubtractionLuminanceThreshold];
			
			retval = [self apply:filterKernel, src, bg, threshold, kCIApplyOptionDefinition, [src definition], nil];
		} else {
			CIKernel* filterKernel = [tFCIBackgroundSubtractionFilters objectAtIndex:0];
			
			retval = [self apply:filterKernel, src, bg, kCIApplyOptionDefinition, [src definition], nil];
		}
	}
	
	return retval;
}

@end
