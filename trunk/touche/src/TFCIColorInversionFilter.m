//
//  TFCIColorInversionFilter.m
//  Touche
//
//  Created by Georg Kaindl on 26/8/08.
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

#import "TFCIColorInversionFilter.h"

#import "TFLocalization.h"


@implementation TFCIColorInversionFilter

@synthesize enabled;

+ (void)initialize
{
	[CIFilter registerFilterName:@"TFCIColorInversionFilter"
					 constructor:self
				 classAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
								  TFLocalizedString(@"ColorInvertFilterName",
													@"ColorInvertFilterName"),
								  kCIAttributeFilterDisplayName,
								  [NSArray arrayWithObjects:
								   kCICategoryVideo, kCICategoryBlur,
								   kCICategoryStillImage, kCICategoryNonSquarePixels,
								   kCICategoryColorEffect,
								   nil], kCIAttributeFilterCategories,
								  nil]
	 ];
}

- (void)dealloc
{
	[_colorInversionFilter release];
	_colorInversionFilter = nil;
	
	[super dealloc];
}

- (id)init
{
	if (nil == (self = [super init])) {
		[self release];
		return nil;
	}
	
	_colorInversionFilter = [[CIFilter filterWithName:@"CIColorInvert"] retain];
	[_colorInversionFilter setDefaults];
	
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
			
			nil];
}

- (CIImage*)outputImage
{
	CIImage* outImg = inputImage;
	
	if (enabled) {
		[_colorInversionFilter setValue:inputImage forKey:@"inputImage"];
		outImg = [_colorInversionFilter valueForKey:@"outputImage"];
	}
	
	return outImg;
}

@end
