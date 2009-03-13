//
//  TFPerformanceTimer.m
//  Touché
//
//  Created by Georg Kaindl on 12/3/09.
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
//

#import "TFPerformanceTimer.h"

#import "TFLocalization.h"


static TFPerformanceTimer* _sharedTimer = nil;

NSString* kTFPerformanceTimerDictTypeKey			= @"TFPerformanceTimerDictTypeKey";
NSString* kTFPerformanceTimerDictNameKey			= @"TFPerformanceTimerDictNameKey";
NSString* kTFPerformanceTimerNanosecondsKey			= @"TFPerformanceTimerNanosecondsKey";
NSString* kTFPerformanceTimerHumanReadableTimeKey	= @"TFPerformanceTimerHumanReadableTimeKey";
NSString* kTFPerformanceTimerOverlapPercentageKey	= @"TFPerformanceTimerOverlapPercentageKey";
NSString* kTFPerformanceTimerFPSKey					= @"TFPerformanceTimerFPSKey";

@interface TFPerformanceTimer (PrivateMethods)
- (id)_initPrivate;
- (TFPerformanceMeasureID)_measurementIdForPointer:(const void*)obj;

- (NSString*)_stringFromNanos:(u_int64_t)nanos;
- (NSString*)_stringFromTimerType:(TFPerformanceTimerType)type;
@end

@implementation TFPerformanceTimer

+ (id)sharedTimer
{
	if (nil == _sharedTimer) {
		TFPMInitialize(TFPerformanceTimerTypeCount);
	
		_sharedTimer = [[[self class] alloc] _initPrivate];
	}
	
	return _sharedTimer;
}

- (id)init
{
	return [[[self class] sharedTimer] retain];
}

- (id)_initPrivate
{
	if (nil != (self = [super init])) {
		_timerIDsForObjects = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (void)dealloc
{
	[_timerIDsForObjects release];
	_timerIDsForObjects = nil;
	
	[super dealloc];
}

- (TFPerformanceMeasureID)createTimer
{
	return TFPMCreatePerformanceMeasurement();
}

- (void)disposeTimerWithID:(TFPerformanceMeasureID)pmid
{
	for (NSValue* obj in [_timerIDsForObjects allKeys])
		if ([[_timerIDsForObjects objectForKey:obj] integerValue] == pmid)
			[_timerIDsForObjects removeObjectForKey:obj];
	
	TFPMDestroyPerformanceMeasurement(pmid);
}

- (void)registerObject:(const void*)obj forMeasurementID:(TFPerformanceMeasureID)measurementID
{
	if (NULL != obj) {
		NSValue* p = [NSValue valueWithPointer:obj];
		[_timerIDsForObjects setObject:[NSNumber numberWithInteger:measurementID]
															forKey:p];
	}
}

- (void)unregisterObject:(const void*)obj
{
	if (NULL != obj)
		[_timerIDsForObjects removeObjectForKey:[NSValue valueWithPointer:obj]];
}

- (void)startTimerWithID:(TFPerformanceMeasureID)measurementID ofType:(TFPerformanceTimerType)type
{
	TFPMStartPerformanceTimer(measurementID, type);
}

- (void)stopTimerWithID:(TFPerformanceMeasureID)measurementID ofType:(TFPerformanceTimerType)type
{
	TFPMStopPerformanceTimer(measurementID, type);
}

- (void)startTimerForObject:(const void*)obj ofType:(TFPerformanceTimerType)type
{
	TFPerformanceMeasureID pmid = [self _measurementIdForPointer:obj];
	
	TFPMStartPerformanceTimer(pmid, type);
}

- (void)stopTimerForObject:(const void*)obj ofType:(TFPerformanceTimerType)type
{
	TFPerformanceMeasureID pmid = [self _measurementIdForPointer:obj];
	
	TFPMStopPerformanceTimer(pmid, type);
}

- (TFPerformanceMeasurements)measurementsForID:(TFPerformanceMeasureID)pmid
{
	return TFPMMeasurementsForID(pmid);
}

- (TFPerformanceMeasurements)measurementsForObject:(const void*)obj
{
	TFPerformanceMeasureID pmid = [self _measurementIdForPointer:obj];

	return [self measurementsForID:pmid];
}

- (NSDictionary*)measurementDictionaryForID:(TFPerformanceMeasureID)pmid
{
	NSMutableDictionary* dict = nil;
	
	if (TFPMPerformanceMeasurementIDIsValid(pmid)) {
		TFPerformanceMeasurements m = [self measurementsForID:pmid];

		dict = [NSMutableDictionary dictionary];

		TFPerformanceTimerType t = TFPerformanceTimerTypeMin;
		for (t; t<=TFPerformanceTimerTypeMax && t<m.numMeasurements; t++) {
			NSMutableDictionary* sdict = [NSMutableDictionary dictionary];
			
			NSString* name = [self _stringFromTimerType:t];
			if (nil != name)
				[sdict setObject:name
						  forKey:kTFPerformanceTimerDictNameKey];
			
			[sdict setObject:[NSNumber numberWithInteger:t]
					  forKey:kTFPerformanceTimerDictTypeKey];
			[sdict setObject:[NSNumber numberWithUnsignedLong:m.measuredNanos[t]]
					  forKey:kTFPerformanceTimerNanosecondsKey];
			[sdict setObject:[self _stringFromNanos:m.measuredNanos[t]]
					  forKey:kTFPerformanceTimerHumanReadableTimeKey];
			[sdict setObject:[NSNumber numberWithFloat:m.overlapPercentage[t]*100.0f]
					  forKey:kTFPerformanceTimerOverlapPercentageKey];
			[sdict setObject:[NSNumber numberWithFloat:(m.measuredNanos[t] > 0 ? (1000000000.0f/(float)m.measuredNanos[t]) : 0.0f)]
					  forKey:kTFPerformanceTimerFPSKey];
		
			[dict setObject:sdict
					 forKey:[NSNumber numberWithInteger:t]];
		}
	}
	
	return dict;
}

- (NSDictionary*)measurementDictionaryForObject:(const void*)obj
{
	TFPerformanceMeasureID pmid = [self _measurementIdForPointer:obj];
	
	return [self measurementDictionaryForID:pmid];
}

- (void)logMeasurementsForID:(TFPerformanceMeasureID)pmid
{
	 NSDictionary* measurementsDict = [self measurementDictionaryForID:pmid];
	
	NSMutableString* str = [NSMutableString string];
	[str appendString:@"\n"];
	[str appendString:TFLocalizedString(@"PerfInternalMeasurementLogHeader",
										@"PerfInternalMeasurementLogHeader")];
	[str appendString:@"\n"];
	
	NSSortDescriptor* sDesc = [[NSSortDescriptor alloc] initWithKey:kTFPerformanceTimerDictTypeKey ascending:YES];
	NSArray* sortedDicts = [[measurementsDict allValues]
								sortedArrayUsingDescriptors:[NSArray arrayWithObject:sDesc]];
	[sDesc release];
	
	for (NSDictionary* dict in sortedDicts) {
			[str appendFormat:TFLocalizedString(@"PerfInternalMeasurementLogLine",
												@"PerfInternalMeasurementLogLine"),
				[dict objectForKey:kTFPerformanceTimerDictNameKey],
				[dict objectForKey:kTFPerformanceTimerHumanReadableTimeKey],
				[[dict objectForKey:kTFPerformanceTimerOverlapPercentageKey] floatValue],
				[[dict objectForKey:kTFPerformanceTimerFPSKey] floatValue]];
	}
	
	NSLog(@"%@", str);
}

- (void)logMeasurementsForObject:(const void*)obj
{
	TFPerformanceMeasureID pmid = [self _measurementIdForPointer:obj];
	
	[self logMeasurementsForID:pmid];
}

- (TFPerformanceMeasureID)_measurementIdForPointer:(const void*)obj
{
	NSNumber* n = [_timerIDsForObjects objectForKey:[NSValue valueWithPointer:obj]];
	
	return (nil != n ? [n integerValue] : TFPerformanceMeasureInvalidID);
}

- (NSString*)_stringFromNanos:(u_int64_t)nanos
{
	NSString* str = nil;
	
	// precision for floating point is %.2f
	if (nanos > 100000000)
		str = [NSString stringWithFormat:TFLocalizedString(@"PerfSeconds", @"PerfSeconds"),
				(float)nanos/1000000000.0f];
	else if (nanos > 100000)
		str = [NSString stringWithFormat:TFLocalizedString(@"PerfMilliseconds", @"PerfMilliseconds"),
				(float)nanos/1000000.0f];
	else if (nanos > 0)
		str = [NSString stringWithFormat:TFLocalizedString(@"PerfNanoseconds", @"PerfNanoseconds"), nanos];
	else
		str = TFLocalizedString(@"PerfNothing", @"PerfNothing");

	return str;
}

- (NSString*)_stringFromTimerType:(TFPerformanceTimerType)type
{
	NSString* str = TFLocalizedString(@"PerfTimerTypeUnknown", @"PerfTimerTypeUnknown");
	
	switch (type) {
		case TFPerformanceTimerCIImageAcquisition:
			str = TFLocalizedString(@"PerfTimerTypeCIImageAcquisition", @"PerfTimerTypeCIImageAcquisition");
			break;
		case TFPerformanceTimerFilterRendering:
			str = TFLocalizedString(@"PerfTimerTypeFilterRendering", @"PerfTimerTypeFilterRendering");
			break;
		case TFPerformanceTimerBlobDetection:
			str = TFLocalizedString(@"PerfTimerTypeBlobDetection", @"PerfTimerTypeBlobDetection");
			break;
		default:
			break;
	}
	
	return str;
}

@end
