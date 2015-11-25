//
//  RIConnectivityAdapter.m
//  ringID
//
//  Created by Nagib Bin Azad on 9/7/15.
//  Copyright (c) 2015 IPVision Canada Inc. All rights reserved.
//

#import "RIConnectivityAdapter.h"
#import "RIConnectivityManager.h"


static CIPVConnectivityDLL *cIPVConnectivity = nil;

@implementation RIConnectivityAdapter


+(CIPVConnectivityDLL *)getCIPVConnectivityDLL
{
    if (cIPVConnectivity == nil) {
        cIPVConnectivity = new CIPVConnectivityDLL;
    }
    return cIPVConnectivity;
}

+(BOOL)init:(const IPVLongType) userID
sourceLogFilePath:(NSString *) sLogFilePath
   logLevel:(int) logLevel
{
    std::string logFilePath([sLogFilePath UTF8String]);
    CIPVConnectivityDLL *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    return cIPVConnectivity->Init(userID, logFilePath, logLevel);
}

+(BOOL)initializeLibrary:(const IPVLongType) userID
{
    CIPVConnectivityDLL *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    return cIPVConnectivity->InitializeLibrary(userID);
}

+(int)createSession:(const IPVLongType) friendID
          mediaType:(MediaType) sMedia
      relayServerIP:(NSString *) relayServerIP
    relayServerPort:(int)relayServerPort
{
    std::string relayServerIPStr([relayServerIP UTF8String]);
    CIPVConnectivityDLL *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    return cIPVConnectivity->CreateSession(friendID, sMedia, relayServerIPStr, relayServerPort);
}

+(void)startP2PCall:(const IPVLongType) friendID mediaType:(MediaType) sMedia isCaller:(bool)isCaller
{
    CIPVConnectivityDLL *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    cIPVConnectivity->StartP2PCall(friendID, sMedia, isCaller);
}

+(void)setRelayServerInformation:(const IPVLongType) friendID
                       mediaType:(MediaType) sMedia
            relayServerIPAddress:(NSString *)relayServerIPAddress
                 relayServerPort:(int) relayServerPort
{
    
    std::string relayServerIPStr([relayServerIPAddress UTF8String]);
    CIPVConnectivityDLL *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    cIPVConnectivity->SetRelayServerInformation(friendID, sMedia, relayServerIPStr, relayServerPort);
}

+(int)send:(const IPVLongType) friendID
 mediaType:(MediaType) sMedia
      data:(NSData *) data
    length:(int)len
{
    if (!friendID || !sMedia || !data) {
        return -1;
    }

    unsigned char *sentData = (unsigned char *)[data bytes];
    int dataLength = (int)data.length;
    
    CIPVConnectivityDLL *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    return cIPVConnectivity->Send(friendID, sMedia, sentData, dataLength);
}

+(int)sendTo:(const IPVLongType) friendID
   mediaType:(MediaType) sMedia
        data:(NSData *) data
      length:(int)len
destinationAddress:(NSString *) dstAddress
destinationPort:(int) dstPort
{
    if (!friendID || !sMedia || !data || !dstAddress) {
        return -1;
    }
    
    
    std::string dstAddressStr([dstAddress UTF8String]);
    unsigned char *sentData = (unsigned char *)[data bytes];
    int dataLength = (int)data.length;
    CIPVConnectivityDLL *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    return cIPVConnectivity->SendTo(friendID, sMedia, sentData, dataLength, dstAddressStr, dstPort);
}


+(int)sendTo:(const IPVLongType) friendID
   mediaType:(MediaType) sMedia
        data:(NSData *) data
      length:(int)len
{
    if (!friendID || !sMedia || !data) {
        return -1;
    }

    
    unsigned char *sentData = (unsigned char *)[data bytes];
    int dataLength = (int)data.length;
    CIPVConnectivityDLL *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    return cIPVConnectivity->Send(friendID, sMedia, sentData, dataLength);

}


+(BOOL)closeSession:(const IPVLongType) friendID
          mediaType:(MediaType) sMedia
{
    
    CIPVConnectivityDLL *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    return cIPVConnectivity->CloseSession(friendID, sMedia);
}

+(void)setLogFileLocation:(NSString *) logFileLocation
{
    std::string logFileLocationStr([logFileLocation UTF8String]);
    CIPVConnectivityDLL *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    cIPVConnectivity->SetLogFileLocation(logFileLocationStr);
}

+(void)release
{
    CIPVConnectivityDLL *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    cIPVConnectivity->Release();
}

+(NSString *)getSelectedIPAddress:(const IPVLongType) friendID
                        mediaType:(MediaType) sMedia
{
    
    CIPVConnectivityDLL *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    std::string ipAddress = cIPVConnectivity->GetSelectedIPAddress(friendID, sMedia);
    
    return [NSString stringWithCString:ipAddress.c_str()
                              encoding:[NSString defaultCStringEncoding]];
}

+(int)getSelectedPort:(const IPVLongType) friendID
            mediaType:(MediaType) sMedia
{
    
    CIPVConnectivityDLL *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    return cIPVConnectivity->GetSelectedPort(friendID, sMedia);
    
}

+(void)releaseLib {

   CIPVConnectivityDLL *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    return cIPVConnectivity->Release();
}

+(void)InterfaceChanged {
    CIPVConnectivityDLL *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    cIPVConnectivity->InterfaceChanged();
}

+(BOOL)setAuthenticationServerWith:(NSString *)authIp withPort:(int)port withSessionId:(NSString *)appSessionId {
    
    CIPVConnectivityDLL *cIPVConnectivity = [[self class] getCIPVConnectivityDLL];
    std::string sAuthSeverIp([authIp UTF8String]);
    std::string sAppSessionId([appSessionId UTF8String]);
    return  cIPVConnectivity->SetAuthenticationServer(sAuthSeverIp, port, sAppSessionId);
}

@end
