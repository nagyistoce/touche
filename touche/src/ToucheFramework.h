//
//  ToucheFramework.h
//  Touché
//
//  Created by Georg C. Kaindl on 19/05/08.
//
//  Copyright (C) 2007 Georg Kaindl
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

#import <ToucheFramework/TFBlob.h>
#import <ToucheFramework/TFBlob+FrameworkAdditions.h>
#import <ToucheFramework/TFBlobPoint.h>
#import <ToucheFramework/TFBlobBox.h>
#import <ToucheFramework/TFBlobSize.h>
#import <ToucheFramework/TFBlobLabel.h>
#import <ToucheFramework/TFLabeledTouchSet.h>

#import <ToucheFramework/TFFullscreenController.h>

#import <ToucheFramework/TFDOTrackingClient.h>

#import <ToucheFramework/TFAlignedMalloc.h>
#import <ToucheFramework/TFCombinadicIndices.h>
#import <ToucheFramework/TFGeometry.h>
#import <ToucheFramework/TFTouchLabelObjectAssociator.h>

#import <ToucheFramework/TFCATouchIndicationLayer.h>

#import <ToucheFramework/TFGestureConstants.h>
#import <ToucheFramework/TFGestureInfo.h>
#import <ToucheFramework/TFGestureRecognizer.h>
#import <ToucheFramework/TFZoomPinchRecognizer.h>
#import <ToucheFramework/TFTapRecognizer.h>

typedef TFDOTrackingClient TFTrackingClient;
typedef TFBlob TFTouch;
typedef TFBlobPoint TFTouchPoint;
typedef TFBlobBox TFTouchBox;
typedef TFBlobSize TFTouchSize;
typedef TFBlobLabel TFTouchLabel;
