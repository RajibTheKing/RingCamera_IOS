//
//  SignalPacket.h
//  CallFrameworkApp
//
//  Created by Nagib Bin Azad on 2/26/15.
//  Copyright (c) 2015 Ring Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CallCommonDefs.h"
//#import <CallCommonDefs.h>

@interface SignalPacket : NSObject

@property (nonatomic, retain) NSString *ipAddress;
@property (nonatomic, assign) NSInteger port;
@property (nonatomic, retain) NSData *dataToSent;
@property (nonatomic, assign) NSInteger repeatCount;
@property (nonatomic, assign) NSInteger timeInterval;
@property (nonatomic, retain) NSString *timerIdentifier;
@property (nonatomic, assign) BOOL isInfiniteTimerEnabled;
@property (nonatomic, retain) NSString *callID;
@property (nonatomic, assign) int packetType;
@property (nonatomic, retain) NSString *friendID;

- (instancetype) initWithIpAddress:(NSString *)ipAddress Port:(NSInteger)port SendingPacket:(NSData*)data NumberOfRepeat:(NSInteger)noOfRepeat TimeInterval:(NSInteger)timeInterval InfiniteTimerEnabled:(BOOL)infiniteTimerEnable friendId:(NSString *)friendId;

@end
