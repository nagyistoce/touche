//
//  TFPerformanceMeasurement.h
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

#if !defined(_TFPERFORMANCEMEASUREMENT_H_)
#define _TFPERFORMANCEMEASUREMENT_H_ 1

#include <sys/types.h>

typedef struct {
	float*		overlapPercentage;
	u_int64_t*	measuredNanos;
	unsigned	numMeasurements;
} TFPerformanceMeasurements;

typedef int TFPerformanceMeasureID;
typedef int TFPerformanceMeasurementType;

#define	TFPerformanceMeasureInvalidID	((TFPerformanceMeasureID)-1)


// this has to be called before calling any other function. exactly once.
void TFPMInitialize(unsigned int numMeasurementTypes);

// returns the identifier of the new performance measure struct
TFPerformanceMeasureID TFPMCreatePerformanceMeasurement();

// removes a performance measure with the given id
void TFPMDestroyPerformanceMeasurement(TFPerformanceMeasureID pmid);

// returns 1 if the ID is valid, 0 otherwise
int TFPMPerformanceMeasurementIDIsValid(TFPerformanceMeasureID pmid);

// starts a timer for a given measurement ID and type
void TFPMStartPerformanceTimer(TFPerformanceMeasureID pmid, TFPerformanceMeasurementType type);

// stops a timer for a given measurement ID and type
void TFPMStopPerformanceTimer(TFPerformanceMeasureID pmid, TFPerformanceMeasurementType type);

// returns the current measurements for a given ID
TFPerformanceMeasurements TFPMMeasurementsForID(TFPerformanceMeasureID pmid);

#endif // !defined(_TFPERFORMANCEMEASUREMENT_H_)