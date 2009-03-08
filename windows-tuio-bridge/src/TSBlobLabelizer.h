//
//  TSBlobLabelizer.h
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
