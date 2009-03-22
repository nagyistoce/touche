//
//  CIImage+MakeBitmaps.h
//  Touché
//
//  Created by Georg Kaindl on 15/12/07.
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
//  Based on code by: http://www.geekspiff.com/unlinkedCrap/ciImageToBitmap.html

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>


typedef struct CIImageBitmapData {
	void* data;
	size_t width, height, rowBytes;
} CIImageBitmapData;

void* CIImageBitmapsCreateContextForGrayscale8(CIImage* image, BOOL renderOnCPU);
void* CIImageBitmapsCreateContextForRGB8(CIImage* image, BOOL renderOnCPU);
void* CIImageBitmapsCreateContextForPremultipliedARGB8(CIImage* image, BOOL renderOnCPU);
void* CIImageBitmapsCreateContextForPremultipliedRGBA8(CIImage* image, BOOL renderOnCPU);
void* CIImageBitmapsCreateContextForPremultipliedRGBAf(CIImage* image, BOOL renderOnCPU);

void CIImageBitmapsReleaseContext(void* pContext);

// if you set this to YES, the context will determine the fastest rendering method (for your system)
// dynamically by measuring the performance of different methods. Only set this on contexts that you
// will use to render at least a couple of CIImages with. Off per default.
void CIImageBitmapsSetContextDeterminesFastestRenderingDynamically(void* pContext, BOOL determineDynamically);

inline BOOL CIImageBitmapsContextMatchesBitmapSize(void* pContext, CGSize size);
inline BOOL CIImageBitmapsContextRendersOnCPU(void* pContext);

inline CIImageBitmapData CIImageBitmapsCurrentBitmapDataForContext(void* pContext);

inline CGColorSpaceRef CIImageBitmapsCIOutputColorSpaceForContext(void* pContext);
inline CGColorSpaceRef CIImageBitmapsCIWorkingColorSpaceForContext(void* pContext);

@interface CIImage (MakeBitmapsExtensions)

+ (CGColorSpaceRef)screenColorSpace;

- (CIImageBitmapData)bitmapDataWithBitmapCreationContext:(void*)pContext;

@end
