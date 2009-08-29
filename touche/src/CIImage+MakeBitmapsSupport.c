//
//  CIImage+MakeBitmapsSupport.h
//  Touché
//
//  Created by Georg Kaindl on 30/03/09.
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

#include "CIImage+MakeBitmapsSupport.h"

#import <stdint.h>
#import <Accelerate/Accelerate.h>

#if defined(_USES_IPP_)
#import <ipp.h>
#import <ippi.h>
#endif


#if defined(__LITTLE_ENDIAN__)
#define PACKARGB8(a, r, g, b)	(((a) & 0xff)			|	\
								(((r) & 0xff) << 8)		|	\
								(((g) & 0xff) << 16)	|	\
								(((b) & 0xff) << 24))
#else
#define PACKARGB8(a, r, g, b)	((((a) & 0xff) << 24)	|	\
								(((r) & 0xff) << 16)	|	\
								(((g) & 0xff) << 8)		|	\
								((b) & 0xff))
#endif

int _CIImageBitmapsConvert8888toMono8(void* src,
									  unsigned srcRowBytes,
									  void* dest,
									  unsigned destRowBytes,
									  void* buffer,
									  int bufferRowBytes,
									  int width,
									  int height,
									  const int permute[4]);
int _CIImageBitmapsPermute8888To8888(void* src,
									 unsigned srcRowBytes,
									 void* dest,
									 unsigned destRowBytes,
									 int width,
									 int height,
									 const int permute[4]);
int _CIImageBitmapsConvert8888to888(void* src,
									unsigned srcRowBytes,
									void* dest,
									unsigned destRowBytes,
									void* buffer,
									int bufferRowBytes,
									int width,
									int height,
									const int permute[3]);


int CIImageBitmapsConvertARGB8toMono8(void* src,
									  unsigned srcRowBytes,
									  void* dest,
									  unsigned destRowBytes,
									  void* buffer,
									  int bufferRowBytes,
									  int width,
									  int height)
{
#if defined(_USES_IPP_)
	// needs RGBA
	const int permute[] = { 1, 2, 3, 0};
#else
	// needs ARGB
	const int permute[] = { 0, 1, 2, 3 };
#endif
	return _CIImageBitmapsConvert8888toMono8(src,
											 srcRowBytes,
											 dest,
											 destRowBytes,
											 buffer,
											 bufferRowBytes,
											 width,
											 height,
											 permute);
}

int CIImageBitmapsConvertBGRA8toMono8(void* src,
									  unsigned srcRowBytes,
									  void* dest,
									  unsigned destRowBytes,
									  void* buffer,
									  int bufferRowBytes,
									  int width,
									  int height)
{
#if defined(_USES_IPP_)
	// needs RGBA
	const int permute[] = { 2, 1, 0, 3};
#else
	// needs ARGB
	const int permute[] = { 3, 2, 1, 0 };
#endif
	return _CIImageBitmapsConvert8888toMono8(src,
											 srcRowBytes,
											 dest,
											 destRowBytes,
											 buffer,
											 bufferRowBytes,
											 width,
											 height,
											 permute);
}

int _CIImageBitmapsConvert8888toMono8(void* src,
									  unsigned srcRowBytes,
									  void* dest,
									  unsigned destRowBytes,
									  void* buffer,
									  int bufferRowBytes,
									  int width,
									  int height,
									  const int permute[4])
{
#if defined(_USES_IPP_)
	IppiSize swapChannelRoiSize = { width, height };
	const int* permuteMap = permute;
	
	ippiSwapChannels_8u_C4IR(src,
							 srcRowBytes,
							 swapChannelRoiSize,
							 permuteMap);
	
	IppiSize convertToGrayRoiSize = { width, height };
	
	ippiRGBToGray_8u_AC4C1R(src,
							srcRowBytes,
							dest,
							destRowBytes,
							convertToGrayRoiSize);			
#else // no IPP available
	vImage_Buffer intermediateBuf, srcBuf, destBuf;
	
	intermediateBuf.data = buffer;
	intermediateBuf.width = width;
	intermediateBuf.height = height;
	intermediateBuf.rowBytes = bufferRowBytes;
	
	srcBuf.data = src;
	srcBuf.width = width;
	srcBuf.height = height;
	srcBuf.rowBytes = srcRowBytes;
	
	destBuf.data = dest;
	destBuf.width = width;
	destBuf.height = height;
	destBuf.rowBytes = destRowBytes;
	
	int16_t matrix[] = { 0,   0, 0, 0,
						 0,   0, 0, 0,
						 0,   0, 0, 0,
						 0,   0, 0, 0 };
	
	// these constants are derived from the NTSC RGB->Luminance conversion
	// the same values are used by the Intel IPP.
	int i, colOff = 0;
	for (i=0; i<4; i++) {
		int16_t val = 0;
		switch (permute[i]) {
			case 1: val = 299; colOff = i; break;
			case 2: val = 587; break;
			case 3: val = 114; break;
			default: break;
		}
		
		int j;
		for (j=0; j<4; j++)
			matrix[i*4+j] = val;
	}
	
	vImageMatrixMultiply_ARGB8888(&srcBuf, &intermediateBuf, matrix, 100, NULL, NULL, 0);
	
	const void* srcBufArray[] = { (void*)((char*)intermediateBuf.data + colOff) };
	const vImage_Buffer* destBufArray[] = { &destBuf };
	
	vImageConvert_ChunkyToPlanar8(srcBufArray,
								  destBufArray,
								  1,
								  4,
								  width,
								  height,
								  intermediateBuf.rowBytes,
								  0);
#endif

	return 1;
}

int CIImageBitmapsConvertARGB8ToRGBA8(void* src,
									  unsigned srcRowBytes,
									  void* dest,
									  unsigned destRowBytes,
									  int width,
									  int height)
{
	const int permute[] = { 1, 2, 3, 0 };
	return _CIImageBitmapsPermute8888To8888(src,
											srcRowBytes,
											dest,
											destRowBytes,
											width,
											height,
											permute);
}

int CIImageBitmapsConvertBGRA8ToRGBA8(void* src,
									  unsigned srcRowBytes,
									  void* dest,
									  unsigned destRowBytes,
									  int width,
									  int height)
{
	const int permute[] = { 2, 1, 0, 3 };
	return _CIImageBitmapsPermute8888To8888(src,
											srcRowBytes,
											dest,
											destRowBytes,
											width,
											height,
											permute);
}

int _CIImageBitmapsPermute8888To8888(void* src,
									 unsigned srcRowBytes,
									 void* dest,
									 unsigned destRowBytes,
									 int width,
									 int height,
									 const int permute[4])
{
#if defined(_USES_IPP_)
	IppiSize roiSize = { width, height };
	const int* permuteMap = permute;
	
	if (src == dest)
		ippiSwapChannels_8u_C4IR(dest,
								 destRowBytes,
								 roiSize,
								 permuteMap);
	else
		ippiSwapChannels_8u_AC4R(src,
								 srcRowBytes,
								 dest,
								 destRowBytes,
								 roiSize,
								 permuteMap);
#else // no IPP available
	vImage_Buffer srcBuf, destBuf;
	
	destBuf.data = dest;
	destBuf.width = width;
	destBuf.height = height;
	destBuf.rowBytes = destRowBytes;
	
	srcBuf.data = src;
	srcBuf.width = width;
	srcBuf.height = height;
	srcBuf.rowBytes = srcRowBytes;
	
	uint8_t permuteMap[4];
	int i;
	for (i=0; i<4; i++)
		permuteMap[i] = (uint8_t)permute[i];

	vImagePermuteChannels_ARGB8888(&srcBuf, &destBuf, permuteMap, 0);
#endif
	
	return 1;
}

int CIImageBitmapsConvertARGB8toRGB8(void* src,
									 unsigned srcRowBytes,
									 void* dest,
									 unsigned destRowBytes,
									 void* buffer,
									 int bufferRowBytes,
									 int width,
									 int height)
{
#if defined(_USES_IPP_)
	const int permute[] = { 1, 2, 3 };
#else
	const int* permute = NULL;
#endif
	return _CIImageBitmapsConvert8888to888(src,
										   srcRowBytes,
										   dest,
										   destRowBytes,
										   buffer,
										   bufferRowBytes,
										   width,
										   height,
										   permute);
}

int CIImageBitmapsConvertBGRA8toRGB8(void* src,
									 unsigned srcRowBytes,
									 void* dest,
									 unsigned destRowBytes,
									 void* buffer,
									 int bufferRowBytes,
									 int width,
									 int height)
{
#if defined(_USES_IPP_)
	const int permute[] = { 2, 1, 0 };
#else
	const int permute[] = { 3, 2, 1, 0 };
#endif
	return _CIImageBitmapsConvert8888to888(src,
										   srcRowBytes,
										   dest,
										   destRowBytes,
										   buffer,
										   bufferRowBytes,
										   width,
										   height,
										   permute);
}

int _CIImageBitmapsConvert8888to888(void* src,
									unsigned srcRowBytes,
									void* dest,
									unsigned destRowBytes,
									void* buffer,
									int bufferRowBytes,
									int width,
									int height,
									const int permute[4])
{
#if defined(_USES_IPP_)
	IppiSize roiSize = { width, height };
	const int* permuteMap = permute;
	
	ippiSwapChannels_8u_C4C3R(src,
							  srcRowBytes,
							  dest,
							  destRowBytes,
							  roiSize,
							  permuteMap);
#else // no IPP available
	vImage_Buffer srcBuf, destBuf, tmpBuf, *cBuf;
	
	destBuf.data = dest;
	destBuf.width = width;
	destBuf.height = height;
	destBuf.rowBytes = destRowBytes;
	
	srcBuf.data = src;
	srcBuf.width = width;
	srcBuf.height = height;
	srcBuf.rowBytes = srcRowBytes;
	
	if (NULL != permute) {
		tmpBuf.data = buffer;
		tmpBuf.width = width;
		tmpBuf.height = height;
		tmpBuf.rowBytes = bufferRowBytes;
		
		uint8_t permuteMap[4];
		int i;
		for (i=0; i<4; i++)
			permuteMap[i] = (uint8_t)permute[i];
		
		vImagePermuteChannels_ARGB8888(&srcBuf, &tmpBuf, permuteMap, 0);
				
		cBuf = &tmpBuf;
	} else
		cBuf = &srcBuf;
		
	
	vImageConvert_ARGB8888toRGB888(cBuf, &destBuf, 0);
#endif

	return 1;
}

int CIImageBitmaps1PixelImageBorder8888(void* image,
										unsigned imageRowBytes,
										int width,
										int height,
										const unsigned char borderColor[4])
{	
	uint32_t destRowPixels = imageRowBytes/4;
	uint32_t pix = PACKARGB8(borderColor[0],
							 borderColor[1],
							 borderColor[2],
							 borderColor[3]);	
	
	uint32_t* restrict l1 = (uint32_t*)image, *restrict ll = (uint32_t*)image + (height-1)*destRowPixels;
	for (int i=0; i<width; i++)
		l1[i] = ll[i] = pix;
	
	uint32_t cnt = (height-1)*destRowPixels;
	uint32_t* restrict c1 = (uint32_t*)image, *restrict cl = (uint32_t*)image + (width - 1);
	for (int i=destRowPixels; i <= cnt; i += destRowPixels)
		c1[i] = cl[i] = pix;
		
	return 1;
}

int CIImageBitmaps1PixelImageBorderFFFF(void* image,
										unsigned imageRowBytes,
										int width,
										int height,
										const float borderColor[4])
{	
	float a = borderColor[0], r = borderColor[1], g = borderColor[2], b = borderColor[3];
	uint32_t destRowElements = imageRowBytes/4;	
	uint32_t cnt = width * 4;
	float* restrict l1 = (float*)image, *restrict ll = (float*)image + (height-1)*destRowElements;		
	for (int i=0; i < cnt; i += 4) {
		l1[i] = ll[i] = a;
		l1[i+1] = ll[i+1] = r;
		l1[i+2] = ll[i+2] = g;
		l1[i+3] = ll[i+3] = b;
	}
	
	cnt = (height-1)*destRowElements;
	float* restrict c1 = (float*)image, *restrict cl = (float*)image + (width - 1) * 4;	
	for (int i=destRowElements; i <= cnt; i += destRowElements) {
		c1[i] = cl[i] = a;
		c1[i+1] = cl[i+1] = r;
		c1[i+2] = cl[i+2] = g;
		c1[i+3] = cl[i+3] = b;
	}
	
	return 1;
}
