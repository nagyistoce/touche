//
//  TFRGBA8888BlobDetector.m
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

#import "TFRGBA8888BlobDetector.h"

#import "TFIncludes.h"

@implementation TFRGBA8888BlobDetector

- (void)dealloc
{
	// whoever allocated this detector is responsible
	// for releasing _imgBuf
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
	
	return self;
}

- (void)setImageBuffer:(void*)imgBuf
				 width:(size_t)width
				height:(size_t)height
			  rowBytes:(size_t)rowBytes
{
	@synchronized (self) {
		_imgBuf		= imgBuf;
		
		_width		= width;
		_height		= height;
		_rowBytes	= rowBytes;
		_rowSamples	= rowBytes/4;
	}
}

@end
