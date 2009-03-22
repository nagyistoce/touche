//
//  TFOpenCVContourBlobDetector.h
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

#import <Cocoa/Cocoa.h>
#import <OpenCV/OpenCV.h>

#import "TFGrayscale8BlobDetector.h"

@interface TFOpenCVContourBlobDetector : TFGrayscale8BlobDetector {
	IplImage*		_cvImg;
	BOOL			_blobsNotYetDetected;
	float			minimumBlobDiameter;
}

@property (assign) float minimumBlobDiameter;

- (id)initWithImageBuffer:(void*)imgBuf
					width:(size_t)width
				   height:(size_t)height
				 rowBytes:(size_t)rowBytes;

- (void)setImageBuffer:(void*)imgBuf
				 width:(size_t)width
				height:(size_t)height
			  rowBytes:(size_t)rowBytes;

- (BOOL)detectBlobs:(NSError**)error ignoreErrors:(BOOL)ignoreErrors;

@end
