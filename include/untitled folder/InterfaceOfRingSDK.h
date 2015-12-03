
#ifndef _INTERFACE_OF_RING_SDK_H_
#define _INTERFACE_OF_RING_SDK_H_

#include <stdio.h>
#include <string>
#include <string.h>

#include "DLLLinkerOfRingSDK.h"

//static std::string Audio_Media = "audio";
//static std::string Video_Media = "video";
//static std::string Instant_Message = "chat";
//static std::string File_Transfer = "file_transfer";

/*enum MediaType
{
	IPV_UNKNOWN_MEDIA = 0,
	IPV_MEDIA_AUDIO = 1,
	IPV_MEDIA_VIDEO = 2,
	IPV_MEDIA_CHAT = 3,
	IPV_MEDIA_FILE_TRANSFER = 4
};*/


/*enum SessionStatus
{
	FAIL_TO_CREATE_SESSION,
	SESSION_CREATE_SUCCESSFULLY,
	ALREADY_SESSION_EXIST,
	NO_SESSION_AVAILABLE,
	INVALID_MEDIA,
	NONE
};*/


class CIPVStdString;

class CInterfaceOfRingSDK
{

public:

	virtual ~CInterfaceOfRingSDK() {};
	virtual bool Init(const IPVLongType& lUserID, const char* sLoggerPath, int iLoggerPrintLevel) = 0;
	virtual bool InitializeLibrary(const IPVLongType& lUserID) = 0;
	virtual bool SetUserName(const IPVLongType& lUserName) = 0;
	virtual bool StartVideoCall(const IPVLongType& lFriendID, int iVideoHeight, int iVideoWidth) = 0;
    virtual int EncodeAndTransfer(const IPVLongType& lFriendID, unsigned char *in_data, unsigned int in_size) = 0;
    virtual int PushPacketForDecoding(const IPVLongType& lFriendID, unsigned char *in_data, unsigned int in_size ) = 0;
    virtual int PushAudioForDecoding(const IPVLongType& lFriendID, unsigned char *in_data, unsigned int in_size) = 0;
    virtual int SendAudioData(const IPVLongType& lFriendID, short *in_data, unsigned int in_size) = 0;
    virtual int SendVideoData(const IPVLongType& lFriendID, unsigned char *in_data, unsigned int in_size) = 0;
    virtual int SendIMData(const IPVLongType& lFriendID, unsigned char *in_data, unsigned int in_size) = 0;
	virtual int SetHeightWidth(const IPVLongType& lFriendID, int width, int height) = 0;
	virtual int SetBitRate(const IPVLongType& lFriendID, int bitRate) = 0;
	virtual bool StopVideoCall(const IPVLongType& lFriendID) = 0;
	virtual void DeleteString(CIPVStdString* pString) = 0;

	virtual void SetNotifyClientWithPacketCallback(void(*callBackFunctionPointer)(IPVLongType, unsigned char*, int)) = 0;
	virtual void SetNotifyClientWithVideoDataCallback(void(*callBackFunctionPointer)(IPVLongType, unsigned char*, int, int, int)) = 0;
	virtual void SetNotifyClientWithAudioDataCallback(void(*callBackFunctionPointer)(IPVLongType, unsigned char*, int)) = 0;

	virtual bool SetAuthenticationServer(const CIPVStdString& sAuthServerIP, int iAuthServerPort, const CIPVStdString& sAppSessionId) = 0;
	virtual int CreateSession(const IPVLongType& lFriendID, int mediaType, const CIPVStdString& sRelayServerIP, int iRelayServerPort) = 0;
	virtual void SetRelayServerInformation(const IPVLongType& lFriendID, int mediaType, const CIPVStdString& sRelayServerIP, int iRelayServerPort) = 0;
	virtual void StartP2PCall(const IPVLongType& lFriendID, int mediaType, bool bCaller) = 0;
	virtual bool IsConnectionTypeHostToHost(IPVLongType lFriendID, int mediaType) = 0;
	virtual int Send(const IPVLongType& lFriendID, int mediaType, unsigned char data[], int iLen) = 0;
	virtual int SendTo(const IPVLongType& lFriendID, int mediaType, unsigned char data[], int iLen, const CIPVStdString& sDestinationIP, int iDestinationPort) = 0;
	virtual int Recv(const IPVLongType& lFriendID, int mediaType, unsigned char* data, int iLen) = 0;
	virtual std::string GetSelectedIPAddress(const IPVLongType& lFriendID, int mediaType) = 0;
	virtual int GetSelectedPort(const IPVLongType& lFriendID, int mediaType) = 0;
	virtual bool CloseSession(const IPVLongType& lFriendID, int mediaType) = 0;
	virtual void Release() = 0;
	virtual void InterfaceChanged() = 0;
	virtual void SetLogFileLocation(const CIPVStdString& loc) = 0;

	virtual void SetNotifyClientMethodCallback(void(*ptr)(int)) = 0;
	virtual void SetNotifyClientMethodForFriendCallback(void(*ptr)(int, IPVLongType, int)) = 0;
	virtual void SetNotifyClientMethodWithReceivedBytesCallback(void(*ptr)(int, IPVLongType, int, int, unsigned char*)) = 0;

};

class CIPVStdString
{
public:
	CIPVStdString()
		: m_iSize(0), m_pBytes(NULL)
	{}

	CIPVStdString(const std::string& s)
		: m_iSize((unsigned int)s.size()), m_pBytes(NULL)
	{
		if (m_iSize > 0)
		{
			m_pBytes = new char[m_iSize];
			memcpy(m_pBytes, s.data(), m_iSize);
		}
	}

	~CIPVStdString()
	{
		if (m_iSize > 0)
		{
			delete[] m_pBytes;
			m_iSize = 0;			// memoryLeck nn
			m_pBytes = NULL;		// memoryLeck nn
		}
	}

	CIPVStdString& operator=(const std::string& s)
	{
		if (m_iSize > 0)
		{
			delete[] m_pBytes;
		}

		m_iSize = (unsigned int)s.size();
		m_pBytes = NULL;

		if (m_iSize > 0)
		{
			m_pBytes = new char[m_iSize];
			memcpy(m_pBytes, s.data(), m_iSize);
		}
		return (*this);
	}

	operator std::string() const
	{
		if (m_iSize > 0)
		{
			return std::string(m_pBytes, m_iSize);
		}
		else
		{
			return std::string();
		}
	}

	inline bool IsHostListValid() const
	{
		return (m_pBytes != NULL);
	}

private:
	unsigned long m_iSize;
	char*         m_pBytes;
};

#endif