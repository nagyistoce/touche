//
//  TFBlob+FrameworkAdditions.h
//  Touché
//
//  Created by Georg Kaindl on 21/5/08.
//  Copyright 2008 Georg Kaindl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TFBlob.h"

@interface TFBlob (FrameworkAdditions)
- (NSPoint)centerQCCoordinatesForViewSize:(NSSize)viewSize;
- (NSPoint)QCCoordinatesForPoint:(NSPoint)point andViewSize:(NSSize)viewSize;
@end
