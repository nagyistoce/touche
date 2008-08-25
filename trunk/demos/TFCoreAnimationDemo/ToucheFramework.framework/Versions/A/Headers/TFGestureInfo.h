//
//  TFGestureInfo
//  Touché
//
//  Created by Georg Kaindl on 22/5/08.
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

#import "TFGestureConstants.h"

@interface TFGestureInfo : NSObject {
	TFGestureType		type;
	TFGestureSubtype	subtype;
	NSDictionary*		parameters;
	NSTimeInterval		createdAt;
	id					userInfo;
}

@property (nonatomic, assign) TFGestureType type;
@property (nonatomic, assign) TFGestureSubtype subtype;
@property (nonatomic, retain) NSDictionary* parameters;
@property (readonly) NSTimeInterval createdAt;
@property (nonatomic, retain) id userInfo;

- (id)initWithType:(TFGestureType)t;
- (id)initWithType:(TFGestureType)t andSubtype:(TFGestureSubtype)st;
- (id)initWithType:(TFGestureType)t andSubtype:(TFGestureSubtype)st andParameters:(NSDictionary*)params;

+ (id)info;
+ (id)infoWithType:(TFGestureType)t;
+ (id)infoWithType:(TFGestureType)t andSubtype:(TFGestureSubtype)st;
+ (id)infoWithType:(TFGestureType)t andSubtype:(TFGestureSubtype)st andParameters:(NSDictionary*)params;

@end
