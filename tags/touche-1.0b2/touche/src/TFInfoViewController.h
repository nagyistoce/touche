//
//  TFInfoViewController.h
//  Touché
//
//  Created by Georg Kaindl on 7/5/08.
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
	TFInfoViewControllerTypeInfo = 1,
	TFInfoViewControllerTypeAlert = 2,
	TFInfoViewControllerTypeError = 3
};

@interface TFInfoViewController : NSViewController {
	id							delegate;

	IBOutlet NSImageView*		_icon;
	IBOutlet NSTextField*		_titleField;
	IBOutlet NSTextField*		_descriptionField;
	IBOutlet NSButton*			_dismissButton;
	IBOutlet NSButton*			_actionButton;
	
	id							_actionTarget;
	SEL							_actionSelector;
	
	NSView*						previousView;
	
	NSInteger					type;
	BOOL						clickingActionAlsoDismisses;
	NSUInteger					identifier;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) NSInteger type;
@property (nonatomic, retain) NSView* previousView;
@property (nonatomic, assign) BOOL clickingActionAlsoDismisses;
@property (nonatomic, assign) NSUInteger identifier;

- (IBAction)dismissButtonClicked:(id)sender;

- (void)hideDismissButton;
- (void)setTitleText:(NSString*)titleText;
- (void)setDescriptionText:(NSString*)descText;
- (void)setActionButtonTitle:(NSString*)title action:(SEL)action target:(id)target;

- (void)loadDescriptionFromError:(NSError*)error;
- (void)loadDescriptionFromError:(NSError*)error defaultRecoverySuggestion:(NSString*)defaultRecoverySuggestion;

@end

@interface NSObject (TFInfoViewControllerDelegate)
- (void)infoViewControllerActionButtonClicked:(TFInfoViewController*)controller;
- (void)infoViewControllerDismissButtonClicked:(TFInfoViewController*)controller;
@end
