//
//  IDVideoOperation.h
//  ThreadingTestApp
//
//  Created by Md Shahinur Rahman on 10/13/15.
//  Copyright © 2015 -. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RingCommon/NSMutableArray+QueueAdditions.h>


@interface IDVideoOperation : NSObject

@property (atomic, retain) NSMutableArray *receiveVideoDataQueue;
@property (atomic, retain) NSMutableArray *sendVideoDataQueue;
@property (nonatomic, assign) int sequenceLength;


+ (IDVideoOperation *)sharedManager;

-(void) startVideoOpreration;
-(void) stopVideoProcess;

-(void)addReceiveVideoDataOnQueue:(NSData *)data;
-(void)addSendVideoDataOnQueue:(NSData *)data;

@end
