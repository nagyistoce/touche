//
//  TFCapture.m
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

#import "TFCapture.h"

#import "TFIncludes.h"

@implementation TFCapture

@synthesize delegate;

- (void)dealloc
{
	delegate = nil;
	
	[super dealloc];
}

- (void)setDelegate:(id)newDelegate
{
	delegate = newDelegate;
	
	_delegateCapabilities.hasWantedCIImageColorSpace =
		[delegate respondsToSelector:@selector(wantedCIImageColorSpaceForCapture:)];
	
	_delegateCapabilities.hasDidCaptureFrame =
		[delegate respondsToSelector:@selector(capture:didCaptureFrame:)];
}

- (BOOL)isCapturing
{
	TFThrowMethodNotImplementedException();
	
	return NO;
}

- (BOOL)startCapturing:(NSError**)error
{
	TFThrowMethodNotImplementedException();
	
	if (NULL != error)
		*error = nil;
	
	return NO;
}

- (BOOL)stopCapturing:(NSError**)error
{
	TFThrowMethodNotImplementedException();
	
	if (NULL != error)
		*error = nil;
	
	return NO;
}

- (CGSize)frameSize
{
	TFThrowMethodNotImplementedException();
	
	return CGSizeMake(0, 0);
}

- (BOOL)setFrameSize:(CGSize)size error:(NSError**)error
{
	TFThrowMethodNotImplementedException();
	
	if (NULL != error)
		*error = nil;
	
	return NO;
}

- (BOOL)supportsFrameSize:(CGSize)size
{
	TFThrowMethodNotImplementedException();
	
	return NO;
}

@end
