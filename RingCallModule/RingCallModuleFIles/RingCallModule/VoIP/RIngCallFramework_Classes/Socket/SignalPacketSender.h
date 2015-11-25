//
//  SignalPacketSender.h
//  CallFrameworkApp
//
//  Created by Nagib Bin Azad on 2/26/15.
//  Copyright (c) 2015 Ring Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CallPacketSenderWithTimer.h"
#import "SignalPacket.h"



@interface SignalPacketSender : NSObject


@property (nonatomic, retain) NSMutableDictionary *sentPacketMap;

+ (instancetype)sharedInstance;

- (BOOL)sendPacket:(SignalPacket *)packet packetType:(RingCallPacketType) packetType;
- (BOOL)stopSendingPacketForKey:(NSString *)key;


//Sending and stop sending method with feedback block
- (void)sendPacket:(SignalPacket *)packet forPacketType:(RingCallPacketType) packetType onSuccess:(void (^)(BOOL finished))success onFailure:(void (^)(NSError *error))failure;
- (void)stopSendingPacketForKey:(NSString *)key onSuccess:(void (^)(BOOL finished))success onFailure:(void (^)(NSError *error))failure;
- (void)stopSendingPacketForCallerID:(NSString *)callerID withSignalType:(CallResponseType)signalType onSuccess:(void (^)(BOOL finished))success onFailure:(void (^)(NSError *error))failure;


@end
