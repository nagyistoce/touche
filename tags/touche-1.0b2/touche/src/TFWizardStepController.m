//
//  TFWizardStepController.m
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

#import "TFWizardStepController.h"

#import "TFIncludes.h"
#import "GCKNumberCircleView.h"
#import "TFMiscPreferencesController.h"

#define	SPINNER_TO_BUTTON_X_OFFSET	(8.0f)

@interface TFWizardStepController (NonPublicMethods)
- (void)_clickSpecificButton:(id)sender;
- (void)_sizeControlWithAnchorToTheRight:(NSControl*)control;
@end

@implementation TFWizardStepController

@synthesize delegate;

- (void)dealloc
{
	[[NSUserDefaults standardUserDefaults] removeObserver:self
											   forKeyPath:tFUIColorPreferenceKey];
	
	[super dealloc];
}

- (id)init
{
	return [self initWithStep:1];
}

- (id)initWithStep:(NSUInteger)step
{
	return [self initWithNibName:@"WizardStep"
						  bundle:[NSBundle bundleForClass:[self class]]
							step:step];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	return [self initWithNibName:nibNameOrNil bundle:nibBundleOrNil step:1];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil step:(NSUInteger)step
{
	if (!(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		[self release];
		return nil;
	}
	
	_step = step;
	[self loadView];
	
	[[NSUserDefaults standardUserDefaults] addObserver:self
											forKeyPath:tFUIColorPreferenceKey
											   options:NSKeyValueObservingOptionNew
											   context:NULL];
	
	return self;
}

- (void)loadView
{
	[super loadView];
	
	NSColor* color = [TFMiscPreferencesController wizardNumberCircleColor];
	_numberCircleView.number = _step;
	_numberCircleView.circleStrokeColor = color;
	_numberCircleView.circleFillColor = [NSColor clearColor];
	_numberCircleView.fontFillColor = color;
	_numberCircleView.fontStrokeColor = color;
	_numberCircleView.backgroundColor = [NSColor clearColor];
	_numberCircleView.fontStrokeWidth = 0.0f;
	_numberCircleView.circleLineWidth = 4.5f;
	
	[_specificButton setHidden:YES];
	[_nextButton setEnabled:NO];
}

- (void)setNextButtonEnabled:(BOOL)val
{
	[_nextButton setEnabled:val];
}

- (void)setNextButtonTitle:(NSString*)newTitle
{
	if (nil != newTitle) {
		[_nextButton setTitle:newTitle];
		[self _sizeControlWithAnchorToTheRight:_specificButton];
		[self _sizeControlWithAnchorToTheRight:_nextButton];
	}
}

- (void)setTitleLabelString:(NSString*)titleString
{
	[_titleLabel setStringValue:titleString];
}

- (void)setDescriptionLabelString:(NSString*)descriptionString
{
	[_descriptionLabel setStringValue:descriptionString];
}

- (void)setSpecificButtonTitle:(NSString*)buttonTitle action:(SEL)action ofObject:(id)object
{
	[_specificButton setAction:@selector(_clickSpecificButton:)];
	[_specificButton setTarget:self];
	[_specificButton setTitle:buttonTitle];
	[_specificButton setHidden:(nil == buttonTitle || nil == object)];
	
	[self _sizeControlWithAnchorToTheRight:_specificButton];
	[self _sizeControlWithAnchorToTheRight:_nextButton];
	
	_specificAction = action;
	_specificObject = object;
}

- (void)startSpinner
{
	[_spinner setHidden:NO];
	[_spinner startAnimation:nil];
}

- (void)stopSpinner
{
	[_spinner stopAnimation:nil];
	[_spinner setHidden:YES];
}

- (void)positionSpinnerNextToLeftmostButton
{
	NSRect buttonFrame = [_specificButton isHidden] ? [_nextButton frame] : [_specificButton frame];
	NSRect spinnerFrame = [_spinner frame];
	
	spinnerFrame.origin.x = buttonFrame.origin.x - spinnerFrame.size.width - SPINNER_TO_BUTTON_X_OFFSET;
	
	[_spinner setFrame:spinnerFrame];
}

#pragma mark -
#pragma mark Actions

- (IBAction)nextButtonClicked:(id)sender
{
	[_nextButton setEnabled:NO];
	if ([delegate respondsToSelector:@selector(wizardStepController:nextButtonWasClickedInStep:)])
		[delegate wizardStepController:self nextButtonWasClickedInStep:_step];
}

#pragma mark -
#pragma mark Key-Value Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isEqual:[NSUserDefaults standardUserDefaults]]) {
		if ([keyPath isEqualToString:tFUIColorPreferenceKey]) {
			NSColor* c = [NSKeyedUnarchiver unarchiveObjectWithData:[change objectForKey:NSKeyValueChangeNewKey]];
			NSColor* color = [TFMiscPreferencesController wizardNumberCircleColorForBaseColor:c];
			_numberCircleView.circleStrokeColor = color;
			_numberCircleView.fontFillColor = color;
			_numberCircleView.fontStrokeColor = color;
		}
	}
}

#pragma mark -
#pragma mark Private Methods

- (void)_clickSpecificButton:(id)sender
{
	if (nil != _specificObject)
		[_specificObject performSelector:_specificAction withObject:nil];

	if ([delegate respondsToSelector:@selector(wizardStepController:specificButtonWasClickedInStep:)])
		[delegate wizardStepController:self specificButtonWasClickedInStep:_step];
}

- (void)_sizeControlWithAnchorToTheRight:(NSControl*)control
{
	NSRect oldFrame = [control frame];
	[control sizeToFit];
	NSRect newFrame = [control frame];
	[control setFrame:NSMakeRect(
			oldFrame.origin.x + (oldFrame.size.width-newFrame.size.width),
			newFrame.origin.y,
			newFrame.size.width,
			newFrame.size.height
			)];
	[control setNeedsDisplay:YES];
}

@end
