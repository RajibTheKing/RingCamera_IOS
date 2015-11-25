//
//  RISession.h
//  RingCallModule
//
//  Created by Nagib Bin Azad on 10/14/15.
//  Copyright © 2015 Sumon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CallCommonDefs.h"

extern NSString const *kSessionFriendID;
extern NSString const *kSessionMediaType;

@interface RISession : NSObject

@property (nonatomic, retain) NSString *friendID;
@property (nonatomic, assign) IDCallMediaType mediaType;
@property (nonatomic, retain) NSString *relayServerIP;
@property (nonatomic, assign) int relayServerPort;
@property (nonatomic, retain) NSTimer *closeSessionTimer;
@property (nonatomic, assign) NSInteger sessionTimeout;
@property (nonatomic, assign) BOOL isVerified;
@property (nonatomic, assign) BOOL isStartP2PCalled;

+(instancetype)initWithFriendID:(NSString *)friendID
                      mediaType:(IDCallMediaType)mediaType
                 sessionTimeout:(NSInteger)timeout
                  relayServerIP:(NSString *)serverIPAddr
                relayServerPort:(int)serverPort;

-(BOOL)createSession;
-(void)closeSession;
-(void)reset;
@end
