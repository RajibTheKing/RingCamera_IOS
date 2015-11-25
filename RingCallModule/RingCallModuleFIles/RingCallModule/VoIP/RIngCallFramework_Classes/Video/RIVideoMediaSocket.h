//
//  RIVideoMediaSocket.h
//  ringID
//
//  Created by Md Shahinur Rahman on 10/4/15.
//  Copyright © 2015 IPVision Canada Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RingSocket/UDPSocket.h>
#import "RingCallConstants.h"


@interface RIVideoMediaSocket : NSObject

@property (nonatomic, retain) UDPSocket *vcUdpSocket;
@property (nonatomic, retain) NSThread *receivingThread;

+(RIVideoMediaSocket *)sharedInstance;


-(void) startVideoSocketOpreration;
-(void)closeVideoSocket;
- (void) sendVideoDataWith: (NSData *)data toHost: (NSString *)host Port: (int)port;

@end
