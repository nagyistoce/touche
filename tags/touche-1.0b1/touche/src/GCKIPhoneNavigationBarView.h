//
//  GCKIPhoneNavigationBarView.h
//
//  Created by Georg Kaindl on 5/5/08.
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

#import "GCKObservingForDisplayView.h"

enum {
	GCKIPhoneNavigationBarViewShadowPositionBottom = 0,
	GCKIPhoneNavigationBarViewShadowPositionTop = 1,
	GCKIPhoneNavigationBarViewShadowPositionBoth = 2
};

@interface GCKIPhoneNavigationBarView : GCKObservingForDisplayView {
	NSColor*		baseColor;
	BOOL			hasShadow;
	NSInteger		shadowPosition;
	BOOL			hasTopDarkLine;
		
	CGColorRef		_baseColorCG;
	CGColorRef		_topLineColor;
	CGColorRef		_bottomLineColor;
	CGColorRef		_bottomGradientTopColor;
	CGColorRef		_topGradientTopColor;
	CGColorRef		_topGradientBottomColor;
	CGGradientRef	_topGradient;
	CGGradientRef	_bottomGradient;
}

@property (nonatomic, retain) NSColor* baseColor;
@property (nonatomic, assign) BOOL hasShadow;
@property (nonatomic, assign) NSInteger shadowPosition;
@property (nonatomic, assign) BOOL hasTopDarkLine;

@end
