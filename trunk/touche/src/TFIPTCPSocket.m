//
//  TFIPTCPSocket.m
//  Touché
//
//  Created by Georg Kaindl on 20/8/08.
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

#import "TFIPTCPSocket.h"

#if !defined(WINDOWS)
#import <sys/socket.h>
#import <netinet/tcp.h>
#else
#import <winsock.h>
#endif


@implementation TFIPTCPSocket

- (id)init
{
	if (nil != (self = [super init])) {
		_sockType = SOCK_STREAM;
	}
	
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (BOOL)setTCPNoDelay:(BOOL)onOrOff
{
#if defined(WINDOWS)
	char val = onOrOff ? 1 : 0;
#else
	int val = onOrOff ? 1 : 0;
#endif
	return (setsockopt([self nativeSocketHandle], IPPROTO_TCP, TCP_NODELAY, &val, sizeof(val)) >= 0);
}

@end
