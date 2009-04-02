//
//  TFBlob.h
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

#import <Cocoa/Cocoa.h>


@class TFBlobPoint;
@class TFBlobBox;
@class TFBlobLabel;

typedef TFBlobPoint TFBlobVector;

@interface TFBlob : NSObject <NSCopying, NSCoding> {
	TFBlobPoint*		center;
	TFBlobPoint*		previousCenter;
	TFBlobVector*		acceleration;
	TFBlobBox*			axisAlignedBoundingBox;
	TFBlobBox*			orientedBoundingBox;
	double				area;
	NSArray*			edgeVertices;
	TFBlobLabel*		label;
	BOOL				isUpdate;
	NSTimeInterval		createdAt;
	NSTimeInterval		previousCreatedAt;
	NSTimeInterval		trackedSince;
}

@property (retain) TFBlobPoint* center;
@property (retain) TFBlobPoint* previousCenter;
@property (retain) TFBlobVector* acceleration;
@property (retain) TFBlobBox* axisAlignedBoundingBox;
@property (retain) TFBlobBox* orientedBoundingBox;
@property (retain) NSArray* edgeVertices;
@property (retain) TFBlobLabel* label;
@property (assign) double area;
@property (assign) BOOL isUpdate;
@property (readonly) NSTimeInterval createdAt;
@property (assign) NSTimeInterval previousCreatedAt;
@property (assign) NSTimeInterval trackedSince;

// for historical reasons. This is an alias to the axisAlignedBoundingBox
@property (retain) TFBlobBox* boundingBox;

+ (id)blob;
+ (id)blobWithCenter:(TFBlobPoint*)c;
+ (id)blobWithCenter:(TFBlobPoint*)c boundingBox:(TFBlobBox*)bbox;
+ (id)blobWithCenter:(TFBlobPoint*)c boundingBox:(TFBlobBox*)bbox edgeVertices:(NSArray*)vertices;

- (id)initWithCenter:(TFBlobPoint*)c;
- (id)initWithCenter:(TFBlobPoint*)c boundingBox:(TFBlobBox*)bbox;
- (id)initWithCenter:(TFBlobPoint*)c boundingBox:(TFBlobBox*)bbox edgeVertices:(NSArray*)vertices;

@end
