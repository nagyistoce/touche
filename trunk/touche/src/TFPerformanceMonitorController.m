//
//  TFPerformanceMonitorController.m
//  Touché
//
//  Created by Georg Kaindl on 28/3/09.
//
//  Copyright (C) 2009 Georg Kaindl
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

#import "TFPerformanceMonitorController.h"

#import "TFIncludes.h"
#import "TFResourceStats.h"


#define	UPDATE_INTERVAL		((NSTimeInterval)1.0)

NSString* kTFPMCNameKey			= @"measurementName";
NSString* kTFPMCTimeKey			= @"measurementTime";
NSString* kTFPMCFPSKey			= @"measurementFPS";

NSString* kTFPMCTaskNameKey		= @"taskName";
NSString* kTFPMCTaskInfo1Key	= @"taskInfo1";
NSString* kTFPMCTaskInfo2Key	= @"taskInfo2";

enum {
	kTFPMTaskCPURow		= 0,
	kTFPMTaskMemRow		= 1
};

@interface TFPerformanceMonitorController (PrivateMethods)
- (void)_clearUpdateTimer;
- (NSString*)_memSizeStringFromByteCount:(unsigned int)bytes;
- (void)_updatePerformanceMeasurements:(NSTimer*)timer;
@end

@implementation TFPerformanceMonitorController

@synthesize measureID;

- (id)init
{
	if (nil != (self = [super initWithWindowNibName:@"PerformanceMonitor"])) {
		self.measureID = TFPerformanceMeasureInvalidID;
		
		_updateLock = [[NSLock alloc] init];
		
		_cpuPercent = 0.0;
		_realMemBytes = _virtualMemBytes = 0;
	}
	
	return self;
}

- (void)dealloc
{
	[self _clearUpdateTimer];
	
	[_measurements release];
	_measurements = nil;
	
	[_updateLock release];
	_updateLock = nil;
	
	[super dealloc];
}

- (void)showWindow:(id)sender
{
	[self _clearUpdateTimer];
	
	_updateTimer = [[NSTimer scheduledTimerWithTimeInterval:UPDATE_INTERVAL
													 target:self
												   selector:@selector(_updatePerformanceMeasurements:)
												   userInfo:nil
													repeats:YES] retain];
	
	[[NSRunLoop currentRunLoop] addTimer:_updateTimer forMode:NSEventTrackingRunLoopMode];
	
	[self _updatePerformanceMeasurements:_updateTimer];
	
	[super showWindow:sender];
}

#pragma mark -
#pragma mark NSTableDataSource informal protocol

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{	
	NSInteger rowCnt = 0;
	
	if (aTableView == _measurementsTableView) {
		[_updateLock lock];
			rowCnt = [_measurements count];
		[_updateLock unlock];
	} else if (aTableView == _taskTableView)
		rowCnt = 2;
	
	return rowCnt;
}

- (id)tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)rowIndex
{
	id retval = nil;
	id identifier = [aTableColumn identifier];
	
	if (aTableView == _measurementsTableView) {
		[_updateLock lock]; {
			NSDictionary* sDict = [_measurements objectForKey:[NSNumber numberWithInteger:rowIndex]];
		
			if (nil != sDict) {
				if ([identifier isEqual:kTFPMCNameKey])
					retval = [sDict objectForKey:kTFPerformanceTimerDictNameKey];
				else if ([identifier isEqual:kTFPMCTimeKey]) {
					NSNumber* ns = [sDict objectForKey:kTFPerformanceTimerNanosecondsKey];
					
					if ([ns floatValue] <= 0.0)
						retval = [NSString stringWithFormat:TFLocalizedString(@"PerformanceMeasureNothing",
																			  @"PerformanceMeasureNothing")];
					else
						retval = [NSString stringWithFormat:TFLocalizedString(@"PerformanceMeasureTimeFormat",
																			  @"PerformanceMeasureTimeFormat"),
																					[ns floatValue]/1000000.0f];
				} else if ([identifier isEqual:kTFPMCFPSKey]) {
					NSNumber* fps = [sDict objectForKey:kTFPerformanceTimerFPSKey];
					
					if ([fps floatValue] <= 0.0)
						retval = [NSString stringWithFormat:TFLocalizedString(@"PerformanceMeasureNothing",
																			  @"PerformanceMeasureNothing")];
					else
						retval = [NSString stringWithFormat:TFLocalizedString(@"PerformanceMeasureFPSFormat",
																			  @"PerformanceMeasureFPSFormat"),
																					[fps floatValue]];
				}
			}
		} [_updateLock unlock];
	} else if (aTableView == _taskTableView) {
		switch (rowIndex) {
			case kTFPMTaskCPURow: {
				if ([identifier isEqual:kTFPMCTaskNameKey])
					retval = [NSString stringWithString:TFLocalizedString(@"PerformanceCPUTimeName",
																		  @"PerformanceCPUTimeName")];
				else if ([identifier isEqual:kTFPMCTaskInfo1Key])
					retval = [NSString stringWithFormat:TFLocalizedString(@"PerformanceCPUTimeFormat",
																		  @"PerformanceCPUTimeFormat"),
																		  (float)_cpuPercent*100.0f];
				else if ([identifier isEqual:kTFPMCTaskInfo2Key])
					retval = [NSString stringWithFormat:TFLocalizedString(@"PerformanceCPUTimeMaxFormat",
																		  @"PerformanceCPUTimeMaxFormat"),
																100*[[NSProcessInfo processInfo] activeProcessorCount]];
				
				break;
			}
			
			case kTFPMTaskMemRow: {
				if ([identifier isEqual:kTFPMCTaskNameKey])
					retval = [NSString stringWithString:TFLocalizedString(@"PerformanceMemUsageName",
																		  @"PerformanceMemUsageName")];
				else if ([identifier isEqual:kTFPMCTaskInfo1Key])
					retval = [NSString stringWithFormat:TFLocalizedString(@"PerformanceMemRealFormat",
																		  @"PerformanceMemRealFormat"),
																		  [self _memSizeStringFromByteCount:_realMemBytes]];
				else if ([identifier isEqual:kTFPMCTaskInfo2Key])
					retval = [NSString stringWithFormat:TFLocalizedString(@"PerformanceMemVirtualFormat",
																		  @"PerformanceMemVirtualFormat"),
																		  [self _memSizeStringFromByteCount:_virtualMemBytes]];
				
				break;
			}
			
			default:
				break;
		}
	}
	
	return retval;
}

#pragma mark -
#pragma mark NSTableView delegate

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
	return NO;
}

#pragma mark -
#pragma mark NSWindow delegate

- (void)windowWillClose:(NSNotification *)notification
{
	if ([[notification object] isEqual:[self window]])
		[self _clearUpdateTimer];
}

#pragma mark -
#pragma mark Private Methods

- (void)_clearUpdateTimer
{
	[_updateTimer invalidate];
	[_updateTimer release];
	_updateTimer = nil;
}

- (NSString*)_memSizeStringFromByteCount:(unsigned int)bytes
{
	NSString* rv = nil;
	
	if (bytes >= 1024*1024*1024)
		rv = [NSString stringWithFormat:TFLocalizedString(@"PerformanceMemGBFormat",
														  @"PerformanceMemGBFormat"),
														  (float)bytes / (1024.0f*1024.0f*1024.0f)];
	else if (bytes >= 1024*1024)
		rv = [NSString stringWithFormat:TFLocalizedString(@"PerformanceMemMBFormat",
														  @"PerformanceMemMBFormat"),
														  (float)bytes / (1024.0f*1024.0f)];
	else if (bytes >= 1024)
		rv = [NSString stringWithFormat:TFLocalizedString(@"PerformanceMemKBFormat",
														  @"PerformanceMemKBFormat"),
														  (float)bytes / 1024.0f];
	else
		rv = [NSString stringWithFormat:TFLocalizedString(@"PerformanceMemBFormat",
														  @"PerformanceMemBFormat"),
														  bytes];
	
	return rv;
}

- (void)_updatePerformanceMeasurements:(NSTimer*)timer
{
	if  (TFPMPerformanceMeasurementIDIsValid(measureID)) {
		[_updateLock lock];
			[_measurements release];
			_measurements = [[[TFPerformanceTimer sharedTimer] measurementDictionaryForID:measureID] retain];			
		[_updateLock unlock];
		
		[_measurementsTableView reloadData];
		
		TFRSGetTaskCPUTime(TFRSCurrentTask(), NULL, NULL, &_cpuPercent);
		TFRSGetTaskMemoryUsage(TFRSCurrentTask(), &_realMemBytes, &_virtualMemBytes, NULL);
		
		[_taskTableView reloadData];
	}	
}

@end
