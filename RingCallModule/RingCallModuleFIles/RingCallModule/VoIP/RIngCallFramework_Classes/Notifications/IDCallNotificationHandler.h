//
//  IDCallNotificationHandler.h
//  ringID
//
//  Created by Partho Biswas on 2/25/15.
//  Copyright (c) 2015 IPVision Canada Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RingCallDelegate.h"
#import "IDCallMakePacket.h"
#import "IDCallManager.h"

#import "CallSocketCommunication.h"
#import "RingCallAudioManager.h"


@interface IDCallNotificationHandler : NSObject

@property (nonatomic, assign) BOOL isNotificationHandlerListening;

+ (IDCallNotificationHandler *) sharedInstance;
+ (void) destroyIDCallNotificationHandler;

- (void) startNotificationHandler;
- (void) stopNotificationHandler;

@end
