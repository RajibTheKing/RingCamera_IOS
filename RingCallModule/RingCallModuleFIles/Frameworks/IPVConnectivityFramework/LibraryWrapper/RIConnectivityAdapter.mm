//
//  RIConnectivityAdapter.m
//  ringID
//
//  Created by Nagib Bin Azad on 9/7/15.
//  Copyright (c) 2015 IPVision Canada Inc. All rights reserved.
//

#import "RIConnectivityAdapter.h"
#import "RIConnectivityManager.h"
#include <arpa/inet.h>

static CRingIDSDK *cIPVConnectivity = nil;

@implementation RIConnectivityAdapter


+(CRingIDSDK *)getCIPVConnectivityDLL
{
    if (cIPVConnectivity == nil) {
        cIPVConnectivity = new CRingIDSDK;
    }
    return cIPVConnectivity;
}

+(BOOL)init:(const LongLong) userID
sourceLogFilePath:(NSString *) sLogFilePath
   logLevel:(int) logLevel
{
    BOOL success = NO;
    std::string logFilePath([sLogFilePath UTF8String]);
    CRingIDSDK *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    success = cIPVConnectivity->Init(userID, logFilePath, logLevel);
    //cIPVConnectivity-> SetLoggingState(false);
    return success;
}

+(BOOL)initializeLibrary:(const LongLong) userID
{
    CRingIDSDK *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    //return cIPVConnectivity->InitializeLibrary(userID);
    return false;
}

+(int)createSession:(const LongLong) friendID
          mediaType:(int) sMedia
      relayServerIP:(NSString *) relayServerIP
    relayServerPort:(int)relayServerPort
{
    if (relayServerIP == nil) {
        return -1;
    }
    CRingIDSDK *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    //return cIPVConnectivity->CreateSession(friendID, sMedia, [RIConnectivityAdapter convertStringIPtoLongLong:relayServerIP], relayServerPort);
    return false;
}

+(void)startP2PCall:(const LongLong) friendID mediaType:(int) sMedia isCaller:(bool)isCaller
{
    //return; //StartP2PCall is disabled for Test Purpose by RajibTheKing
    CRingIDSDK *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    //cIPVConnectivity->StartP2PCall(friendID, sMedia, isCaller);
    return;
}

+(void)setRelayServerInformation:(const LongLong) friendID
                       mediaType:(int) sMedia
            relayServerIPAddress:(NSString *)relayServerIPAddress
                 relayServerPort:(int) relayServerPort
{
    if (relayServerIPAddress == nil) {
        return;
    }
    CRingIDSDK *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    //cIPVConnectivity->SetRelayServerInformation(friendID, sMedia, [RIConnectivityAdapter convertStringIPtoLongLong:relayServerIPAddress], relayServerPort);
    return;
}

+(int)sendTo:(const LongLong) friendID
   mediaType:(int) sMedia
        data:(NSData *) data
      length:(int)len
destinationAddress:(NSString *) dstAddress
destinationPort:(int) dstPort
{
    if (!friendID || !sMedia || !data || !dstAddress) {
        return -1;
    }
    unsigned char *sentData = (unsigned char *)[data bytes];
    int dataLength = (int)data.length;
    CRingIDSDK *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    
    //return cIPVConnectivity->SendTo(friendID, sMedia, sentData, dataLength, [RIConnectivityAdapter convertStringIPtoLongLong:dstAddress], dstPort);
    return -1;
}


+(BOOL)closeSession:(const LongLong) friendID
          mediaType:(int) sMedia
{
    
    CRingIDSDK *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    //return cIPVConnectivity->CloseSession(friendID, sMedia);
    return false;
}

+(void)setLogFileLocation:(NSString *) logFileLocation
{
    std::string logFileLocationStr([logFileLocation UTF8String]);
    CRingIDSDK *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    //cIPVConnectivity->SetLogFileLocation(logFileLocationStr);
    return;
}

+(void)updateInformation
{
    CRingIDSDK *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    //cIPVConnectivity->UpdateInformation();
    return;
}

+(void)release
{
    CRingIDSDK *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    //cIPVConnectivity->Release();
    return ;
}

+(NSString *)getSelectedIPAddress:(const LongLong) friendID
                        mediaType:(int) sMedia
{
    
    CRingIDSDK *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    //std::string ipAddress = cIPVConnectivity->GetSelectedIPAddress(friendID, sMedia);
    std::string ipAddress = "";
    return [NSString stringWithCString:ipAddress.c_str()
                              encoding:[NSString defaultCStringEncoding]];
}

+(int)getSelectedPort:(const LongLong) friendID
            mediaType:(int) sMedia
{
    
    CRingIDSDK *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    //return cIPVConnectivity->GetSelectedPort(friendID, sMedia);
    return -1;
    
}

+(void)releaseLib {
    
    CRingIDSDK *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    //return cIPVConnectivity->Release();
    return;
}

+(BOOL)setAuthenticationServerWith:(NSString *)authIp withPort:(int)port withSessionId:(NSString *)appSessionId {
    if (authIp == nil) {
        return NO;
    }
    CRingIDSDK *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    std::string sAppSessionId([appSessionId UTF8String]);
    //return  cIPVConnectivity->SetAuthenticationServer([RIConnectivityAdapter convertStringIPtoLongLong:authIp], port, sAppSessionId);
    return false;
}
//AudioVideoLibMethods

+(BOOL)startAudioCall:(const LongLong)friendID
{
    CRingIDSDK *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    //return cIPVConnectivity->StartAudioCall(friendID);
    return false;
}

+(int)sendAudioData:(const LongLong)friendID audioData:(short *)data dataSize:(unsigned int)size
{
    CRingIDSDK *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    //return cIPVConnectivity->SendAudioData(friendID, data, size);
    return -1;
}
+(BOOL)startVideoCall:(const LongLong)friendID videoHeight:(int)height videoWidth:(int)width
{
    CRingIDSDK *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    //cIPVConnectivity->SetLoggingState(false);
    //return cIPVConnectivity->StartVideoCall(friendID, height, width);
    return false;
}
+(int)sendVideoData:(const LongLong)friendID videoData:(NSData *)data dataSize:(unsigned int)size
{
    unsigned char *temp_data = (unsigned char*)[data bytes];
    CRingIDSDK *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    //return cIPVConnectivity->SendVideoData(friendID,temp_data, size,0,0);
    return -1;
}
+(BOOL)stopAudioCall:(const LongLong)friendID
{
    CRingIDSDK *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    //return cIPVConnectivity->StopAudioCall(friendID);
    return false;
}
+(BOOL)stopVideoCall:(const LongLong)friendID
{
    CRingIDSDK *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    //return cIPVConnectivity->StopVideoCall(friendID);
    return false;
}
+(BOOL)setLoggingState:(bool)state logLevel:(int)level
{
    CRingIDSDK *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    //return cIPVConnectivity->SetLoggingState(state);
    return false;
}
+(long long)convertStringIPtoLongLong:(NSString *)ipAddr
{
    struct in_addr addr;
    long long ip = 0;
    if (inet_aton([ipAddr UTF8String], &addr) != 0) {
        ip = addr.s_addr;
    }
    return ip;
}
@end
