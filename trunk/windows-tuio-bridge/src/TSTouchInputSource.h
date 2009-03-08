//
//  TSTouchInputSource.h
//  TouchsmartTUIO
//
//  Created by Georg Kaindl on 27/2/09.
//
//  Copyright (C) 2009 Georg Kaindl
//
//  This file is part of Touchsmart TUIO.
//
//  Touchsmart TUIO is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as
//  published by the Free Software Foundation, either version 3 of
//  the License, or (at your option) any later version.
//
//  Touchsmart TUIO is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public
//  License along with Touchsmart TUIO. If not, see <http://www.gnu.org/licenses/>.
//

#import <Cocoa/Cocoa.h>


extern NSString*	kTISSenderName;
extern NSString*	kTISSenderProductID;
extern NSString*	kTISSenderModel;
extern NSString*	kTISSenderSerialNumber;
extern NSString*	kTISSenderFirmwareVersion;

@interface TSTouchInputSource : NSObject {
	id					delegate;

	NSDictionary*		_senderInfoDict;
}

@property (assign) id delegate;

// this will be called before the program exits. The class should clean up any shared resources
// here, such as driver handles, etc.
+ (void)cleanUp;

- (id)init;
- (void)dealloc;

- (void)invalidate;
- (BOOL)isReceivingTouchData;

- (NSDictionary*)currentSenderInfo;

- (NSArray*)currentLabelizedTouches;

@end

@interface NSObject (TSTouchInputSourceDelegate)
- (void)touchInputSource:(TSTouchInputSource*)source senderInfoDidChange:(NSDictionary*)senderInfoDict;
@end
