//
//  TFInverseTextureMappingConverter.m
//  Touché
//
//  Created by Georg Kaindl on 28/12/07.
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

#import "TFInverseTextureMappingConverter.h"

#import "TFIncludes.h"
#import "TFBlobPoint.h"
#import "TFCalibrationPoint.h"

#define	DEFAULT_CALIBRATION_POINTS_PER_AXIS		(4)
#define vertex(A,x,y)							(&(A)[((_maxPatchY+1)*(y)+(x)) << 1])

@interface TFInverseTextureMappingConverter (NonPublicMethods)
- (void)_computePatchSizesFromCalibrationPointsPerAxis:(NSUInteger)pointsPerAxis;
- (void)_resetForNewPointsPerAxis;
- (void)_initializeTriangleCentroids;
- (NSInteger)_findTriangleForPoint:(float*)P inMesh:(float*)mesh barycentricUinto:(float*)U Vinto:(float*)V;
- (void)_pointsForTriangle:(NSUInteger)triangleNum fromMesh:(float*)mesh intoA:(float**)A B:(float**)B C:(float**)C;
- (void)_recordError:(NSError*)error intoArrayAt:(NSMutableArray**)array;
@end

@implementation TFInverseTextureMappingConverter

@synthesize calibrationPointsPerAxis;

- (void)setCalibrationPointsPerAxis:(NSUInteger)newPoints
{
	if (newPoints == calibrationPointsPerAxis)
		return;
	
	if (newPoints < 2)
		newPoints = 2;

	calibrationPointsPerAxis = newPoints;
	[self _resetForNewPointsPerAxis];
}

- (void)dealloc
{
	if (NULL != _cameraVertices) {
		free(_cameraVertices);
		_cameraVertices = NULL;
	}
	
	if (NULL != _screenVertices) {
		free(_screenVertices);
		_screenVertices = NULL;
	}
	
	if (NULL != _cameraTriangleCentroids) {
		free(_cameraTriangleCentroids);
		_cameraTriangleCentroids = NULL;
	}
	
	if (NULL != _centroidScratchSpace) {
		free(_centroidScratchSpace);
		_centroidScratchSpace = NULL;
	}
	
	if (NULL != _centroidIndices) {
		free(_centroidIndices);
		_centroidIndices = NULL;
	}
	
	[super dealloc];
}

- (id)initWithScreenSize:(CGSize)screenSize andCameraSize:(CGSize)cameraSize
{
	if (!(self = [super initWithScreenSize:screenSize andCameraSize:cameraSize])) {
		[self release];
		return nil;
	}
	
	self.calibrationPointsPerAxis = DEFAULT_CALIBRATION_POINTS_PER_AXIS;
	_isCalibrated = NO;
	
	return self;
}

- (void)_computePatchSizesFromCalibrationPointsPerAxis:(NSUInteger)pointsPerAxis
{
	float patchRatio = 1.0f/(float)(pointsPerAxis-1);
	
	_cameraPatchSizeX = ceil(patchRatio*self.cameraWidth);
	_cameraPatchSizeY = ceil(patchRatio*self.cameraHeight);
	_screenPatchSizeX = ceil(patchRatio*self.screenWidth);
	_screenPatchSizeY = ceil(patchRatio*self.screenHeight);
}

- (void)_resetForNewPointsPerAxis
{
	_isCalibrated = NO;
	
	[self _computePatchSizesFromCalibrationPointsPerAxis:calibrationPointsPerAxis];
	
	// the amount of patches in horizontal and vertical directions
	// NOTE: if you have x patches, you have (x+1) vertices per line in this direction
	_maxPatchX = ceil(self.cameraWidth/_cameraPatchSizeX);
	_maxPatchY = ceil(self.cameraHeight/_cameraPatchSizeY);
		
	_screenPatchSizeX += (self.screenWidth-(_maxPatchX)*_screenPatchSizeX)/(_maxPatchX);
	_screenPatchSizeY += (self.screenHeight-(_maxPatchY)*_screenPatchSizeY)/(_maxPatchY);
	
	if (NULL != _cameraVertices)
		free(_cameraVertices);
	if (NULL != _screenVertices)
		free(_screenVertices);
	
	_cameraVertices = malloc(sizeof(float)*2*(_maxPatchX+1)*(_maxPatchY+1));
	_screenVertices = malloc(sizeof(float)*2*(_maxPatchX+1)*(_maxPatchY+1));
	
	// the default calibration implies a perfect setup, i.e. camera is perfectly placed (image represents screen
	// 1 to 1, no tilting, same aspect ratio as screen, etc...).
	NSUInteger x, y;
	for (y=0; y<=_maxPatchY; y++)
		for (x=0; x<=_maxPatchX; x++) {
			float* camVertex = vertex(_cameraVertices, x, y);
			float* scrVertex = vertex(_screenVertices, x, y);
			
			camVertex[0] = MIN(x*_cameraPatchSizeX/cameraWidth, 1.0f);
			camVertex[1] = MIN(y*_cameraPatchSizeY/cameraHeight, 1.0f);
			
			scrVertex[0] = MIN(x*_screenPatchSizeX/screenWidth, 1.0f);
			scrVertex[1] = MIN(y*_screenPatchSizeY/screenHeight, 1.0f);
		}
	
	if ([delegate respondsToSelector:@selector(calibrationDidBecomeNecessary)])
		[delegate calibrationDidBecomeNecessary];
}

- (BOOL)isCalibrated
{
	return _isCalibrated;
}

- (NSArray*)screenPointsForCalibration
{
	if (calibrationPointsPerAxis-1 != _maxPatchX)
		[self _resetForNewPointsPerAxis];

	NSMutableArray* arr = [NSMutableArray array];
		
	NSUInteger i;
	for (i=0; i<(_maxPatchX+1)*(_maxPatchY+1)*2; i+=2)
		[arr addObject:[TFCalibrationPoint pointWithScreenX:_screenVertices[i]*screenWidth
													screenY:_screenVertices[i+1]*screenHeight]];
				
	return [NSArray arrayWithArray:arr];
}

- (BOOL)calibrateWithPoints:(NSArray*)points errors:(NSArray**)errors
{
	NSMutableArray* errCollection = nil;

	if (NULL != errors)
		*errors = nil;

	if (nil == points) {
		NSError* err =
			[NSError errorWithDomain:TFErrorDomain
								code:TFErrorCam2ScreenNilCalibrationPoints
							userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
									  TFLocalizedString(@"TFCam2ScreenNilCalibrationPointsErrorDesc", @"TFCam2ScreenNilCalibrationPointsErrorDesc"),
										NSLocalizedDescriptionKey,
									  TFLocalizedString(@"TFCam2ScreenNilCalibrationPointsErrorReason", @"TFCam2ScreenNilCalibrationPointsErrorReason"),
										NSLocalizedFailureReasonErrorKey,
									  TFLocalizedString(@"TFCam2ScreenNilCalibrationPointsErrorRecovery", @"TFCam2ScreenNilCalibrationPointsErrorRecovery"),
										NSLocalizedRecoverySuggestionErrorKey,
									  [NSNumber numberWithInteger:NSUTF8StringEncoding],
										NSStringEncodingErrorKey,
									  nil]];
		
		[self _recordError:err intoArrayAt:&errCollection];
		
		if (nil != errCollection && NULL != errors)
			*errors = [NSArray arrayWithArray:errCollection];
		
		_isCalibrated = NO;
		
		return NO;
	}
		
	if ([points count] != (_maxPatchX+1)*(_maxPatchY+1)) {
		NSError* err =
			[NSError errorWithDomain:TFErrorDomain
								code:TFErrorCam2ScreenCalibrationPointsAmountMismatch
							userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
									  TFLocalizedString(@"TFCam2ScreenCalibrationPointsAmountErrorDesc", @"TFCam2ScreenCalibrationPointsAmountErrorDesc"),
										NSLocalizedDescriptionKey,
									  TFLocalizedString(@"TFCam2ScreenCalibrationPointsAmountErrorReason", @"TFCam2ScreenCalibrationPointsAmountErrorReason"),
										NSLocalizedFailureReasonErrorKey,
									  TFLocalizedString(@"TFCam2ScreenCalibrationPointsAmountErrorRecovery", @"TFCam2ScreenCalibrationPointsAmountErrorRecovery"),
										NSLocalizedRecoverySuggestionErrorKey,
									  [NSNumber numberWithInteger:NSUTF8StringEncoding],
										NSStringEncodingErrorKey,
									  nil]];

		[self _recordError:err intoArrayAt:&errCollection];

		if (nil != errCollection && NULL != errors)
			*errors = [NSArray arrayWithArray:errCollection];
		
		_isCalibrated = NO;
		
		return NO;
	}
	
	BOOL pointSet[(_maxPatchX+1)*(_maxPatchY+1)];
	memset(pointSet, NO, sizeof(BOOL)*(_maxPatchX+1)*(_maxPatchY+1));
	
	for (TFCalibrationPoint* point in points) {
		if (![point isCalibrated]) {
			NSError* err =
				[NSError errorWithDomain:TFErrorDomain
									code:TFErrorCam2ScreenCalibrationPointNotCalibrated
								userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
										  TFLocalizedString(@"TFCam2ScreenCalibrationPointNotCalibratedErrorDesc", @"TFCam2ScreenCalibrationPointNotCalibratedErrorDesc"),
											NSLocalizedDescriptionKey,
										  [NSString stringWithFormat:TFLocalizedString(@"TFCam2ScreenCalibrationPointNotCalibratedErrorReason", @"TFCam2ScreenCalibrationPointNotCalibratedErrorReason"),
											point.screenX, point.screenY],
											NSLocalizedFailureReasonErrorKey,
										  TFLocalizedString(@"TFCam2ScreenCalibrationPointNotCalibratedErrorRecovery", @"TFCam2ScreenCalibrationPointNotCalibratedErrorRecovery"),
											NSLocalizedRecoverySuggestionErrorKey,
										  [NSNumber numberWithInteger:NSUTF8StringEncoding],
											NSStringEncodingErrorKey,
										  nil]];
			
			[self _recordError:err intoArrayAt:&errCollection];
			continue;
		}
	
		// calculate mesh position for the given point
		NSUInteger xpos = round(point.screenX/(float)_screenPatchSizeX);
		NSUInteger ypos = round(point.screenY/(float)_screenPatchSizeY);
				
		if (xpos > _maxPatchX || ypos > _maxPatchY) {
			NSError* err =
				[NSError errorWithDomain:TFErrorDomain
									code:TFErrorCam2ScreenCalibrationPointNotCalibrated
								userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
										  TFLocalizedString(@"TFCam2ScreenCalibrationPointInvalidScreenCoordsErrorDesc", @"TFCam2ScreenCalibrationPointInvalidScreenCoordsErrorDesc"),
											NSLocalizedDescriptionKey,
										  [NSString stringWithFormat:TFLocalizedString(@"TFCam2ScreenCalibrationPointInvalidScreenCoordsErrorReason", @"TFCam2ScreenCalibrationPointInvalidScreenCoordsErrorReason"),
										   point.screenX, point.screenY],
											NSLocalizedFailureReasonErrorKey,
										  TFLocalizedString(@"TFCam2ScreenCalibrationPointInvalidScreenCoordsErrorRecovery", @"TFCam2ScreenCalibrationPointInvalidScreenCoordsErrorRecovery"),
											NSLocalizedRecoverySuggestionErrorKey,
										  [NSNumber numberWithInteger:NSUTF8StringEncoding],
											NSStringEncodingErrorKey,
										  nil]];
			
			[self _recordError:err intoArrayAt:&errCollection];
			continue;
		}
		
		if (pointSet[(_maxPatchY+1)*ypos + xpos]) {
			NSError* err =
				[NSError errorWithDomain:TFErrorDomain
									code:TFErrorCam2ScreenCalibrationPointContainedTwice
								userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
										  TFLocalizedString(@"TFCam2ScreenCalibrationPointContainedTwiceErrorDesc", @"TFCam2ScreenCalibrationPointContainedTwiceErrorDesc"),
											NSLocalizedDescriptionKey,
										  [NSString stringWithFormat:TFLocalizedString(@"TFCam2ScreenCalibrationPointContainedTwiceErrorReason", @"TFCam2ScreenCalibrationPointContainedTwiceErrorReason"),
										   point.screenX, point.screenY],
											NSLocalizedFailureReasonErrorKey,
										  TFLocalizedString(@"TFCam2ScreenCalibrationPointContainedTwiceErrorRecovery", @"TFCam2ScreenCalibrationPointContainedTwiceErrorRecovery"),
											NSLocalizedRecoverySuggestionErrorKey,
										  [NSNumber numberWithInteger:NSUTF8StringEncoding],
											NSStringEncodingErrorKey,
										  nil]];
			
			[self _recordError:err intoArrayAt:&errCollection];
			continue;
		}
		
		float* cv = vertex(_cameraVertices, xpos, ypos);
		cv[0] = point.cameraX/cameraWidth;
		cv[1] = point.cameraY/cameraHeight;
		
		cv = vertex(_screenVertices, xpos, ypos);
		cv[0] = point.screenX/screenWidth;
		cv[1] = point.screenY/screenHeight;
		
		pointSet[(_maxPatchY+1)*ypos + xpos] = YES;
		
		/* NSLog(@"pos: (%d, %d) - screen: (%.4f, %.4f) - camera: (%.4f, %.4f)\n",
			xpos, ypos, point.screenX, point.screenY, point.cameraX, point.cameraY); */
	}
	
	NSUInteger x, y;
	for (y=0; y<=_maxPatchY; y++)
		for (x=0; x<=_maxPatchX; x++)
			if (!pointSet[(_maxPatchY+1)*y + x]) {
				NSError* err =
					[NSError errorWithDomain:TFErrorDomain
										code:TFErrorCam2ScreenCalibrationPointMissing
									userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											  TFLocalizedString(@"TFCam2ScreenCalibrationPointMissingErrorDesc", @"TFCam2ScreenCalibrationPointMissingErrorDesc"),
												NSLocalizedDescriptionKey,
											  [NSString stringWithFormat:TFLocalizedString(@"TFCam2ScreenCalibrationPointMissingErrorReason", @"TFCam2ScreenCalibrationPointMissingErrorReason"),
											   x*_screenPatchSizeX, y*_screenPatchSizeY],
												NSLocalizedFailureReasonErrorKey,
											  TFLocalizedString(@"TFCam2ScreenCalibrationPointMissingErrorRecovery", @"TFCam2ScreenCalibrationPointMissingErrorRecovery"),
												NSLocalizedRecoverySuggestionErrorKey,
											  [NSNumber numberWithInteger:NSUTF8StringEncoding],
												NSStringEncodingErrorKey,
											  nil]];
				
				[self _recordError:err intoArrayAt:&errCollection];
			}
	
	if (NULL != errors) {
		if (nil != errCollection)
			*errors = [NSArray arrayWithArray:errCollection];
		else
			*errors = nil;
	}
	
	[self _initializeTriangleCentroids];

	_isCalibrated = (nil == errCollection);
	
	if (nil != errCollection && NULL != errors)
		*errors = [NSArray arrayWithArray:errCollection];

	return _isCalibrated;
}

- (NSData*)specificSerializedCalibrationData
{
	if (NULL == _screenVertices || NULL == _cameraVertices)
		return nil;
	
	NSUInteger verticesSize = (NSUInteger)(sizeof(float)*2*(_maxPatchX+1)*(_maxPatchY+1));
	NSData* screenData = [NSData dataWithBytes:_screenVertices
										length:verticesSize];
	NSData* cameraData = [NSData dataWithBytes:_cameraVertices
										length:verticesSize];
	
	return [NSArchiver archivedDataWithRootObject:[NSArray arrayWithObjects:screenData, cameraData,
								[NSNumber numberWithUnsignedInteger:_maxPatchX],
								[NSNumber numberWithUnsignedInteger:_maxPatchY],
								[NSNumber numberWithUnsignedInteger:calibrationPointsPerAxis],
								nil]];
}

- (BOOL)shouldLoadScreenAndCameraDimensionsFromSerializedData
{
	// we don't want to load the screen dimensions from saved data, since we're operating in normalized
	// [0, 1] coordinates internally, so we can work with whatever screen dimensions are currently set
	return NO;
}

- (BOOL)loadSpecificSerializedCalibrationData:(NSData*)calibrationData error:(NSError**)error
{
	NSError* invalidCalibrationError =
			[NSError errorWithDomain:TFErrorDomain
								code:TFErrorCam2ScreenInvalidCalibrationData
							userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
									  TFLocalizedString(@"TFCam2ScreenInvalidCalibrationDataErrorDesc", @"TFCam2ScreenInvalidCalibrationDataErrorDesc"),
									  NSLocalizedDescriptionKey,
									  TFLocalizedString(@"TFCam2ScreenInvalidCalibrationDataErrorReason", @"TFCam2ScreenInvalidCalibrationDataErrorReason"),
									  NSLocalizedFailureReasonErrorKey,
									  TFLocalizedString(@"TFCam2ScreenInvalidCalibrationDataErrorRecovery", @"TFCam2ScreenInvalidCalibrationDataErrorRecovery"),
									  NSLocalizedRecoverySuggestionErrorKey,
									  [NSNumber numberWithInteger:NSUTF8StringEncoding],
									  NSStringEncodingErrorKey,
									  nil]];

	id unarchivedData = [NSUnarchiver unarchiveObjectWithData:calibrationData];
	
	if (![unarchivedData isKindOfClass:[NSArray class]]) {
		if (NULL != error)
			*error = invalidCalibrationError;

		return NO;
	}
	
	NSArray* arrayData = (NSArray*)unarchivedData;
	
	if ([arrayData count] != 5) {
		if (NULL != error)
			*error = invalidCalibrationError;

		return NO;
	}
	
	// TODO: maybe more error checking (i.e. wether the types are correct or not). Also check wether the size
	//       of the arrays matches the values of maxPatchX and maxPatchY...
	
	if (NULL != _screenVertices)
		free(_screenVertices);
	if (NULL != _cameraVertices)
		free(_cameraVertices);
	
	NSData* screenData = (NSData*)[arrayData objectAtIndex:0];
	_screenVertices = (float*)malloc([screenData length]);
	memcpy(_screenVertices, [screenData bytes], [screenData length]);
	
	NSData* cameraData = (NSData*)[arrayData objectAtIndex:1];
	_cameraVertices = (float*)malloc([cameraData length]);
	memcpy(_cameraVertices, [cameraData bytes], [cameraData length]);
	
	_maxPatchX = [[arrayData objectAtIndex:2] unsignedIntegerValue];
	_maxPatchY = [[arrayData objectAtIndex:3] unsignedIntegerValue];
	NSUInteger numCalibrationPoints = [[arrayData objectAtIndex:4] floatValue];
	
	[self _computePatchSizesFromCalibrationPointsPerAxis:numCalibrationPoints];
	[self _initializeTriangleCentroids];

	return YES;
}

- (void)_initializeTriangleCentroids
{
	if (NULL != _cameraTriangleCentroids) {
		free(_cameraTriangleCentroids);
		_cameraTriangleCentroids = NULL;
	}
	
	if (NULL != _centroidScratchSpace) {
		free(_centroidScratchSpace);
		_centroidScratchSpace = NULL;
	}
	
	if (NULL != _centroidIndices) {
		free(_centroidIndices);
		_centroidIndices = NULL;
	}
	
	_numTriangles = _maxPatchX*_maxPatchY*2;
	_cameraTriangleCentroids = (float*)malloc(sizeof(float)*_numTriangles*2);
	_centroidScratchSpace = (float*)malloc(sizeof(float)*_numTriangles*4);
	_centroidIndices = (vDSP_Length*)malloc(sizeof(vDSP_Length)*_numTriangles);
	
	float *p1, *p2, *p3;
	int i;
	for (i=0; i<_numTriangles; i++) {
		[self _pointsForTriangle:i fromMesh:_cameraVertices intoA:&p1 B:&p2 C:&p3];
		
		_cameraTriangleCentroids[i<<1] = (p1[0] + p2[0] + p3[0]) / 3.0f;
		_cameraTriangleCentroids[(i<<1)+1] = (p1[1] + p2[1] + p3[1]) / 3.0f;
		
		_centroidIndices[i] = i;
	}
}

// Our triangles are made from the mesh points by joining them by putting the diagonal from the
// top left to the bottom right into each adjacent 4 mesh points. The triangle to the lower left
// gets the even index, the one in the upper right gets the odd index.
- (void)_pointsForTriangle:(NSUInteger)triangleNum fromMesh:(float*)mesh intoA:(float**)A B:(float**)B C:(float**)C
{
	float* p1, *p2, *p3;
	p1 = p2 = p3 = NULL;

	if (triangleNum >= _numTriangles)
		goto returnVal;
	
	BOOL even = (triangleNum%2 == 0);
	if (!even)
		triangleNum -= 1;
	
	NSUInteger x = (triangleNum >> 1) % _maxPatchX;
	NSUInteger y = (triangleNum >> 1) / _maxPatchY;

	p1 = vertex(mesh, x, y);
	p2 = vertex(mesh, even ? x : (x+1), even ? (y+1) : y);
	p3 = vertex(mesh, x+1, y+1);
	
returnVal:
	if (NULL != A)
		*A = p1;
	if (NULL != B)
		*B = p2;
	if (NULL != C)
		*C = p3;
}

- (NSInteger)_findTriangleForPoint:(float*)P inMesh:(float*)mesh barycentricUinto:(float*)U Vinto:(float*)V
{
	NSUInteger twoNumTriangles = _numTriangles << 1;
	float* s = _centroidScratchSpace;
	if (NULL == s || NULL == _centroidIndices || NULL == _cameraTriangleCentroids)
		return -1;
	
	vDSP_vfill(&P[0], s, 2, _numTriangles);
	vDSP_vfill(&P[1], &(s[1]), 2, _numTriangles);				
	vDSP_vpythg(s, 2,
				&(s[1]), 2,
				_cameraTriangleCentroids, 2,
				&(_cameraTriangleCentroids[1]), 2,
				&(s[twoNumTriangles]), 1,
				_numTriangles);	
	vDSP_vsorti(&(s[twoNumTriangles]), _centroidIndices, NULL, _numTriangles, 1);

	NSInteger tNum, bestNum = -1;
	float *p1, *p2, *p3, tA, u, v, u_best, v_best;
	int i;
	for (i=0; i<_numTriangles; i++) {
		tNum = _centroidIndices[i];

		[self _pointsForTriangle:tNum fromMesh:mesh intoA:&p1 B:&p2 C:&p3];
		if (NULL == p1 || NULL == p2 || NULL == p3)
			continue;

		tA = (p1[0] - p2[0]) * (p1[1] - p3[1]) - (p1[1] - p2[1]) * (p1[0] - p3[0]);
		if (0 == tA)
			continue;

		u = ((P[0] - p2[0]) * (P[1] - p3[1]) - (P[1] - p2[1]) * (P[0] - p3[0])) / tA;
		v = ((p1[0] - P[0]) * (p1[1] - p3[1]) - (p1[1] - P[1]) * (p1[0] - p3[0])) / tA;

		// check barycentric coordinates to see wether the point lies within this
		// triangle... if yes, we return the triangle's index and the u,v coordinates
		if (u >= 0 && v >= 0 && (u + v) <= 1) {
			if (NULL != U)
				*U = u;
			if (NULL != V)
				*V = v;
									
			return tNum;
		}

		if (bestNum < 0) {
			u_best = u;
			v_best = v;
			bestNum = i;
		}
	}

	// if we're here, this means that the screen point is not within any of the triangles in
	// our mesh. Therefore, we return the triangle (and the u,v coordinates) whose centroid
	// is closest to the point, even though it doesn't lie within it. This ensures that we can
	// provide some sort of transformation (though maybe not as accurate) in case a point falls
	// outside of the mesh.
	if (NULL != U)
		*U = u_best;
	if (NULL != V)
		*V = v_best;
	 
	return _centroidIndices[bestNum];
}

// loosely based on CTouchScreen::cameraToScreenSpace from the touchlib, which is in turn based on
// http://www.cescg.org/CESCG97/olearnik/txmap.htm
- (BOOL)transformPointFromCameraToScreen:(TFBlobPoint*)point error:(NSError**)error
{
	if (NULL != error)
		*error = nil;
	
	if (nil == point)
		return YES;

	NSInteger triangleNumber;
	float P[2], u, v, t;
	P[0] = point.x/cameraWidth;
	P[1] = point.y/cameraHeight;
	
	triangleNumber = [self _findTriangleForPoint:P inMesh:_cameraVertices barycentricUinto:&u Vinto:&v];
		
	if (triangleNumber < 0 || _numTriangles <= triangleNumber) {		
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorInverseTextureCam2ScreenInternalError
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFInverseTextureCam2ScreenInternalErrorDesc", @"TFInverseTextureCam2ScreenInternalErrorDesc"),
												NSLocalizedDescriptionKey,
											   [NSString stringWithFormat:TFLocalizedString(@"TFInverseTextureCam2ScreenInternalErrorReason", @"TFInverseTextureCam2ScreenInternalErrorReason"),
												point.x, point.y],
												NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFInverseTextureCam2ScreenInternalErrorRecovery", @"TFInverseTextureCam2ScreenInternalErrorRecovery"),
												NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
												NSStringEncodingErrorKey,
											   nil]];

		return NO;
	}
	
	t = 1.0f - u - v;
			
	float *sA, *sB, *sC;
	[self _pointsForTriangle:triangleNumber fromMesh:_screenVertices intoA:&sA B:&sB C:&sC];
	
	if (NULL == sA || NULL == sB || NULL == sC) {
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorInverseTextureCam2ScreenInternalError
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFInverseTextureCam2ScreenInternalErrorDesc", @"TFInverseTextureCam2ScreenInternalErrorDesc"),
											   NSLocalizedDescriptionKey,
											   [NSString stringWithFormat:TFLocalizedString(@"TFInverseTextureCam2ScreenInternalErrorReason", @"TFInverseTextureCam2ScreenInternalErrorReason"),
												point.x, point.y],
											   NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFInverseTextureCam2ScreenInternalErrorRecovery", @"TFInverseTextureCam2ScreenInternalErrorRecovery"),
											   NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
											   NSStringEncodingErrorKey,
											   nil]];
		
		return NO;
	}
	
	float transformedX = (sA[0]*u) + (sB[0]*v) + (sC[0]*t);
	float transformedY = (sA[1]*u) + (sB[1]*v) + (sC[1]*t);
	
	point.x = transformedX*screenWidth;
	point.y = transformedY*screenHeight;
	
	return YES;
}

@end
