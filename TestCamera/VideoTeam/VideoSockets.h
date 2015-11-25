//
//  VideoSockets.h
//  TestCamera 
//
//  Created by Apple on 11/18/15.
//
//

#ifndef VideoSockets_h
#define VideoSockets_h

#import "RingCallModule.h"
#include "Common.h"
#include "VideoAPI.hpp"
//#include "VideoCallProcessor.h"


@interface VideoSockets : NSObject
{
    CVideoAPI *m_pVideoAPI;
    long long m_lUserId;
    
    //VideoCallProcessor *m_pCallProcessor;
}


+ (id)GetInstance;
- (id) init;
- (void) SetVideoAPI:(CVideoAPI *)pVideoAPI;
- (void) SetUserID:(long long)lUserId;
- (void) InitializeSocket;
- (void) BindSocketToReceiveRemoteData;
- (void) PacketReceiverForVideoSendSocket;
- (void) PacketReceiverForVideoData;
- (void) PacketReceiver;


void InitializeSocketForRemoteUser(string sRemoteIp);
void InitializeServerSocketForRemoteUser(int &SocketFd, string sRemoteIp, int iRemotePort);
void SendToServer(byte sendingBytePacket[], int length);
void SendToVideoSocket(byte sendingBytePacket[], int length);
void SendToVideoSendSocket(byte sendingBytePacket[], int length);
void SendPacket(byte sendingBytePacket[], int length);

int ByteArrayToIntegerConvert( byte* rawData, int stratPoint );
@end

static VideoSockets *m_pVideoSockets = nil;
#endif /* VideoSockets_h */
