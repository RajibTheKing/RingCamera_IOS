
#ifndef _DLL_LINKER_OF_RING_SDK_H_
#define _DLL_LINKER_OF_RING_SDK_H_

#include <stdio.h>
#include <string>

#include "RingSDKDefinitions.h"

#ifndef _WIN32

extern "C" 
{

#endif

	IPVType RingSDK_Library(const char* sLoggerPath, int iLoggerPrintLevel);

#ifndef _WIN32

}

#endif

#endif