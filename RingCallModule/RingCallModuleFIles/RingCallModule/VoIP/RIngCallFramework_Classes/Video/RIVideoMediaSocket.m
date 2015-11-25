//
//  RIVideoMediaSocket.m
//  ringID
//
//  Created by Md Shahinur Rahman on 10/4/15.
//  Copyright © 2015 IPVision Canada Inc. All rights reserved.
//

#import "RIVideoMediaSocket.h"
#import "IDVideoOperation.h"

static RIVideoMediaSocket *sharedInstance = nil;


@interface RIVideoMediaSocket ()

@end

@implementation RIVideoMediaSocket


+ (RIVideoMediaSocket *)sharedInstance {
    if (sharedInstance == nil) {
        sharedInstance = [[RIVideoMediaSocket alloc] init];
        
        if(!isConnectivityModuleEnabled) {
            sharedInstance.receivingThread = [[[NSThread alloc] initWithTarget:sharedInstance selector:@selector(startRevceiving) object:nil] autorelease];
            int bindPort = 0;
            sharedInstance.vcUdpSocket = [UDPSocket newWithPort:bindPort];
            
            [sharedInstance.vcUdpSocket setTimeout:10];
            [sharedInstance.receivingThread start];
        }
    } else {
        if(!isConnectivityModuleEnabled) {
            [sharedInstance.vcUdpSocket bindPortIfNeeded];
        }
    }
    
    return sharedInstance;
}

- (void)startRevceiving
{
    while (TRUE)
    {
        //NSLog(@"Call Socket Running!");
        NSString *host = nil;
        int port_ = 0;
        
        NSData *receivedData = [[RIVideoMediaSocket sharedInstance].vcUdpSocket receiveFrom:&host Port:&port_ Size:CALL_MAX_PACKET_SIZE];
        if (receivedData)
        {
            [[IDVideoOperation sharedManager] addReceiveVideoDataOnQueue:receivedData];
        }
        [host release];
    }
}

-(void) startVideoSocketOpreration
{
    if (!isConnectivityModuleEnabled) {
        
        if ([RIVideoMediaSocket sharedInstance].vcUdpSocket == nil) {
            [RIVideoMediaSocket sharedInstance].vcUdpSocket = [UDPSocket newWithPort:0];
            [sharedInstance.vcUdpSocket setTimeout:10.0];
            [[RIVideoMediaSocket sharedInstance].vcUdpSocket bindPortIfNeeded];
            
        } else {
            [[RIVideoMediaSocket sharedInstance].vcUdpSocket bindPortIfNeeded];
        }
    } // When isConnectivityModuleEnabled enable no need to ceare this socket
    
    [[IDVideoOperation sharedManager] startVideoOpreration] ;
}



- (void) sendVideoDataWith: (NSData *)data toHost: (NSString *)host Port: (int)port
{
    [[RIVideoMediaSocket sharedInstance].vcUdpSocket send:data toHost:host Port:port];
}

- (void)dealloc
{
    self.vcUdpSocket = nil;
    [super dealloc];
}

- (void)closeVideoSocket
{
    [[IDVideoOperation sharedManager] stopVideoProcess] ;
    
    //    if (self.vcUdpSocket) {
    //        [self.vcUdpSocket close];
    //        self.vcUdpSocket= nil;
    //    }
    //[self.videoSocketOperation cancel];
    //self.isRunning = NO;
    //[self performSelectorOnMainThread:@selector(videoSocketOperationStop) withObject:nil waitUntilDone:YES];
    NSLog(@"closeVideoSocket");
}


@end
