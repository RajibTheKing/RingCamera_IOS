//
//  RCCurrentCallInfoModel.m
//  CallFrameworkApp
//
//  Created by Partho Biswas on 3/19/15.
//  Copyright (c) 2015 Ring Inc. All rights reserved.
//

#import "RCCurrentCallInfoModel.h"

@implementation RCCurrentCallInfoModel

- (id) init {
    self = [super init];
    
    if(self)
    {
        self.packetID = @"";
        self.packetType = CallResponseType_Auth;
        self.callOperationType = Call_Operation_Type__General;
        self.networkStrength = NetworkStrength_Average;
        self.callingFrnId = @"";
        self.callingFriendName = @"";
        self.currentCallState = CallResponseType_Auth;
        self.isValidCall = NO;
        self.isSimultaneousCall = NO;
        self.isCallHoldSignalSent = NO;
        self.networkType = IDCallMediaType_None;
        self.callInfo = [[[RCCallInfoModel alloc] init] autorelease];
    }
    return self;
}

- (void)dealloc
{
    self.callInfo = nil;
    self.packetID = nil;
    self.callingFriendName = nil;
    [super dealloc];
}

@end

