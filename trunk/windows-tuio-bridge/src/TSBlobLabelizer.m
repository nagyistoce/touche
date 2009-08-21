//
//  TSBlobLabelizer.m
//  TouchsmartTUIO
//
//  Created by Georg Kaindl on 26/02/09.
//
//  Copyright (C) 2009 Georg Kaindl
//
//  This file is part of Touchsmart TUIO.
//
//  Touchsmart TUIO is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as
//  published by the Free Software Foundation, either version 3 of
//  the License, or (at your option) any later version.
//
//  Touchsmart TUIO is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public
//  License along with Touchsmart TUIO. If not, see <http://www.gnu.org/licenses/>.
//

#import "TSBlobLabelizer.h"

#import "TFBlob.h"
#import "TFBlobLabel.h"
#import "TFLabelFactory.h"


@implementation TSBlobLabelizer

- (id)init
{
	if (nil != (self = [super init])) {
		_previousBlobs = [[NSMutableDictionary alloc] init];
		_labelMapping = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (void)dealloc
{
	[_previousBlobs release];
	_previousBlobs = nil;
	
	[_labelMapping release];
	_labelMapping = nil;
	
	[super dealloc];
}

- (NSArray*)labelizeBlobs:(NSArray*)blobs
		   unmatchedBlobs:(NSArray**)unmatchedBlobs
		   ignoringErrors:(BOOL)ignoreErrors
					error:(NSError**)error
{
	NSMutableArray* livingLabels = [NSMutableArray array];

	for (TFBlob* blob in blobs) {
		TFBlobLabel* inLabel = blob.label;
		TFBlobLabel* mappedLabel = [_labelMapping objectForKey:inLabel];
		TFBlob* oldBlob = nil;
		
		if (nil != mappedLabel)
			oldBlob = [_previousBlobs objectForKey:mappedLabel];
		
		if (nil != oldBlob) {
			[self matchOldBlob:oldBlob withNewBlob:blob];
		} else {
			[self initializeNewBlob:blob];
			[_labelMapping setObject:blob.label forKey:inLabel];
		}
		
		[_previousBlobs setObject:blob forKey:blob.label];
		[livingLabels addObject:blob.label];
	}
	
	NSMutableArray* removedBlobs = [NSMutableArray array];
	NSMutableArray* removedLabels = [NSMutableArray array];
	for (TFBlob* blob in [_previousBlobs allValues]) {
		if (![livingLabels containsObject:blob.label]) {
			NSArray* reverseMappingKeys = [_labelMapping allKeysForObject:blob.label];
			if ([reverseMappingKeys count] > 0) {
				TFBlobLabel* reverseMappedLabel = [reverseMappingKeys objectAtIndex:0];
				if (nil != reverseMappedLabel)
					[_labelMapping removeObjectForKey:reverseMappedLabel];				
			}
			
			[removedLabels addObject:blob.label];
			[self prepareUnmatchedBlobForRemoval:blob];
			[removedBlobs addObject:blob];
		}
	}
	
	for (TFBlob* label in removedLabels)
		[_previousBlobs removeObjectForKey:label];
	
	if (NULL != unmatchedBlobs)
		*unmatchedBlobs = removedBlobs;
	
	return blobs;
}

@end
