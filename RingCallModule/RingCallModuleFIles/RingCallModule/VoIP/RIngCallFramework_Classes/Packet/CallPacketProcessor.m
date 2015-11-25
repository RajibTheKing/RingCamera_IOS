//
//  CallPacketProcessor.m
//  ringID
//
//  Created by Mac2 on 11/9/14.
//
//

#import "CallPacketProcessor.h"
#import "RIConnectivityManager.h"
#import "RingCallConstants.h"

static CallPacketProcessor *sharedInstance = nil;

@implementation CallPacketProcessor
@synthesize processThread;
@synthesize dispatchQueue;



+(CallPacketProcessor *)sharedInstance
{
    if (sharedInstance == nil)
    {
        sharedInstance = [[CallPacketProcessor alloc] init];
        sharedInstance.dispatchQueue = dispatch_queue_create("com.ringId.callProcessPacketQueue", NULL);
        sharedInstance.processThread = [[NSThread alloc] initWithTarget:sharedInstance selector:@selector(startPacketProcessing) object:nil];
        [sharedInstance.processThread start];
    }
    
    return sharedInstance;
}
-(void)startPacketProcessing
{
    while (TRUE)
    {
        @try {
            
            if (isConnectivityModuleEnabled == 1) {
                while ([RIConnectivityManager sharedInstance].queue_packet.count > 0)
                {
                    NSData *receivedData = [[RIConnectivityManager sharedInstance].queue_packet pull];
                    if (receivedData != nil)
                    {
                        dispatch_sync(self.dispatchQueue, ^{
                            [self processData:receivedData];
                        });
                    }
                }
            } else {
                while ([CallSocketCommunication sharedInstance].queue_packet.count > 0)
                {
                    NSData *receivedData = [[CallSocketCommunication sharedInstance].queue_packet pull];
                    if (receivedData != nil)
                    {
                        dispatch_sync(self.dispatchQueue, ^{
                            [self processData:receivedData];
                        });
                    }
                }
            }
            usleep(100000);
        }
        @catch (NSException *exception) {
            NSLog(@"%@",exception);
        }
        
    }
}
-(void)processData:(NSData *)data
{
    __block IDCallManager *manager = [[IDCallManager sharedInstance] retain];
    dispatch_async(dispatch_get_main_queue(), ^{
        [manager processCallSignal:data];
        [manager release];
    });
}

@end
