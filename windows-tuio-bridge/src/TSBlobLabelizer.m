//
//  TSBlobLabelizer.m
//  TouchsmartTUIO
//
//  Created by Georg Kaindl on 26/02/09.
//  Copyright 2009 Georg Kaindl. All rights reserved.
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
