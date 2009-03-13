//
//  TFPerformanceTimer.h
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

#import <Cocoa/Cocoa.h>

#import "TFPerformanceMeasurement.h"

extern NSString* kTFPerformanceTimerDictTypeKey;
extern NSString* kTFPerformanceTimerDictNameKey;
extern NSString* kTFPerformanceTimerNanosecondsKey;
extern NSString* kTFPerformanceTimerHumanReadableTimeKey;
extern NSString* kTFPerformanceTimerOverlapPercentageKey;
extern NSString* kTFPerformanceTimerFPSKey;

typedef enum {
	TFPerformanceTimerCIImageAcquisition = 0,
	TFPerformanceTimerFilterRendering,
	TFPerformanceTimerBlobDetection
} TFPerformanceTimerType;

#define TFPerformanceTimerTypeMin		(TFPerformanceTimerCIImageAcquisition)
#define TFPerformanceTimerTypeMax		(TFPerformanceTimerBlobDetection)
#define TFPerformanceTimerTypeCount		(TFPerformanceTimerTypeMax-TFPerformanceTimerTypeMin+1)

// convenience macros
#define TFPMStartTimer(type)	do { [[TFPerformanceTimer sharedTimer] startTimerForObject:self ofType:(type)]; } while (0)
#define TFPMStopTimer(type)		do { [[TFPerformanceTimer sharedTimer] stopTimerForObject:self ofType:(type)]; } while (0)


@interface TFPerformanceTimer : NSObject {
	NSMutableDictionary*	_timerIDsForObjects;
}

+ (id)sharedTimer;

- (id)init;
- (void)dealloc;

- (TFPerformanceMeasureID)createTimer;
- (void)disposeTimerWithID:(TFPerformanceMeasureID)pmid;

- (void)registerObject:(const void*)obj forMeasurementID:(TFPerformanceMeasureID)measurementID;
- (void)unregisterObject:(const void*)obj;

- (void)startTimerWithID:(TFPerformanceMeasureID)measurementID ofType:(TFPerformanceTimerType)type;
- (void)stopTimerWithID:(TFPerformanceMeasureID)measurementID ofType:(TFPerformanceTimerType)type;

- (void)startTimerForObject:(const void*)obj ofType:(TFPerformanceTimerType)type;
- (void)stopTimerForObject:(const void*)obj ofType:(TFPerformanceTimerType)type;

- (TFPerformanceMeasurements)measurementsForID:(TFPerformanceMeasureID)pmid;
- (TFPerformanceMeasurements)measurementsForObject:(const void*)obj;

- (NSDictionary*)measurementDictionaryForID:(TFPerformanceMeasureID)pmid;
- (NSDictionary*)measurementDictionaryForObject:(const void*)obj;

- (void)logMeasurementsForID:(TFPerformanceMeasureID)pmid;
- (void)logMeasurementsForObject:(const void*)obj;

@end
