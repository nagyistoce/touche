//
//  TFDOTrackingCommProtocols.h
//  Touché
//
//  Created by Georg Kaindl on 5/2/08.
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

#define		DEFAULT_SERVICE_NAME	(@"touche-multitouch-lib-do-service")

@protocol TFDOTrackingClientProtocol

- (BOOL)isAlive;
- (oneway void)disconnectedByServerWithError:(bycopy in NSError*)error;
- (bycopy NSDictionary*)clientInfo;
- (oneway void)clientShouldQuit;
- (oneway void)deliverBeginningTouches:(bycopy in NSArray*)beginningTouches
						updatedTouches:(bycopy in NSArray*)updatedTouches
						  endedTouches:(bycopy in NSArray*)endedTouches
						sequenceNumber:(UInt64)sequenceNumber;

@end

@protocol TFDOTrackingServerProtocol

- (BOOL)registerClient:(byref id)client withName:(bycopy NSString*)name error:(bycopy out NSError**)error;
- (oneway void)unregisterClientWithName:(bycopy NSString*)name;
- (CGDirectDisplayID)screenId;
- (CGFloat)screenPixelsPerCentimeter;
- (CGFloat)screenPixelsPerInch;

@end