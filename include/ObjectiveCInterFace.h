
#ifndef _IOS_EVENT_NOTIFIER_H_
#define _IOS_EVENT_NOTIFIER_H_
typedef long long IPVLongType;

void notifyClientMethodWithPacket(IPVLongType lFriendID, unsigned char data[], int dataLenth);
void notifyClientMethodWithFrame(IPVLongType lFriendID, unsigned char data[], int dataLenth, int iVideoHeight, int iVideoWidth);

#endif
