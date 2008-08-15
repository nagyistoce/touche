//
//  TFPipelineSetupController.h
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

#import <Cocoa/Cocoa.h>

@class TFBlobTrackingView;

@interface TFPipelineSetupController : NSWindowController {
	IBOutlet NSView*				_configurationBox;
	IBOutlet TFBlobTrackingView*	smallTrackingView;
	
	IBOutlet NSTextField*			_statusLabel;
	IBOutlet NSPanel*				previewWindow;
	IBOutlet TFBlobTrackingView*	largeTrackingView;
	
	IBOutlet NSPopUpButton*			_smallPreviewFilterStageSelection;
	IBOutlet NSPopUpButton*			_largePreviewFilterStageSelection;
	
	IBOutlet NSView*				_qtKitConfigurationView;
	IBOutlet NSView*				_libdc1394ConfigurationView;
	IBOutlet NSView*				_filterConfigurationView;
	IBOutlet NSView*				_wiiRemoteConfigurationView;
	IBOutlet NSView*				_simpleDistanceLabelizerConfigurationView;
	IBOutlet NSView*				_invertedTextureMappingCam2ScreenConfigurationView;
	
	IBOutlet NSPopUpButton*			qtDevicePopup;
	IBOutlet NSPopUpButton*			libdc1394DevicePopup;
	
	IBOutlet NSPopUpButton*			qtResolutionPopup;
	IBOutlet NSPopUpButton*			libdc1394ResolutionPopup;
	
	IBOutlet NSSlider*				libDc1394FocusSlider;
	IBOutlet NSSlider*				libDc1394ShutterSlider;
	IBOutlet NSSlider*				libDc1394GainSlider;
	IBOutlet NSSlider*				libDc1394BrightnessSlider;
	IBOutlet NSSlider*				libDc1394ExposureSlider;
	
	IBOutlet NSButton*				libDc1394FocusAutoBox;
	IBOutlet NSButton*				libDc1394ShutterAutoBox;
	IBOutlet NSButton*				libDc1394GainAutoBox;
	IBOutlet NSButton*				libDc1394BrightnessAutoBox;
	IBOutlet NSButton*				libDc1394ExposureAutoBox;

	CGFloat							_previewWindowVideoAspectRatio;
	NSSize							_previewWindowBordersAroundVideoView;
	NSSize							_emptyConfigurationWindowSize;
	NSMutableDictionary*			_viewHeights;	
}

- (IBAction)showPreviewWindow:(id)sender;
- (void)changeConfigurationViewForInputType:(NSInteger)inputType;
- (void)setTrackingInputStatusMessage:(NSString*)status;
- (void)updateAfterPipelineReload;
- (void)updateForNewPipelineSettings;

@end
