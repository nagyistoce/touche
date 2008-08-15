//
//  TFCIBackgroundSubtractionFilter.h
//  Touché
//
//  Created by Georg Kaindl on 9/1/08.
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

@interface TFCIBackgroundSubtractionFilter : CIFilter {
	CIImage*		inputImage;
	BOOL			isEnabled;
	BOOL			useBlending;
	BOOL			allowBackgroundPictureUpdate;
	BOOL			forceBackgroundPictureAfterEnabling;
	CGFloat			blendingRatio;
	
	CIFilter*			_blendingFilter;
	CIImageAccumulator* _backgroundAccumulator;
	float				_framesProcessedSinceEnabled;
}

@property (assign) CGFloat blendingRatio;
@property (assign) BOOL isEnabled;
@property (assign) BOOL useBlending;
@property (assign) BOOL forceBackgroundPictureAfterEnabling;
@property (assign) BOOL allowBackgroundPictureUpdate;

- (void)assignBackgroundImage:(CIImage*)newImage;
- (void)clearBackgroundImage;

@end
