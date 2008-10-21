//
//  TFOpenCVContourBlobDetector.m
//  Touché
//
//  Created by Georg Kaindl on 1/5/08.
//
//  Copyright (C) 2008 Georg Kaindl
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
//

#import "TFOpenCVContourBlobDetector.h"

#import "TFIncludes.h"
#import "TFBlob.h"
#import "TFBlobPoint.h"
#import "TFBlobBox.h"
#import "TFBlobSize.h"


#define	MAX_BLOBS		(100)	// maximum amounts of blobs to track simultaneously
#define	EXACT_TRACKING	(NO)

@implementation TFOpenCVContourBlobDetector

@synthesize minimumBlobDiameter;

- (void)dealloc
{
	@synchronized (self) {
		if (NULL != _cvImg) {
			cvSetData(_cvImg, NULL, 0);
			cvReleaseImage(&_cvImg);
			_cvImg = NULL;
		}
	}
	
	[super dealloc];
}

- (id)initWithGrayscale8ImageBuffer:(UInt8*)imgBuf
							  width:(size_t)width
							 height:(size_t)height
						   rowBytes:(size_t)rowBytes
{
	if (!(self = [super initWithGrayscale8ImageBuffer:imgBuf width:width height:height rowBytes:rowBytes])) {
		[super dealloc];
		return nil;
	}
	
	minimumBlobDiameter = 0.0f;
	
	return self;
}

- (void)setGrayscale8ImageBuffer:(UInt8*)imgBuf
						   width:(size_t)width
						  height:(size_t)height
						rowBytes:(size_t)rowBytes
{
	if (NULL == imgBuf)
		return;

	@synchronized (self) {
		if (NULL == _cvImg || width != _cvImg->width || height != _cvImg->height) {
			if (NULL != _cvImg) {
				cvSetData(_cvImg, NULL, 0);
				cvReleaseImage(&_cvImg);
				_cvImg = NULL;
			}
			
			_cvImg = cvCreateImage(cvSize(width, height), IPL_DEPTH_8U, 1);
		}
		
		[super setGrayscale8ImageBuffer:imgBuf
								  width:width
								 height:height
							   rowBytes:rowBytes];
		
		cvSetData(_cvImg, imgBuf, rowBytes);
		
		_blobsNotYetDetected = YES;
		
		/* char buf[100];
		static int i = 0;
		i++;
		sprintf(buf, [[@"~/Desktop/img/img%d.bmp" stringByExpandingTildeInPath] UTF8String], i);
		cvSaveImage(buf, _cvImg); */
	}
}

- (BOOL)detectBlobs:(NSError**)error ignoreErrors:(BOOL)ignoreErrors
{
	@synchronized (self) {
		if (!_blobsNotYetDetected)
			return YES;

		[detectedBlobs removeAllObjects];

		NSMutableArray* edgeVertices = [NSMutableArray array];
		int i;
		CvMemStorage* storage = cvCreateMemStorage(0);
		CvSeq* contours = NULL, *edgePoints = NULL;
		CvBox2D box;
	
		//cvFindContours(_cvImg, storage, &contours, sizeof(CvContour), CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, cvPoint(0,0));
		cvFindContours(_cvImg, storage, &contours, sizeof(CvContour), CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE, cvPoint(0,0));

		int numContours = 0;
		for (; contours != NULL; contours = contours->h_next) {
			CGRect blobBox;
			
			if (EXACT_TRACKING) {
				if (contours->total > 5)
					box = cvFitEllipse2(contours);
				else
					box = cvMinAreaRect2(contours, storage);
				
				if (box.size.height < minimumBlobDiameter*(float)_height || box.size.width < minimumBlobDiameter*(float)_width)
					continue;
				
				// OpenCV's boxes have a rotation angle, to in order to determine the actual bounding
				// box, we need to apply this rotation in order to get the visible bounding box size.
				CGRect boundingRect = CGRectMake(box.center.x - box.size.width/2.0,
												 box.center.y - box.size.height/2.0,
												 box.size.width,
												 box.size.height);
				CGPoint boundingCenter = CGPointMake(CGRectGetMidX(boundingRect), CGRectGetMidY(boundingRect));
				CGAffineTransform boxRotation = CGAffineTransformMakeTranslation(boundingCenter.x, 
																				 boundingCenter.y);
				boxRotation = CGAffineTransformRotate(boxRotation, box.angle*(M_PI/180.0));
				boxRotation = CGAffineTransformTranslate(boxRotation, -boundingCenter.x, -boundingCenter.y);

				blobBox = CGRectApplyAffineTransform(boundingRect, boxRotation);
			} else {
				CvRect bRect = cvBoundingRect(contours, 1);
				
				if (bRect.height < minimumBlobDiameter*(float)_height || bRect.width < minimumBlobDiameter*(float)_width)
					continue;
				
				blobBox = CGRectMake(bRect.x, bRect.y, bRect.width, bRect.height);
			}
												
			TFBlob* blob = [TFBlob blob];

			blob.center.x					= CGRectGetMidX(blobBox);
			blob.center.y					= CGRectGetMidY(blobBox);
			blob.boundingBox.origin.x		= CGRectGetMinX(blobBox);
			blob.boundingBox.origin.y		= CGRectGetMinY(blobBox);
			blob.boundingBox.size.width		= CGRectGetWidth(blobBox);
			blob.boundingBox.size.height	= CGRectGetHeight(blobBox);
			
			edgePoints = cvApproxPoly(contours, sizeof(CvContour), storage, CV_POLY_APPROX_DP, cvContourPerimeter(contours)*0.02, 0);
			
			[edgeVertices removeAllObjects];
			for (i=0; i<edgePoints->total; i++) {
				CvPoint* p = (CvPoint*)cvGetSeqElem(edgePoints, i);
				[edgeVertices addObject:[TFBlobPoint pointWithX:p->x Y:p->y]];
			}
			
			blob.edgeVertices = [NSArray arrayWithArray:edgeVertices];
			
			[detectedBlobs addObject:blob];
			
			if (numContours++ > MAX_BLOBS)
				break;
		}
		
		cvReleaseMemStorage(&storage);
		
		_blobsNotYetDetected = NO;
	}
	
	return YES;
}

@end
