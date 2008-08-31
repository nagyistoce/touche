//
//  TFPipelineSetupController.m
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

#import "TFPipelineSetupController.h"
#import "TFPipelineSetupController+LibDc1394Configuration.h"

#import "TFIncludes.h"
#import "TFTrackingPipeline.h"
#import "TFTrackingPipeline+QTInputAdditions.h"
#import "TFTrackingPipeline+LibDc1394InputAdditions.h"
#import "TFBlobTrackingView.h"
#import "TFQTKitCapture.h"
#import "TFLibDC1394Capture.h"

@interface TFPipelineSetupController (NonPublicMethods)
- (void)_populatePopup:(NSPopUpButton*)popup fromDictionary:(NSDictionary*)dict withSelectedRepresentedObject:(id)obj;
- (void)_populateLibDc1394DevicePopup;
- (void)_populateQTDevicePopup;
- (void)_updateResolutionPopup:(NSPopUpButton*)popup;
- (void)_setDefaults;
- (void)_setDisplayLinkForWindow:(NSWindow*)window;
- (void)_setConfigurationViews:(NSArray*)views forInputKey:(NSInteger)inputKey;
- (void)_setConfigurationViewAnimate:(NSView*)newView;
- (void)_libdc1394CameraDidChange:(NSNotification*)notification;
@end

@implementation TFPipelineSetupController

- (id)init
{
	if (!(self = [super initWithWindowNibName:@"PipelineSetup"])) {
		[self release];
		return nil;
	}
	
	[self loadWindow];
	[self _setDefaults];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(_libdc1394CameraDidChange:)
												 name:TFLibDc1394CameraDidChangeNotification
											   object:nil];
	
	return self;
}

- (void)dealloc
{
	[_viewHeights release];
	_viewHeights = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

- (void)_setDefaults
{
	self.window.delegate = self;
	previewWindow.delegate = self;
	
	NSRect previewFrame = [previewWindow frame];
	NSRect previewVideoFrame = [[previewWindow contentView] frame];
	_previewWindowBordersAroundVideoView = NSMakeSize(previewFrame.size.width-previewVideoFrame.size.width, 
													  previewFrame.size.height-previewVideoFrame.size.height);
	if (previewVideoFrame.size.height-_previewWindowBordersAroundVideoView.height != 0.0f)
		_previewWindowVideoAspectRatio =
					(previewVideoFrame.size.width-_previewWindowBordersAroundVideoView.width) /
					(previewVideoFrame.size.height-_previewWindowBordersAroundVideoView.height);
	
	if (nil == _viewHeights)
		_viewHeights = [[NSMutableDictionary alloc] init];
	
	_emptyConfigurationWindowSize = [[self window] frame].size;
	
	[self changeConfigurationViewForInputType:[TFTrackingPipeline sharedPipeline].inputMethod];
	
	CATransition* transition = [CATransition animation];
	transition.type = kCATransitionFade;
	transition.subtype = kCATransitionFromRight;
	transition.duration = .3f;
	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
	transition.delegate = self;
	
	[_configurationBox setAnimations:[NSDictionary dictionaryWithObject:transition forKey:@"subviews"]];
}

- (void)_populatePopup:(NSPopUpButton*)popup fromDictionary:(NSDictionary*)dict withSelectedRepresentedObject:(id)obj
{
	NSMenu* menu = [popup menu];
	
	for (NSMenuItem* item in [menu itemArray])
		[menu removeItem:item];
	
	for (NSString* uniqueObj in dict) {
		NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:[dict objectForKey:uniqueObj]
													  action:NULL
											   keyEquivalent:[NSString string]];
		[item setRepresentedObject:uniqueObj];
		[menu addItem:item];
		
		if ([obj isEqualTo:uniqueObj])
			[popup selectItem:item];
		
		[item release];
	}
}

- (void)_populateQTDevicePopup
{
	NSDictionary* devices = [TFQTKitCapture connectedDevicesNamesAndIds];
	NSString* defaultUUID = [[TFTrackingPipeline sharedPipeline] currentPreferencesQTDeviceUUID];
	[self _populatePopup:qtDevicePopup fromDictionary:devices withSelectedRepresentedObject:defaultUUID];
}

- (void)_populateLibDc1394DevicePopup
{
	NSDictionary* cameras = [TFLibDC1394Capture connectedCameraNamesAndUniqueIds];
	NSNumber* defaultUUID = [[TFTrackingPipeline sharedPipeline] currentPreferencesLibDc1394CameraUUID];
	[self _populatePopup:libdc1394DevicePopup fromDictionary:cameras withSelectedRepresentedObject:defaultUUID];
}

- (IBAction)showPreviewWindow:(id)sender
{
	[previewWindow makeKeyAndOrderFront:sender];
		
	largeTrackingView.delegate = [TFTrackingPipeline sharedPipeline];
	[largeTrackingView startDisplayLink];
	[self _setDisplayLinkForWindow:previewWindow];
}

- (IBAction)showWindow:(id)sender
{	
	[super showWindow:sender];
	
	smallTrackingView.delegate = [TFTrackingPipeline sharedPipeline];
	[smallTrackingView startDisplayLink];
	[self _setDisplayLinkForWindow:[self window]];
}

- (void)setTrackingInputStatusMessage:(NSString*)status
{
	if (nil != status) {
		[_statusLabel performSelectorOnMainThread:@selector(setStringValue:)
									   withObject:status
									waitUntilDone:NO];
	}
}

- (void)changeConfigurationViewForInputType:(NSInteger)inputType
{
	NSArray* views = nil;
	switch (inputType) {
		case TFTrackingPipelineInputMethodQuickTimeKitCamera:
			views = [NSArray arrayWithObjects:_qtKitConfigurationView,
												_filterConfigurationView,
												_simpleDistanceLabelizerConfigurationView,
												_invertedTextureMappingCam2ScreenConfigurationView,
												nil];
			break;
		case TFTrackingPipelineInputMethodWiiRemote:
			views = [NSArray arrayWithObjects:_wiiRemoteConfigurationView,
												_simpleDistanceLabelizerConfigurationView,
												_invertedTextureMappingCam2ScreenConfigurationView,
												nil];
			break;
		case TFTrackingPipelineInputMethodLibDc1394Camera:
			views = [NSArray arrayWithObjects:_libdc1394ConfigurationView,
					 _filterConfigurationView,
					 _simpleDistanceLabelizerConfigurationView,
					 _invertedTextureMappingCam2ScreenConfigurationView,
					 nil];
			break;
		default:
			views = nil;
			break;
	}
		
	if (nil != views)
		[self _setConfigurationViews:views forInputKey:inputType];
}

- (void)updateForNewPipelineSettings
{
	TFTrackingPipeline* pipeline = [TFTrackingPipeline sharedPipeline];
	
	switch (pipeline.inputMethod) {
		case TFTrackingPipelineInputMethodLibDc1394Camera:
			[self _populateLibDc1394DevicePopup];
			[self _updateResolutionPopup:libdc1394ResolutionPopup];
			[self _updateConfigForNewLibDc1394Camera];
			break;
		case TFTrackingPipelineInputMethodQuickTimeKitCamera:
			[self _populateQTDevicePopup];
			[self _updateResolutionPopup:qtResolutionPopup];
			break;
		default:
			break;
	}
}

- (void)updateAfterPipelineReload
{
	BOOL supportsFilters = [[TFTrackingPipeline sharedPipeline]	currentInputMethodSupportsFilterStages];
	
	[_smallPreviewFilterStageSelection setEnabled:supportsFilters];
	[_largePreviewFilterStageSelection setEnabled:supportsFilters];
}

- (void)_updateResolutionPopup:(NSPopUpButton*)popup
{
	TFTrackingPipeline* pipeline = [TFTrackingPipeline sharedPipeline];
	NSMenu* menu = [popup menu];
	
	[menu setAutoenablesItems:NO];
	
	for (NSMenuItem* item in [menu itemArray]) {
		if ([pipeline currentSettingsSupportCaptureResolutionWithKey:[item tag]])
			[item setEnabled:YES];
		else
			[item setEnabled:NO];
	}
}

- (void)_setDisplayLinkForWindow:(NSWindow*)window
{
	NSInteger displayID = [[[[window screen] deviceDescription] objectForKey:@"NSScreenNumber"] intValue];
		
	if ([window isEqual:[self window]])
		[smallTrackingView setCurrentDisplay:displayID];
	else if ([window isEqual:previewWindow])
		[largeTrackingView setCurrentDisplay:displayID];
}

- (void)_setConfigurationViews:(NSArray*)views forInputKey:(NSInteger)inputKey
{	
	NSNumber* heightNum = [_viewHeights objectForKey:[NSNumber numberWithInteger:inputKey]];
	float height = 0.0f;
	
	if (nil == heightNum) {
		for (NSView* view in views)
			height += [view frame].size.height;
		
		[_viewHeights setObject:[NSNumber numberWithFloat:height] forKey:[NSNumber numberWithInteger:inputKey]];
	} else
		height = [heightNum floatValue];

	NSView* newView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, _emptyConfigurationWindowSize.width, height)];
	[newView setAutoresizesSubviews:NO];
	
	NSArray* subviews = [_configurationBox subviews];
	if ([subviews count] > 0)
		[(NSView*)[subviews objectAtIndex:0] removeFromSuperview];
	
	float curPos = 0.0f;
	NSView* view;
	NSEnumerator* e = [views reverseObjectEnumerator];
	while (nil != (view = [e nextObject])) {
		[newView addSubview:view];
		[view setFrameOrigin:NSMakePoint(0.0f, curPos)];
		curPos += [view frame].size.height;
	}
	
	NSSize newSize = NSMakeSize(_emptyConfigurationWindowSize.width, _emptyConfigurationWindowSize.height + height);
    NSRect oldFrame = [[self window] frame];
	
	int newY = oldFrame.origin.y + oldFrame.size.height - newSize.height;
	[[self window] setFrame:NSMakeRect(oldFrame.origin.x, newY, newSize.width, newSize.height)
					display:YES
					animate:YES];
	/* [[[self window] animator] setFrame:NSMakeRect(oldFrame.origin.x, newY, newSize.width, newSize.height)
							   display:YES]; */
	
	if ([[self window] isVisible]) {
		[_configurationBox setWantsLayer:YES];
		[self performSelector:@selector(_setConfigurationViewAnimate:) withObject:newView afterDelay:0.01f];
	} else {
		[_configurationBox addSubview:newView];
	}
	
	[newView release];
}

- (void)_setConfigurationViewAnimate:(NSView*)newView
{
	if (![_configurationBox wantsLayer])
		[self performSelector:@selector(_setConfigurationViewAnimate:) withObject:newView afterDelay:0.01f];

	[[_configurationBox animator] addSubview:newView];
}

- (void)_libdc1394CameraDidChange:(NSNotification*)notification
{
	[self updateForNewPipelineSettings];
}

#pragma mark -
#pragma mark CAAnimation delegate

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
	[_configurationBox setWantsLayer:NO];
}

#pragma mark -
#pragma mark NSWindow delegate

- (void)windowWillClose:(NSNotification *)notification
{
	if ([[notification object] isEqual:[self window]]) {
		[smallTrackingView stopDisplayLink];
		smallTrackingView.delegate = nil;
	} else if ([[notification object] isEqual:previewWindow]) {
		[largeTrackingView stopDisplayLink];
		largeTrackingView.delegate = nil;
	}
}

- (void)_windowDidChangeScreen:(NSNotification*)notification
{
	[self _setDisplayLinkForWindow:[notification object]];
}

- (NSSize)windowWillResize:(NSWindow*)sender toSize:(NSSize)frameSize
{
	if ([sender isEqual:previewWindow]) {
		// maintain aspect ratio of window frame, so that the aspect ratio of the video input is
		// also retained
		frameSize.width -= _previewWindowBordersAroundVideoView.width;	
		frameSize.height = frameSize.width/_previewWindowVideoAspectRatio;
		frameSize.width += _previewWindowBordersAroundVideoView.width;
		frameSize.height += 19.0f + _previewWindowBordersAroundVideoView.height;
	}
	
	return frameSize;
}

@end
