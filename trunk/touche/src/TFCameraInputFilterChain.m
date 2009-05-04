//
//  TFCameraInputFilterChain.m
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

#import "TFCameraInputFilterChain.h"

#import "TFIncludes.h"
#import "TFCIBackgroundSubtractionFilter.h"

#define DEFAULT_TIME_BETWEEN_BG_IMAGE_ACQUISITION	((NSTimeInterval)5.0)

enum {
	TFCIFilterChainStageUnknown					=		-1,
	TFCIFilterChainStageUnfiltered				=		1,
	TFCIFilterChainStageColorInverted			=		2,
	TFCIFilterChainStageBackgroundSubtracted	=		3,
	TFCIFilterChainStageBlurred					=		4,
	TFCIFilterChainStageHighpass				=		5,
	TFCIFilterChainStageContrastStretched		=		6,
	TFCIFilterChainStageGrayscaleConverted		=		7,
	TFCIFilterChainStageThresholded				=		8,
	TFCIFilterChainStageMorphologicalOpen		=		9,
	TFCIFilterChainStageMorphologicalClose		=		10,
	TFCIFilterChainStageFinal					=		11
};

@implementation TFCameraInputFilterChain

@synthesize timeBetweenBackgroundFrameAcquisition;

- (void)dealloc
{
	[[filters objectAtIndex:0] removeObserver:self
								   forKeyPath:@"enabled"];
	[[filters objectAtIndex:1] removeObserver:self
								   forKeyPath:@"isEnabled"];
	[[filters objectAtIndex:1] removeObserver:self
								   forKeyPath:@"useBlending"];
	
	[super dealloc];
}

- (id)init
{
	if (!(self = [super init])) {
		[self release];
		return nil;
	}
	
	timeBetweenBackgroundFrameAcquisition = DEFAULT_TIME_BETWEEN_BG_IMAGE_ACQUISITION;
	[self resetBackgroundAcquisitionTiming];
	
	// If the user wants to track dark blobs in front of a bright background, we have the
	// color inversion filter
	CIFilter* filter = [CIFilter filterWithName:@"TFCIColorInversionFilter"];
	[filter setDefaults];
	[self addFilter:filter];
	
	[filter addObserver:self
			 forKeyPath:@"enabled"
				options:NSKeyValueObservingOptionNew
				context:NULL];
	
	// This enables background subtraction if a background image gets set
	filter = [CIFilter filterWithName:@"TFCIBackgroundSubtractionFilter"];
	[filter setDefaults];
	[self addFilter:filter];
	
	[filter addObserver:self
			 forKeyPath:@"isEnabled"
				options:NSKeyValueObservingOptionNew
				context:NULL];
	
	[filter addObserver:self
			 forKeyPath:@"useBlending"
				options:NSKeyValueObservingOptionNew
				context:NULL];
	
	// No we blur the picture to reduce the noise, if necessary
	filter = [CIFilter filterWithName:@"TFCIGaussianBlurFilter"];
	[filter setDefaults];
	[self addFilter:filter];
	
	// Highpass filtering
	filter = [CIFilter filterWithName:@"TFCIHighpassFilter"];
	[filter setDefaults];
	[self addFilter:filter];
	
	// We can now stretch the contrast of the image so that we can use the full contrast range for our
	// thresholding...
	filter = [CIFilter filterWithName:@"TFCIContrastStretchFilter"];
	[filter setDefaults];
	[self addFilter:filter];
	
	// Now we're converting the picture to grayscale (if this is wanted), in order to reduce color noise that
	// might be introduced by the contrast stretcher amplifying debayering noise, etc.
	filter = [CIFilter filterWithName:@"TFCIGrayscalingFilter"];
	[filter setDefaults];
	[self addFilter:filter];
	
	// This does the thresholding to get a binary image (background = black, blobs = white)
	filter = [CIFilter filterWithName:@"TFCIThresholdFilter"];
	[filter setDefaults];
	[self addFilter:filter];
	
	// Morphological "open" operation on the thresholded picture in order to get rid of stray pixels
	filter = [CIFilter filterWithName:@"TFCIMorphologicalOpenWith3x3ShapeFilter"];
	[filter setDefaults];
	[self addFilter:filter];
	
	// Morphological "close" operation on the thresholded picture in order to emphasize weak blobs
	filter = [CIFilter filterWithName:@"TFCIMorphologicalCloseWith3x3ShapeFilter"];
	[filter setDefaults];
	[self addFilter:filter];
	
	// This draws a 1-pixel black border around the image to ensure that all blobs are closed
	// UPDATE: We now do this on the CPU after filter-rendering, which performs better.
	// See CIImage+MakeBitmaps (plus support files)
	/*filter = [CIFilter filterWithName:@"TFCI1PixelBorderAroundImage"];
	[filter setDefaults];
	[self addFilter:filter];*/
					
	return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([object isEqual:[filters objectAtIndex:1]]) {
		if ([keyPath isEqualToString:@"isEnabled"]) {
			if ([[change objectForKey:NSKeyValueChangeNewKey] boolValue])
				[self resetBackgroundAcquisitionTiming];
			else
				[self clearBackground];
		} else if ([keyPath isEqualToString:@"useBlending"]) {
			[self resetBackgroundAcquisitionTiming];
		}
	} else if ([object isEqual:[filters objectAtIndex:0]]) {
		if ([keyPath isEqualToString:@"enabled"]) {
			[self resetBackgroundAcquisitionTiming];
			[(TFCIBackgroundSubtractionFilter*)[filters objectAtIndex:1]
				setForceNextBackgroundPictureUpdate:YES];
		}
	}
}

- (CIImage*)currentImageForStage:(TFFilterChainStage)stage;
{
	if (nil == [[filters objectAtIndex:0] valueForKey:@"inputImage"])
		return nil;

	switch (stage) {
		case TFCIFilterChainStageUnfiltered:
			return [[filters objectAtIndex:0] valueForKey:@"inputImage"];
		case TFCIFilterChainStageColorInverted:
			return [[filters objectAtIndex:0] valueForKey:@"outputImage"];
		case TFCIFilterChainStageBackgroundSubtracted:
			return [[filters objectAtIndex:1] valueForKey:@"outputImage"];
		case TFCIFilterChainStageBlurred:
			return [[filters objectAtIndex:2] valueForKey:@"outputImage"];
		case TFCIFilterChainStageHighpass:
			return [[filters objectAtIndex:3] valueForKey:@"outputImage"];
		case TFCIFilterChainStageContrastStretched:
			return [[filters objectAtIndex:4] valueForKey:@"outputImage"];
		case TFCIFilterChainStageGrayscaleConverted:
			return [[filters objectAtIndex:5] valueForKey:@"outputImage"];
		case TFCIFilterChainStageThresholded:
			return [[filters objectAtIndex:6] valueForKey:@"outputImage"];
		case TFCIFilterChainStageMorphologicalOpen:
			return [[filters objectAtIndex:7] valueForKey:@"outputImage"];
		case TFCIFilterChainStageMorphologicalClose:
			return [[filters objectAtIndex:8] valueForKey:@"outputImage"];
		case TFCIFilterChainStageUnknown:
		case TFCIFilterChainStageFinal:
		default: {			
			return [[filters lastObject] valueForKey:@"outputImage"];
		}
	}
	
	// unreachable
	return nil;
}

- (NSDictionary*)filterChainStages
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
				TFLocalizedString(@"StageUnfiltered", @"StageUnfiltered"),
					[NSNumber numberWithInteger:TFCIFilterChainStageUnfiltered],
				TFLocalizedString(@"StageColorInverted", @"StageColorInverted"),
					[NSNumber numberWithInteger:TFCIFilterChainStageColorInverted],
				TFLocalizedString(@"StageBGSubtracted", @"StageBGSubtracted"),
					[NSNumber numberWithInteger:TFCIFilterChainStageBackgroundSubtracted],
				TFLocalizedString(@"StageBlur", @"StageBlur"),
					[NSNumber numberWithInteger:TFCIFilterChainStageBlurred],
				TFLocalizedString(@"StageHighpass", @"StageHighpass"),
					[NSNumber numberWithInteger:TFCIFilterChainStageHighpass],
				TFLocalizedString(@"StageContrastStretch", @"StageContrastStretch"),
					[NSNumber numberWithInteger:TFCIFilterChainStageContrastStretched],
				TFLocalizedString(@"StageGrayscale", @"StageGrayscale"),
					[NSNumber numberWithInteger:TFCIFilterChainStageGrayscaleConverted],
				TFLocalizedString(@"StageThresholding", @"StageThresholding"),
					[NSNumber numberWithInteger:TFCIFilterChainStageThresholded],
				TFLocalizedString(@"StageMorphOpen", @"StageMorphOpen"),
					[NSNumber numberWithInteger:TFCIFilterChainStageMorphologicalOpen],
				TFLocalizedString(@"StageMorphClose", @"StageMorphClose"),
					[NSNumber numberWithInteger:TFCIFilterChainStageMorphologicalClose],
				TFLocalizedString(@"StageFinal", @"StageFinal"),
					[NSNumber numberWithInteger:TFCIFilterChainStageFinal],
				nil];
				
}

- (void)updateBackgroundForSubtraction
{
	NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
	if (now - _lastBackgroundImageAcquisitionTime > timeBetweenBackgroundFrameAcquisition) {
		[(TFCIBackgroundSubtractionFilter*)[filters objectAtIndex:1] assignBackgroundImage:
			[[filters objectAtIndex:0] valueForKey:@"outputImage"]];
		
		_lastBackgroundImageAcquisitionTime = now;
	}
}

- (void)clearBackground
{
	[(TFCIBackgroundSubtractionFilter*)[filters objectAtIndex:1] clearBackgroundImage];
}

- (void)resetBackgroundAcquisitionTiming
{
	_lastBackgroundImageAcquisitionTime = [[NSDate distantPast] timeIntervalSinceNow];
}

@end
