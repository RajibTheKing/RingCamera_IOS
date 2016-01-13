//
//  RIConnectivityAdapter.h
//  ringID
//
//  Created by Nagib Bin Azad on 9/7/15.
//  Copyright (c) 2015 IPVision Canada Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

//#import "IPVConnectivityDLL.h"
#import "RingIDSDK.h"
//#import "../header/IPVConnectivityDLL.h"

@interface RIConnectivityAdapter : NSObject

+(CRingIDSDK *)getCIPVConnectivityDLL;


+(BOOL)init:(const LongLong) userID sourceLogFilePath:(NSString *) sLogFilePath logLevel:(int) logLevel;
+(BOOL)initializeLibrary:(const LongLong) userID;
+(int)createSession:(const LongLong) friendID mediaType:(int) sMedia relayServerIP:(NSString *) relayServerIP relayServerPort:(int)relayServerPort;
+(void)startP2PCall:(const LongLong) friendID mediaType:(int) sMedia isCaller:(bool)isCaller;
+(void)setRelayServerInformation:(const LongLong) friendID mediaType:(int)sMedia relayServerIPAddress:(NSString *) relayServerIPAddress relayServerPort:(int) relayServerPort;
+(int)sendTo:(const LongLong) friendID mediaType:(int) sMedia data:(NSData *) data length:(int)len destinationAddress:(NSString *) dstAddress destinationPort:(int) dstPort;
+(BOOL)closeSession:(const LongLong) friendID mediaType:(int)sMedia;
+(void)setLogFileLocation:(NSString *) logFileLocation;
+(void)updateInformation;
+(void)release;
+(NSString *)getSelectedIPAddress:(const LongLong) friendID mediaType:(int)sMedia;
+(int)getSelectedPort:(const LongLong) friendID mediaType:(int)sMedia;
+(void)releaseLib ;
+(BOOL)setAuthenticationServerWith:(NSString *)authIp withPort:(int)port withSessionId:(NSString *)appSessionId;
//AudioVideoEngine
+(BOOL)startAudioCall:(const LongLong)friendID;
+(int)sendAudioData:(const LongLong)friendID audioData:(short *)data dataSize:(unsigned int)size;
+(BOOL)startVideoCall:(const LongLong)friendID videoHeight:(int)height videoWidth:(int)width;
+(int)sendVideoData:(const LongLong)friendID videoData:(NSData *)data dataSize:(unsigned int)size;
+(BOOL)stopAudioCall:(const LongLong)friendID;
+(BOOL)stopVideoCall:(const LongLong)friendID;
+(BOOL)setLoggingState:(bool)state logLevel:(int)level;
@end
