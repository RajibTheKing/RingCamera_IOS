//
//  CallSocketCommunication.m
//  ringID
//
//  Created by Mac2 on 11/9/14.
//
//


#import "CallSocketCommunication.h"

static CallSocketCommunication *sharedInstance = nil;

@interface CallSocketCommunication ()

@end

@implementation CallSocketCommunication


+ (CallSocketCommunication *)sharedInstance {
    if (sharedInstance == nil)
    {
        sharedInstance = [[CallSocketCommunication alloc] init];
        if (!isConnectivityModuleEnabled) {
            sharedInstance.receivingThread = [[[NSThread alloc] initWithTarget:sharedInstance selector:@selector(startRevceiving) object:nil] autorelease];
            int bindPort = 0;
            sharedInstance.udpSocket = [[UDPSocket newWithPort:bindPort] autorelease];
            sharedInstance.queue_packet = [[[NSMutableArray alloc] init] autorelease];
            [sharedInstance.receivingThread start];
        }
    }
    
    return sharedInstance;
}
-(void)reinitializeSocket
{
     if (!isConnectivityModuleEnabled) {
        [[CallSocketCommunication sharedInstance].udpSocket reinitializeSocket];
     }
}
- (void)startRevceiving
{
    while (TRUE)
    {
        //NSLog(@"Call Socket Running!");
        NSString *host = nil;
        int port_ = 0;
        
        NSData *receivedData = [sharedInstance.udpSocket receiveFrom:&host Port:&port_ Size:CALL_MAX_PACKET_SIZE];
        if (receivedData)
        {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isReachable"];
            [self.queue_packet push:receivedData];
        }
        [host release];
    }
}

- (void)dealloc {
    self.queue_packet = nil;
    self.udpSocket = nil;
    self.receivingThread = nil;
    [super dealloc];
}

- (void)closeSocket {
    if (!isConnectivityModuleEnabled) {
        if (self.udpSocket != nil) {
            [self.udpSocket close];
            self.udpSocket = nil;
        }
        [sharedInstance.receivingThread cancel];
        [sharedInstance.receivingThread release];
        sharedInstance.receivingThread = nil;
        sharedInstance = nil;
    }
}
@end