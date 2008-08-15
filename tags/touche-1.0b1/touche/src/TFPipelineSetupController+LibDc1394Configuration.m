//
//  TFPipelineSetupController+LibDc1394Configuration.m
//  Touché
//
//  Created by Georg Kaindl on 16/5/08.
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

#import "TFPipelineSetupController+LibDc1394Configuration.h"

#import "TFIncludes.h"
#import "TFLibDC1394Capture.h"
#import "TFTrackingPipeline.h"
#import "TFTrackingPipeline+LibDc1394InputAdditions.h"

static BOOL tFPipelineSetupControllerLibDc1394DefaultsRegistered = NO;

NSString* tFPipelineSetupControllerLibDc1394FocusPrefKey = @"tFPipelineSetupControllerLibDc1394FocusPrefKey";
NSString* tFPipelineSetupControllerLibDc1394ShutterPrefKey = @"tFPipelineSetupControllerLibDc1394ShutterPrefKey";
NSString* tFPipelineSetupControllerLibDc1394GainPrefKey = @"tFPipelineSetupControllerLibDc1394GainPrefKey";
NSString* tFPipelineSetupControllerLibDc1394BrightnessPrefKey = @"tFPipelineSetupControllerLibDc1394BrightnessPrefKey";
NSString* tFPipelineSetupControllerLibDc1394ExposurePrefKey = @"tFPipelineSetupControllerLibDc1394ExposurePrefKey";
NSString* tFPipelineSetupControllerLibDc1394FocusAutoPrefKey = @"tFPipelineSetupControllerLibDc1394FocusAutoPrefKey";
NSString* tFPipelineSetupControllerLibDc1394ShutterAutoPrefKey = @"tFPipelineSetupControllerLibDc1394ShutterAutoPrefKey";
NSString* tFPipelineSetupControllerLibDc1394GainAutoPrefKey = @"tFPipelineSetupControllerLibDc1394GainAutoPrefKey";
NSString* tFPipelineSetupControllerLibDc1394BrightnessAutoPrefKey = @"tFPipelineSetupControllerLibDc1394BrightnessAutoPrefKey";
NSString* tFPipelineSetupControllerLibDc1394ExposureAutoPrefKey = @"tFPipelineSetupControllerLibDc1394ExposureAutoPrefKey";

@implementation TFPipelineSetupController (LibDc1394Configuration)

- (void)_updateConfigForNewLibDc1394Camera
{
	NSUserDefaults* standardDefaults = [NSUserDefaults standardUserDefaults];
	TFTrackingPipeline* pipeline = [TFTrackingPipeline sharedPipeline];

	if (!tFPipelineSetupControllerLibDc1394DefaultsRegistered) {
		NSDictionary* defaultValues = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithFloat:[pipeline valueForLibDc1394Feature:TFLibDC1394CaptureFeatureFocus]],
										tFPipelineSetupControllerLibDc1394FocusPrefKey,
										[NSNumber numberWithFloat:[pipeline valueForLibDc1394Feature:TFLibDC1394CaptureFeatureShutter]],
										tFPipelineSetupControllerLibDc1394ShutterPrefKey,
									    [NSNumber numberWithFloat:[pipeline valueForLibDc1394Feature:TFLibDC1394CaptureFeatureGain]],
										tFPipelineSetupControllerLibDc1394GainPrefKey,
									    [NSNumber numberWithFloat:[pipeline valueForLibDc1394Feature:TFLibDC1394CaptureFeatureBrightness]],
										tFPipelineSetupControllerLibDc1394BrightnessPrefKey,
									    [NSNumber numberWithFloat:[pipeline valueForLibDc1394Feature:TFLibDC1394CaptureFeatureExposure]],
									    tFPipelineSetupControllerLibDc1394ExposurePrefKey,
										[NSNumber numberWithBool:[pipeline libDc1394FeatureInAutoMode:TFLibDC1394CaptureFeatureFocus]],
										tFPipelineSetupControllerLibDc1394FocusAutoPrefKey,
									    [NSNumber numberWithBool:[pipeline libDc1394FeatureInAutoMode:TFLibDC1394CaptureFeatureShutter]],
									    tFPipelineSetupControllerLibDc1394ShutterAutoPrefKey,
									    [NSNumber numberWithBool:[pipeline libDc1394FeatureInAutoMode:TFLibDC1394CaptureFeatureGain]],
									    tFPipelineSetupControllerLibDc1394GainAutoPrefKey,
									    [NSNumber numberWithBool:[pipeline libDc1394FeatureInAutoMode:TFLibDC1394CaptureFeatureBrightness]],
									    tFPipelineSetupControllerLibDc1394BrightnessAutoPrefKey,
									    [NSNumber numberWithBool:[pipeline libDc1394FeatureInAutoMode:TFLibDC1394CaptureFeatureExposure]],
									    tFPipelineSetupControllerLibDc1394ExposureAutoPrefKey,
										nil];
		
		[standardDefaults registerDefaults:defaultValues];
		
		tFPipelineSetupControllerLibDc1394DefaultsRegistered = YES;
	}
	
	float focusVal = [[standardDefaults objectForKey:tFPipelineSetupControllerLibDc1394FocusPrefKey] floatValue];
	float shutterVal = [[standardDefaults objectForKey:tFPipelineSetupControllerLibDc1394ShutterPrefKey] floatValue];
	float gainVal = [[standardDefaults objectForKey:tFPipelineSetupControllerLibDc1394GainPrefKey] floatValue];
	float brightnessVal = [[standardDefaults objectForKey:tFPipelineSetupControllerLibDc1394BrightnessPrefKey] floatValue];
	float exposureVal = [[standardDefaults objectForKey:tFPipelineSetupControllerLibDc1394ExposurePrefKey] floatValue];

	BOOL focusInAuto = [[standardDefaults objectForKey:tFPipelineSetupControllerLibDc1394FocusAutoPrefKey] boolValue];
	BOOL shutterInAuto = [[standardDefaults objectForKey:tFPipelineSetupControllerLibDc1394ShutterAutoPrefKey] boolValue];
	BOOL gainInAuto = [[standardDefaults objectForKey:tFPipelineSetupControllerLibDc1394GainAutoPrefKey] boolValue];
	BOOL brightnessInAuto = [[standardDefaults objectForKey:tFPipelineSetupControllerLibDc1394BrightnessAutoPrefKey] boolValue];
	BOOL exposureInAuto = [[standardDefaults objectForKey:tFPipelineSetupControllerLibDc1394ExposureAutoPrefKey] boolValue];
	
	
	if ([pipeline libDc1394FeatureIsMutable:TFLibDC1394CaptureFeatureFocus]) {
		[pipeline setLibDc1394Feature:TFLibDC1394CaptureFeatureFocus
							  toValue:focusVal];
		[libDc1394FocusSlider setEnabled:YES];
		[libDc1394FocusAutoBox setEnabled:YES];
		[libDc1394FocusSlider setFloatValue:focusVal];
	} else {
		[libDc1394FocusSlider setEnabled:NO];
		[libDc1394FocusAutoBox setEnabled:NO];
	}
	
	if ([pipeline libDc1394FeatureIsMutable:TFLibDC1394CaptureFeatureShutter]) {
		[pipeline setLibDc1394Feature:TFLibDC1394CaptureFeatureShutter
							  toValue:shutterVal];
		[libDc1394ShutterSlider setEnabled:YES];
		[libDc1394ShutterAutoBox setEnabled:YES];
		[libDc1394ShutterSlider setFloatValue:shutterVal];
	} else {
		[libDc1394ShutterSlider setEnabled:NO];
		[libDc1394ShutterAutoBox setEnabled:NO];
	}
						  					  
	if ([pipeline libDc1394FeatureIsMutable:TFLibDC1394CaptureFeatureGain]) {
		[pipeline setLibDc1394Feature:TFLibDC1394CaptureFeatureGain
							  toValue:gainVal];
		[libDc1394GainSlider setEnabled:YES];
		[libDc1394GainAutoBox setEnabled:YES];
		[libDc1394GainSlider setFloatValue:gainVal];
	} else {
		[libDc1394GainSlider setEnabled:NO];
		[libDc1394GainAutoBox setEnabled:NO];
	}
	
	if ([pipeline libDc1394FeatureIsMutable:TFLibDC1394CaptureFeatureBrightness]) {
		[pipeline setLibDc1394Feature:TFLibDC1394CaptureFeatureBrightness
							  toValue:brightnessVal];
		[libDc1394BrightnessSlider setEnabled:YES];
		[libDc1394BrightnessAutoBox setEnabled:YES];
		[libDc1394BrightnessSlider setFloatValue:brightnessVal];
	} else {
		[libDc1394BrightnessSlider setEnabled:NO];
		[libDc1394BrightnessAutoBox setEnabled:NO];
	}
	
	if ([pipeline libDc1394FeatureIsMutable:TFLibDC1394CaptureFeatureExposure]) {
		[pipeline setLibDc1394Feature:TFLibDC1394CaptureFeatureExposure
							  toValue:brightnessVal];
		[libDc1394ExposureSlider setEnabled:YES];
		[libDc1394ExposureAutoBox setEnabled:YES];
		[libDc1394ExposureSlider setFloatValue:exposureVal];
	} else {
		[libDc1394ExposureSlider setEnabled:NO];
		[libDc1394ExposureAutoBox setEnabled:NO];
	}
	
	[libDc1394FocusAutoBox setEnabled:([pipeline libdc1394FeatureSupportsAutoMode:TFLibDC1394CaptureFeatureFocus] &&
									   [pipeline libDc1394FeatureIsMutable:TFLibDC1394CaptureFeatureFocus])];
	if (focusInAuto && [pipeline libdc1394FeatureSupportsAutoMode:TFLibDC1394CaptureFeatureFocus]) {
		[pipeline setLibDc1394Feature:TFLibDC1394CaptureFeatureFocus toAutoMode:YES];
		[libDc1394FocusAutoBox setState:YES];
		[libDc1394FocusSlider setEnabled:NO];
	} else
		[libDc1394FocusAutoBox setState:NO];
	
	[libDc1394ShutterAutoBox setEnabled:([pipeline libdc1394FeatureSupportsAutoMode:TFLibDC1394CaptureFeatureShutter] &&
										 [pipeline libDc1394FeatureIsMutable:TFLibDC1394CaptureFeatureShutter])];
	if (shutterInAuto && [pipeline libdc1394FeatureSupportsAutoMode:TFLibDC1394CaptureFeatureShutter]) {
		[pipeline setLibDc1394Feature:TFLibDC1394CaptureFeatureShutter toAutoMode:YES];
		[libDc1394ShutterAutoBox setState:YES];
		[libDc1394ShutterSlider setEnabled:NO];
	} else
		[libDc1394ShutterAutoBox setState:NO];
	
	[libDc1394GainAutoBox setEnabled:([pipeline libdc1394FeatureSupportsAutoMode:TFLibDC1394CaptureFeatureGain] &&
									  [pipeline libDc1394FeatureIsMutable:TFLibDC1394CaptureFeatureGain])];
	if (gainInAuto && [pipeline libdc1394FeatureSupportsAutoMode:TFLibDC1394CaptureFeatureGain]) {
		[pipeline setLibDc1394Feature:TFLibDC1394CaptureFeatureGain toAutoMode:YES];
		[libDc1394GainAutoBox setState:YES];
		[libDc1394GainSlider setEnabled:NO];
	} else
		[libDc1394GainAutoBox setState:NO];
	
	[libDc1394BrightnessAutoBox setEnabled:([pipeline libdc1394FeatureSupportsAutoMode:TFLibDC1394CaptureFeatureBrightness] &&
											[pipeline libDc1394FeatureIsMutable:TFLibDC1394CaptureFeatureBrightness])];
	if (brightnessInAuto && [pipeline libdc1394FeatureSupportsAutoMode:TFLibDC1394CaptureFeatureBrightness]) {
		[pipeline setLibDc1394Feature:TFLibDC1394CaptureFeatureBrightness toAutoMode:YES];
		[libDc1394BrightnessAutoBox setState:YES];
		[libDc1394BrightnessSlider setEnabled:NO];
	} else
		[libDc1394BrightnessAutoBox setState:NO];
	
	[libDc1394ExposureAutoBox setEnabled:([pipeline libdc1394FeatureSupportsAutoMode:TFLibDC1394CaptureFeatureExposure] &&
										  [pipeline libDc1394FeatureIsMutable:TFLibDC1394CaptureFeatureExposure])];
	if (exposureInAuto && [pipeline libdc1394FeatureSupportsAutoMode:TFLibDC1394CaptureFeatureExposure]) {
		[pipeline setLibDc1394Feature:TFLibDC1394CaptureFeatureExposure toAutoMode:YES];
		[libDc1394ExposureAutoBox setState:YES];
		[libDc1394ExposureSlider setEnabled:NO];
	} else
		[libDc1394ExposureAutoBox setState:NO];
}

- (IBAction)libdc1394SliderChanged:(id)sender
{
	NSUserDefaults* sd = [NSUserDefaults standardUserDefaults];
	NSInteger feature;
	NSString* key = nil;
	
	if (libDc1394FocusSlider == sender) {
		feature = TFLibDC1394CaptureFeatureFocus;
		key = tFPipelineSetupControllerLibDc1394FocusPrefKey;
	} else if (libDc1394ShutterSlider == sender) {
		feature = TFLibDC1394CaptureFeatureShutter;
		key = tFPipelineSetupControllerLibDc1394ShutterPrefKey;
	} else if (libDc1394GainSlider == sender) {
		feature = TFLibDC1394CaptureFeatureGain;
		key = tFPipelineSetupControllerLibDc1394GainPrefKey;
	} else if (libDc1394BrightnessSlider == sender) {
		feature = TFLibDC1394CaptureFeatureBrightness;
		key = tFPipelineSetupControllerLibDc1394BrightnessPrefKey;
	} else if (libDc1394ExposureSlider == sender) {
		feature = TFLibDC1394CaptureFeatureExposure;
		key = tFPipelineSetupControllerLibDc1394ExposurePrefKey;
	}
	
	if (nil != key) {
		[sd setObject:[NSNumber numberWithFloat:[sender floatValue]] forKey:key];
		[[TFTrackingPipeline sharedPipeline] setLibDc1394Feature:feature
														 toValue:[sender floatValue]];
	}
}

- (IBAction)libdc1394CheckboxChanged:(id)sender
{
	NSUserDefaults* sd = [NSUserDefaults standardUserDefaults];
	NSInteger feature;
	NSString* key = nil;
	NSSlider* slider = nil;
	TFTrackingPipeline* pipeline = [TFTrackingPipeline sharedPipeline];
	
	if (libDc1394FocusAutoBox == sender) {
		feature = TFLibDC1394CaptureFeatureFocus;
		key = tFPipelineSetupControllerLibDc1394FocusAutoPrefKey;
		slider = libDc1394FocusSlider;
	} else if (libDc1394ShutterAutoBox == sender) {
		feature = TFLibDC1394CaptureFeatureShutter;
		key = tFPipelineSetupControllerLibDc1394ShutterAutoPrefKey;
		slider = libDc1394ShutterSlider;
	} else if (libDc1394GainAutoBox == sender) {
		feature = TFLibDC1394CaptureFeatureGain;
		key = tFPipelineSetupControllerLibDc1394GainAutoPrefKey;
		slider = libDc1394GainSlider;
	} else if (libDc1394BrightnessAutoBox == sender) {
		feature = TFLibDC1394CaptureFeatureBrightness;
		key = tFPipelineSetupControllerLibDc1394BrightnessAutoPrefKey;
		slider = libDc1394BrightnessSlider;
	} else if (libDc1394ExposureAutoBox == sender) {
		feature = TFLibDC1394CaptureFeatureExposure;
		key = tFPipelineSetupControllerLibDc1394ExposureAutoPrefKey;
		slider = libDc1394ExposureSlider;
	}
	
	if (nil != key) {
		[slider setEnabled:![sender state]];
		[sd setObject:[NSNumber numberWithBool:[sender state]] forKey:key];
		if ([sender state])
			[pipeline setLibDc1394Feature:feature
							   toAutoMode:YES];
		else if ([pipeline libDc1394FeatureIsMutable:feature]) {
			[pipeline setLibDc1394Feature:feature
							   toAutoMode:NO];
		
			[self performSelector:@selector(libdc1394SliderChanged:)
					   withObject:slider
					   afterDelay:.25];
		}
	}
}

@end
