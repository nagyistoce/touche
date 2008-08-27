//
//  TFQTKitCapture.h
//  Touché
//
//  Created by Georg Kaindl on 4/1/08.
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
#import <QTKit/QTKit.h>

#import "TFCapture.h"


@interface TFQTKitCapture : TFCapture {
	QTCaptureSession*					session;
	QTCaptureDeviceInput*				deviceInput;
	QTCaptureDecompressedVideoOutput*	videoOut;
	double								framedropLatencyThreshold;
}

@property (readonly) QTCaptureSession* session;
@property (readonly) QTCaptureDeviceInput* deviceInput;
@property (readonly) QTCaptureOutput* videoOut;
@property (nonatomic, assign) double framedropLatencyThreshold;

- (id)initWithDevice:(QTCaptureDevice*)device;
- (id)initWithDevice:(QTCaptureDevice*)device error:(NSError**)error;
- (id)initWithUniqueDeviceId:(NSString*)deviceId;
- (id)initWithUniqueDeviceId:(NSString*)deviceId error:(NSError**)error;

- (QTCaptureDevice*)captureDevice;
- (BOOL)setCaptureDevice:(QTCaptureDevice*)newDevice error:(NSError**)error;
- (NSString*)captureDeviceUniqueId;
- (BOOL)setCaptureDeviceWithUniqueId:(NSString*)deviceId error:(NSError**)error;

+ (NSDictionary*)connectedDevicesNamesAndIds;
+ (QTCaptureDevice*)defaultCaptureDevice;
+ (NSString*)defaultCaptureDeviceUniqueId;

@end
