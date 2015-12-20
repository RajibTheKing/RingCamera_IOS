#ifndef RingIDSDK_h
#define RingIDSDK_h

#include <stdio.h>
#include <string>

#define LongLong long long

// Start NAT Traversal Team

void NotifyClientMethod(int event);
void NotifyClientMethodForFriend(int event, LongLong friendId, int mediaName);
void NotifyClientMethodWithReceivedBytes(int event, LongLong friendId, int mediaName, int dataLen, unsigned char* data);

// End NAT Traversal Team

// Start Video Team

void NotifyClientMethodWithPacket(LongLong lFriendID, unsigned char data[], int dataLenth);
void NotifyClientMethodWithVideoData(LongLong lFriendID, unsigned char data[], int dataLenth, int iVideoHeight, int iVideoWidth);
void NotifyClientMethodWithAudioData(LongLong lFriendID, short data[], int dataLenth);
void NotifyClientMethodWithAudiPacketData(LongLong lFriendID, unsigned char data[], int dataLenth);

void AudioDecoding(LongLong lFriendID, unsigned char *in_data, int in_size);
void VideoDecoding(LongLong lFriendID, unsigned char *in_data, int in_size);
void SendFunction(LongLong lFriendID, int mediaType, unsigned char* data, int iLen);

// End Video Team

#ifdef __APPLE__

// Start NAT Traversal Team

void notifyClientMethodIos(int eventType);
void notifyClientMethodForFriendIos(int eventType, long long friendName, int iMedia);
void notifyClientMethodWithReceivedIos(int eventType, long long friendName, int iMedia, int dataLenth, unsigned char data[]);

// End NAT Traversal Team

// Start Video Team

void notifyClientMethodWithPacketIos(LongLong lFriendID, unsigned char data[], int dataLenth);
void notifyClientMethodWithVideoDataIos(LongLong lFriendID, unsigned char data[], int dataLenth, int iVideoHeight, int iVideoWidth);
void notifyClientMethodWithAudioDataIos(LongLong lFriendID, short data[], int dataLenth);
void notifyClientMethodWithAudiPacketDataIos(LongLong lFriendID, unsigned char data[], int dataLenth);

// End Video Team

#endif

class CEventHandler;

// Start NAT Traversal Team

class CIPVConnectivityDLL;

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

    bool SetAuthenticationServer(const std::string& sAuthServerIP, int iAuthServerPort, const std::string& sAppSessionId);
    
    int CreateSession(const LongLong& lFriendID, int mediaType, const std::string& sRelayServerIP, int iRelayServerPort);
    
    void SetRelayServerInformation(const LongLong& lFriendID, int mediaType, const std::string& sRelayServerIP, int iRelayServerPort);
    
    void StartP2PCall(const LongLong& lFriendID, int medaiType, bool bCaller);
    
    bool IsConnectionTypeHostToHost(LongLong lFriendID, int mediaType);
    
    int SendTo(const LongLong& lFriendID, const int mediaType, unsigned char data[], int iLen, const std::string& sDestinationIP, int iDestinationPort);
    
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
    
    void SetLogFileLocation(const std::string& loc);
    
// Start Video Team
    
    bool StartAudioCall(const LongLong& lFriendID);
    
    bool StartVideoCall(const LongLong& lFriendID, int iVideoHeight, int iVideoWidth);
    
    void PushPacketForDecoding(LongLong lFriendID, unsigned char *in_data, int in_size );
    
    void PushAudioForDecoding(LongLong lFriendID, unsigned char *in_data, int in_size);
    
    int SendAudioData(const LongLong& lFriendID, short *in_data, unsigned int in_size);
    
    int SendVideoData(const LongLong& lFriendID, unsigned char *in_data, unsigned int in_size);
    
    int SetHeightWidth(const LongLong& lFriendID, int width, int height);
    
    int SetBitRate(const LongLong& lFriendID, int bitRate);
    
    bool StopAudioCall(const LongLong& lFriendID);
    
    bool StopVideoCall(const LongLong& lFriendID);
    
    bool SetLoggingState(bool loggingState, int logLevel=5);
    
    void SetNotifyClientWithPacketCallback(void(*callBackFunctionPointer)(LongLong, unsigned char*, int));
    
    void SetNotifyClientWithVideoDataCallback(void(*callBackFunctionPointer)(LongLong, unsigned char*, int, int, int));
    
    void SetNotifyClientWithAudioDataCallback(void(*callBackFunctionPointer)(LongLong, short*, int));
    
    void SetNotifyClientWithAudioPacketDataCallback(void(*callBackFunctionPointer)(LongLong, unsigned char*, int));
    
    static void notifyClientMethodWithPacketIos(LongLong lFriendID, unsigned char data[], int dataLenth);
    
    static void notifyClientMethodWithVideoDataIos(LongLong lFriendID, unsigned char data[], int dataLenth, int iVideoHeight, int iVideoWidth);
    
    static void notifyClientMethodWithAudioDataIos(LongLong lFriendID, short data[], int dataLenth);
    
    static void notifyClientMethodWithAudioPacketDataIos(LongLong lFriendID, unsigned char data[], int dataLenth);
    
// End Video Team
    
    
//private:
    
// Start NAT Traversal Team
    
    CIPVConnectivityDLL *m_pConnectivityInstance;
    
// End NAT Traversal Team
    
// Start Video Team
    
    CInterfaceOfAudioVideoEngine *m_pCinterfaceOfAudioVideoEngine;
    
// End Video Team
    
};


#endif