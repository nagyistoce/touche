//
//  TFLibDC1394Capture+CVPixelBufferFromDc1394Frame.m
//  Touché
//
//  Created by Georg Kaindl on 15/5/08.
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

#import "TFLibDC1394Capture+CVPixelBufferFromDc1394Frame.h"
#import <QTKit/QTKit.h>
#import <dc1394/dc1394.h>

#import "TFIncludes.h"

@implementation TFLibDC1394Capture (CVPixelBufferFromDc1394Frame)

- (NSString*)dc1394ColorCodingToString:(dc1394color_coding_t)coding
{
	switch (coding) {
		case DC1394_COLOR_CODING_MONO8:
			return @"DC1394_COLOR_CODING_MONO8";
		case DC1394_COLOR_CODING_YUV411:
			return @"DC1394_COLOR_CODING_YUV411";
		case DC1394_COLOR_CODING_YUV422:
			return @"DC1394_COLOR_CODING_YUV422";
		case DC1394_COLOR_CODING_YUV444:
			return @"DC1394_COLOR_CODING_YUV444";
		case DC1394_COLOR_CODING_RGB8:
			return @"DC1394_COLOR_CODING_RGB8";
		case DC1394_COLOR_CODING_MONO16:
			return @"DC1394_COLOR_CODING_MONO16";
		case DC1394_COLOR_CODING_RGB16:
			return @"DC1394_COLOR_CODING_RGB16";
		case DC1394_COLOR_CODING_MONO16S:
			return @"DC1394_COLOR_CODING_MONO16S";
		case DC1394_COLOR_CODING_RGB16S:
			return @"DC1394_COLOR_CODING_RGB16S";
		case DC1394_COLOR_CODING_RAW8:
			return @"DC1394_COLOR_CODING_RAW8";
		case DC1394_COLOR_CODING_RAW16:
			return @"DC1394_COLOR_CODING_RAW16";
		default:
			return @"(unknown pixelformat)";
	}
	
	return nil;
}

- (CIImage*)ciImageWithDc1394Frame:(dc1394video_frame_t*)frame error:(NSError**)error
{
	if (NULL == frame)
		return nil;
	
	if (NULL != error)
		*error = nil;
	
	switch (frame->color_coding) {
		case DC1394_COLOR_CODING_YUV411:
		case DC1394_COLOR_CODING_YUV422:
		case DC1394_COLOR_CODING_YUV444:
	//	case DC1394_COLOR_CODING_RGB8:
		case DC1394_COLOR_CODING_RGB16:
		case DC1394_COLOR_CODING_MONO16: {
			if ((DC1394_COLOR_CODING_MONO16 == frame->color_coding || DC1394_COLOR_CODING_RGB16 == frame->color_coding) &&
				DC1394_TRUE == frame->little_endian) {
				if (NULL != error)
					*error = [NSError errorWithDomain:TFErrorDomain
												 code:TFErrorDc1394LittleEndianVideoUnsupported
											 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
													   TFLocalizedString(@"TFDc1394LittleEndianVideoUnsupportedErrorDesc", @"TFDc1394LittleEndianVideoUnsupportedErrorDesc"),
														NSLocalizedDescriptionKey,
													   TFLocalizedString(@"TFDc1394LittleEndianVideoUnsupportedErrorReason", @"TFDc1394LittleEndianVideoUnsupportedErrorReason"),
														NSLocalizedFailureReasonErrorKey,
													   TFLocalizedString(@"TFDc1394LittleEndianVideoUnsupportedErrorRecovery", @"TFDc1394LittleEndianVideoUnsupportedErrorRecovery"),
														NSLocalizedRecoverySuggestionErrorKey,
													   [NSNumber numberWithInteger:NSUTF8StringEncoding],
														NSStringEncodingErrorKey,
													   nil]];

				return nil;
			}
		
			if (_pixelBufferPoolNeedsUpdating) {
				if (NULL != _pixelBufferPool) {
					CVPixelBufferPoolRelease(_pixelBufferPool);
					_pixelBufferPool = NULL;
				}
				
				unsigned int pixelFormat = -1;
								
				switch (frame->color_coding) {
					case DC1394_COLOR_CODING_YUV422:
						pixelFormat = (DC1394_BYTE_ORDER_UYVY == frame->yuv_byte_order) ? k2vuyPixelFormat :
																						  kYUVSPixelFormat;
						break;
					case DC1394_COLOR_CODING_YUV411:
						// Core Video doesn't support this format, so it'll be converted to YUV4:2:2 instead...
						pixelFormat = k2vuyPixelFormat;
						break;
					case DC1394_COLOR_CODING_YUV444:
						// this should work out of the box, but it doesn't, so we have to go the route
						// over YUV:4:2:2, which sucks...
						//pixelFormat = k444YpCbCr8CodecType;
						//break;
						pixelFormat = k2vuyPixelFormat;
						break;
					case DC1394_COLOR_CODING_RGB8:
						pixelFormat = k24RGBPixelFormat;
						break;
					case DC1394_COLOR_CODING_RGB16:
						pixelFormat = k48RGBCodecType;
						break;
					case DC1394_COLOR_CODING_MONO16:
						pixelFormat = k16GrayCodecType;
						break;
				}
				
				NSDictionary* poolAttr = [NSDictionary dictionaryWithObjectsAndKeys:
											[NSNumber numberWithUnsignedInt:pixelFormat], (id)kCVPixelBufferPixelFormatTypeKey,
											[NSNumber numberWithUnsignedInt:frame->size[0]], (id)kCVPixelBufferWidthKey,
											[NSNumber numberWithUnsignedInt:frame->size[1]], (id)kCVPixelBufferHeightKey,
											[NSNumber numberWithUnsignedInt:0], (id)kCVPixelBufferBytesPerRowAlignmentKey,
											nil]; 
				
				
				CVReturn err = CVPixelBufferPoolCreate(kCFAllocatorDefault, NULL, (CFDictionaryRef)poolAttr, &_pixelBufferPool);
				if (kCVReturnSuccess != err) {
					// TODO: report error
				}
								
				_pixelBufferPoolNeedsUpdating = NO;
			}
			
			// WARNING: conversion is NOT thread safe!
			dc1394video_frame_t convertedFrame;						// it seems we need this for some formats, since CVPixelBuffer
			static unsigned char* conversionScratchSpace = NULL;	// apparently doesn't convert some formats properly...
			static unsigned int conversionScratchLength = 0;
			
			// these need conversion...
			if (DC1394_COLOR_CODING_YUV444 == frame->color_coding || DC1394_COLOR_CODING_YUV411 == frame->color_coding) {
				if (conversionScratchLength < 2*frame->allocated_image_bytes) {
					if (NULL == conversionScratchSpace)
						conversionScratchSpace = malloc(2*frame->allocated_image_bytes);
					else
						conversionScratchSpace = realloc(conversionScratchSpace, 2*frame->allocated_image_bytes);
					
					conversionScratchLength = 2*frame->allocated_image_bytes;
				}
			
				memcpy(&convertedFrame, frame, sizeof(dc1394video_frame_t));
				convertedFrame.image = conversionScratchSpace;
				convertedFrame.allocated_image_bytes = conversionScratchLength;
						
				convertedFrame.color_coding = DC1394_COLOR_CODING_YUV422;
				convertedFrame.yuv_byte_order = DC1394_BYTE_ORDER_UYVY;
						
				dc1394_convert_frames(frame, &convertedFrame);
				frame = &convertedFrame;
			}
			
			CVPixelBufferRef pixelBuffer = nil;
			CVReturn err = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, _pixelBufferPool, &pixelBuffer);
			
			if (kCVReturnSuccess != err) {
				if (NULL != error)
					*error = [NSError errorWithDomain:TFErrorDomain
												 code:TFErrorDc1394CVPixelBufferCreationFailed
											 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
													   TFLocalizedString(@"TFDc1394PixelBufferCreationErrorDesc", @"TFDc1394PixelBufferCreationErrorDesc"),
														NSLocalizedDescriptionKey,
													   TFLocalizedString(@"TFDc1394PixelBufferCreationErrorReason", @"TFDc1394PixelBufferCreationErrorReason"),
														NSLocalizedFailureReasonErrorKey,
													   TFLocalizedString(@"TFDc1394PixelBufferCreationErrorRecovery", @"TFDc1394PixelBufferCreationErrorRecovery"),
														NSLocalizedRecoverySuggestionErrorKey,
													   [NSNumber numberWithInteger:NSUTF8StringEncoding],
														NSStringEncodingErrorKey,
													   nil]];

				return nil;
			}
						
			err = CVPixelBufferLockBaseAddress(pixelBuffer, 0);
			
			if (kCVReturnSuccess != err) {
				// TODO: report error
			}
			
			unsigned char* baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
			memcpy(baseAddress, frame->image, frame->image_bytes);
			
			err = CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
			
			if (kCVReturnSuccess != err) {
				// TODO: report error
			}
			
			CIImage* image = nil;
			if (_delegateCapabilities.hasWantedCIImageColorSpace)
				image = [CIImage imageWithCVImageBuffer:pixelBuffer
												options:[NSDictionary dictionaryWithObject:(id)[delegate wantedCIImageColorSpaceForCapture:self]
																					forKey:kCIImageColorSpace]];
			else
				image = [CIImage imageWithCVImageBuffer:pixelBuffer];
						
			CVPixelBufferRelease(pixelBuffer);
					
			return image;
		}
		
		case DC1394_COLOR_CODING_RGB8:
		case DC1394_COLOR_CODING_MONO8: {
			CGColorSpaceRef colorSpace = nil;
			CGBitmapInfo bitmapInfo = kCGImageAlphaNone;
			size_t bitsPerComponent, bitsPerPixel;

			switch (frame->color_coding) {
				case DC1394_COLOR_CODING_RGB8: {
					static CGColorSpaceRef rgbColorSpace = NULL;
					
					if (NULL == rgbColorSpace)
						rgbColorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
					
					colorSpace = rgbColorSpace;
					bitsPerComponent = 8;
					bitsPerPixel = 24;
					
					break;
				}
				
				case DC1394_COLOR_CODING_MONO8: {
					static CGColorSpaceRef grayScaleColorSpace = NULL;
					
					if (NULL == grayScaleColorSpace)
						grayScaleColorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericGray);
					
					colorSpace = grayScaleColorSpace;
					bitsPerComponent = 8;
					bitsPerPixel = 8;
					
					break;
				}
			}
		
			CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData(
													(CFDataRef)[NSData dataWithBytes:frame->image
																			  length:frame->image_bytes]);
		
			CGImageRef cgImage = CGImageCreate(frame->size[0],
											   frame->size[1],
											   bitsPerComponent,
											   bitsPerPixel,
											   frame->stride,
											   colorSpace,
											   bitmapInfo,
											   dataProvider,
											   NULL,
											   NO,
											   kCGRenderingIntentDefault);
			
			CGDataProviderRelease(dataProvider);
			
			CIImage* image = nil;
			if (_delegateCapabilities.hasWantedCIImageColorSpace)
				image = [CIImage imageWithCGImage:cgImage
										  options:[NSDictionary dictionaryWithObject:(id)[delegate wantedCIImageColorSpaceForCapture:self]
																			  forKey:kCIImageColorSpace]];
			else
				image = [CIImage imageWithCGImage:cgImage];
			
			CGImageRelease(cgImage);
			
			return image;
		}
	}
	
	if (NULL != error)
		*error = [NSError errorWithDomain:TFErrorDomain
									 code:TFErrorDc1394UnsupportedPixelFormat
								 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
										   TFLocalizedString(@"TFDc1394PixelFormatErrorDesc", @"TFDc1394PixelFormatErrorDesc"),
										   NSLocalizedDescriptionKey,
										   TFLocalizedString(@"TFDc1394PixelFormatErrorReason", @"TFDc1394PixelFormatErrorReason"),
										   NSLocalizedFailureReasonErrorKey,
										   TFLocalizedString(@"TFDc1394PixelFormatErrorRecovery", @"TFDc1394PixelFormatErrorRecovery"),
										   NSLocalizedRecoverySuggestionErrorKey,
										   [NSNumber numberWithInteger:NSUTF8StringEncoding],
										   NSStringEncodingErrorKey,
										   nil]];

	return nil;
}

// we prefer video modes that don't need to be converted for core image (rgb8) or are easy to convert
+ (int)rankingForVideoMode:(dc1394video_mode_t)mode
{
	switch (mode) {
		case DC1394_VIDEO_MODE_640x480_RGB8:
		case DC1394_VIDEO_MODE_800x600_RGB8:
		case DC1394_VIDEO_MODE_1024x768_RGB8:
		case DC1394_VIDEO_MODE_1280x960_RGB8:
		case DC1394_VIDEO_MODE_1600x1200_RGB8:
			return 0;
		
		case DC1394_VIDEO_MODE_640x480_MONO8:
		case DC1394_VIDEO_MODE_800x600_MONO8:
		case DC1394_VIDEO_MODE_1024x768_MONO8:
		case DC1394_VIDEO_MODE_1280x960_MONO8:
		case DC1394_VIDEO_MODE_1600x1200_MONO8:
			return 1;
	
		case DC1394_VIDEO_MODE_640x480_MONO16:
		case DC1394_VIDEO_MODE_800x600_MONO16:
		case DC1394_VIDEO_MODE_1024x768_MONO16:
		case DC1394_VIDEO_MODE_1280x960_MONO16:
		case DC1394_VIDEO_MODE_1600x1200_MONO16:
			return 2;
		
		case DC1394_VIDEO_MODE_320x240_YUV422:
		case DC1394_VIDEO_MODE_640x480_YUV422:
		case DC1394_VIDEO_MODE_800x600_YUV422:
		case DC1394_VIDEO_MODE_1024x768_YUV422:
		case DC1394_VIDEO_MODE_1280x960_YUV422:
		case DC1394_VIDEO_MODE_1600x1200_YUV422:
			return 3;
		
		case DC1394_VIDEO_MODE_160x120_YUV444:
			return 4;
		
		case DC1394_VIDEO_MODE_640x480_YUV411:
			return 5;
	}
	
	return INT_MAX;
}

@end