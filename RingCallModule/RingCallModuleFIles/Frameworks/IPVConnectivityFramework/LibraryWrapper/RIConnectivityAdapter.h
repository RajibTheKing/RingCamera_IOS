//
//  RIConnectivityAdapter.h
//  ringID
//
//  Created by Nagib Bin Azad on 9/7/15.
//  Copyright (c) 2015 IPVision Canada Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "IPVConnectivityDLL.h"
//#import "../header/IPVConnectivityDLL.h"

@interface RIConnectivityAdapter : NSObject

+(CIPVConnectivityDLL *)getCIPVConnectivityDLL;

+(BOOL)init:(const IPVLongType) userID sourceLogFilePath:(NSString *) sLogFilePath logLevel:(int) logLevel;
+(BOOL)initializeLibrary:(const IPVLongType) userID;
+(int)createSession:(const IPVLongType) friendID mediaType:(MediaType) sMedia relayServerIP:(NSString *) relayServerIP relayServerPort:(int)relayServerPort;
+(void)startP2PCall:(const IPVLongType) friendID mediaType:(MediaType) sMedia isCaller:(bool)isCaller;
+(void)setRelayServerInformation:(const IPVLongType) friendID mediaType:(MediaType)sMedia relayServerIPAddress:(NSString *) relayServerIPAddress relayServerPort:(int) relayServerPort;
+(int)send:(const IPVLongType) friendID mediaType:(MediaType) sMedia data:(NSData *) data length:(int)len;
+(int)sendTo:(const IPVLongType) friendID mediaType:(MediaType) sMedia data:(NSData *) data length:(int)len destinationAddress:(NSString *) dstAddress destinationPort:(int) dstPort;
+(BOOL)closeSession:(const IPVLongType) friendID mediaType:(MediaType)sMedia;
+(void)setLogFileLocation:(NSString *) logFileLocation;
+(void)release;
+(NSString *)getSelectedIPAddress:(const IPVLongType) friendID mediaType:(MediaType)sMedia;
+(int)getSelectedPort:(const IPVLongType) friendID mediaType:(MediaType)sMedia;
+(void)releaseLib ;
+(BOOL)setAuthenticationServerWith:(NSString *)authIp withPort:(int)port withSessionId:(NSString *)appSessionId;
+(void)InterfaceChanged;
@end
