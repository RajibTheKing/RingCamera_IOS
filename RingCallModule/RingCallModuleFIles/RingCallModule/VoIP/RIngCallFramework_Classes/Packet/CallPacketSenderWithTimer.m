//
//  CallPacketSenderWithTimer.m
//  CallFrameworkApp
//
//  Created by Nagib Bin Azad on 3/1/15.
//  Copyright (c) 2015 Ring Inc. All rights reserved.
//

#import "CallPacketSenderWithTimer.h"
#import "RIConnectivityManager.h"

@implementation CallPacketSenderWithTimer

@synthesize delegate,signalPacket;

- (instancetype) initWithPacket:(SignalPacket *)packet
{
    self = [super init];
    
    if(self) {
        self.signalPacket = packet;
    }
    
    return self;
}


+ (instancetype) initWithPacket:(SignalPacket *)packet
{
    return [[[CallPacketSenderWithTimer alloc] initWithPacket:packet] autorelease];
}

- (void)startSending
{
    
    if (self.signalPacket.isInfiniteTimerEnabled) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.sendingTimer = [NSTimer scheduledTimerWithTimeInterval:self.signalPacket.timeInterval target:self selector:@selector(repeatServerCall:) userInfo:nil repeats:YES];

        });
    } else if (self.signalPacket.repeatCount > 0) {
        self.sendingTimer = [NSTimer scheduledTimerWithTimeInterval:self.signalPacket.timeInterval target:self selector:@selector(repeatServerCall:) userInfo:nil repeats:YES];
    }
    //Send a packet immediatly
    [self sendPacket];
}


-(void)repeatServerCall:(NSTimer *)repeatTimer
{
    if (!self.signalPacket.isInfiniteTimerEnabled) {
        
        self.signalPacket.repeatCount--;
        
        if(self.signalPacket.repeatCount == 0) {
            if([self.sendingTimer isValid]) {
                [self.sendingTimer invalidate];
                self.sendingTimer = nil;
                if ([self.delegate respondsToSelector:@selector(didFinishSendingPacketWithKey:)]) {
                    [self.delegate didFinishSendingPacketWithKey:self.signalPacket.timerIdentifier];
                }
                
                 NSDictionary* userInfo = [NSDictionary dictionaryWithObjects:@[[NSNumber numberWithInt:self.signalPacket.packetType],[NSString stringWithString:self.signalPacket.callID]] forKeys:@[@"callState",@"callID"]];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"CALL_STATE_ERROR" object:self userInfo:userInfo];
                
            }
            return;
        }
    }
   
    [self sendPacket];
}

-(void)sendPacket
{
    if (self.packetType == RingCallPacketTypeAudio) {
        
        if (isConnectivityModuleEnabled == 1) {
            [[RIConnectivityManager sharedInstance] sendTo:self.signalPacket.dataToSent friendID:self.signalPacket.friendID destinationIPaddress:self.signalPacket.ipAddress destinationPort:(int)self.signalPacket.port mediaType:MEDIA_TYPE_AUDIO];
        } else {
            [[CallSocketCommunication sharedInstance].udpSocket send:self.signalPacket.dataToSent toHost:self.signalPacket.ipAddress Port:(int)self.signalPacket.port];
        }
        
    } else if (self.packetType == RingCallPacketTypeVideo) {
        
        if (isConnectivityModuleEnabled == 1) {
            [[RIConnectivityManager sharedInstance] sendTo:self.signalPacket.dataToSent friendID:self.signalPacket.friendID destinationIPaddress:self.signalPacket.ipAddress destinationPort:(int)self.signalPacket.port mediaType:MEDIA_TYPE_VIDEO];
        } else {
            [[RIVideoMediaSocket sharedInstance] sendVideoDataWith:self.signalPacket.dataToSent toHost:self.signalPacket.ipAddress Port:(int)self.signalPacket.port];
        }
    } else {
        // Undefine Packet
    }
}

- (void)stopSending
{
    if([self.sendingTimer isValid])
    {
        [self.sendingTimer invalidate];
        self.sendingTimer = nil;
    }

}

- (void)stopSendingPacketForKey:(NSString*)timerIdentifier
{

}




@end
