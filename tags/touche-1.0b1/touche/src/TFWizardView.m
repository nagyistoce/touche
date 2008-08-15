//
//  TFWizardView.m
//  Touché
//
//  Created by Georg Kaindl on 6/5/08.
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

#import "TFWizardView.h"

#import <QuartzCore/CoreAnimation.h>

#import "TFIncludes.h"

enum {
	TransitionTypeNotSet = 0,
	TransitionTypeIn = 1,
	TransitionTypeSwitch = 2
};

@interface TFWizardView (NonPublicMethods)
- (void)_setTransitionType;
- (void)_doSwitchToView:(NSView*)view;
@end

@implementation TFWizardView

@synthesize animationEnabled;

- (void)setAnimationEnabled:(BOOL)newVal
{
	animationEnabled = newVal;
	[self _setTransitionType];
}

- (void)dealloc
{
	[_currentView release];
	_currentView = nil;
	
	[super dealloc];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		_transitionType = TransitionTypeNotSet;
		animationEnabled = YES;
    }
    return self;
}

- (void)reset
{
	[_currentView release];
	_currentView = nil;
	
	_transitionType = TransitionTypeNotSet;
}

- (void)switchToView:(NSView*)view
{
	if (nil == view)
		return;
	
	[self _setTransitionType];
	[self setWantsLayer:YES];
	
	[self performSelector:@selector(_doSwitchToView:) withObject:view afterDelay:.01f];
}

- (void)_setTransitionType
{
	if (!animationEnabled) {
		[self setAnimations:[NSDictionary dictionary]];
		return;
	}

	NSString* type = nil;
	if (nil == _currentView && TransitionTypeIn != _transitionType)
		type = kCATransitionFade;
	else if (nil != _currentView && TransitionTypeSwitch != _transitionType)
		type = kCATransitionPush;
	
	if (nil != type) {
		CATransition* transition = [CATransition animation];
		transition.type = type;
		transition.subtype = kCATransitionFromRight;
		transition.duration = .3f;
		transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		transition.delegate = self;
		
		[self setAnimations:[NSDictionary dictionaryWithObject:transition forKey:@"subviews"]];
	}
}

- (void)_doSwitchToView:(NSView*)view
{
	if (![self wantsLayer]) {
		[self setWantsLayer:YES];
		[self performSelector:@selector(_doSwitchToView:) withObject:view afterDelay:.01f];
	}

	if (_currentView)
		[[self animator] replaceSubview:_currentView with:view];
	else
		[[self animator] addSubview:view];
	
	[_currentView release];
	_currentView = [view retain];
}

#pragma mark -
#pragma mark CAAnimation delegate

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
	[self setWantsLayer:NO];
}

@end
