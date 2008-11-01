//
//  TFInfoViewController.m
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

#import "TFInfoViewController.h"

#import <QuartzCore/QuartzCore.h>

#import "TFIncludes.h"
#import "TFInfoView.h"

@interface TFInfoViewController (NonPublicMethods)
- (void)_actionButtonAction:(id)sender;
- (void)_sizeControlWithAnchorToTheRight:(NSControl*)control;
@end

@implementation TFInfoViewController

@synthesize delegate;
@synthesize type;
@synthesize previousView;
@synthesize clickingActionAlsoDismisses;
@synthesize identifier;

- (void)dealloc
{
	[previousView release];
	previousView = nil;
	
	[super dealloc];
}

- (id)init
{
	return [self initWithNibName:@"InfoView" bundle:[NSBundle bundleForClass:[self class]]];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if (!(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		[self release];
		return nil;
	}
	
	[self loadView];
	
	previousView = nil;
	clickingActionAlsoDismisses = NO;
	
	return self;
}

- (void)loadView
{
	[super loadView];
	
	[_actionButton setAction:@selector(_actionButtonAction:)];
	[_actionButton setTarget:self];
	
	((TFInfoView*)[self view]).controller = self;
}

- (void)hideDismissButton
{
	NSRect dismissFrame = [_dismissButton frame];
	NSRect actionFrame = [_actionButton frame];

	[_dismissButton removeFromSuperview];
	
	actionFrame.origin.x = dismissFrame.origin.x + dismissFrame.size.width - actionFrame.size.width;
	[_actionButton setFrame:actionFrame];
}

- (void)setType:(NSInteger)newType
{
	NSImage* img = nil;
	switch (newType) {
		case TFInfoViewControllerTypeError:
			img = [NSImage imageNamed:@"erroricon"];
			break;
		case TFInfoViewControllerTypeAlert:
			img = [NSImage imageNamed:@"warningicon"];
			break;
		case TFInfoViewControllerTypeInfo:
			img = [NSImage imageNamed:@"NSInfo"];
			break;
		default:
			break;
	};
	
	if (nil != img)
		[_icon setImage:img];
	
	type = newType;
}

- (void)setTitleText:(NSString*)titleText
{
	if (nil != titleText)
		[_titleField setStringValue:titleText];
}

- (void)setDescriptionText:(NSString*)descText
{
	if (nil != descText)
		[_descriptionField setStringValue:descText];
}

- (void)setActionButtonTitle:(NSString*)title action:(SEL)action target:(id)target
{
	if (nil != title && nil != target) {
		_actionSelector = action;
		_actionTarget = target;	
		[_actionButton setTitle:title];
		[_actionButton setHidden:NO];
		[self _sizeControlWithAnchorToTheRight:_actionButton];
	}
}

- (void)loadDescriptionFromError:(NSError*)error
{
	[self loadDescriptionFromError:error defaultRecoverySuggestion:nil];
}

- (void)loadDescriptionFromError:(NSError*)error defaultRecoverySuggestion:(NSString*)defaultRecoverySuggestion
{
	NSMutableString* desc = [NSMutableString string];
	
	if (nil != [error localizedFailureReason])
		[desc appendString:[error localizedFailureReason]];
	else if (nil != [error localizedDescription])
		[desc appendString:[error localizedDescription]];
	
	if (nil != [error localizedRecoverySuggestion])
		[desc appendFormat:@"\n\n%@", [error localizedRecoverySuggestion]];
	else if (nil != defaultRecoverySuggestion)
		[desc appendFormat:@"\n\n%@", defaultRecoverySuggestion];
	
	[self setDescriptionText:[NSString stringWithString:desc]];
}

- (IBAction)dismissButtonClicked:(id)sender
{
	if ([delegate respondsToSelector:@selector(infoViewControllerDismissButtonClicked:)])
		[delegate infoViewControllerDismissButtonClicked:self];
}

- (void)_actionButtonAction:(id)sender
{
	if (nil != _actionTarget)
		[_actionTarget performSelector:_actionSelector];
	
	if ([delegate respondsToSelector:@selector(infoViewControllerActionButtonClicked:)])
		[delegate infoViewControllerActionButtonClicked:self];
	
	if (self.clickingActionAlsoDismisses)
		[self dismissButtonClicked:sender];
}

- (void)_sizeControlWithAnchorToTheRight:(NSControl*)control
{
	NSRect oldFrame = [control frame];
	[control sizeToFit];
	NSRect newFrame = [control frame];
	[control setFrame:NSMakeRect(
								 oldFrame.origin.x + (oldFrame.size.width-newFrame.size.width),
								 newFrame.origin.y,
								 newFrame.size.width,
								 newFrame.size.height
								 )];
	[control setNeedsDisplay:YES];
}

@end
