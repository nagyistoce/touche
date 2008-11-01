//
//  TFBlobSimpleDistanceLabelizer.m
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

#import "TFBlobSimpleDistanceLabelizer.h"

#import "TFIncludes.h"
#import "TFBlob.h"
#import "TFBlobLabel.h"
#import "TFBlobPoint.h"
#import "TFLabelFactory.h"
#import "TFTrackingPipeline.h"

#define INITIAL_SCRATCH_SIZE		(6*100)
#define	DEFAULT_LOOKBACK_FRAMES		(0)

@interface TFBlobSimpleDistanceLabelizer (NonPublicMethods)
- (void)_addNewBlob:(TFBlob*)b withAge:(NSInteger)age;
- (BOOL)_blobWasActive:(TFBlob*)blob;
- (BOOL)_growScratchSpaceToSize:(NSUInteger)size;
- (NSArray*)_newBlobsBecameActive;
- (void)_replaceBlob:(TFBlob*)oldBlob withBlob:(TFBlob*)newBlob;
- (NSArray*)_updateAndDeleteBlobs;
@end

NSString* TFBlobSimpleDistanceLabelizerAgeKey				= @"TFBlobSimpleDistanceLabelizerAgeKey";
NSString* TFBlobSimpleDistanceLabelizerFrameCountKey		= @"TFBlobSimpleDistanceLabelizerFrameCountKey";

@implementation TFBlobSimpleDistanceLabelizer

@synthesize lookbackFrames, maxDistanceForMatch;

- (void)dealloc
{	
	[_previousBlobs release];
	_previousBlobs = nil;
	
	if (NULL != _scratchSpace) {
		free(_scratchSpace);
		_scratchSpace = NULL;
	}
	
	if (NULL != _scratchIndicesSpace) {
		free(_scratchIndicesSpace);
		_scratchIndicesSpace = NULL;
	}
	
	[super dealloc];
}

- (id)init
{
	if (!(self = [super init])) {
		[self release];
		return nil;
	}
	
	_previousBlobs = [[NSMutableDictionary alloc] init];
	
	self.lookbackFrames = DEFAULT_LOOKBACK_FRAMES;
	maxDistanceForMatch = 0.08f;
	
	_scratchSize = INITIAL_SCRATCH_SIZE;
	_scratchSpace = (float*)malloc(sizeof(float)*_scratchSize);
	_scratchIndicesSpace = (vDSP_Length*)malloc(sizeof(vDSP_Length)*_scratchSize/3);
	
	if (NULL == _scratchSpace || NULL == _scratchIndicesSpace) {
		[self release];
		return nil;
	}
	
	return self;
}

- (NSArray*)labelizeBlobs:(NSArray*)blobs unmatchedBlobs:(NSArray**)unmatchedBlobs ignoringErrors:(BOOL)ignoreErrors error:(NSError**)error
{
	if (!ignoreErrors && NULL != error)
		*error = nil;
	
	if (nil == blobs || [blobs count] <= 0) {
		NSArray* removedBlobs =  [self _updateAndDeleteBlobs];
		if (NULL != unmatchedBlobs) {
			*unmatchedBlobs = removedBlobs;
		}
		
		return [NSArray array];
	}
	
	if ([[_previousBlobs allKeys] count] <= 0) {
		// ok, this is the easy case
		// since there were no blobs in the last frame that we have to match against,
		// we simply labelize each blob in the current frame and return
		
		for (TFBlob* blob in blobs) {
			[self _addNewBlob:blob withAge:0];
		}
				
		return [self _newBlobsBecameActive];
	}
		
	NSMutableArray* retval			= [NSMutableArray array];
	NSArray*   previousBlobs		= [_previousBlobs allKeys];
	NSUInteger numBlobs				= [blobs count];
	NSUInteger numOldBlobs			= [previousBlobs count];
	NSUInteger numCombinations		= numBlobs * numOldBlobs;
	NSUInteger twoNumCombinations	= 2 * numCombinations;
	
	if (3*twoNumCombinations > _scratchSize || NULL == _scratchSpace || NULL == _scratchIndicesSpace) {
		// we grow our scratch space to 6*twoNumCombinations, even though just 3*twoNumCombinations would
		// be needed in order to have some extra space to minimize the chance that we'll have to realloc
		// again soon...
		BOOL couldResize = [self _growScratchSpaceToSize:6*twoNumCombinations];
		if (!couldResize) {
			if (!ignoreErrors && NULL != error)
				*error = [NSError errorWithDomain:TFErrorDomain
											 code:TFErrorSimpleDistanceLabelizerOutOfMemory
										 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
												   TFLocalizedString(@"TFSimpleDistanceLabelizerMemoryErrorDesc", @"TFSimpleDistanceLabelizerMemoryErrorDesc"),
												   NSLocalizedDescriptionKey,
												   TFLocalizedString(@"TFSimpleDistanceLabelizerMemoryErrorReason", @"TFSimpleDistanceLabelizerMemoryErrorReason"),
												   NSLocalizedFailureReasonErrorKey,
												   TFLocalizedString(@"TFSimpleDistanceLabelizerMemoryErrorRecovery", @"TFSimpleDistanceLabelizerMemoryErrorRecovery"),
												   NSLocalizedRecoverySuggestionErrorKey,
												   [NSNumber numberWithInteger:NSUTF8StringEncoding],
												   NSStringEncodingErrorKey,
												   nil]];
				return nil;
		}
	}
	
	float* A = _scratchSpace;
	float* B = &(_scratchSpace[twoNumCombinations]);
	float* C = &(_scratchSpace[twoNumCombinations << 1]);
	vDSP_Length* IC = _scratchIndicesSpace;
		
	NSUInteger i;
	for (i=0; i<numCombinations; i++) {
		A[i] = ((TFBlob*)[previousBlobs objectAtIndex:i%numOldBlobs]).center.x;
		B[i] = ((TFBlob*)[blobs objectAtIndex:i/numOldBlobs]).center.x;
		A[i+numCombinations] = ((TFBlob*)[previousBlobs objectAtIndex:i%numOldBlobs]).center.y;
		B[i+numCombinations] = ((TFBlob*)[blobs objectAtIndex:i/numOldBlobs]).center.y;
		IC[i] = i;
	}
	
	vDSP_vpythg(A, 1,
				A+numCombinations, 1,
				B, 1,
				B+numCombinations, 1,
				C, 1,
				numCombinations);
	vDSP_vsorti(C, IC, NULL, numCombinations, 1);
	
	static TFTrackingPipeline* pipeline = nil;
	if (nil == pipeline)
		pipeline = [TFTrackingPipeline sharedPipeline];
	float maxDist = [pipeline currentCaptureResolution].width*maxDistanceForMatch;
	
	NSUInteger curBlob, curOldBlob;
	NSUInteger numMatchedBlobs			= 0;
	NSUInteger numBlobsToMatch			= MIN(numBlobs, numOldBlobs);
	BOOL oldBlobMatched[numOldBlobs], newBlobMatched[numBlobs];
	memset(oldBlobMatched, (char)NO, sizeof(BOOL)*numOldBlobs);
	memset(newBlobMatched, (char)NO, sizeof(BOOL)*numBlobs);
	for (i=0; i<numCombinations; i++) {
		float distance = C[IC[i]];
		
		// if the distance is already above our threshold, don't match any more blobs
		if (distance > maxDist)
			break;
		
		curOldBlob	= IC[i]%numOldBlobs;
		curBlob		= IC[i]/numOldBlobs;
		
		if (oldBlobMatched[curOldBlob] || newBlobMatched[curBlob])
			continue;
			
		TFBlob* oldBlob = (TFBlob*)[previousBlobs objectAtIndex:curOldBlob];
		TFBlob* newBlob = (TFBlob*)[blobs objectAtIndex:curBlob];
		[self matchOldBlob:oldBlob withNewBlob:newBlob];
		
		oldBlobMatched[curOldBlob] = newBlobMatched[curBlob] = YES;
		numMatchedBlobs++;
		
		if ([self _blobWasActive:oldBlob])
			[retval addObject:newBlob];

		[self _replaceBlob:oldBlob withBlob:newBlob];
				
		if (numMatchedBlobs >= numBlobsToMatch)
			break;
	}
	
	for (i=0; i<numBlobs; i++) {
		if (!newBlobMatched[i]) {
			TFBlob* blob = (TFBlob*)[blobs objectAtIndex:i];
			[self _addNewBlob:blob withAge:-1];
		}
	}
	
	[retval addObjectsFromArray:[self _newBlobsBecameActive]];
	
	NSArray* removedBlobs =  [self _updateAndDeleteBlobs];
	if (NULL != unmatchedBlobs)
		*unmatchedBlobs = removedBlobs;
	
	return [NSArray arrayWithArray:retval];
}

- (BOOL)_growScratchSpaceToSize:(NSUInteger)size
{
	_scratchSpace = realloc(_scratchSpace, size*sizeof(float));
	_scratchIndicesSpace = realloc(_scratchIndicesSpace, (size/3)*sizeof(vDSP_Length));
	
	if (NULL == _scratchSpace || NULL == _scratchIndicesSpace) {
		if (NULL != _scratchSpace) {
			free(_scratchSpace);
			_scratchSpace = NULL;
		}
		
		if (NULL != _scratchIndicesSpace) {
			free(_scratchIndicesSpace);
			_scratchIndicesSpace = NULL;
		}
	
		return NO;
	}
	
	_scratchSize = size;
	
	return YES;
}

- (void)_addNewBlob:(TFBlob*)b withAge:(NSInteger)age
{	
	NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:0], TFBlobSimpleDistanceLabelizerFrameCountKey,
								 [NSNumber numberWithInt:-1], TFBlobSimpleDistanceLabelizerAgeKey, nil];
	[_previousBlobs setObject:dict forKey:b];
}

- (BOOL)_blobWasActive:(TFBlob*)blob
{
	return (nil == [[_previousBlobs objectForKey:blob] objectForKey:TFBlobSimpleDistanceLabelizerFrameCountKey]);
}

- (NSArray*)_newBlobsBecameActive
{
	NSMutableArray* accum = [NSMutableArray array];
	for (TFBlob* blob in [_previousBlobs allKeys]) {
		NSMutableDictionary* dict = [_previousBlobs objectForKey:blob];
		NSNumber* frameCount = [dict objectForKey:TFBlobSimpleDistanceLabelizerFrameCountKey];
		if (nil == frameCount)
			continue;
				
		if (((NSInteger)lookbackFrames) <= [frameCount intValue]) {
			[self initializeNewBlob:blob];
			
			TFBlob* copy = [blob copy];
			[accum addObject:copy];
			[copy release];
			
			[dict removeObjectForKey:TFBlobSimpleDistanceLabelizerFrameCountKey];
		}
	}
	
	return [NSArray arrayWithArray:accum];
}

- (void)_replaceBlob:(TFBlob*)oldBlob withBlob:(TFBlob*)newBlob
{
	NSMutableDictionary* dict = [[_previousBlobs objectForKey:oldBlob] retain];
	[_previousBlobs removeObjectForKey:oldBlob];
	
	NSNumber* blobFrameCount = [dict objectForKey:TFBlobSimpleDistanceLabelizerFrameCountKey];
	if (nil != blobFrameCount)
		[dict setObject:[NSNumber numberWithInt:[blobFrameCount intValue]+1] forKey:TFBlobSimpleDistanceLabelizerFrameCountKey];
		
	[dict setObject:[NSNumber numberWithInt:-1] forKey:TFBlobSimpleDistanceLabelizerAgeKey];
	
	[_previousBlobs setObject:dict forKey:newBlob];
		
	[dict release];
}

- (NSArray*)_updateAndDeleteBlobs
{
	NSMutableArray* removedBlobs = [NSMutableArray array];
	
	for (TFBlob* blob in [_previousBlobs allKeys]) {
		NSMutableDictionary* dict = [_previousBlobs objectForKey:blob];
		NSNumber* age = [dict objectForKey:TFBlobSimpleDistanceLabelizerAgeKey];
		
		if ([age intValue] >= (NSInteger)lookbackFrames) {
			NSNumber* blobFrameCount = [dict objectForKey:TFBlobSimpleDistanceLabelizerFrameCountKey];
		
			if (nil == blobFrameCount) {
				[self prepareUnmatchedBlobForRemoval:blob];
				[removedBlobs addObject:blob];
			}
			
			[_previousBlobs removeObjectForKey:blob];
			blob.isUpdate = NO;
		} else {
			[dict setObject:[NSNumber numberWithInt:([age intValue]+1)] forKey:TFBlobSimpleDistanceLabelizerAgeKey];
		}
	}
	
	return [NSArray arrayWithArray:removedBlobs];
}

@end
