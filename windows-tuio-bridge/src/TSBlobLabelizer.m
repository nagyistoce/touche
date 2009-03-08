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
	}
	
	return self;
}

- (void)dealloc
{
	[_previousBlobs release];
	_previousBlobs = nil;
	
	[super dealloc];
}

- (NSArray*)labelizeBlobs:(NSArray*)blobs
		   unmatchedBlobs:(NSArray**)unmatchedBlobs
		   ignoringErrors:(BOOL)ignoreErrors
					error:(NSError**)error
{
	for (TFBlob* blob in blobs) {
		TFBlob* oldBlob = [_previousBlobs objectForKey:blob.label];
		
		if (nil != oldBlob) {
			[self matchOldBlob:oldBlob withNewBlob:blob];
		} else {
			TFBlobLabel* label = blob.label;
			[self initializeNewBlob:blob];
			[_labelFactory freeLabel:blob.label];
			blob.label = label;
		}
		
		[_previousBlobs setObject:blob forKey:blob.label];
	}
	
	NSMutableArray* removedBlobs = [NSMutableArray array];
	NSMutableArray* removedLabels = [NSMutableArray array];
	for (TFBlob* blob in [_previousBlobs allValues]) {
		if (![blobs containsObject:blob]) {
			[removedLabels addObject:blob.label];
			
			TFBlobLabel* tmp = blob.label;
			blob.label = [_labelFactory claimLabel];
			[self prepareUnmatchedBlobForRemoval:blob];
			
			blob.label = tmp;
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
