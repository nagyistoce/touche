//
//  TSBlobLabelizer.h
//  TouchsmartTUIO
//
//  Created by Georg Kaindl on 26/02/09.
//  Copyright 2009 Georg Kaindl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TFBlobLabelizer.h"


// Just a trivial labelizer, since we already have the correct label
// from the WiiRemote. We just use this to have the matching of old
// to new blobs done by existing code.

@interface TSBlobLabelizer : TFBlobLabelizer {
	NSMutableDictionary* _previousBlobs;
}

- (id)init;
- (void)dealloc;

- (NSArray*)labelizeBlobs:(NSArray*)blobs
		   unmatchedBlobs:(NSArray**)unmatchedBlobs
		   ignoringErrors:(BOOL)ignoreErrors
					error:(NSError**)error;

@end
