//
//  TFTouchView.h
//  Touché
//
//  Created by Georg Kaindl on 28/3/08.
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
#import <QuartzCore/CoreAnimation.h>

@interface TFTouchView : NSView {
	CGFloat					touchAnimationSpeed;
	id						delegate;
	NSValue*				touchSize;

	NSMutableDictionary*	_touches;
	CALayer*				_touchesLayer;
	
	NSMutableDictionary*	_cachedTouchImages;	// color -> image
}

@property (assign) CGFloat touchAnimationSpeed;
@property (assign) id delegate;
@property (nonatomic, retain) NSValue* touchSize;

- (void)addTouchWithID:(id)ID atPosition:(CGPoint)pos;
- (void)addTouchWithID:(id)ID atPosition:(CGPoint)pos withColor:(NSColor*)color;
- (void)addTouchWithID:(id)ID atPosition:(CGPoint)pos withColor:(NSColor*)color belowTouchWithID:(id)belowID;
- (void)animateTouchWithID:(id)ID toPosition:(CGPoint)pos;
- (void)moveTouchWithID:(id)ID toPosition:(CGPoint)pos;
- (void)fadeInTouchWithID:(id)ID;
- (void)removeTouchWithID:(id)ID;
- (void)showText:(NSString*)text forSeconds:(NSTimeInterval)seconds;
- (void)clearText;

@end

@interface NSObject (TFTouchViewDelegate)
- (void)keyWentDown:(NSString*)characters;
@end