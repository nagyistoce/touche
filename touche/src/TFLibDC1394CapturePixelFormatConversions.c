//
// TFLibDC1394CapturePixelFormatConversions.h
// Touché
//
//  Created by Georg Kaindl on 24/3/09.
//
//  Copyright (C) 2009 Georg Kaindl
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

#include "TFLibDC1394CapturePixelFormatConversions.h"

#include <stdlib.h>
#include <stdint.h>

#include <Accelerate/Accelerate.h>


// taken from libdc1394
#define YUV2RGB(y, u, v, r, g, b) {		\
	r = y + ((v*1436) >> 10);			\
	g = y - ((u*352 + v*731) >> 10);	\
	b = y + ((u*1814) >> 10);			\
	r = r < 0 ? 0 : r;					\
	g = g < 0 ? 0 : g;					\
	b = b < 0 ? 0 : b;					\
	r = r > 255 ? 255 : r;				\
	g = g > 255 ? 255 : g;				\
	b = b > 255 ? 255 : b; }

int TFLibDC1394PixelFormatConvertYUV411toARGB8(uint8_t* srcBuf,
											   uint8_t* dstBuf,
											   int width,
											   int height)
{
	if (NULL == srcBuf || NULL == dstBuf)
		return 0;
	
	int i = (width*height) + ( (width*height) >> 1 )-1;
	int j = ((width*height) << 2) - 1;
	int y0, y1, y2, y3, u, v, r, g, b;
	
    while (i >= 0) {
        y3 = (uint8_t) srcBuf[i--];
        y2 = (uint8_t) srcBuf[i--];
        v  = (uint8_t) srcBuf[i--] - 128;
        y1 = (uint8_t) srcBuf[i--];
        y0 = (uint8_t) srcBuf[i--];
        u  = (uint8_t) srcBuf[i--] - 128;
        YUV2RGB (y3, u, v, r, g, b);
        dstBuf[j--] = b;
        dstBuf[j--] = g;
        dstBuf[j--] = r;
		dstBuf[j--] = UINT8_MAX;
        YUV2RGB (y2, u, v, r, g, b);
        dstBuf[j--] = b;
        dstBuf[j--] = g;
        dstBuf[j--] = r;
		dstBuf[j--] = UINT8_MAX;
        YUV2RGB (y1, u, v, r, g, b);
        dstBuf[j--] = b;
        dstBuf[j--] = g;
        dstBuf[j--] = r;
		dstBuf[j--] = UINT8_MAX;
        YUV2RGB (y0, u, v, r, g, b);
        dstBuf[j--] = b;
        dstBuf[j--] = g;
        dstBuf[j--] = r;
		dstBuf[j--] = UINT8_MAX;
    }
	
	return 1;
}

int TFLibDC1394PixelFormatConvertYUV444toARGB8(uint8_t* srcBuf,
											   int srcRowBytes,
											   uint8_t* dstBuf,
											   int dstRowBytes,
											   uint8_t* intermediateBuf,
											   int intermediateRowBytes,
											   int width,
											   int height)
{
	vImage_Buffer vInter, vSrc, vDst;
	
	vInter.data = intermediateBuf;
	vInter.width = width;
	vInter.height = height;
	vInter.rowBytes = intermediateRowBytes;
	
	vSrc.data = srcBuf;
	vSrc.width = width;
	vSrc.height = height;
	vSrc.rowBytes = srcRowBytes;
	
	vDst.data = dstBuf;
	vDst.width = width;
	vDst.height = height;
	vDst.rowBytes = dstRowBytes;
	
	vImageConvert_RGB888toARGB8888(&vSrc,
								   NULL,
								   255,
								   &vInter,
								   false,
								   0);
	
	// constants from http://www.fourcc.org/fccyvrgb.php
	int16_t matrix[] = { 100,   0,   0,   0,
						   0, 100, 100, 100,
						   0,   0, -34, 177,
						   0, 140, -71,   0 };
	
	vImageMatrixMultiply_ARGB8888(&vInter,
								  &vDst,
								  matrix,
								  100,
								  NULL,
								  NULL,
								  0);
	
	return 1;
}
