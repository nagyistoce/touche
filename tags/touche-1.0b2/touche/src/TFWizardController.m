//
//  TFWizardController.m
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

#import "TFWizardController.h"

#import "TFIncludes.h"
#import "TFWizardStepController.h"
#import "TFWizardView.h"

@interface TFWizardController (NonPublicMethods)
- (void)_showViewForStep:(NSUInteger)step;
@end

@implementation TFWizardController

@synthesize delegate;
@synthesize isRunning;

- (void)dealloc
{
	[_currentViewController release];
	_currentViewController = nil;
	
	[super dealloc];
}

- (void)startWizard
{
	if (isRunning)
		return;
	
	isRunning = YES;

	_step = 1;
	
	[_currentViewController release];
	_currentViewController = nil;
	
	[self _showViewForStep:_step];
}

- (void)_showViewForStep:(NSUInteger)step
{
	NSString* title = nil;
	NSString* desc = nil;
	
	if ([delegate respondsToSelector:@selector(wizardWillStartStep:)])
		[delegate wizardWillStartStep:step];
	if ([delegate respondsToSelector:@selector(wizardTitleForStep:)])
		title = [delegate wizardTitleForStep:step];
	if ([delegate respondsToSelector:@selector(wizardDescriptionForStep:)])
		desc = [delegate wizardDescriptionForStep:step];

	TFWizardStepController* c = [[TFWizardStepController alloc] initWithStep:step];
	if (nil != title)
		[c setTitleLabelString:title];
	if (nil != desc)
		[c setDescriptionLabelString:desc];
	c.delegate = self;
	
	if (TFWizardControllerStepFinished == step) {
		[c setNextButtonEnabled:YES];
		[c setNextButtonTitle:@"Finish"];
	} else {
		id target = nil;
		NSString* buttontitle = nil;
		SEL action;
		
		if ([delegate respondsToSelector:@selector(wizardActionForStep:ofTarget:withTitle:)])
			action = [delegate wizardActionForStep:step ofTarget:&target withTitle:&buttontitle];
		
		if (nil != target && nil != buttontitle)
			[c setSpecificButtonTitle:buttontitle action:action ofObject:target];
		else
			[c setNextButtonEnabled:YES];
	}
	
	TFWizardView* wizardView = (TFWizardView*)[self view];
	[wizardView switchToView:[c view]];
	
	[_currentViewController release];
	_currentViewController = c;
}

- (void)startCurrentStepSpinner
{
	[_currentViewController positionSpinnerNextToLeftmostButton];
	[_currentViewController startSpinner];
}

#pragma mark -
#pragma mark TFWizardStepController delegate

- (void)wizardStepController:(TFWizardStepController*)controller nextButtonWasClickedInStep:(NSUInteger)step
{
	if ([delegate respondsToSelector:@selector(wizardWillFinishStep:)])
		[delegate wizardWillFinishStep:step];

	if (step >= TFWizardControllerStepFinished) {
		isRunning = NO;
	
		if ([delegate respondsToSelector:@selector(wizardDidFinish)])
			[delegate wizardDidFinish];
		
		return;
	}

	_step++;
	[self _showViewForStep:_step];
}

- (void)wizardStepController:(TFWizardStepController*)controller specificButtonWasClickedInStep:(NSUInteger)step
{
	[controller setNextButtonEnabled:YES];
}

@end
