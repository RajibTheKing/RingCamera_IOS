//
//  CallSocketCommunication.h
//  ringID
//
//  Created by Nagib Bin Azad on 11/9/14.
//
//

#import <Foundation/Foundation.h>
#import <RingCommon/NSMutableArray+QueueAdditions.h>
#import <RingSocket/UDPSocket.h>
#import "RingCallConstants.h"

@interface CallSocketCommunication : NSObject

@property (nonatomic, retain) UDPSocket *udpSocket;
@property (nonatomic, retain) NSThread *receivingThread;
@property (nonatomic, retain) NSMutableArray *queue_packet;

+(CallSocketCommunication *)sharedInstance;
-(void)closeSocket;
-(void)reinitializeSocket;
@end
