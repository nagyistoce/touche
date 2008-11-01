//
//  TFCombinadicIndices.m
//  Touché
//
//  Created by Georg Kaindl on 23/5/08.
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

#import "TFCombinadicIndices.h"

#import "TFIncludes.h"

@interface TFCombinadicIndices (PrivateMethods)
+ (float)_factorial:(NSUInteger)n;
+ (float)_gammaLn:(float)xx;
@end

#define	FACT(x)		([[self class] _factorial:(x)])

@implementation TFCombinadicIndices

@synthesize numElementsInSet;
@synthesize numElementsToSelect;
@synthesize isExhausted;

- (void)dealloc
{
	if (NULL != _slots) {
		free(_slots);
		_slots = NULL;
	}
	
	[super dealloc];
}

- (id)init
{
	return [self initWithElementsToSelect:2 fromSetWithPower:4];
}

- (id)initWithElementsToSelect:(NSUInteger)numElements fromSetWithPower:(NSUInteger)setPower
{
	if (!(self = [super init])) {
		[self release];
		return nil;
	}
	
	numElementsInSet = setPower;
	numElementsToSelect = numElements;
	_slots = (NSUInteger*)malloc((numElements+1)*sizeof(NSUInteger));
	_numCombinations = -1;
	
	[self reset];
											
	return self;
}

+ (id)combinadicWithElementsToSelect:(NSUInteger)numElements fromSetWithPower:(NSUInteger)setPower
{
	return [[[[self class] alloc] initWithElementsToSelect:numElements fromSetWithPower:setPower] autorelease];
}

- (const NSUInteger*)nextCombination
{
	if (isExhausted)
		return NULL;

	NSInteger i;
	for (i=numElementsToSelect-1; i>=0; i--) {
		if (_slots[i] < _slots[i+1]-1) {
			_slots[i]++;
			break;
		}
	}
	
	if (i < 0) {
		isExhausted = YES;
		return NULL;
	}
	
	NSUInteger d = _slots[i];
	for (i = i+1; i<numElementsToSelect; i++)
		_slots[i] = ++d;
	
	return _slots;
}

- (BOOL)isExhausted
{
	return isExhausted;
}

- (void)reset
{
	NSUInteger i;
	for (i=0; i<numElementsToSelect; i++)
		_slots[i] = i;
	
	_slots[numElementsToSelect-1] -= 1;
	_slots[numElementsToSelect] = numElementsInSet;
	
	isExhausted = NO;
}

- (NSInteger)numCombinations
{
	if (-1 != _numCombinations)
		return _numCombinations;
	
	switch (numElementsInSet) {
		case 0:
			_numCombinations = 0;
			return _numCombinations;
		case 1:
			_numCombinations = numElementsToSelect;
			return _numCombinations;
		case 2:
			_numCombinations = ((numElementsInSet-1)*(numElementsInSet-1)+(numElementsInSet-1))/2;
			return _numCombinations;
		default:
			break;
	}
	
	_numCombinations = FACT(numElementsInSet) / (FACT(numElementsToSelect) * FACT(numElementsInSet-numElementsToSelect));
	return _numCombinations;
}

+ (float)_factorial:(NSUInteger)n
{
	int j;
	static int ntop = 4;
	static float p[33] = {1.0f, 1.0f, 2.0f, 6.0f, 24.0f};
	
	// for large values of n, we approximate via the gamma function
	if (n > 32)
		return exp([[self class] _gammaLn:n+1.0]);
	
	while (ntop < n) {
		j = ntop++;
		p[ntop] = p[j]*ntop;
	}
	
	return p[n];
}

+ (float)_gammaLn:(float)xx
{
	int i;
	double x, y, tmp, ser;
	static double cof[6] = {76.18009172947146,
							-86.50532032941677,
							24.01409824083091,
							-1.231739572450155,
							0.1208650973866179e-2,
							-0.5395239384953e-5};
	y = x = xx;
	tmp = x + 5.5;
	tmp -= (x+0.5)*log(tmp);
	ser = 1.000000000190015;
	for (i=0; i<=5; i++)
		ser += cof[i]/++y;
	
	return -tmp + log(2.5066282746310005* ser/x);
}

@end
