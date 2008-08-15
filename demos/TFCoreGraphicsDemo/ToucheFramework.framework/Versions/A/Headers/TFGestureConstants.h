//
//  TFGestureConstants.h
//  Touché
//
//  Created by Georg Kaindl on 24/5/08.
//  Copyright 2008 Georg Kaindl. All rights reserved.
//

typedef enum {
	TFGestureTypeAny			= 1,
	TFGestureTypeTap,
	TFGestureTypeZoomPinch
} TFGestureType;

#define		TFGestureTypeMin	(TFGestureTypeAny)
#define		TFGestureTypeMax	(TFGestureTypeZoomPinch)

typedef enum {
	TFGestureSubtypeAny			= 1,
	TFGestureSubtypeTapDown,
	TFGestureSubtypeTapUp,
	TFGestureSubtypeZoom,
	TFGestureSubtypePinch
} TFGestureSubtype;

#define		TFGestureSubtypeMin		(TFGestureSubtypeAny)
#define		TFGestureSubtypeMax		(TFGestureSubtypePinch)