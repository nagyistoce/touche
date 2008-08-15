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

- (CVPixelBufferRef)pixelBufferWithDc1394Frame:(dc1394video_frame_t*)frame error:(NSError**)error
{
	if (NULL == frame)
		return nil;
	
	if (NULL != error)
		*error = nil;
	
	switch (frame->color_coding) {
		case DC1394_COLOR_CODING_YUV422:
		case DC1394_COLOR_CODING_YUV444:
		case DC1394_COLOR_CODING_RGB8:
		case DC1394_COLOR_CODING_RGB16: {
			if (DC1394_COLOR_CODING_RGB16 == frame->color_coding && DC1394_TRUE == frame->little_endian) {
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
		
			OSType pixelType = 0;
			
			switch (frame->color_coding) {
				case DC1394_COLOR_CODING_YUV422:
					pixelType = (DC1394_BYTE_ORDER_UYVY == frame->yuv_byte_order) ? k2vuyPixelFormat :
																					kYUVSPixelFormat;
					break;
				case DC1394_COLOR_CODING_YUV444:
					pixelType = k444YpCbCr8CodecType;
					break;
				case DC1394_COLOR_CODING_RGB8:
					pixelType = k24RGBPixelFormat;
					break;
				case DC1394_COLOR_CODING_RGB16:
					pixelType = k48RGBPixelFormat;
					break;
			}
			
			
			CVPixelBufferRef pixelBuffer = nil;
			CVReturn err = CVPixelBufferCreateWithBytes(NULL,
														frame->size[0],
														frame->size[1],
														pixelType,
														frame->image,
														frame->stride,
														NULL,
														NULL,
														nil,
														&pixelBuffer);
			
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
			
			return pixelBuffer;
		}
		
		case DC1394_COLOR_CODING_MONO8:
		case DC1394_COLOR_CODING_MONO16: {
			if (DC1394_COLOR_CODING_MONO16 == frame->color_coding && DC1394_TRUE == frame->little_endian) {
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
		
			OSType pixelFormat = (DC1394_COLOR_CODING_MONO8 == frame->color_coding) ? k24RGBPixelFormat : k48RGBPixelFormat;
		
			void* planeAddresses[3];
			size_t planeWidths[3];
			size_t planeHeights[3];
			size_t planeBytesPerRow[3];
			
			int i;
			for (i=0; i<3; i++) {
				planeAddresses[i] = frame->image;
				planeWidths[i] = frame->size[0];
				planeHeights[i] = frame->size[1];
				planeBytesPerRow[i] = frame->stride;
			}
		
			CVPixelBufferRef pixelBuffer = nil;
			CVReturn err = CVPixelBufferCreateWithPlanarBytes(NULL,
															  frame->size[0],
															  frame->size[1],
															  pixelFormat,
															  NULL,
															  0,
															  3,
															  planeAddresses,
															  planeWidths,
															  planeHeights,
															  planeBytesPerRow,
															  NULL,
															  nil,
															  nil,
															  &pixelBuffer);
			
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
			
			return pixelBuffer;
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
- (int)rankingForVideoMode:(dc1394video_mode_t)mode
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
	
		case DC1394_VIDEO_MODE_160x120_YUV444:
			return 3;
		
		case DC1394_VIDEO_MODE_320x240_YUV422:
		case DC1394_VIDEO_MODE_640x480_YUV422:
		case DC1394_VIDEO_MODE_800x600_YUV422:
		case DC1394_VIDEO_MODE_1024x768_YUV422:
		case DC1394_VIDEO_MODE_1280x960_YUV422:
		case DC1394_VIDEO_MODE_1600x1200_YUV422:
			return 4;
		
		case DC1394_VIDEO_MODE_640x480_YUV411:
			return 5;
	}
	
	return INT_MAX;
}

@end
