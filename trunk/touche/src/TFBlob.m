//
//  TFBlob.m
//  Touché
//
//  Created by Georg Kaindl on 18/12/07.
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

#import "TFBlob.h"

#import "TFIncludes.h"
#import "TFBlobPoint.h"
#import "TFBlobBox.h"
#import "TFBlobLabel.h"

@implementation TFBlob

@synthesize center, previousCenter, acceleration, boundingBox, edgeVertices,
			label, isUpdate, createdAt, previousCreatedAt, trackedSince;

+ (id)blob
{
	return [[[[self class] alloc] init] autorelease];
}

+ (id)blobWithCenter:(TFBlobPoint*)c
{
	return [[[[self class] alloc] initWithCenter:c] autorelease];
}

+ (id)blobWithCenter:(TFBlobPoint*)c boundingBox:(TFBlobBox*)bbox
{
	return [[[[self class] alloc] initWithCenter:c boundingBox:bbox] autorelease];
}

+ (id)blobWithCenter:(TFBlobPoint*)c boundingBox:(TFBlobBox*)bbox edgeVertices:(NSArray*)vertices
{
	return [[[[self class] alloc] initWithCenter:c boundingBox:bbox edgeVertices:vertices] autorelease];
}

- (void)dealloc
{
	[center release];
	center = nil;
	[previousCenter release];
	previousCenter = nil;
	[boundingBox release];
	boundingBox = nil;
	[edgeVertices release];
	edgeVertices = nil;
	[label release];
	label = nil;
	
	[super dealloc];
}

- (id)init
{
	return [self initWithCenter:nil boundingBox:nil edgeVertices:nil];
}

- (id)initWithCenter:(TFBlobPoint*)c
{
	return [self initWithCenter:c boundingBox:nil edgeVertices:nil];
}

- (id)initWithCenter:(TFBlobPoint*)c boundingBox:(TFBlobBox*)bbox
{
	return [self initWithCenter:c boundingBox:bbox edgeVertices:nil];
}

- (id)initWithCenter:(TFBlobPoint*)c boundingBox:(TFBlobBox*)bbox edgeVertices:(NSArray*)vertices
{
	if (!(self = [super init])) {
		[self release];
		return nil;
	}
	
	if (nil != c)
		center = [c retain];
	else
		center = [[TFBlobPoint alloc] init];
	
	if (nil != bbox)
		boundingBox = [bbox retain];
	else
		boundingBox = [[TFBlobBox alloc] init];
	
	if (nil != edgeVertices)
		edgeVertices = [vertices retain];
	else
		edgeVertices = [[NSArray alloc] init];
	
	previousCenter = [[TFBlobPoint alloc] init];
	label = [[TFBlobLabel alloc] init];
	
	isUpdate = NO;
	createdAt = [NSDate timeIntervalSinceReferenceDate];
	trackedSince = createdAt;
			
	return self;
}

#pragma mark -
#pragma mark NSCopying protocol

- (id)copyWithZone:(NSZone *)zone
{
	TFBlob* aCopy = NSCopyObject(self, 0, zone);
	
	aCopy->center = [self.center copy];
	aCopy->previousCenter = [self.previousCenter copy];
	aCopy->boundingBox = [self.boundingBox copy];
	aCopy->edgeVertices = nil;
	aCopy->edgeVertices = [[NSArray alloc] initWithArray:self.edgeVertices copyItems:YES];
	aCopy->label = [self.label copy];
		
	return aCopy;
}

#pragma mark -
#pragma mark NSCoding protocol

- (id)initWithCoder:(NSCoder *)coder
{
	TFBlobPoint*	centerC			= [coder decodeObject];
	TFBlobPoint*	previousCenterC	= [coder decodeObject];
	TFBlobVector*	accelerationC	= [coder decodeObject];
	TFBlobBox*		boundingBoxC	= [coder decodeObject];
	NSArray*		edgeVerticesC	= [coder decodeObject];
	TFBlobLabel*	labelC			= [coder decodeObject];

	self = [self init];
	
	if (nil != self) {
		self.center			= centerC;
		self.previousCenter	= previousCenterC;
		self.acceleration	= accelerationC;
		self.boundingBox	= boundingBoxC;
		self.edgeVertices	= edgeVerticesC;
		self.label			= labelC;

		[coder decodeValueOfObjCType:@encode(BOOL) at:&isUpdate];
		[coder decodeValueOfObjCType:@encode(NSTimeInterval) at:&createdAt];
		[coder decodeValueOfObjCType:@encode(NSTimeInterval) at:&previousCreatedAt];
		[coder decodeValueOfObjCType:@encode(NSTimeInterval) at:&trackedSince];
	}
		
	return self;
}

- (void)encodeWithCoder:(NSCoder*)coder
{
	[coder encodeObject:center];
	[coder encodeObject:previousCenter];
	[coder encodeObject:acceleration];
	[coder encodeObject:boundingBox];
	[coder encodeObject:edgeVertices];
	[coder encodeObject:label];
	[coder encodeValueOfObjCType:@encode(BOOL) at:&isUpdate];
	[coder encodeValueOfObjCType:@encode(NSTimeInterval) at:&createdAt];
	[coder encodeValueOfObjCType:@encode(NSTimeInterval) at:&previousCreatedAt];
	[coder encodeValueOfObjCType:@encode(NSTimeInterval) at:&trackedSince];
}

#pragma mark -
#pragma mark NSPortCoder specifics

- (id)replacementObjectForPortCoder:(NSPortCoder*)encoder
{
	if ([encoder isBycopy])
		return self;
	
	return [super replacementObjectForPortCoder:encoder];
}

@end
