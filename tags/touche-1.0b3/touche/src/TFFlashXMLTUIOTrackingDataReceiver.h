//
//  TFFlashXMLTUIOTrackingDataReceiver.h
//  Touché
//
//  Created by Georg Kaindl on 6/9/08.
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

#import <Foundation/Foundation.h>

#import "TFTrackingDataReceiver.h"


@class TFIPStreamSocket, TFSocket;

@interface TFFlashXMLTUIOTrackingDataReceiver : TFTrackingDataReceiver {
@protected
	TFIPStreamSocket*			_socket;
	NSThread*					_socketThread;
	BOOL						_connectionDidDie;
}

- (id)init;
- (id)initWithConnectedSocket:(TFIPStreamSocket*)socket;
- (void)dealloc;

- (void)receiverShouldQuit;
- (void)consumeTrackingData:(id)trackingData;

#pragma mark -
#pragma mark TFSocket delegate

- (void)socket:(TFSocket*)socket dataIsAvailableWithLength:(NSUInteger)dataLength;

#pragma mark -
#pragma mark TFIPStreamSocket delegate

- (void)socketGotDisconnected:(TFIPStreamSocket*)socket;

@end
