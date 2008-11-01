//
//  TFBlobBox.h
//  Touché
//
//  Created by Georg Kaindl on 18/12/07.
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

@class TFBlobPoint;
@class TFBlobSize;

@interface TFBlobBox : NSObject <NSCopying, NSCoding> {
	TFBlobPoint*		origin;
	TFBlobSize*			size;
}

@property (retain) TFBlobPoint* origin;
@property (retain) TFBlobSize* size;

- (id)initWithOrigin:(TFBlobPoint*)o size:(TFBlobSize*)s;

@end
