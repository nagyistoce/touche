//
//  TFCIErosionDilationComboFilter.m
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

#import "TFCIErosionDilationComboFilter.h"

#import "TFIncludes.h"
#import "TFCI3x3ErosionFilter.h"
#import "TFCI3x3DilationFilter.h"


@implementation TFCIErosionDilationComboFilter

@synthesize isEnabled;

- (void)dealloc
{
	[self removeObserver:self forKeyPath:@"inputPasses"];
	[self removeObserver:self forKeyPath:@"inputShapeType"];

	[_erode release];
	_erode = nil;
	
	[_dilate release];
	_dilate = nil;
		
	[super dealloc];
}

- (id)init
{
	if (nil == (self = [super init])) {
		[self release];
		return nil;
	}
	
	_erode = [[TFCI3x3ErosionFilter alloc] init];
	[_erode setDefaults];
	_dilate = [[TFCI3x3DilationFilter alloc] init];
	[_dilate setDefaults];
	
	if (nil == _erode || nil == _dilate) {
		[self release];
		return nil;
	}
	
	isEnabled = NO;
	
	[self addObserver:self
		   forKeyPath:@"inputPasses"
			  options:NSKeyValueObservingOptionNew
			  context:NULL];
	
	[self addObserver:self
		   forKeyPath:@"inputShapeType"
			  options:NSKeyValueObservingOptionNew
			  context:NULL];
	
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
			 [NSNumber numberWithFloat:0.0f],	kCIAttributeMin,
			 [NSNumber numberWithFloat:100.0f],	kCIAttributeMax,
			 [NSNumber numberWithFloat:0.0f],	kCIAttributeSliderMin,
			 [NSNumber numberWithFloat:100.0f],	kCIAttributeSliderMax,
			 [NSNumber numberWithFloat:1.0f],	kCIAttributeDefault,
			 kCIAttributeType,					kCIAttributeTypeCount,
			 kCIAttributeTypeScalar,			kCIAttributeType,
			 nil],								@"inputPasses",
			 
			[NSDictionary dictionaryWithObjectsAndKeys:
			 [NSNumber numberWithFloat:TFCI3x3ErosionDilationFilterShapeTypeMin],	kCIAttributeMin,
			 [NSNumber numberWithFloat:TFCI3x3ErosionDilationFilterShapeTypeMax],	kCIAttributeMax,
			 [NSNumber numberWithFloat:TFCI3x3ErosionDilationFilterShapeTypeMin],	kCIAttributeSliderMin,
			 [NSNumber numberWithFloat:TFCI3x3ErosionDilationFilterShapeTypeMax],	kCIAttributeSliderMax,
			 [NSNumber numberWithFloat:TFCI3x3ErosionDilationFilterShapeSquare],	kCIAttributeDefault,
			 kCIAttributeTypeInteger,			kCIAttributeType,
			 nil],								@"inputShapeType",
			
			[NSDictionary dictionaryWithObjectsAndKeys:
			 [CIImage class],					kCIAttributeClass,
			 nil],								@"inputImage",
			
			nil];
}

- (CIImage*)outputImage
{
	return nil;
}

- (void)inputPassesDidChange:(NSNumber*)newPasses
{
	[_erode setValue:newPasses forKey:@"inputPasses"];
	[_dilate setValue:newPasses forKey:@"inputPasses"];
}

- (void)inputShapeTypeDidChange:(NSNumber*)newShapeType
{
	[_erode setValue:newShapeType forKey:@"inputShapeType"];
	[_dilate setValue:newShapeType forKey:@"inputShapeType"];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
	if ([keyPath isEqualToString:@"inputPasses"] && object == self)
		[self inputPassesDidChange:[change objectForKey:NSKeyValueChangeNewKey]];
	else if ([keyPath isEqualToString:@"inputShapeType"] && object == self)
		[self inputShapeTypeDidChange:[change objectForKey:NSKeyValueChangeNewKey]];
	else
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


@end
