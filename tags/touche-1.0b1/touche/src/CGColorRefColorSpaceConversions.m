//
//  CGColorRefColorSpaceConversions.c
//
//  Created by Georg Kaindl on 27/4/08.
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

#import "CGColorRefColorSpaceConversions.h"

void CGColorGetLABComponentsForRGBColor(CGColorRef rgbColor, CGFloat* lab)
{
	const CGFloat* rgb = CGColorGetComponents(rgbColor);
	CGFloat frgb[3];
	int i;
	
	for (i=0; i<3; i++) {
		if (rgb[i] > 0.04045f)
			frgb[i] = pow(((rgb[i] + 0.055f) / 1.055f), 2.4f);
		else
			frgb[i] = rgb[i] / 12.92;
		
		frgb[i] *= 100.0f;
	}
	
	CGFloat xyz[3];
	
	xyz[0] = (frgb[0]*0.4124f + frgb[1]*0.3576f + frgb[2]*0.1805f) / 95.047f;
	xyz[1] = (frgb[0]*0.2126f + frgb[1]*0.7152f + frgb[2]*0.0722f) / 100.000f;
	xyz[2] = (frgb[0]*0.0193f + frgb[1]*0.1192f + frgb[2]*0.9505f) / 108.883f;
	
	for (i=0; i<3; i++) {
		if (xyz[i] > 0.008856)
			xyz[i] = pow(xyz[i], (1.0f/3.0f));
		else
			xyz[i] = (7.787f * xyz[i]) + (16.0f / 116.0f);
	}
	
	lab[0] = (116.0f * xyz[1]) - 16.0f;
	lab[1] = 500.0f * (xyz[0] - xyz[1]);
	lab[2] = 200.0f * (xyz[1] - xyz[2]);
}

CGColorRef CGColorCreateRGBfromGenericLABComponents(CGFloat* lab, CGFloat alpha)
{
	CGFloat xyz[3], rgb[4];
	int i;
	
	xyz[1] = (lab[0] + 16.0f) / 116.0f;
	xyz[0] = lab[1]/500.0f + xyz[1];
	xyz[2] = xyz[1] - lab[2] / 200.0f;
	
	for (i=0; i<3; i++) {
		if (pow(xyz[i], 3.0f) > 0.008856f)
			xyz[i] = pow(xyz[i], 3.0f);
		else
			xyz[i] = (xyz[i] - 16.0f/116.0f) / 7.787f;
	}
	
	xyz[0] *= 0.95047f;
	xyz[2] *= 1.08883f;
	
	rgb[0] = xyz[0]*3.2406f + xyz[1]*-1.5372f + xyz[2]*-0.4986f;
	rgb[1] = xyz[0]*-0.9689f + xyz[1]*1.8758f + xyz[2]*0.0415f;
	rgb[2] = xyz[0]*0.0557f + xyz[1]*-0.2040f + xyz[2]*1.0570f;
	
	for (i=0; i<3; i++) {
		if (rgb[i] > 0.0031308)
			rgb[i] = 1.055f * pow(rgb[i], (1.0f/2.4f)) - 0.055;
		else
			rgb[i] *= 12.92f;
	}
	
	rgb[3] = alpha;
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGColorRef newColor = CGColorCreate(colorSpace, rgb);
	CFRelease(colorSpace);
	
	return newColor;
}

CGColorRef CGColorCreateRGBFromGenericLAB(CGFloat L, CGFloat a, CGFloat b, CGFloat alpha)
{
	CGFloat lab[3];
	lab[0] = L;
	lab[1] = a;
	lab[2] = b;
	
	return CGColorCreateRGBfromGenericLABComponents(lab, alpha);
}

void CGColorClampLABComponents(CGFloat* lab)
{
	if (lab[0] > 100.0f)
		lab[0] = 100.0f;
	else if (lab[0] < 0.0f)
		lab[0] = 0.0f;
	
	int i;
	for (i=1; i<3; i++) {
		if (lab[i] > 127.0f)
			lab[i] = 127.0f;
		else if (lab[i] < -128.0f)
			lab[i] = -128.0f;
	}
}

CGColorRef CGColorCreateFromRGBColorWithLABOffset(CGColorRef color, CGFloat deltaL, CGFloat deltaA, CGFloat deltaB)
{
	CGFloat lab[3];
	
	CGColorGetLABComponentsForRGBColor(color, lab);
	lab[0] += deltaL;
	lab[1] += deltaA;
	lab[2] += deltaB;
	
	CGColorClampLABComponents(lab);
	return CGColorCreateRGBfromGenericLABComponents(lab, CGColorGetAlpha(color));
}