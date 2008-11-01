//
//  TFScreenPreferencesController.m
//  Touché
//
//  Created by Georg Kaindl on 17/5/08.
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

#import "TFScreenPreferencesController.h"

#import "TFIncludes.h"
#import "NSScreen+Extras.h"
#import "TFScreenPrefsMeasureView.h"

#define DEFAULT_MEASURE_WIDTH_IN_CENTIMETERS	((CGFloat)9.1f)		// both from my macbook air
#define DEFAULT_MEASURE_WIDTH_IN_PIXELS			((CGFloat)410.0f)

static NSString* tFScreenPreferencesControllerOutputScreenPrefKey = @"tFScreenPreferencesControllerOutputScreenPrefKey";
static NSString* tFScreenPreferencesControllerOutputScreenResolutionPrefKey = @"tFScreenPreferencesControllerOutputScreenResolutionPrefKey";

static CGFloat tFScreenPreferencesControllerMeasureInPixels = DEFAULT_MEASURE_WIDTH_IN_PIXELS;

@interface TFScreenPreferencesController (NonPublicMethods)
- (void)_populateScreenPopup;
@end

@implementation TFScreenPreferencesController

@synthesize delegate;

- (void)dealloc
{
	[[NSUserDefaults standardUserDefaults] removeObserver:self
											   forKeyPath:tFScreenPreferencesControllerOutputScreenPrefKey];
	
	[super dealloc];
}

+ (void)initialize
{
	NSDictionary *defaultPrefs = [NSDictionary dictionaryWithObjectsAndKeys:
								  [NSNumber numberWithInteger:[[NSScreen mainScreen] directDisplayID]],
								  tFScreenPreferencesControllerOutputScreenPrefKey,
								  [NSNumber numberWithFloat:DEFAULT_MEASURE_WIDTH_IN_CENTIMETERS],
								  tFScreenPreferencesControllerOutputScreenResolutionPrefKey,
								  nil];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultPrefs];
}

- (id)init
{
	if (!(self = [super initWithWindowNibName:@"ScreenPreferences"])) {
		[self release];
		return nil;
	}
	
	[self loadWindow];
	tFScreenPreferencesControllerMeasureInPixels = [measureView currentWidth];
	measureView.thickness = 6.0f;
	measureView.color = [NSColor colorWithCalibratedWhite:0.6f alpha:1.0f];
	[self measureSliderChanged:screenResolutionSlider];
	
	[[NSUserDefaults standardUserDefaults] addObserver:self
											forKeyPath:tFScreenPreferencesControllerOutputScreenPrefKey
											   options:NSKeyValueObservingOptionNew
											   context:NULL];
	
	return self;
}

- (void)showWindow:(id)sender
{
	[self _populateScreenPopup];
	
	[super showWindow:sender];
}

+ (NSScreen*)screen
{
	NSNumber* displayID = [[NSUserDefaults standardUserDefaults] objectForKey:tFScreenPreferencesControllerOutputScreenPrefKey];
	NSScreen* screen = [NSScreen screenWithDisplayID:[displayID integerValue]];
	
	if (nil == screen)
		screen = [NSScreen mainScreen];
	
	return screen;
}

+ (CGFloat)screenPixelsPerCentimeter
{
	CGFloat measureCentimeters = [[[NSUserDefaults standardUserDefaults] objectForKey:tFScreenPreferencesControllerOutputScreenResolutionPrefKey] floatValue];

	return (tFScreenPreferencesControllerMeasureInPixels/measureCentimeters);
}

+ (CGFloat)screenPixelsPerInch
{
	CGFloat perCentimeter = [[self class] screenPixelsPerCentimeter];
	
	return perCentimeter/0.393700787f;
}

- (IBAction)measureSliderChanged:(id)sender
{
	CGFloat centimeters = [sender floatValue];
	NSString* sizeLabel = [NSString stringWithFormat:TFLocalizedString(@"PixelsMeasureLabel", @"%1$.2f cm (%2$.1f pixels/cm) — %3$.4f inch (%4$.1f pixels/inch)"),
						   centimeters, [[self class] screenPixelsPerCentimeter],
						   centimeters*0.393700787f, [[self class] screenPixelsPerInch]];
	[measureField setStringValue:sizeLabel];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([object isEqual:[NSUserDefaults standardUserDefaults]] && [keyPath isEqualToString:tFScreenPreferencesControllerOutputScreenPrefKey]) {
		if ([delegate respondsToSelector:@selector(multitouchScreenDidChangeTo:)])
			[delegate multitouchScreenDidChangeTo:[NSScreen screenWithDisplayID:[[change objectForKey:NSKeyValueChangeNewKey] integerValue]]];
	}
}

- (void)_populateScreenPopup
{
	NSMenu* menu = [screenPopup menu];
	
	for (NSMenuItem* item in [menu itemArray])
		[menu removeItem:item];
	
	NSArray* screens = [NSScreen screens];
	
	int i = 1;
	for (NSScreen* screen in screens) {
		NSString* title = [NSString stringWithFormat:TFLocalizedString(@"ScreenTitle", @"Screen %d (%d x %d)"),
							i, (int)[screen frame].size.width, (int)[screen frame].size.height];
		NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:title
													  action:NULL
											   keyEquivalent:[NSString string]];
		[item setRepresentedObject:[NSNumber numberWithInteger:[screen directDisplayID]]];
		[menu addItem:item];
		
		if ([screen directDisplayID] == [[[self class] screen] directDisplayID])
			[screenPopup selectItem:item];
		
		[item release];
		i++;
	}
}

@end
