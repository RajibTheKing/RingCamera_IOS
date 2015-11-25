#ifndef _CPP_INTERFACE_OF_IPV_SDK_H_
#define _CPP_INTERFACE_OF_IPV_SDK_H_

#include <stdio.h>
#include <string>

#ifdef _WIN32
#include <windows.h>
#else
#include <dlfcn.h>
#endif

#include "InterfaceOfIPVSDK.h"
#include "DLLLinkerOfIPVSDK.h"

#ifdef _WIN32
#define IPVisionLIB "IPV_SDK.dll"
#elif __ANDROID__
#define IPVisionLIB "libIPV_SDK.so"
#elif __linux__
#define IPVisionLIB "./libIPV_SDK.so"
#elif __APPLE__
#define IPVisionLIB "libIPV_SDK.dylib"
#endif

#define IPV_DLL_NAME "IPV_SDK_Library"

typedef IPVType(*Fp_LibraryHandlePointerType)(const char*, int);

class CCppInterfaceOfIPVSDK;


class CCppInterfaceOfIPVSDK
{

public:

	CCppInterfaceOfIPVSDK() :
		
	m_pCInterfaceOfIPVSDK(NULL),
	m_hLibraryHandleInstance(NULL)

	{
	}

	~CCppInterfaceOfIPVSDK() 
	{

	}

	bool Init(const IPVLongType& lUserID, const std::string& sLoggerPath, int iLoggerPrintLevel)
	{
		std::string selfLibraryPath = "";

		bool bReturnedValue = LoadSelfLibrary(selfLibraryPath, sLoggerPath, iLoggerPrintLevel);

		if (bReturnedValue)
		{
			bReturnedValue &= SetUserName(lUserID);
		}

		return bReturnedValue;
	}

	bool InitializeLibrary(const IPVLongType& lUserID)
	{
		std::string selfLibraryPath = "";

		bool bReturnedValue = LoadSelfLibrary(selfLibraryPath, "IPV_SDK.log", 5);

		if (bReturnedValue)
		{
			bReturnedValue &= SetUserName(lUserID);
		}

		return bReturnedValue;
	}

#ifdef _WIN32

	bool InitDLL(HINSTANCE hHandleInstance, const IPVLongType& lUserID, const std::string& sLoggerPath, int& iLoggerPrintLevel)
	{
		std::string selfLibraryPath = GetPathInString(GetModuleDirectory(hHandleInstance), IPVisionLIB);

		bool bReturnedValue = LoadSelfLibrary(selfLibraryPath, sLoggerPath, iLoggerPrintLevel);

		if (bReturnedValue)
		{
			bReturnedValue &= SetUserName(lUserID);
		}

		return bReturnedValue;
	}

	bool InitializeDLL(HINSTANCE hHandleInstance, const IPVLongType& lUserID)
	{
		std::string selfLibraryPath = GetPathInString(GetModuleDirectory(hHandleInstance), IPVisionLIB);

		bool bReturnedValue = LoadSelfLibrary(selfLibraryPath, "IPVSDKTrack.log", 5);

		if (bReturnedValue)
		{
			bReturnedValue &= SetUserName(lUserID);
		}

		return bReturnedValue;
	}

#endif

	bool StartVideoCall(const IPVLongType& lFriendID, int iVideoHeight, int iVideoWidth)
	{
		if (m_pCInterfaceOfIPVSDK)
		{
			return m_pCInterfaceOfIPVSDK->StartVideoCall(lFriendID, iVideoHeight, iVideoWidth);
		}
		else
		{
			return false;
		}	
	}

	int EncodeAndTransfer(const IPVLongType& lFriendID, unsigned char *in_data, unsigned int in_size)
	{
		if (m_pCInterfaceOfIPVSDK)
		{
			return m_pCInterfaceOfIPVSDK->EncodeAndTransfer(lFriendID, in_data, in_size);
		}
		else
		{
			return -1;
		}
	}

	int PushPacketForDecoding(const IPVLongType& lFriendID, unsigned char *in_data, unsigned int in_size)
	{
		if (m_pCInterfaceOfIPVSDK)
		{
			return m_pCInterfaceOfIPVSDK->PushPacketForDecoding(lFriendID, in_data, in_size);
		}
		else
		{
			return -1;
		}
	}

	int SetHeightWidth(const IPVLongType& lFriendID, int &width, int &height)
	{
		if (m_pCInterfaceOfIPVSDK)
		{
			return m_pCInterfaceOfIPVSDK->SetHeightWidth(lFriendID, width, height);
		}
		else
		{
			return false;
		}
	}

	int SetBitRate(const IPVLongType& lFriendID, int &bitRate)
	{
		if (m_pCInterfaceOfIPVSDK)
		{
			return m_pCInterfaceOfIPVSDK->SetBitRate(lFriendID, bitRate);
		}
		else
		{
			return false;
		}
	}

	bool StopVideoCall(const IPVLongType& lFriendID)
	{
		if (m_pCInterfaceOfIPVSDK)
		{
			return m_pCInterfaceOfIPVSDK->StopVideoCall(lFriendID);
		}
		else
		{
			return false;
		}
	}

	void SetNotifyClientWithPacketCallback(void(*callBackFunctionPointer)(unsigned char*, int))
	{
		if (m_pCInterfaceOfIPVSDK)
		{
			m_pCInterfaceOfIPVSDK->SetNotifyClientWithPacketCallback(callBackFunctionPointer);
		}
	}

	void SetNotifyClientWithFrameCallback(void(*callBackFunctionPointer)(unsigned char*, int, int, int))
	{
		if (m_pCInterfaceOfIPVSDK)
		{
			m_pCInterfaceOfIPVSDK->SetNotifyClientWithFrameCallback(callBackFunctionPointer);
		}
	}

	bool SetAuthenticationServer(const std::string& sAuthServerIP, int iAuthServerPort, const std::string& sAppSessionId)
	{
		return (m_pCInterfaceOfIPVSDK) ? m_pCInterfaceOfIPVSDK->SetAuthenticationServer(sAuthServerIP, iAuthServerPort, sAppSessionId) : false;
	}

	SessionStatus CreateSession(const IPVLongType& lFriendID, MediaType mediaType, const std::string& sRelayServerIP, int iRelayServerPort)
	{
		return (m_pCInterfaceOfIPVSDK) ? m_pCInterfaceOfIPVSDK->CreateSession(lFriendID, mediaType, sRelayServerIP, iRelayServerPort) : NONE;
	}

	void SetRelayServerInformation(const IPVLongType& lFriendID, MediaType mediaType, const std::string& sRelayServerIP, int iRelayServerPort)
	{
		if (m_pCInterfaceOfIPVSDK)
		{
			m_pCInterfaceOfIPVSDK->SetRelayServerInformation(lFriendID, mediaType, sRelayServerIP, iRelayServerPort);
		}
	}

	void StartP2PCall(const IPVLongType& lFriendID, MediaType medaiType, bool bCaller)
	{
		if (m_pCInterfaceOfIPVSDK)
		{
			m_pCInterfaceOfIPVSDK->StartP2PCall(lFriendID, medaiType, bCaller);
		}
	}

	bool IsConnectionTypeHostToHost(IPVLongType lFriendID, MediaType mediaType)
	{
		if (m_pCInterfaceOfIPVSDK)
		{
			return m_pCInterfaceOfIPVSDK->IsConnectionTypeHostToHost(lFriendID, mediaType);
		}
		return false;
	}

	int Send(const IPVLongType& lFriendID, const MediaType mediaType, unsigned char data[], int iLen)
	{
		return (m_pCInterfaceOfIPVSDK) ? m_pCInterfaceOfIPVSDK->Send(lFriendID, mediaType, data, iLen) : -1;
	}

	int SendTo(const IPVLongType& lFriendID, const MediaType mediaType, unsigned char data[], int iLen, const std::string& sDestinationIP, int iDestinationPort)
	{
		return (m_pCInterfaceOfIPVSDK) ? m_pCInterfaceOfIPVSDK->SendTo(lFriendID, mediaType, data, iLen, sDestinationIP, iDestinationPort) : -1;
	}

	int Recv(const IPVLongType& lFriendID, MediaType mediaType, unsigned char* data, int iLen)
	{
		return (m_pCInterfaceOfIPVSDK) ? m_pCInterfaceOfIPVSDK->Recv(lFriendID, mediaType, data, iLen) : -1;
	}

	std::string GetSelectedIPAddress(const IPVLongType& lFriendID, MediaType mediaType)
	{
		return (m_pCInterfaceOfIPVSDK) ? m_pCInterfaceOfIPVSDK->GetSelectedIPAddress(lFriendID, mediaType) : "";
	}

	int GetSelectedPort(const IPVLongType& lFriendID, MediaType mediaType)
	{
		return (m_pCInterfaceOfIPVSDK) ? m_pCInterfaceOfIPVSDK->GetSelectedPort(lFriendID, mediaType) : -1;
	}

	bool CloseSession(const IPVLongType& lFriendID, MediaType mediaType)
	{
		return (m_pCInterfaceOfIPVSDK) ? m_pCInterfaceOfIPVSDK->CloseSession(lFriendID, mediaType) : false;
	}

	void Release()
	{
		if (m_pCInterfaceOfIPVSDK)
		{
			m_pCInterfaceOfIPVSDK->Release();
		}
	}

	void InterfaceChanged()
	{
		if (m_pCInterfaceOfIPVSDK)
		{
			m_pCInterfaceOfIPVSDK->InterfaceChanged();
		}
	}

	void SetLogFileLocation(const std::string& loc)
	{
		if (m_pCInterfaceOfIPVSDK)
		{
			m_pCInterfaceOfIPVSDK->SetLogFileLocation(loc);
		}
	}

	void SetNotifyClientMethodCallback(void(*ptr)(int))
	{
		if (m_pCInterfaceOfIPVSDK)
		{
			m_pCInterfaceOfIPVSDK->SetNotifyClientMethodCallback(ptr);
		}
	}

	void SetNotifyClientMethodForFriendCallback(void(*ptr)(int, IPVLongType, int))
	{
		if (m_pCInterfaceOfIPVSDK)
		{
			m_pCInterfaceOfIPVSDK->SetNotifyClientMethodForFriendCallback(ptr);
		}
	}

	void SetNotifyClientMethodWithReceivedBytesCallback(void(*ptr)(int, IPVLongType, int, int, unsigned char*))
	{
		if (m_pCInterfaceOfIPVSDK)
		{
			m_pCInterfaceOfIPVSDK->SetNotifyClientMethodWithReceivedBytesCallback(ptr);
		}
	}

private:

	CInterfaceOfIPVSDK* m_pCInterfaceOfIPVSDK;

#ifdef _WIN32

	HINSTANCE m_hLibraryHandleInstance;

#else

	void *m_hLibraryHandleInstance;

#endif

#ifdef _WIN32

	std::string GetModuleDirectory(HMODULE hHandleInstance)
	{
		char szFileName[MAX_PATH];

#if !(defined(WINDOWS_UNIVERSAL) || defined(WINDOWS_PHONE_8))

		bool bReturnedValue = ( GetModuleFileNameA(hHandleInstance, szFileName, sizeof(szFileName) / sizeof(char)) != 0 );

#endif

		if (!bReturnedValue)
		{
			return "";
		}

		std::string sPathName = szFileName;
		std::string::size_type idx = sPathName.find_last_of('\\');

		if (idx == std::string::npos)
		{
			return "";
		}

		return sPathName.substr(0, idx);
	}

	std::string GetPathInString(const std::string& sDirectoryName, const std::string& sFileName)
	{
		if (sFileName.find_first_of('\\') != std::string::npos)
		{
			return "";
		}

		if (sDirectoryName.empty())
		{
			return sFileName;
		}

		if (sFileName.empty())
		{
			return sDirectoryName;
		}

		std::string sRet = sDirectoryName;

		if (sDirectoryName[sDirectoryName.length() - 1] != '\\')
		{
			sRet += '\\';
		}

		sRet += sFileName;

		return sRet;
	}

#endif

	bool LoadSelfLibrary(std::string m_sDllPath, std::string sLoggerPath, int iLoggerPrintLevel)
	{
		if (NULL != m_hLibraryHandleInstance)
		{
			return true;   // already loaded
		}

		if (NULL != m_pCInterfaceOfIPVSDK)
		{
			return true;
		}

		Fp_LibraryHandlePointerType fpLibraryHandle = NULL;

#ifdef _WIN32

		if (m_sDllPath.size() > 0)
		{

#if !(defined(WINDOWS_UNIVERSAL) || defined(WINDOWS_PHONE_8))

			m_hLibraryHandleInstance = LoadLibraryA(m_sDllPath.c_str());

#endif

		}

		if (NULL == m_hLibraryHandleInstance)
		{

#if !(defined(WINDOWS_UNIVERSAL) || defined(WINDOWS_PHONE_8))

			m_hLibraryHandleInstance = LoadLibraryA(IPVisionLIB);

#endif

			if (NULL == m_hLibraryHandleInstance)
			{
				return false;  // could not load DLL
			}
		}

		fpLibraryHandle = (Fp_LibraryHandlePointerType)GetProcAddress(m_hLibraryHandleInstance, IPV_DLL_NAME);
            
#elif TARGET_OS_IPHONE
        
		fpLibraryHandle =  (Fp_LibraryHandlePointerType) IPV_SDK_Library;

#elif TARGET_IPHONE_SIMULATOR

		fpLibraryHandle =  (Fp_LibraryHandlePointerType) IPV_SDK_Library;

#else
        
		m_hLibraryHandleInstance = dlopen(IPVisionLIB, RTLD_LAZY);

		if (!m_hLibraryHandleInstance) 
		{
			printf("CCppInterfaceOfIPVSDK::LoadSelfLibrary() Fail to Load.\n");

			return false;
		}

		fpLibraryHandle = (Fp_LibraryHandlePointerType)dlsym(m_hLibraryHandleInstance, IPV_DLL_NAME);

#endif

		if (NULL == fpLibraryHandle)
		{
			return false;  // could not load function from DLL
		}

		m_pCInterfaceOfIPVSDK = (CInterfaceOfIPVSDK*)(fpLibraryHandle)(sLoggerPath.c_str(), iLoggerPrintLevel);

		if (NULL == m_pCInterfaceOfIPVSDK)
		{
			return false;  // could not execute function
		}

		return true;
	}

	bool SetUserName(const IPVLongType& lUserName)
	{
		if (m_pCInterfaceOfIPVSDK)
		{
			return m_pCInterfaceOfIPVSDK->SetUserName(lUserName);
		}
		else
		{
			return false;
		}
	}

};

#endif