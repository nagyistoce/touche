//
//  TFLibDC1394Capture+CIImageFromDc1394Frame.m
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

#import "TFLibDC1394Capture+CIImageFromDc1394Frame.h"
#import <QTKit/QTKit.h>
#import <dc1394/dc1394.h>

#import "TFIncludes.h"
#import "TFLibDC1394CapturePixelFormatConversions.h"

typedef struct TFLibDC1394CaptureConversionContext {
	int width, height, rowBytes, bytesPerPixel, alignment, multiples;
	dc1394color_coding_t srcColorCoding;
	unsigned int destCVPixelFormat;
	void* data;
} TFLibDC1394CaptureConversionContext;

typedef struct TFLibDC1394CaptureConversionResult {
	int success;	// zero or non-zero
	void* data;		// not owned by this structure
	unsigned int cvPixelFormat;
	int width, height, rowBytes, bytesPerPixel, alignment, totalSize;
} TFLibDC1394CaptureConversionResult;

// checks wether the given scratch space is appropriate for the given color conversion. If not,
// a new scratchspace is created (old one's free'd) and stored through the given pointer.
// the pointer to destCVPixelFormat will be filled with the CV pixel format to which srcColorCoding
// can be converted most efficiently.
void _TFLibDC1394CapturePrepareConversionScratchSpace(TFLibDC1394CaptureConversionContext** scratchSpace,
													  dc1394color_coding_t srcColorCoding,
													  unsigned int* destCVPixelFormat,
													  int width,
													  int height);

// converts a frame with a given conversion context
TFLibDC1394CaptureConversionResult _TFLibDC1394CaptureConvert(TFLibDC1394CaptureConversionContext* context,
															  dc1394video_frame_t* frame);

// returns an optimal value for rowBytes for a given image width and byterPerPixel value.
size_t _TFLibDC1394CaptureOptimalRowBytesForWidthAndBytesPerPixel(size_t width,
																  size_t bytesPerPixel);

@implementation TFLibDC1394Capture (CIImageFromDc1394Frame)

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
		case DC1394_COLOR_CODING_RGB8:
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
				unsigned int pixelAlignment = 0;
								
				switch (frame->color_coding) {
					case DC1394_COLOR_CODING_YUV422:
						pixelFormat = (DC1394_BYTE_ORDER_UYVY == frame->yuv_byte_order) ? k2vuyPixelFormat :
																						  kYUVSPixelFormat;
						break;
					case DC1394_COLOR_CODING_YUV411:
					case DC1394_COLOR_CODING_YUV444:
						_TFLibDC1394CapturePrepareConversionScratchSpace(&_pixelConversionContext,
																		 frame->color_coding,
																		 &pixelFormat,
																		 frame->size[0],
																		 frame->size[1]);
						pixelAlignment = _pixelConversionContext->alignment;
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
											[NSNumber numberWithUnsignedInt:pixelAlignment], (id)kCVPixelBufferBytesPerRowAlignmentKey,
											nil]; 
								
				CVReturn err = CVPixelBufferPoolCreate(kCFAllocatorDefault, NULL, (CFDictionaryRef)poolAttr, &_pixelBufferPool);
				if (kCVReturnSuccess != err) {
					// TODO: report error
				}
								
				_pixelBufferPoolNeedsUpdating = NO;
			}
			
			void* imageData = frame->image;
			int imageDataSize = frame->image_bytes;
						
			// do pixel format conversion if needed.
			if (DC1394_COLOR_CODING_YUV444 == frame->color_coding		||
				DC1394_COLOR_CODING_YUV411 == frame->color_coding) {
				
				TFLibDC1394CaptureConversionResult conversionResult =
					_TFLibDC1394CaptureConvert(_pixelConversionContext, frame);
			
				imageData = conversionResult.data;
				imageDataSize = conversionResult.totalSize;
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
			memcpy(baseAddress, imageData, imageDataSize);
			
			err = CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
			
			if (kCVReturnSuccess != err) {
				// TODO: report error
			}
			
			CIImage* image = nil;
			if (_delegateCapabilities.hasWantedCIImageColorSpace) {
				id colorSpace = (id)[delegate wantedCIImageColorSpaceForCapture:self];
				if (nil == colorSpace)
					colorSpace = [NSNull null];
				
				image = [CIImage imageWithCVImageBuffer:pixelBuffer
												options:[NSDictionary dictionaryWithObject:colorSpace
																					forKey:kCIImageColorSpace]];
			} else
				image = [CIImage imageWithCVImageBuffer:pixelBuffer];
						
			CVPixelBufferRelease(pixelBuffer);
					
			return image;
		}
		
		//case DC1394_COLOR_CODING_RGB8:
		case DC1394_COLOR_CODING_MONO8: {
			CGColorSpaceRef colorSpace = nil;
			CGBitmapInfo bitmapInfo = kCGImageAlphaNone;
			size_t bitsPerComponent = 8, bitsPerPixel = 24;

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
			if (_delegateCapabilities.hasWantedCIImageColorSpace) {
				id colorSpace = (id)[delegate wantedCIImageColorSpaceForCapture:self];
				if (nil == colorSpace)
					colorSpace = [NSNull null];
				
				image = [CIImage imageWithCGImage:cgImage
										  options:[NSDictionary dictionaryWithObject:(id)colorSpace
																			  forKey:kCIImageColorSpace]];
			} else
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

void _TFLibDC1394CapturePrepareConversionScratchSpace(TFLibDC1394CaptureConversionContext** pScratchSpace,
													  dc1394color_coding_t srcColorCoding,
													  unsigned int *destCVPixelFormat,
													  int width,
													  int height)
{
	if (NULL == pScratchSpace)
		return;
	
	TFLibDC1394CaptureConversionContext* scratchSpace = *pScratchSpace;
	
	int wantedBytesPerPixel = 0;
	BOOL wantsAlignedRowBytes = YES;
	unsigned int selectedCVFormat;
	unsigned int multiples = 1;
	
	switch (srcColorCoding) {
		case DC1394_COLOR_CODING_YUV411:
#if defined(_USES_IPP_)
			wantsAlignedRowBytes = YES;
#else
			wantsAlignedRowBytes = NO;
			selectedCVFormat = k32ARGBPixelFormat;
			wantedBytesPerPixel = 4;
#endif
			break;
		
		DC1394_COLOR_CODING_YUV444:
			wantsAlignedRowBytes = YES;
			selectedCVFormat = k32ARGBPixelFormat;
			wantedBytesPerPixel = 4;
			multiples = 2;
			break;
					
		default:
			break;
	}
	
	if (0 == wantedBytesPerPixel)
		return;

	if (NULL != destCVPixelFormat)
		*destCVPixelFormat = selectedCVFormat;
	
	if (NULL != scratchSpace) {
		if (scratchSpace->srcColorCoding != srcColorCoding			||
			scratchSpace->width != width							||
			scratchSpace->height != height							||
			scratchSpace->bytesPerPixel != wantedBytesPerPixel		||
			scratchSpace->multiples != multiples) {
				free(scratchSpace->data);
				free(scratchSpace);
				scratchSpace = NULL;
		}
	}
	
	// scratchSpace is fine for this conversion, don't do anything
	if (NULL != scratchSpace)
		return;
	
	// allocate a new scratchSpace.
	// TODO: some unchecked malloc's here...
	scratchSpace = (TFLibDC1394CaptureConversionContext*)
						malloc(sizeof(TFLibDC1394CaptureConversionContext));
	
	scratchSpace->width = width;
	scratchSpace->height = height;
	scratchSpace->srcColorCoding = srcColorCoding;
	scratchSpace->destCVPixelFormat = selectedCVFormat;
	scratchSpace->bytesPerPixel = wantedBytesPerPixel;
	scratchSpace->multiples = multiples;

	if (wantsAlignedRowBytes) {
		scratchSpace->rowBytes = _TFLibDC1394CaptureOptimalRowBytesForWidthAndBytesPerPixel(width,
																							wantedBytesPerPixel);
		scratchSpace->data = malloc(multiples * scratchSpace->rowBytes * height);
		
		ptrdiff_t p = (ptrdiff_t)((char*)scratchSpace->data + scratchSpace->rowBytes);
		int i = 1;
		while (0 == p % i)
			i >>= 1;
		
		scratchSpace->alignment = i;
		
		NSLog(@"alignment of scratch buffer is %d\n", i);
	} else {
		scratchSpace->rowBytes = wantedBytesPerPixel * width;
		scratchSpace->data = malloc(multiples * scratchSpace->rowBytes * height);
		scratchSpace->alignment = 0;
	}
	
	*pScratchSpace = scratchSpace;
}

TFLibDC1394CaptureConversionResult _TFLibDC1394CaptureConvert(TFLibDC1394CaptureConversionContext* context,
															  dc1394video_frame_t* frame)
{
	if (NULL == context) {
		TFLibDC1394CaptureConversionResult r = { 0, NULL, 0, 0, 0, 0, 0, 0 };
		return r;
	}
	
	TFLibDC1394CaptureConversionResult result = { 0,
												  context->data,
												  context->destCVPixelFormat,
												  context->width,
												  context->height,
												  context->rowBytes,
												  context->bytesPerPixel,
												  context->alignment,
												  context->rowBytes * context->height };
	
	if (frame->color_coding == context->srcColorCoding) {
		if (DC1394_COLOR_CODING_YUV411 == frame->color_coding	&&
			k32ARGBPixelFormat == context->destCVPixelFormat) {
			
			TFLibDC1394PixelFormatConvertYUV411toARGB8(frame->image,
													   context->data,
													   context->width,
													   context->height);

			result.success = 1;
		} else if (DC1394_COLOR_CODING_YUV444 == frame->color_coding	&&
			k32ARGBPixelFormat == context->destCVPixelFormat) {
		
			TFLibDC1394PixelFormatConvertYUV444toARGB8(frame->image,
													   3*frame->size[0],
													   context->data,
													   context->rowBytes,
													   ((uint8_t*)context->data + (context->height * context->rowBytes)),
													   context->rowBytes,
													   context->width,
													   context->height);
			
		}
	}
	
	return result;
}

size_t _TFLibDC1394CaptureOptimalRowBytesForWidthAndBytesPerPixel(size_t width, size_t bytesPerPixel)
{
	size_t rowBytes = width * bytesPerPixel;
	
	// Widen rowBytes out to a integer multiple of 16 bytes
	rowBytes = (rowBytes + 15) & ~15;
	
	// Make sure we are not an even power of 2 wide. 
	// Will loop a few times for rowBytes <= 16.
	while(0 == (rowBytes & (rowBytes - 1)))
		rowBytes += 16;
	
	return rowBytes;
}
