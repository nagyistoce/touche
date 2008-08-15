//
//  TFQCDemoView.m
//  TFQCDemo
//
//  Created by Georg Kaindl on 21/5/08.
//  Copyright 2008 Georg Kaindl. All rights reserved.
//

#import "TFQCDemoView.h"


@implementation TFQCDemoView

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)becomeFirstResponder
{
	return YES;
}

// if the user presses the escape key, we quit...
- (void)keyDown:(NSEvent*)event
{
	unichar c = [[event characters] characterAtIndex:0];
	if (27 == c) {
		[NSApp terminate:self];
	}
}

@end
