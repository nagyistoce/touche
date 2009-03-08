//
//	CFRunLoop replacement stuff
//
//  Created by Georg Kaindl on 25/2/09.
//  Copyright 2009 Georg Kaindl. All rights reserved.

#import <Cocoa/Cocoa.h>

#import <AppKit/Win32EventInputSource.h>
#import <Foundation/NSHandleMonitor_win32.h>

typedef NSInputSource NSRunLoopSource;

void CFRunLoopAddSource(CFRunLoopRef self, CFRunLoopSourceRef source, CFStringRef mode)
{
	// unfortunately, cocotron's implementation of NSRunLoop is buggy with multiple threads,
	// so we always need to schedule on the main runloop.
	[[NSRunLoop mainRunLoop] addInputSource:(NSInputSource*)source forMode:NSDefaultRunLoopMode];
	
	// note: whenever we're calling this, it's to add this only one source to a threads
	// runloop. Since this doesn't work, running the runloop would return immediately, causing
	// the thread's "while" loop to consume a lot of CPU. Therefore, we "infinite loop" with a
	// sleep in between here, just to check for our thread being canceled, and return only
	// then. It's another ugly work-around that cocotron needs, unfortunately.
	while (![[NSThread currentThread] isCancelled])
		[NSThread sleepForTimeInterval:1.0];
}

Boolean CFRunLoopSourceIsValid(CFRunLoopSourceRef self)
{
	return [(NSInputSource*)self isValid];
}

void CFRunLoopSourceInvalidate(CFRunLoopSourceRef self)
{
	[(NSInputSource*)self invalidate];
	
	// again, we use the main runloop (see CFRunLoopAddSource)
	[[NSRunLoop mainRunLoop] removeInputSource:(NSInputSource*)self forMode:NSDefaultRunLoopMode];
}