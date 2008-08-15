//
//  TFBlob.h
//  Touché
//
//  Created by Georg Kaindl on 18/12/07.
//  Copyright 2007 Georg Kaindl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TFBlobPoint;
@class TFBlobBox;
@class TFBlobLabel;

@interface TFBlob : NSObject <NSCopying, NSCoding> {
	TFBlobPoint*		center;
	TFBlobPoint*		previousCenter;
	TFBlobBox*			boundingBox;
	NSArray*			edgeVertices;
	TFBlobLabel*		label;
	BOOL				isUpdate;
	NSTimeInterval		createdAt;
	NSTimeInterval		trackedSince;
}

@property (retain) TFBlobPoint* center;
@property (retain) TFBlobPoint* previousCenter;
@property (retain) TFBlobBox* boundingBox;
@property (retain) NSArray* edgeVertices;
@property (retain) TFBlobLabel* label;
@property (assign) BOOL isUpdate;
@property (readonly) NSTimeInterval createdAt;
@property (assign) NSTimeInterval trackedSince;

+ (id)blob;
+ (id)blobWithCenter:(TFBlobPoint*)c;
+ (id)blobWithCenter:(TFBlobPoint*)c boundingBox:(TFBlobBox*)bbox;
+ (id)blobWithCenter:(TFBlobPoint*)c boundingBox:(TFBlobBox*)bbox edgeVertices:(NSArray*)vertices;

- (id)initWithCenter:(TFBlobPoint*)c;
- (id)initWithCenter:(TFBlobPoint*)c boundingBox:(TFBlobBox*)bbox;
- (id)initWithCenter:(TFBlobPoint*)c boundingBox:(TFBlobBox*)bbox edgeVertices:(NSArray*)vertices;

@end
