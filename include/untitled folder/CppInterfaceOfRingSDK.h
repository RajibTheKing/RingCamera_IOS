
#ifndef _CPP_INTERFACE_OF_RING_SDK_H_
#define _CPP_INTERFACE_OF_RING_SDK_H_

#include <stdio.h>
#include <string>

#ifdef _WIN32
#include <windows.h>
#else
#include <dlfcn.h>
#endif

#include "InterfaceOfRingSDK.h"
#include "DLLLinkerOfRingSDK.h"

#ifdef _WIN32
#define IPVisionLIB "RingSDK.dll"
#elif __ANDROID__
#define IPVisionLIB "libRingSDK.so"
#elif __linux__
#define IPVisionLIB "./libRingSDK.so"
#elif __APPLE__
#define IPVisionLIB "libRingSDK.dylib"
#endif

#define DYNAMIC_LIBRARY_NAME "RingSDK_Library"

typedef IPVType(*Fp_LibraryHandlePointerType)(const char*, int);

class CCppInterfaceOfRingSDK;

//extern CCppInterfaceOfRingSDK *g_CPPInterface;

class CCppInterfaceOfRingSDK
{

public:

	CCppInterfaceOfRingSDK() :
		
	m_pCInterfaceOfRingSDK(NULL),
	m_hLibraryHandleInstance(NULL)

	{
		//g_CPPInterface = this;
	}

	~CCppInterfaceOfRingSDK() 
	{

	}

	virtual void SendPakcetFragments(unsigned char*data, int dataLenth)
	{
		printf("Inside SendPakcetFragments parent\n");
	}

	virtual void ReceiveFullFrame(unsigned char*data, int dataLenth)
	{
		printf("Insdie g_CPPInterface->ReceiveFullFrame\n");
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

		bool bReturnedValue = LoadSelfLibrary(selfLibraryPath, "RingSDK.log", 5);

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
		if (m_pCInterfaceOfRingSDK)
		{
			return m_pCInterfaceOfRingSDK->StartVideoCall(lFriendID, iVideoHeight, iVideoWidth);
		}
		else
		{
			return false;
		}	
	}

    int EncodeAndTransfer(const IPVLongType& lFriendID, unsigned char *in_data, unsigned int in_size)
    {
        if (m_pCInterfaceOfRingSDK)
        {
            return m_pCInterfaceOfRingSDK->EncodeAndTransfer(lFriendID, in_data, in_size);
        }
        else
        {
            return -1;
        }
    }
    
    int PushPacketForDecoding(const IPVLongType& lFriendID, unsigned char *in_data, unsigned int in_size)
    {
        if (m_pCInterfaceOfRingSDK)
        {
            return m_pCInterfaceOfRingSDK->PushPacketForDecoding(lFriendID, in_data, in_size);
        }
        else
        {
            return -1;
        }
    }
    
    int PushAudioForDecoding(const IPVLongType& lFriendID, unsigned char *in_data, unsigned int in_size)
    {
        if (m_pCInterfaceOfRingSDK)
        {
            return m_pCInterfaceOfRingSDK->PushAudioForDecoding(lFriendID, in_data, in_size);
        }
        else
        {
            return -1;
        }
    }
    
    int SendAudioData(const IPVLongType& lFriendID, short *in_data, unsigned int in_size)
    {
        if (m_pCInterfaceOfRingSDK)
        {
            return m_pCInterfaceOfRingSDK->SendAudioData(lFriendID, in_data, in_size);
        }
        else
        {
            return -1;
        }
    }
    
    int SendVideoData(const IPVLongType& lFriendID, unsigned char *in_data, unsigned int in_size)
    {
        if (m_pCInterfaceOfRingSDK)
        {
            return m_pCInterfaceOfRingSDK->SendVideoData(lFriendID, in_data, in_size);
        }
        else
        {
            return -1;
        }
    }

	int SendIMData(const IPVLongType& lFriendID, unsigned char *in_data, unsigned int in_size)
	{
		if (m_pCInterfaceOfRingSDK)
		{
			return m_pCInterfaceOfRingSDK->SendIMData(lFriendID, in_data, in_size);
		}
		else
		{
			return -1;
		}
	}

	int SetHeightWidth(const IPVLongType& lFriendID, int width, int height)
	{
		if (m_pCInterfaceOfRingSDK)
		{
			return m_pCInterfaceOfRingSDK->SetHeightWidth(lFriendID, width, height);
		}
		else
		{
			return false;
		}
	}

	int SetBitRate(const IPVLongType& lFriendID, int bitRate)
	{
		if (m_pCInterfaceOfRingSDK)
		{
			return m_pCInterfaceOfRingSDK->SetBitRate(lFriendID, bitRate);
		}
		else
		{
			return false;
		}
	}

	bool StopVideoCall(const IPVLongType& lFriendID)
	{
		if (m_pCInterfaceOfRingSDK)
		{
			return m_pCInterfaceOfRingSDK->StopVideoCall(lFriendID);
		}
		else
		{
			return false;
		}
	}

	void SetNotifyClientWithPacketCallback(void(*callBackFunctionPointer)(IPVLongType, unsigned char*, int))
	{
		if (m_pCInterfaceOfRingSDK)
		{
			m_pCInterfaceOfRingSDK->SetNotifyClientWithPacketCallback(callBackFunctionPointer);
		}
	}

	void SetNotifyClientWithVideoDataCallback(void(*callBackFunctionPointer)(IPVLongType, unsigned char*, int, int, int))
	{
		if (m_pCInterfaceOfRingSDK)
		{
			m_pCInterfaceOfRingSDK->SetNotifyClientWithVideoDataCallback(callBackFunctionPointer);
		}
	}

	void SetNotifyClientWithAudioDataCallback(void(*callBackFunctionPointer)(IPVLongType, unsigned char*, int))
	{
		if (m_pCInterfaceOfRingSDK)
		{
			m_pCInterfaceOfRingSDK->SetNotifyClientWithAudioDataCallback(callBackFunctionPointer);
		}
	}

	bool SetAuthenticationServer(const std::string& sAuthServerIP, int iAuthServerPort, const std::string& sAppSessionId)
	{
		return (m_pCInterfaceOfRingSDK) ? m_pCInterfaceOfRingSDK->SetAuthenticationServer(sAuthServerIP, iAuthServerPort, sAppSessionId) : false;
	}

	int CreateSession(const IPVLongType& lFriendID, int mediaType, const std::string& sRelayServerIP, int iRelayServerPort)
	{
		return (m_pCInterfaceOfRingSDK) ? m_pCInterfaceOfRingSDK->CreateSession(lFriendID, mediaType, sRelayServerIP, iRelayServerPort) : 0;
	}

	void SetRelayServerInformation(const IPVLongType& lFriendID, int mediaType, const std::string& sRelayServerIP, int iRelayServerPort)
	{
		if (m_pCInterfaceOfRingSDK)
		{
			m_pCInterfaceOfRingSDK->SetRelayServerInformation(lFriendID, mediaType, sRelayServerIP, iRelayServerPort);
		}
	}

	void StartP2PCall(const IPVLongType& lFriendID, int medaiType, bool bCaller)
	{
		if (m_pCInterfaceOfRingSDK)
		{
			m_pCInterfaceOfRingSDK->StartP2PCall(lFriendID, medaiType, bCaller);
		}
	}

	bool IsConnectionTypeHostToHost(IPVLongType lFriendID, int mediaType)
	{
		if (m_pCInterfaceOfRingSDK)
		{
			return m_pCInterfaceOfRingSDK->IsConnectionTypeHostToHost(lFriendID, mediaType);
		}
		return false;
	}

	int Send(const IPVLongType& lFriendID, const int mediaType, unsigned char data[], int iLen)
	{
		return (m_pCInterfaceOfRingSDK) ? m_pCInterfaceOfRingSDK->Send(lFriendID, mediaType, data, iLen) : -1;
	}

	int SendTo(const IPVLongType& lFriendID, const int mediaType, unsigned char data[], int iLen, const std::string& sDestinationIP, int iDestinationPort)
	{
		return (m_pCInterfaceOfRingSDK) ? m_pCInterfaceOfRingSDK->SendTo(lFriendID, mediaType, data, iLen, sDestinationIP, iDestinationPort) : -1;
	}

	int Recv(const IPVLongType& lFriendID, int mediaType, unsigned char* data, int iLen)
	{
		return (m_pCInterfaceOfRingSDK) ? m_pCInterfaceOfRingSDK->Recv(lFriendID, mediaType, data, iLen) : -1;
	}

	std::string GetSelectedIPAddress(const IPVLongType& lFriendID, int mediaType)
	{
		return (m_pCInterfaceOfRingSDK) ? m_pCInterfaceOfRingSDK->GetSelectedIPAddress(lFriendID, mediaType) : "";
	}

	int GetSelectedPort(const IPVLongType& lFriendID, int mediaType)
	{
		return (m_pCInterfaceOfRingSDK) ? m_pCInterfaceOfRingSDK->GetSelectedPort(lFriendID, mediaType) : -1;
	}

	bool CloseSession(const IPVLongType& lFriendID, int mediaType)
	{
		return (m_pCInterfaceOfRingSDK) ? m_pCInterfaceOfRingSDK->CloseSession(lFriendID, mediaType) : false;
	}

	void Release()
	{
		if (m_pCInterfaceOfRingSDK)
		{
			m_pCInterfaceOfRingSDK->Release();
		}
	}

	/*void InterfaceChanged()
	{
		if (m_pCInterfaceOfRingSDK)
		{
			m_pCInterfaceOfRingSDK->InterfaceChanged();
		}
	}*/

	void SetLogFileLocation(const std::string& loc)
	{
		if (m_pCInterfaceOfRingSDK)
		{
			m_pCInterfaceOfRingSDK->SetLogFileLocation(loc);
		}
	}

	void SetNotifyClientMethodCallback(void(*ptr)(int))
	{
		if (m_pCInterfaceOfRingSDK)
		{
			m_pCInterfaceOfRingSDK->SetNotifyClientMethodCallback(ptr);
		}
	}

	void SetNotifyClientMethodForFriendCallback(void(*ptr)(int, IPVLongType, int))
	{
		if (m_pCInterfaceOfRingSDK)
		{
			m_pCInterfaceOfRingSDK->SetNotifyClientMethodForFriendCallback(ptr);
		}
	}

	void SetNotifyClientMethodWithReceivedBytesCallback(void(*ptr)(int, IPVLongType, int, int, unsigned char*))
	{
		if (m_pCInterfaceOfRingSDK)
		{
			m_pCInterfaceOfRingSDK->SetNotifyClientMethodWithReceivedBytesCallback(ptr);
		}
	}

private:

	CInterfaceOfRingSDK* m_pCInterfaceOfRingSDK;

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

		if (NULL != m_pCInterfaceOfRingSDK)
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

		fpLibraryHandle = (Fp_LibraryHandlePointerType)GetProcAddress(m_hLibraryHandleInstance, DYNAMIC_LIBRARY_NAME);
            
#elif TARGET_OS_IPHONE
        
		fpLibraryHandle =  (Fp_LibraryHandlePointerType) RingSDK_Library;

#elif TARGET_IPHONE_SIMULATOR

		fpLibraryHandle =  (Fp_LibraryHandlePointerType) RingSDK_Library;

#else
        
		m_hLibraryHandleInstance = dlopen(IPVisionLIB, RTLD_LAZY);

		if (!m_hLibraryHandleInstance) 
		{
			printf("CCppInterfaceOfRingSDK::LoadSelfLibrary() Fail to Load.\n");

			return false;
		}

		fpLibraryHandle = (Fp_LibraryHandlePointerType)dlsym(m_hLibraryHandleInstance, DYNAMIC_LIBRARY_NAME);

#endif

		if (NULL == fpLibraryHandle)
		{
			return false;  // could not load function from DLL
		}

		m_pCInterfaceOfRingSDK = (CInterfaceOfRingSDK*)(fpLibraryHandle)(sLoggerPath.c_str(), iLoggerPrintLevel);

		if (NULL == m_pCInterfaceOfRingSDK)
		{
			return false;  // could not execute function
		}

		return true;
	}

	bool SetUserName(const IPVLongType& lUserName)
	{
		if (m_pCInterfaceOfRingSDK)
		{
			return m_pCInterfaceOfRingSDK->SetUserName(lUserName);
		}
		else
		{
			return false;
		}
	}

};

#endif