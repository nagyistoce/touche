//
//  TFWizardController.h
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

enum {
	TFWizardControllerStepSetupFTIRTable = 1,
	TFWizardControllerStepSetupScreen = 2,
	TFWizardControllerStepConnectCamera = 3,
	TFWizardControllerStepSetupCamera = 4,
	TFWizardControllerStepConfigurePipeline = 5,
	TFWizardControllerStepCalibrate = 6,
	TFWizardControllerStepTest = 7,
	TFWizardControllerStepFinished = 8
};

@class TFWizardStepController;

@interface TFWizardController : NSViewController {
	id							delegate;
	BOOL						isRunning;

	TFWizardStepController*		_currentViewController;
	NSUInteger					_step;
}

@property (nonatomic, assign) id delegate;
@property (readonly) BOOL isRunning;

- (void)startWizard;
- (void)startCurrentStepSpinner;

@end

@interface NSObject (TFWizardControllerDelegate)
- (NSString*)wizardTitleForStep:(NSInteger)step;
- (NSString*)wizardDescriptionForStep:(NSInteger)step;
- (void)wizardWillStartStep:(NSInteger)step;
- (void)wizardWillFinishStep:(NSInteger)step;
- (SEL)wizardActionForStep:(NSInteger)step ofTarget:(id*)object withTitle:(NSString**)title;
- (void)wizardDidFinish;
@end