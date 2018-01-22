//
//  Constants.h
//  MediaConnectivity
//
//  Created by Rajib Chandra Das on 5/31/17.
//  Copyright © 2017 Rajib Chandra Das. All rights reserved.
//

#ifndef Constants_h
#define Constants_h

class Constants
{
public:
    const static int REGISTER_MESSAGE = 101;
    const static int UNREGISTER_MESSAGE = 102;
    const static int INVITE_MESSAGE = 103;
    const static int END_CALL_MESSAGE = 104;
    const static int CANCEL_MESSAGE = 105;
    const static int GET_ONLINE_USER_MESSAGE  = 106;
    const static int PRESENCE_MESSAGE = 107;
    const static int PUBLISH_MESSAGE = 108;
    const static int VIEW_MESSAGE = 109;
    const static int PUBLISHER_INVITE_MESSAGE = 110;
    const static int VIEWER_INVITE_MESSAGE = 111;
    const static int ONLINE_PUBLISHER_MESSAGE = 112;
    const static int TERMINATE_ALL_MESSAGE = 199; // BE careful about this.
    const static int STOP_LIVE_CALL_MESSAGE = 113;
    
    
    const static int REPLY_REGISTER_MESSAGE = 121;
    const static int REPLY_UNREGISTER_MESSAGE = 122;
    const static int REPLY_INVITE_MESSAGE = 123;
    const static int REPLY_END_CALL_MESSAGE = 124;
    const static int REPLY_CANCEL_MESSAGE = 125;
    const static int REPLY_GET_ONLINE_USER_MESSAGE  = 126;
    const static int REPLY_PRESENCE_MESSAGE = 127;
    const static int REPLY_PUBLISH_MESSAGE = 128;
    const static int REPLY_VIEW_MESSAGE = 129;
    const static int REPLY_PUBLISHER_INVITE_MESSAGE = 130;
    const static int REPLY_VIEWER_INVITE_MESSAGE = 131;
    const static int REPLY_ONLINE_PUBLISHER_MESSAGE = 132;
    const static int REPLY_STOP_LIVE_CALL_MESSAGE = 133;
    
    const static int USER_TYPE_IDLE = 0;
    const static int USER_TYPE_CALLER = 1;
    const static int USER_TYPE_CALLEE = 2;
    const static int USER_TYPE_PUBLISHER = 3;
    const static int USER_TYPE_VIEWER = 4;
    const static int USER_TYPE_PUBLISHER_CALLER = 5;
    const static int USER_TYPE_PUBLISHER_CALLEE = 6;
    const static int USER_TYPE_VIEWER_CALLER = 7;
    const static int USER_TYPE_VIEWER_CALLEE = 8;
    
    
    const static int ERRORR_MESSAGE = 12;
    
    const static int MAX_SERVER_PORT_NUMBER = 40000;
    const static int MIN_SERVER_PORT_NUMBER = 30001;
    
    const static int MAX_CLIENT_PORT_NUMBER = 30000;
    const static int MIN_CLIENT_PORT_NUMBER = 20001;
    
    const static int SIGNALING_SOCKET_TYPE = 1;
    const static int MEDIA_SOCKET_TYPE = 2;
    
};

#endif /* Constants_h */
