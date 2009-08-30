//
//  CIImage+MakeBitmaps.m
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
//  CGBitmapContext-backed rendering based on:
//	http://www.geekspiff.com/unlinkedCrap/ciImageToBitmap.html

// TODO: glReadPixels() method does not yet support Float output for the color
//		 channels.

#import "CIImage+MakeBitmaps.h"

#import "CIImage+MakeBitmapsSupport.h"

#import <Accelerate/Accelerate.h>
#import <OpenGL/gl.h>
#import <OpenGL/OpenGL.h>
#import <mach/mach.h>
#import <mach/mach_time.h>

#if defined(_USES_IPP_)
#import <ipp.h>
#import <ippi.h>
#endif

typedef enum {
	CIImageInternalOutputPixelFormatARGB8,
	CIImageInternalOutputPixelFormatRGBA8,
	CIImageInternalOutputPixelFormatRGBAF,
	CIImageInternalOutputPixelFormatRGB8,
	CIImageInternalOutputPixelFormatGray8
} CIImageInternalOutputPixelFormat;

typedef enum {
	CIImageInternalBitmapCreationMethodBitmapContextBackedCIContext = 0,
	CIImageInternalBitmapCreationMethodCIContextRender,
	CIImageInternalBitmapCreationMethodGlReadPixels,
	CIImageInternalBitmapCreationMethodUndetermined
} CIImageInternalBitmapCreationMethod;

#define CIImageInternalBitmapCreationMethodMin	(CIImageInternalBitmapCreationMethodBitmapContextBackedCIContext)
#define	CIImageInternalBitmapCreationMethodMax	(CIImageInternalBitmapCreationMethodGlReadPixels)
#define CIImageInternalBitmapCreationMethodCnt	(CIImageInternalBitmapCreationMethodMax - CIImageInternalBitmapCreationMethodMin + 1)
#define CIImageInternalBitmapCreationMethodDefault	(CIImageInternalBitmapCreationMethodGlReadPixels)

#define DYNAMIC_METHOD_SELECTION_SAMPLE_COUNT	(5)

#define MAX_INTERNAL_DATA_SCRATCH_SPACE		(4)

typedef struct CIImageBitmapsInternalData {
	size_t								width, height;
	CGFloat								aspectRatio;

	CGColorSpaceRef						colorSpace, ciOutputColorSpace, ciWorkingColorSpace;
	CGContextRef						cgContext;
	CIContext*							ciContextcgContext;		// CGBitmapContext-backed CIContext
	CGLContextObj						cglContext;
	CIContext*							ciContextglContext;		// CGLContext-backed CIContext	
	CGRect								glrpRenderImgRect;
	GLenum								glrpFormatType, glrpPixelFormatType;
	CGLContextObj						glrpCglContext;
	GLboolean							glrpHasPbo;
	GLuint								glrpPboId;
	CGLPBufferObj						glrpPBObj;
	CIContext*							glrpCiContext;			// rendering via glReadPixels()
	
	BOOL								renderOnCPU;
	
	CIImageInternalOutputPixelFormat	internalOutputPixelFormat;
	CGBitmapInfo						bitmapInfo;
	NSUInteger							bytesPerPixel;
	int									rowBytes;
	void*								outputBuffer;
	
	BOOL								borderDrawingEnabled;
	float								borderA, borderR, borderG, borderB;
	
	CIImageInternalBitmapCreationMethod	chosenCreationMethod;

	void* scratchSpace[MAX_INTERNAL_DATA_SCRATCH_SPACE];
	int scratchRowBytes[MAX_INTERNAL_DATA_SCRATCH_SPACE];
	
	uint64_t measuredNanosPerMethod[CIImageInternalBitmapCreationMethodCnt];
	unsigned measurementsPerMethodCount[CIImageInternalBitmapCreationMethodCnt];
} CIImageBitmapsInternalData;

#define RELEASE_CF_MEMBER(c)	do { if (NULL != (c)) { CFRelease((c)); (c) = NULL; } } while (0)

// quick way to make a CIImageBitmapData struct (like NSMakeRange(), for example)
inline CIImageBitmapData _CIImagePrivateMakeBitmapData(void* data,
													   size_t width,
													   size_t height,
													   size_t rowBytes);

// common initialization stuff for all bitmap creation context types
CIImageBitmapsInternalData* _CIImagePrivateInitializeBitmapCreationContext(CIImage* image);

// common initialization stuff for all bitmap creation context types
void* _CIImagePrivateFinalizeBitmapCreationContext(CIImageBitmapsInternalData* context,
												   CIImage* image,
												   BOOL renderOnCPU);

// set up the CGLContext for rendering CIImages to an FBO
void _CIImagePrivateCreateCGLContextForGlReadPixels(CIImageBitmapsInternalData* context,
													CIImage* image,
													BOOL renderOnCPU);

// returns the optimal rowBytes for a pixel buffer with respect to memory alignment
size_t _CIImagePrivateOptimalRowBytesForWidthAndBytesPerPixel(size_t width, size_t bytesPerPixel);

// returns non-zero on success, zero on error
int _CIImagePrivateConvertCIFormatPixelFormats(void* dest,
											   int destRowBytes,
											   CIImageBitmapsInternalData* internalData,
											   int width,
											   int height,
											   CIImageInternalOutputPixelFormat destFormat,
											   CIFormat srcFormat);

int _CIImagePrivateConvertOpenGLPixelFormats(void* dest,
											 int destRowBytes,
											 CIImageBitmapsInternalData* internalData,
											 int width,
											 int height,
											 CIImageInternalOutputPixelFormat destFormat,
											 GLenum openglPixelFormatType,
											 GLenum openglType);

// get the amount of nanoseconds since the system was started (used to determine the fastest
// rendering method dynamically)
uint64_t _CIImagePrivateGetCurrentNanoseconds();

// allocates memory like malloc, but with the correct alignment for a given high-performance
// image manipulation library
// height and width in pixels, rowBytes in bytes
// rowBytes may be modified by this call.
void* _CIImageBitmapsMalloc(int width, int height, int* rowBytes, CIImageInternalOutputPixelFormat pixelFormat);

// frees a pointer allocated with the above malloc variant.
void _CIImageBitmapsFree(void* ptr);

@implementation CIImage (MakeBitmapsExtensions)

+ (CGColorSpaceRef)screenColorSpace
{
	CMProfileRef systemProfile = NULL;
	OSStatus status = CMGetSystemProfile(&systemProfile);
	
	if (noErr != status)
		return nil;
		
	CGColorSpaceRef colorSpace = CGColorSpaceCreateWithPlatformColorSpace(systemProfile);
	
	CMCloseProfile(systemProfile);
	
	return (CGColorSpaceRef)[(id)colorSpace autorelease];
}

- (CIImageBitmapData)bitmapDataWithBitmapCreationContext:(void*)pContext
{		
	uint64_t beforeTime;
	BOOL measurePerformance = NO;
	CIImageBitmapsInternalData* context = (CIImageBitmapsInternalData*)pContext;
	CIImageInternalBitmapCreationMethod method = context->chosenCreationMethod;
	CIImageBitmapData bitmapData = _CIImagePrivateMakeBitmapData(NULL, 0, 0, 0);
	CGRect extent = [self extent];
	
	if (NULL == context || CGRectIsInfinite(extent))
		goto errorReturn;
	
	if (CIImageInternalBitmapCreationMethodUndetermined == method) {
		measurePerformance = YES;
	
		uint64_t minNanos = UINT64_MAX;
		int minIndex = CIImageInternalBitmapCreationMethodMin;
		int i = CIImageInternalBitmapCreationMethodMin;
		
		for (i; i<=CIImageInternalBitmapCreationMethodMax; i++) {
			// exclude on-GPU rendering of CGContext-backed context, since this would be a massive leak.
			if (!context->renderOnCPU && i == CIImageInternalBitmapCreationMethodBitmapContextBackedCIContext)
				continue;
					
			if (context->measurementsPerMethodCount[i] < DYNAMIC_METHOD_SELECTION_SAMPLE_COUNT) {
				method = i;
				goto methodDetermined;
			} else if (context->measuredNanosPerMethod[i] < minNanos) {
				minNanos = context->measuredNanosPerMethod[i];
				minIndex = i;
			}
		}
		
		// if we're here, we have enough samples for all rendering methods. now determine the fastest one.
		context->chosenCreationMethod = minIndex;
		method = minIndex;
				
		for (i=CIImageInternalBitmapCreationMethodMin; i<CIImageInternalBitmapCreationMethodMax; i++) {
			if (i == method)
				continue;
			
			switch (i) {
				case CIImageInternalBitmapCreationMethodGlReadPixels:
					[(context->glrpCiContext) clearCaches];
					[(context->glrpCiContext) reclaimResources];
					break;
				case CIImageInternalBitmapCreationMethodCIContextRender:
					[(context->ciContextglContext) clearCaches];
					[(context->ciContextglContext) reclaimResources];
					break;
				case CIImageInternalBitmapCreationMethodBitmapContextBackedCIContext:
					[(context->ciContextcgContext) clearCaches];
					[(context->ciContextcgContext) reclaimResources];
					break;
				default:
					break;
			}
		}
	}
	
methodDetermined:
	
	if (measurePerformance)
		beforeTime = _CIImagePrivateGetCurrentNanoseconds(); 
	
	switch (method) {
		case CIImageInternalBitmapCreationMethodBitmapContextBackedCIContext: {
			CGContextSaveGState(context->cgContext);
			[(context->ciContextcgContext) drawImage:self
											 atPoint:CGPointZero
											fromRect:extent];
			CGContextFlush(context->cgContext);
			CGContextRestoreGState(context->cgContext);
			
			context->rowBytes = CGBitmapContextGetBytesPerRow(context->cgContext);
			
			break;
		}
		
		case CIImageInternalBitmapCreationMethodCIContextRender: {
			CIFormat renderFormat = kCIFormatRGBAf;
			int renderRowBytes = context->rowBytes;
			void* renderBuffer = context->outputBuffer;
			
			switch(context->internalOutputPixelFormat) {
				case CIImageInternalOutputPixelFormatRGB8:
					renderFormat = kCIFormatARGB8;
					renderRowBytes = context->scratchRowBytes[0];
					renderBuffer = context->scratchSpace[0];
					break;
				case CIImageInternalOutputPixelFormatGray8:
					renderFormat = kCIFormatARGB8;
					renderRowBytes = context->scratchRowBytes[0];
					renderBuffer = context->scratchSpace[0];
					break;
				case CIImageInternalOutputPixelFormatARGB8:
					renderFormat = kCIFormatARGB8;
					renderRowBytes = context->rowBytes;
					renderBuffer = context->outputBuffer;
					break;
				case CIImageInternalOutputPixelFormatRGBA8:
					renderFormat = kCIFormatARGB8;
					renderRowBytes = context->scratchRowBytes[0];
					renderBuffer = context->scratchSpace[0];
					break;
				case CIImageInternalOutputPixelFormatRGBAF:
					renderFormat = kCIFormatRGBAf;
					renderRowBytes = context->rowBytes;
					renderBuffer = context->outputBuffer;
					break;
				default:
					break;
			}
						
			[(context->ciContextglContext) render:self
										 toBitmap:renderBuffer
										 rowBytes:renderRowBytes
										   bounds:extent
										   format:renderFormat
									   colorSpace:NULL];
						
			if (context->borderDrawingEnabled) {
				if (kCIFormatARGB8 == renderFormat) {
					unsigned char channels[] = { context->borderA * 255,
												 context->borderR * 255,
												 context->borderG * 255,
												 context->borderB * 255 };
				
					CIImageBitmaps1PixelImageBorder8888(renderBuffer,
														 renderRowBytes,
														 context->width,
														 context->height,
														 channels);
				} else if (kCIFormatRGBAf) {
					float channels[] = { context->borderA,
										 context->borderR,
										 context->borderG,
										 context->borderB };
					
					CIImageBitmaps1PixelImageBorderFFFF(renderBuffer,
														 renderRowBytes,
														 context->width,
														 context->height,
														 channels);
					
				}
			}
			
			switch (context->internalOutputPixelFormat) {
				case CIImageInternalOutputPixelFormatGray8:
					_CIImagePrivateConvertCIFormatPixelFormats(context->outputBuffer,
															   context->rowBytes,
															   context,
															   context->width,
															   context->height,
															   CIImageInternalOutputPixelFormatGray8,
															   kCIFormatARGB8);
					break;
				case CIImageInternalOutputPixelFormatRGBA8:
					_CIImagePrivateConvertCIFormatPixelFormats(context->outputBuffer,
															   context->rowBytes,
															   context,
															   context->width,
															   context->height,
															   CIImageInternalOutputPixelFormatRGBA8,
															   kCIFormatARGB8);
					break;
				case CIImageInternalOutputPixelFormatRGB8:
					_CIImagePrivateConvertCIFormatPixelFormats(context->outputBuffer,
															   context->rowBytes,
															   context,
															   context->width,
															   context->height,
															   CIImageInternalOutputPixelFormatRGB8,
															   kCIFormatARGB8);
					break;
				default:
					break;
			}
			
			break;
		}
			
		case CIImageInternalBitmapCreationMethodGlReadPixels: {
			int renderRowBytes = context->rowBytes;
			void* renderBuffer = context->outputBuffer;
			
			switch(context->internalOutputPixelFormat) {
				case CIImageInternalOutputPixelFormatRGB8:
					renderRowBytes = context->scratchRowBytes[0];
					renderBuffer = context->scratchSpace[0];
					break;
				case CIImageInternalOutputPixelFormatGray8:
					renderRowBytes = context->scratchRowBytes[0];
					renderBuffer = context->scratchSpace[0];
					break;
				case CIImageInternalOutputPixelFormatARGB8:
					renderRowBytes = context->rowBytes;
					renderBuffer = context->outputBuffer;
					break;
				case CIImageInternalOutputPixelFormatRGBA8:
					renderRowBytes = context->scratchRowBytes[0];
					renderBuffer = context->scratchSpace[0];
					break;
				// TODO: support RGBAF output
				/*case CIImageInternalOutputPixelFormatRGBAF:
					renderRowBytes = context->rowBytes;
					renderBuffer = context->outputBuffer;
					break;*/
				default:
					break;
			}
			
			CGLSetCurrentContext(context->glrpCglContext);
															
			[context->glrpCiContext drawImage:self
									 atPoint:CGPointZero
									fromRect:context->glrpRenderImgRect];
			
			if (context->glrpHasPbo) {
				glBindBufferARB(GL_PIXEL_PACK_BUFFER_ARB, context->glrpPboId);
				glReadPixels(0,
							 0,
							 context->width,
							 context->height,
							 context->glrpPixelFormatType,
							 context->glrpFormatType,
							 0);
				// this is needed because of an Apple bug, where glMapBufferARB() doesn't always
				// return after the DMA is finished, but earlier...
				glFinishObjectAPPLE(GL_BUFFER_OBJECT_APPLE, context->glrpPboId);
				GLubyte* ptr = (GLubyte*)glMapBufferARB(GL_PIXEL_PACK_BUFFER_ARB,
														GL_READ_ONLY);
										
				if (ptr) {
#if defined(_USES_IPP_)
					IppiSize roiSize = { context->width, context->height };
					switch (context->glrpFormatType) {
						case GL_UNSIGNED_INT_8_8_8_8_REV:
						default:
							ippiCopy_8u_C4R(ptr,
											renderRowBytes,
											renderBuffer,
											renderRowBytes,
											roiSize);
							break;
					}
#else
					memcpy(renderBuffer, ptr, renderRowBytes * context->height);
#endif
					glUnmapBufferARB(GL_PIXEL_PACK_BUFFER_ARB);
				}
				
				glBindBuffer(GL_PIXEL_PACK_BUFFER_ARB, 0);
			} else {
				glReadPixels(0,
							 0,
							 context->width,
							 context->height,
							 context->glrpPixelFormatType,
							 context->glrpFormatType,
							 renderBuffer);
			}
															
			CGLSetCurrentContext(NULL);
						
			if (context->borderDrawingEnabled) {
				unsigned char channels[] = { context->borderB * 255,
					context->borderG * 255,
					context->borderR * 255,
					context->borderA * 255 };
				
				CIImageBitmaps1PixelImageBorder8888(renderBuffer,
													renderRowBytes,
													context->width,
													context->height,
													channels);
			}
			
			switch (context->internalOutputPixelFormat) {
				case CIImageInternalOutputPixelFormatGray8:
					_CIImagePrivateConvertOpenGLPixelFormats(context->outputBuffer,
															 context->rowBytes,
															 context,
															 context->width,
															 context->height,
															 CIImageInternalOutputPixelFormatGray8,
															 context->glrpPixelFormatType,
															 context->glrpFormatType);
					break;
				case CIImageInternalOutputPixelFormatRGBA8:
					_CIImagePrivateConvertOpenGLPixelFormats(context->outputBuffer,
															 context->rowBytes,
															 context,
															 context->width,
															 context->height,
															 CIImageInternalOutputPixelFormatRGBA8,
															 context->glrpPixelFormatType,
															 context->glrpFormatType);
					break;
				case CIImageInternalOutputPixelFormatRGB8:
					_CIImagePrivateConvertOpenGLPixelFormats(context->outputBuffer,
															 context->rowBytes,
															 context,
															 context->width,
															 context->height,
															 CIImageInternalOutputPixelFormatRGB8,
															 context->glrpPixelFormatType,
															 context->glrpFormatType);
					break;
				default:
					break;
			}
				
			break;
		}
		
		default:
			goto errorReturn;
			break;
	}
	
	if (measurePerformance) {
		uint64_t time = _CIImagePrivateGetCurrentNanoseconds() - beforeTime;
		context->measuredNanosPerMethod[method] = (context->measuredNanosPerMethod[method] >> 1) + (time >> 1);
		context->measurementsPerMethodCount[method] += 1;
	}
	
	bitmapData = _CIImagePrivateMakeBitmapData(context->outputBuffer,
											   context->width,
											   context->height,
											   context->rowBytes);
	
errorReturn:
	return bitmapData;
}

@end

void* CIImageBitmapsCreateContextForPremultipliedARGB8(CIImage* image, BOOL renderOnCPU)
{
	CIImageBitmapsInternalData* context =  _CIImagePrivateInitializeBitmapCreationContext(image);
	
	if (NULL != context) {
		context->colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
		context->internalOutputPixelFormat = CIImageInternalOutputPixelFormatARGB8;
		context->bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host;
		context->bytesPerPixel = 4;
	}
	
	return _CIImagePrivateFinalizeBitmapCreationContext(context, image, renderOnCPU);
}

void* CIImageBitmapsCreateContextForPremultipliedRGBA8(CIImage* image, BOOL renderOnCPU)
{
	CIImageBitmapsInternalData* context =  _CIImagePrivateInitializeBitmapCreationContext(image);
	
	if (NULL != context) {
		context->colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
		context->internalOutputPixelFormat = CIImageInternalOutputPixelFormatRGBA8;
		context->bitmapInfo = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Host;
		context->bytesPerPixel = 4;
	}
	
	return _CIImagePrivateFinalizeBitmapCreationContext(context, image, renderOnCPU);
}

void* CIImageBitmapsCreateContextForPremultipliedRGBAf(CIImage* image, BOOL renderOnCPU)
{
	CIImageBitmapsInternalData* context =  _CIImagePrivateInitializeBitmapCreationContext(image);
	
	if (NULL != context) {
		context->colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
		context->internalOutputPixelFormat = CIImageInternalOutputPixelFormatRGBAF;
		context->bitmapInfo =  kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Host | kCGBitmapFloatComponents;
		context->bytesPerPixel = 16;
	}
	
	return _CIImagePrivateFinalizeBitmapCreationContext(context, image, renderOnCPU);
}

void* CIImageBitmapsCreateContextForRGB8(CIImage* image, BOOL renderOnCPU) {
	CIImageBitmapsInternalData* context =  _CIImagePrivateInitializeBitmapCreationContext(image);
	
	if (NULL != context) {
		context->colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
		context->internalOutputPixelFormat = CIImageInternalOutputPixelFormatRGB8;
		context->bitmapInfo = kCGImageAlphaNone | kCGBitmapByteOrder32Host;
		context->bytesPerPixel = 3;
	}
	
	return _CIImagePrivateFinalizeBitmapCreationContext(context, image, renderOnCPU);
}

void* CIImageBitmapsCreateContextForGrayscale8(CIImage* image, BOOL renderOnCPU)
{
	CIImageBitmapsInternalData* context =  _CIImagePrivateInitializeBitmapCreationContext(image);
	
	if (NULL != context) {
		context->colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericGray);
		context->internalOutputPixelFormat = CIImageInternalOutputPixelFormatGray8;
		context->bitmapInfo = kCGImageAlphaNone;
		context->bytesPerPixel = 1;
	}
	
	return _CIImagePrivateFinalizeBitmapCreationContext(context, image, renderOnCPU);
}

void CIImageBitmapsReleaseContext(void* pContext)
{
	if (NULL != pContext) {
		CIImageBitmapsInternalData* context = (CIImageBitmapsInternalData*)pContext;
		
		[context->ciContextcgContext release];
		context->ciContextcgContext = nil;
		
		[context->ciContextglContext release];
		context->ciContextglContext = nil;
		
		[context->glrpCiContext release];
		context->glrpCiContext = nil;
		
		if (NULL != context->glrpCglContext) {
			if (context->glrpHasPbo && 0 != context->glrpPboId) {
				CGLSetCurrentContext(context->glrpCglContext);
				glDeleteBuffersARB(1, &context->glrpPboId);
				context->glrpPboId = 0;
				CGLSetCurrentContext(NULL);
			}
		
			CGLClearDrawable(context->glrpCglContext);
			
			CGLDestroyContext(context->glrpCglContext);
			context->glrpCglContext = NULL;
		}
		
		if (NULL != context->glrpPBObj) {
			if (NULL != context->glrpCglContext)
				CGLDestroyPBuffer(context->glrpPBObj);
			context->glrpPBObj = NULL;
		}
		
		RELEASE_CF_MEMBER(context->colorSpace);
		RELEASE_CF_MEMBER(context->ciOutputColorSpace);
		RELEASE_CF_MEMBER(context->ciWorkingColorSpace);
		RELEASE_CF_MEMBER(context->cgContext);
		
		if (NULL != context->cglContext)
			CGLDestroyContext(context->cglContext);
		context->cglContext = NULL;
		
		_CIImageBitmapsFree(context->outputBuffer);
		
		int i;
		for (i=0; i<MAX_INTERNAL_DATA_SCRATCH_SPACE; i++)
			if (NULL != context->scratchSpace[i]) {
				_CIImageBitmapsFree(context->scratchSpace[i]);
				context->scratchSpace[i] = NULL;
				context->scratchRowBytes[i] = 0;
			}
		
		free(context);
	}
}

void CIImageBitmapsSetContextDeterminesFastestRenderingDynamically(void* pContext, BOOL determineDynamically)
{
	CIImageBitmapsInternalData* context = (CIImageBitmapsInternalData*)pContext;
	
	if (determineDynamically)
		context->chosenCreationMethod = CIImageInternalBitmapCreationMethodUndetermined;
	else
		context->chosenCreationMethod = CIImageInternalBitmapCreationMethodDefault;
}

void CIImageBitmapsSetContextShouldBorderImage(void* pContext, BOOL shouldBorder)
{
	CIImageBitmapsInternalData* context = (CIImageBitmapsInternalData*)pContext;
	context->borderDrawingEnabled = shouldBorder;
}

void CIImageBitmapsSetContextBorderColor(void* pContext, float a, float r, float g, float b)
{
	CIImageBitmapsInternalData* context = (CIImageBitmapsInternalData*)pContext;
	context->borderA = MIN(1.0f, MAX(a, 0.0f));
	context->borderR = MIN(1.0f, MAX(r, 0.0f));
	context->borderG = MIN(1.0f, MAX(g, 0.0f));
	context->borderB = MIN(1.0f, MAX(b, 0.0f));
}

inline BOOL CIImageBitmapsContextMatchesBitmapSize(void* pContext, CGSize size)
{
	CIImageBitmapsInternalData* context = (CIImageBitmapsInternalData*)pContext;
	return ((size_t)size.width == context->width && (size_t)size.height == context->height);
}

inline BOOL CIImageBitmapsContextRendersOnCPU(void* pContext)
{
	CIImageBitmapsInternalData* context = (CIImageBitmapsInternalData*)pContext;
	return context->renderOnCPU;
}

inline CIImageBitmapData CIImageBitmapsCurrentBitmapDataForContext(void* pContext)
{
	CIImageBitmapsInternalData* context = (CIImageBitmapsInternalData*)pContext;
	return _CIImagePrivateMakeBitmapData(context->outputBuffer,
										 context->width,
										 context->height,
										 context->rowBytes);
}

inline CGColorSpaceRef CIImageBitmapsCIOutputColorSpaceForContext(void* pContext)
{
	CIImageBitmapsInternalData* context = (CIImageBitmapsInternalData*)pContext;
	return context->ciOutputColorSpace;
}

inline CGColorSpaceRef CIImageBitmapsCIWorkingColorSpaceForContext(void* pContext)
{
	CIImageBitmapsInternalData* context = (CIImageBitmapsInternalData*)pContext;
	return context->ciWorkingColorSpace;
}

inline CIImageBitmapData _CIImagePrivateMakeBitmapData(void* data,
													   size_t width,
													   size_t height,
													   size_t rowBytes)
{
#if defined (_USES_IPP_)
	static BOOL ippInitialized = NO;
	
	if (!ippInitialized) {
		ippStaticInit();
		ippInitialized = YES;
	}
#endif
	
	CIImageBitmapData bitmapData = { data, width, height, rowBytes };
	return bitmapData;
}

CIImageBitmapsInternalData* _CIImagePrivateInitializeBitmapCreationContext(CIImage* image)
{
	if (nil == image || CGRectIsInfinite([image extent]))
		return NULL;
	
	CIImageBitmapsInternalData* context =
		(CIImageBitmapsInternalData*)malloc(sizeof(CIImageBitmapsInternalData));
	
	if (NULL != context)	
		memset(context, 0, sizeof(CIImageBitmapsInternalData));
	
	CGRect extent = [image extent];
	
	context->width = extent.size.width;
	context->height = extent.size.height;
	context->aspectRatio = extent.size.width / extent.size.height;
	
	return context;
}

void* _CIImagePrivateFinalizeBitmapCreationContext(CIImageBitmapsInternalData* context,
												   CIImage* image,
												   BOOL renderOnCPU)
{
	if (NULL == context)
		return NULL;
	
	context->rowBytes = _CIImagePrivateOptimalRowBytesForWidthAndBytesPerPixel(context->width, context->bytesPerPixel);
	context->outputBuffer = _CIImageBitmapsMalloc(context->width, context->height, &context->rowBytes, context->internalOutputPixelFormat);
	
	context->renderOnCPU = renderOnCPU;
	context->chosenCreationMethod = CIImageInternalBitmapCreationMethodDefault;
	
	context->borderDrawingEnabled = NO;
	context->borderA = context->borderR = context->borderG = context->borderB = 0.0f;
	
	// no color matching
	context->ciWorkingColorSpace = (CGColorSpaceRef)[[NSNull null] retain];
	context->ciOutputColorSpace = (CGColorSpaceRef)[[NSNull null] retain];
	
	switch (context->internalOutputPixelFormat) {
		case CIImageInternalOutputPixelFormatGray8: {
			unsigned sRowBytes = _CIImagePrivateOptimalRowBytesForWidthAndBytesPerPixel(context->width, 4);
			
			context->scratchRowBytes[0] = sRowBytes;
			context->scratchSpace[0] = _CIImageBitmapsMalloc(context->width,
															 context->height,
															 &context->scratchRowBytes[0],
															 CIImageInternalOutputPixelFormatARGB8);
			
			context->scratchRowBytes[1] = sRowBytes;
			context->scratchSpace[1] = _CIImageBitmapsMalloc(context->width,
															 context->height,
															 &context->scratchRowBytes[1],
															 CIImageInternalOutputPixelFormatARGB8);
			
			break;
		}
		
		case CIImageInternalOutputPixelFormatRGB8:
		case CIImageInternalOutputPixelFormatRGBA8: {
			unsigned sRowBytes = _CIImagePrivateOptimalRowBytesForWidthAndBytesPerPixel(context->width, 4);
		
			context->scratchRowBytes[0] = sRowBytes;
			context->scratchSpace[0] = _CIImageBitmapsMalloc(context->width,
															 context->height,
															 &context->scratchRowBytes[0],
															 CIImageInternalOutputPixelFormatARGB8);
			
			context->scratchRowBytes[1] = sRowBytes;
			context->scratchSpace[1] = _CIImageBitmapsMalloc(context->width,
															 context->height,
															 &context->scratchRowBytes[1],
															 CIImageInternalOutputPixelFormatARGB8);
		
			break;
		}
		
		default:
			break;
	}
	
	// create the CGBitmapContext
	context->cgContext = CGBitmapContextCreate(context->outputBuffer,
											   context->width,
											   context->height,
											   ((context->bitmapInfo & kCGBitmapFloatComponents) ? 32 : 8),
											   context->rowBytes,
											   context->colorSpace,
											   context->bitmapInfo);
	
	if (NULL == context->cgContext)
		goto errorReturn;
	
	CGContextSetInterpolationQuality(context->cgContext, kCGInterpolationNone);
	
	// create the CIContext backed by this CGBitmapContext
	NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
							 (id)context->ciOutputColorSpace, kCIContextOutputColorSpace, 
							 (id)context->ciWorkingColorSpace, kCIContextWorkingColorSpace,
							 [NSNumber numberWithBool:context->renderOnCPU], kCIContextUseSoftwareRenderer,
							 nil];
	
	context->ciContextcgContext = [[CIContext contextWithCGContext:context->cgContext
												  options:options] retain];
	
	if (nil == context->ciContextcgContext)
		goto errorReturn;
	
	// create the CIContext backed by a CGLContext
	CGLPixelFormatObj cglPixelFormatObj = nil;
	
	static const CGLPixelFormatAttribute attr[] = {
		kCGLPFAAccelerated,
		kCGLPFANoRecovery,
		kCGLPFAAllowOfflineRenderers,
		NSOpenGLPFAColorSize, 24,
		NSOpenGLPFAAlphaSize, 8,
		(CGLPixelFormatAttribute)NULL
	};
	
	GLint numFormats = 0;
	CGLChoosePixelFormat(attr, &cglPixelFormatObj, &numFormats);
	
	if (numFormats <= 0) {
		// we didn't find a suitable format, so we reuse the cgContext-backed CIContext instead
		context->ciContextglContext = [context->ciContextcgContext retain];
	} else {
		// CIContext's render:toBitmap: doesn't really touch the CGL context, so we don't
		// need to worry much about the setup for now...
		CGLCreateContext(cglPixelFormatObj, NULL, &context->cglContext);
				
		CGLSetCurrentContext(context->cglContext);

		context->ciContextglContext = [[CIContext contextWithCGLContext:context->cglContext
															pixelFormat:cglPixelFormatObj
																options:options] retain];
	
		CGLSetCurrentContext(NULL);				
	}
	
	if (NULL != cglPixelFormatObj)
		CGLDestroyPixelFormat(cglPixelFormatObj);
	
	if (nil == context->ciContextglContext)
		goto errorReturn;
	
	// set up the glReadPixels rendering method
	_CIImagePrivateCreateCGLContextForGlReadPixels(context, image, renderOnCPU);
	
	return (void*)context;
	
errorReturn:
	CIImageBitmapsReleaseContext((void*)context);
	
	return NULL;
}

void _CIImagePrivateCreateCGLContextForGlReadPixels(CIImageBitmapsInternalData* context,
													CIImage* image,
													BOOL renderOnCPU)
{
	// create the CIContext backed by a CGLContext
	CGLPixelFormatObj cglPixelFormatObj = nil;
	
	static const CGLPixelFormatAttribute attr[] = {
		kCGLPFAPBuffer,
		kCGLPFAAccelerated,
		kCGLPFADoubleBuffer,
		kCGLPFANoRecovery,
		kCGLPFAAllowOfflineRenderers,
		kCGLPFAColorSize, 32,
		(CGLPixelFormatAttribute)NULL
	};
	
	GLint numFormats = 0;
	CGLChoosePixelFormat(attr, &cglPixelFormatObj, &numFormats);
	
	if (numFormats <= 0)
		goto errorReturn;
	else {
		unsigned glBytesPerPixel = 4;
		switch (context->internalOutputPixelFormat) {
			case CIImageInternalOutputPixelFormatGray8:
			case CIImageInternalOutputPixelFormatARGB8:
			case CIImageInternalOutputPixelFormatRGB8:
			case CIImageInternalOutputPixelFormatRGBA8:
			default:
				glBytesPerPixel = 4;
				context->glrpPixelFormatType = GL_BGRA;
				context->glrpFormatType = GL_UNSIGNED_INT_8_8_8_8_REV;
				break;
		}
	
		CGLCreatePBuffer(context->width, context->height, GL_TEXTURE_RECTANGLE_EXT, GL_RGBA, 0, &context->glrpPBObj);
		
		if (NULL == context->glrpPBObj)
			goto errorReturn;
		
		CGLCreateContext(cglPixelFormatObj, NULL, &context->glrpCglContext);
		
		if (NULL == context->glrpCglContext)
			goto errorReturn;
				
		GLint virtScreen;
		CGLGetVirtualScreen(context->glrpCglContext, &virtScreen);
		CGLSetPBuffer(context->glrpCglContext, context->glrpPBObj, 0, 0, virtScreen);
		
		CGLSetCurrentContext(context->glrpCglContext);
		
		glDisable(GL_ALPHA_TEST);
		glDisable(GL_DEPTH_TEST);
		glDisable(GL_SCISSOR_TEST);
		glDisable(GL_BLEND);
		glDisable(GL_DITHER);
		glDisable(GL_CULL_FACE);
		glDisable(GL_LIGHTING);
		glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
		glDepthMask(GL_FALSE);
		glStencilMask (0);
		glHint(GL_TRANSFORM_HINT_APPLE, GL_FASTEST);
		glClearColor(0, 0, 0, 1);
		
		GLint textureSize;
		glGetIntegerv(GL_MAX_TEXTURE_SIZE, &textureSize);
		
		context->glrpRenderImgRect = [image extent];
		if (context->glrpRenderImgRect.size.width > textureSize || context->glrpRenderImgRect.size.height > textureSize) {			
			if (context->aspectRatio > 1.0) {
				context->glrpRenderImgRect.size.width = textureSize;
				context->glrpRenderImgRect.size.height = textureSize / context->aspectRatio;
			} else {
				context->glrpRenderImgRect.size.width = textureSize / context->aspectRatio;
				context->glrpRenderImgRect.size.height = textureSize;
			}
		}
		
		// if it is supported, we'll use a PBO for the readback
		{
			const GLubyte* glExtensions = glGetString(GL_EXTENSIONS);
			context->glrpHasPbo = gluCheckExtension((const GLubyte*)"GL_ARB_pixel_buffer_object", glExtensions);
		}
		
		if (context->glrpHasPbo) {
			glGenBuffersARB(1, &context->glrpPboId);
			glBindBufferARB(GL_PIXEL_PACK_BUFFER_ARB, context->glrpPboId);
			glBufferDataARB(GL_PIXEL_PACK_BUFFER_ARB, context->width * context->height * glBytesPerPixel, NULL, GL_DYNAMIC_READ);
			glBindBufferARB(GL_PIXEL_PACK_BUFFER_ARB, 0);
		}
				
		glViewport(0, 0, context->width, context->height);
		
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		glOrtho(0, context->width, context->height, 0, -1, 1);
		
		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
		
		glClear(GL_COLOR_BUFFER_BIT);
		
		// respect our rowBytes setting during glReadPixels
		glPixelStorei(GL_PACK_ROW_LENGTH, context->rowBytes);
				
		NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
								 (id)context->ciOutputColorSpace, kCIContextOutputColorSpace, 
								 (id)context->ciWorkingColorSpace, kCIContextWorkingColorSpace,
								 [NSNumber numberWithBool:renderOnCPU], kCIContextUseSoftwareRenderer,
								 nil];
		
		context->glrpCiContext = [[CIContext contextWithCGLContext:context->glrpCglContext
													  pixelFormat:cglPixelFormatObj
														  options:options] retain];
		
		CGLSetCurrentContext(NULL);				
	}
	
	if (NULL != cglPixelFormatObj)
		CGLDestroyPixelFormat(cglPixelFormatObj);
	
	return;
	
errorReturn:

	[context->glrpCiContext release];
	context->glrpCiContext = nil;
	
	if (NULL != context->glrpCglContext) {
		if (context->glrpHasPbo && 0 != context->glrpPboId) {
			CGLSetCurrentContext(context->glrpCglContext);
			glDeleteBuffersARB(1, &context->glrpPboId);
			context->glrpPboId = 0;
			CGLSetCurrentContext(NULL);
		}
	
		CGLClearDrawable(context->glrpCglContext);
		
		CGLDestroyContext(context->glrpCglContext);
		context->glrpCglContext = NULL;
	}
	
	if (NULL != context->glrpPBObj) {
		if (NULL != context->glrpCglContext)
		CGLDestroyPBuffer(context->glrpPBObj);
		context->glrpPBObj = NULL;
	}
	
	if (NULL != cglPixelFormatObj)
		CGLDestroyPixelFormat(cglPixelFormatObj);
}

size_t _CIImagePrivateOptimalRowBytesForWidthAndBytesPerPixel(size_t width, size_t bytesPerPixel)
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

int _CIImagePrivateConvertCIFormatPixelFormats(void* dest,
											   int destRowBytes,
											   CIImageBitmapsInternalData* internalData,
											   int width,
											   int height,
											   CIImageInternalOutputPixelFormat destFormat,
											   CIFormat srcFormat)
{
	int success = 0;
	
	if (NULL != dest && NULL != internalData) {
		if (CIImageInternalOutputPixelFormatGray8 == destFormat &&
			kCIFormatARGB8 == srcFormat) {
			
			success = CIImageBitmapsConvertARGB8toMono8(internalData->scratchSpace[0],
														internalData->scratchRowBytes[0],
														dest,
														destRowBytes,
														internalData->scratchSpace[1],
														internalData->scratchRowBytes[1],
														width,
														height);

		} else if (CIImageInternalOutputPixelFormatRGBA8 == destFormat &&
				   kCIFormatARGB8 == srcFormat) {
				   
			success = CIImageBitmapsConvertARGB8ToRGBA8(internalData->scratchSpace[0],
														internalData->scratchRowBytes[0],
														dest,
														destRowBytes,
														width,
														height);

		} else if (CIImageInternalOutputPixelFormatRGB8 == destFormat &&
				   kCIFormatARGB8 == srcFormat) {

			success = CIImageBitmapsConvertARGB8toRGB8(internalData->scratchSpace[0],
													   internalData->scratchRowBytes[0],
													   dest,
													   destRowBytes,
													   internalData->scratchSpace[1],
													   internalData->scratchRowBytes[1],
													   width,
													   height);

		}
	}
	
	return success;
}

int _CIImagePrivateConvertOpenGLPixelFormats(void* dest,
											 int destRowBytes,
											 CIImageBitmapsInternalData* internalData,
											 int width,
											 int height,
											 CIImageInternalOutputPixelFormat destFormat,
											 GLenum openglPixelFormatType,
											 GLenum openglType)
{
	int success = 0;
	
	if (NULL != dest && NULL != internalData) {
		if (CIImageInternalOutputPixelFormatGray8 == destFormat &&
			GL_UNSIGNED_INT_8_8_8_8_REV == openglType) {
			
			if (GL_BGRA == openglPixelFormatType)
				success = CIImageBitmapsConvertBGRA8toMono8(internalData->scratchSpace[0],
															internalData->scratchRowBytes[0],
															dest,
															destRowBytes,
															internalData->scratchSpace[1],
															internalData->scratchRowBytes[1],
															width,
															height);
			
		} else if (CIImageInternalOutputPixelFormatRGBA8 == destFormat &&
				   GL_UNSIGNED_INT_8_8_8_8_REV == openglType) {
		 
			 if (GL_BGRA == openglPixelFormatType)
				 success = CIImageBitmapsConvertBGRA8ToRGBA8(internalData->scratchSpace[0],
															 internalData->scratchRowBytes[0],
															 dest,
															 destRowBytes,
															 width,
															 height);
		 
		} else if (CIImageInternalOutputPixelFormatRGB8 == destFormat &&
				   GL_UNSIGNED_INT_8_8_8_8_REV == openglType) {
		 
			if (GL_BGRA == openglPixelFormatType)
				success = CIImageBitmapsConvertBGRA8toRGB8(internalData->scratchSpace[0],
														   internalData->scratchRowBytes[0],
														   dest,
														   destRowBytes,
														   internalData->scratchSpace[1],
														   internalData->scratchRowBytes[1],
														   width,
														   height);
		 
		 }
	}
	
	return success;
}

uint64_t _CIImagePrivateGetCurrentNanoseconds()
{
	static mach_timebase_info_data_t timeBase;

	if (0 == timeBase.denom)
		(void)mach_timebase_info(&timeBase);
	
	uint64_t now = mach_absolute_time();
	
	return now * (timeBase.numer / timeBase.denom);
}

void* _CIImageBitmapsMalloc(int width, int height, int* rowBytes, CIImageInternalOutputPixelFormat pixelFormat)
{
#if defined(_USES_IPP_)
	void* m = NULL;
	
	switch(pixelFormat) {
		case CIImageInternalOutputPixelFormatRGBAF:
			m  = ippiMalloc_32f_AC4(width, height, rowBytes);
			break;
		case CIImageInternalOutputPixelFormatRGB8:
			m = ippiMalloc_8u_C3(width, height, rowBytes);
			break;
		case CIImageInternalOutputPixelFormatGray8:
			m = ippiMalloc_8u_C1(width, height, rowBytes);
			break;
		case CIImageInternalOutputPixelFormatARGB8:
		case CIImageInternalOutputPixelFormatRGBA8:
		default:
			m = ippiMalloc_8u_AC4(width, height, rowBytes);
			break;
	}
	
	return m;
#else
	return (void*)valloc(height * (*rowBytes));
#endif
}

void _CIImageBitmapsFree(void* ptr)
{
#if defined(_USES_IPP_)
	ippiFree(ptr);
#else
	free(ptr);
#endif
}
