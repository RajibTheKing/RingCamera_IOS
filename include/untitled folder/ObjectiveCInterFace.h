
#ifndef ringID_ObjectiveCInterFace_h
#define ringID_ObjectiveCInterFace_h

#include "RingSDKDefinitions.h"

void notifyClientMethodWithPacketIos(IPVLongType lFriendID, unsigned char data[], int dataLenth);
void notifyClientMethodWithVideoDataIos(IPVLongType lFriendID, unsigned char data[], int dataLenth, int iVideoHeight, int iVideoWidth);
void notifyClientMethodWithAudioDataIos(IPVLongType lFriendID, short data[], int dataLenth);
void notifyClientMethodWithAudiPacketDataIos(IPVLongType lFriendID, unsigned char data[], int dataLenth);

void notifyClientMethodIos(int eventType);
void notifyClientMethodForFriendIos(int eventType, IPVLongType friendName, int mediaName);
void notifyClientMethodWithReceivedIos(int eventType, IPVLongType friendName, int mediaName, int dataLenth, unsigned char data[]);

#endif
