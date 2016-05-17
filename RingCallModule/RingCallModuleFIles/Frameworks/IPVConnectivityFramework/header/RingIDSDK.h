#ifndef RingIDSDK_h
#define RingIDSDK_h

#include <stdio.h>
#include <string>
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

// Start NAT Traversal Team

void NotifyClientMethod(int event);
void NotifyClientMethodForFriend(int event, LongLong friendId, int mediaName);
void NotifyClientMethodWithReceivedBytes(int event, LongLong friendId, int mediaName, int dataLen, unsigned char* data);

// End NAT Traversal Team

// Start Video Team

void NotifyClientMethodWithPacket(LongLong lFriendID, unsigned char data[], int dataLenth);
void NotifyClientMethodWithVideoData(LongLong lFriendID, unsigned char data[], int dataLenth, int iVideoHeight, int iVideoWidth, int iOrienttation);
void NotifyClientMethodWithVideoNotification(LongLong lCallID, int eventType);
void NotifyClientMethodWithAudioData(LongLong lFriendID, short data[], int dataLenth);
void NotifyClientMethodWithAudiPacketData(LongLong lFriendID, unsigned char data[], int dataLenth);

void AudioDecoding(LongLong lFriendID, unsigned char *in_data, int in_size);
void VideoDecoding(LongLong lFriendID, unsigned char *in_data, int in_size);
void SendFunction(LongLong lFriendID, int mediaType, unsigned char* data, int iLen);

// End Video Team

#if defined(__APPLE__) || defined(_DESKTOP_C_SHARP_) || defined(TARGET_OS_WINDOWS_PHONE)

// Start NAT Traversal Team

void notifyClientMethodIos(int eventType);
void notifyClientMethodForFriendIos(int eventType, long long friendName, int iMedia);
void notifyClientMethodWithReceivedIos(int eventType, long long friendName, int iMedia, int dataLenth, unsigned char data[]);

// End NAT Traversal Team

// Start Video Team

void notifyClientMethodWithPacketIos(LongLong lFriendID, unsigned char data[], int dataLenth);
void notifyClientMethodWithVideoDataIos(LongLong lFriendID, unsigned char data[], int dataLenth, int iVideoHeight, int iVideoWidth, int iOrienttation);
void notifyClientMethodWithVideoNotificationIos(LongLong lCallID, int eventType);
void notifyClientMethodWithAudioDataIos(LongLong lFriendID, short data[], int dataLenth);
void notifyClientMethodWithAudiPacketDataIos(LongLong lFriendID, unsigned char data[], int dataLenth);

// End Video Team

#endif

class CEventHandler;

// Start NAT Traversal Team

class CConnectivityEngine;

// End NAT Traversal Team

// Start Video Team

class CInterfaceOfAudioVideoEngine;

// End Video Team

class CRingIDSDK
{
    
public:
    
    static CEventHandler* m_pEventInstance;
    
    CRingIDSDK();
    ~CRingIDSDK();
    
    bool Init(const LongLong& lUserID, const std::string& sLogFilePath, int logLevel);
    
    bool InitializeLibrary(const LongLong& lUserID);
    
// Start NAT Traversal Team

    bool SetAuthenticationServer(const LongLong& sAuthServerIP, int iAuthServerPort, const std::string& sAppSessionId);
    
    void SetTimeOutForSocket(int time_in_sec);
    
    int CreateSession(const LongLong& lFriendID, int mediaType, const LongLong& sRelayServerIP, int iRelayServerPort);
    
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
    
    static void notifyClientMethodIos(int eventType);
    static void notifyClientMethodForFriendIos(int eventType, LongLong friendName, int iMedia);
    static void notifyClientMethodWithReceivedIos(int eventType, LongLong friendName, int iMedia, int dataLenth, unsigned char data[]);
    
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
    
    bool StartAudioCall(const LongLong& lFriendID);
    
    bool StartVideoCall(const LongLong& lFriendID, int iVideoHeight, int iVideoWidth, int iNetworkType = 0);
    
    void PushPacketForDecoding(LongLong lFriendID, unsigned char *in_data, int in_size );
    
    void PushAudioForDecoding(LongLong lFriendID, unsigned char *in_data, int in_size);
    
    int SendAudioData(const LongLong& lFriendID, short *in_data, unsigned int in_size);

    int SendVideoData(const LongLong& lFriendID, unsigned char *in_data, unsigned int in_size, unsigned int orientation_type = 0, int device_orientation = 0);
    
    int SetHeightWidth(const LongLong& lFriendID, int width, int height);
    
    int SetBitRate(const LongLong& lFriendID, int bitRate);
    
    bool StopAudioCall(const LongLong& lFriendID);
    
    bool StopVideoCall(const LongLong& lFriendID);

    int CheckDeviceCapability(const LongLong& lFriendID, int width, int height);
    
    bool SetLoggingState(bool loggingState, int logLevel=5);
    
    void SetNotifyClientWithPacketCallback(void(*callBackFunctionPointer)(LongLong, unsigned char*, int));
    
    void SetNotifyClientWithVideoDataCallback(void(*callBackFunctionPointer)(LongLong, unsigned char*, int, int, int, int));

    void SetNotifyClientWithVideoNotificationCallback(void(*callBackFunctionPointer)(LongLong, int));
    
    void SetNotifyClientWithAudioDataCallback(void(*callBackFunctionPointer)(LongLong, short*, int));
    
    void SetNotifyClientWithAudioPacketDataCallback(void(*callBackFunctionPointer)(LongLong, unsigned char*, int));
    
    static void notifyClientMethodWithPacketIos(LongLong lFriendID, unsigned char data[], int dataLenth);
    
    static void notifyClientMethodWithVideoDataIos(LongLong lFriendID, unsigned char data[], int dataLenth, int iVideoHeight, int iVideoWidth, int iOrienttation);

    static void notifyClientMethodWithVideoNotificationIos(LongLong lCallID, int eventType);
    
    static void notifyClientMethodWithAudioDataIos(LongLong lFriendID, short data[], int dataLenth);
    
    static void notifyClientMethodWithAudioPacketDataIos(LongLong lFriendID, unsigned char data[], int dataLenth);
    
// End Video Team
    
    
//private:
    
// Start NAT Traversal Team
    
    CConnectivityEngine *m_pConnectivityInstance;
    
// End NAT Traversal Team
    
// Start Video Team
    
    CInterfaceOfAudioVideoEngine *m_pCinterfaceOfAudioVideoEngine;
    
// End Video Team
    
};


#endif
