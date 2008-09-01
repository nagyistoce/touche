//
//  TFCameraInputPreviewView.m
//  Touché
//
//  Created by Georg Kaindl on 13/12/07.
//  Copyright 2007 Georg Kaindl. All rights reserved.
//

#import "TFCameraInputPreviewView.h"
#import "TFCameraInputFilterChain.h"

@implementation TFCameraInputPreviewView

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	_filterChain = [TFCameraInputFilterChain sharedFilterChain];
}

- (CIImage*)_processImage:(CIImage*)inputImage
{
	return [_filterChain apply:inputImage];
}

@end
