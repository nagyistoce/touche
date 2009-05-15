//
//  TFCIGaussianBlurFilter.h
//  Touche
//
//  Created by Georg Kaindl on 14/7/08.
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

@interface TFCIGaussianBlurFilter : CIFilter {
	BOOL			isEnabled;
	CIImage*		inputImage;
	NSNumber*		inputRadius;
	CIFilter*		_blurFilter;
	
	NSInteger		_blurType;
	double			_blurRadiusMultiplier;
	double			_prevRadius;
}

@property (assign) BOOL isEnabled;

@end
