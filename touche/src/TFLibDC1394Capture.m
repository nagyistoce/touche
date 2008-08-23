//
//  TFLibDC1394Capture.m
//  Touché
//
//  Created by Georg Kaindl on 13/5/08.
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
//

#import "TFLibDC1394Capture.h"
#import "TFLibDC1394Capture+CVPixelBufferFromDc1394Frame.h"

#import "TFIncludes.h"

#define NUM_DMA_BUFFERS					(10)
#define	SLEEP_ON_ERROR_INTERVAL			((NSTimeInterval)0.0015)
#define MAX_FEATURE_KEY					(4)

static NSMutableDictionary* _allocatedTFLibDc1394CaptureObjects = nil;

@interface TFLibDC1394Capture (NonPublicMethods)
+ (BOOL)_camera:(dc1394camera_t*)camera supportsResolution:(CGSize)resolution;
- (void)_freeCamera;
+ (NSString*)_displayNameForCamera:(dc1394camera_t*)camera;
- (dc1394feature_t)_featureFromKey:(NSInteger)featureKey;
+ (NSArray*)_supportedVideoModesForFrameSize:(CGSize)frameSize forCamera:(dc1394camera_t*)cam error:(NSError**)error;
- (NSArray*)_supportedVideoModesForFrameSize:(CGSize)frameSize error:(NSError**)error;
- (void)_setupCapture:(NSValue*)errPointer;
- (void)_stopCapture:(NSValue*)errPointer;
- (void)_videoCaptureThread;
@end

@implementation TFLibDC1394Capture

+ (void)initialize
{
	_allocatedTFLibDc1394CaptureObjects = [[NSMutableDictionary alloc] init];
}

- (void)dealloc
{
	[_thread cancel];
	@synchronized(_threadLock) {
		[_thread release];
		_thread = nil;
	}
	
	[_threadLock release];
	_threadLock = nil;

	[self _freeCamera];

	if (NULL != _dc) {
		dc1394_free(_dc);
		_dc = NULL;
	}	

	[super dealloc];
}

- (id)initWithCameraUniqueId:(NSNumber*)uid
{
	return [self initWithCameraUniqueId:uid error:nil];
}

- (id)initWithCameraUniqueId:(NSNumber*)uid error:(NSError**)error
{
	if (!(self = [super init])) {
		[self release];
		return nil;
	}

	if (nil == uid)
		uid = [[self class] defaultCameraUniqueId];
	
	if (nil == uid) {
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorDc1394NoDeviceFound
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFDc1394NoDeviceErrorDesc", @"TFDc1394NoDeviceErrorDesc"),
												NSLocalizedDescriptionKey,
											   TFLocalizedString(@"TFDc1394NoDeviceErrorReason", @"TFDc1394NoDeviceErrorReason"),
												NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFDc1394NoDeviceErrorRecovery", @"TFDc1394NoDeviceErrorRecovery"),
												NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
												NSStringEncodingErrorKey,
											   nil]];

		[self release];
		return nil;
	}
	
	_dc = dc1394_new();
	if (NULL == _dc) {
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorDc1394LibInstantiationFailed
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFDc1394LibInstantiationFailedErrorDesc", @"TFDc1394LibInstantiationFailedErrorDesc"),
												NSLocalizedDescriptionKey,
											   TFLocalizedString(@"TFDc1394LibInstantiationFailedErrorReason", @"TFDc1394LibInstantiationFailedErrorReason"),
												NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFDc1394LibInstantiationFailedErrorRecovery", @"TFDc1394LibInstantiationFailedErrorRecovery"),
												NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
												NSStringEncodingErrorKey,
											   nil]];

		[self release];
		return nil;
	}
	
	_currentFrameRate = DC1394_FRAMERATE_30;
	
	if (![self setCameraToCameraWithUniqueId:uid error:error]) {
		[self release];
		return nil;
	}
	
	_threadLock = [[NSLock alloc] init];
		
	if (NULL != error)
		*error = nil;
	
	return self;
}

- (void)_freeCamera
{
	if (NULL == _camera)
		return;

	if ([self isCapturing])
		[self stopCapturing:NULL];
		
	if (NULL != _camera) {
		NSNumber* guid = [NSNumber numberWithUnsignedLongLong:_camera->guid];
		
		@synchronized(self) {
			dc1394_camera_free(_camera);
			_camera = NULL;
		}
					
		@synchronized(_allocatedTFLibDc1394CaptureObjects) {
			[_allocatedTFLibDc1394CaptureObjects removeObjectForKey:guid];
		}
	}
}

- (BOOL)setCameraToCameraWithUniqueId:(NSNumber*)uid error:(NSError**)error;
{
	if (NULL != error)
		*error = nil;
		
	if (NULL != _camera && [uid unsignedLongLongValue] == _camera->guid)
		return YES;
	
	BOOL wasRunning = [self isCapturing];

	if (NULL != _camera) {
		[self stopCapturing:NULL];
		[self _freeCamera];
	}
	
	id c;
	@synchronized(_allocatedTFLibDc1394CaptureObjects) {
		c = [_allocatedTFLibDc1394CaptureObjects objectForKey:uid];
	}
	
	if (nil != c) {
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorDc1394CameraAlreadyInUse
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFDc1394CameraInUseErrorDesc", @"TFDc1394CameraInUseErrorDesc"),
											   NSLocalizedDescriptionKey,
											   TFLocalizedString(@"TFDc1394CameraInUseErrorReason", @"TFDc1394CameraInUseErrorReason"),
											   NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFDc1394CameraInUseErrorRecovery", @"TFDc1394CameraInUseErrorRecovery"),
											   NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
											   NSStringEncodingErrorKey,
											   nil]];

		return NO;
	}

	_camera = dc1394_camera_new(_dc, [uid unsignedLongLongValue]);
	if (NULL == _camera) {
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorDc1394CameraCreationFailed
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFDc1394CameraCreationErrorDesc", @"TFDc1394CameraCreationErrorDesc"),
												NSLocalizedDescriptionKey,
											   TFLocalizedString(@"TFDc1394CameraCreationErrorReason", @"TFDc1394CameraCreationErrorReason"),
												NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFDc1394CameraCreationErrorRecovery", @"TFDc1394CameraCreationErrorRecovery"),
												NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
												NSStringEncodingErrorKey,
											   nil]];
	
		return NO;
	}
	
	int i;
	for (i=0; i<=MAX_FEATURE_KEY; i++) {
		dc1394feature_t currentFeature = [self _featureFromKey:i];
		
		dc1394feature_info_t featureInfo;
		featureInfo.id = currentFeature;
		
		if (DC1394_SUCCESS != dc1394_feature_get(_camera, &featureInfo))
			continue;
		
		_supportedFeatures[i] = NO;
		_automodeFeatures[i] = NO;
		
		int j;
		for (j=0; j<featureInfo.modes.num; j++)
			if (DC1394_FEATURE_MODE_MANUAL == featureInfo.modes.modes[j])
				_supportedFeatures[i] = YES;
			else if (DC1394_FEATURE_MODE_AUTO == featureInfo.modes.modes[j])
				_automodeFeatures[i] = YES;
		
		if (_supportedFeatures[i]) {
			_featureMinMax[i][0] = featureInfo.min;
			_featureMinMax[i][1] = featureInfo.max;
		}
		
		// we try setting to 'auto' even if this feature doesn't have a manual mode on this camera
		[self setFeature:i toAutoMode:YES];
	}
	
	// store self, so we can access this camera's properties via class methods, too
	@synchronized(_allocatedTFLibDc1394CaptureObjects) {
		// we go via NSValue because we do not want to be retained ourselves...
		[_allocatedTFLibDc1394CaptureObjects setObject:[NSValue valueWithPointer:self] forKey:uid];
	}
	
	// try setting to the last known framerate if available...
	dc1394_video_set_framerate(_camera, _currentFrameRate);
	
	// get the default video mode and supported framerates for this mode (no error if we fail here...)
	dc1394_video_get_mode(_camera, &_currentVideoMode);
	dc1394_video_get_supported_framerates(_camera, _currentVideoMode, &_frameratesForCurrentVideoMode);
	dc1394_video_get_framerate(_camera, &_currentFrameRate);
	
	BOOL success = YES;
	if (wasRunning)
		success = [self startCapturing:error];
	
	return success;
}

- (BOOL)featureIsMutable:(NSInteger)feature
{
	if (feature <= MAX_FEATURE_KEY)
		return _supportedFeatures[feature];
	
	return NO;
}

- (BOOL)featureSupportsAutoMode:(NSInteger)feature
{
	if (feature <= MAX_FEATURE_KEY)
		return _automodeFeatures[feature];
	
	return NO;
}

- (BOOL)featureInAutoMode:(NSInteger)feature
{
	dc1394feature_t f = [self _featureFromKey:feature];
	dc1394feature_mode_t mode;
	
	if (DC1394_SUCCESS != dc1394_feature_get_mode(_camera, f, &mode))
		return NO;
	
	return (DC1394_FEATURE_MODE_AUTO == mode);
}

- (BOOL)setFeature:(NSInteger)feature toAutoMode:(BOOL)val
{
	dc1394feature_t f = [self _featureFromKey:feature];
	dc1394feature_mode_t mode = val ? DC1394_FEATURE_MODE_AUTO : DC1394_FEATURE_MODE_MANUAL;
	
	return (DC1394_SUCCESS == dc1394_feature_set_mode(_camera, f, mode));
}

- (float)valueForFeature:(NSInteger)feature
{
	dc1394feature_t f = [self _featureFromKey:feature];
	unsigned val;
	
	if (DC1394_SUCCESS != dc1394_feature_get_value(_camera, f, (void*)&val))
		return 0.0f;
	
	return ((float)val - (float)_featureMinMax[feature][0]) /
			((float)_featureMinMax[feature][1] - (float)_featureMinMax[feature][0]);
}

- (BOOL)setFeature:(NSInteger)feature toValue:(float)val
{
	if (!_supportedFeatures[feature])
		return NO;
	
	dc1394feature_t f = [self _featureFromKey:feature];
	dc1394feature_mode_t mode;
	dc1394bool_t isSwitchable;
	
	if (DC1394_SUCCESS != dc1394_feature_is_switchable(_camera, f, &isSwitchable))
		return NO;
	
	if (isSwitchable) {
		dc1394switch_t isSwitched;
		
		if (DC1394_SUCCESS != dc1394_feature_get_power(_camera, f, &isSwitched))
			return NO;
		
		if (DC1394_ON != isSwitched) {
			isSwitched = DC1394_ON;
			
			if (DC1394_SUCCESS != dc1394_feature_set_power(_camera, f, DC1394_ON))
				return NO;
		}
	}
	
	if (DC1394_SUCCESS != dc1394_feature_get_mode(_camera, f, &mode))
		return NO;
	
	if (DC1394_FEATURE_MODE_MANUAL != mode &&
		DC1394_SUCCESS != dc1394_feature_set_mode(_camera, f, DC1394_FEATURE_MODE_MANUAL))
		return NO;
	
	UInt32 newVal = _featureMinMax[feature][0] + val*(_featureMinMax[feature][1]-_featureMinMax[feature][0]);
	
	if (DC1394_SUCCESS != dc1394_feature_set_value(_camera, f, newVal))
		return NO;
	
	return YES;
}

- (dc1394camera_t*)cameraStruct
{
	return _camera;
}

- (NSNumber*)cameraUniqueId
{
	NSNumber* uid = nil;
	
	if (NULL != _camera)
		uid = [NSNumber numberWithUnsignedLongLong:_camera->guid];
	
	return uid;
}

- (NSString*)cameraDisplayName
{
	return [[self class] _displayNameForCamera:_camera];
}

- (BOOL)isCapturing
{
	if (NULL == _camera)
		return NO;
	
	dc1394switch_t status;
	if (DC1394_SUCCESS != dc1394_video_get_transmission(_camera, &status))
		return NO;
	
	return (DC1394_ON == status);
}

- (BOOL)startCapturing:(NSError**)error
{
	NSError* dummy;
	if (NULL != error)
		*error = nil;
	else
		error = &dummy;

	if ([self isCapturing])
		return YES;
	
	[self performSelectorOnMainThread:@selector(_setupCapture:)
						   withObject:[NSValue valueWithPointer:error]
						waitUntilDone:YES];
	
	if (nil != *error)
		return NO;
	
	_thread = [[NSThread alloc] initWithTarget:self
									  selector:@selector(_videoCaptureThread)
										object:nil];
	[_thread start];
	
	return YES;
}

- (BOOL)stopCapturing:(NSError**)error
{
	NSError* dummy;
	if (NULL != error)
		*error = nil;
	else
		error = &dummy;
	
	if (![self isCapturing])
		return YES;
	
	[_thread cancel];

	// wait for the thread to exit
	@synchronized (_threadLock) {
		[self performSelectorOnMainThread:@selector(_stopCapture:)
							   withObject:[NSValue valueWithPointer:error]
							waitUntilDone:YES];
	}
	
	[_thread release];
	_thread = nil;
		
	if (nil != *error)
		return NO;
	
	return YES;
}

- (void)_setupCapture:(NSValue*)errPointer
{
	NSError** error = [errPointer pointerValue];
	
	if (NULL != error)
		*error = nil;

	if (DC1394_SUCCESS != dc1394_capture_setup(_camera,
											   NUM_DMA_BUFFERS,
											   DC1394_CAPTURE_FLAGS_DEFAULT)) {
		
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorDc1394CaptureSetupFailed
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFDc1394CaptureSetupErrorDesc", @"TFDc1394CaptureSetupErrorDesc"),
												NSLocalizedDescriptionKey,
											   TFLocalizedString(@"TFDc1394CaptureSetupErrorReason", @"TFDc1394CaptureSetupErrorReason"),
												NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFDc1394CaptureSetupErrorRecovery", @"TFDc1394CaptureSetupErrorRecovery"),
												NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
												NSStringEncodingErrorKey,
											   nil]];
		
		return;
	}
	
	if (DC1394_SUCCESS != dc1394_video_set_transmission(_camera, DC1394_ON)) {
		dc1394_capture_stop(_camera);
		
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorDc1394SetTransmissionFailed
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFDc1394SetTransmissionErrorDesc", @"TFDc1394SetTransmissionErrorDesc"),
												NSLocalizedDescriptionKey,
											   TFLocalizedString(@"TFDc1394SetTransmissionErrorReason", @"TFDc1394SetTransmissionErrorReason"),
												NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFDc1394SetTransmissionErrorRecovery", @"TFDc1394SetTransmissionErrorRecovery"),
												NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
												NSStringEncodingErrorKey,
											   nil]];
		
		return;
	}
}

- (void)_stopCapture:(NSValue*)errPointer
{
	NSError** error = [errPointer pointerValue];
	
	if (NULL != error)
		*error = nil;
	
	dc1394error_t transmissionErr, captureErr;
	@synchronized(self) {
		transmissionErr = dc1394_video_set_transmission(_camera, DC1394_OFF);
		captureErr = dc1394_capture_stop(_camera);
	}
	
	if (DC1394_SUCCESS != transmissionErr) {
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorDc1394StopTransmissionFailed
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFDc1394StopTransmissionErrorDesc", @"TFDc1394StopTransmissionErrorDesc"),
												NSLocalizedDescriptionKey,
											   TFLocalizedString(@"TFDc1394StopTransmissionErrorReason", @"TFDc1394StopTransmissionErrorReason"),
												NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFDc1394StopTransmissionErrorRecovery", @"TFDc1394StopTransmissionErrorRecovery"),
												NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
												NSStringEncodingErrorKey,
											   nil]];

		return;
	}
	
	if (DC1394_SUCCESS != captureErr) {
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorDc1394StopCapturingFailed
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFDc1394StopCapturingErrorDesc", @"TFDc1394StopCapturingErrorDesc"),
												NSLocalizedDescriptionKey,
											   TFLocalizedString(@"TFDc1394StopCapturingErrorReason", @"TFDc1394StopCapturingErrorReason"),
												NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFDc1394StopCapturingErrorRecovery", @"TFDc1394StopCapturingErrorRecovery"),
												NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
												NSStringEncodingErrorKey,
											   nil]];
		
		return;
	}
}

- (CGSize)frameSize
{
	dc1394video_mode_t currentMode;
	dc1394error_t err = dc1394_video_get_mode(_camera, &currentMode);
	
	if (DC1394_SUCCESS != err)
		return CGSizeMake(0.0f, 0.0f);
	
	switch (currentMode) {
		case DC1394_VIDEO_MODE_160x120_YUV444:
			return CGSizeMake(160.0f, 120.0f);
		case DC1394_VIDEO_MODE_320x240_YUV422:
			return CGSizeMake(320.0f, 240.0f);
		case DC1394_VIDEO_MODE_640x480_YUV411:
		case DC1394_VIDEO_MODE_640x480_YUV422:
		case DC1394_VIDEO_MODE_640x480_RGB8:
		case DC1394_VIDEO_MODE_640x480_MONO8:
		case DC1394_VIDEO_MODE_640x480_MONO16:
			return CGSizeMake(640.0f, 480.0f);
		case DC1394_VIDEO_MODE_800x600_YUV422:
		case DC1394_VIDEO_MODE_800x600_RGB8:
		case DC1394_VIDEO_MODE_800x600_MONO8:
		case DC1394_VIDEO_MODE_800x600_MONO16:
			return CGSizeMake(800.0f, 600.0f);
		case DC1394_VIDEO_MODE_1024x768_YUV422:
		case DC1394_VIDEO_MODE_1024x768_RGB8:
		case DC1394_VIDEO_MODE_1024x768_MONO8:
		case DC1394_VIDEO_MODE_1024x768_MONO16:
			return CGSizeMake(1024.0f, 768.0f);
		case DC1394_VIDEO_MODE_1280x960_YUV422:
		case DC1394_VIDEO_MODE_1280x960_RGB8:
		case DC1394_VIDEO_MODE_1280x960_MONO8:
		case DC1394_VIDEO_MODE_1280x960_MONO16:
			return CGSizeMake(1280.0f, 960.0f);
		case DC1394_VIDEO_MODE_1600x1200_YUV422:
		case DC1394_VIDEO_MODE_1600x1200_RGB8:
		case DC1394_VIDEO_MODE_1600x1200_MONO8:
		case DC1394_VIDEO_MODE_1600x1200_MONO16:
			return CGSizeMake(1600.0f, 1200.0f);
	}
	
	return CGSizeMake(0.0f, 0.0f);
}

- (BOOL)setFrameSize:(CGSize)size error:(NSError**)error
{
	NSArray* modes = [[self class] _supportedVideoModesForFrameSize:size
														  forCamera:_camera
															  error:error];
	if (nil == modes)
		return NO;
	else if ([modes count] <= 0) {
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorDc1394ResolutionChangeFailed
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFDc1394ResolutionChangeErrorDesc", @"TFDc1394ResolutionChangeErrorDesc"),
												NSLocalizedDescriptionKey,
											   [NSString stringWithFormat:TFLocalizedString(@"TFDc1394ResolutionChangeErrorReason", @"TFDc1394ResolutionChangeErrorReason"),
												size.width, size.height],
												NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFDc1394ResolutionChangeErrorRecovery", @"TFDc1394ResolutionChangeErrorRecovery"),
												NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
												NSStringEncodingErrorKey,
											   nil]];

		return NO;
	}
		
	int ranking = INT_MAX;
	NSNumber* bestMode = nil;
	for (NSNumber* mode in modes) {
		if (nil == bestMode || ranking > [self rankingForVideoMode:[mode intValue]]) {
			bestMode = mode;
			ranking = [self rankingForVideoMode:[mode intValue]];
		}
	}

	BOOL wasRunning = [self isCapturing];
	if (wasRunning)
		if (![self stopCapturing:error])
			return NO;

	dc1394error_t err = dc1394_video_set_mode(_camera, [bestMode intValue]);
	if (DC1394_SUCCESS != err) {
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorDc1394ResolutionChangeFailedInternalError
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFDc1394ResolutionChangeInternalErrorDesc", @"TFDc1394ResolutionChangeInternalErrorDesc"),
											   NSLocalizedDescriptionKey,
											   [NSString stringWithFormat:TFLocalizedString(@"TFDc1394ResolutionChangeInternalErrorReason", @"TFDc1394ResolutionChangeInternalErrorReason"),
												size.width, size.height],
											   NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFDc1394ResolutionChangeInternalErrorRecovery", @"TFDc1394ResolutionChangeInternalErrorRecovery"),
											   NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
											   NSStringEncodingErrorKey,
											   nil]];

		return NO;
	}
	
	_currentVideoMode = [bestMode intValue];
	dc1394_video_get_supported_framerates(_camera, _currentVideoMode, &_frameratesForCurrentVideoMode);
	dc1394_video_get_framerate(_camera, &_currentFrameRate);
	
	if (wasRunning) {
		[NSThread sleepForTimeInterval:.5];
		if (![self startCapturing:error])
			return NO;
	}
	
	return YES;
}

- (BOOL)setMinimumFramerate:(NSUInteger)frameRate
{
	if (NULL == _camera)
		return NO;

	dc1394framerate_t minFPS;
	
	if (frameRate <= 15)
		minFPS = DC1394_FRAMERATE_15;
	else if (frameRate <= 30)
		minFPS = DC1394_FRAMERATE_30;
	else if (frameRate <= 60)
		minFPS = DC1394_FRAMERATE_60;
	else if (frameRate <= 120)
		minFPS = DC1394_FRAMERATE_120;
	else if (frameRate <= 240)
		minFPS = DC1394_FRAMERATE_240;
	else
		return NO;
	
	if (_currentFrameRate == minFPS)
		return YES;
	
	// first, try finding a framerate that is equal or larger than minFPS
	int j;
	dc1394framerate_t selectedFPS = minFPS;
	for (selectedFPS; selectedFPS <= DC1394_FRAMERATE_MAX; selectedFPS++)
		for (j=0; j<_frameratesForCurrentVideoMode.num; j++)
			if (selectedFPS == _frameratesForCurrentVideoMode.framerates[j]) {
				if (_currentFrameRate == selectedFPS)
					return YES;
			
				BOOL success = (DC1394_SUCCESS == dc1394_video_set_framerate(_camera, selectedFPS));
				
				if (success)
					_currentFrameRate = selectedFPS;
				
				return success;
			}
	
	// ok, if we didn't find a framerate larger or equal, we search for smaller ones...
	for (selectedFPS = minFPS-1; selectedFPS >= DC1394_FRAMERATE_MIN; selectedFPS--)
		for (j=0; j<_frameratesForCurrentVideoMode.num; j++)
			if (selectedFPS == _frameratesForCurrentVideoMode.framerates[j]) {
				if (_currentFrameRate == selectedFPS)
					return YES;
			
				BOOL success = (DC1394_SUCCESS == dc1394_video_set_framerate(_camera, selectedFPS));
				
				if (success)
					_currentFrameRate = selectedFPS;
				
				return success;
			}
	
	return NO;
}

- (BOOL)supportsFrameSize:(CGSize)size
{
	if (NULL == _camera)
		return NO;

	return [[self class] cameraWithUniqueId:[NSNumber numberWithUnsignedLongLong:_camera->guid]
						 supportsResolution:size];
}

- (void)_videoCaptureThread
{
	dc1394error_t err;
	dc1394video_frame_t* frame;
	
	NSAutoreleasePool* threadPool = [[NSAutoreleasePool alloc] init];

	// while the thread is running, it locks itself. This way, we can find out when the thread has
	// exited...
	@synchronized(_threadLock) {
		while (![_thread isCancelled]) {
			NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		
			@synchronized(self) {
				err = dc1394_capture_dequeue(_camera, DC1394_CAPTURE_POLICY_POLL, &frame);
				
				if (DC1394_SUCCESS != err || NULL == frame) {
					[NSThread sleepForTimeInterval:SLEEP_ON_ERROR_INTERVAL];
					continue;
				}
				
				// if this is not the most recent frame, drop it and continue
				if (0 < frame->frames_behind) {
					dc1394_capture_enqueue(_camera, frame);
					continue;
				}
								
				NSError* error;
				CVPixelBufferRef pixelBuffer = [self pixelBufferWithDc1394Frame:frame error:&error];
				
				if (nil == pixelBuffer)
					continue;
				
				if (_delegateCapabilities.hasDidCaptureFrame) {
					CIImage* image = nil;
					
					if (_delegateCapabilities.hasWantedCIImageColorSpace)
						image = [CIImage imageWithCVImageBuffer:pixelBuffer
														options:[NSDictionary dictionaryWithObject:(id)[delegate wantedCIImageColorSpaceForCapture:self]
																							forKey:kCIImageColorSpace]];
					else
						image = [CIImage imageWithCVImageBuffer:pixelBuffer];
					
		
					[delegate capture:self didCaptureFrame:image];
				}
						
				dc1394_capture_enqueue(_camera, frame);
				CVPixelBufferRelease(pixelBuffer);
			}
			
			[pool release];
		}
	
		// flush the DMA buffers
		dc1394_capture_dequeue(_camera, DC1394_CAPTURE_POLICY_POLL, &frame);
		while (NULL != frame) {
			dc1394_capture_enqueue(_camera, frame);
			dc1394_capture_dequeue(_camera, DC1394_CAPTURE_POLICY_POLL, &frame);
		}
	}
	
	[threadPool release];
}

- (dc1394feature_t)_featureFromKey:(NSInteger)featureKey
{
	switch (featureKey) {
		case TFLibDC1394CaptureFeatureBrightness:
			return DC1394_FEATURE_BRIGHTNESS;
		case TFLibDC1394CaptureFeatureFocus:
			return DC1394_FEATURE_FOCUS;
		case TFLibDC1394CaptureFeatureGain:
			return DC1394_FEATURE_GAIN;
		case TFLibDC1394CaptureFeatureShutter:
			return DC1394_FEATURE_SHUTTER;
	}
	
	return 0;
}

+ (NSString*)_displayNameForCamera:(dc1394camera_t*)camera
{
	if (NULL == camera)
		return nil;
	
	NSString* cameraName = nil;
	if (NULL != camera->model && NULL != camera->vendor)
		cameraName = [NSString stringWithFormat:@"%s (%s)", camera->model, camera->vendor];
	else if (NULL != camera->model)
		cameraName = [NSString stringWithUTF8String:camera->model];
	else if (NULL != camera->vendor)
		cameraName = [NSString stringWithFormat:TFLocalizedString(@"UnknownDV1394CameraWithVendor",
																  @"Unknown camera (%s)"), camera->vendor];
	
	return cameraName;
}

+ (NSDictionary*)connectedCameraNamesAndUniqueIds
{
	dc1394_t* dc = dc1394_new();
	dc1394camera_list_t* list;
	
	if (DC1394_SUCCESS != dc1394_camera_enumerate(dc, &list)) {
		dc1394_free(dc);
		
		return [NSDictionary dictionary];
	}
	
	if (NULL == list || 0 >= list->num) {
		dc1394_camera_free_list(list);
		dc1394_free(dc);
	
		return [NSDictionary dictionary];
	}
	
	NSMutableDictionary* cameras = [NSMutableDictionary dictionary];
	int i;
	for (i=0; i<list->num; i++) {
		@synchronized(_allocatedTFLibDc1394CaptureObjects) {
			if (nil != [_allocatedTFLibDc1394CaptureObjects objectForKey:[NSNumber numberWithUnsignedLongLong:list->ids[i].guid]])
				continue;
		}
		
		dc1394camera_t* cam = dc1394_camera_new(dc, list->ids[i].guid);
		if (NULL == cam)
			continue;

		NSString* camName = [self _displayNameForCamera:cam];
		
		if (nil != camName)
			[cameras setObject:camName forKey:[NSNumber numberWithUnsignedLongLong:list->ids[i].guid]];
		
		dc1394_camera_free(cam);
	}
	
	// now add the currently running cameras as well...
	@synchronized(_allocatedTFLibDc1394CaptureObjects) {
		for (NSNumber* guid in _allocatedTFLibDc1394CaptureObjects) {
			TFLibDC1394Capture* c = (TFLibDC1394Capture*)((NSValue*)[[_allocatedTFLibDc1394CaptureObjects objectForKey:guid] pointerValue]);
			NSString* camName = [c cameraDisplayName];
			if (camName)
				[cameras setObject:camName forKey:guid];
		}
	}
	
	dc1394_camera_free_list(list);
	dc1394_free(dc);

	return [NSDictionary dictionaryWithDictionary:cameras];
}

+ (NSNumber*)defaultCameraUniqueId
{
	dc1394_t* dc = dc1394_new();
	dc1394camera_list_t* list;
	
	if (DC1394_SUCCESS != dc1394_camera_enumerate(dc, &list)) {
		dc1394_free(dc);
	
		return nil;
	}
	
	NSNumber* defaultCamId = nil;
	if (NULL != list && 0 < list->num)
		defaultCamId = [NSNumber numberWithUnsignedLongLong:list->ids[0].guid];
	
	dc1394_camera_free_list(list);
	dc1394_free(dc);
	
	return defaultCamId;
}

+ (CGSize)defaultResolutionForCameraWithUniqueId:(NSNumber*)uid
{
	dc1394_t* dc = NULL;
	dc1394camera_t* cam = NULL;

	if (nil == uid)
		goto errorReturn;
	
	dc1394video_modes_t list;
	TFLibDC1394Capture* c = nil;
	@synchronized(_allocatedTFLibDc1394CaptureObjects) {
		c = (TFLibDC1394Capture*)((NSValue*)[[_allocatedTFLibDc1394CaptureObjects objectForKey:uid] pointerValue]);
	}
	
	if (nil != c) {
		if (DC1394_SUCCESS != dc1394_video_get_supported_modes([c cameraStruct], &list))
			goto errorReturn;
	} else {	
		dc = dc1394_new();
		if (NULL == dc)
			goto errorReturn;
		
		cam = dc1394_camera_new(dc, [uid unsignedLongLongValue]);
		if (NULL == cam)
			goto errorReturn2;
		
		if (DC1394_SUCCESS != dc1394_video_get_supported_modes(cam, &list))
			goto errorReturn3;
	}
	
	dc1394video_mode_t wantedModes[] = {
		DC1394_VIDEO_MODE_320x240_YUV422,
		DC1394_VIDEO_MODE_640x480_RGB8,
		DC1394_VIDEO_MODE_640x480_MONO8,
		DC1394_VIDEO_MODE_640x480_MONO16,
		DC1394_VIDEO_MODE_640x480_YUV422,
		DC1394_VIDEO_MODE_640x480_YUV411,
		DC1394_VIDEO_MODE_160x120_YUV444,
		DC1394_VIDEO_MODE_800x600_RGB8,
		DC1394_VIDEO_MODE_800x600_MONO8,
		DC1394_VIDEO_MODE_800x600_MONO16,
		DC1394_VIDEO_MODE_800x600_YUV422,
		DC1394_VIDEO_MODE_1024x768_RGB8,
		DC1394_VIDEO_MODE_1024x768_MONO8,
		DC1394_VIDEO_MODE_1024x768_MONO16,
		DC1394_VIDEO_MODE_1024x768_YUV422,
		DC1394_VIDEO_MODE_1280x960_RGB8,
		DC1394_VIDEO_MODE_1280x960_MONO8,
		DC1394_VIDEO_MODE_1280x960_MONO16,
		DC1394_VIDEO_MODE_1280x960_YUV422,
		DC1394_VIDEO_MODE_1600x1200_RGB8,
		DC1394_VIDEO_MODE_1600x1200_MONO8,
		DC1394_VIDEO_MODE_1600x1200_MONO16,
		DC1394_VIDEO_MODE_1600x1200_YUV422
	};
	int numModes = 23;
	
	int i, j;
	for (i=0; i<numModes; i++) {
		for (j=0; j<list.num; j++) {
			if (wantedModes[i] == list.modes[j]) {
				dc1394_camera_free(cam);
				dc1394_free(dc);
				
				switch(list.modes[j]) {
					case DC1394_VIDEO_MODE_320x240_YUV422:
						return CGSizeMake(320.0f, 240.0f);
					case DC1394_VIDEO_MODE_640x480_RGB8:
					case DC1394_VIDEO_MODE_640x480_MONO8:
					case DC1394_VIDEO_MODE_640x480_MONO16:
					case DC1394_VIDEO_MODE_640x480_YUV422:
					case DC1394_VIDEO_MODE_640x480_YUV411:
						return CGSizeMake(640.0f, 480.0f);
					case DC1394_VIDEO_MODE_160x120_YUV444:
						return CGSizeMake(160.0f, 120.0f);
					case DC1394_VIDEO_MODE_800x600_RGB8:
					case DC1394_VIDEO_MODE_800x600_MONO8:
					case DC1394_VIDEO_MODE_800x600_MONO16:
					case DC1394_VIDEO_MODE_800x600_YUV422:
						return CGSizeMake(800.0f, 600.0f);
					case DC1394_VIDEO_MODE_1024x768_RGB8:
					case DC1394_VIDEO_MODE_1024x768_MONO8:
					case DC1394_VIDEO_MODE_1024x768_MONO16:
					case DC1394_VIDEO_MODE_1024x768_YUV422:
						return CGSizeMake(1024.0f, 768.0f);
					case DC1394_VIDEO_MODE_1280x960_RGB8:
					case DC1394_VIDEO_MODE_1280x960_MONO8:
					case DC1394_VIDEO_MODE_1280x960_MONO16:
					case DC1394_VIDEO_MODE_1280x960_YUV422:
						return CGSizeMake(1280.0f, 960.0f);
					case DC1394_VIDEO_MODE_1600x1200_RGB8:
					case DC1394_VIDEO_MODE_1600x1200_MONO8:
					case DC1394_VIDEO_MODE_1600x1200_MONO16:
					case DC1394_VIDEO_MODE_1600x1200_YUV422:
						return CGSizeMake(1600.0f, 1200.0f);
				}
			}
		}
	}
	
errorReturn3:
	if (NULL != cam)
		dc1394_camera_free(cam);
errorReturn2:
	if (NULL != dc)
		dc1394_free(dc);
errorReturn:
	return CGSizeMake(0.0f, 0.0f);
}

+ (BOOL)_camera:(dc1394camera_t*)camera supportsResolution:(CGSize)resolution
{
	NSArray* supportedModes = [[self class] _supportedVideoModesForFrameSize:resolution
																   forCamera:camera
																	   error:NULL];
	
	return ([supportedModes count] > 0);
}

+ (BOOL)cameraWithUniqueId:(NSNumber*)uid supportsResolution:(CGSize)resolution
{
	if (nil == uid)
		return NO;
	
	TFLibDC1394Capture* c = nil;
	@synchronized(_allocatedTFLibDc1394CaptureObjects) {
		c = (TFLibDC1394Capture*)((NSValue*)[[_allocatedTFLibDc1394CaptureObjects objectForKey:uid] pointerValue]);
	}
	
	if (nil != c) {
		return [[self class] _camera:[c cameraStruct] supportsResolution:resolution];
	}
	
	dc1394_t* dc = dc1394_new();
	if (NULL == dc)
		return NO;
	
	dc1394camera_t* cam = dc1394_camera_new(dc, [uid unsignedLongLongValue]);
	if (NULL == cam) {
		dc1394_free(dc);
		return NO;
	}

	NSArray* supportedModes = [[self class] _supportedVideoModesForFrameSize:resolution
																   forCamera:cam
																	   error:NULL];
					
	
	dc1394_camera_free(cam);
	dc1394_free(dc);
	
	return ([supportedModes count] > 0);
}

+ (NSArray*)_supportedVideoModesForFrameSize:(CGSize)frameSize forCamera:(dc1394camera_t*)cam error:(NSError**)error
{
	if (NULL != error)
		*error = nil;
	
	dc1394_t* dc;
	
	dc = dc1394_new();
	if (NULL == dc) {
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorDc1394LibInstantiationFailed
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFDc1394LibInstantiationFailedErrorDesc", @"TFDc1394LibInstantiationFailedErrorDesc"),
												NSLocalizedDescriptionKey,
											   TFLocalizedString(@"TFDc1394LibInstantiationFailedErrorReason", @"TFDc1394LibInstantiationFailedErrorReason"),
												NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFDc1394LibInstantiationFailedErrorRecovery", @"TFDc1394LibInstantiationFailedErrorRecovery"),
												NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
												NSStringEncodingErrorKey,
											   nil]];

		goto errorReturn;
	}
	
	dc1394video_modes_t list;
	dc1394error_t err = dc1394_video_get_supported_modes(cam, &list);
	if (DC1394_SUCCESS != err) {
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorDc1394GettingVideoModesFailed
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFDc1394GettingVideoModesErrorDesc", @"TFDc1394GettingVideoModesErrorDesc"),
												NSLocalizedDescriptionKey,
											   TFLocalizedString(@"TFDc1394GettingVideoModesErrorReason", @"TFDc1394GettingVideoModesErrorReason"),
												NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFDc1394GettingVideoModesErrorRecovery", @"TFDc1394GettingVideoModesErrorRecovery"),
												NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
												NSStringEncodingErrorKey,
											   nil]];

		goto errorReturn2;
	}
	
	NSMutableArray* modes = [NSMutableArray array];
	int i;
	for (i=0; i<list.num; i++) {
		if (
			(frameSize.width == 160.0f && frameSize.height == 120.0f &&
			 DC1394_VIDEO_MODE_160x120_YUV444 == list.modes[i])			||
			(frameSize.width == 320.0f && frameSize.height == 240.0f &&
			 DC1394_VIDEO_MODE_320x240_YUV422 == list.modes[i])			||
			(frameSize.width == 640.0f && frameSize.height == 480.0f &&
			 (DC1394_VIDEO_MODE_640x480_YUV411 == list.modes[i] ||
			  DC1394_VIDEO_MODE_640x480_YUV422 == list.modes[i] ||
			  DC1394_VIDEO_MODE_640x480_RGB8 == list.modes[i] ||
			  DC1394_VIDEO_MODE_640x480_MONO8 == list.modes[i] ||
			  DC1394_VIDEO_MODE_640x480_MONO16 == list.modes[i]))		||
			(frameSize.width == 800.0f && frameSize.height == 600.0f &&
			 (DC1394_VIDEO_MODE_800x600_YUV422 == list.modes[i] ||
			  DC1394_VIDEO_MODE_800x600_RGB8 == list.modes[i] ||
			  DC1394_VIDEO_MODE_800x600_MONO8 == list.modes[i] ||
			  DC1394_VIDEO_MODE_800x600_MONO16 == list.modes[i]))		||
			(frameSize.width == 1024.0f && frameSize.height == 768.0f &&
			 (DC1394_VIDEO_MODE_1024x768_YUV422 == list.modes[i] ||
			  DC1394_VIDEO_MODE_1024x768_RGB8 == list.modes[i] ||
			  DC1394_VIDEO_MODE_1024x768_MONO8 == list.modes[i] ||
			  DC1394_VIDEO_MODE_1024x768_MONO16 == list.modes[i]))		||
			(frameSize.width == 1280.0f && frameSize.height == 960.0f &&
			 (DC1394_VIDEO_MODE_1280x960_YUV422 == list.modes[i] ||
			  DC1394_VIDEO_MODE_1280x960_RGB8 == list.modes[i] ||
			  DC1394_VIDEO_MODE_1280x960_MONO8 == list.modes[i] ||
			  DC1394_VIDEO_MODE_1280x960_MONO16 == list.modes[i]))		||
			(frameSize.width == 1600.0f && frameSize.height == 1200.0f &&
			 (DC1394_VIDEO_MODE_1600x1200_YUV422 == list.modes[i] ||
			  DC1394_VIDEO_MODE_1600x1200_RGB8 == list.modes[i] ||
			  DC1394_VIDEO_MODE_1600x1200_MONO8 == list.modes[i] ||
			  DC1394_VIDEO_MODE_1600x1200_MONO16 == list.modes[i]))
			) {
			[modes addObject:[NSNumber numberWithInt:list.modes[i]]];
		}
	}
	
	return [NSArray arrayWithArray:modes];
	
errorReturn2:
	dc1394_free(dc);
errorReturn:
	return nil;
}

@end
