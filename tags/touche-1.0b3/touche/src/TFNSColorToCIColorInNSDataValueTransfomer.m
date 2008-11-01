//
//  TFNSColorToCIColorInNSDataValueTransfomer.m
//  Touche
//
//  Created by Georg Kaindl on 26/10/08.
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

#import "TFNSColorToCIColorInNSDataValueTransfomer.h"

#import <QuartzCore/CIColor.h>


NSString* TFNSColorToCIColorInNSDataValueTransfomerName	= @"TFNSColorToCIColorInNSDataValueTransfomer";

@implementation TFNSColorToCIColorInNSDataValueTransfomer

+ (void)initialize
{
	static BOOL wasHere = NO;
	
	if (!wasHere) {
		wasHere = YES;
		
		TFNSColorToCIColorInNSDataValueTransfomer* transformer = [[self alloc] init];
		[NSValueTransformer setValueTransformer:transformer
										forName:TFNSColorToCIColorInNSDataValueTransfomerName];
		[transformer release];
	}
}

+ (BOOL)allowsReverseTransformation
{
	return YES;
}

+ (Class)transformedValueClass
{
	return [NSData class];
}

- (id)transformedValue:(id)value
{
	id retval = nil;
	
	if ([value isKindOfClass:[NSData class]]) {
		CIColor* ciColor = [NSKeyedUnarchiver unarchiveObjectWithData:(NSData*)value];
		if ([ciColor isKindOfClass:[CIColor class]])
			retval = [NSColor colorWithCIColor:ciColor];
	}
		
	return retval;
}

- (id)reverseTransformedValue:(id)value
{
	id retval = nil;
	
	if ([value isKindOfClass:[NSColor class]]) {
		CIColor* ciColor = [[CIColor alloc] initWithColor:(NSColor*)value];
		retval = [NSKeyedArchiver archivedDataWithRootObject:ciColor];
		[ciColor release];
	}
	
	return retval;
}

@end
