//
//  IDVideoOperation.m
//  ThreadingTestApp
//
//  Created by Md Shahinur Rahman on 10/13/15.
//  Copyright © 2015 -. All rights reserved.
//

#import "IDVideoOperation.h"
#import "IDVideoFrameModel.h"
#import "RIVideoMediaSocket.h"
#import "IDCallManager.h"
#import "RIConnectivityManager.h"

static IDVideoOperation *sharedMyManager = nil;

@interface IDVideoOperation ()

@property (nonatomic,assign)    NSInteger currentFrmae;

@property (nonatomic, retain) NSOperationQueue *operationQueue;
@property (nonatomic, retain) NSInvocationOperation *sendOperation;
@property (nonatomic, retain) NSInvocationOperation *receiveOperation;
@property (nonatomic, retain) dispatch_queue_t dispatchQueue;
@property (atomic, retain) NSMutableArray *sendVideoframeQueue;
@property (nonatomic, retain) NSTimer *videoSendingTimer;

@end

@implementation IDVideoOperation


#pragma mark Singleton Methods
+ (IDVideoOperation *)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {
        self.operationQueue = [NSOperationQueue new];
        self.dispatchQueue = dispatch_queue_create("VideoReceiveQueue", NULL);
        self.sequenceLength = 500;
    }
    return self;
}

-(void) startVideoSendOpreration
{
    if (self.sendVideoDataQueue) {
        self.sendVideoDataQueue = nil;
        NSLog(@"Reset sendVideoDataQueue");
    }
    
    if (self.sendVideoframeQueue) {
        self.sendVideoframeQueue = nil;
        NSLog(@"Reset sendVideoframeQueue");
    }
    
    [self stopVideoProcess];
    
    
    self.sendVideoDataQueue = [[[NSMutableArray alloc] init] autorelease];
    self.sendVideoframeQueue = [[[NSMutableArray alloc] init] autorelease];
    
    self.sendOperation = [[[NSInvocationOperation alloc] initWithTarget:self
                                                               selector:@selector(videoSendProcess)
                                                                 object:nil] autorelease];
    // Add the operation to the queue and let it to be executed.
    [self.operationQueue addOperation:self.sendOperation];
    
    if (self.videoSendingTimer != nil) {
        if ([self.videoSendingTimer isValid]) {
            [self.videoSendingTimer invalidate];
            self.videoSendingTimer = nil;
        }
    }
    self.videoSendingTimer = [NSTimer
                              scheduledTimerWithTimeInterval:0.015f
                              target:self
                              selector:@selector(videoSendingMethod)
                              userInfo:nil
                              repeats:YES];
    
}

-(void) startVideoReceiveOpreration
{
    if (self.receiveVideoDataQueue) {
        self.receiveVideoDataQueue = nil;
    }
    [self stopVideoReceiveProcess];
    self.receiveVideoDataQueue = [[[NSMutableArray alloc] init] autorelease];
    
    self.receiveOperation = [[[NSInvocationOperation alloc] initWithTarget:self
                                                                  selector:@selector(videoReceiveProcess)
                                                                    object:nil] autorelease];
    // Add the operation to the queue and let it to be executed.
    [self.operationQueue addOperation:self.receiveOperation];
    
    NSLog(@"operation queue count: %lu",(unsigned long)[self.operationQueue operationCount]);
}


-(void) startVideoOpreration
{
    [self startVideoSendOpreration];
    [self startVideoReceiveOpreration];
}

-(void)videoSendProcess
{
    while (true) {
        if ([self.sendOperation isCancelled]) {
            break;
        }
        while (self.sendVideoDataQueue.count > 0)
        {
            NSData *videoData = [self.sendVideoDataQueue pull];
            if (videoData != nil) {
                [self processVideoframe:videoData];
            }
            //Work here
        }
        [NSThread sleepForTimeInterval:.01]; //sleep 10ms
    }
}

-(void)processVideoframe:(NSData *)sendVideoFrame
{
    NSInteger totalCurrentFrameSequence = 0;
    NSInteger seqLength = self.sequenceLength; // Wifi for 1000 and 3G for 500
    NSInteger tempTotal =  (sendVideoFrame.length %seqLength)?1:0;
    totalCurrentFrameSequence = (NSInteger) (sendVideoFrame.length/seqLength)+tempTotal;
    
    //NSLog(@"Send Frame number: %ld withLength: %lu",(long)self.currentFrmae,(unsigned long)sendVideoFrame.length);
    for (NSInteger i= 1; i <= totalCurrentFrameSequence; i++) {
        
        @autoreleasepool {
            
            NSData *frameData = nil;
            
            if (i == totalCurrentFrameSequence) {
                frameData = [sendVideoFrame subdataWithRange:NSMakeRange(seqLength*(i-1),(sendVideoFrame.length - seqLength*(i-1)))];
            } else {
                frameData = [sendVideoFrame subdataWithRange:NSMakeRange(seqLength*(i-1),seqLength)];
            }
            
            IDVideoFrameModel *frameModel = [[[IDVideoFrameModel alloc] init] autorelease];
            frameModel.videoFrameData = frameData;
            frameModel.totalSingleFrameSequence = totalCurrentFrameSequence;
            frameModel.currentFrameSeqence = i;
            frameModel.currentFrameNumber =  self.currentFrmae;
            
            [self makeVideoMediaPacket:frameModel];
            
        }
    }
    self.currentFrmae++;
}


- (void ) makeVideoMediaPacket:(IDVideoFrameModel *) frameModel
{
    if ([IDCallManager sharedInstance].currentCallInfoModel.callInfo.callServerInfo.videoBindingPort> 0) {
        NSMutableData * framePacket = [[NSMutableData alloc] init];
        
        Byte data[1];
        data[0] = CallResponseType_VideoMedia;
        [framePacket appendBytes:data length:1];
        
        
        NSData *currentFrame = [IDCallMakePacket getDataFromInteger:frameModel.currentFrameNumber];
        [framePacket appendData:currentFrame];
        
        Byte teamData[2];
        teamData[0] = frameModel.totalSingleFrameSequence;
        teamData[1] = frameModel.currentFrameSeqence;
        
        [framePacket appendBytes:teamData length:2];
        [framePacket  appendData:frameModel.videoFrameData];
        
        [self.sendVideoframeQueue push:(NSData *)framePacket];
        [framePacket release];
        
        //[[RIVideoMediaSocket sharedInstance] sendVideoDataWith:(NSData *)framePacket toHost:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.callServerInfo.videoBindingPort];
    } else {
        NSLog(@"Did Not get Bind Port YET!");
    }
    
}

-(void) videoSendingMethod
{
    @try {
        NSData * framePacket = [self.sendVideoframeQueue pull];
        if (framePacket != nil) {
            if (isConnectivityModuleEnabled) {
                
                [[RIConnectivityManager sharedInstance] sendTo:framePacket friendID:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.friendIdentity destinationIPaddress:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress destinationPort:(int)[IDCallManager sharedInstance].currentCallInfoModel.callInfo.callServerInfo.videoBindingPort mediaType:MEDIA_TYPE_VIDEO];
            } else {
                [[RIVideoMediaSocket sharedInstance] sendVideoDataWith:framePacket toHost:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.callServerInfo.videoBindingPort];
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Sending exception : %@",exception);
    }
    @finally {
        
    }
   
}


-(void)videoReceiveProcess
{
    while (true) {
        if ([self.receiveOperation isCancelled]) {
            break;
        }
        while (self.receiveVideoDataQueue.count > 0)
        {
            @autoreleasepool {
                
                @try {
                    NSData *receivedData = nil;
                    @synchronized(self) {
                        receivedData = [self.receiveVideoDataQueue pull];
                    }
                    
                    if (receivedData != nil) {
                        dispatch_sync(self.dispatchQueue, ^{
                            [self getVideoFrameFromVideoPacket:receivedData];
                        });
                    }
                }
                @catch (NSException *exception) {
                    NSLog(@"--------------- ERROR in enquqeing received video data. ---------------");
                }
                
            }
            
        }
        [NSThread sleepForTimeInterval:.010]; // sleep 10ms
    }
}

- (void) getVideoFrameFromVideoPacket: (NSData *) data
{
    //dispatch_async(dispatch_get_main_queue(), ^{
    [[IDCallManager sharedInstance] processVideoSignalData:data];
    //});
}

-(void) stopVideoProcess
{
    if (self.videoSendingTimer) {
        [self.videoSendingTimer invalidate];
        self.videoSendingTimer = nil;
    }
    [self stopVideoSendProcess];

    [self stopVideoReceiveProcess];
}

-(void) stopVideoSendProcess
{
    NSLog(@"stopVideoSendProcess");
    if (self.sendOperation != nil) {
        [self.sendOperation cancel];
        self.sendOperation = nil;
    }
    // [self.sendVideoData removeAllObjects];
}


-(void) stopVideoReceiveProcess
{
    NSLog(@"stopVideoReceiveProcess");
    if (self.receiveOperation) {
        [self.receiveOperation cancel];
        self.receiveOperation = nil;
    }
}

-(void)addReceiveVideoDataOnQueue:(NSData *)data
{
    @synchronized(self) {
        @try {
            [self.receiveVideoDataQueue push:data];
        }
        @catch (NSException *exception) {
            NSLog(@"addReceiveVideoDataOnQueue exception:%@",exception);
        }
        @finally {
            
        }
    }
}

-(void)addSendVideoDataOnQueue:(NSData *)data
{
    @try {
        [self.sendVideoDataQueue push:data];
    }
    @catch (NSException *exception) {
        self.sendVideoDataQueue = nil;
        NSLog(@"addSendVideoDataOnQueue exception:%@",exception);
    }
    @finally {
        
    }
}

- (void)dealloc
{
    // Should never be called, but just here for clarity really.
    self.sendVideoDataQueue = nil;
    self.receiveVideoDataQueue = nil;
    self.operationQueue = nil;
    [super dealloc];
}

@end
