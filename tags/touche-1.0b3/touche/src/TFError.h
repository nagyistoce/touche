//
//  TFError.h
//  Touché
//
//  Created by Georg Kaindl on 7/5/08.
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

extern NSString* TFErrorDomain;

typedef enum {
	TFErrorUnknown								= 1000,

	TFErrorServerIsAlreadyRunning,
	TFErrorServerCouldNotRegisterItself,
	
	TFErrorClientUnexpectedlyDisconnected,
	TFErrorClientServerConnectionRefused,
	TFErrorClientServerNameRegistrationFailed,
	TFErrorClientDisconnectedSinceServerWasStopped,
	TFErrorClientRegisteredWithInvalidArguments,
	
	TFErrorWiiRemoteDiscoveryCreationFailed,
	TFErrorWiiRemoteDiscoveryStartupFailed,
	TFErrorWiiRemoteDiscoveryFailed,
	TFErrorWiiRemoteStartProcessingFailed,
	TFErrorWiiRemoteResolutionChangeFailed,
	TFErrorWiiRemoteDisconnectedUnexpectedly,
	
	TFErrorQTKitCaptureFailedToCreateWithUniqueID,
	TFErrorQTKitCaptureDeviceSetToNil,
	TFErrorQTKitCaptureDeviceInputCouldNotBeCreated,
	TFErrorQTKitCaptureDeviceWithUIDNotFound,
	
	TFErrorDc1394NoDeviceFound,
	TFErrorDc1394LibInstantiationFailed,
	TFErrorDc1394CameraAlreadyInUse,
	TFErrorDc1394CameraCreationFailed,
	TFErrorDc1394CaptureSetupFailed,
	TFErrorDc1394SetTransmissionFailed,
	TFErrorDc1394StopTransmissionFailed,
	TFErrorDc1394StopCapturingFailed,
	TFErrorDc1394ResolutionChangeFailed,
	TFErrorDc1394ResolutionChangeFailedInternalError,
	TFErrorDc1394GettingVideoModesFailed,
	TFErrorDc1394LittleEndianVideoUnsupported,
	TFErrorDc1394CVPixelBufferCreationFailed,
	TFErrorDc1394UnsupportedPixelFormat,
	
	TFErrorInputSourceInvalidArguments,
	
	TFErrorCameraInputSourceCIFilterChainCreationFailed,
	TFErrorCameraInputSourceOpenCVBlobDetectorCreationFailed,
	
	TFErrorSimpleDistanceLabelizerOutOfMemory,
	
	TFErrorCam2ScreenInvalidCalibrationData,
	TFErrorCam2ScreenNilCalibrationPoints,
	TFErrorCam2ScreenCalibrationPointsAmountMismatch,
	TFErrorCam2ScreenCalibrationPointNotCalibrated,
	TFErrorCam2ScreenCalibrationPointContainedTwice,
	TFErrorCam2ScreenCalibrationPointMissing,
	
	TFErrorInverseTextureCam2ScreenInternalError,
	
	TFErrorTrackingPipelineInputIsNotQTKitSource,
	TFErrorTrackingPipelineInputIsNotLibDc1394Source,
	TFErrorTrackingPipelineInputMethodUnknown,
	TFErrorTrackingPipelineBlobInputCreationFailed,
	TFErrorTrackingPipelineBlobLabelizerCreationFailed,
	TFErrorTrackingPipelineCam2ScreenConverterCreationFailed,
	TFErrorTrackingPipelinePipelineNotReady,
	TFErrorTrackingPipelineInputMethodNeverCalibrated,
	
	TFErrorCouldNotEnterFullscreen,
	
	TFErrorCouldNotCreateTUIOXMLFlashServer
} TFErrorType;

#define TFUnknownErrorObj	([NSError errorWithDomain:TFErrorDomain	\
												 code:TFErrorUnknown	\
											 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:	\
														TFLocalizedString(@"TFUnknownErrorDesc", @"TFUnknownErrorDesc"),	\
															NSLocalizedDescriptionKey,	\
													    TFLocalizedString(@"TFUnknownErrorReason", @"TFUnknownErrorReason"),	\
															NSLocalizedFailureReasonErrorKey,	\
													    TFLocalizedString(@"TFUnknownErrorRecovery", @"TFUnknownErrorRecovery"),	\
															NSLocalizedRecoverySuggestionErrorKey,	\
													    [NSNumber numberWithInteger:NSUTF8StringEncoding], \
															NSStringEncodingErrorKey,	\
													    nil]])
