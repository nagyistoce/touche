//
//  TFCapture.h
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

@interface TFCapture : NSObject {
	id		delegate;
	
	struct {
		unsigned int hasWantedCIImageColorSpace:1;
		unsigned int hasDidCaptureFrame:1;
	} _delegateCapabilities;
}

@property (assign) id delegate;

- (void)setDelegate:(id)newDelegate;

- (BOOL)isCapturing;
- (BOOL)startCapturing:(NSError**)error;
- (BOOL)stopCapturing:(NSError**)error;
- (CGSize)frameSize;
- (BOOL)setFrameSize:(CGSize)size error:(NSError**)error;
- (BOOL)supportsFrameSize:(CGSize)size;

@end

@interface NSObject (TFCaptureDelegate)
- (CGColorSpaceRef)wantedCIImageColorSpace;
- (void)didCaptureFrame:(CIImage*)capturedFrame;
@end