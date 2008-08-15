//
//  TFWizardStepController.h
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

#import <Cocoa/Cocoa.h>

@class GCKNumberCircleView;

@interface TFWizardStepController : NSViewController {
	id								delegate;

	IBOutlet GCKNumberCircleView*	_numberCircleView;
	IBOutlet NSTextField*			_titleLabel;
	IBOutlet NSTextField*			_descriptionLabel;
	IBOutlet NSButton*				_specificButton;
	IBOutlet NSButton*				_nextButton;
	IBOutlet NSProgressIndicator*	_spinner;

	NSUInteger						_step;
	SEL								_specificAction;
	id								_specificObject;
}

@property (nonatomic, assign) id delegate;

- (id)initWithStep:(NSUInteger)step;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil step:(NSUInteger)step;

- (void)setNextButtonEnabled:(BOOL)val;
- (void)setNextButtonTitle:(NSString*)newTitle;
- (void)setTitleLabelString:(NSString*)titleString;
- (void)setDescriptionLabelString:(NSString*)descriptionString;
- (void)setSpecificButtonTitle:(NSString*)buttonTitle action:(SEL)action ofObject:(id)object;
- (void)startSpinner;
- (void)stopSpinner;
- (void)positionSpinnerNextToLeftmostButton;

- (IBAction)nextButtonClicked:(id)sender;

@end

@interface NSObject (TFWizardStepControllerDelegate)
- (void)wizardStepController:(TFWizardStepController*)controller nextButtonWasClickedInStep:(NSUInteger)step;
- (void)wizardStepController:(TFWizardStepController*)controller specificButtonWasClickedInStep:(NSUInteger)step;
@end