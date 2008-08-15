//
//  GCKNumberCircleView.h
//
//  Created by Georg Kaindl on 6/5/08.
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

@interface GCKNumberCircleView : GCKObservingForDisplayView {
	NSUInteger	number;
	CGFloat		circleLineWidth;
	CGFloat		fontStrokeWidth;
	NSValue*	shadowSize;
	CGFloat		shadowBlur;
	
	NSColor*	backgroundColor;
	NSColor*	circleFillColor;
	NSColor*	circleStrokeColor;
	NSColor*	fontStrokeColor;
	NSColor*	fontFillColor;
	NSColor*	shadowColor;	
}

@property (nonatomic, assign) NSUInteger number;
@property (nonatomic, assign) CGFloat circleLineWidth;
@property (nonatomic, assign) CGFloat fontStrokeWidth;
@property (nonatomic, retain) NSValue* shadowSize;
@property (nonatomic, assign) CGFloat shadowBlur;
@property (nonatomic, retain) NSColor* backgroundColor;
@property (nonatomic, retain) NSColor* circleFillColor;
@property (nonatomic, retain) NSColor* circleStrokeColor;
@property (nonatomic, retain) NSColor* fontStrokeColor;
@property (nonatomic, retain) NSColor* fontFillColor;
@property (nonatomic, retain) NSColor* shadowColor;

@end
