//
//  TFScreenPreferencesController.h
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

#import <Cocoa/Cocoa.h>

@class TFScreenPrefsMeasureView;

@interface TFScreenPreferencesController : NSWindowController {
	IBOutlet NSPopUpButton*				screenPopup;
	IBOutlet NSSlider*					screenResolutionSlider;
	IBOutlet TFScreenPrefsMeasureView*	measureView;
	IBOutlet NSTextField*				measureField;
	id									delegate;
}

@property (nonatomic, assign) id delegate;

+ (NSScreen*)screen;
+ (CGFloat)screenPixelsPerCentimeter;
+ (CGFloat)screenPixelsPerInch;

- (IBAction)measureSliderChanged:(id)sender;

@end

@interface NSObject (TFScreenPreferencesControllerDelegate)
- (void)multitouchScreenDidChangeTo:(NSScreen*)screen;
@end