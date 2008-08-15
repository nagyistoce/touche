//
//  TFCIMorphologicalOpenWith3x3ShapeFilter.m
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

#import "TFCIMorphologicalOpenWith3x3ShapeFilter.h"

#import "TFIncludes.h"


@implementation TFCIMorphologicalOpenWith3x3ShapeFilter

+ (void)initialize
{
	[CIFilter registerFilterName:@"TFCIMorphologicalOpenWith3x3ShapeFilter"
					 constructor:self
				 classAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
								  TFLocalizedString(@"3x3OpenName", @"3x3OpenName"),
								  kCIAttributeFilterDisplayName,
								  [NSArray arrayWithObjects:
								   kCICategoryVideo, kCICategoryReduction,
								   kCICategoryStylize, kCICategoryStillImage,
								   kCICategoryInterlaced, kCICategoryNonSquarePixels,
								   nil], kCIAttributeFilterCategories,
								  nil]
	 ];
}

- (CIImage*)outputImage
{
	CIImage* img = inputImage;
	if (nil == img)
		return nil;
	else if (!isEnabled || 0 >= [inputPasses intValue])
		return img;
		
	[_erode setValue:img forKey:@"inputImage"];
	img = [_erode valueForKey:@"outputImage"];
	
	[_dilate setValue:img forKey:@"inputImage"];
	img = [_dilate valueForKey:@"outputImage"];
	
	return img;
}

@end
