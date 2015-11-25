//
//  RCCallInfoModel.m
//  CallFrameworkApp
//
//  Created by Partho Biswas on 3/19/15.
//  Copyright (c) 2015 Ring Inc. All rights reserved.
//

#import "RCCallInfoModel.h"

@implementation RCCallInfoModel

- (id) init {
    self = [super init];
    
    if(self)
    {
        self.callingFrnDevicePlatformCode = 0;
        self.appTypeOfFriend = 0;
        self.friendsIDC = 0;
        self.friendsAppMode = 0;
        self.presence = 0;
        self.callID = @"";
        self.friendIdentity = @"";
        self.friendName = @"";
        self.userIdentity = @"";
        self.friendDeviceToken = @"";
        self.responseType = CallResponseType_Auth;
        self.currentCallType = IDCallTypeUndefine;
        self.currentCallFrom = IDCallFromGeneral;
        self.connectivityEventType = RIConnectivityEventType_None;
        self.callServerInfo = [[[RCServerInfoModel alloc] init] autorelease];
        self.currentCallMediaType = IDCallMediaType_Voice;
    }
    return self;
}


- (void)dealloc
{
    self.callID = nil;
    self.friendIdentity = nil;
    self.friendName = nil;
    self.userIdentity = nil;
    self.callServerInfo = nil;
    self.friendDeviceToken = nil;
    [super dealloc];
}
@end



