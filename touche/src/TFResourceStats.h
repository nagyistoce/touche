//
//  TFResourceStats.h
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

#if !defined(__TFResourceStats_H__)
#define __TFResourceStats_H__

#include <mach/mach_port.h>
#include <mach/task.h>


task_t TFRSCurrentTask();

kern_return_t TFRSGetTaskCPUTime(task_t task,
								 double* userTime,
								 double* sysTime,
								 double* percent);
										
kern_return_t TFRSGetThreadCPUTime(thread_t thread,
								   double* userTime,
								   double* sysTime,
								   double* percent);

kern_return_t TFRSGetTaskMemoryUsage(task_t task,
									 unsigned* realSize,
									 unsigned* virtualSize,
									 double* percent);

#endif