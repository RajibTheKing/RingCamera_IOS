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


#include "CppInterfaceOfIPVSDK.h"
#include "ObjectiveCInterFace.h"

#include "Common.h"



//class CCppInterfaceOfVideoEngine;

//extern CCppInterfaceOfVideoEngine *g_pVideoEngineInterface;
class CVideoAPI;

class CVideoAPI : public CCppInterfaceOfIPVSDK
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

   
    queue<byte*> m_RenderQueue;
    queue<int> m_RenderDataLenQueue;
    pthread_mutex_t pRenderQueueMutex;
    
    
};

static CVideoAPI *m_pVideoAPI = NULL;



#endif /* VideoAPI_h */
