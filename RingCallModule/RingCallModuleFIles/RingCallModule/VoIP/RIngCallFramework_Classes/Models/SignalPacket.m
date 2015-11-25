//
//  SignalPacket.m
//  CallFrameworkApp
//
//  Created by Nagib Bin Azad on 2/26/15.
//  Copyright (c) 2015 Ring Inc. All rights reserved.
//

#import "SignalPacket.h"
#import "IDCallMakePacket.h"

@implementation SignalPacket

- (instancetype) initWithIpAddress:(NSString *)ipAddress Port:(NSInteger)port SendingPacket:(NSData*)data NumberOfRepeat:(NSInteger)noOfRepeat TimeInterval:(NSInteger)timeInterval InfiniteTimerEnabled:(BOOL)infiniteTimerEnable friendId:(NSString *)fId
{
    self = [super init];
    
    if(self)
    {
        
        int totalRead = 0;
        self.packetType = CFSwapInt32LittleToHost(*(int*)([[data subdataWithRange:NSMakeRange(totalRead, 1)] bytes]));
        totalRead ++;
        
        totalRead += 8;
        
        if (self.packetType != CallResponseType_VOICE_REGISTER_CONFIRMATION) {
            totalRead += 8;
        }
        
        int callIDLength = CFSwapInt32LittleToHost(*(int*)([[data subdataWithRange:NSMakeRange(totalRead, 1)] bytes]));
        totalRead++;
        self.callID = [[[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(totalRead,callIDLength)] encoding:NSUTF8StringEncoding] autorelease];
        self.ipAddress = ipAddress;
        self.port = port;
        self.dataToSent = data;
        self.repeatCount = noOfRepeat;
        self.timeInterval = timeInterval;
        self.timerIdentifier = [IDCallMakePacket makeKeyStringWithCallID:self.callID andSignalType:self.packetType];
        self.isInfiniteTimerEnabled = infiniteTimerEnable;
        self.friendID = fId;
        
    }
    
    return self;
}

-(void)dealloc
{
    self.callID = nil;
    self.ipAddress = nil;
    self.dataToSent = nil;
    self.timerIdentifier = nil;
    self.friendID = nil;
    [super dealloc];
}
@end
