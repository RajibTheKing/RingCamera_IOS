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

#include "ObjectiveCInterFace.h"

void notifyClientMethodWithPacket(IPVLongType lFriendID, unsigned char data[], int dataLenth)
{
    //cout<<"Inside notifyClientMethodWithPacket"<<endl;
    CVideoAPI::GetInstance()->SendPakcetFragments(data, dataLenth);
}
void notifyClientMethodWithFrame(IPVLongType lFriendID, unsigned char data[], int dataLenth, int iVideoHeight, int iVideoWidth)
{
    //cout<<"Inside notifyClientMethodWithFrame"<<endl;
    CVideoAPI::GetInstance()->ReceiveFullFrame(data, dataLenth);}

CVideoAPI::CVideoAPI()
{
    cout<<"Inside CVideoAPI constructor"<<endl;
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
    
    printf("-->Received Full Frame Number = \n");
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

int CVideoAPI::EncodeAndTransferV(long long lFriendID, unsigned char *in_data, unsigned int in_size)
{
    return EncodeAndTransfer(lFriendID, in_data, in_size);
}

int CVideoAPI::PushPacketForDecodingV(long long lFriendID, unsigned char *in_data, unsigned int in_size)
{
    return PushPacketForDecoding(lFriendID, in_data, in_size);
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

void CVideoAPI::UninitializeLibraryV()
{
    //UninitializeLibraryV();
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


