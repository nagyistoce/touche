//
// TFFlashLCSHMEM.h
// Touché
//
// Created by Georg Kaindl on 16/3/09.
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

#include "TFFlashLCSHMEM.h"

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>

#if !defined(WINDOWS)
#include <sys/ipc.h>
#include <sys/shm.h>
#include <mach/mach.h>
#include <mach/mach_time.h>
#endif

#define FLASHLC_SHM_SIZE				(64528)	// This is what Flash always uses as size
#define	FLASHLC_SHM_LISTENERS_OFFSET	(40976)	// Another "magic number"
#define MAX_LISTENER_NAME_LEN			(64)
#define MAX_LISTENER_METHOD_NAME		(64)

#define	PROTOCOL_NAME				("localhost")

#define	WINDOWS_SEMAPHORE_NAME				("MacromediaMutexOmega")
#define WINDOWS_SHMEM_NAME					("MacromediaFMOmega")
#define DARWIN_SEMAPHORE_NAME				("MacromediaSemaphoreDig")
#define	DARWIN_SEMAPHORE_INITIAL_VALUE		(10)

#define	AMF_TYPE_STRING				(0x02)
#define AMF_TYPE_AMF3OBJ			(0x11)
#define AMF3_TYPE_BYTEARRAY			(0x0C)

#define AMF_ENVELOPE_LEN			(16)
#define AMF_ENVELOPE_TIMESTAMP_POS	(8)
#define AMF_ENVELOPE_SIZE_POS		(12)

void _TFLCSLockSemaphore(TFLCSLocalConnection_t* connection);
void _TFLCSUnlockSemaphore(TFLCSLocalConnection_t* connection);

// returns non-zero if the given connection is in a usable state, zero otherwise
int _TFLCSConnectionStructureIsValidForUse(TFLCSLocalConnection_t* connection);

// On Windows, we cannot create the shared memory and semaphore ourselves, because
// we don't know the exact parameters. Therefore, if Flash is not running when we
// try to connect, we'll try again whenever we should send data, until we finally
// manage to connect.
int _TFLCSDelayedConnect(TFLCSLocalConnection_t* connection);

#define	ENSURE_CONNECTION_UP(c, rv)		do { if (!(c)->open && !_TFLCSDelayedConnect((c))) return (rv); } while (0)

u_int32_t _TFLCSKnownDarwinKeys[] = { 0x53414e44, 0 };

TFLCSError_t	TFLCSErrno = TFLCSErrorSuccess;

TFLCSLocalConnection_t* TFLCSConnect(const char* listenerName,
									 const char* listenerMethod,
									 void* shmemKey,
									 void* semaphoreKey)
{
	TFLCSLocalConnection_t* connection = NULL;
	
	if (NULL == listenerName || NULL == listenerMethod ||
		strlen(listenerName) > TFLCS_LISTENER_NAME_MAX_LEN ||
		strlen(listenerMethod) > TFLCS_LISTENER_METHOD_MAX_LEN) {
		TFLCSErrno = TFLCSErrorInvalidArgument;
		return NULL;
	}
	
	connection = (TFLCSLocalConnection_t*)malloc(sizeof(TFLCSLocalConnection_t));
	if (NULL == connection) {
		TFLCSErrno = TFLCSErrorOutOfMemory;
		goto errorReturn;
	}

	connection->open = 0;

#if defined(WINDOWS)
	// initialize the structure
	connection->semaphore = NULL;
	connection->mapFile = NULL;
	connection->mapAddress = NULL;
	connection->data = NULL;
	
	_TFLCSDelayedConnect(connection);
#else
	// initialize the structure
	connection->semaphore = SEM_FAILED;
	connection->shmid = -1;
	connection->data = (char*)-1;
	
	// we don't need a delayed connect on MacOS X, so let's just connect now!
	key_t key;
	char* semName;
	
	if (NULL != shmemKey)
		key = *(key_t*)shmemKey;
	else {
		key_t* guessedKey = TFLCSGuessShmemKey();
		if (NULL != guessedKey)
			key = *(key_t*)guessedKey;
		else {
			TFLCSErrno = TFLCSErrorShmemKeyNotFound;
			goto errorReturn;
		}
	}
	
	if (NULL != semaphoreKey)
		semName = (char*)semaphoreKey;
	else
		semName = DARWIN_SEMAPHORE_NAME;
	
	connection->semaphore = sem_open(semName,
									 O_CREAT,
									 S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH,
									 DARWIN_SEMAPHORE_INITIAL_VALUE);
	if (SEM_FAILED == connection->semaphore) {
		TFLCSErrno = TFLCSErrorSemaphoreCreationFailed;
		goto errorReturn;
	}
	
	if (-1 == (connection->shmid = shmget(key, FLASHLC_SHM_SIZE, 0666 | IPC_CREAT))) {
		TFLCSErrno = TFLCSErrorShmemIDNotFound;
		goto errorReturn;
	}
	
	connection->data = shmat(connection->shmid, NULL, 0);
	if ((char*)-1 == connection->data) {
		TFLCSErrno = TFLCSErrorShmemOpeningFailed;
		goto errorReturn;
	}
	
	connection->open = 1;
	
	// initialize the memory region the way Flash likes it :-)
	connection->data[0] = 1;
	connection->data[4] = 1;
#endif

	strncpy(connection->listenerName, listenerName, TFLCS_LISTENER_NAME_MAX_LEN);
	strncpy(connection->listenerMethod, listenerMethod, TFLCS_LISTENER_METHOD_MAX_LEN);

	return connection;

errorReturn:
	TFLCSDisconnect(connection);
	
	return NULL;
}

void TFLCSDisconnect(TFLCSLocalConnection_t* connection)
{
	if (NULL != connection) {
#if defined(WINDOWS)
		if (NULL != connection->semaphore)
			CloseHandle(connection->semaphore);
		
		if (NULL != connection->mapAddress)
			UnmapViewOfFile(connection->mapAddress);
		
		if (NULL != connection->mapFile)
			CloseHandle(connection->mapFile);
#else
		if (SEM_FAILED != connection->semaphore)
			sem_close(connection->semaphore);
		
		if ((char*)-1 != connection->data)
			(void)shmdt(connection->data);
#endif
		free(connection);
	}
}

void TFLCSChangeListenerName(TFLCSLocalConnection_t* connection, const char* newListenerName)
{
	if (NULL != connection && NULL != newListenerName)
		strncpy(connection->listenerName, newListenerName, TFLCS_LISTENER_NAME_MAX_LEN);
}

void TFLCSChangeMethodName(TFLCSLocalConnection_t* connection, const char* newMethodName)
{
	if (NULL != connection && NULL != newMethodName)
		strncpy(connection->listenerMethod, newMethodName, TFLCS_LISTENER_METHOD_MAX_LEN);
}

int TFLCSConnectionHasConnectedClient(TFLCSLocalConnection_t* connection)
{
	ENSURE_CONNECTION_UP(connection, 0);
	
	int retval = 0;
	
	if (_TFLCSConnectionStructureIsValidForUse(connection)) {
		_TFLCSLockSemaphore(connection);
	
		int c, l = strlen(connection->listenerName);
		char* p = &connection->data[FLASHLC_SHM_LISTENERS_OFFSET];
		
		while (!retval && (char)0 != *p) {
			c = strlen(p) + 1;
			if (0 == strncmp(p, connection->listenerName, l))
				retval = 1;

			p += c;
		}
		
		_TFLCSUnlockSemaphore(connection);
	}
	
	return retval;
}

int TFLCSGetConnectedConnectionNames(TFLCSLocalConnection_t* connection, char* dest, int destLen)
{
	ENSURE_CONNECTION_UP(connection, 0);
	
	int retval = 0;
	
	if (NULL != dest && 0 < destLen && _TFLCSConnectionStructureIsValidForUse(connection)) {
		_TFLCSLockSemaphore(connection);
	
		int c, i=0;
		char* p = &connection->data[FLASHLC_SHM_LISTENERS_OFFSET];
		
		while ((char)0 != *p && destLen > 0) {
			c = strlen(p) + 1;
			if (0 == (i % 3)) {
				strncpy(dest, p, destLen < c ? destLen : c);
				destLen -= c;
				dest += c;
			}
			
			p += c;
			i++;
		}
		
		retval = i/3;
		
		_TFLCSUnlockSemaphore(connection);
	}
	
	return retval;
}

void* TFLCSGuessShmemKey()
{
#if defined(WINDOWS)
	return (void*)WINDOWS_SHMEM_NAME;
#else
	static int found = 0;
	static key_t key;
	
	// first, try our known keys
	int i = 0;
	while(!found && _TFLCSKnownDarwinKeys[i]) {
		if (-1 != shmget(_TFLCSKnownDarwinKeys[i], FLASHLC_SHM_SIZE, 0)) {
			found = 1;
			key = _TFLCSKnownDarwinKeys[i];
		}
			
		i++;
	}
	
	/* // magic numbers for MacOS X 10.5, probably later and earlier versions too, dunno...
	int minid = 0xffff;
	int maxid = 0x500000;
	struct shmid_ds shm_info;
	for (i=minid; !found && i<=maxid; i++) {
		if (shmctl(i, IPC_STAT, &shm_info) < 0)
			continue;
				
		if (FLASHLC_SHM_SIZE == shm_info.shm_segsz) {
			found = 1;
			key = shm_info.shm_perm._key;
		}
	} */

	// if we didn't find anything, set the key to a reasonable guess
	// this is necessary because the shared segment might not exist yet.
	if (!found) {
		key = _TFLCSKnownDarwinKeys[0];
		found = 1;
	}
	
	return &key;
#endif
}

u_int32_t TFLCSGetTickCount()
{
#if defined(WINDOWS)
	return (u_int32_t)GetTickCount();
#else
	static mach_timebase_info_data_t timeBase;
	
	u_int64_t nanos = mach_absolute_time();
	
	if (0 == timeBase.denom) {
		(void)mach_timebase_info(&timeBase);
	}
    
	return (u_int32_t)((nanos * (u_int64_t)timeBase.numer / (u_int64_t)timeBase.denom) / (u_int64_t)1000000);
#endif
}

int TFLCSWriteAMF3Integer(char* buffer, int value, int pos)
{
	if (value < 0) {
		buffer[pos++] = (0x80 | ((value >> 22) & 0xff));
		buffer[pos++] = (0x80 | ((value >> 15) & 0x7f));
		buffer[pos++] = (0x80 | ((value >> 8) & 0x7f));
		buffer[pos++] = (value & 0xff);
	} else if (value <= 0x7f) {
		buffer[pos++] = value;
	} else if (value <= 0x3fff) {
		buffer[pos++] = (0x80 | ((value >> 7) & 0x7f));
		buffer[pos++] = (value & 0x7f);
	} else if (value <= 0x1fffff) {
		buffer[pos++] = (0x80 | ((value >> 14) & 0x7f));
		buffer[pos++] = (0x80 | ((value >> 7) & 0x7f));
		buffer[pos++] = (value & 0x7f);
	} else {
		buffer[pos++] = (0x80 | ((value >> 22) & 0xff));
		buffer[pos++] = (0x80 | ((value >> 15) & 0x7f));
		buffer[pos++] = (0x80 | ((value >> 8) & 0x7f));
		buffer[pos++] = (value & 0xff);
	}
	
	return pos;
}

int TFLCSWriteAMFString(char* buffer, const char * str, int pos)
{
	int len = strlen(str);
	
	buffer[pos++] = AMF_TYPE_STRING;
	buffer[pos++] = 0; // TODO: string length is badly encoded here!
	buffer[pos++] = (char)(len & 0xff);
	
	strcpy((char*)&buffer[pos], str);
	
	pos += len;
	return pos;
}

int TFLCSWriteAMF3ByteArray(char* buffer, const char* bytes, int pos, int len)
{
	// buffer[pos++] = AMF_TYPE_AMF3OBJ;
	buffer[pos++] = AMF3_TYPE_BYTEARRAY; // AMF3_TYPE_BYTE_ARRAY
	
	pos = TFLCSWriteAMF3Integer(buffer, ((len << 1) | 1), pos);
	
	int i=0;
	for(i=0; i<len; i++)
		buffer[pos++] = bytes[i];
	
	return pos;
}

int TFLCSWriteLCAMFEnvelopeHeader(TFLCSLocalConnection_t* connection)
{
	if (NULL == connection)
		return 0;

	u_int32_t* timestamp = (u_int32_t*)&connection->data[AMF_ENVELOPE_TIMESTAMP_POS];
	
	int pos = AMF_ENVELOPE_LEN;
	// check timestamp and size
	
	memset(connection->data, 0, AMF_ENVELOPE_LEN);
	
	connection->data[0] = 1;
	connection->data[4] = 1;
	
	*timestamp = TFLCSGetTickCount();
	
	// write connection name
	pos = TFLCSWriteAMFString(connection->data, connection->listenerName, pos);
	// write protocol
	pos = TFLCSWriteAMFString(connection->data, PROTOCOL_NAME, pos);
	
	// I have no idea what this is, but we apparently need it...
	char weirdBytes[] = {
		0x01, 0x01, 0x01, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0x40, 0x24, 0, 0, 0, 0, 0, 0, 0, 0x40, 0x08, 0, 0,
		0, 0, 0, 0};
	int i;
	for (i=0; i<31; i++)
		connection->data[pos++] = weirdBytes[i];
	
	// write method name
	pos = TFLCSWriteAMFString(connection->data, connection->listenerMethod, pos);

	return pos;
}

int TFLCSWriteLCAMFEnvelopeTrailer(TFLCSLocalConnection_t* connection, int pos)
{
	if (NULL == connection)
		return pos;
	
	u_int32_t* size = (u_int32_t*)&connection->data[AMF_ENVELOPE_SIZE_POS];

	//pos = writeAMF3ByteArray(buffer, msg, pos, strlen(msg));
	*size = pos-16;

	return pos;
}

int TFLCSSendByteArray(TFLCSLocalConnection_t* connection, const char* bytes, int len)
{
	ENSURE_CONNECTION_UP(connection, 0);
	
	if (NULL == bytes || 0 == len || !_TFLCSConnectionStructureIsValidForUse(connection)) {
		TFLCSErrno = TFLCSErrorInvalidArgument;
		return 0;
	}
	
	_TFLCSLockSemaphore(connection);
	
	int pos = TFLCSWriteLCAMFEnvelopeHeader(connection);
	pos = TFLCSWriteAMF3ByteArray(connection->data, bytes, pos, len);
	(void)TFLCSWriteLCAMFEnvelopeTrailer(connection, pos);
	
	_TFLCSUnlockSemaphore(connection);
	
	return 1;
}

void TFLCSDumpMemory(char* buffer, int offset, int size)
{
	int i = 0;
	int c = 0;
	char b;
	
	while (i < size) {
		while ((c < 16) && (i+c < size)) {
			b = buffer[offset+i+c];
			printf("%X%X ", b/16 & 0x0f, b & 0x0f );
			c++;
		}
		
		while (c++ < 16)
			printf("   ");
		
		c = 0;
		
		while ((c < 16) && (i+c < size)) {
			b = buffer[offset+i+c];
			if (b > 31)
				printf("%c", (char)b);
			else
				printf(".");
			c++;
		}
		
		i += 16;
		c = 0;
		printf("\n");
	}
}

void _TFLCSLockSemaphore(TFLCSLocalConnection_t* connection)
{
	if (NULL != connection) {
#if defined(WINDOWS)
		if (NULL != connection->semaphore)
			WaitForSingleObject(connection->semaphore, INFINITE);
#else
		if (SEM_FAILED != connection->semaphore)
			sem_wait(connection->semaphore);
#endif
	}
}

void _TFLCSUnlockSemaphore(TFLCSLocalConnection_t* connection)
{
	if (NULL != connection) {
#if defined(WINDOWS)
		if (NULL != connection->semaphore)
			ReleaseMutex(connection->semaphore);
#else
		if (SEM_FAILED != connection->semaphore)
			sem_post(connection->semaphore);
#endif
	}
}

int _TFLCSConnectionStructureIsValidForUse(TFLCSLocalConnection_t* connection)
{
	return 	(NULL != connection
		&& 0 != connection->open
#if defined(WINDOWS)
		&& NULL != connection->semaphore
		&& NULL != connection->mapFile
		&& NULL != connection->mapAddress
		&& NULL != connection->data
#else
		&& SEM_FAILED != connection->semaphore
		&& (char*)-1 != connection->data
#endif
	);
}

int _TFLCSDelayedConnect(TFLCSLocalConnection_t* connection)
{
#if defined(WINDOWS)
	if (NULL == connection)
		return 0;
	if (connection->open)
		return 1;
	
	if (NULL == (connection->semaphore = OpenMutex(MUTEX_ALL_ACCESS,
												   FALSE,
												   WINDOWS_SEMAPHORE_NAME))) {
		TFLCSErrno = TFLCSErrorSemaphoreCreationFailed;
		goto errorReturn;
	}
	
	if (NULL == (connection->mapFile = OpenFileMapping(FILE_MAP_ALL_ACCESS,
													   FALSE,
													   WINDOWS_SHMEM_NAME))) {
		TFLCSErrno = TFLCSErrorShmemIDNotFound;
		goto errorReturn;
	}
	
	if (NULL == (connection->mapAddress = MapViewOfFile(connection->mapFile,
														FILE_MAP_ALL_ACCESS,
														0,
														0,
														0))) {
		TFLCSErrno = TFLCSErrorShmemOpeningFailed;
		goto errorReturn;
	}
	
	connection->data = (char*)connection->mapAddress;
	connection->open = 1;

errorReturn:
#endif

	return connection->open;
}
