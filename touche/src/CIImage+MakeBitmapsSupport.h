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

#if !defined(__CIImage_MakeBitmapsSupport_h__)
#define __CIImage_MakeBitmapsSupport_h__

// zero on failure, non-zero on success
int CIImageBitmapsConvertARGB8toMono8(void* src,
									  unsigned srcRowBytes,
									  void* dest,
									  unsigned destRowBytes,
									  void* buffer,
									  int bufferRowBytes,
									  int width,
									  int height);

// zero on failure, non-zero on success
int CIImageBitmapsConvertARGB8ToRGBA8(void* src,
									  unsigned srcRowBytes,
									  void* dest,
									  unsigned destRowBytes,
									  int width,
									  int height);

// zero on failure, non-zero on success
int CIImageBitmapsConvertARGB8toRGB8(void* src,
									 unsigned srcRowBytes,
									 void* dest,
									 unsigned destRowBytes,
									 int width,
									 int height);

// zero on failure, non-zero on success
int CIImageBitmaps1PixelImageBorderARGB8(void* image,
										 unsigned imageRowBytes,
										 int width,
										 int height,
										 const unsigned char borderColor[4]);

int CIImageBitmaps1PixelImageBorderARGBf(void* image,
										 unsigned imageRowBytes,
										 int width,
										 int height,
										 const float borderColor[4]);

#endif // __CIImage_MakeBitmapsSupport_h__