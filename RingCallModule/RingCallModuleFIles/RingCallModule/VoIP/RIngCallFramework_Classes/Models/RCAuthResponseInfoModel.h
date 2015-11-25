//
//  RCAuthResponseInfoModel.h
//  CallFrameworkApp
//
//  Created by Partho Biswas on 3/19/15.
//  Copyright (c) 2015 Ring Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CallCommonDefs.h"

@interface RCAuthResponseInfoModel : NSObject

- (id) initWithDictionary:(NSDictionary *)dictionary;

@property(nonatomic,strong) NSString *callID;
@property(nonatomic,assign) int callingFrnDevicePlatformCode;
@property(nonatomic,strong) NSString *friendIdentity;
@property(nonatomic,strong) NSString *friendName; //
@property(nonatomic,strong) NSString *packetID;
@property(nonatomic,strong) NSString *deviceToken;
@property(nonatomic,assign) int presence;
@property(nonatomic,assign) int success;
@property(nonatomic,strong) NSString *voicehostIPAddress;
@property(nonatomic,assign) int voiceRegisterport;
@property(nonatomic,assign) long long callInitiationTime;
@property(nonatomic,assign) int appTypeOfFriend;
@property(nonatomic,assign) int friendsIDC; //
@property(nonatomic, retain) NSString *connectWith;//cw
@property(nonatomic,assign) int friendsAppMode; //
@property(nonatomic,assign) int friendsRC; // ReasonCode
@property(nonatomic,strong) NSString *message; //
@property(nonatomic,assign) IDCallMediaType currentCallMediaType;

@property(nonatomic,strong) NSString *authServerIP; //
@property(nonatomic,strong) NSString *appSessionID;
@property(nonatomic,assign) int authServerPort;


@end
