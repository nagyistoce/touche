//
//  TFTrackingPipeline.h
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

#import <Cocoa/Cocoa.h>

@class TFBlobInputSource;
@class TFRGBA8888BlobDetector;
@class TFBlobLabelizer;
@class TFCamera2ScreenCoordinatesConverter;

enum {
	TFTrackingPipelineInputResolution160x120	=	1,
	TFTrackingPipelineInputResolution320x240	=	2,
	TFTrackingPipelineInputResolution640x480	=	3,
	TFTrackingPipelineInputResolution800x600	=	4,
	TFTrackingPipelineInputResolution1024x768	=	5,
	TFTrackingPipelineInputResolution1280x960	=	6,
	TFTrackingPipelineInputResolution1600x1200	=	7,
	TFTrackingPipelineInputResolutionUnknown	=	-1
};

enum {
	TFTrackingPipelineInputMethodQuickTimeKitCamera = 1,
	TFTrackingPipelineInputMethodWiiRemote = 2,
	TFTrackingPipelineInputMethodLibDc1394Camera = 3
};

extern NSInteger TFTrackingPipelineInputResolutionLowest;
extern NSInteger TFTrackingPipelineInputResolutionHighest;

@interface TFTrackingPipeline : NSObject {
	TFBlobInputSource*						_blobInput;
	TFBlobLabelizer*						_blobLabelizer;
	TFCamera2ScreenCoordinatesConverter*	_coordConverter;
	
	NSArray*								_currentUntransformedBlobs;
	
	NSInteger								inputMethod;
	id										delegate;
		
	BOOL									showBlobsInPreview;
	BOOL									transformBlobsToScreenCoordinates;
	NSInteger								frameStageForDisplay;
	
	NSMutableDictionary*					_objectBindings;
	NSInteger								_calibrationStatus;
	NSError*								_calibrationError;
	
	BOOL									_delegateHasDidFindBlobs;
}

@property (readonly) NSInteger inputMethod;
@property (assign) id delegate;
@property (assign) BOOL showBlobsInPreview;
@property (assign) BOOL transformBlobsToScreenCoordinates;
@property (assign) NSInteger frameStageForDisplay;

+ (TFTrackingPipeline*)sharedPipeline;

- (void)setDelegate:(id)newDelegate;

- (BOOL)isReady;
- (BOOL)isProcessing;
- (BOOL)startProcessing:(NSError**)error;
- (BOOL)stopProcessing:(NSError**)error;

- (BOOL)loadPipeline:(NSError**)error;
- (BOOL)unloadPipeline:(NSError**)error;

- (NSArray*)screenPointsForCalibration;
- (BOOL)calibrateWithPoints:(NSArray*)points error:(NSError**)error;

- (BOOL)currentSettingsSupportCaptureResolution:(CGSize)resolution;
- (BOOL)currentSettingsSupportCaptureResolutionWithKey:(NSInteger)key;

- (BOOL)currentInputMethodSupportsFilterStages;

@end

@interface NSObject (TFTrackingPipelineDelegate)
- (void)pipelineDidLoad;
- (void)pipelineDidBecomeReady;
- (void)pipelineNotReadyWithReason:(NSString*)reason;
- (void)pipelineWillNotBecomeReadyWithError:(NSError*)error;
- (void)calibrationIsFineForChosenResolution;
- (void)calibrationNecessaryForCurrentSettingsBecauseOfError:(NSError*)error;
- (void)calibrationRecommendedForCurrentSettings;
- (void)trackingInputMethodDidChangeTo:(NSInteger)methodKey;
- (void)pipelineDidBecomeUnavailableWithError:(NSError*)error;
- (void)pipelineDidBecomeAvailableAgain;
- (void)pipelineDidFindBlobs:(NSArray*)blobs unmatchedBlobs:(NSArray*)unmatchedBlobs;
@end

