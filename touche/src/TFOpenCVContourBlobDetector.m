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
#import "TFPerformanceTimer.h"


#define	MAX_BLOBS		(128)	// maximum amounts of blobs to track simultaneously

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

- (id)initWithImageBuffer:(void*)imgBuf
					width:(size_t)width
				   height:(size_t)height
				 rowBytes:(size_t)rowBytes
{
	if (!(self = [super initWithImageBuffer:imgBuf
									  width:width
									 height:height
								   rowBytes:rowBytes])) {
		[super dealloc];
		return nil;
	}
	
	minimumBlobDiameter = 0.0f;
	
	return self;
}

- (void)setImageBuffer:(void*)imgBuf
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
		
		[super setImageBuffer:imgBuf
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

		TFPMStartTimer(TFPerformanceTimerBlobDetection);

		[detectedBlobs removeAllObjects];

		NSMutableArray* edgeVertices = [NSMutableArray array];
		int i;
		CvMemStorage* storage = cvCreateMemStorage(0);
		CvSeq* contours = NULL, *edgePoints = NULL;
		CvBox2D obb;
		CvRect aabb;
		float area;
	
		//cvFindContours(_cvImg, storage, &contours, sizeof(CvContour), CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, cvPoint(0,0));
		cvFindContours(_cvImg, storage, &contours, sizeof(CvContour), CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE, cvPoint(0,0));

		int numContours = 0;
		for (; contours != NULL; contours = contours->h_next) {			
			if (contours->total > 5)
				obb = cvFitEllipse2(contours);
			else
				obb = cvMinAreaRect2(contours, storage);
			
			if (obb.size.height < minimumBlobDiameter*(float)_height || obb.size.width < minimumBlobDiameter*(float)_width)
				continue;
			
			aabb = cvBoundingRect(contours, 1);
			area = cvContourArea(contours, CV_WHOLE_SEQ);
															
			TFBlob* blob = [TFBlob blob];

			blob.center.x							= obb.center.x;
			blob.center.y							= obb.center.y;
			
			blob.area								= area;
			
			blob.axisAlignedBoundingBox.origin.x	= aabb.x;
			blob.axisAlignedBoundingBox.origin.y	= aabb.y;
			blob.axisAlignedBoundingBox.size.width	= aabb.width;
			blob.axisAlignedBoundingBox.size.height	= aabb.height;
			blob.axisAlignedBoundingBox.angle		= 0.0;
			
			blob.orientedBoundingBox.origin.x		= obb.center.x - obb.size.width/2.0;
			blob.orientedBoundingBox.origin.y		= obb.center.y - obb.size.height/2.0;
			blob.orientedBoundingBox.size.width		= obb.size.width;
			blob.orientedBoundingBox.size.height	= obb.size.height;
			blob.orientedBoundingBox.angle			= obb.angle * (pi / 180.0);
						
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
		
		TFPMStopTimer(TFPerformanceTimerBlobDetection);
	}
	
	return YES;
}

@end
