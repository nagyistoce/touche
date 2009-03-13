//
//  TFPerformanceMeasurement.c
//  Touché
//
//  Created by Georg Kaindl on 10/3/09.
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

#include "TFPerformanceMeasurement.h"

#include <mach/mach.h>
#include <mach/mach_time.h>
#include <pthread.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

// see http://developer.apple.com/qa/qa2004/qa1398.html for measurement details

#define MAX_MEASUREMENT_TYPES	(32)

static int _TFPMNumMeasurementTypes = 1;

typedef struct {
	// used in internal calculations
	// running is 0 or 1, depending on whether the time is currently being taken
	// lastStart is the last start time for a given measure
	// lastStop is the last stop time for a given measure
	int			running[MAX_MEASUREMENT_TYPES];
	u_int64_t	lastStart[MAX_MEASUREMENT_TYPES];
	u_int64_t	lastStop[MAX_MEASUREMENT_TYPES];
	
	// overlap percentage is the percentage (between 0 and 1) of times that
	// it was attempted to start a timer before the previous run finished (which
	// can happen in a heavily pipelined application)
	float		overlapPercentage[MAX_MEASUREMENT_TYPES];
	// time measurements (in nanoseconds)
	u_int64_t	measures[MAX_MEASUREMENT_TYPES];
} _TFPerformanceMeasureInternal;

u_int64_t _TFPMCurrentSystemTimeInternal();

static unsigned int _measuresCnt = 0;
static pthread_mutex_t _measuresLock = PTHREAD_MUTEX_INITIALIZER;
static _TFPerformanceMeasureInternal** _measures;

void TFPMInitialize(unsigned int numMeasurementTypes)
{
	_TFPMNumMeasurementTypes =
		(numMeasurementTypes > MAX_MEASUREMENT_TYPES) ? MAX_MEASUREMENT_TYPES : numMeasurementTypes;
}

TFPerformanceMeasureID TFPMCreatePerformanceMeasurement()
{
	TFPerformanceMeasureID result = TFPerformanceMeasureInvalidID;
	
	_TFPerformanceMeasureInternal* pm = (_TFPerformanceMeasureInternal*)malloc(sizeof(_TFPerformanceMeasureInternal));
	if (NULL != pm) {
		pthread_mutex_lock(&_measuresLock);
	
		if (0 == _measuresCnt) {
			_measures = (_TFPerformanceMeasureInternal**)malloc(sizeof(_TFPerformanceMeasureInternal*));
			if (NULL != _measures) {
				_measuresCnt = 1;
				result = (TFPerformanceMeasureID)(_measuresCnt-1);
			}
		} else {
			// first, look if there's a free space
			int i = 0;
			for (i; i < _measuresCnt; i++) {
				if (NULL == _measures[i]) {
					result = i;
					break;
				}
			}
			
			// if not, we gotta create a new entry
			if (TFPerformanceMeasureInvalidID == result) {		
				_TFPerformanceMeasureInternal** oldMeasures = _measures;
				_measures = (_TFPerformanceMeasureInternal**)realloc(_measures, (_measuresCnt+1)*sizeof(_TFPerformanceMeasureInternal*));
				if (NULL == _measures) {
					_measures = oldMeasures;
				} else {
					_measuresCnt ++;
					result = (TFPerformanceMeasureID)(_measuresCnt-1);
				}
			}
		}
		
		if (TFPMPerformanceMeasurementIDIsValid(result)) {
			memset(pm, 0, sizeof(_TFPerformanceMeasureInternal));
			_measures[result] = pm;
		}
		
		pthread_mutex_unlock(&_measuresLock);
	}

	return result;
}

void TFPMDestroyPerformanceMeasurement(TFPerformanceMeasureID pmid)
{
	if (TFPMPerformanceMeasurementIDIsValid(pmid)) {
		pthread_mutex_lock(&_measuresLock);
	
		_TFPerformanceMeasureInternal* pm = _measures[pmid];
		_measures[pmid] = NULL;
		free(pm);
		
		// now look if there are NULLs at the end. if yes, we can remove them.
		int cnt = 0;
		while(cnt < _measuresCnt && NULL == _measures[_measuresCnt-1-cnt])
			cnt++;
		
		if (cnt > 0) {
			int newCnt = _measuresCnt-cnt;
			
			if (newCnt <= 0) {
				_measuresCnt = 0;
				free(_measures);
				_measures = NULL;
			} else {				
				_TFPerformanceMeasureInternal** oldMeasure = _measures;
				_measures = (_TFPerformanceMeasureInternal**)realloc(_measures, (_measuresCnt-cnt));
				if (NULL == _measures)
					_measures = oldMeasure;
				else
					_measuresCnt = newCnt;
			}
		}
		
		pthread_mutex_unlock(&_measuresLock);
	}
}

int TFPMPerformanceMeasurementIDIsValid(TFPerformanceMeasureID pmid)
{
	return (pmid >= 0 && pmid < _measuresCnt && NULL != _measures[pmid]);
}

void TFPMStartPerformanceTimer(TFPerformanceMeasureID pmid, TFPerformanceMeasurementType type)
{
	if (TFPMPerformanceMeasurementIDIsValid(pmid) &&
		type >= 0 &&
		type <= _TFPMNumMeasurementTypes) {
		_TFPerformanceMeasureInternal* pm = _measures[pmid];
		if (NULL != pm) {
			if (pm->running[type]) {
				pm->overlapPercentage[type] += 1.0f;
				if (pm->overlapPercentage[type] > 1.0f)
					pm->overlapPercentage[type] *= 0.5f;
			} else {
				pm->running[type] = 1;
				pm->lastStart[type] = _TFPMCurrentSystemTimeInternal();
			}
		}
	}
}

void TFPMStopPerformanceTimer(TFPerformanceMeasureID pmid, TFPerformanceMeasurementType type)
{
	static mach_timebase_info_data_t timeBase;
	
	if (TFPMPerformanceMeasurementIDIsValid(pmid) &&
		type >= 0 &&
		type <= _TFPMNumMeasurementTypes) {
		_TFPerformanceMeasureInternal* pm = _measures[pmid];
		if (NULL != pm && pm->running[type]) {
			pm->lastStop[type] = _TFPMCurrentSystemTimeInternal();
			
			if (0 == timeBase.denom)
				(void)mach_timebase_info(&timeBase);
			
			if (pm->lastStart[type] <= pm->lastStop[type]) {
				u_int64_t measure = pm->lastStop[type] - pm->lastStart[type];
				measure = measure * (timeBase.numer / timeBase.denom);
				
				if (pm->measures[type] > 0)
					measure = (pm->measures[type] >> 1) + (measure >> 1);
				
				pm->measures[type] = measure;
			}
			
			pm->running[type] = 0;
		}
	}
}

TFPerformanceMeasurements TFPMMeasurementsForID(TFPerformanceMeasureID pmid)
{
	TFPerformanceMeasurements m;
	memset(&m, 0, sizeof(TFPerformanceMeasurements));
	
	if (TFPMPerformanceMeasurementIDIsValid(pmid)) {
		m.overlapPercentage = _measures[pmid]->overlapPercentage;
		m.measuredNanos = _measures[pmid]->measures;
		m.numMeasurements = _TFPMNumMeasurementTypes;
	}
	
	return m;
}

u_int64_t _TFPMCurrentSystemTimeInternal()
{
	return (u_int64_t)mach_absolute_time();
}
