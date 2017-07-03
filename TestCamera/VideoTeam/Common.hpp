//
//  Common.h
//  TestCamera 
//
//  Created by IPV-VIDEO on 11/18/15.
//
//

#ifndef Common_h
#define Common_h

#include <sstream>
#include <cstdlib>


#include <time.h>
#include <chrono>
#include <stdio.h>
#include <ctime>
#include <chrono>

#import <sys/utsname.h>

using namespace std;



//#define printf(...)
#define MAXWIDTH 1280
#define MAXHEIGHT 1280
#define MAXBUFFER_SIZE 500000
#define byte unsigned char
#define MAX_FRAME_SIZE (MAXWIDTH * MAXHEIGHT * 3 / 2)

#define MEDIA_TYPE_AUDIO 1
#define MEDIA_TYPE_VIDEO 2
#define MEDIA_TYPE_LIVE_STREAM 3

#define SERVICE_TYPE_CALL 11
#define SERVICE_TYPE_SELF_CALL 13

#define ENTITY_TYPE_CALLER 31

#define SERVICE_TYPE_LIVE_STREAM 12
#define SERVICE_TYPE_SELF_STREAM 14

#define ENTITY_TYPE_PUBLISHER 31
#define ENTITY_TYPE_VIEWER 32
#define ENTITY_TYPE_VIEWER_CALLEE 2
#define ENTITY_TYPE_PUBLISHER_CALLER 1

#define FULL_PACKET_CODE 100
#define LAST_PACKET_CODE 99
#define MAX_SEND_BUFFER_SIZE 9000

#define PUBLISHER_IN_CALL 1
#define VIEWER_IN_CALL 2
#define CALL_NOT_RUNNING 4;

class CCommon
{
public:
    CCommon();
    ~CCommon();
};


static long long CurrentTimeStamp()
{
    namespace sc = std::chrono;
    auto time = sc::system_clock::now(); // get the current time
    auto since_epoch = time.time_since_epoch(); // get the duration since epoch
    // I don't know what system_clock returns
    // I think it's uint64_t nanoseconds since epoch
    // Either way this duration_cast will do the right thing
    auto millis = sc::duration_cast<sc::milliseconds>(since_epoch);
    long long now = millis.count(); // just like java (new Date()).getTime();
    return now;
}
static void SOSleep(int nSleepTimeout)
{
    timespec t;
    
    u_int32_t seconds = nSleepTimeout / 1000;
    t.tv_sec = seconds;
    t.tv_nsec = (nSleepTimeout - (seconds * 1000)) * (1000 * 1000);
    
    nanosleep(&t, NULL);
    
}
static std::string getDeviceModel()
{
    /*
     //Simultor
     @"i386"      on 32-bit Simulator
     @"x86_64"    on 64-bit Simulator
     
     //iPhone
     @"iPhone1,1" on iPhone
     @"iPhone1,2" on iPhone 3G
     @"iPhone2,1" on iPhone 3GS
     @"iPhone3,1" on iPhone 4 (GSM)
     @"iPhone3,3" on iPhone 4 (CDMA/Verizon/Sprint)
     @"iPhone4,1" on iPhone 4S
     @"iPhone5,1" on iPhone 5 (model A1428, AT&T/Canada)
     @"iPhone5,2" on iPhone 5 (model A1429, everything else)
     @"iPhone5,3" on iPhone 5c (model A1456, A1532 | GSM)
     @"iPhone5,4" on iPhone 5c (model A1507, A1516, A1526 (China), A1529 | Global)
     @"iPhone6,1" on iPhone 5s (model A1433, A1533 | GSM)
     @"iPhone6,2" on iPhone 5s (model A1457, A1518, A1528 (China), A1530 | Global)
     @"iPhone7,1" on iPhone 6 Plus
     @"iPhone7,2" on iPhone 6
     @"iPhone8,1" on iPhone 6S
     @"iPhone8,2" on iPhone 6S Plus
     @"iPhone8,4" on iPhone SE
     @"iPhone9,1" on iPhone 7 (CDMA)
     @"iPhone9,3" on iPhone 7 (GSM)
     @"iPhone9,2" on iPhone 7 Plus (CDMA)
     @"iPhone9,4" on iPhone 7 Plus (GSM)
     
     //iPad 1
     @"iPad1,1" on iPad - Wifi (model A1219)
     @"iPad1,1" on iPad - Wifi + Cellular (model A1337)
     
     //iPad 2
     @"iPad2,1" - Wifi (model A1395)
     @"iPad2,2" - GSM (model A1396)
     @"iPad2,3" - 3G (model A1397)
     @"iPad2,4" - Wifi (model A1395)
     
     // iPad Mini
     @"iPad2,5" - Wifi (model A1432)
     @"iPad2,6" - Wifi + Cellular (model  A1454)
     @"iPad2,7" - Wifi + Cellular (model  A1455)
     
     //iPad 3
     @"iPad3,1" - Wifi (model A1416)
     @"iPad3,2" - Wifi + Cellular (model  A1403)
     @"iPad3,3" - Wifi + Cellular (model  A1430)
     
     //iPad 4
     @"iPad3,4" - Wifi (model A1458)
     @"iPad3,5" - Wifi + Cellular (model  A1459)
     @"iPad3,6" - Wifi + Cellular (model  A1460)
     
     //iPad AIR
     @"iPad4,1" - Wifi (model A1474)
     @"iPad4,2" - Wifi + Cellular (model A1475)
     @"iPad4,3" - Wifi + Cellular (model A1476)
     
     // iPad Mini 2
     @"iPad4,4" - Wifi (model A1489)
     @"iPad4,5" - Wifi + Cellular (model A1490)
     @"iPad4,6" - Wifi + Cellular (model A1491)
     
     // iPad Mini 3
     @"iPad4,7" - Wifi (model A1599)
     @"iPad4,8" - Wifi + Cellular (model A1600)
     @"iPad4,9" - Wifi + Cellular (model A1601)
     
     // iPad Mini 4
     @"iPad5,1" - Wifi (model A1538)
     @"iPad5,2" - Wifi + Cellular (model A1550)
     
     //iPad AIR 2
     @"iPad5,3" - Wifi (model A1566)
     @"iPad5,4" - Wifi + Cellular (model A1567)
     
     // iPad PRO 12.9"
     @"iPad6,3" - Wifi (model A1673)
     @"iPad6,4" - Wifi + Cellular (model A1674)
     @"iPad6,4" - Wifi + Cellular (model A1675)
     
     //iPad PRO 9.7"
     @"iPad6,7" - Wifi (model A1584)
     @"iPad6,8" - Wifi + Cellular (model A1652)
     
     //iPod Touch
     @"iPod1,1"   on iPod Touch
     @"iPod2,1"   on iPod Touch Second Generation
     @"iPod3,1"   on iPod Touch Third Generation
     @"iPod4,1"   on iPod Touch Fourth Generation
     @"iPod7,1"   on iPod Touch 6th Generation
     */
    
    struct utsname systemInfo;
    uname(&systemInfo);
    char *p = systemInfo.machine;
    
    //NSString *nsDeviceModel = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    std::string ans(p);
    
    return ans;
}

//#define nullptr NULL

#endif /* Common_h */
