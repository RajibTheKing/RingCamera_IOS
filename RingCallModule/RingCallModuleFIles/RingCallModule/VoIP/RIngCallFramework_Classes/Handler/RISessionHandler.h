//
//  RISessionHandler.h
//  RingCallModule
//
//  Created by Nagib Bin Azad on 10/14/15.
//  Copyright © 2015 Sumon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RISession.h"

@interface RISessionHandler : NSObject

+(instancetype)sharedInstance;
-(BOOL)addSessionForFriendID:(NSString *)friendID withMediaType:(IDCallMediaType)mediaType relayServerIP:(NSString *)relayServerIP relayServerPort:(int)relayServerPort sessionTimeout:(NSInteger)sessionTimeout;
-(RISession *)getSessionForFriendID:(NSString *)friendID withMediaType:(IDCallMediaType)mediaType;
-(void)verifySessionForFriendID:(NSString *)friendID withMediaType:(IDCallMediaType)mediaType;
-(void)removeSessionForFriendID:(NSString *)friendID withMediaType:(IDCallMediaType)mediaType;
-(void)removeAllSession;
-(void)removeAllSessionExceptFriendID:(NSString *)friendID withMediaType:(IDCallMediaType)mediaType;

-(void)sessionTimeoutWithInfo:(NSDictionary *)sessionInfo;
@end
