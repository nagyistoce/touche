//
//  TFInverseTextureMappingConverter.h
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

#import <Cocoa/Cocoa.h>
#import <Accelerate/Accelerate.h>

#import "TFCamera2ScreenCoordinatesConverter.h"

@interface TFInverseTextureMappingConverter : TFCamera2ScreenCoordinatesConverter {
	NSUInteger		calibrationPointsPerAxis;
	float*			_cameraVertices;
	float*			_screenVertices;
	NSUInteger		_maxPatchX, _maxPatchY;
	float			_screenPatchSizeX, _screenPatchSizeY, _cameraPatchSizeX, _cameraPatchSizeY;
	float*			_cameraTriangleCentroids, *_centroidScratchSpace;
	vDSP_Length*	_centroidIndices;
	NSUInteger		_numTriangles;
	BOOL			_isCalibrated;
}

@property (nonatomic, assign) NSUInteger calibrationPointsPerAxis;

- (id)initWithScreenSize:(CGSize)screenSize andCameraSize:(CGSize)cameraSize;

@end
