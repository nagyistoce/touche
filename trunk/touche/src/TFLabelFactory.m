//
//  TFLabelFactory.m
//  Touché
//
//  Created by Georg Kaindl on 21/12/07.
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

#import "TFLabelFactory.h"

#import "TFIncludes.h"
#import "TFBlobLabel.h"

#define		START_LABEL_AMOUNT	((NSUInteger)10)

@implementation TFLabelFactory

- (void)dealloc
{
	[_freeLabels release];
	[_usedLabels release];
	
	[super dealloc];
}

- (id)init
{
	if (!(self = [super init])) {
		[self release];
		return nil;
	}
	
	_freeLabels = [[NSMutableArray alloc] init];
	_usedLabels = [[NSMutableArray alloc] init];
	
	_curLabelAmount = START_LABEL_AMOUNT;
	
	NSUInteger i;
	for (i=0; i<_curLabelAmount; i++)
		[_freeLabels addObject:[TFBlobLabel labelWithInteger:i]];
				
	return self;
}

- (TFBlobLabel*)claimLabel
{
	TFBlobLabel* chosenLabel = nil;

	if ([_freeLabels count] > 0) {
		chosenLabel = [_freeLabels objectAtIndex:0];
		[_usedLabels addObject:chosenLabel];
		[_freeLabels removeObjectAtIndex:0];
	} else {
		// apparently, we ran out of labels, so we will create a new one...
		chosenLabel = [TFBlobLabel labelWithInteger:_curLabelAmount];
		_curLabelAmount++;
		
		[_usedLabels addObject:chosenLabel];
	}
	
	chosenLabel.isNew = YES;

	return chosenLabel;
}

- (void)freeLabel:(TFBlobLabel*)aLabel
{
	if (nil == aLabel || [aLabel isNilLabel] || ![_usedLabels containsObject:aLabel])
		return;
	
	[_freeLabels insertObject:aLabel atIndex:0];
	[_usedLabels removeObject:aLabel];
	
	aLabel.isNew = NO;
}

@end
