
#ifndef _RING_SDK_DEFINITIONS_H_
#define _RING_SDK_DEFINITIONS_H_

#ifdef WIN32
typedef __int64 IPVLongType;
#else 
typedef long long IPVLongType;
#endif

#if (_DESKTOP_C_SHARP_)
#define EXPORT __declspec(dllexport)
#else
#define EXPORT
#endif

#if defined (WIN64)
typedef long long IPVType;
typedef unsigned long long u_IPVType;
#elif defined (WIN32)
typedef long IPVType;
typedef unsigned long u_IPVType;
#elif (__LP64__)
typedef long IPVType;
typedef unsigned long u_IPVType;
#elif (__LP32__)
typedef long IPVType;
typedef unsigned long u_IPVType;
#else
typedef long long IPVType;
typedef unsigned long long u_IPVType;
#endif

#endif