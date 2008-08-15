//
//  TFBlob+FrameworkAdditions.m
//  Touché
//
//  Created by Georg Kaindl on 21/5/08.
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

#import "TFBlob+FrameworkAdditions.h"

#import "TFIncludes.h"
#import "TFBlobPoint.h"

@implementation TFBlob (FrameworkAdditions)

- (NSPoint)centerQCCoordinatesForViewSize:(NSSize)viewSize
{
	return [self QCCoordinatesForPoint:NSMakePoint(self.center.x, self.center.y)
						   andViewSize:viewSize];
}

- (NSPoint)QCCoordinatesForPoint:(NSPoint)point andViewSize:(NSSize)viewSize
{
	NSPoint rv;
	CGFloat invAspectRatio = viewSize.height / viewSize.width;
	rv.x = ((point.x / viewSize.width) * 2.0) - 1.0;
	rv.y = ((point.y / viewSize.height) * 2.0 * invAspectRatio) - invAspectRatio;
	
	return rv;
}

@end
