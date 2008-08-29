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

@interface CIImage (MakeBitmapsExtensions)

+ (CGColorSpaceRef)screenColorSpace;
- (size_t)optimalRowBytesForWidth:(size_t)width
					bytesPerPixel:(size_t)bytesPerPixel;
					
- (UInt32*)createPremultipliedRGBA8888BitmapWithColorSpace:(CGColorSpaceRef)colorSpace
												  rowBytes:(size_t *)rowBytes
													buffer:(void*)buffer;
- (UInt32*)createPremultipliedRGBA8888BitmapWithColorSpace:(CGColorSpaceRef)colorSpace
												  rowBytes:(size_t *)rowBytes
													buffer:(void*)buffer
											   renderOnCPU:(BOOL)renderOnCPU;
- (UInt32*)createPremultipliedRGBA8888BitmapWithColorSpace:(CGColorSpaceRef)colorSpace
										 workingColorSpace:(CGColorSpaceRef)workingColorSpace
												  rowBytes:(size_t *)rowBytes
													buffer:(void*)buffer
											   renderOnCPU:(BOOL)renderOnCPU;
- (UInt32*)createPremultipliedRGBA8888BitmapWithColorSpace:(CGColorSpaceRef)colorSpace
										 workingColorSpace:(CGColorSpaceRef)workingColorSpace
												  rowBytes:(size_t *)rowBytes
													buffer:(void*)buffer
										  cgContextPointer:(CGContextRef*)cgContextPointer
										  ciContextPointer:(CIContext**)ciContextPointer
											   renderOnCPU:(BOOL)renderOnCPU;

- (float*)createPremultipliedRGBAFFFFBitmapWithColorSpace:(CGColorSpaceRef)colorSpace
												 rowBytes:(size_t *)rowBytes
												   buffer:(void*)buffer;
- (float*)createPremultipliedRGBAFFFFBitmapWithColorSpace:(CGColorSpaceRef)colorSpace
												 rowBytes:(size_t *)rowBytes
												   buffer:(void*)buffer
											  renderOnCPU:(BOOL)renderOnCPU;
- (float*)createPremultipliedRGBAFFFFBitmapWithColorSpace:(CGColorSpaceRef)colorSpace
										workingColorSpace:(CGColorSpaceRef)workingColorSpace
												 rowBytes:(size_t *)rowBytes
												   buffer:(void*)buffer
											  renderOnCPU:(BOOL)renderOnCPU;
- (float*)createPremultipliedRGBAFFFFBitmapWithColorSpace:(CGColorSpaceRef)colorSpace
										workingColorSpace:(CGColorSpaceRef)workingColorSpace
												 rowBytes:(size_t *)rowBytes
												   buffer:(void*)buffer
										 cgContextPointer:(CGContextRef*)cgContextPointer
										 ciContextPointer:(CIContext**)ciContextPointer
											  renderOnCPU:(BOOL)renderOnCPU;

- (UInt8*)createGrayscaleBitmapWithColorSpace:(CGColorSpaceRef)colorSpace
									 rowBytes:(size_t *)rowBytes
									   buffer:(void*)buffer;
- (UInt8*)createGrayscaleBitmapWithColorSpace:(CGColorSpaceRef)colorSpace
									 rowBytes:(size_t *)rowBytes
									   buffer:(void*)buffer
								  renderOnCPU:(BOOL)renderOnCPU;
- (UInt8*)createGrayscaleBitmapWithColorSpace:(CGColorSpaceRef)colorSpace
							workingColorSpace:(CGColorSpaceRef)workingColorSpace
									 rowBytes:(size_t *)rowBytes
									   buffer:(void*)buffer
								  renderOnCPU:(BOOL)renderOnCPU;
- (UInt8*)createGrayscaleBitmapWithColorSpace:(CGColorSpaceRef)colorSpace
							workingColorSpace:(CGColorSpaceRef)workingColorSpace
									 rowBytes:(size_t *)rowBytes
									   buffer:(void*)buffer
							 cgContextPointer:(CGContextRef*)cgContextPointer
							 ciContextPointer:(CIContext**)ciContextPointer
								  renderOnCPU:(BOOL)renderOnCPU;

@end
