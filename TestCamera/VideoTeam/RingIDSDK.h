#ifndef RingIDSDK_h
#define RingIDSDK_h

#include <stdio.h>
#include <string>
#include <vector>

#ifdef TARGET_OS_WINDOWS_PHONE
#define LongLong __int64
#define IPVLongType LongLong
#else
#ifdef WIN32
typedef __int64 IPVLongType;
#else
typedef long long IPVLongType;
#endif

typedef long long LongLong;
#endif

#define MEDIA_TYPE_AUDIO 1
#define MEDIA_TYPE_VIDEO 2

#define ENABLE_MEDIA_CONNECTIVITY


#ifdef ENABLE_MEDIA_CONNECTIVITY
void AudioDecoding(LongLong lFriendID, unsigned char *in_data, int in_size, int insetID);
void notifyClientMethodWithSignalingDataIos(unsigned char *buffer, int iLen);
#else
void AudioDecoding(LongLong lFriendID, unsigned char *in_data, int in_size);
#endif

void VideoDecoding(LongLong lFriendID, unsigned char *in_data, int in_size);
void SendFunction(IPVLongType lFriendID, int mediaType, unsigned char* data, int iLen, int TimeDiff, std::vector< std::pair<int, int> > vAudioBlocks);

// End Video Team

#if defined(__APPLE__) || defined(_DESKTOP_C_SHARP_) || defined(TARGET_OS_WINDOWS_PHONE)

// Start NAT Traversal Team

void notifyClientMethodIos(int eventType);
void notifyClientMethodForFriendIos(int eventType, long long friendName, int iMedia);
void notifyClientMethodWithReceivedIos(int eventType, long long friendName, int iMedia, int dataLenth, unsigned char data[]);

// End NAT Traversal Team

// Start Video Team

void notifyClientMethodWithPacketIos(LongLong lFriendID, unsigned char data[], int dataLenth);
void notifyClientMethodWithVideoDataIos(LongLong lFriendID, int eventType, unsigned char data[], int dataLenth, int iVideoHeight, int iVideoWidth, int insetHeight, int insetWidth, int iOrienttation);
void notifyClientMethodWithVideoNotificationIos(LongLong lCallID, int eventType);
void notifyClientMethodWithNetworkStrengthNotificationIos(LongLong lCallID, int eventType);
void notifyClientMethodWithAudioDataIos(LongLong lFriendID, int eventType, short data[], int dataLenth);
void notifyClientMethodWithAudioAlarmIos(LongLong lFriendID, short data[], int dataLenth);
void notifyClientMethodWithAudioAlarmIos(LongLong lEventType, short data[], int dataLenth);
void notifyClientMethodWithAudiPacketDataIos(LongLong lFriendID, unsigned char data[], int dataLenth);

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
    
    bool Init(const LongLong& lUserID, const std::string& sLogFilePath, int logLevel);
    
    bool InitializeLibrary(const LongLong& lUserID);
    
    bool IsLoadRingIDSDK();
    
    // Start NAT Traversal Team
    
    bool SetAuthenticationServer(const LongLong& sAuthServerIP, int iAuthServerPort, const std::string& sAppSessionId);
    
    void SetTimeOutForSocket(int time_in_sec);
    
    int CreateSession(const LongLong& lFriendID, int mediaType, const LongLong& sRelayServerIP, int iRelayServerPort);
    
    int TransferFile(const LongLong& fileID, const LongLong& lFriendID, bool isSender, const std::string &filePath, LongLong fileOffset = -1);
    
    void CancelTransferFile(const LongLong& fileID, const LongLong& lFriendID, bool deleteFile);
    
    void SetRelayServerInformation(const LongLong& lFriendID, int mediaType, const LongLong& sRelayServerIP, int iRelayServerPort);
    
    void StartP2PCall(const LongLong& lFriendID, int medaiType, bool bCaller);
    
    bool IsConnectionTypeHostToHost(LongLong lFriendID, int mediaType);
    
    int SendTo(const LongLong& lFriendID, const int mediaType, unsigned char data[], int iLen, const LongLong& sDestinationIP, int iDestinationPort);
    
    std::string GetSelectedIPAddress(const LongLong& lFriendID, int mediaType);
    
    int GetSelectedPort(const LongLong& lFriendID, int mediaType);
    
    bool CloseSession(const LongLong& lFriendID, int mediaType);
    
    void SetNotifyClientMethodCallback(void (*ptr)(int));
    
    void SetNotifyClientMethodForFriendCallback(void (*ptr)(int, LongLong, int));
    
    void SetNotifyClientMethodWithReceivedBytesCallback(void (*ptr)(int, LongLong, int, int, unsigned char*));
    
    void SetNotifierForFileTransfer(void(*ptr)(int, LongLong, LongLong, LongLong, LongLong, double));
    
    // End NAT Traversal Team
    
    void Release();
    
    void UpdateInformation();
    
    void SetLogFileProperty(const std::string& loc, int logLevel, bool bCreate);
    
    void SetLogFileLocation(const std::string& loc);
    
    // Start Video Team
    
    int StartAudioEncodeDecodeSession();
    
    int EncodeAudioFrame(short *psaEncodingDataBuffer, int nAudioFrameSize, unsigned char *ucaEncodedDataBuffer);
    
    int DecodeAudioFrame(unsigned char *ucaDecodedDataBuffer, int nAudioFrameSize, short *psaDecodingDataBuffer);
    
    int StopAudioEncodeDecodeSession();
    
    int StartVideoMuxingAndEncodeSession(unsigned char *pBMP32Data,int iLen, int nVideoHeight, int nVideoWidth);
    int FrameMuxAndEncode( unsigned char *pVideoYuv, int iHeight, int iWidth);
    int StopVideoMuxingAndEncodeSession(unsigned char *finalData);
    
    bool StartAudioCall(const LongLong& lFriendID, int nServiceType, int entityType, int nAudioSpeakerType);
    
    bool StartCallInLive(const LongLong& llFriendID, int iRole, int nCallInLiveType);
    
    void SetCallInLiveType(const LongLong& llFriendID, int nCallInLiveType);
    
    bool EndCallInLive(const LongLong& lFriendID);
    
    bool SetVolume(const LongLong& lFriendID, int iVolume, bool bRecorder);
    
    bool SetSpeakerType(const LongLong& lFriendID, int iSpeakerType);
    
    bool SetEchoCanceller(const LongLong& lFriendID, bool bOn);
    
    bool StartVideoCall(const LongLong& llFriendID, int nVideoHeight, int nVideoWidth, int nServiceType, int nEntityType, int packetSizeOfNetwork = 0, int nNetworkType = 0, bool bAudioOnlyLive = false);
    
    void PushPacketForDecoding(LongLong lFriendID, int mediaType, int nEntityType, unsigned char *in_data, int in_size);
    
    void PushAudioForDecoding(LongLong lFriendID, int mediaType, int nEntityType, unsigned char *in_data, int in_size);
    
    int SendAudioData(const LongLong& lFriendID, short *in_data, unsigned int in_size);
    
    int CancelAudioData(const LongLong& lFriendID, short *in_data, unsigned int in_size);
    
    int SendVideoData(const LongLong& lFriendID, unsigned char *in_data, unsigned int in_size, unsigned int orientation_type=0, int device_orientation=0);
    
    int SetEncoderHeightWidth(const LongLong& lFriendID, int height, int width);
    
    int SetBitRate(const LongLong& lFriendID, int bitRate);
    
    int SetDeviceDisplayHeightWidth(int nVideoHeight, int nVideoWidth);
    
    int SetBeautification(const IPVLongType llFriendID, bool bIsEnable);
    
    int SetVideoEffect(const IPVLongType llFriendID, int nEffectStatus);
    
    int TestVideoEffect(const IPVLongType llFriendID, int *param, int size);
    
    
    bool StopAudioCall(const LongLong& lFriendID);
    
    bool StopVideoCall(const LongLong& lFriendID);
    
    int CheckDeviceCapability(const LongLong& lFriendID, int iHeightHigh, int iWidthHigh, int iHeightLow, int iWidthLow);
    int SetDeviceCapabilityResults(int iNotification, int iHeightHigh, int iWidthHigh, int iHeightLow, int iWidthLow);
    
    void InterruptOccured(const LongLong& lFriendID);
    
    void InterruptOver(const LongLong& lFriendID);
    
    bool SetLoggingState(bool loggingState, int logLevel=5);
    
    
    void SetNotifyClientWithPacketCallback(void(*callBackFunctionPointer)(LongLong, unsigned char*, int));
    
    void SetNotifyClientWithVideoDataCallback(void(*callBackFunctionPointer)(LongLong, int, unsigned char*, int, int, int, int, int, int));
    
    void SetNotifyClientWithVideoNotificationCallback(void(*callBackFunctionPointer)(LongLong, int));
    
    void SetNotifyClientWithNetworkStrengthNotificationCallback(void(*callBackFunctionPointer)(LongLong, int));
    
    void SetNotifyClientWithAudioDataCallback(void(*callBackFunctionPointer)(LongLong, int, short*, int));
    
    void SetNotifyClientWithAudioAlarmCallback(void(*callBackFunctionPointer)(LongLong, short*, int));
    
    void SetNotifyClientWithAudioPacketDataCallback(void(*callBackFunctionPointer)(LongLong, unsigned char*, int));
    
    
#ifdef ENABLE_MEDIA_CONNECTIVITY
    int InitializeMediaConnectivity(std::string sServerIP, int iPort, int iLogLevel);
    
    int ProcessCommand(std::string sCommand);
    
    int SendData(unsigned char *pData, int iLen);
    
    int UnInitializeMediaConnectivity();
#endif
    
    
    // End Video Team
    
    //private:
    
    // Start NAT Traversal Team
    
    CConnectivityEngine *m_pConnectivityInstance;
    
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
