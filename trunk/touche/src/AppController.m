//
//  AppController.m
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

#import "AppController.h"

#import "TFIncludes.h"
#import "TFQTKitCapture.h"
#import "TFTrackingPipeline.h"
#import "TFTrackingServer.h"
#import "TFPipelineSetupController.h"
#import "TFScreenPreferencesController.h"
#import "TFMiscPreferencesController.h"
#import "TFAboutController.h"
#import "TFCalibrationController.h"
#import "TFTouchTestController.h"
#import "GCKIPhoneNavigationBarView.h"
#import "GCKIPhoneNavigationBarLabelView.h"
#import "TFWizardController.h"
#import "TFWizardView.h"
#import "TFInfoViewController.h"
#import "TFInfoView.h"
#import "TFTrackingClient.h"

NSString* tFIsFirstRunPreferenceKey = @"tFIsFirstRunPreferenceKey";

#define InfoViewIdentifierMatches(view, ident)	([(view) respondsToSelector:@selector(controller)] && \
												[[(id)(view) controller] isKindOfClass:[TFInfoViewController class]] && \
												(NSUInteger)[(id)[(id)(view) controller] identifier] == (ident))

enum {
	AppStatusUninitialized = -1,
	AppStatusIsTracking = 0,
	AppStatusPipelineReady = 1,
	AppStatusCalibrationRecommended = 2,
	AppStatusCalibrationNeeded = 3,
	AppStatusPipelineIntermittentError = 4,
	AppStatusPipelineNotReady = 5,
	AppStatusPipelineStartupFailed = 6,
	AppStatusPipelineError = 7,
	AppStatusWelcomeScreenRunning = 8
};

enum {
	InfoViewIdentifierCalibrationCanceledByUser = 1,
	InfoViewIdentifierCalibrationCanceledWithError,
	InfoViewIdentifierCalibrationSuccessful,
	InfoViewIdentifierCalibrationInvalidData,
	InfoViewIdentifierTouchTestSuccessful,
	InfoViewIdentifierTouchTestError
};

@interface AppController (NonPublicMethods)
- (void)_removeDisconnectedClient:(NSString*)name;
- (void)_showCurrentMainView;
- (void)_updateCurrentMainView;
- (void)_promoteViewToMainView:(NSView*)view;
- (void)_promoteViewToMainViewOnMainThread:(NSView*)view;
- (void)_animatePromotionToMainView:(NSView*)view;
- (void)_makeMainView:(NSView*)view;
- (void)_resizeWindowTo:(NSSize)size;
- (void)_ensurePipelineSetupControllerLoaded;
- (void)_loadPipelineAsync;
- (void)_loadPipelineAsyncThread;
- (void)_pipelineLoadedAsyncWithError:(NSError*)error;
- (void)_updateStatusLabelForListView;
@end

@implementation AppController

@synthesize connectedClients;

- (void)dealloc
{
	[[NSUserDefaults standardUserDefaults] removeObserver:self
											   forKeyPath:tFUIColorPreferenceKey];

	[connectedClients release];
	connectedClients = nil;
	
	[_pipeline release];
	_pipeline = nil;
	
	[_currentMainView release];
	_currentMainView = nil;
	
	[_server release];
	_server = nil;
	
	[_pipelineSetupController release];
	_pipelineSetupController = nil;
	
	[_wizardController release];
	_wizardController = nil;
	
	[_aboutController release];
	_aboutController = nil;
	
	[super dealloc];
}

- (void)awakeFromNib
{
	_statusBar.baseColor = [TFMiscPreferencesController baseColor];
	_statusLabel.fontFillColor = [TFMiscPreferencesController labelColor];
	_statusLabel.string = @"Touché";
	//_statusLabel.fontName = @"LucidaGrande-Bold";
	_statusLabel.textAlignX = GCKIPhoneNavigationBarLabelViewTextAlignCenter;
		
	[self _showCurrentMainView];
	
	_windowCanResize = YES;
	
	[[self window] setDelegate:self];
	
	NSString		*userDefaultsPath	= [[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"];
	NSDictionary	*userDefaults		= [NSDictionary dictionaryWithContentsOfFile:userDefaultsPath];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:userDefaults];
	
	_appStatus = AppStatusUninitialized;
	connectedClients = [[NSMutableArray alloc] init];
	
	CATransition* transition = [CATransition animation];
	transition.type = kCATransitionFade;
	transition.subtype = kCATransitionFromRight;
	transition.duration = .3f;
	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
	transition.delegate = self;
	
	[_hostView setAnimations:[NSDictionary dictionaryWithObject:transition forKey:@"subviews"]];
	
	[[NSUserDefaults standardUserDefaults] addObserver:self
											forKeyPath:tFUIColorPreferenceKey
											   options:NSKeyValueObservingOptionNew
											   context:NULL];
}

- (IBAction)showAboutPanel:(id)sender
{
	if (nil == _aboutController)
		_aboutController = [[TFAboutController alloc] init];
	
	[_aboutController showWindow:sender];
}

- (IBAction)showPipelineConfigurationWindow:(id)sender
{
	[self _ensurePipelineSetupControllerLoaded];
	[_pipelineSetupController showWindow:self];
}

- (IBAction)showScreenPrefs:(id)sender
{
	if (nil == _screenPrefsController)
		_screenPrefsController = [[TFScreenPreferencesController alloc] init];
	
	[_screenPrefsController showWindow:sender];
}

- (IBAction)showMiscPrefs:(id)sender
{
	if (nil == _miscPrefsController)
		_miscPrefsController = [[TFMiscPreferencesController alloc] init];
	
	[_miscPrefsController showWindow:sender];
}

- (IBAction)showTrackingPreviewWindow:(id)sender
{
	[self _ensurePipelineSetupControllerLoaded];
	[_pipelineSetupController showPreviewWindow:sender];
}

- (IBAction)startCalibration:(id)sender
{
	if (!_calibrationController.isCalibrating) {
		_calibrationController.delegate = self;
		_pipeline.transformBlobsToScreenCoordinates = NO;
		[_calibrationController startCalibrationWithPoints:[_pipeline screenPointsForCalibration]];
	}
}

- (IBAction)startTouchTest:(id)sender
{
	if (!_touchTestController.isRunning) {
		_touchTestController.delegate = self;
		[_touchTestController startTest];
	}
}

- (IBAction)startWizard:(id)sender
{
	if (AppStatusPipelineReady < _appStatus && AppStatusWelcomeScreenRunning != _appStatus)
		return;

	if (nil == _wizardController) {
		_wizardController = [[TFWizardController alloc] init];
		[_wizardController setView:_wizardView];
		_wizardController.delegate = self;
	}
	
	[self _promoteViewToMainView:_wizardView];
	[_wizardController startWizard];
	_appStatus = AppStatusUninitialized;
}

- (IBAction)welcomeViewDismissClicked:(id)sender
{
	_appStatus = AppStatusUninitialized;
	[self _loadPipelineAsync];
}

- (void)_ensurePipelineSetupControllerLoaded
{
	if (nil == _pipelineSetupController) {
		_pipelineSetupController = [[TFPipelineSetupController alloc] init];
		[_pipelineSetupController setTrackingInputStatusMessage:@""];
	}
}

- (void)_promoteViewToMainView:(NSView*)view
{
	[_wizardView setAnimationEnabled:NO];

	if (view == _currentMainView)
		return;
	
	[self performSelectorOnMainThread:@selector(_promoteViewToMainViewOnMainThread:)
						   withObject:view
						waitUntilDone:YES];
}

- (void)_promoteViewToMainViewOnMainThread:(NSView*)view
{
	if ([[self window] isVisible]) {
		[_hostView setWantsLayer:YES];
		[self performSelector:@selector(_animatePromotionToMainView:) withObject:view afterDelay:0.05f];
	} else {
		[self _makeMainView:view];
	}
}

- (void)_animatePromotionToMainView:(NSView*)view
{
	if (![_hostView wantsLayer]) {
		[_hostView setWantsLayer:YES];
		[self performSelector:@selector(_animatePromotionToMainView:) withObject:view afterDelay:0.05f];
	}
	
	[self _makeMainView:view];
}

- (void)_makeMainView:(NSView*)view
{	
	if (_switchToMainViewIsUpdate && (view == _emptyClientListView || view == _clientListView)) {
		_switchToMainViewIsUpdate = NO;
		
		if (_emptyClientListView != _currentMainView && _clientListView != _currentMainView)
			return;
	}
	
	if ((_clientListView == view || _emptyClientListView == view) && AppStatusPipelineReady < _appStatus)
		return;

	if (view == _wizardView || view == _welcomeView || [view isKindOfClass:[TFInfoView class]]) {		
		[_hostView setAutoresizesSubviews:NO];
		[[self window] setShowsResizeIndicator:NO];
		_windowCanResize = NO;
		[self _resizeWindowTo:NSMakeSize(428.0f, 331.0f)];
	} else {
		[_hostView setAutoresizesSubviews:YES];
		[[self window] setShowsResizeIndicator:YES];
		_windowCanResize = YES;
	}
	
	if (nil != _currentMainView)
		[[_hostView animator] replaceSubview:_currentMainView with:view];
	else
		[[_hostView animator] addSubview:view];
	
	[_currentMainView release];
	_currentMainView = [view retain];
	
	NSString* newStr = nil;
	if (view == _wizardView)
		newStr = TFLocalizedString(@"Setup Assistant", @"Setup Assistant");
	else if (view == _welcomeView)
		newStr = TFLocalizedString(@"Welcome to Touché", @"Welcome to Touché");
	else if ([view isKindOfClass:[TFInfoView class]]) {
		TFInfoViewController* viewController = (TFInfoViewController*)((TFInfoView*)view).controller;
		
		switch (viewController.type) {
			case TFInfoViewControllerTypeInfo:
				newStr = TFLocalizedString(@"StatusLabelInfo", @"Notification");
				break;
			case TFInfoViewControllerTypeAlert:
				newStr = TFLocalizedString(@"StatusLabelWarning", @"Warning");
				break;
			case TFInfoViewControllerTypeError:
			default:
				newStr = TFLocalizedString(@"StatusLabelError", @"Error");
				break;
		}
	} else if (view == _clientListView || view == _emptyClientListView)
		[self _updateStatusLabelForListView];
	
	if (nil != newStr && ![newStr isEqualToString:_statusLabel.string])
		_statusLabel.string = newStr;	
}

- (void)_resizeWindowTo:(NSSize)size
{
	NSRect frame = [[self window] frame];
	frame.origin.y = frame.origin.y + frame.size.height - size.height;
	frame.size = size;
	[[[self window] animator] setFrame:frame display:YES];
}

- (void)_showCurrentMainView
{
	if ([_wizardController isRunning]) {
		[self _promoteViewToMainView:_wizardView];
	} else if ([connectedClients count] <= 0) {
		[self _promoteViewToMainView:_emptyClientListView];
	} else {
		[self _promoteViewToMainView:_clientListView];
	}
}

- (void)_updateCurrentMainView
{
	if (_currentMainView != _emptyClientListView && _currentMainView != _clientListView)
		return;
	
	_switchToMainViewIsUpdate = YES;
	[self _showCurrentMainView];
}

- (void)_updateStatusLabelForListView
{
	if (_currentMainView != _clientListView && _currentMainView != _emptyClientListView)
		return;
	
	NSString* str = nil;
	switch([connectedClients count]) {
		case 0:
			str = TFLocalizedString(@"NoClientsConnected", @"No clients connected");
			break;
		case 1:
			str = TFLocalizedString(@"OneClientConnected", @"One client connected");
			break;
		default:
			str = [NSString stringWithFormat:TFLocalizedString(@"XClientsConntected", @"%d clients connected"),
												[connectedClients count]];
			break;
	}
	
	if (nil != str && ![str isEqualToString:_statusLabel.string])
		_statusLabel.string = str;
}

- (void)_removeDisconnectedClient:(NSString*)clientName
{
	@synchronized (connectedClients) {
		for (NSDictionary* dict in connectedClients) {
			if ([clientName isEqualToString:[dict objectForKey:kToucheTrackingClientInfoName]]) {
				[[self mutableArrayValueForKey:@"connectedClients"] removeObject:dict];
			}
		}
	}
	
	[self _updateCurrentMainView];
	[self _updateStatusLabelForListView];
}

- (void)_loadPipelineAsync
{
	if (_isLoadingPipelineAsync)
		return;
	
	_isLoadingPipelineAsync = YES;
	
	_appStatus = AppStatusUninitialized;
	[NSThread detachNewThreadSelector:@selector(_loadPipelineAsyncThread)
							 toTarget:self
						   withObject:nil];
}

- (void)_loadPipelineAsyncThread
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSError* error = nil;
	
	if ([_pipeline unloadPipeline:&error])
		error = nil;
	else if (nil == error)
		error = TFUnknownErrorObj;
		
	// give physical devices (such as cameras) some time to shut down
	[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];
		
	if (nil == error) {
		if ([_pipeline loadPipeline:&error])
			error = nil;
		else if (nil == error)
			error = TFUnknownErrorObj;
	}
	
	_isLoadingPipelineAsync = NO;
	
	[self performSelectorOnMainThread:@selector(_pipelineLoadedAsyncWithError:)
						   withObject:error
						waitUntilDone:YES];
	
	[pool release];
}

- (void)_pipelineLoadedAsyncWithError:(NSError*)error
{
	[self _ensurePipelineSetupControllerLoaded];

	// this is ok here since we explicitly nil out error if no error occurred...
	if (nil != error) {
		if (AppStatusPipelineError > _appStatus) {
			_appStatus = AppStatusPipelineError;
		
			TFInfoViewController* c = [[TFInfoViewController alloc] init];
			[c setTitleText:TFLocalizedString(@"PipelineLoadingFailed", @"Error loading pipeline!")];
			[c loadDescriptionFromError:error defaultRecoverySuggestion:TFLocalizedString(@"PipelineLoadingFailureSolution",
																						  @"PipelineLoadingFailureSolution")];
			[c setType:TFInfoViewControllerTypeError];
			[c hideDismissButton];
			[c setActionButtonTitle:TFLocalizedString(@"ReloadPipeline", @"Reload pipeline")
							 action:@selector(_loadPipelineAsync)
							 target:self];
			c.delegate = self;
			
			[self _promoteViewToMainView:[c view]];
		}
		
		if (nil != [error localizedFailureReason])
			[_pipelineSetupController setTrackingInputStatusMessage:[error localizedFailureReason]];
		else if (nil != [error localizedDescription])
			[_pipelineSetupController setTrackingInputStatusMessage:[error localizedFailureReason]];
	}
}

#pragma mark -
#pragma mark Key-Value Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isEqual:[NSUserDefaults standardUserDefaults]]) {
		if ([keyPath isEqualToString:tFUIColorPreferenceKey]) {
			NSColor* color = [NSKeyedUnarchiver unarchiveObjectWithData:[change objectForKey:NSKeyValueChangeNewKey]];
			_statusBar.baseColor = color;
			_statusLabel.fontFillColor = [TFMiscPreferencesController labelColorForBaseColor:color];
		}
	}
}

#pragma mark -
#pragma mark CAAnimation delegate

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
	[_hostView setWantsLayer:NO];
}

#pragma mark -
#pragma mark NSApplication delegate stuff...

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification
{	
	_server = [[TFTrackingServer alloc] init];
	[_server startServer:nil error:NULL];
	_server.delegate = self;
	
	_pipeline = [[TFTrackingPipeline sharedPipeline] retain];
	_pipeline.delegate = self;
	_pipeline.trackingServer = _server;
	
	BOOL isFirstRun = [[NSUserDefaults standardUserDefaults] boolForKey:tFIsFirstRunPreferenceKey];
	
	if (isFirstRun) {
		_appStatus = AppStatusWelcomeScreenRunning;
		[self _promoteViewToMainView:_welcomeView];
	} else {
		[self _loadPipelineAsync];
	}
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication*)sender
{
	[_server stopServer];

	[_pipeline stopProcessing:NULL];
	[_pipeline unloadPipeline:NULL];
	
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:tFIsFirstRunPreferenceKey];
		
	return NSTerminateNow;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)sender
{
    return NO;
}

#pragma mark -
#pragma mark NSWindow delegate

- (NSSize)windowWillResize:(NSWindow *)window toSize:(NSSize)proposedFrameSize
{
	if (_windowCanResize)
		return proposedFrameSize;
	else
		return [[self window] frame].size;
}

- (void)windowWillClose:(NSNotification *)notification
{
	if ([[notification object] isEqual:[self window]]) {
		[[NSApplication sharedApplication] terminate:nil];
	}
}

#pragma mark -
#pragma mark NSTableView delegate

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex
{
	return NO;
}

#pragma mark -
#pragma mark TFTrackingServer delegate

- (void)clientConnectedWithName:(NSString*)clientName andInfoDictionary:(NSDictionary*)infoDict
{
	NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary:infoDict];
	[dict setObject:_server forKey:@"trackingServer"];

	@synchronized (connectedClients) {		
		[[self mutableArrayValueForKey:@"connectedClients"] addObject:[NSDictionary dictionaryWithDictionary:dict]];
	}
	
	[self _updateCurrentMainView];
	[self _updateStatusLabelForListView];
}

- (void)clientDiedWithName:(NSString*)clientName
{
	[self _removeDisconnectedClient:clientName];
}

- (void)clientDisconnectedWithName:(NSString*)clientName
{
	[self _removeDisconnectedClient:clientName];
}

#pragma mark -
#pragma mark Calibration controller delegate

- (void)calibrationCanceledByUser
{
	_pipeline.transformBlobsToScreenCoordinates = YES;
	
	if (!InfoViewIdentifierMatches(_currentMainView, InfoViewIdentifierCalibrationCanceledByUser)) {
		TFInfoViewController* c = [[TFInfoViewController alloc] init];
		[c setTitleText:TFLocalizedString(@"CalibrationCanceled", @"Calibration canceled!")];
		[c setDescriptionText:TFLocalizedString(@"CalibrationCanceledDescription",
												@"CalibrationCanceledDescription")];
		[c setType:TFInfoViewControllerTypeAlert];
		c.previousView = _currentMainView;
		c.identifier = InfoViewIdentifierCalibrationCanceledByUser;
		c.delegate = self;
		
		[self _promoteViewToMainView:[c view]];
	}
	
	_appStatus = AppStatusIsTracking;
}

- (void)calibrationCanceledWithError:(NSError*)error
{
	_pipeline.transformBlobsToScreenCoordinates = YES;
	
	if (!InfoViewIdentifierMatches(_currentMainView, InfoViewIdentifierCalibrationCanceledWithError)) {
		TFInfoViewController* c = [[TFInfoViewController alloc] init];
		[c setTitleText:TFLocalizedString(@"CalibrationCanceledWithError", @"An error occurred during calibration!")];
		[c loadDescriptionFromError:error defaultRecoverySuggestion:TFLocalizedString(@"CalibrationCanceledWithErrorDescription",
																					  @"CalibrationCanceledWithErrorDescription")];
		[c setType:TFInfoViewControllerTypeAlert];
		[c setActionButtonTitle:TFLocalizedString(@"CalibrateAgain", @"Calibrate again")
						 action:@selector(startCalibration:)
						 target:self];
		if (AppStatusCalibrationNeeded != _appStatus && AppStatusCalibrationRecommended != _appStatus)
			c.previousView = _currentMainView;
		c.identifier = InfoViewIdentifierCalibrationCanceledWithError;
		c.delegate = self;
		[self _promoteViewToMainView:[c view]];
	}
	
	_appStatus = AppStatusIsTracking;
}

- (void)didCalibrateWithPoints:(NSArray*)calibrationPoints
{
	NSError* error;
	
	if ([_pipeline calibrateWithPoints:calibrationPoints error:&error]) {
		if (!InfoViewIdentifierMatches(_currentMainView, InfoViewIdentifierCalibrationSuccessful)) {
			TFInfoViewController* c = [[TFInfoViewController alloc] init];
			[c setTitleText:TFLocalizedString(@"CalibrationSuccessful", @"Calibration successful!")];
			[c setDescriptionText:TFLocalizedString(@"CalibrationSuccessfulDescription",
													@"CalibrationSuccessfulDescription")];
			[c setType:TFInfoViewControllerTypeInfo];
			if (AppStatusCalibrationNeeded != _appStatus && AppStatusCalibrationRecommended != _appStatus)
				c.previousView = _currentMainView;
			c.identifier = InfoViewIdentifierCalibrationSuccessful;
			c.delegate = self;
			
			[self _promoteViewToMainView:[c view]];
		}
		
		_appStatus = AppStatusIsTracking;
	} else {
		if (!InfoViewIdentifierMatches(_currentMainView, InfoViewIdentifierCalibrationInvalidData)) {
			TFInfoViewController* c = [[TFInfoViewController alloc] init];
			[c setTitleText:TFLocalizedString(@"CalibrationInvalidData", @"Calibration yielded invalid data!")];
			[c loadDescriptionFromError:error defaultRecoverySuggestion:TFLocalizedString(@"CalibrationInvalidDataDescription",
																						  @"CalibrationInvalidDataDescription")];
			[c setType:TFInfoViewControllerTypeAlert];
			[c setActionButtonTitle:TFLocalizedString(@"CalibrateAgain", @"Calibrate again")
							 action:@selector(startCalibration:)
							 target:self];
			if (AppStatusCalibrationNeeded != _appStatus && AppStatusCalibrationRecommended != _appStatus)
				c.previousView = _currentMainView;
			c.identifier = InfoViewIdentifierCalibrationInvalidData;
			c.delegate = self;
			
			[self _promoteViewToMainView:[c view]];
		}
		
		_appStatus = AppStatusIsTracking;
	}
	
	_pipeline.transformBlobsToScreenCoordinates = YES;
}

#pragma mark -
#pragma mark Touch Test Controller delegate

- (void)touchTestEndedByUser
{
	if (!InfoViewIdentifierMatches(_currentMainView, InfoViewIdentifierTouchTestSuccessful)) {
		TFInfoViewController* c = [[TFInfoViewController alloc] init];
		[c setTitleText:TFLocalizedString(@"TouchTestDone", @"Touch test finished!")];
		[c setDescriptionText:TFLocalizedString(@"TouchTestDoneDescription",
												@"TouchTestDoneDescription")];
		[c setType:TFInfoViewControllerTypeInfo];
		[c setActionButtonTitle:TFLocalizedString(@"TouchTestStartAgainNoError", @"Run test again")
						 action:@selector(startTouchTest:)
						 target:self];
		c.previousView = _currentMainView;
		c.identifier = InfoViewIdentifierTouchTestSuccessful;
		c.delegate = self;
		
		[self _promoteViewToMainView:[c view]];
	}
}

- (void)touchTestFailedWithError:(NSError*)error
{
	if (!InfoViewIdentifierMatches(_currentMainView, InfoViewIdentifierTouchTestError)) {
		TFInfoViewController* c = [[TFInfoViewController alloc] init];
		[c setTitleText:TFLocalizedString(@"TouchTestError", @"Problem loading test app!")];
		[c loadDescriptionFromError:error defaultRecoverySuggestion:TFLocalizedString(@"TouchTestErrorDescription",
																					  @"TouchTestErrorDescription")];
		[c setType:TFInfoViewControllerTypeAlert];
		[c setActionButtonTitle:TFLocalizedString(@"TouchTestStartAgain", @"Try test again")
						 action:@selector(startTouchTest:)
						 target:self];
		c.previousView = _currentMainView;
		c.identifier = InfoViewIdentifierTouchTestError;
		c.delegate = self;
		
		[self _promoteViewToMainView:[c view]];
	}
}

#pragma mark -
#pragma mark TFScreenPreferencesController delegate

- (void)multitouchScreenDidChangeTo:(NSScreen*)screen
{
	if (![_wizardController isRunning])
		[self _loadPipelineAsync];
}

#pragma mark -
#pragma mark Pipeline delegate

- (void)calibrationIsFineForChosenResolution
{
	_appStatus = AppStatusIsTracking;
	
	[self _showCurrentMainView];
}

- (void)calibrationRecommendedForCurrentSettings
{
	_appStatus = AppStatusCalibrationRecommended;
	
	if ([_wizardController isRunning])
		return;
	
	TFInfoViewController* c = [[TFInfoViewController alloc] init];
	[c setTitleText:TFLocalizedString(@"CalibrationRecommended", @"Calibration recommended")];
	[c setDescriptionText:TFLocalizedString(@"CalibrationRecommendedDescription",
											@"CalibrationRecommendedDescription")];
	[c setType:TFInfoViewControllerTypeInfo];
	[c setActionButtonTitle:TFLocalizedString(@"Calibrate", @"Calibrate")
					 action:@selector(startCalibration:)
					 target:self];
	c.clickingActionAlsoDismisses = YES;
	c.delegate = self;
	
	[self _promoteViewToMainView:[c view]];
}

- (void)calibrationNecessaryForCurrentSettingsBecauseOfError:(NSError*)error
{
	_appStatus = AppStatusCalibrationNeeded;
	
	if ([_wizardController isRunning])
		return;
	
	TFInfoViewController* c = [[TFInfoViewController alloc] init];
	[c setTitleText:TFLocalizedString(@"CalibrationNecessary", @"Calibration necessary")];
	[c loadDescriptionFromError:error defaultRecoverySuggestion:TFLocalizedString(@"CalibrationFailedWithErrorSolution",
																				  @"CalibrationFailedWithErrorSolution")];
	[c setType:TFInfoViewControllerTypeAlert];
	[c setActionButtonTitle:TFLocalizedString(@"Calibrate", @"Calibrate")
					 action:@selector(startCalibration:)
					 target:self];
	c.clickingActionAlsoDismisses = YES;
	c.delegate = self;
	
	[self _promoteViewToMainView:[c view]];
}

- (void)pipelineDidLoad
{
	[self _ensurePipelineSetupControllerLoaded];
	[_pipelineSetupController updateAfterPipelineReload];
}

- (void)pipelineDidBecomeReady
{	
	[self _ensurePipelineSetupControllerLoaded];
	[_pipelineSetupController setTrackingInputStatusMessage:@""];
	[_pipelineSetupController updateForNewPipelineSettings];

	NSError* error;
	if (![_pipeline startProcessing:&error] && AppStatusPipelineStartupFailed > _appStatus) {
		_appStatus = AppStatusPipelineStartupFailed;
		
		TFInfoViewController* c = [[TFInfoViewController alloc] init];
		[c setTitleText:TFLocalizedString(@"PipelineStartupFailed", @"Starting the pipeline failed!")];
		[c loadDescriptionFromError:error defaultRecoverySuggestion:TFLocalizedString(@"PipelineStartupFailedSolution",
																					  @"PipelineStartupFailedSolution")];
		[c setType:TFInfoViewControllerTypeError];
		[c hideDismissButton];
		[c setActionButtonTitle:TFLocalizedString(@"ReloadPipeline", @"Reload pipeline")
						 action:@selector(_loadPipelineAsync)
						 target:self];
		c.delegate = self;
		
		[self _promoteViewToMainView:[c view]];
	} else if (AppStatusPipelineReady >= _appStatus || [_wizardController isRunning]) {
		[self _showCurrentMainView];
		
		if (AppStatusCalibrationNeeded != _appStatus && AppStatusCalibrationRecommended != _appStatus)
			_appStatus = AppStatusIsTracking;
	}
}

- (void)pipelineNotReadyWithReason:(NSString*)reason
{
	[self _ensurePipelineSetupControllerLoaded];

	if (AppStatusPipelineNotReady > _appStatus) {
		_appStatus = AppStatusPipelineNotReady;

		TFInfoViewController* c = [[TFInfoViewController alloc] init];
		[c setTitleText:TFLocalizedString(@"TrackingPipelineNotReady", @"Tracking pipeline not ready")];
		[c setDescriptionText:reason];
		[c setType:TFInfoViewControllerTypeAlert];
		[c hideDismissButton];
		[c setActionButtonTitle:TFLocalizedString(@"ConfigurePipeline", @"Configure pipeline")
						 action:@selector(showWindow:)
						 target:_pipelineSetupController];
		c.delegate = self;
		
		[self _promoteViewToMainView:[c view]];
	}
	
	[_pipelineSetupController setTrackingInputStatusMessage:reason];
}

- (void)pipelineWillNotBecomeReadyWithError:(NSError*)error
{
	if (AppStatusPipelineError > _appStatus) {
		_appStatus = AppStatusPipelineError;
	
		TFInfoViewController* c = [[TFInfoViewController alloc] init];
		[c setTitleText:TFLocalizedString(@"PipelineWontBecomeReady", @"Pipeline initialization failed!")];
		[c loadDescriptionFromError:error defaultRecoverySuggestion:TFLocalizedString(@"PipelineWontBecomeReadySolution",
																					  @"PipelineWontBecomeReadySolution")];
		[c setType:TFInfoViewControllerTypeError];
		[c hideDismissButton];
		[c setActionButtonTitle:TFLocalizedString(@"ReloadPipeline", @"Reload pipeline")
						 action:@selector(_loadPipelineAsync)
						 target:self];
		c.delegate = self;
		
		[self _promoteViewToMainView:[c view]];
	}
}

- (void)pipelineDidBecomeUnavailableWithError:(NSError*)error
{
	[self _ensurePipelineSetupControllerLoaded];
	[_pipelineSetupController updateForNewPipelineSettings];
	
	if (AppStatusPipelineIntermittentError > _appStatus) {
		_appStatus = AppStatusPipelineIntermittentError;
		
		TFInfoViewController* c = [[TFInfoViewController alloc] init];
		[c setTitleText:TFLocalizedString(@"TrackingPipelineStalled", @"Tracking pipeline stalled!")];
		[c loadDescriptionFromError:error defaultRecoverySuggestion:TFLocalizedString(@"PipelineStalledSolution",
																					  @"PipelineStalledSolution")];
		[c setType:TFInfoViewControllerTypeAlert];
		[c hideDismissButton];
		[c setActionButtonTitle:TFLocalizedString(@"ConfigurePipeline", @"Configure pipeline")
						 action:@selector(showWindow:)
						 target:_pipelineSetupController];
		c.delegate = self;
		
		[self _promoteViewToMainView:[c view]];
	}
	
	if (nil != [error localizedFailureReason])
		[_pipelineSetupController setTrackingInputStatusMessage:[error localizedFailureReason]];
	else if (nil != [error localizedDescription])
		[_pipelineSetupController setTrackingInputStatusMessage:[error localizedFailureReason]];
}

- (void)pipelineDidBecomeAvailableAgain
{
	[_pipelineSetupController updateForNewPipelineSettings];

	if (AppStatusPipelineIntermittentError == _appStatus) {
		_appStatus = AppStatusIsTracking;
		[self _showCurrentMainView];
		[self _ensurePipelineSetupControllerLoaded];
		[_pipelineSetupController setTrackingInputStatusMessage:@""];
	}
}

- (void)trackingInputMethodDidChangeTo:(NSInteger)methodKey
{
	[self _ensurePipelineSetupControllerLoaded];
	[_pipelineSetupController changeConfigurationViewForInputType:methodKey];
	[_pipelineSetupController setTrackingInputStatusMessage:@""];
	
	[self _loadPipelineAsync];
}

#pragma mark -
#pragma mark TFInfoViewController delegate

- (void)infoViewControllerActionButtonClicked:(TFInfoViewController*)controller
{
}

- (void)infoViewControllerDismissButtonClicked:(TFInfoViewController*)controller
{
	if (nil == controller.previousView) {
		_appStatus = AppStatusUninitialized;
		[self _showCurrentMainView];
	} else {		
		NSView* prevView = controller.previousView;
		if (prevView == _emptyClientListView || prevView == _clientListView)
			[self _showCurrentMainView];
		else
			[self _promoteViewToMainView:prevView];
	}
}

#pragma mark -
#pragma mark TFWizardController delegate

- (void)wizardWillStartStep:(NSInteger)step
{
	[_wizardView setAnimationEnabled:YES];

	switch (step) {
		case TFWizardControllerStepConfigurePipeline:
			[self performSelector:@selector(_loadPipelineAsync)
					   withObject:nil
					   afterDelay:.5f];
			break;
		default:
			break;
	}
}

- (void)wizardWillFinishStep:(NSInteger)step
{
	switch (step) {
		case TFWizardControllerStepFinished:
			[_wizardController startCurrentStepSpinner];
			break;
		default:
			break;
	}
}

- (NSString*)wizardTitleForStep:(NSInteger)step
{
	switch (step) {
		case TFWizardControllerStepSetupFTIRTable:
			return TFLocalizedString(@"TFWizardControllerStepSetupFTIRTableTitle",
									 @"TFWizardControllerStepSetupFTIRTableTitle");
		case TFWizardControllerStepSetupScreen:
			return TFLocalizedString(@"TFWizardControllerStepSetupScreenTitle",
									 @"TFWizardControllerStepSetupScreenTitle");
		case TFWizardControllerStepConnectCamera:
			return TFLocalizedString(@"TFWizardControllerStepConnectCameraTitle",
									 @"TFWizardControllerStepConnectCameraTitle");
		case TFWizardControllerStepSetupCamera:
			return TFLocalizedString(@"TFWizardControllerStepSetupCameraTitle",
									 @"TFWizardControllerStepSetupCameraTitle");
		case TFWizardControllerStepConfigurePipeline:
			return TFLocalizedString(@"TFWizardControllerStepConfigurePipelineTitle",
									 @"TFWizardControllerStepConfigurePipelineTitle");
		case TFWizardControllerStepCalibrate:
			return TFLocalizedString(@"TFWizardControllerStepCalibrateTitle",
									 @"TFWizardControllerStepCalibrateTitle");
		case TFWizardControllerStepTest:
			return TFLocalizedString(@"TFWizardControllerStepTestTitle",
									 @"TFWizardControllerStepTestTitle");
		case TFWizardControllerStepFinished:
			return TFLocalizedString(@"TFWizardControllerStepFinishedTitle",
									 @"TFWizardControllerStepFinishedTitle");
		default:
			return nil;
	}
	
	return nil;
}

- (NSString*)wizardDescriptionForStep:(NSInteger)step
{
	switch (step) {
		case TFWizardControllerStepSetupFTIRTable:
			return TFLocalizedString(@"TFWizardControllerStepSetupFTIRTableDescription",
									 @"TFWizardControllerStepSetupFTIRTableDescription");
		case TFWizardControllerStepSetupScreen:
			return TFLocalizedString(@"TFWizardControllerStepSetupScreenDescription",
									 @"TFWizardControllerStepSetupScreenDescription");
		case TFWizardControllerStepConnectCamera:
			return TFLocalizedString(@"TFWizardControllerStepConnectCameraDescription",
									 @"TFWizardControllerStepConnectCameraDescription");
		case TFWizardControllerStepSetupCamera:
			return TFLocalizedString(@"TFWizardControllerStepSetupCameraDescription",
									 @"TFWizardControllerStepSetupCameraDescription");
		case TFWizardControllerStepConfigurePipeline:
			return TFLocalizedString(@"TFWizardControllerStepConfigurePipelineDescription",
									 @"TFWizardControllerStepConfigurePipelineDescription");
		case TFWizardControllerStepCalibrate:
			return TFLocalizedString(@"TFWizardControllerStepCalibrateDescription",
									 @"TFWizardControllerStepCalibrateDescription");
		case TFWizardControllerStepTest:
			return TFLocalizedString(@"TFWizardControllerStepTestDescription",
									 @"TFWizardControllerStepTestDescription");
		case TFWizardControllerStepFinished:
			return TFLocalizedString(@"TFWizardControllerStepFinishedDescription",
									 @"TFWizardControllerStepFinishedDescription");
		default:
			return nil;
	}
	
	return nil;
}

- (SEL)wizardActionForStep:(NSInteger)step ofTarget:(id*)object withTitle:(NSString**)title
{
	switch (step) {
		case TFWizardControllerStepSetupScreen:
			if (nil == _screenPrefsController)
				_screenPrefsController = [[TFScreenPreferencesController alloc] init];
			*object = _screenPrefsController;
			*title = TFLocalizedString(@"SetUpScreen", @"Set up screen");
			return @selector(showWindow:);
		case TFWizardControllerStepConfigurePipeline:
			[self _ensurePipelineSetupControllerLoaded];
			*object = _pipelineSetupController;
			*title = TFLocalizedString(@"ConfigurePipeline", @"Configure pipeline");
			return @selector(showWindow:);
		case TFWizardControllerStepCalibrate:
			*object = self;
			*title = TFLocalizedString(@"Calibrate", @"Calibrate");
			return @selector(startCalibration:);
		case TFWizardControllerStepTest:
			*object = self;
			*title = TFLocalizedString(@"Start test application", @"Start test application");
			return @selector(startTouchTest:);
		default:
			*object = nil;
			*title = nil;
			return nil;
	}
	
	return nil;
}

- (void)wizardDidFinish
{
	_appStatus = AppStatusUninitialized;
	[self _loadPipelineAsync];
}

@end
