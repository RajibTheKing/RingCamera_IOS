#ifndef __IPV_CONNECTIVITY_DLL_C_INTERFACE_H_
#define __IPV_CONNECTIVITY_DLL_C_INTERFACE_H_

#ifdef WIN32
typedef __int64 IPVLongType;
#else 
typedef long long IPVLongType;
#endif

#include "IPVConnectivityDLL.h"

#include <string.h>
#include <stdlib.h>
#include <string>

#ifdef __cplusplus
extern "C" {
#endif

	int ipv_Init(const IPVLongType lUserID, const char* sLogFileLocation, int logLevel);

	int ipv_InitializeLibrary(const IPVLongType lUserID);

	int ipv_SetAuthenticationServer(const char* cAuthServerIP, int iAuthServerPort, const char* cAppSessionId);

	int ipv_CreateSession(const IPVLongType lFriendID, int mediaType, const char*  cRelayServerIP, int iRelayServerPort);

	void ipv_SetRelayServerInformation(const IPVLongType lFriendID, int mediaType, const char* cRelayServerIP, int iRelayServerPort);

	void ipv_StartP2PCall(const IPVLongType lFriendID, int mediaType, int bCaller);

	bool ipv_IsConnectionTypeHostToHost(IPVLongType lFriendID, int mediaType);
	
	int ipv_Send(const IPVLongType lFriendID, int mediaType, unsigned char data[], int iLen);

	int ipv_SendTo(const IPVLongType lFriendID, int mediaType, unsigned char data[], int iLen, const char* cDestinationIP, int iDestinationPort);
	
	int ipv_Recv(const IPVLongType lFriendID, int mediaType, unsigned char* data, int iLen);

	const char* ipv_GetSelectedIPAddress(const IPVLongType lFriendID, int mediaType);

	int ipv_GetSelectedPort(const IPVLongType lFriendID, int mediaType);
	
	int ipv_CloseSession(const IPVLongType lFriendID, int mediaType);

	void ipv_Release();

	void ipv_InterfaceChanged();

	void ipv_SetLogFileLocation(const char* loc);

    void ipv_SetNotifyClientMethodCallback(void (*ptr)(int));

    void ipv_SetNotifyClientMethodForFriendCallback(void (*ptr)(int, IPVLongType, int));

    void ipv_SetNotifyClientMethodWithReceivedBytesCallback(void (*ptr)(int, IPVLongType, int, int, unsigned char*));


#ifdef __cplusplus
}
#endif

#endif