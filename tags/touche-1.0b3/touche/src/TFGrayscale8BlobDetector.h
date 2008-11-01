//
//  TFGrayscale8BlobDetector.h
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

#import "TFBlobDetector.h"

@interface TFGrayscale8BlobDetector : TFBlobDetector {
	UInt8*		_imgBuf;
	NSUInteger	_width, _height, _rowBytes, _rowSamples;
}

// IMPORTANT NOTE: When assigning image data, this class DOES NOT take ownership of it! The
// caller is responsible for keeping the data available until blobs are detected and free'ing
// it afterwards if necessary!

+ (id)detectorWithGrayscale8ImageBuffer:(UInt8*)imgBuf
								  width:(size_t)width
								 height:(size_t)height
							   rowBytes:(size_t)rowBytes;
- (id)initWithGrayscale8ImageBuffer:(UInt8*)imgBuf
							  width:(size_t)width
							 height:(size_t)height
						   rowBytes:(size_t)rowBytes;

- (void)setGrayscale8ImageBuffer:(UInt8*)imgBuf
						   width:(size_t)width
						  height:(size_t)height
						rowBytes:(size_t)rowBytes;


@end
