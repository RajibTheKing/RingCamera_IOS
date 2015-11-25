//
//  CallPacketSenderWithTimer.h
//  CallFrameworkApp
//
//  Created by Nagib Bin Azad on 3/1/15.
//  Copyright (c) 2015 Ring Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "SignalPacket.h"
#import "CallSocketCommunication.h"
#import "RIVideoMediaSocket.h"

typedef NS_ENUM(NSUInteger, RingCallPacketType) {
    RingCallPacketTypeUndefine = 0,
    RingCallPacketTypeAudio,
    RingCallPacketTypeVideo
};

@protocol CallPacketSenderDelegate <NSObject>

- (void)didFinishSendingPacketWithKey:(NSString *)key;

@end

@interface CallPacketSenderWithTimer : NSObject

@property (nonatomic ,retain) NSTimer *sendingTimer;
@property (nonatomic, retain) SignalPacket *signalPacket;
@property (nonatomic, retain) id<CallPacketSenderDelegate> delegate;
@property (nonatomic, assign) RingCallPacketType packetType;

+ (instancetype) initWithPacket:(SignalPacket *)packet;

- (void)startSending;
- (void)stopSending;



@end
