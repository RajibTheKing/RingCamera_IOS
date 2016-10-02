//
//  VideoAPI.h
//  TestCamera 
//
//  Created by IPV-VIDEO on 11/18/15.
//
//

#ifndef VideoAPI_h
#define VideoAPI_h

#include <string>
#include <iostream>
#include <queue>
using namespace std;


//#include "CppInterfaceOfRingSDK.h"
//#include "ObjectiveCInterFace.h"
#include "RingIDSDK.h"


#include "Common.h"



//class CCppInterfaceOfVideoEngine;

//extern CCppInterfaceOfVideoEngine *g_pVideoEngineInterface;

#define SET_CAMERA_RESOLUTION_640x480_25FPS 205
#define SET_CAMERA_RESOLUTION_640x480_25FPS_NOT_SUPPORTED 206
#define SET_CAMERA_RESOLUTION_352x288_25FPS 207
#define SET_CAMERA_RESOLUTION_352x288_25FPS_NOT_SUPPORTED 208

#define SET_CAMERA_RESOLUTION_352x288 210
#define SET_CAMERA_RESOLUTION_640x480 211

class CVideoAPI;

class CVideoAPI : public CRingIDSDK
{
    
public:
    
    CVideoAPI();
    ~CVideoAPI();
    
    //void SendPakcetFragments(byte *data, int iLen);
    //void ReceiveFullFrame(byte *data, int iLen, int frameNumber);
    
    //void notifyClientMethodWithPacket(int eventType, int frameNumber, int numberOfPackets, int packetNumber, int packetSize, int dataLenth, unsigned char data[]);
    //void notifyClientMethodWithFrame(int eventType, int frameNumber, int dataLenth, unsigned char data[], int iVideoHeight, int iVideoWidth);
    
    static CVideoAPI* GetInstance();
    
    bool InitV(long long lUserID, const char* sLoggerPath, int iLoggerPrintLevel);
    
    bool InitializeLibraryV(long long lUserID);
    
    bool SetUserNameV(long long lUserName);
    
    bool StartVideoCallV(long long lFriendID, int iVideoHeight, int iVideoWidth);
    
    int EncodeAndTransferV(long long lFriendID, unsigned char *in_data, unsigned int in_size);

    int SendVideoDataV(long long lFriendID, unsigned char *in_data, unsigned int in_size, int device_orientation, int  iOrientation);
    int SendAudioDataV(long long lFriendID, short *in_data, unsigned int in_size);
    
    int PushPacketForDecodingV(long long lFriendID, unsigned char *in_data, unsigned int in_size);
    
    //int PushReceivedPacketForMergingV(long long lFriendID, unsigned char *in_data, unsigned int in_size );
    
    //int DecodeV(long long lFriendID, unsigned char *in_data, unsigned int in_size, unsigned char *out_buffer, int &iVideoHeight, int &iVideoWidth);
    
    int SetHeightWidthV(long long lFriendID, int &width, int &height);
    
    int SetBitRateV(long long lFriendID, int &bitRate);
    
    bool StopVideoCallV(long long lFriendID);
    
    void UninitializeLibraryV();
    
    void DeleteStringV(string pString);
    
    void SetLoggerPathV(string sLoggerPath);
    

    void SendPakcetFragments(unsigned char*data, int dataLenth);
    
    void ReceiveFullFrame(byte*data, int iLen);
    
    void ReleaseV();
    
    
    //LiveStreamRelatedFunctions
    
    void setSendToNetworkFunction(long functionPointer);
    long GetSendToClientFunction();
    
    long GetSendToNetworkFunc();
    void setSendToClientFunc(long functionPointer);
    
    
    string startRudpSender(long ringId, string server);
    void startRudpReceiver(string streamId);
    
    void stopRudpSender();
    void stopRudpReceiver();
    

    string IntegertoStringConvert(int nConvertingNumber);
    
    queue<byte*> m_RenderQueue;
    queue<int> m_RenderDataLenQueue;
    pthread_mutex_t pRenderQueueMutex;
    int m_iReceivedHeight;
    int m_iReceivedWidth;
    
    queue<int> m_EventQueue;
    
    
    bool m_bReInitialized;
    int m_iRecvFrameCounter;
    
};

static CVideoAPI *m_pVideoAPI = NULL;



#endif /* VideoAPI_h */
