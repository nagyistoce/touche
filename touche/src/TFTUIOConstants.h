//
//  TFTUIOConstants.h
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

#import <Foundation/Foundation.h>


extern NSString*	kTFTUIO10CursorProfileAddressString;

extern NSString*	kTFTUIO11BlobProfileAddressString;

extern NSString*	kTFTUIO10SourceArgumentName;
extern NSString*	kTFTUIO10FrameSequenceNumberArgumentName;
extern NSString*	kTFTUIO10AliveArgumentName;
extern NSString*	kTFTUIO10SetArgumentName;

typedef enum {
	TFTUIOVersion1_0Cursors				= 0,
	TFTUIOVersion1_1Blobs				= 1,
	TFTUIOVersion1_0CursorsAnd1_1Blobs	= 2
} TFTUIOVersion;

#define	TFTUIOVersionMin		(TFTUIOVersion1_0Cursors)
#define TFTUIOVersionMax		(TFTUIOVersion1_0CursorsAnd1_1Blobs)
#define TFTUIOVersionCount		((TFTUIOVersionMax) - (TFTUIOVersionMin) + 1)

#define TFTUIOVersionDefault	(TFTUIOVersion1_0Cursors)

NSString* TFTUIOConstantsSourceName();

NSString* TFTUIOVersionToString(TFTUIOVersion ver);

NSMenu* TFTUIOVersionSelectionMenu();

TFTUIOVersion TFTUIOVersionForMenuItem(NSMenuItem* item);

// -1 on error, index of the item otherwise
NSInteger TFTUIOIndexForMenuItemWithVersion(NSMenu* menu, TFTUIOVersion ver);

// time interval between the Cocoa reference date and the NTP reference date (as used
// in TUIO + OSC)
NSTimeInterval TFTUIOTimeIntervalBetweenCocoaAndNTPRefDate();
