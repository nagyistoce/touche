//
//  AppController.h
//  Touché
//
//  Created by Georg C. Kaindl on 13/12/07.
//
//  Copyright (C) 2007 Georg Kaindl
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

#import <Cocoa/Cocoa.h>

@class TFBlobTrackingView;
@class TFTrackingPipeline;
@class TFTrackingDataDistributionCenter;
@class TFPipelineSetupController;
@class TFScreenPreferencesController;
@class TFMiscPreferencesController;
@class TFAboutController;
@class TFCalibrationController;
@class TFTouchTestController;
@class GCKIPhoneNavigationBarView;
@class GCKIPhoneNavigationBarLabelView;
@class TFWizardController;
@class TFWizardView;
@class TFTUIOOSCSettingsController;

@interface AppController : NSWindowController {
	IBOutlet GCKIPhoneNavigationBarView*		_statusBar;
	IBOutlet GCKIPhoneNavigationBarLabelView*	_statusLabel;
	IBOutlet NSView*							_hostView;
	IBOutlet TFWizardView*						_wizardView;
	IBOutlet NSView*							_welcomeView;
	IBOutlet NSView*							_clientListView;
	IBOutlet NSView*							_emptyClientListView;

	IBOutlet TFCalibrationController*		_calibrationController;
	IBOutlet TFTouchTestController*			_touchTestController;

	NSMutableArray*							connectedClients;

	BOOL									_windowCanResize;
	NSView*									_currentMainView;
	BOOL									_switchToMainViewIsUpdate;
	BOOL									_isLoadingPipelineAsync;

	TFTrackingPipeline*						_pipeline;
	TFTrackingDataDistributionCenter*		_distributionCenter;
	TFPipelineSetupController*				_pipelineSetupController;
	TFScreenPreferencesController*			_screenPrefsController;
	TFMiscPreferencesController*			_miscPrefsController;
	TFAboutController*						_aboutController;
	TFWizardController*						_wizardController;
	
	TFTUIOOSCSettingsController*			_tuioSettingsController;
	
	NSInteger								_appStatus;
}

@property (readonly) NSArray* connectedClients;

- (IBAction)showAboutPanel:(id)sender;
- (IBAction)startCalibration:(id)sender;
- (IBAction)startTouchTest:(id)sender;
- (IBAction)showPipelineConfigurationWindow:(id)sender;
- (IBAction)showScreenPrefs:(id)sender;
- (IBAction)showTUIOAddClientPanel:(id)sender;
- (IBAction)showTUIOSettings:(id)sender;
- (IBAction)showMiscPrefs:(id)sender;
- (IBAction)showTrackingPreviewWindow:(id)sender;
- (IBAction)startWizard:(id)sender;
- (IBAction)welcomeViewDismissClicked:(id)sender;
- (IBAction)openIssueTrackerWebpage:(id)sender;
- (IBAction)openHomepage:(id)sender;

@end
