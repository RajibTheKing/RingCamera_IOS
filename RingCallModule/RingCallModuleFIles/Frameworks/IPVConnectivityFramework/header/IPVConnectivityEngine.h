#ifndef __IPVConnectivityEngine_H_
#define __IPVConnectivityEngine_H_

#include <stdio.h>
#include <string>
//#include <windows>


#define IPV_ChatChannel  "chat"
#define IPV_AudioChannel "audio"
#define IPV_VideoChannel "video"


#include "IPVConnectivityInterface.h"

class CIPVManager;


class CIPVConnectivityEngine : public CIPVConnectivityInterface
{
public:
	CIPVConnectivityEngine();
	CIPVConnectivityEngine(const char* sLogFilePath, int logLevel);
	virtual ~CIPVConnectivityEngine();

	virtual bool Init(const IPVLongType& lUserID, const char* sLogFileLocation, int logLevel);

	virtual bool InitializeLibrary(const IPVLongType& lUserID);
	
	virtual bool SetUserName(const IPVLongType& lUserName);

	virtual bool SetAuthenticationServer(const CIPVStdString& sAuthServerIP, int iAuthServerPort,const CIPVStdString& sAppSessionId);
	
	virtual bool CreateSession(const IPVLongType& lFriendID, int iMedia, const CIPVStdString& sRelayServerIP, int iRelayServerPort);

	virtual void SetRelayServerInformation(const IPVLongType& lFriendID, int iMedia, const CIPVStdString& sRelayServerIP, int iRelayServerPort);
	
	void StartP2PCall(const IPVLongType& lFriendID, int iMedia, bool bCaller);

	bool IsConnectionTypeHostToHost(IPVLongType lFriendID, int mediaType);

	virtual int Send(const IPVLongType& lFriendID, int mediaType, unsigned char data[], int iLen);

	virtual int SendTo(const IPVLongType& lFriendID, int mediaType, unsigned char data[], int iLen, const CIPVStdString& sDestinationIP, int iDestinationPort);
	
	virtual int Recv(const IPVLongType& lFriendID, int iMedia, unsigned char* data, int iLen);

	virtual std::string GetSelectedIPAddress(const IPVLongType& lFriendID, int iMedia);

	virtual int GetSelectedPort(const IPVLongType& lFriendID, int iMedia);
	
	virtual bool CloseSession(const IPVLongType& lFriendID, int iMedia);
	
	virtual void Release();

	virtual void InterfaceChanged();

	virtual void SetLogFileLocation(const CIPVStdString& loc);

	virtual void DeleteString(CIPVStdString* pString);

    virtual void SetNotifyClientMethodCallback(void (*ptr)(int));

    virtual void SetNotifyClientMethodForFriendCallback(void (*ptr)(int, IPVLongType, int));

    virtual void SetNotifyClientMethodWithReceivedBytesCallback(void (*ptr)(int, IPVLongType, int, int, unsigned char*));

private:

	CIPVManager* m_pIPVManager;
};

#endif