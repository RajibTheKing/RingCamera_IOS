#ifndef RingIDSDK_h
#define RingIDSDK_h

#include <stdio.h>
#include <string>
#include <vector>


#define MEDIA_TYPE_AUDIO 1
#define MEDIA_TYPE_VIDEO 2

#define ENABLE_MEDIA_CONNECTIVITY


#ifdef ENABLE_MEDIA_CONNECTIVITY
void AudioDecoding(long long lFriendID, unsigned char *in_data, int in_size, int insetID);
void notifyClientMethodWithSignalingDataIos(unsigned char *buffer, int iLen);
#else
void AudioDecoding(long long lFriendID, unsigned char *in_data, int in_size);
#endif

void VideoDecoding(long long lFriendID, unsigned char *in_data, int in_size);
void SendFunction(long long lFriendID, int mediaType, unsigned char* data, int iLen, int TimeDiff, std::vector< std::pair<int, int> > vAudioBlocks);

// End Video Team

#if defined(__APPLE__) || defined(_DESKTOP_C_SHARP_) || defined(TARGET_OS_WINDOWS_PHONE)

// Start NAT Traversal Team

//void notifyClientMethodIos(int eventType);
//void notifyClientMethodForFriendIos(int eventType, long long friendName, int iMedia);
//void notifyClientMethodWithReceivedIos(int eventType, long long friendName, int iMedia, int dataLenth, unsigned char data[]);

// End NAT Traversal Team

// Start Video Team

void notifyClientMethodWithPacketIos(long long lFriendID, unsigned char data[], int dataLenth);
void notifyClientMethodWithVideoDataIos(long long lFriendID, int eventType, unsigned char data[], int dataLenth, int iVideoHeight, int iVideoWidth, int insetHeight, int insetWidth, int iOrienttation);
void notifyClientMethodWithVideoNotificationIos(long long lCallID, int eventType);
void notifyClientMethodWithNetworkStrengthNotificationIos(long long lCallID, int eventType);
void notifyClientMethodWithAudioDataIos(long long lFriendID, int eventType, short data[], int dataLenth);
void notifyClientMethodWithAudioAlarmIos(long long lFriendID, short data[], int dataLenth);
void notifyClientMethodWithAudioAlarmIos(long long lEventType, short data[], int dataLenth);
void notifyClientMethodWithAudiPacketDataIos(long long lFriendID, unsigned char data[], int dataLenth);
void notifyClientWithThumbnailDataIos(unsigned char data[], int iHeight, int iWidth, int dataLenth);

// End Video Team

#endif

class CEventHandler;

// Start NAT Traversal Team

class CConnectivityEngine;

// End NAT Traversal Team

// Start Video Team
namespace MediaSDK {
    class CInterfaceOfAudioVideoEngine;
}
// End Video Team

class CInterfaceOfMediaConnectivity;

class CRingIDSDK
{
    
public:
    
    static CEventHandler* m_pEventInstance;
    
    CRingIDSDK();
    ~CRingIDSDK();
    
    bool Init(const long long& lUserID, const std::string& sLogFilePath, int logLevel);
    
    bool InitializeLibrary(const long long& lUserID);
    
    bool IsLoadRingIDSDK();
    
    // Start NAT Traversal Team
    
    bool CloseSession(const long long& lFriendID, int mediaType);
    
    
    // End NAT Traversal Team
    
    void Release();
    
    
    void SetLogFileLocation(const std::string& loc);
    
    // Start Video Team
    
    int StartAudioEncodeDecodeSession();
    
    int EncodeAudioFrame(short *psaEncodingDataBuffer, int nAudioFrameSize, unsigned char *ucaEncodedDataBuffer);
    
    int DecodeAudioFrame(unsigned char *ucaDecodedDataBuffer, int nAudioFrameSize, short *psaDecodingDataBuffer);
    
    int StopAudioEncodeDecodeSession();
    
    int StartVideoMuxingAndEncodeSession(unsigned char *pBMP32Data,int iLen, int nVideoHeight, int nVideoWidth);
    int FrameMuxAndEncode( unsigned char *pVideoYuv, int iHeight, int iWidth);
    int StopVideoMuxingAndEncodeSession(unsigned char *finalData);
    
    bool StartAudioCall(const long long& lFriendID, int nServiceType, int entityType, int nAudioSpeakerType);
    
    bool StartCallInLive(const long long& llFriendID, int iRole, int nCallInLiveType);
    
    void SetCallInLiveType(const long long& llFriendID, int nCallInLiveType);
    
    bool EndCallInLive(const long long& lFriendID);
    
    bool SetVolume(const long long& lFriendID, int iVolume, bool bRecorder);
    
    bool SetSpeakerType(const long long& lFriendID, int iSpeakerType);
    
    bool SetEchoCanceller(const long long& lFriendID, bool bOn);
    
    bool StartVideoCall(const long long& llFriendID, int nVideoHeight, int nVideoWidth, int nServiceType, int nEntityType, int nNetworkType, bool bAudioOnlyLive);
    
    void PushPacketForDecoding(long long lFriendID, int mediaType, int nEntityType, unsigned char *in_data, int in_size);
    
    void PushAudioForDecoding(long long lFriendID, int mediaType, int nEntityType, unsigned char *in_data, int in_size);
    
    int SendAudioData(const long long& lFriendID, short *in_data, unsigned int in_size);
    
    int CancelAudioData(const long long& lFriendID, short *in_data, unsigned int in_size);
    
    int SendVideoData(const long long& lFriendID, unsigned char *in_data, unsigned int in_size, unsigned int orientation_type, int device_orientation);
    
    int SetEncoderHeightWidth(const long long& lFriendID, int height, int width);
    
    int SetBitRate(const long long& lFriendID, int bitRate);
    
    int SetDeviceDisplayHeightWidth(int nVideoHeight, int nVideoWidth);
    
    int SetBeautification(const long long llFriendID, bool bIsEnable);
    
    int SetVideoEffect(const long long llFriendID, int nEffectStatus);
    
    int TestVideoEffect(const long long llFriendID, int *param, int size);
    
    
    bool StopAudioCall(const long long& lFriendID);
    
    bool StopVideoCall(const long long& lFriendID);
    
    int CheckDeviceCapability(const long long& lFriendID, int iHeightHigh, int iWidthHigh, int iHeightLow, int iWidthLow);
    int SetDeviceCapabilityResults(int iNotification, int iHeightHigh, int iWidthHigh, int iHeightLow, int iWidthLow);
    
    void InterruptOccured(const long long& lFriendID);
    
    void InterruptOver(const long long& lFriendID);
    
    bool SetLoggingState(bool loggingState, int logLevel=5);
    
    
    void SetNotifyClientWithPacketCallback(void(*callBackFunctionPointer)(long long, unsigned char*, int));
    
    void SetNotifyClientWithVideoDataCallback(void(*callBackFunctionPointer)(long long, int, unsigned char*, int, int, int, int, int, int));
    
    void SetNotifyClientWithVideoNotificationCallback(void(*callBackFunctionPointer)(long long, int));
    
    void SetNotifyClientWithNetworkStrengthNotificationCallback(void(*callBackFunctionPointer)(long long, int));
    
    void SetNotifyClientWithAudioDataCallback(void(*callBackFunctionPointer)(long long, int, short*, int));
    
    void SetNotifyClientWithAudioAlarmCallback(void(*callBackFunctionPointer)(long long, short*, int));
    
    void SetNotifyClientWithAudioPacketDataCallback(void(*callBackFunctionPointer)(long long, unsigned char*, int));
    
    
    int StartExternalVideoProcessingSession();
    int SendH264EncodedDataToGetThumbnail(unsigned char *pH264Data, int iLen, int iThumbnailFrameNumber);
    int SendH264EncodedDataFilePathToGetThumbnail(const std::string& sFilePath, int iPositionToSelectFrame);
    int StopExternalVideoProcessingSession();
    void SetNotifyClientWithThumbnailDataCallback(void(*callBackFunctionPointer)(unsigned char[], int, int, int));
    
    
    
    
    
#ifdef ENABLE_MEDIA_CONNECTIVITY
    int InitializeMediaConnectivity(std::string sServerIP, int iPort, int iLogLevel);
    
    int ProcessCommand(std::string sCommand);
    
    int SendData(unsigned char *pData, int iLen);
    
    int UnInitializeMediaConnectivity();
    
    void SetNotifynotifyClientMethodWithSignalingDataCallback(void(*callBackFunctionPointer)(unsigned char*, int));
#endif
    
    
    // End Video Team
    
    //private:
    
    // Start NAT Traversal Team
    
    // CConnectivityEngine *m_pConnectivityInstance;
    
    // End NAT Traversal Team
    
    // Start Video Team
    
    MediaSDK::CInterfaceOfAudioVideoEngine *m_pCinterfaceOfAudioVideoEngine;
    
#ifdef ENABLE_MEDIA_CONNECTIVITY
    CInterfaceOfMediaConnectivity *m_pCinterfaceOfMediaConnectivity;
#endif
    
    int m_iMediaType, m_iServiceType, m_iEntityType, m_iCallInLiveType, m_iRole;
    
    // End Video Team
    
    
};


#endif
