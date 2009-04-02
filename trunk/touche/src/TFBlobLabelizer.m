//
//  TFBlobLabelizer.m
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

#import "TFBlobLabelizer.h"

#import "TFIncludes.h"
#import "TFBlob.h"
#import "TFBlobPoint.h"
#import "TFBlobBox.h"
#import "TFBlobLabel.h"
#import "TFLabelFactory.h"

@implementation TFBlobLabelizer

- (void)dealloc
{
	[_labelFactory release];
	
	[super dealloc];
}

- (id)init
{
	if (!(self = [super init])) {
		[self release];
		return nil;
	}
	
	_labelFactory	= [[TFLabelFactory alloc] init];
	
	return self;
}

- (void)initializeNewBlob:(TFBlob*)blob
{
	blob.label = [_labelFactory claimLabel];
	blob.label.isNew = YES;
	blob.isUpdate = NO;
}

- (void)matchOldBlob:(TFBlob*)oldBlob withNewBlob:(TFBlob*)newBlob
{
	newBlob.label =	oldBlob.label;
	newBlob.label.isNew = NO;
	newBlob.previousCenter = [[oldBlob.center copy] autorelease];
	newBlob.isUpdate = YES;
	newBlob.previousCreatedAt = oldBlob.createdAt;
	newBlob.trackedSince = oldBlob.trackedSince;
	
	// compute the acceleration vector
	float xAccel = newBlob.center.x - 2*oldBlob.center.x + oldBlob.previousCenter.x;
	float yAccel = newBlob.center.y - 2*oldBlob.center.y + oldBlob.previousCenter.y;
	newBlob.acceleration = [TFBlobVector pointWithX:xAccel Y:yAccel];
	
	// compute oriented bounding box angular motion and acceleration.
	TFBlobBox *b = newBlob.orientedBoundingBox, *b2 = oldBlob.orientedBoundingBox;
	b.angularMotion = b.angle - b2.angle;
	b.angularAcceleration = b.angularMotion - b2.angularMotion;
}

- (void)prepareUnmatchedBlobForRemoval:(TFBlob*)blob
{
	[_labelFactory freeLabel:blob.label];
}

// TODO: use an error array like in camera to screen converter
- (NSArray*)labelizeBlobs:(NSArray*)blobs unmatchedBlobs:(NSArray**)unmatchedBlobs ignoringErrors:(BOOL)ignoreErrors error:(NSError**)error
{
	TFThrowMethodNotImplementedException();
	
	if (NULL != error)
		*error = nil;
	
	return nil;
}

@end
