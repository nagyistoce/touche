//
//  TFMiscPreferencesController.m
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

#import "TFMiscPreferencesController.h"

#import "TFIncludes.h"
#import "CGColorFromNSColor.h"
#import "CGColorRefColorSpaceConversions.h"

#define L_THRESHOLD_FOR_DARK_LABEL_TEXT	(90.8f)

NSString* tFUIColorPreferenceKey = @"tFUIColorPreferenceKey";
NSString* tFTouchViewTouchesAreAnimatedPreferenceKey = @"tFTouchViewTouchesAreAnimatedPreferenceKey";

@interface TFMiscPreferencesController (NonPublicMethods)
+ (NSColor*)_defaultColor;
- (void)_storeColorInPrefs:(NSColor*)color;
@end


@implementation TFMiscPreferencesController

- (void)dealloc
{
	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:tFUIColorPreferenceKey];
	
	[super dealloc];
}

+ (void)initialize
{
	// other preferences are initialized via UserDefaults.plist in the resources
	NSColor* color = [[self class] _defaultColor];
	NSData* colorData = [NSKeyedArchiver archivedDataWithRootObject:color];
	NSDictionary* defaults =
		[NSDictionary dictionaryWithObjectsAndKeys:colorData, tFUIColorPreferenceKey, nil];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (id)init
{
	if (!(self = [super initWithWindowNibName:@"MiscPreferences"])) {
		[self release];
		return nil;
	}
	
	[self loadWindow];
	
	[baseColorWell setColor:[[self class] baseColor]];
	
	[[NSUserDefaults standardUserDefaults] addObserver:self
											forKeyPath:tFUIColorPreferenceKey
											   options:NSKeyValueObservingOptionNew
											   context:NULL];
	
	return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isEqual:[NSUserDefaults standardUserDefaults]] && [keyPath isEqualToString:tFUIColorPreferenceKey]) {
		NSColor* color = [NSKeyedUnarchiver unarchiveObjectWithData:[change objectForKey:NSKeyValueChangeNewKey]];
		[baseColorWell setColor:color];
	}
}

+ (BOOL)touchesShouldAnimate
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:tFTouchViewTouchesAreAnimatedPreferenceKey];
}

+ (NSColor*)baseColor
{
	NSData* data = [[NSUserDefaults standardUserDefaults] objectForKey:tFUIColorPreferenceKey];
	return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

+ (NSColor*)labelColor
{
	return [[self class] labelColorForBaseColor:[[self class] baseColor]];
}

+ (NSColor*)labelColorForBaseColor:(NSColor*)baseColor
{
	CGFloat lab[3];
	CGColorRef cgColor = CGColorCreateFromNSColor(baseColor);
	CGColorGetLABComponentsForRGBColor(cgColor, lab);
	CGColorRelease(cgColor);
	
	if (lab[0] > L_THRESHOLD_FOR_DARK_LABEL_TEXT)
		return [NSColor colorWithCalibratedWhite:0.25 alpha:1.0f];
	
	return [NSColor colorWithCalibratedWhite:1.0f alpha:1.0f];
}

+ (NSColor*)wizardNumberCircleColor
{
	return [[self class] wizardNumberCircleColorForBaseColor:[[self class] baseColor]];
}

+ (NSColor*)wizardNumberCircleColorForBaseColor:(NSColor*)baseColor
{
	CGFloat lab[3];
	CGColorRef cgColor = CGColorCreateFromNSColor(baseColor);
	CGColorGetLABComponentsForRGBColor(cgColor, lab);
	CGColorRelease(cgColor);
	
	lab[0] += 12.0f;
	lab[1] += 9.0f;
	lab[2] += 5.0f;
	
	if (lab[0] > 90.0)
		lab[0] = 90.0;
	
	CGColorRef rvColor = CGColorCreateRGBfromGenericLABComponents(lab, 1.0);
	NSColorSpace* colorSpace = [[NSColorSpace alloc] initWithCGColorSpace:CGColorGetColorSpace(rvColor)];
	NSColor* rv = [NSColor colorWithColorSpace:colorSpace
									components:CGColorGetComponents(rvColor)
										 count:CGColorGetNumberOfComponents(rvColor)];
	[colorSpace release];
	CGColorRelease(rvColor);
	
	return rv;
}

- (IBAction)baseColorChanged:(id)sender
{
	[self _storeColorInPrefs:[sender color]];
}

- (IBAction)resetColor:(id)sender
{
	[self _storeColorInPrefs:[[self class] _defaultColor]];
}

+ (NSColor*)_defaultColor
{
	return [NSColor colorWithCalibratedRed:.127f green:.653f blue:.939f alpha:1.0f];
}

- (void)_storeColorInPrefs:(NSColor*)color
{
	NSData* colorData = [NSKeyedArchiver archivedDataWithRootObject:color];
	[[NSUserDefaults standardUserDefaults] setObject:colorData forKey:tFUIColorPreferenceKey];
}

@end
