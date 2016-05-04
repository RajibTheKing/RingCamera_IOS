//
//  VideoAPI.m
//  TestCamera 
//
//  Created by IPV-VIDEO on 11/18/15.
//
//

#import <Foundation/Foundation.h>

#include "VideoAPI.hpp"
#include "VideoSockets.h"
#include "VideoCallProcessor.h"

//#include "ObjectiveCInterFace.h"

byte bAudioData[1000];

/*
void notifyClientMethodIos(int eventType)
{
    
}
 */
/*
void notifyClientMethodForFriendIos(int eventType, long long friendName, int iMedia)
{
    
}
 */
/*
void notifyClientMethodWithReceivedIos(int eventType, long long friendName, int iMedia, int dataLenth, unsigned char data[])
{
    
}
*/
// Audio

void notifyClientMethodWithPacketIos(LongLong lFriendID, unsigned char data[], int dataLenth)
{
    if(data != NULL)
    {
        cout << "lenghthadsfasdf " << dataLenth << endl;
        
        CVideoAPI::GetInstance()->SendPakcetFragments(data, dataLenth);
    }
}
void notifyClientMethodWithVideoDataIos(LongLong lFriendID, unsigned char data[], int dataLenth, int iVideoHeight, int iVideoWidth, int iOrientation)
{
    cout<<"Found Orientation  = "<<iOrientation<<endl;
    
    if(data != NULL)
    {
        //cout << "lenghth2 " << dataLenth << endl;
        CVideoAPI::GetInstance()->m_iReceivedHeight = iVideoHeight;
        CVideoAPI::GetInstance()->m_iReceivedWidth = iVideoWidth;
        
        CVideoAPI::GetInstance()->ReceiveFullFrame(data, dataLenth);
    }
}
void notifyClientMethodWithAudioDataIos(LongLong lFriendID, short data[], int dataLenth)
{
    //cout<<"Check: Found Audio Data"<<endl;
    
    [[RingCallAudioManager sharedInstance] playMyReceivedAudioData:data withLength:dataLenth];
}
void notifyClientMethodWithVideoNotificationIos(LongLong lCallID, int eventType) //Video Notification Added
{
    cout<<"Found Event type = "<<eventType<<endl;
    
    //CVideoAPI::GetInstance()->m_EventQueue.push(eventType);
    
    if(eventType == SET_CAMERA_RESOLUTION_640x480_25FPS_NOT_SUPPORTED)
    {
        cout<<"Found SET_CAMERA_RESOLUTION_640x480_25FPS_NOT_SUPPORTED = "<<eventType<<endl;
        [[VideoCallProcessor GetInstance] CheckCapabilityAgain];
    }
    
    if(eventType == SET_CAMERA_RESOLUTION_352x288_25FPS_NOT_SUPPORTED)
    {
        cout<<"Found SET_CAMERA_RESOLUTION_352x288_25FPS_NOT_SUPPORTED = "<<eventType<<endl;
        [[VideoCallProcessor GetInstance] StopCheckCapability];
    }
    
    if(eventType == SET_CAMERA_RESOLUTION_640x480_25FPS)
    {
        cout<<"Found SET_CAMERA_RESOLUTION_640x480_25FPS = "<<eventType<<endl;
        [[VideoCallProcessor GetInstance] StopCheckCapability];
    }
    if(eventType == SET_CAMERA_RESOLUTION_352x288_25FPS)
    {
        cout<<"Found SET_CAMERA_RESOLUTION_352x288_25FPS = "<<eventType<<endl;
        [[VideoCallProcessor GetInstance] StopCheckCapability];
    }
    
    if(eventType == SET_CAMERA_RESOLUTION_352x288)
    {
        cout<<"Found SET_CAMERA_RESOLUTION_352x288## = "<<eventType<<endl;
        [[VideoCallProcessor GetInstance] ReInitializeCamera:352 withWidth:288];
        cout<<"Call back operatin done"<<endl;
    }
    
    if(eventType == SET_CAMERA_RESOLUTION_640x480)
    {
        cout<<"Found SET_CAMERA_RESOLUTION_640x480## = "<<eventType<<endl;
        [[VideoCallProcessor GetInstance] ReInitializeCamera:640 withWidth:480];
    }
    
    cout<<"Returing from Notify call back"<<endl;
    
}
void notifyClientMethodWithAudiPacketDataIos(LongLong lFriendID, unsigned char data[], int dataLenth)
{
    int iPacketType = (int)data[0];
    cout<<"NotifyClientMethodWithAudioPackt -->"<<dataLenth<<", packet = "<<iPacketType<< endl;
    
    //CVideoAPI::GetInstance()->SendPakcetFragments(data, dataLenth);
    
    //data[0] = (int)33;
    //printf("SendPacketFragment datalen = %d\n", iLen);
    
    memcpy(bAudioData+1, data, dataLenth);
    
    bAudioData[0] = (int)43;
    
    SendToServer(bAudioData, dataLenth+1);
    
    //CVideoAPI::GetInstance()->Send(200, 1, bAudioData, dataLenth+1);
}

/*
void notifyClientMethodWithPacketIos(IPVLongType lFriendID, unsigned char data[], int dataLenth)
{
    //cout<<"Inside notifyClientMethodWithPacket"<<endl;
    CVideoAPI::GetInstance()->SendPakcetFragments(data, dataLenth);
}
void notifyClientMethodWithVideoDataIos(IPVLongType lFriendID, unsigned char data[], int dataLenth, int iVideoHeight, int iVideoWidth)
{
    //cout<<"Inside notifyClientMethodWithFrame"<<endl;
    CVideoAPI::GetInstance()->ReceiveFullFrame(data, dataLenth);
}

void notifyClientMethodWithAudiPacketDataIos(IPVLongType lFriendID, unsigned char data[], int dataLenth)
{
    int iPacketType = (int)data[0];
    cout<<"NotifyClientMethodWithAudioPackt -->"<<dataLenth<<", packet = "<<iPacketType<< endl;
   
    //CVideoAPI::GetInstance()->SendPakcetFragments(data, dataLenth);
    
    //data[0] = (int)33;
    //printf("SendPacketFragment datalen = %d\n", iLen);
    
    memcpy(bAudioData+1, data, dataLenth);
    
    bAudioData[0] = (int)43;
    
    //SendToServer(bAudioData, dataLenth+1);
    
    CVideoAPI::GetInstance()->Send(200, 1, bAudioData, dataLenth+1);
    
    
}



void notifyClientMethodWithAudioDataIos(IPVLongType lFriendID, short data[], int dataLenth)
{
    cout<<"notifyClientMethodWithAudioDataIos -->"<<dataLenth<< endl;
    [[RingCallAudioManager sharedInstance] playMyReceivedAudioData:data withLength:dataLenth];
    
}

void notifyClientMethodIos(int eventType)
{
    
}


void notifyClientMethodForFriendIos(int eventType, IPVLongType friendName, int mediaName)
{
 
}



void notifyClientMethodWithReceivedIos(int eventType, IPVLongType friendName, int mediaName, int dataLenth, unsigned char data[])
{
    
}


*/



CVideoAPI::CVideoAPI()
{
    cout<<"Inside CVideoAPI constructor"<<endl;
    pthread_mutex_init(&pRenderQueueMutex, NULL);
    m_bReInitialized = false;
    /*
    virtual bool SetAuthenticationServer(const CIPVStdString& sAuthServerIP, int iAuthServerPort, const CIPVStdString& sAppSessionId);
    virtual SessionStatus CreateSession(const IPVLongType& lFriendID, MediaType iMedia, const CIPVStdString& sRelayServerIP, int iRelayServerPort);
    virtual void SetRelayServerInformation(const IPVLongType& lFriendID, MediaType iMedia, const CIPVStdString& sRelayServerIP, int iRelayServerPort);
    void StartP2PCall(const IPVLongType& lFriendID, MediaType iMedia, bool bCaller);
    bool IsConnectionTypeHostToHost(IPVLongType lFriendID, MediaType mediaType);
    virtual int Send(const IPVLongType& lFriendID, MediaType mediaType, unsigned char data[], int iLen);
    virtual int SendTo(const IPVLongType& lFriendID, MediaType mediaType, unsigned char data[], int iLen, const CIPVStdString& sDestinationIP, int iDestinationPort);
    */
    
    

    
    
    
}



CVideoAPI* CVideoAPI::GetInstance()
{
    if(m_pVideoAPI == NULL)
    {
        m_pVideoAPI = new CVideoAPI();
    }
    return m_pVideoAPI;
}

void CVideoAPI::SendPakcetFragments(byte  *data, int iLen)
{
    data[0] = (int)33;
    printf("SendPacketFragment datalen = %d\n", iLen);
    
    SendToServer(data, iLen);
}

void CVideoAPI::ReceiveFullFrame(byte*data, int iLen)
{
    printf("-->Received Full Frame. Length = %d\n", iLen);
    byte* pNewData = (byte*)malloc(iLen + 100);
    memcpy(pNewData, data, iLen);
    
    
    m_RenderQueue.push(pNewData);
    m_RenderDataLenQueue.push(iLen);
    
}


/*
void notifyClientMethodWithPacket(int eventType, int frameNumber, int numberOfPackets, int packetNumber, int packetSize, int dataLenth, unsigned char data[])
{
    data[0] = (int)33;
    printf("SendPacketFragment datalen = %d\n", dataLenth);
    
    SendToServer(data, dataLenth);
}
void notifyClientMethodWithFrame(int eventType, int frameNumber, int dataLenth, unsigned char data[], int iVideoHeight, int iVideoWidth)
{
    printf("-->Received Full Frame Number = %d\n", frameNumber);
    byte* pNewData = (byte*)malloc(dataLenth + 100);
    memcpy(pNewData, data, dataLenth);
    
    
    //m_RenderQueue.push(pNewData);
    //m_RenderDataLenQueue.push(dataLenth);
}
*/





bool CVideoAPI::InitV(long long lUserID, const char* sLoggerPath, int iLoggerPrintLevel)
{
    printf("VideoTeam_Check: Init CVideoAPI\n");
    return Init(lUserID, sLoggerPath, iLoggerPrintLevel);
}

bool CVideoAPI::InitializeLibraryV(long long lUserID)
{
    return InitializeLibrary(lUserID);
}

bool CVideoAPI::SetUserNameV(long long lUserName)
{
    return false;
    //return SetUserName(lUserName);
}

bool CVideoAPI::StartVideoCallV(long long lFriendID, int iVideoHeight, int iVideoWidth)
{
    return StartVideoCall(lFriendID, iVideoHeight, iVideoWidth);
}

/*
int CVideoAPI::EncodeAndTransferV(long long lFriendID, unsigned char *in_data, unsigned int in_size)
{
    return EncodeAndTransfer(lFriendID, in_data, in_size);
}
*/

int CVideoAPI::SendVideoDataV(long long lFriendID, unsigned char *in_data, unsigned int in_size, int device_orientation, int iOrientation)
{
    return SendVideoData(lFriendID, in_data, in_size,0,0);
}

int CVideoAPI::SendAudioDataV(long long lFriendID, short *in_data, unsigned int in_size)
{
    return SendAudioData(lFriendID, in_data, in_size);
}

int CVideoAPI::PushPacketForDecodingV(long long lFriendID, unsigned char *in_data, unsigned int in_size)
{
    PushPacketForDecoding(lFriendID, in_data, in_size);
    
    return 1;
}
/*
int CVideoAPI::PushReceivedPacketForMergingV(long long lFriendID, unsigned char *in_data, unsigned int in_size )
{
    return PushReceivedPacketForMerging(lFriendID, in_data, in_size);
}



int CVideoAPI::DecodeV(long long lFriendID, unsigned char *in_data, unsigned int in_size, unsigned char *out_buffer, int &iVideoHeight, int &iVideoWidth)
{
    return Decode(lFriendID, in_data, in_size, out_buffer, iVideoHeight, iVideoWidth);
}
*/


int CVideoAPI::SetHeightWidthV(long long lFriendID, int &width, int &height)
{
    return SetHeightWidth(lFriendID, width, height);
}

int CVideoAPI::SetBitRateV(long long lFriendID, int &bitRate)
{
    return SetBitRate(lFriendID, bitRate);
}

bool CVideoAPI::StopVideoCallV(long long lFriendID)
{
    return StopVideoCall(lFriendID);
}

void CVideoAPI::ReleaseV()
{
     Release();
}

void CVideoAPI::UninitializeLibraryV()
{
    //UninitializeLibraryV();
    //Release();
    
}


void CVideoAPI::DeleteStringV(string pString)
{
    //DeleteString(pString);
}

void CVideoAPI::SetLoggerPathV(string sLoggerPath)
{
    //SetLoggerPathV(sLoggerPath);
}

/*void CVideoAPI::SendPakcetFragments(unsigned char*data, int dataLenth)
{
    printf("VideoTeam_Check: Inside SendPacketFragments\n");
    //data[0] = (int)33;
    //printf("SendPacketFragment datalen = %d\n", iLen);
    //SendToServer(data, iLen);
    
}*/


