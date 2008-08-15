//
//  GCKIPhoneNavigationBarLabelView.h
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

enum {
	GCKIPhoneNavigationBarLabelViewTextAlignLeft = 0,
	GCKIPhoneNavigationBarLabelViewTextAlignCenter = 1,
	GCKIPhoneNavigationBarLabelViewTextAlignRight = 2,
	GCKIPhoneNavigationBarLabelViewTextAlignTop = 3,
	GCKIPhoneNavigationBarLabelViewTextAlignBottom = 4
};

@interface GCKIPhoneNavigationBarLabelView : GCKObservingForDisplayView {
	NSString*		string;
	NSString*		fontName;
	CGFloat			fontSize;
	CGFloat			fontStrokeWidth;
	NSInteger		textAlignX, textAlignY;
	NSValue*		shadowSize;
	CGFloat			shadowBlur;
	NSColor*		shadowColor;
	NSColor*		fontFillColor;
	NSColor*		fontStrokeColor;	
}

@property (nonatomic, retain) NSString* string;
@property (nonatomic, retain) NSString* fontName;
@property (nonatomic, assign) CGFloat fontSize;
@property (nonatomic, assign) CGFloat fontStrokeWidth;
@property (nonatomic, assign) NSInteger textAlignX;
@property (nonatomic, assign) NSInteger textAlignY;
@property (nonatomic, retain) NSValue* shadowSize;
@property (nonatomic, assign) CGFloat shadowBlur;
@property (nonatomic, retain) NSColor* shadowColor;
@property (nonatomic, retain) NSColor* fontFillColor;
@property (nonatomic, retain) NSColor* fontStrokeColor;

@end
