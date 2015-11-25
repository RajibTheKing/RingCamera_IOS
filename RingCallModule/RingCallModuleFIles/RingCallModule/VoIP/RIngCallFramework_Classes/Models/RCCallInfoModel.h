//
//  RCCallInfoModel.h
//  CallFrameworkApp
//
//  Created by Partho Biswas on 3/19/15.
//  Copyright (c) 2015 Ring Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CallCommonDefs.h"
#import "RCServerInfoModel.h"
#import "RIConnectivityManager.h"

@interface RCCallInfoModel : NSObject

- (id) init;

@property(nonatomic,assign) int callingFrnDevicePlatformCode;
@property(nonatomic, retain) NSString *friendDeviceToken;
@property(nonatomic,assign) int appTypeOfFriend;
@property(nonatomic,assign) int friendsIDC; //
@property(nonatomic,assign) int friendsAppMode; //
@property(nonatomic,assign) int presence;
@property(nonatomic,strong) NSString *callID;
@property(nonatomic,strong) NSString *friendIdentity;
@property(nonatomic,strong) NSString *friendName; //
@property(nonatomic,strong) NSString *userIdentity;
@property(nonatomic,assign) CallResponseType responseType;
@property(nonatomic,assign) IDCallType currentCallType;
@property(nonatomic,assign) IDCallFrom currentCallFrom;
@property(nonatomic,assign) RIConnectivityEventType connectivityEventType;
@property(nonatomic,strong) RCServerInfoModel *callServerInfo;
@property(nonatomic,assign) IDCallMediaType currentCallMediaType;

@end
