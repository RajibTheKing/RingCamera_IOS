#ifndef _INTERFACE_OF_VIDEO_ENGINE_H_
#define _INTERFACE_OF_VIDEO_ENGINE_H_

#include <stdio.h>
#include <string>
#include <string.h>

#include "DLLLinkerOfVideoEngine.h"

class CCustomString;

class CInterfaceOfVideoEngine
{

public:

	virtual ~CInterfaceOfVideoEngine() {};
	virtual bool Init(const LongLong& lUserID, const char* sLoggerPath, int iLoggerPrintLevel) = 0;
	virtual bool InitializeLibrary(const LongLong& lUserID) = 0;
	virtual bool SetUserName(const LongLong& lUserName) = 0;
	virtual bool StartVideoCall(const LongLong& lFriendID, int iVideoHeight, int iVideoWidth) = 0;
	virtual int EncodeAndTransfer(const LongLong& lFriendID, unsigned char *in_data, unsigned int in_size) = 0;
	virtual int PushPacketForDecoding(const LongLong& lFriendID, unsigned char *in_data, unsigned int in_size ) = 0;
	virtual int SetHeightWidth(const LongLong& lFriendID, int &width, int &height) = 0;
	virtual int SetBitRate(const LongLong& lFriendID, int &bitRate) = 0;
	virtual bool StopVideoCall(const LongLong& lFriendID) = 0;
	virtual void UninitializeLibrary() = 0;
	virtual void DeleteString(CCustomString* pString) = 0;
	virtual void SetLoggerPath(const CCustomString& sLoggerPath) = 0;
};

class CCustomString
{

public:

	CCustomString()
		: m_iSize(0), m_pBytes(NULL)
	{}

	CCustomString(const std::string& s): 
	m_iSize((unsigned int)s.size()), m_pBytes(NULL)
	{
		if (m_iSize > 0)
		{
			m_pBytes = new char[m_iSize];
			memcpy(m_pBytes, s.data(), m_iSize);
		}
	}

	~CCustomString()
	{
		if (m_iSize > 0)
		{
			delete[] m_pBytes;
			m_iSize = 0;			
			m_pBytes = NULL;		
		}
	}

	CCustomString& operator=(const std::string& s)
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