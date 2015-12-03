#ifndef _INTERFACE_OF_AUDIO_VIDEO_ENGINE_H_
#define _INTERFACE_OF_AUDIO_VIDEO_ENGINE_H_

#include <stdio.h>
#include <string>

#ifdef WIN32
typedef __int64 IPVLongType;
#else 
typedef long long IPVLongType;
#endif

class CIPVManager;

class CInterfaceOFConnectivityEngine
{

public:

	CInterfaceOFConnectivityEngine();
	CInterfaceOFConnectivityEngine(const char* sLoggerPath, int iLoggerPrintLevel);
	virtual ~CInterfaceOFConnectivityEngine();

	virtual bool Init(const IPVLongType& lUserID, const char* sLogFileLocation, int logLevel);
	virtual bool InitializeLibrary(const IPVLongType& lUserID);
	virtual bool SetUserName(const IPVLongType& lUserName);
	virtual bool SetAuthenticationServer(const CIPVStdString& sAuthServerIP, int iAuthServerPort, const CIPVStdString& sAppSessionId);
	virtual SessionStatus CreateSession(const IPVLongType& lFriendID, MediaType iMedia, const CIPVStdString& sRelayServerIP, int iRelayServerPort);
	virtual void SetRelayServerInformation(const IPVLongType& lFriendID, MediaType iMedia, const CIPVStdString& sRelayServerIP, int iRelayServerPort);
	void StartP2PCall(const IPVLongType& lFriendID, MediaType iMedia, bool bCaller);
	bool IsConnectionTypeHostToHost(IPVLongType lFriendID, MediaType mediaType);
	void initializeEventHandler();
	virtual int Send(const IPVLongType& lFriendID, MediaType mediaType, unsigned char data[], int iLen);
	virtual int SendTo(const IPVLongType& lFriendID, MediaType mediaType, unsigned char data[], int iLen, const CIPVStdString& sDestinationIP, int iDestinationPort);
	virtual int Recv(const IPVLongType& lFriendID, MediaType iMedia, unsigned char* data, int iLen);
	virtual std::string GetSelectedIPAddress(const IPVLongType& lFriendID, MediaType iMedia);
	virtual int GetSelectedPort(const IPVLongType& lFriendID, MediaType iMedia);
	virtual bool CloseSession(const IPVLongType& lFriendID, MediaType iMedia);
	virtual void Release();
	virtual void InterfaceChanged();
	virtual void SetLogFileLocation(const CIPVStdString& loc);
	virtual void DeleteString(CIPVStdString* pString);
	virtual void SetNotifyClientMethodCallback(void(*ptr)(int));
	virtual void SetNotifyClientMethodForFriendCallback(void(*ptr)(int, IPVLongType, int));
	virtual void SetNotifyClientMethodWithReceivedBytesCallback(void(*ptr)(int, IPVLongType, int, int, unsigned char*));

private:

	CIPVManager* m_pIPVManager;
};

#endif