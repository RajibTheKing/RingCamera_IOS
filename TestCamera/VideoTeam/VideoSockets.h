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
#include "Common.hpp"
#include "VideoAPI.hpp"
//#include "VideoCallProcessor.h"


class VideoSockets
{
    
public:
    VideoSockets();
    ~VideoSockets();
    static VideoSockets* GetInstance();
    
    void StartDataReceiverThread();
    void StopDataReceiverThread();
    void SetUserID(long long lUserId);
    void InitializeSocket(string sActualServerIP, int sActualServerPort);
    void BindSocketToReceiveRemoteData();
    void PacketReceiverForVideoSendSocket();
    void PacketReceiverForVideoData();
    void PacketReceiver();
    void DataReceiverThread();
    

    void InitializeSocketForRemoteUser(string sRemoteIp);
    void InitializeServerSocketForRemoteUser(int &SocketFd, string sRemoteIp, int iRemotePort);
    
    void SendToServer(byte sendingBytePacket[], int length);
    void SendToServerWithPacketize(byte sendingBytePacket[], int length);
    
    void SendToVideoSocket(byte sendingBytePacket[], int length);
    void SendToVideoSendSocket(byte sendingBytePacket[], int length);
    void SendPacket(byte sendingBytePacket[], int length);
    void ProcessReceivedData(byte *recievedData, int length);
    
    int ByteArrayToIntegerConvert( byte* rawData, int stratPoint );
    CVideoAPI *m_pVideoAPI;
    long long m_lUserId;
    bool m_bDataReceiverThread;
    
    unsigned char m_ucaDatatoSendBuffer[MAXBUFFER_SIZE];
    unsigned char m_ucaDatatoReceiveBuffer[MAXBUFFER_SIZE];
    int m_iReceiveBufferIndex;
    
    int m_iPort;
};

static VideoSockets *m_pVideoSockets = NULL;
#endif /* VideoSockets_h */
