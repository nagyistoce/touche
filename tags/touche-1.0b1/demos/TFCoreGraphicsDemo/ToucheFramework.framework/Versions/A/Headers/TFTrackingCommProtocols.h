//
//  TFTrackingCommProtocols.h
//  Touché
//
//  Created by Georg Kaindl on 5/2/08.
//  Copyright 2008 Georg Kaindl. All rights reserved.
//

#define		DEFAULT_SERVICE_NAME	(@"touche-multitouch-lib-service")

@protocol TFTrackingClientProtocol

- (BOOL)isAlive;
- (oneway void)disconnectedByServerWithError:(bycopy in NSError*)error;
- (bycopy NSDictionary*)clientInfo;
- (oneway void)clientShouldQuit;
- (oneway void)touchesBegan:(bycopy in NSSet*)touches;
- (oneway void)touchesUpdated:(bycopy in NSSet*)touches;
- (oneway void)touchesEnded:(bycopy in NSSet*)touches;

@end

@protocol TFTrackingServerProtocol

- (BOOL)registerClient:(byref id)client withName:(bycopy NSString*)name error:(bycopy out NSError**)error;
- (oneway void)unregisterClientWithName:(bycopy NSString*)name;
- (CGDirectDisplayID)screenId;
- (CGFloat)screenPixelsPerCentimeter;
- (CGFloat)screenPixelsPerInch;

@end