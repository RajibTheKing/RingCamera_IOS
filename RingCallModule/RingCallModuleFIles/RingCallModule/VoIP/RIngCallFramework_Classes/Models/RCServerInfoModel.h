//
//  RCServerInfoModel.h
//  CallFrameworkApp
//
//  Created by Partho Biswas on 3/19/15.
//  Copyright (c) 2015 Ring Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCServerInfoModel : NSObject

@property(nonatomic,strong) NSString *voicehostIPAddress;
@property(nonatomic,assign) int voiceRegisterport;
@property(nonatomic,assign) int voiceBindingPort;
@property(nonatomic,assign) int videoBindingPort;

@property(nonatomic,assign) long long callInitiationTime;

@end
