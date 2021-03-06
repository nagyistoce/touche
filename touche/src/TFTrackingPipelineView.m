//
//  TFTrackingPipelineView.m
//  Touché
//
//  Created by Georg Kaindl on 7/1/08.
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

#import "TFTrackingPipelineView.h"

#import "TFIncludes.h"

@implementation TFTrackingPipelineView

@synthesize delegate;

- (void)dealloc
{
	delegate = nil;
	
	[super dealloc];
}

- (void)setDelegate:(id)newDelegate
{
	delegate = newDelegate;
	
	// cache this for performance reasons
	_delegateHasFrameForTimestamp = [delegate respondsToSelector:@selector(trackingPipelineView:frameForTimestamp:colorSpace:workingColorSpace:)];
}

- (CVReturn)drawFrameForTimeStamp:(const CVTimeStamp*)timeStamp
{
	NSUInteger success = kCVReturnError;
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

	if (_delegateHasFrameForTimestamp) {
		CGColorSpaceRef colorSpace, workingColorSpace;
		
		CIImage* newFrame = [[delegate trackingPipelineView:self
										  frameForTimestamp:timeStamp
											 colorSpace:&colorSpace
									  workingColorSpace:&workingColorSpace] retain];
	
		@synchronized(self) {
			if (nil != colorSpace && _colorSpace != colorSpace) {
				CGColorSpaceRetain(colorSpace);
				CGColorSpaceRelease(_colorSpace);
				_colorSpace = colorSpace;
				
				[self clearCIContext];
			}
			
			if (nil != workingColorSpace && _workingColorSpace != workingColorSpace) {
				CGColorSpaceRetain(workingColorSpace);
				CGColorSpaceRelease(_workingColorSpace);
				_workingColorSpace = workingColorSpace;
				
				[self clearCIContext];
			} 
		
			CGRect oldRect = [_ciimage extent];
			CGRect newRect = [newFrame extent];
			
			if (oldRect.size.width != newRect.size.width || oldRect.size.height != newRect.size.height)
				_needsReshape = YES;
		
			if (nil != _ciimage)
				[_ciimage release];
		
			_ciimage = newFrame;
		}
		
		if (nil != _ciimage) {
			[self render];
			success = kCVReturnSuccess;
		}
	}
	
	if (kCVReturnSuccess == success)
		success = [super drawFrameForTimeStamp:timeStamp];
	
	[pool release];
	
	return success;
}

@end
