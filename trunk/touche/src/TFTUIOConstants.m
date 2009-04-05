//
//  TFTUIOConstants.m
//  Touché
//
//  Created by Georg Kaindl on 6/9/08.
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

#import "TFTUIOConstants.h"


NSString* kTFTUIO10CursorProfileAddressString	= @"/tuio/2Dcur";

NSString* kTFTUIO11BlobProfileAddressString		= @"/tuio/2Dblb";

NSString* kTFTUIO10SourceArgumentName				= @"source";
NSString* kTFTUIO10FrameSequenceNumberArgumentName	= @"fseq";
NSString* kTFTUIO10AliveArgumentName				= @"alive";
NSString* kTFTUIO10SetArgumentName					= @"set";

NSString* TFTUIOConstantsSourceName()
{
	static NSString* appName = nil;
	
	if (nil == appName) {
		NSBundle* mainBundle = [NSBundle mainBundle];
		NSString* name = [mainBundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
		if (nil == name)
			name = [mainBundle objectForInfoDictionaryKey:@"CFBundleName"];
		if (nil == name)
			name = @"<unknown>";
		if (nil != name) {
			NSString* version = [mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
			if (nil == version)
				version = [mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
			if (nil != version)
				name = [name stringByAppendingFormat:@" %@", version];
		}
				
		if (nil != name)
			appName = [[NSString alloc] initWithData:[name dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]
											encoding:NSASCIIStringEncoding];
	}
	
	return appName;
}

NSString* TFTUIOVersionToString(TFTUIOVersion ver)
{
	id rv = nil;
	
	switch(ver) {
		case TFTUIOVersion1_0Cursors:
			rv = [NSString stringWithString:NSLocalizedString(@"TUIOVersion1.0",
															  @"TUIOVersion1.0")];
			break;
		case TFTUIOVersion1_0CursorsAnd1_1Blobs:
			rv = [NSString stringWithString:NSLocalizedString(@"TUIOVersion1.0+1.1Blobs",
															  @"TUIOVersion1.0+1.1Blobs")];
			break;
		case TFTUIOVersion1_1Blobs:
			rv = [NSString stringWithString:NSLocalizedString(@"TFTUIOVersion1.1Blobs",
															  @"TFTUIOVersion1.1Blobs")];
			break;
	}
	
	return rv;
}

NSMenu* TFTUIOVersionSelectionMenu()
{
	NSMenu* menu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"TFTUIOVersionMenuTitle",
																   @"TFTUIOVersionMenuTitle")];
	
	[menu setAutoenablesItems:NO];
	
	int i;
	for (i=TFTUIOVersionMin; i<=TFTUIOVersionMax; i++) {
		NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:TFTUIOVersionToString(i)
													  action:NULL
											   keyEquivalent:[NSString string]];
		
		[item setTag:i];
		[menu addItem:item];
		
		[item release];
	}
	
	return [menu autorelease];
}

TFTUIOVersion TFTUIOVersionForMenuItem(NSMenuItem* item)
{
	TFTUIOVersion ver = [item tag];
	
	if (TFTUIOVersionMin > ver || TFTUIOVersionMax < ver)
		ver = TFTUIOVersionMin;
	
	return ver;
}

NSInteger TFTUIOIndexForMenuItemWithVersion(NSMenu* menu, TFTUIOVersion ver)
{
	return [menu indexOfItemWithTag:ver];
}

NSTimeInterval TFTUIOTimeIntervalBetweenCocoaAndNTPRefDate()
{	
	static NSTimeInterval secs = (NSTimeInterval)0.0;
	
	if (0.0 >= secs) {
		NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		
		NSDateComponents* ntpRefDateComps = [[NSDateComponents alloc] init];
		[ntpRefDateComps setDay:1];
		[ntpRefDateComps setMonth:1];
		[ntpRefDateComps setYear:1900];
		
		NSDate* ntpRefDate = [calendar dateFromComponents:ntpRefDateComps];
		
		NSDate* cocoaRefDate = [NSDate dateWithTimeIntervalSinceReferenceDate:(NSTimeInterval)0.0];
		
		secs = [cocoaRefDate timeIntervalSinceDate:ntpRefDate];
		
		[ntpRefDateComps release];
		[calendar release];
	}
	
	return secs;
}
