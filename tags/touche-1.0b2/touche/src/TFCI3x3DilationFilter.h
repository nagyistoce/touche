//
//  TFCI3x3DilationFilter.h
//  Touche
//
//  Created by Georg Kaindl on 10/6/08.
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

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>


typedef enum {
	TFCI3x3DilationFilterShapeSquare = 0,
	TFCI3x3DilationFilterShapeCross
} TFCI3x3DilationFilterShapeType;

#define TFCI3x3DilationFilterShapeTypeMin	(TFCI3x3DilationFilterShapeSquare)
#define TFCI3x3DilationFilterShapeTypeMax	(TFCI3x3DilationFilterShapeCross)

@interface TFCI3x3DilationFilter : CIFilter {
	CIImage*		inputImage;
	NSNumber*		inputPasses;
	NSNumber*		inputShapeType;
}

@end
