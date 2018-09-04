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
#include "VideoCameraProcessor.h"
#include "RingCallAudioManager.h"
#include "MessageProcessor.hpp"



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
void notifyClientMethodIos(int eventType)
{
    
}
void notifyClientMethodForFriendIos(int eventType, long long friendName, int iMedia)
{
    
}
void notifyClientMethodWithReceivedIos(int eventType, long long friendName, int iMedia, int dataLenth, unsigned char data[])
{
    
}






void notifyClientMethodWithPacketIos(long long lFriendID, unsigned char data[], int dataLenth)
{
    if(data != NULL)
    {
        cout << "lenghthadsfasdf " << dataLenth << endl;
        
        CVideoAPI::GetInstance()->SendPakcetFragments(data, dataLenth);
    }
}
void notifyClientMethodWithVideoDataIos(long long lFriendID, int mediaType, unsigned char data[], int dataLenth, int iVideoHeight, int iVideoWidth, int insetHeight, int insetWidth, int iOrientation)
{
    CVideoAPI::GetInstance()->m_iRecvFrameCounter++;
    
    //cout<<"Found Orientation  = "<<iOrientation<<", iVideoHeight = "<<iVideoHeight<<", iVideoWidth = "<<iVideoWidth<<", dataLen = "<<dataLenth<<", mediaType = "<<mediaType<<", InsetH:W = "<<insetHeight<<","<<insetWidth<<endl;
    string sStatusMessage = "Orientation = " + CVideoAPI::GetInstance()->IntegertoStringConvert(iOrientation) +
                            ", Height = " + CVideoAPI::GetInstance()->IntegertoStringConvert(iVideoHeight) +
                            ", Width = " + CVideoAPI::GetInstance()->IntegertoStringConvert(iVideoWidth);
    
    
    if(CVideoAPI::GetInstance()->m_iRecvFrameCounter%20 == 0)
    {
        [[VideoCameraProcessor GetInstance] UpdateStatusMessage:sStatusMessage];
    }
    /*
    
    if(data != NULL)
    {
        //cout << "lenghth2 " << dataLenth << endl;
        CVideoAPI::GetInstance()->m_iReceivedHeight = iVideoHeight;
        CVideoAPI::GetInstance()->m_iReceivedWidth = iVideoWidth;
        
        CVideoAPI::GetInstance()->ReceiveFullFrame(data, dataLenth);
    }
    */
    
    [[VideoThreadProcessor GetInstance] PushIntoClientRenderingBuffer:data withLen:dataLenth withHeight:iVideoHeight withWidth:iVideoWidth withOrientation:iOrientation];
    
    
}

void WriteToFileVideoAPI(byte *pData, int iLen);
void notifyClientMethodWithAudioDataIos(long long lFriendID, int mediaType, short data[], int dataLenth)
{
    //cout<<"Check: Found Audio Data, datalen = "<<dataLenth<<", mediaType = "<<mediaType<<endl;
    byte *temp = new byte[dataLenth*2];
    for(int i=0;i<dataLenth;i++)
    {
        temp[i*2] = data[i]>>8;
        temp[i*2+1] = data[i] & 0xFF;
        
    }
    
    //WriteToFileVideoAPI(temp, dataLenth*2);
    
    [[RingCallAudioManager sharedInstance] playMyReceivedAudioData:data withLength:dataLenth];
    delete[] temp;
    
}
void notifyClientMethodWithVideoNotificationIos(long long lCallID, int eventType) //Video Notification Added
{
    cout<<"Found Event type = "<<eventType<<endl;
    
    //CVideoAPI::GetInstance()->m_EventQueue.push(eventType);
    
    string sStatusMessage = "";

    if(eventType == SET_CAMERA_RESOLUTION_640x480_25FPS_NOT_SUPPORTED)
    {
        sStatusMessage = "Found SET_CAMERA_RESOLUTION_640x480_25FPS_NOT_SUPPORTED = " + CVideoAPI::GetInstance()->IntegertoStringConvert(eventType);
    }
    else if(eventType == SET_CAMERA_RESOLUTION_352x288_25FPS_NOT_SUPPORTED)
    {
        sStatusMessage = "Found SET_CAMERA_RESOLUTION_352x288_25FPS_NOT_SUPPORTED = " + CVideoAPI::GetInstance()->IntegertoStringConvert(eventType);
    }
    else if(eventType == SET_CAMERA_RESOLUTION_640x480_25FPS)
    {
        sStatusMessage = "Found SET_CAMERA_RESOLUTION_640x480_25FPS = " + CVideoAPI::GetInstance()->IntegertoStringConvert(eventType);
    }
    else if(eventType == SET_CAMERA_RESOLUTION_352x288_25FPS)
    {
        sStatusMessage = "Found SET_CAMERA_RESOLUTION_352x288_25FPS = " + CVideoAPI::GetInstance()->IntegertoStringConvert(eventType);
    }
    else if(eventType == SET_CAMERA_RESOLUTION_352x288)
    {
        sStatusMessage = "Found SET_CAMERA_RESOLUTION_352x288 = " + CVideoAPI::GetInstance()->IntegertoStringConvert(eventType);
        [[VideoCameraProcessor GetInstance] SetCameraResolutionByNotification:352 withWidth:288];
        cout<<"Call back operatin done"<<endl;
    }
    else if(eventType == SET_CAMERA_RESOLUTION_640x480)
    {
        sStatusMessage = "Found SET_CAMERA_RESOLUTION_640x480 = " + CVideoAPI::GetInstance()->IntegertoStringConvert(eventType);
        [[VideoCameraProcessor GetInstance] SetCameraResolutionByNotification:640 withWidth:480];
    }
    else
    {
        cout<<"notifyClientMethodWithVideoNotificationIos = lCallID:EventTYpe = "<<lCallID<<":"<<eventType<<endl;
        sStatusMessage = "Notified = " + CVideoAPI::GetInstance()->IntegertoStringConvert((int)lCallID)+":"+CVideoAPI::GetInstance()->IntegertoStringConvert(eventType);
    }
    
    cout<<sStatusMessage<<endl;
    [[VideoCameraProcessor GetInstance] UpdateStatusMessage:sStatusMessage];
    
}
int mx = 0;
void notifyClientMethodWithAudiPacketDataIos(long long lFriendID, unsigned char data[], int dataLenth)
{
    int iPacketType = (int)data[0];
    cout<<"NotifyClientMethodWithAudioPackt -->"<<dataLenth<<", packet = "<<iPacketType<< endl;
    if(mx<dataLenth)
    {
        mx = dataLenth;
        cout<<"MaxPacketLength -->"<<mx<<endl;
    }
    
    //CVideoAPI::GetInstance()->SendPakcetFragments(data, dataLenth);
    //VideoSockets::GetInstance()->SendToServer(data, dataLenth);
    VideoSockets::GetInstance()->SendToServerWithPacketize(data, dataLenth);
    
    
    
    
    //data[0] = (int)33;
    //printf("SendPacketFragment datalen = %d\n", iLen);
    
    /*memcpy(bAudioData+1, data, dataLenth);
    
    bAudioData[0] = (int)43;
    
    SendToServer(bAudioData, dataLenth+1);
    
    //CVideoAPI::GetInstance()->Send(200, 1, bAudioData, dataLenth+1);
     */
}

void notifyClientMethodWithAudioAlarmIos(long long lFriendID, int *data, int dataLenth)
{
    printf("notifyClientMethodWithAudioAlarmIos dataLenth = %d\n", dataLenth);
}

void notifyClientMethodWithNetworkStrengthNotificationIos(long long lCallID, int eventType)
{
    printf("notifyClientWithNetworkStrengthNotificationCallback eventType = %d\n", eventType);
    cout<<"notifyClientWithNetworkStrengthNotificationCallback : "<<eventType<<endl;
}

void notifyClientMethodWithSignalingDataIos(unsigned char *buffer, int iLen)
{
    CMessageProcessor::GetInstance()->Handle_Signaling_Message(buffer, iLen);
}

void notifyClientWithThumbnailDataIos(unsigned char data[], int iHeight, int iWidth, int dataLenth)
{
    printf("TheKing--> notifyClientWithThumbnailDataIos , iHeight, iWidth, dataLength = %d %d %d\n", iHeight, iWidth, dataLenth);
    MediatorClass *mediator = [MediatorClass GetInstance];
    [mediator.externalVideoProcessingDelegate ProcessBitmapData:data withHeight:iHeight withWidth:iWidth withLen:dataLenth];
    
}



CVideoAPI::CVideoAPI()
{
    cout<<"Inside CVideoAPI constructor"<<endl;
    pthread_mutex_init(&pRenderQueueMutex, NULL);
    m_bReInitialized = false;
    m_iRecvFrameCounter = 0;
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
    if(m_pVideoAPI == nullptr)
    {
        m_pVideoAPI = new CVideoAPI();
    }
    
    return m_pVideoAPI;
}

void CVideoAPI::SendPakcetFragments(byte  *data, int iLen)
{
    data[0] = (int)33;
    printf("SendPacketFragment datalen = %d\n", iLen);
    
    //SendToServer(data, iLen);
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

bool CVideoAPI::StartVideoCallV(long long lFriendID, int iVideoHeight, int iVideoWidth, int nServiceType, int nEntityType)
{
    return StartVideoCall(lFriendID, iVideoHeight, iVideoWidth, nServiceType, nEntityType, /*NetworkType*/0, /*bAudioOnlyLive*/false);
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
    //PushPacketForDecoding(lFriendID, in_data, in_size);
    
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
    return SetEncoderHeightWidth(lFriendID, width, height);
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

string CVideoAPI::IntegertoStringConvert(int nConvertingNumber)
{
    char cConvertedCharArray[12];
    
#ifdef _WIN32
    
    _itoa_s(nConvertingNumber, cConvertedCharArray, 10);
    
#else
    
    sprintf(cConvertedCharArray, "%d", nConvertingNumber);
    
#endif
    
    return (std::string)cConvertedCharArray;
}

@implementation MediatorClass

- (id) init
{
    self = [super init];
    NSLog(@"Inside MediatorClass Constructor");
    
    return self;
}

+ (id)GetInstance
{
    if(m_pMediatorClass == nil)
    {
        cout<<"Video_Team: m_pVideoCallProcessor Initialized"<<endl;
        
        m_pMediatorClass = [[MediatorClass alloc] init];
        
    }
    return m_pMediatorClass;
}

@end

/*void CVideoAPI::SendPakcetFragments(unsigned char*data, int dataLenth)
{
    printf("VideoTeam_Check: Inside SendPacketFragments\n");
    //data[0] = (int)33;
    //printf("SendPacketFragment datalen = %d\n", iLen);
    //SendToServer(data, iLen);
    
}*/

FILE *fpVideoApi;
bool isFpOpenVideoAPI = false;

void WriteToFileVideoAPI(byte *pData, int iLen)
{
    
    
    if(isFpOpenVideoAPI == false)
    {
        isFpOpenVideoAPI = true;
        NSFileHandle *handle;
        NSArray *Docpaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [Docpaths objectAtIndex:0];
        NSString *filePathyuv = [documentsDirectory stringByAppendingPathComponent:@"AudioReceiving.pcm"];
        handle = [NSFileHandle fileHandleForUpdatingAtPath:filePathyuv];
        char *filePathcharyuv = (char*)[filePathyuv UTF8String];
        fpVideoApi = fopen(filePathcharyuv, "wb");
    }
    
    printf("Writing to File\n");
    fwrite(pData, 1, iLen, fpVideoApi);
}



