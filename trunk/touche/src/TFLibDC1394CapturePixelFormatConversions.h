//
//  TFLibDC1394CapturePixelFormatConversions.h
//  Touché
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

#include <stdint.h>

// returns non-zero on success, zero on failure
int TFLibDC1394PixelFormatConvertYUV411toARGB8(uint8_t* srcBuf,
											   uint8_t* dstBuf,
											   int width,
											   int height);

// returns non-zero on success, zero on failure
int TFLibDC1394PixelFormatConvertYUV444toARGB8(uint8_t* srcBuf,
											   int srcRowBytes,
											   uint8_t* dstBuf,
											   int dstRowBytes,
											   uint8_t* intermediateBuf,
											   int intermediateRowBytes,
											   int width,
											   int height);

// returns non-zero on success, zero on failure
int TFLibDC1394PixelFormatConvertRGB8toARGB8(uint8_t* srcBuf,
											 int srcRowBytes,
											 uint8_t* dstBuf,
											 int dstRowBytes,
											 int width,
											 int height);