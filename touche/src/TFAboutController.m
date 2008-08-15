//
//  TFAboutController.m
//  Touché
//
//  Created by Georg Kaindl on 12/5/08.
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

#import "TFAboutController.h"

#import <WebKit/WebKit.h>

#import "TFIncludes.h"
#import "NSView+Extras.h"

@interface TFAboutController (NonPublicMethods)
- (void)_setDefaults;
@end

@implementation TFAboutController

- (void)dealloc
{
	[_webView setPolicyDelegate:nil];

	[super dealloc];
}

- (id)init
{
	if (!(self = [super initWithWindowNibName:@"About"])) {
		[self release];
		return nil;
	}
	
	[self loadWindow];
	[self _setDefaults];
	
	return self;
}

- (void)_setDefaults
{
	NSBundle* mainBundle = [NSBundle bundleForClass:[self class]];
	if (nil != mainBundle) {
		NSString* versionString = [NSString stringWithFormat:TFLocalizedString(@"AboutVersionString", @"Version %@"),
								   [mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
		
		[_versionLabel setStringValue:versionString];
		[_versionLabel sizeToFit];
		[_versionLabel centerInSuperview];
		
		NSString* creditsWrapper = [NSString stringWithContentsOfFile:[mainBundle pathForResource:@"credits-wrapper" ofType:@"html"]
															 encoding:NSUTF8StringEncoding
																error:NULL];
		NSString* credits = [NSString stringWithContentsOfFile:[mainBundle pathForResource:@"credits" ofType:@"html"]
													  encoding:NSUTF8StringEncoding
														 error:NULL];
		[[_webView mainFrame] loadHTMLString:[NSString stringWithFormat:creditsWrapper, credits]
									 baseURL:nil];
		
		[_webView setPolicyDelegate:self];
	}
}

- (void)showWindow:(id)sender
{
	[_webView stringByEvaluatingJavaScriptFromString:@"CreditsScroll.reset(); CreditsScroll.startScroll();"];
	
	[super showWindow:sender];
}

#pragma mark -
#pragma mark NSWindow delegate

- (void)windowWillClose:(NSNotification *)notification
{
	if ([[notification object] isEqual:[self window]]) {
		[_webView stringByEvaluatingJavaScriptFromString:@"CreditsScroll.stopScroll();"];
	}
}

#pragma mark -
#pragma mark WebPolicyDelegate informal protocol

- (void)webView:(WebView*)sender decidePolicyForNavigationAction:(NSDictionary*)actionInformation request:(NSURLRequest*)request frame:(WebFrame*)frame decisionListener:(id <WebPolicyDecisionListener>)listener
{
	[[NSWorkspace sharedWorkspace] openURL:[request URL]];
	[listener ignore];
}

- (void)webView:(WebView*)sender decidePolicyForNewWindowAction:(NSDictionary*)actionInformation request:(NSURLRequest*)request newFrameName:(NSString*)frameName decisionListener:(id <WebPolicyDecisionListener>)listener
{
	[[NSWorkspace sharedWorkspace] openURL:[request URL]];
	[listener ignore];
}

@end
