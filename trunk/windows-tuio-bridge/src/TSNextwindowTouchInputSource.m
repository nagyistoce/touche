//
//  TSNextwindowTouchInputSource.m
//  TouchsmartTUIO
//
//  Created by Georg Kaindl on 27/2/09.
//
//  Copyright (C) 2009 Georg Kaindl
//
//  This file is part of Touchsmart TUIO.
//
//  Touchsmart TUIO is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as
//  published by the Free Software Foundation, either version 3 of
//  the License, or (at your option) any later version.
//
//  Touchsmart TUIO is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public
//  License along with Touchsmart TUIO. If not, see <http://www.gnu.org/licenses/>.
//

#import "TSNextwindowTouchInputSource.h"

#import "TFBlob.h"
#import "TFBlobPoint.h"
#import "TFBlobLabel.h"
#import "TFScreenPreferencesController.h"


// TODO: have a look at the built-in Kalman filtering

static HMODULE _dllHandle = NULL;

#define	DLL_NAME				("NWMultiTouch.dll")
#define NWAPI(funcName, ...)	((GetProcAddress(_dllHandle, (funcName)))(__VA_ARGS__))

// convenience macros for locking Windows semaphores
#define	LOCK(semaphore)		(WaitForSingleObject(semaphore, INFINITE))
#define UNLOCK(semaphore)	(ReleaseSemaphore(semaphore, 1, NULL))

typedef struct _TSNextwindowTouchDevice {
	DWORD	deviceID;
	DWORD	lastPacketID;
	DWORD	lastTouches;
	DWORD	lastGhostTouches;
	DWORD	lastDeviceStatus;
	
	NWDeviceInfo	deviceInfo;
	
	HANDLE	lock;
	
	struct _TSNextwindowTouchDevice* next;
	struct _TSNextwindowTouchDevice* prev;
} TSNextwindowTouchDevice;

static TSNextwindowTouchInputSource* _singleton = nil;

static TSNextwindowTouchDevice* _touchDevices = NULL;
static HANDLE _touchDevicesLock = NULL;

static TSNextwindowTouchDevice* _currentDevice = NULL;

static BOOL _nextwindowShuttingDown = NO;
	 
void __stdcall TSNWOnConnectHandler(DWORD deviceID);
void __stdcall TSNWOnDisconnectHandler(DWORD deviceID);
void __stdcall TSNWMultiTouchDataCallback(DWORD deviceID,
										  DWORD deviceStatus,
										  DWORD packetID,
										  DWORD touches,
										  DWORD ghostTouches);

TSNextwindowTouchDevice* TSNWCreateDeviceStruct(DWORD deviceID);
void TSNWReleaseDeviceStruct(DWORD deviceID);
void TSNWReleaseAllDeviceStructs();
TSNextwindowTouchDevice* TSNWFindDeviceStructByID(DWORD deviceID);
void TSNWLogDevice(TSNextwindowTouchDevice* device);
void TSNWLogAllDevices(TSNextwindowTouchDevice* firstDevice);
BOOL TSNWConnectToDevice(DWORD deviceID);

@interface TSNextwindowTouchInputSource (PrivateMethods)
- (id)_initPrivate;

- (void)_handleCurrentDeviceChanged;

- (const NWDisplayInfo*)_infoForDisplayWithNumber:(NSInteger)displayNo;
- (NSInteger)_numDisplays;
- (void)_logDisplay:(const NWDisplayInfo*)displayInfo;
- (void)_logAllDisplays;
@end

@implementation TSNextwindowTouchInputSource

+ (void)initialize
{
	static BOOL initialized = NO;
	
	if (initialized)
		return;
	
	initialized = YES;
	
	if (NULL == _dllHandle)
		_dllHandle = LoadLibrary("NWMultiTouch.dll");
	
	if (NULL == _dllHandle)
		NSLog(@"DLL WARNING!: %s could not be loaded!\n", DLL_NAME);
	
	_touchDevicesLock = CreateSemaphore(NULL, 1, 1, NULL);
}

+ (void)cleanUp
{	
	[_singleton release];
	_singleton = nil;
	
	if (NULL != _dllHandle) {
		FreeLibrary(_dllHandle);
		_dllHandle = NULL;
	}
	
	if (NULL != _touchDevicesLock) {
		CloseHandle(_touchDevicesLock);
		_touchDevicesLock = NULL;
	}
}

+ (id)sharedSource
{	
	if (nil == _singleton)
		_singleton = [[self alloc] _initPrivate];
	
	return _singleton;
}

- (id)_initPrivate
{	
	if (nil != _singleton)
		return _singleton;
	
	if (nil != (self = [super init])) {
		_displayInfoDict = [[NSMutableDictionary alloc] init];
		
		NWAPI("SetConnectEventHandler", TSNWOnConnectHandler);
		NWAPI("SetDisconnectEventHandler", TSNWOnDisconnectHandler);
				
		NSInteger i;
		NWDisplayInfo displayInfo;
		int numDisplays = NWAPI("GetConnectedDisplayCount");
		
		for (i=0; i < numDisplays; i++) {
			NWAPI("GetConnectedDisplayInfo", i, &displayInfo);
			NSData* infoData = [NSData dataWithBytes:&displayInfo length:sizeof(NWDisplayInfo)];
			[_displayInfoDict setObject:infoData forKey:[NSNumber numberWithInt:displayInfo.deviceNo]];			
		}
		
#if defined(__DEBUG__)
		[self _logAllDisplays];
#endif
		
		DWORD numDevices = NWAPI("GetConnectedDeviceCount");
		for (i=0; i < numDevices; i++) {
			DWORD deviceID = NWAPI("GetConnectedDeviceID", i);
			TSNWConnectToDevice(deviceID);
		}
	}
	
	return self;
}

- (id)init
{
	return [[[self class] sharedSource] retain];
}

- (void)dealloc
{	
	_nextwindowShuttingDown = YES;
	
	NWAPI("SetConnectEventHandler", NULL);
	NWAPI("SetDisconnectEventHandler", NULL);

	_currentDevice = NULL;
	
	LOCK(_touchDevicesLock);
		for (TSNextwindowTouchDevice* d = _touchDevices; NULL != d; d = d->next) {
			LOCK(d->lock);
				NWAPI("CloseDevice", d->deviceID);
			UNLOCK(d->lock);
		}
	UNLOCK(_touchDevicesLock);
	
	TSNWReleaseAllDeviceStructs();
		
	[_displayInfoDict release];
	_displayInfoDict = nil;
	
	[super dealloc];
	
	_nextwindowShuttingDown = NO;
}

- (BOOL)isReceivingTouchData
{
	BOOL rv = NO;
	
	if (NULL != _currentDevice) {
		rv = (DS_DISCONNECTED != _currentDevice->lastDeviceStatus);}
	
	return rv;
}

- (NSArray*)currentLabelizedTouches
{
	DWORD lastTouches = 0;
	NSMutableArray* touches = nil;
	
	// look if our device changed (necessary to do it here, since we can't call objc from a DLL callback
	// directly)
	if ((void*)_lastDevice != (void*)_currentDevice)
		[self _handleCurrentDeviceChanged];
	_lastDevice = (void*)_currentDevice;
	
	if (NULL != _currentDevice) {
		LOCK(_currentDevice->lock);
			if (DS_TOUCH_INFO == _currentDevice->lastDeviceStatus &&
				0 < (lastTouches = _currentDevice->lastTouches)) {
				
				NSUInteger ti;
				successCode_t sc;
				NWTouchPoint pt;
				float displayHeight = [[TFScreenPreferencesController screen] frame].size.height;
				DWORD deviceID = _currentDevice->deviceID;
				DWORD packetID = _currentDevice->lastPacketID;
				touches = [NSMutableArray arrayWithCapacity:MAX_TOUCHES];
				
				for (ti = 0; ti < MAX_TOUCHES; ti++) {
					if (lastTouches & (1 << ti)) {
						sc = NWAPI("GetTouch", deviceID, packetID, &pt, (1 << ti), 0);
												
						// we only report touch down and touch move events, since touch up events
						// are already handled by our labelizer and TUIO generation
						if (SUCCESS == sc &&
							(TE_TOUCH_DOWN == pt.touchEventType ||
							 TE_TOUCHING == pt.touchEventType)) {
						
							TFBlob* blob = [TFBlob blob];
							blob.center.x = pt.touchPos.x;
							blob.center.y = displayHeight - pt.touchPos.y; // y needs to be inverted
							blob.label = [TFBlobLabel labelWithInteger:ti];
							
							[touches addObject:blob];
						}
					}
				}
			}
		UNLOCK(_currentDevice->lock);
	}
	
	return touches;
}

- (void)_handleCurrentDeviceChanged
{
	NSDictionary* infoDict = nil;
	
	if (NULL != _currentDevice) {
		LOCK(_currentDevice->lock);
			infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
						[NSString stringWithString:NSLocalizedString(@"NextwindowCompatibleDevice", @"NextwindowCompatibleDevice")],
							kTISSenderName,
						[NSString stringWithFormat:@"%d", _currentDevice->deviceInfo.productID],
							kTISSenderProductID,
						[NSString stringWithFormat:@"%d.%d",
							_currentDevice->deviceInfo.firmwareVersionMajor,
							_currentDevice->deviceInfo.firmwareVersionMinor],
							kTISSenderFirmwareVersion,
						[NSString stringWithFormat:@"%d", _currentDevice->deviceInfo.modelNumber],
							kTISSenderModel,
						[NSString stringWithFormat:@"%d", _currentDevice->deviceInfo.serialNumber],
							kTISSenderSerialNumber,
						nil];
		UNLOCK(_currentDevice->lock);
	}
	
	[_senderInfoDict release];
	_senderInfoDict = [infoDict retain];
	
	if ([delegate respondsToSelector:@selector(touchInputSource:senderInfoDidChange:)])
		[delegate touchInputSource:self senderInfoDidChange:infoDict];
}

- (const NWDisplayInfo*)_infoForDisplayWithNumber:(NSInteger)displayNo
{
	const NWDisplayInfo* displayInfo = NULL;
	NSData* data = [_displayInfoDict objectForKey:[NSNumber numberWithInt:displayNo]];
	if (nil != data)
		displayInfo = (const NWDisplayInfo*)[data bytes];
	
	return displayInfo;
}

- (NSInteger)_numDisplays
{
	return [_displayInfoDict count];
}

- (void)_logDisplay:(const NWDisplayInfo*)displayInfo
{	
	printf(
		"DeviceNo: %d%s\n"
		"DeviceName: %s\n"
		"DisplayRect: (%.2f, %.2f), (%.2f, %.2f)\n"
		"DisplayWorkRect: (%.2f, %.2f), (%.2f, %.2f)\n",
		displayInfo->deviceNo,
		(displayInfo->isPrimary ? " [Primary]" : ""),
		displayInfo->deviceName,
		displayInfo->displayRect.left, displayInfo->displayRect.top,
		displayInfo->displayRect.right, displayInfo->displayRect.bottom,
		displayInfo->displayWorkRect.left, displayInfo->displayWorkRect.top,
		displayInfo->displayWorkRect.right, displayInfo->displayWorkRect.bottom
	);	
}

- (void)_logAllDisplays
{
	for (id key in [_displayInfoDict allKeys]) {
		NSData* data = [_displayInfoDict objectForKey:key];
		const NWDisplayInfo* displayInfo = (const NWDisplayInfo*)[data bytes];
		[self _logDisplay:displayInfo];
		printf("----------------------\n");
	}
}

@end

void __stdcall TSNWOnConnectHandler(DWORD deviceID)
{
	TSNWConnectToDevice(deviceID);
}

void __stdcall TSNWOnDisconnectHandler(DWORD deviceID)
{
	TSNWReleaseDeviceStruct(deviceID);
}

void __stdcall TSNWMultiTouchDataCallback(DWORD deviceID,
										  DWORD deviceStatus,
										  DWORD packetID,
										  DWORD touches,
										  DWORD ghostTouches)
{	
	if (_nextwindowShuttingDown)
		return;
	
	TSNextwindowTouchDevice* device = TSNWFindDeviceStructByID(deviceID);
		
	if (NULL != device) {
		LOCK(device->lock);
			device->lastDeviceStatus = deviceStatus;
			device->lastPacketID = packetID;
			device->lastTouches = touches;
			device->lastGhostTouches = ghostTouches;
		UNLOCK(device->lock);
	}	
}

BOOL TSNWConnectToDevice(DWORD deviceID)
{	
	successCode_t result = NWAPI("OpenDevice", deviceID, TSNWMultiTouchDataCallback);
	
	if (SUCCESS == result) {
		TSNextwindowTouchDevice* device = TSNWCreateDeviceStruct(deviceID);
	
		// if the firmware is larger than or equal to 2.98, we try slopesmode, otherwise,
		// we fall back to regular multitouch mode (which is less accurate)
		DWORD modeResult = SUCCESS - 1;
		if (device->deviceInfo.firmwareVersionMajor >= 2 ||
			(device->deviceInfo.firmwareVersionMajor == 2 && device->deviceInfo.firmwareVersionMinor >= 98))
			modeResult = NWAPI("SetReportMode", deviceID, RM_SLOPESMODE);
		
		if (SUCCESS != modeResult)
			modeResult = NWAPI("SetReportMode", deviceID, RM_MULTITOUCH);
		
		// TODO: if not successful in setting any report mode, report an error.
				
		if (NULL == _currentDevice)
			_currentDevice = device;
		
#if defined(__DEBUG__)
		TSNWLogDevice(device);
#endif
	} else {
		// TODO: proper error handling
		fprintf(stderr,
				"connecting to Nextwindow device with ID %d failed with code: %d\n", deviceID, result);
	}
	
	return (SUCCESS == result);
}

TSNextwindowTouchDevice* TSNWCreateDeviceStruct(DWORD deviceID)
{
	TSNextwindowTouchDevice* d = (TSNextwindowTouchDevice*)malloc(sizeof(TSNextwindowTouchDevice));
	
	if (NULL != d) {
		d->deviceID = deviceID;
		d->lastPacketID = -1;
		d->lastTouches = 0;
		d->lastGhostTouches = 0;
		d->lastDeviceStatus = -1;
		
		d->lock = CreateSemaphore(NULL, 1, 1, NULL);
		
		NWAPI("GetTouchDeviceInfo", deviceID, &d->deviceInfo);
		
		LOCK(_touchDevicesLock);
			// insert into linked list
			d->next = _touchDevices;
			d->prev = NULL;
			_touchDevices = d;
		UNLOCK(_touchDevicesLock);
	}
	
	return d;
}

void TSNWReleaseDeviceStruct(DWORD deviceID)
{
	TSNextwindowTouchDevice* d = TSNWFindDeviceStructByID(deviceID);
	
	if (NULL != d) {
		if (_currentDevice == d) {
			_currentDevice = NULL;
			
			// TODO: report this as an error somehow
		}
		
		LOCK(_touchDevicesLock);
			if (_touchDevices == d)
				_touchDevices = d->next;
		
			// remove from linked list
			if (NULL != d->prev)
				d->prev->next = d->next;
			if (NULL != d->next)
				d->next->prev = d->prev;
		UNLOCK(_touchDevicesLock);
		
		CloseHandle(d->lock);
		
		free(d);
	}
}

void TSNWReleaseAllDeviceStructs()
{
	LOCK(_touchDevicesLock);
		TSNextwindowTouchDevice* d = _touchDevices;
		_touchDevices = NULL;
		_currentDevice = NULL;
		
		while (NULL != d) {
			TSNextwindowTouchDevice* n = d->next;
			CloseHandle(d->lock);
			free(d);
			d = n;
		}
	UNLOCK(_touchDevicesLock);
}

TSNextwindowTouchDevice* TSNWFindDeviceStructByID(DWORD deviceID)
{
	TSNextwindowTouchDevice* foundDevice = NULL;
	
	LOCK(_touchDevicesLock);
		for (TSNextwindowTouchDevice* d = _touchDevices; NULL != d; d = d->next)
			if (d->deviceID == deviceID) {
				foundDevice = d;
				break;
			}
	UNLOCK(_touchDevicesLock);
	
	return foundDevice;
}

void TSNWLogDevice(TSNextwindowTouchDevice* device)
{
	if (NULL != device) {
		LOCK(device->lock);
			const NWDeviceInfo* d = &device->deviceInfo;
			
			printf(
				 "SerialNumber: %d%s\n"
				 "ModelNumber: %d\n"
				 "ProductID: %d\n"
				 "VendorID: %d\n"
				 "FirmwareVersionMajor: %d\n"
				 "FirmwareVersionMinor: %d\n",
				 d->serialNumber,
				 (_currentDevice == device ? " [Currently used device]" : ""),
				 d->modelNumber,
				 d->productID,
				 d->vendorID,
				 d->firmwareVersionMajor,
				 d->firmwareVersionMinor
			);
		UNLOCK(device->lock);
	}	
}

void TSNWLogAllDevices(TSNextwindowTouchDevice* firstDevice)
{
	LOCK(_touchDevicesLock);
		for (TSNextwindowTouchDevice* d = _touchDevices; NULL != d; d = d->next) {
			TSNWLogDevice(d);
			printf("----------------------\n");
		}
	UNLOCK(_touchDevicesLock);
}
