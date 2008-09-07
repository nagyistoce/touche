//
//  TFFlashXMLTUIOServer.h
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


@class TFFlashXMLTUIOServer, TFIPStreamSocket;

@interface NSObject (TFFlashXMLTUIOServerDelegate)
- (void)flashXmlTuioServerDidAcceptConnectionWithSocket:(TFIPStreamSocket*)socket;
@end

@class TFIPTCPSocket;

@interface TFFlashXMLTUIOServer : NSObject {
	id					delegate;

@protected
	TFIPTCPSocket*		_socket;
	NSThread*			_socketThread;
}

@property (assign) id delegate;

+ (void)initialize;

- (id)init;
- (id)initWithPort:(UInt16)port andLocalAddress:(NSString*)localAddress error:(NSError**)error;
- (void)dealloc;

- (void)invalidate;

- (NSString*)sockHost;
- (UInt16)sockPort;

#pragma mark -
#pragma mark TFIPStreamSocket delegate

- (void)socket:(TFIPStreamSocket*)socket didAcceptConnectionWithSocket:(TFIPStreamSocket*)connectionSocket;

@end
