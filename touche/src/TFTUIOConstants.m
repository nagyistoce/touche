//
//  TFTUIOConstants.m
//  Touché
//
//  Created by Georg Kaindl on 6/9/08.
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

#import "TFTUIOConstants.h"


NSString* kTFTUIOProfileAddressString	= @"/tuio/2Dcur";

NSString* kTFTUIOSourceArgumentName					= @"source";
NSString* kTFTUIOFrameSequenceNumberArgumentName	= @"fseq";
NSString* kTFTUIOAliveArgumentName					= @"alive";
NSString* kTFTUIOSetArgumentName					= @"set";

NSString* TFTUIOConstantsSourceName()
{
	static NSString* appName = nil;
	
	if (nil == appName) {
		NSBundle* mainBundle = [NSBundle mainBundle];
		NSString* name = [mainBundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
		if (nil != name) {
			NSString* version = [mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
			if (nil != version)
				name = [name stringByAppendingFormat:@" %@", version];
		}
		
		if (nil != name)
			appName = [name retain];
	}
	
	return appName;
}