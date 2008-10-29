//
//  TFTrackingPipeline.m
//  Touché
//
//  Created by Georg Kaindl on 5/1/08.
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

#import <QuartzCore/QuartzCore.h>

#import "TFTrackingPipeline.h"
#import "TFTrackingPipeline+QTInputAdditions.h"
#import "TFTrackingPipeline+LibDc1394InputAdditions.h"

#import "TFIncludes.h"
#import "TFThreadMessagingQueue.h"
#import "TFScreenPreferencesController.h"
#import "TFBlobQuicktimeKitInputSource.h"
#import "TFFilterChain.h"
#import "TFCameraInputFilterChain.h"
#import "TFCIColorInversionFilter.h"
#import "TFCIThresholdFilter.h"
#import "TFCIBackgroundSubtractionFilter.h"
#import "TFCIGaussianBlurFilter.h"
#import "TFCIContrastStretchFilter.h"
#import "TFCIGrayscalingFilter.h"
#import "TFCIMorphologicalOpenWith3x3ShapeFilter.h"
#import "TFCIMorphologicalCloseWith3x3ShapeFilter.h"
#import "TFRGBA8888BlobDetector.h"
#import "TFBlobLabelizer.h"
#import "TFBlobSimpleDistanceLabelizer.h"
#import "TFCamera2ScreenCoordinatesConverter.h"
#import "TFInverseTextureMappingConverter.h"
#import "TFBlobWiiRemoteInputSource.h"
#import "TFBlobLibDc1394InputSource.h"
#import "TFBlobCameraInputSource.h"
#import "TFOpenCVContourBlobDetector.h"


#define BLOB_PROCESSING_THREAD_PRIORITY	(1.0)

@class TFTrackingPipelineView, TFBlobTrackingView;

NSInteger TFTrackingPipelineInputResolutionLowest = 1;
NSInteger TFTrackingPipelineInputResolutionHighest = 7;

static NSString* trackingInputMethodQTCameraKey = @"trackingInputMethodQTCameraKey";
static NSString* trackingInputMethodWiiRemoteKey = @"trackingInputMethodWiiRemoteKey";
static NSString* trackingInputMethodLibDc1394Key = @"trackingInputMethodLibDc1394Key";

static NSString* trackingInputMethodPrefKey = @"trackingInputMethodPrefKey";
static NSString* trackingCalibrationPrefKeyTemplate = @"trackingCalibration_%d_%@_%@";

static TFTrackingPipeline*        tFTrackingPipelineSingleton = nil;

enum {
	TFTrackingPipelineCalibrationFine = 0,
	TFTrackingPipelineCalibrationRecommended = 1,
	TFTrackingPipelineCalibrationRequired = 2
};

@interface TFTrackingPipeline	(NonPublicMethods)
- (id)_initPrivate;
- (void)_bindToPreferences:(id)object keyPaths:(NSArray*)paths;
- (void)_checkAndReportCalibrationProblemsToDelegate:(BOOL)isResolutionChange;
- (void)_unbindFromPreferences:(BOOL)alsoUnbindSelf;
- (CGSize)_currentCaptureResolution;
- (NSData*)_closestCalibrationDataFromPreferences:(NSInteger*)distanceFromPerfectMatch;
- (NSString*)_prefKeyPartForCurrentInputMethod;
- (NSString*)_prefKeyForCalibrationDataOfCurrentInputSettings;
- (NSInteger)_resolutionKeyFromCGSize:(CGSize)size;
- (CGSize)_sizeFromResolutionKey:(NSInteger)resolutionKey;
- (BOOL)_setupBlobInput:(NSError**)error;
- (BOOL)_setupBlobLabelizer:(NSError**)error;
- (BOOL)_setupCoordinateConverter:(NSError**)error;
- (NSString*)_trackingCalibrationKeyForResolution:(NSInteger)resKey andCaptureInputKey:(NSString*)captureInputKey andCoordinateConverterClassName:(NSString*)coordConverterName;
- (void)_cacheBlobs:(NSArray*)blobs inField:(NSArray**)cacheField;
- (void)_changeCaptureResolution:(NSInteger)sizeCode;
- (void)_processBlobsThread;
@end

@implementation TFTrackingPipeline

@synthesize inputMethod;
@synthesize delegate;
@synthesize showBlobsInPreview;
@synthesize frameStageForDisplay;
@synthesize transformBlobsToScreenCoordinates;

+ (void)initialize
{
	if (nil == tFTrackingPipelineSingleton)
		tFTrackingPipelineSingleton = [[TFTrackingPipeline alloc] _initPrivate];
}

+ (TFTrackingPipeline*)sharedPipeline
{
	return [[tFTrackingPipelineSingleton retain] autorelease];
}

- (void)dealloc
{
	delegate = nil;
	
	if (self == tFTrackingPipelineSingleton) {
		NSUserDefaults* standardUserDefaults = [NSUserDefaults standardUserDefaults];
		[standardUserDefaults removeObserver:self forKeyPath:qtCaptureCameraResolutionPrefKey];
		[standardUserDefaults removeObserver:self forKeyPath:qtCaptureDeviceUniqueIdPrefKey];
		[standardUserDefaults removeObserver:self forKeyPath:libdc1394CaptureCameraResolutionPrefKey];
		[standardUserDefaults removeObserver:self forKeyPath:libDc1394CameraUniqueIdPrefKey];
		[standardUserDefaults removeObserver:self forKeyPath:trackingInputMethodPrefKey];
		[self unloadPipeline:NULL];
		[self _unbindFromPreferences:YES];
		
		[_objectBindings release];
		_objectBindings = nil;
		
		[_calibrationError release];
		_calibrationError = nil;
		
		[_currentUntransformedBlobs release];
		_currentUntransformedBlobs = nil;
	}
	
	[super dealloc];
}

- (id)init
{
	NSAssert(
			 self != tFTrackingPipelineSingleton,
			 ([NSString stringWithFormat:TFLocalizedString(@"InitSentToSingletonError", @"-init sent to %@ directly!"),
			   @"tFTrackingPipelineSingleton"])
			 );
	
	[self release];
	[tFTrackingPipelineSingleton retain];
	return tFTrackingPipelineSingleton;
}

- (id)_initPrivate
{
	if (!(self = [super init])) {
		[self release];
		return nil;
	}
	
	delegate = nil;
	_objectBindings = [[NSMutableDictionary alloc] init];
	
	showBlobsInPreview = YES;
	transformBlobsToScreenCoordinates = YES;
	frameStageForDisplay = TFFilterChainStageUnfiltered;
	_calibrationStatus = TFTrackingPipelineCalibrationFine;
	_calibrationError = nil;
		
	[self _bindToPreferences:self keyPaths:[NSArray arrayWithObjects:@"frameStageForDisplay",
																	 @"showBlobsInPreview",
																		nil]];
	
	NSMutableDictionary* defaultPrefs =
		[NSMutableDictionary dictionaryWithObjectsAndKeys:
			  [NSNumber numberWithInt:TFTrackingPipelineInputResolution320x240],
				qtCaptureCameraResolutionPrefKey,
			  [NSNumber numberWithInt:TFTrackingPipelineInputMethodQuickTimeKitCamera],
				trackingInputMethodPrefKey,
			  nil];
	
	NSNumber* defaultLibDc1394UniqueId = [self _defaultLibDc1394CameraUniqueID];
	if (nil != defaultLibDc1394UniqueId) {
		[defaultPrefs setObject:defaultLibDc1394UniqueId forKey:libDc1394CameraUniqueIdPrefKey];
		
		CGSize defaultLibDc1394Resolution = [self _defaultResolutionForLibDc1394CameraWithUniqueId:defaultLibDc1394UniqueId];
		[defaultPrefs setObject:[NSNumber numberWithInt:[self _resolutionKeyFromCGSize:defaultLibDc1394Resolution]]
						 forKey:libdc1394CaptureCameraResolutionPrefKey];
	}
	
	NSString* defaultQtUniqueId = [self _defaultQTVideoDeviceUniqueID];
	if (nil != defaultQtUniqueId)
		[defaultPrefs setObject:defaultQtUniqueId forKey:qtCaptureDeviceUniqueIdPrefKey];
	
	NSInteger i;
	for (i = TFTrackingPipelineInputResolutionLowest; i<=TFTrackingPipelineInputResolutionHighest; i++) {
		[defaultPrefs setObject:[NSArray array] forKey:[self _trackingCalibrationKeyForResolution:i
																			   andCaptureInputKey:trackingInputMethodQTCameraKey
																  andCoordinateConverterClassName:[TFInverseTextureMappingConverter className]]];
		[defaultPrefs setObject:[NSArray array] forKey:[self _trackingCalibrationKeyForResolution:i
																			   andCaptureInputKey:trackingInputMethodLibDc1394Key
																  andCoordinateConverterClassName:[TFInverseTextureMappingConverter className]]];
	}
	
	NSUserDefaults* standardDefaults = [NSUserDefaults standardUserDefaults];
		
	[standardDefaults registerDefaults:defaultPrefs];
	
	[standardDefaults addObserver:self
					   forKeyPath:qtCaptureCameraResolutionPrefKey
						  options:NSKeyValueObservingOptionNew
						  context:NULL];
	
	[standardDefaults addObserver:self
					   forKeyPath:qtCaptureDeviceUniqueIdPrefKey
						  options:NSKeyValueObservingOptionNew
						  context:NULL];
	
	[standardDefaults addObserver:self
					   forKeyPath:libdc1394CaptureCameraResolutionPrefKey
						  options:NSKeyValueObservingOptionNew
						  context:NULL];
	
	[standardDefaults addObserver:self
					   forKeyPath:libDc1394CameraUniqueIdPrefKey
						  options:NSKeyValueObservingOptionNew
						  context:NULL];
	
	[standardDefaults addObserver:self
					   forKeyPath:trackingInputMethodPrefKey
						  options:NSKeyValueObservingOptionNew
						  context:NULL];
	
	inputMethod = [standardDefaults integerForKey:trackingInputMethodPrefKey];
			
	return self;
}

- (void)setDelegate:(id)newDelegate
{
	delegate = newDelegate;
	
	// cache the blob tracking delegate method availability for performance reasons
	_delegateHasDidFindBlobs = [delegate respondsToSelector:@selector(pipeline:didFindBlobs:unmatchedBlobs:)];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isEqual:[NSUserDefaults standardUserDefaults]]) {
		if ([keyPath isEqualToString:qtCaptureCameraResolutionPrefKey] || [keyPath isEqualToString:libdc1394CaptureCameraResolutionPrefKey])
			[self _changeCaptureResolution:[[change objectForKey:NSKeyValueChangeNewKey] intValue]];
		else if ([keyPath isEqualToString:qtCaptureDeviceUniqueIdPrefKey]) {
			NSError* error = nil;
			
			if (![self _changeQTCaptureDeviceToDeviceWithUniqueId:[change objectForKey:NSKeyValueChangeNewKey] error:&error]) {
				if ([delegate respondsToSelector:@selector(pipeline:didBecomeUnavailableWithError:)])
					[delegate pipeline:self didBecomeUnavailableWithError:error];
			}
		} else if ([keyPath isEqualToString:libDc1394CameraUniqueIdPrefKey]) {
			NSError* error = nil;
		
			if (![self _changeLibDc1394CameraToCameraWithUniqueId:[change objectForKey:NSKeyValueChangeNewKey] error:&error]) {
				if ([delegate respondsToSelector:@selector(pipeline:didBecomeUnavailableWithError:)])
					[delegate pipeline:self didBecomeUnavailableWithError:error];
			}
		} else if ([keyPath isEqualToString:trackingInputMethodPrefKey]) {
			inputMethod = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
			
			if ([delegate respondsToSelector:@selector(pipeline:trackingInputMethodDidChangeTo:)])
				[delegate pipeline:self trackingInputMethodDidChangeTo:inputMethod];
		}
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)_cacheBlobs:(NSArray*)blobs inField:(NSArray**)cacheField
{
	@synchronized(*cacheField) {
		[blobs retain];
		[*cacheField release];
		*cacheField = blobs;
	}
}

- (void)_bindToPreferences:(id)object keyPaths:(NSArray*)paths
{
	NSUserDefaultsController *defController = [NSUserDefaultsController sharedUserDefaultsController];
	NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary* defaultValues = [NSMutableDictionary dictionary];
	
	for (NSString* path in paths) {
		NSString* prefKey = [NSString stringWithFormat:@"%@_%@", path, [object className]];
	
		id defaultVal = [object valueForKeyPath:path];
		
		NSDictionary* bindingOptions = nil;
		if (nil != defaultVal &&
			![defaultVal isKindOfClass:[NSData class]] &&
			![defaultVal isKindOfClass:[NSString class]] &&
			![defaultVal isKindOfClass:[NSNumber class]] &&
			![defaultVal isKindOfClass:[NSDate class]]) {
			
			NSValueTransformer* keyedUnarchiveTransformer =
				[NSValueTransformer valueTransformerForName:NSKeyedUnarchiveFromDataTransformerName];
			
			bindingOptions = [NSDictionary dictionaryWithObject:keyedUnarchiveTransformer
														 forKey:NSValueTransformerBindingOption];
			
			defaultVal = [keyedUnarchiveTransformer reverseTransformedValue:defaultVal];			
		}
		
		[defaultValues setObject:defaultVal forKey:prefKey];
	
		[object bind:path
			toObject:defController
		 withKeyPath:[NSString stringWithFormat:@"values.%@", prefKey]
			 options:bindingOptions];
		
		// since we're binding to the prefs anyway, the path is a unique key!
		[_objectBindings setObject:object forKey:[path stringByAppendingString:[object className]]];
	}
	
	[userDefaults registerDefaults:defaultValues];
}

- (void)_unbindFromPreferences:(BOOL)alsoUnbindSelf
{
	for (NSString* key in [_objectBindings allKeys]) {
		id object = [_objectBindings objectForKey:key];
		if (nil != object && (alsoUnbindSelf || object != self)) {
			[object unbind:[key stringByReplacingOccurrencesOfString:[object className] withString:@""]];
			[_objectBindings removeObjectForKey:key];
		}
	}
}

- (CGSize)_currentCaptureResolution
{
	return [_blobInput currentCaptureResolution];
}

- (NSInteger)_resolutionKeyFromCGSize:(CGSize)size
{
	if (size.width == 160.0f && size.height == 120.0f)
		return TFTrackingPipelineInputResolution160x120;
	else if (size.width == 320.0f && size.height == 240.0f)
		return TFTrackingPipelineInputResolution320x240;
	else if (size.width == 640.0f && size.height == 480.0f)
		return TFTrackingPipelineInputResolution640x480;
	else if (size.width == 800.0f && size.height == 600.0f)
		return TFTrackingPipelineInputResolution800x600;
	else if (size.width == 1024.0f && size.height == 768.0f)
		return TFTrackingPipelineInputResolution1024x768;
	else if (size.width == 1280.0f && size.height == 960.0f)
		return TFTrackingPipelineInputResolution1024x768;
	else if (size.width == 1600.0f && size.height == 1200.0f)
		return TFTrackingPipelineInputResolution1024x768;
	
	return TFTrackingPipelineInputResolutionUnknown;
}

- (CGSize)_sizeFromResolutionKey:(NSInteger)resolutionKey
{
	CGSize size;

	switch (resolutionKey) {
		case TFTrackingPipelineInputResolution160x120:
			size = CGSizeMake(160.0f, 120.0f);
			break;
		case TFTrackingPipelineInputResolution320x240:
			size = CGSizeMake(320.0f, 240.0f);
			break;
		case TFTrackingPipelineInputResolution640x480:
			size = CGSizeMake(640.0f, 480.0f);
			break;
		case TFTrackingPipelineInputResolution800x600:
			size = CGSizeMake(800.0f, 600.0f);
			break;
		case TFTrackingPipelineInputResolution1024x768:
			size = CGSizeMake(1024.0f, 768.0f);
			break;
		case TFTrackingPipelineInputResolution1280x960:
			size = CGSizeMake(1280.0f, 960.0f);
			break;
		case TFTrackingPipelineInputResolution1600x1200:
			size = CGSizeMake(1600.0f, 1200.0f);
			break;
		default:
			size = CGSizeMake(0.0f, 0.0f);
	}
	
	return size;
}

// TODO: inform about errors, e.g. via a delegate
- (void)_changeCaptureResolution:(NSInteger)sizeCode
{
	CGSize newSize = [self _sizeFromResolutionKey:sizeCode];
	
	NSError *error;
	
	if (![_blobInput changeCaptureResolution:newSize error:&error]) {
		// TODO: inform the user that changing the resolution failed, via delegate
	}
		
	if (_coordConverter != nil) {
		// first, we need to unbind all bindings to this coordinate converter
		NSArray* keyPaths = [_objectBindings allKeysForObject:_coordConverter];
		for (NSString* keyPath in keyPaths)
			[_coordConverter unbind:[keyPath stringByReplacingOccurrencesOfString:[_coordConverter className]
																	   withString:@""]];

		if (![self _setupCoordinateConverter:&error])  {
			// TODO: inform the user that changing the resolution failed, via delegate
		}
		
		[self _checkAndReportCalibrationProblemsToDelegate:YES];
	}
}

- (NSString*)_prefKeyPartForCurrentInputMethod
{
	switch (inputMethod) {
		case TFTrackingPipelineInputMethodWiiRemote:
			return trackingInputMethodWiiRemoteKey;
		case TFTrackingPipelineInputMethodLibDc1394Camera:
			return trackingInputMethodLibDc1394Key;
		case TFTrackingPipelineInputMethodQuickTimeKitCamera:
		default:
			return trackingInputMethodQTCameraKey;
	}
}

- (NSString*)_prefKeyForCalibrationDataOfCurrentInputSettings
{
	NSInteger captureResolutionKey = [self _resolutionKeyFromCGSize:[self _currentCaptureResolution]];
	NSString* calibrationPrefKey = [self _trackingCalibrationKeyForResolution:captureResolutionKey
														   andCaptureInputKey:[self _prefKeyPartForCurrentInputMethod]
											  andCoordinateConverterClassName:[_coordConverter className]];
	
	return calibrationPrefKey;
}

- (BOOL)_setupBlobInput:(NSError**)error
{
	if (TFTrackingPipelineInputMethodLibDc1394Camera == inputMethod) {
		NSUserDefaults* standardDefaults = [NSUserDefaults standardUserDefaults];
		
		NSNumber* cameraUid = [standardDefaults objectForKey:libDc1394CameraUniqueIdPrefKey];
		if (![self libdc1394CameraConnectedWithGUID:cameraUid])
			cameraUid = [self _defaultLibDc1394CameraUniqueID];
		
		CGSize frameSize = [self _sizeFromResolutionKey:
							[[standardDefaults objectForKey:libdc1394CaptureCameraResolutionPrefKey] intValue]];
		
		if (![self _libDc1394CameraWithUniqueId:cameraUid supportsResolution:frameSize])
			frameSize = [self _defaultResolutionForLibDc1394CameraWithUniqueId:cameraUid];
		
		NSDictionary* configurationDictionary =
				[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithFloat:frameSize.width], tfBlobLibDc1394InputSourceConfItemCameraResolutionX,
					[NSNumber numberWithFloat:frameSize.height], tfBlobLibDc1394InputSourceConfItemCameraResolutionY,
					cameraUid, tfBlobLibDc1394InputSourceConfItemCameraUniqueID,
					nil];
		
		TFBlobLibDc1394InputSource* dcInput = [[TFBlobLibDc1394InputSource alloc] init];
		dcInput.delegate = self;
		
		if (nil != dcInput && ![dcInput loadWithConfiguration:configurationDictionary error:error])
			return NO;
		
		_blobInput = dcInput;
	} else if (TFTrackingPipelineInputMethodQuickTimeKitCamera == inputMethod) {
		NSUserDefaults* standardDefaults = [NSUserDefaults standardUserDefaults];
		
		NSString* cameraUniqueID = [standardDefaults objectForKey:qtCaptureDeviceUniqueIdPrefKey];
		if (![self qtDeviceConnectedWithUniqueID:cameraUniqueID])
			cameraUniqueID = [self _defaultQTVideoDeviceUniqueID];
		
		CGSize frameSize = [self _sizeFromResolutionKey:
							[[standardDefaults objectForKey:qtCaptureCameraResolutionPrefKey] intValue]];
		
		NSDictionary* configurationDictionary =
		[NSDictionary dictionaryWithObjectsAndKeys:
		 [NSNumber numberWithFloat:frameSize.width], tfBlobQuicktimeKitInputSourceConfItemCameraResolutionX,
		 [NSNumber numberWithFloat:frameSize.height], tfBlobQuicktimeKitInputSourceConfItemCameraResolutionY,
		 cameraUniqueID, tfBlobQuicktimeKitInputSourceConfItemCameraUniqueID,
		 nil];
		
		TFBlobQuicktimeKitInputSource* qtInput = [[TFBlobQuicktimeKitInputSource alloc] init];
		qtInput.delegate = self;
		
		if (nil != qtInput && ![qtInput loadWithConfiguration:configurationDictionary error:error])
			return NO;
		
		_blobInput = qtInput;	
	} else if (TFTrackingPipelineInputMethodWiiRemote == inputMethod) {
		TFBlobWiiRemoteInputSource* wiiRemoteSource = [[TFBlobWiiRemoteInputSource alloc] init];
		wiiRemoteSource.delegate = self;
		
		if (nil != wiiRemoteSource && ![wiiRemoteSource loadWithConfiguration:nil error:error])
			return NO;
		
		_blobInput = wiiRemoteSource;
	} else {
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorTrackingPipelineInputMethodUnknown
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFTrackingPipelineInputMethodUnknownErrorDesc", @"TFTrackingPipelineInputMethodUnknownErrorDesc"),
												NSLocalizedDescriptionKey,
											   [NSString stringWithFormat:TFLocalizedString(@"TFTrackingPipelineInputMethodUnknownErrorReason", @"TFTrackingPipelineInputMethodUnknownErrorReason"),
												inputMethod],
												NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFTrackingPipelineInputMethodUnknownErrorRecovery", @"TFTrackingPipelineInputMethodUnknownErrorRecovery"),
												NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
												NSStringEncodingErrorKey,
											   nil]];

		return NO;
	}
	
	if (nil == _blobInput) {
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorTrackingPipelineBlobInputCreationFailed
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFTrackingPipelineBlobInputCreationFailedErrorDesc", @"TFTrackingPipelineBlobInputCreationFailedErrorDesc"),
												NSLocalizedDescriptionKey,
											   TFLocalizedString(@"TFTrackingPipelineBlobInputCreationFailedErrorReason", @"TFTrackingPipelineBlobInputCreationFailedErrorReason"),
												NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFTrackingPipelineBlobInputCreationFailedErrorRecovery", @"TFTrackingPipelineBlobInputCreationFailedErrorRecovery"),
												NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
												NSStringEncodingErrorKey,
											   nil]];
	
		return NO;
	}
	
	[self _bindToPreferences:_blobInput keyPaths:[NSArray arrayWithObjects:
													@"blobTrackingEnabled",
													@"maximumFramesPerSecond",
													nil]];
	
	if ([_blobInput isKindOfClass:[TFBlobCameraInputSource class]]) {
		TFBlobCameraInputSource* cameraSource = (TFBlobCameraInputSource*)_blobInput;
	
		if ([cameraSource.blobDetector isKindOfClass:[TFOpenCVContourBlobDetector class]]) {
			[self _bindToPreferences:cameraSource.blobDetector keyPaths:[NSArray arrayWithObjects:
																		 @"minimumBlobDiameter",
																		 nil]];
		}
	}
	
	// If the input source has a filter chain, set it up here...
	if ([_blobInput isKindOfClass:[TFBlobCameraInputSource class]]) {
		TFBlobCameraInputSource* cameraInput = (TFBlobCameraInputSource*)_blobInput;
	
		if ([cameraInput.filterChain isKindOfClass:[TFCameraInputFilterChain class]]) {
			[self _bindToPreferences:cameraInput.filterChain keyPaths:[NSArray arrayWithObjects:
																	   @"renderOnCPU",
																	   @"timeBetweenBackgroundFrameAcquisition",
																	   nil]];
						
			for (CIFilter* filter in ((TFCameraInputFilterChain*)cameraInput.filterChain).filters) {
				if ([filter isKindOfClass:[TFCIThresholdFilter class]])
					[self _bindToPreferences:filter keyPaths:[NSArray arrayWithObjects:
																@"inputMethodType",
																@"inputLuminanceThreshold",
																@"inputTargetColor",
																@"inputColorDistanceThreshold",
																nil]];
				else if ([filter isKindOfClass:[TFCIColorInversionFilter class]])
					[self _bindToPreferences:filter keyPaths:[NSArray arrayWithObjects:
															  @"enabled",
															  nil]];
				else if ([filter isKindOfClass:[TFCIBackgroundSubtractionFilter class]])
					[self _bindToPreferences:filter keyPaths:[NSArray arrayWithObjects:
																@"isEnabled",
																@"useBlending",
																@"blendingRatio",
																@"forceBackgroundPictureAfterEnabling",
																@"allowBackgroundPictureUpdate",
																@"doSmartSubtraction",
																@"smartSubtractionLuminanceThreshold",
															  nil]];
				else if ([filter isKindOfClass:[TFCIGaussianBlurFilter class]])
					[self _bindToPreferences:filter keyPaths:[NSArray arrayWithObjects:
															  @"isEnabled",
															  @"inputRadius",
															  nil]];
				else if ([filter isKindOfClass:[TFCIContrastStretchFilter class]])
					[self _bindToPreferences:filter keyPaths:[NSArray arrayWithObjects:
																@"isEnabled",
																@"inputBoostStrength",
																@"inputOpType",
																@"evalMinMaxOnCPU",
															  nil]];
				else if ([filter isKindOfClass:[TFCIMorphologicalOpenWith3x3ShapeFilter class]])
					[self _bindToPreferences:filter keyPaths:[NSArray arrayWithObjects:
															  @"inputPasses",
															  @"inputShapeType",
															  @"isEnabled",
															  nil]];
				else if ([filter isKindOfClass:[TFCIMorphologicalCloseWith3x3ShapeFilter class]])
					[self _bindToPreferences:filter keyPaths:[NSArray arrayWithObjects:
															  @"inputPasses",
															  @"inputShapeType",
															  @"isEnabled",
															  nil]];
				else if ([filter isKindOfClass:[TFCIGrayscalingFilter class]])
					[self _bindToPreferences:filter keyPaths:[NSArray arrayWithObjects:
															  @"inputMethodType",
															  @"isEnabled",
															  nil]];
			}
		}
	}
	
	return YES;
}

- (BOOL)_setupBlobLabelizer:(NSError**)error
{
	TFBlobSimpleDistanceLabelizer* distanceLabelizer = [[TFBlobSimpleDistanceLabelizer alloc] init];
	
	if (nil == distanceLabelizer) {
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorTrackingPipelineBlobLabelizerCreationFailed
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFTrackingPipelineBlobLabelizerCreationFailedErrorDesc", @"TFTrackingPipelineBlobLabelizerCreationFailedErrorDesc"),
												NSLocalizedDescriptionKey,
											   TFLocalizedString(@"TFTrackingPipelineBlobLabelizerCreationFailedErrorReason", @"TFTrackingPipelineBlobLabelizerCreationFailedErrorReason"),
												NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFTrackingPipelineBlobLabelizerCreationFailedErrorRecovery", @"TFTrackingPipelineBlobLabelizerCreationFailedErrorRecovery"),
												NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
												NSStringEncodingErrorKey,
											   nil]];
		
		return NO;
	}
	
	[self _bindToPreferences:distanceLabelizer keyPaths:[NSArray arrayWithObjects:@"lookbackFrames", nil]];
	
	_blobLabelizer = distanceLabelizer;
	
	if (NULL != error)
		*error = nil;
	
	return YES;
}

- (BOOL)_setupCoordinateConverter:(NSError**)error
{
	[_coordConverter release];
	_coordConverter = nil;

	NSScreen *screen = [TFScreenPreferencesController screen];
	NSRect screenFrame = [screen frame];

	TFInverseTextureMappingConverter* inverseTMConverter =
		[[TFInverseTextureMappingConverter alloc] initWithScreenSize:CGSizeMake(screenFrame.size.width, screenFrame.size.height)
													   andCameraSize:[_blobInput currentCaptureResolution]];
	
	if (nil == inverseTMConverter) {
		if (NULL != error)
			*error = [NSError errorWithDomain:TFErrorDomain
										 code:TFErrorTrackingPipelineCam2ScreenConverterCreationFailed
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											   TFLocalizedString(@"TFTrackingPipelineCam2ScreenConverterCreationFailedErrorDesc", @"TFTrackingPipelineCam2ScreenConverterCreationFailedErrorDesc"),
												NSLocalizedDescriptionKey,
											   TFLocalizedString(@"TFTrackingPipelineCam2ScreenConverterCreationFailedErrorReason", @"TFTrackingPipelineCam2ScreenConverterCreationFailedErrorReason"),
												NSLocalizedFailureReasonErrorKey,
											   TFLocalizedString(@"TFTrackingPipelineCam2ScreenConverterCreationFailedErrorRecovery", @"TFTrackingPipelineCam2ScreenConverterCreationFailedErrorRecovery"),
												NSLocalizedRecoverySuggestionErrorKey,
											   [NSNumber numberWithInteger:NSUTF8StringEncoding],
												NSStringEncodingErrorKey,
											   nil]];
		
		return NO;
	}
	
	[self _bindToPreferences:inverseTMConverter keyPaths:[NSArray arrayWithObjects:
														  @"calibrationPointsPerAxis",
														  nil]];
	
	_coordConverter = inverseTMConverter;
	_coordConverter.delegate = self;
	
	[self _bindToPreferences:_coordConverter keyPaths:[NSArray arrayWithObjects:
													   @"transformsBoundingBox",
													   @"transformsEdgeVertices",
													   nil]];
	
	NSInteger matchDistance;
	NSData* calibrationData = [self _closestCalibrationDataFromPreferences:&matchDistance];
	if (calibrationData) {
		if (![_coordConverter loadSerializedCalibrationData:calibrationData error:error]) {
			self.transformBlobsToScreenCoordinates = NO;
			[_calibrationError release];
			
			if (NULL != error)
				_calibrationError = [*error retain];
			
			_calibrationStatus = TFTrackingPipelineCalibrationRequired;
		} else {
			if (0 != matchDistance)
				_calibrationStatus = TFTrackingPipelineCalibrationRecommended;
			else
				_calibrationStatus = TFTrackingPipelineCalibrationFine;
		}
	} else {
		self.transformBlobsToScreenCoordinates = NO;
		[_calibrationError release];
		_calibrationError = [[NSError errorWithDomain:TFErrorDomain
												code:TFErrorTrackingPipelineInputMethodNeverCalibrated
											userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
													  TFLocalizedString(@"TFTrackingPipelineInputMethodNeverCalibratedErrorDesc", @"TFTrackingPipelineInputMethodNeverCalibratedErrorDesc"),
														NSLocalizedDescriptionKey,
													  TFLocalizedString(@"TFTrackingPipelineInputMethodNeverCalibratedErrorReason", @"TFTrackingPipelineInputMethodNeverCalibratedErrorReason"),
														NSLocalizedFailureReasonErrorKey,
													  TFLocalizedString(@"TFTrackingPipelineInputMethodNeverCalibratedErrorRecovery", @"TFTrackingPipelineInputMethodNeverCalibratedErrorRecovery"),
														NSLocalizedRecoverySuggestionErrorKey,
													  [NSNumber numberWithInteger:NSUTF8StringEncoding],
														NSStringEncodingErrorKey,
													  nil]] retain];
		
		_calibrationStatus = TFTrackingPipelineCalibrationRequired;
	}
	
	if (NULL != error)
		*error = nil;
	
	return YES;
}

- (NSData*)_closestCalibrationDataFromPreferences:(NSInteger*)distanceFromPerfectMatch
{
	NSInteger i, currentCaptureKey = [self _resolutionKeyFromCGSize:[self _currentCaptureResolution]];
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSInteger currentMatchDistance = NSIntegerMax;
	NSData* currentData = nil;
	
	for (i = TFTrackingPipelineInputResolutionHighest; i>=TFTrackingPipelineInputResolutionLowest; i--) {
		NSInteger distance = ABS(i-currentCaptureKey);
		if (distance > currentMatchDistance)
			continue;
		
		id val = [defaults objectForKey:[self _trackingCalibrationKeyForResolution:i
																andCaptureInputKey:[self _prefKeyPartForCurrentInputMethod]
												   andCoordinateConverterClassName:[_coordConverter className]]];
		
		if (nil != val && [val isKindOfClass:[NSData class]]) {
			currentData = (NSData*)val;
			currentMatchDistance = distance;
		}
	}
	
	if (nil != currentData) {
		if (NULL != distanceFromPerfectMatch)
			*distanceFromPerfectMatch = currentMatchDistance;
		
		return currentData;
	}
	
	return nil;
}

- (void)_checkAndReportCalibrationProblemsToDelegate:(BOOL)isResolutionChange
{
	if (TFTrackingPipelineCalibrationRequired == _calibrationStatus) {
		if ([delegate respondsToSelector:@selector(pipeline:calibrationNecessaryForCurrentSettingsBecauseOfError:)])
			[delegate pipeline:self calibrationNecessaryForCurrentSettingsBecauseOfError:_calibrationError];
	} else if (TFTrackingPipelineCalibrationRecommended == _calibrationStatus) {
		if ([delegate respondsToSelector:@selector(calibrationRecommendedForCurrentSettingsInPipeline:)])
			[delegate calibrationRecommendedForCurrentSettingsInPipeline:self];
	} else if (isResolutionChange) {
		if ([delegate respondsToSelector:@selector(calibrationIsFineForChosenResolutionInPipeline:)])
			[delegate calibrationIsFineForChosenResolutionInPipeline:self];
	}
	
	[_calibrationError release];
	_calibrationError = nil;
	_calibrationStatus = TFTrackingPipelineCalibrationFine;
}

- (NSString*)_trackingCalibrationKeyForResolution:(NSInteger)resKey andCaptureInputKey:(NSString*)captureInputKey andCoordinateConverterClassName:(NSString*)coordConverterName
{
	return [NSString stringWithFormat:trackingCalibrationPrefKeyTemplate, resKey, captureInputKey, coordConverterName];
}

- (void)_processBlobsThread
{
	NSAutoreleasePool* outerPool = [[NSAutoreleasePool alloc] init];
	
	TFThreadMessagingQueue* processingQueue = [_processingQueue retain];
	
	[NSThread setThreadPriority:BLOB_PROCESSING_THREAD_PRIORITY];
	
	while (YES) {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		
		NSArray* detectedBlobs = [processingQueue dequeue];
		
		if ([[NSThread currentThread] isCancelled]) {
			[pool release];
			break;
		}
		
		if ([detectedBlobs isKindOfClass:[NSArray class]] && _delegateHasDidFindBlobs) {
			@synchronized (self) {
				NSArray* unmatchedBlobs = nil;
				NSArray* blobs = [_blobLabelizer labelizeBlobs:detectedBlobs unmatchedBlobs:&unmatchedBlobs ignoringErrors:YES error:NULL];
				
				if ([blobs count] <= 0) {
					[self _cacheBlobs:nil inField:&_currentUntransformedBlobs];
				} else
					[self _cacheBlobs:[[[NSArray alloc] initWithArray:blobs copyItems:YES] autorelease] inField:&_currentUntransformedBlobs];
				
				if ([blobs count] <= 0 && (nil == unmatchedBlobs || [unmatchedBlobs count] <= 0)) {
					[pool release];
					continue;
				}
				
				if (transformBlobsToScreenCoordinates) {
					[_coordConverter transformBlobsFromCameraToScreen:blobs errors:NULL];
					[_coordConverter transformBlobsFromCameraToScreen:unmatchedBlobs errors:NULL];
				}
				
				[delegate pipeline:self didFindBlobs:blobs unmatchedBlobs:unmatchedBlobs];
			}
		}
		
		[pool release];
	}
	
	[processingQueue release];
	
	[outerPool release];
}

- (BOOL)isReady
{
	return [_blobInput isReady:nil];
}

- (BOOL)isProcessing
{
	return [_blobInput isProcessing];
}

- (BOOL)startProcessing:(NSError**)error
{
	NSString* notReadyReason = nil;
	if ([_blobInput isReady:&notReadyReason]) {
		if (nil == _processingQueue && nil == _processingThread) {
			_processingQueue = [[TFThreadMessagingQueue alloc] init];
			
			_processingThread = [[NSThread alloc] initWithTarget:self
														selector:@selector(_processBlobsThread)
														  object:nil];
			[_processingThread start];
		}
	
		return [_blobInput startProcessing:error];
	}
	
	if (NULL != error)
		*error = [NSError errorWithDomain:TFErrorDomain
									 code:TFErrorTrackingPipelinePipelineNotReady
								 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
										   TFLocalizedString(@"TFTrackingPipelineNotReadyErrorDesc", @"TFTrackingPipelineNotReadyErrorDesc"),
										   NSLocalizedDescriptionKey,
										   [NSString stringWithFormat:TFLocalizedString(@"TFTrackingPipelineNotReadyErrorReason", @"TFTrackingPipelineNotReadyErrorReason"),
											notReadyReason],
										   NSLocalizedFailureReasonErrorKey,
										   TFLocalizedString(@"TFTrackingPipelineNotReadyErrorRecovery", @"TFTrackingPipelineNotReadyErrorRecovery"),
										   NSLocalizedRecoverySuggestionErrorKey,
										   [NSNumber numberWithInteger:NSUTF8StringEncoding],
										   NSStringEncodingErrorKey,
										   nil]];

	return NO;
}

- (BOOL)stopProcessing:(NSError**)error
{
	if ([self isProcessing]) {
		if (nil != _processingQueue && nil != _processingThread) {
			[_processingThread cancel];
			[_processingThread release];
			_processingThread = nil;
			
			// wake the delivering thread if necessary
			[_processingQueue enqueue:[NSArray array]];
			[_processingQueue release];
			_processingQueue = nil;
		}
	
		return [_blobInput stopProcessing:error];
	}
	
	return YES;
}

- (BOOL)currentInputMethodSupportsFilterStages
{
	return [_blobInput hasFilterStages];
}

- (BOOL)currentSettingsSupportCaptureResolution:(CGSize)resolution
{
	return [_blobInput supportsCaptureResolution:resolution];
}

- (BOOL)currentSettingsSupportCaptureResolutionWithKey:(NSInteger)key
{
	return [_blobInput supportsCaptureResolution:[self _sizeFromResolutionKey:key]];
}

- (BOOL)loadPipeline:(NSError**)error
{
	[self _unbindFromPreferences:NO];
	
	_calibrationStatus = TFTrackingPipelineCalibrationFine;
	[_calibrationError release];
	_calibrationError = nil;

	if (![self _setupBlobInput:error])
		goto errorReturn;
	
	if (![self _setupBlobLabelizer:error])
		goto errorReturn;
	
	if (![self _setupCoordinateConverter:error])
		goto errorReturn;
	
	if (NULL != error)
		*error = nil;
	
	if ([delegate respondsToSelector:@selector(pipelineDidLoad:)])
		[delegate pipelineDidLoad:self];
	
	NSString* reason;
	if ([_blobInput isReady:&reason]) {
		[self _checkAndReportCalibrationProblemsToDelegate:NO];
	
		if ([delegate respondsToSelector:@selector(pipelineDidBecomeReady:)])
			[delegate pipelineDidBecomeReady:self];
	} else {
		if ([delegate respondsToSelector:@selector(pipeline:notReadyWithReason:)])
			[delegate pipeline:self notReadyWithReason:reason];
	}
	
	return YES;

errorReturn:
	[self unloadPipeline:nil];
	return NO;
}

- (BOOL)unloadPipeline:(NSError**)error
{
	BOOL success = [self stopProcessing:error];
	
	[self _unbindFromPreferences:NO];
	
	@synchronized (_blobInput) {
		[_blobInput unloadWithError:NULL];
		[_blobInput release];
		_blobInput = nil;
	}
	
	@synchronized (_blobLabelizer) {
		[_blobLabelizer release];
		_blobLabelizer = nil;
	}
	
	@synchronized (_coordConverter) {
		[_coordConverter release];
		_coordConverter = nil;
	}
	
	[self _cacheBlobs:nil inField:&_currentUntransformedBlobs];
	
	if (success && NULL != error)
		*error = nil;
	
	return success;
}

- (NSArray*)screenPointsForCalibration
{
	return [_coordConverter screenPointsForCalibration];
}

- (BOOL)calibrateWithPoints:(NSArray*)points error:(NSError**)error
{
	[_calibrationError release];
	_calibrationError = nil;
	_calibrationStatus = TFTrackingPipelineCalibrationFine;
	
	NSArray* errors = nil;
	
	if (![_coordConverter calibrateWithPoints:points errors:&errors]) {
		if (NULL != error && [errors count] > 0)
			*error = [errors objectAtIndex:0];
	
		return NO;
	}
	
	NSString* calibrationPrefKey = [self _prefKeyForCalibrationDataOfCurrentInputSettings];
	NSData* calibrationData = [_coordConverter serializedCalibrationData];
	
	if (nil != calibrationData) {
		NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
		[defaults setObject:calibrationData forKey:calibrationPrefKey];
	}
	
	return YES;
}

#pragma mark -
#pragma mark Delegate methods for TFBlobInputSource

- (void)blobInputSource:(TFBlobInputSource*)inputSource didDetectBlobs:(NSArray*)detectedBlobs
{	
	if (_blobInput == inputSource && nil != detectedBlobs) {
		[_processingQueue enqueue:detectedBlobs];
	}
}

- (void)blobInputSourceDidBecomeReady:(TFBlobInputSource*)inputSource
{
	if (_blobInput == inputSource) {
		[self _checkAndReportCalibrationProblemsToDelegate:NO];
		
		if ([delegate respondsToSelector:@selector(pipelineDidBecomeReady:)])
			[delegate pipelineDidBecomeReady:self];
	}
}

- (void)blobInputSource:(TFBlobInputSource*)inputSource willNotBecomeReadyWithError:(NSError*)error
{
	if (_blobInput == inputSource) {
		[self unloadPipeline:nil];
		
		if ([delegate respondsToSelector:@selector(pipeline:willNotBecomeReadyWithError:)])
			[delegate pipeline:self willNotBecomeReadyWithError:error];
	}
}

- (void)blobInputSource:(TFBlobInputSource*)inputSource didBecomeUnavailableWithError:(NSError*)error
{
	if (_blobInput == inputSource) {
		if ([delegate respondsToSelector:@selector(pipeline:didBecomeUnavailableWithError:)])
			[delegate pipeline:self didBecomeUnavailableWithError:error];
	}
}

- (void)blobInputSourceDidBecomeAvailableAgain:(TFBlobInputSource*)inputSource
{
	if (_blobInput == inputSource) {
		if ([delegate respondsToSelector:@selector(pipelineDidBecomeAvailableAgain:)])
			[delegate pipelineDidBecomeAvailableAgain:self];
	}
}

#pragma mark -
#pragma mark Delegate methods for TFBlobTrackingView

- (CIImage*)trackingPipelineView:(TFTrackingPipelineView*)pipelineView frameForTimestamp:(const CVTimeStamp*)timeStamp
{
	if (nil == _blobInput)
		return nil;

	// we simply ignore the timestamp and always return the most current frame
	CIImage* img;
	@synchronized (_blobInput) {
		img = [_blobInput currentRawImageForStage:frameStageForDisplay];
	}
		
	return img;
}

- (NSArray*)blobTrackingView:(TFBlobTrackingView*)trackingView cameraBlobsForTimestamp:(const CVTimeStamp*)timeStamp
{
	NSArray* blobs = nil;
	@synchronized(_currentUntransformedBlobs) {
		// we simply ignore the timestamp and always return the most current blobs
		blobs = showBlobsInPreview ? [NSArray arrayWithArray:_currentUntransformedBlobs] : nil;
	}
	
	return blobs;
}

@end
