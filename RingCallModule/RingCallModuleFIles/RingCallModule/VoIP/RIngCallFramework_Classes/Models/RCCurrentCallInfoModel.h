//
//  RCCurrentCallInfoModel.h
//  CallFrameworkApp
//
//  Created by Partho Biswas on 3/19/15.
//  Copyright (c) 2015 Ring Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "RCCallInfoModel.h"

@interface RCCurrentCallInfoModel : NSObject

- (id) init;

@property(nonatomic,strong) NSString *packetID;
@property(nonatomic,assign) CallResponseType packetType;
@property(nonatomic,assign) Call_Operation_Type callOperationType;
@property(nonatomic,assign) NetworkStrength networkStrength;
@property(nonatomic,strong) NSString *callingFrnId;
@property(nonatomic,strong) NSString *callingFriendName; //
@property(nonatomic,assign) CallResponseType currentCallState;
@property(nonatomic, assign) BOOL isValidCall;
@property(nonatomic, assign) BOOL isSimultaneousCall;
@property(nonatomic, assign) BOOL isCallHoldSignalSent;
@property(nonatomic,strong) RCCallInfoModel *callInfo;
@property(nonatomic,assign) IDNetworkType networkType;

@end
