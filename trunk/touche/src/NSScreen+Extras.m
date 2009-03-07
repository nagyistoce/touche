//
//  NSScreen+Extras.m
//  Touché
//
//  Created by Georg Kaindl on 17/5/08.
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

#import "NSScreen+Extras.h"


@implementation NSScreen (GCKExtras)

#if defined(WINDOWS)
- (NSDictionary*)deviceDescription
{
	return nil;
}
#endif

+ (NSScreen*)screenWithDisplayID:(CGDirectDisplayID)displayID
{
	for (NSScreen* s in [NSScreen screens]) {
		NSNumber* screenNum = [[s deviceDescription] objectForKey:@"NSScreenNumber"];
		if (nil == screenNum)
			continue;
		
		if ([screenNum intValue] == displayID)
			return s;
	}
	
	return nil;
}

- (CGDirectDisplayID)directDisplayID
{
	return [[[self deviceDescription] objectForKey:@"NSScreenNumber"] integerValue];
}

@end
