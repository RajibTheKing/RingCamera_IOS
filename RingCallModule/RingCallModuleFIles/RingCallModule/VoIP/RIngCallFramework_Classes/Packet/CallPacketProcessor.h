//
//  CallPacketProcessor.h
//  ringID
//
//  Created by Mac2 on 11/9/14.
//
//

#import <Foundation/Foundation.h>
#import "CallSocketCommunication.h"
#import <RingCommon/NSMutableArray+QueueAdditions.h>
#import "IDCallManager.h"

@interface CallPacketProcessor : NSObject

@property (nonatomic, retain) NSThread *processThread;
@property (nonatomic, retain) dispatch_queue_t dispatchQueue;

+(CallPacketProcessor *)sharedInstance;

@end
