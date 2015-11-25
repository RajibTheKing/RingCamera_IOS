//
//  RCAuthResponseInfoModel.m
//  CallFrameworkApp
//
//  Created by Partho Biswas on 3/19/15.
//  Copyright (c) 2015 Ring Inc. All rights reserved.
//

#import "RCAuthResponseInfoModel.h"

#import "VoipUtils.h"



@implementation RCAuthResponseInfoModel

- (id) initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    
    if(self)
    {
        self.callID = [dictionary objectForKey:KEY_CALL_ID];
        self.callingFrnDevicePlatformCode = [[dictionary objectForKey:KEY_DEVICE_CALL] intValue];
        self.friendIdentity = [dictionary objectForKey:KEY_FRIEND_ID_CALL];
        self.packetID = [dictionary objectForKey:KEY_PACKET_ID_CALL];
        self.presence = [[dictionary objectForKey:KEY_PRESENCE_CALL] intValue];
        self.success = [[dictionary objectForKey:KEY_SUCCESS_CALL] intValue];
        self.voicehostIPAddress = [dictionary objectForKey:KEY_SWITCH_IP_CALL];
        self.voiceRegisterport = [[dictionary objectForKey:KEY_SWITCH_PORT_CALL] intValue];
        self.callInitiationTime = [[dictionary objectForKey:KEY_CALL_INITIATION_TIME] longLongValue];
        self.appTypeOfFriend = [[dictionary objectForKey:KEY_APP_TYPE_CALL] intValue];
        self.friendName = [dictionary objectForKey:KEY_FRIEND_NAME];
        self.friendsIDC = [[dictionary objectForKey:KEY_FRIEND_IDC] intValue];
        self.connectWith = [dictionary objectForKey:KEY_FRIEND_CONNECT_WITH];
        self.friendsAppMode = [[dictionary objectForKey:KEY_FRIEND_MOOD] intValue];
        self.friendsRC = [[dictionary objectForKey:KEY_FRIEND_RC] intValue];
        self.message = [dictionary objectForKey:KEY_FRIEND_MESSAGE];
        self.currentCallMediaType = [[dictionary objectForKey:KEY_CALL_MEDIA_TYPE] intValue];
        self.deviceToken = [dictionary objectForKey:KEY_RINGID_DEVICE_TOKEN];
        self.authServerIP = nil;
        self.authServerPort = 0;
        self.appSessionID = nil;
    }
    return self;
}

@end


