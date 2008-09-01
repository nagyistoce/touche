//
//  TFGrayscale8BlobDetector.m
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

#import "TFGrayscale8BlobDetector.h"

#import "TFIncludes.h"

@implementation TFGrayscale8BlobDetector

+ (id)detectorWithGrayscale8ImageBuffer:(UInt8*)imgBuf
								  width:(size_t)width
								 height:(size_t)height
							   rowBytes:(size_t)rowBytes
{
	return [[[[self class] alloc]
			initWithGrayscale8ImageBuffer:imgBuf width:width height:height rowBytes:rowBytes]
				autorelease];
}

- (void)dealloc
{
	// whoever allocated this detector is responsible
	// for releasing _imgBuf
	[super dealloc];
}

- (id)init
{
	return [self initWithGrayscale8ImageBuffer:NULL width:0 height:0 rowBytes:0];
}

- (id)initWithGrayscale8ImageBuffer:(UInt8*)imgBuf
							  width:(size_t)width
							 height:(size_t)height
						   rowBytes:(size_t)rowBytes
{
	if (!(self = [super init])) {
		[super dealloc];
		return nil;
	}
	
	[self setGrayscale8ImageBuffer:imgBuf width:width height:height rowBytes:rowBytes];
	
	return self;
}

- (void)setGrayscale8ImageBuffer:(UInt8*)imgBuf
						   width:(size_t)width
						  height:(size_t)height
						rowBytes:(size_t)rowBytes
{
	@synchronized (self) {
		_imgBuf		= imgBuf;
		
		_width		= width;
		_height		= height;
		_rowBytes	= rowBytes;
		_rowSamples	= width;
	}
}

@end
