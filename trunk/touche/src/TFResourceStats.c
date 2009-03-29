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
//  Credit for these goes to http://sourceforge.net/projects/agkit/
//	I only made some minor changes.

#include "TFResourceStats.h"

#include <mach/shared_memory_server.h>


task_t TFRSCurrentTask()
{
	return mach_task_self(); 
}

kern_return_t TFRSGetThreadCPUTime(thread_t thread,
								   double* userTime,
								   double* sysTime,
								   double* percent)
{
	struct thread_basic_info thInfo;
	kern_return_t err;
	mach_msg_type_number_t thInfoCnt = THREAD_BASIC_INFO_COUNT;
	
	err = thread_info(thread, THREAD_BASIC_INFO, (thread_info_t)&thInfo, &thInfoCnt);
	if (KERN_SUCCESS != err)
		return err;
	
	if (NULL != userTime)
		*userTime = thInfo.user_time.seconds + thInfo.user_time.microseconds / 1000000.0;
	if (NULL != sysTime)
		*sysTime = thInfo.system_time.seconds + thInfo.system_time.microseconds / 1000000.0;
	if (NULL != percent)
		*percent = (double)thInfo.cpu_usage / (double)TH_USAGE_SCALE;
	
	return KERN_SUCCESS;
}

kern_return_t TFRSGetTaskCPUTime(task_t task,
								 double* userTime,
								 double* sysTime,
								 double* percent)
{
	struct task_basic_info tInfo;
	thread_array_t thArray;
	kern_return_t err;
	mach_msg_type_number_t thCnt, tInfoCnt = TASK_BASIC_INFO_COUNT;
	task_t self = mach_task_self();
	double ut = 0, st = 0, p = 0;
	
	err = task_info(task, TASK_BASIC_INFO, (task_info_t)&tInfo, &tInfoCnt);
	if (KERN_SUCCESS != err)
		return err;
	
	err = task_threads(task, &thArray, &thCnt);
	if (KERN_SUCCESS != err)
		return err;
	
	int i;
	double thut, thst, pst;
	for (i=0; i<thCnt; i++) {
		err = TFRSGetThreadCPUTime(thArray[i], &thut, &thst, &pst); 
		
		if (KERN_SUCCESS != err)
			break;
		
		ut += thut;
		st += thst;
		p += pst;
	}
		
	for (i=0; i<thCnt; i++)
		mach_port_deallocate(self, thArray[i]);
	
	vm_deallocate(self, (vm_address_t)thArray, sizeof(thread_t) * thCnt);
	
	if (KERN_SUCCESS != err)
		return err;
	
	ut += tInfo.user_time.seconds + tInfo.user_time.microseconds / 1000000.0;
	st += tInfo.system_time.seconds + tInfo.system_time.microseconds / 1000000.0;
	
	if (NULL != userTime)
		*userTime = ut;
	if (NULL != sysTime)
		*sysTime = st;
	if (NULL != percent)
		*percent = p;
	
	return KERN_SUCCESS;
}

kern_return_t TFRSGetTaskMemoryUsage(task_t task,
									 unsigned* realSize,
									 unsigned* virtualSize,
									 double* percent)
{
	struct task_basic_info tInfo;
	struct host_basic_info hInfo;
	struct vm_region_basic_info_64 vmInfo;
	mach_msg_type_number_t tInfoCnt = TASK_BASIC_INFO_COUNT;
	mach_msg_type_number_t hInfoCnt = HOST_BASIC_INFO_COUNT;
	mach_msg_type_number_t vmInfoCnt = VM_REGION_BASIC_INFO_COUNT_64;
	mach_msg_type_number_t hCnt;
	vm_address_t address = GLOBAL_SHARED_TEXT_SEGMENT;
	vm_size_t size, pageSize;
	vm_statistics_data_t vmStat;
	mach_port_t objName;
	host_t thisHost = mach_host_self();
	uint64_t physMem;
	kern_return_t err;
	
	err = task_info(task, TASK_BASIC_INFO, (task_info_t)&tInfo, &tInfoCnt);
	if (KERN_SUCCESS != err)
		return err;
	
	err = host_info(thisHost, HOST_BASIC_INFO, (host_info_t)&hInfo, &hInfoCnt);
	if (KERN_SUCCESS != err)
		return err;
	
	err = vm_region_64(task,
					   &address,
					   &size,
					   VM_REGION_BASIC_INFO,
					   (vm_region_info_t)&vmInfo,
					   &vmInfoCnt,
					   &objName);
	if (KERN_SUCCESS != err)
		return err;
	
	if (vmInfo.reserved)
		tInfo.virtual_size -= (SHARED_DATA_REGION_SIZE + SHARED_TEXT_REGION_SIZE);
	
	host_page_size(thisHost, &pageSize);
	hCnt = sizeof(vm_statistics_data_t)/sizeof(integer_t);
	
	err = host_statistics(thisHost, HOST_VM_INFO, (host_info_t)&vmStat, &hCnt);
	if (KERN_SUCCESS != err)
		return err;
	
	physMem = vmStat.active_count +
			  vmStat.inactive_count +
			  vmStat.wire_count +
			  vmStat.free_count;
	physMem *= (uint64_t)pageSize;
	
	if (NULL != realSize)
		*realSize = tInfo.resident_size;
	if (NULL != virtualSize)
		*virtualSize = tInfo.virtual_size;
	if (NULL != percent)
		*percent = (double)tInfo.resident_size / physMem;
	
	return KERN_SUCCESS;
}