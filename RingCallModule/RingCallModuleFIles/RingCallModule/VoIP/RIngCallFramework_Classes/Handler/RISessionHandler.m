//
//  RISessionHandler.m
//  RingCallModule
//
//  Created by Nagib Bin Azad on 10/14/15.
//  Copyright © 2015 Sumon. All rights reserved.
//

#import "RISessionHandler.h"

@interface RISessionHandler ()

@property (nonatomic, retain) NSMutableDictionary *sessionMap;

@end

@implementation RISessionHandler

+(instancetype)sharedInstance
{
    
    static dispatch_once_t once;
    static id sharedInstance = nil;
    dispatch_once(&once, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    
    
    return sharedInstance;
}
-(id)init
{
    self = [super init];
    if (self) {
        self.sessionMap = [[[NSMutableDictionary alloc] init] autorelease];
    }
    return self;
}
-(void)dealloc
{
    self.sessionMap = nil;
    [super dealloc];
}


-(BOOL)addSessionForFriendID:(NSString *)friendID withMediaType:(IDCallMediaType)mediaType relayServerIP:(NSString *)relayServerIP relayServerPort:(int)relayServerPort sessionTimeout:(NSInteger)sessionTimeout
{
    NSString *session_key = [NSString stringWithFormat:@"%@_%lu",friendID,(unsigned long)mediaType];
    RISession *oldSession = [[RISessionHandler sharedInstance].sessionMap objectForKey:session_key];
    BOOL success = NO;
    if (oldSession != nil) {
        if (oldSession.isVerified == YES) {
            if (oldSession.closeSessionTimer != nil && [oldSession.closeSessionTimer isValid]) {
                [oldSession.closeSessionTimer invalidate];
            }
        }
        else
        {
           [oldSession reset];
        }
    }
    else
    {
        RISession *newSession = [RISession initWithFriendID:friendID mediaType:mediaType sessionTimeout:sessionTimeout relayServerIP:relayServerIP relayServerPort:relayServerPort];
        success = [newSession createSession];
        [[RISessionHandler sharedInstance].sessionMap setObject:newSession forKey:session_key];

    }

//    if (success == YES) {
//        RISession *oldSession = [[RISessionHandler sharedInstance].sessionMap objectForKey:session_key];
//        if (oldSession != nil) {
//            if (oldSession.closeSessionTimer != nil && [oldSession.closeSessionTimer isValid]) {
//                [oldSession.closeSessionTimer invalidate];
//            }
//            if (oldSession.isVerified) {
//                if (newSession.closeSessionTimer != nil && [newSession.closeSessionTimer isValid]) {
//                    [newSession.closeSessionTimer invalidate];
//                    newSession.isVerified = YES;
//                }
//            }
//        }
//        [[RISessionHandler sharedInstance].sessionMap removeObjectForKey:session_key];
//        
//        [[RISessionHandler sharedInstance].sessionMap setObject:newSession forKey:session_key];
//    }
    return success;
    
}
-(RISession *)getSessionForFriendID:(NSString *)friendID withMediaType:(IDCallMediaType)mediaType
{
    NSString *session_key = [NSString stringWithFormat:@"%@_%lu",friendID,(unsigned long)mediaType];
    return [[RISessionHandler sharedInstance].sessionMap objectForKey:session_key];
}
-(void)verifySessionForFriendID:(NSString *)friendID withMediaType:(IDCallMediaType)mediaType
{
    NSString *session_key = [NSString stringWithFormat:@"%@_%lu",friendID,(unsigned long)mediaType];
    RISession *session = [[RISessionHandler sharedInstance].sessionMap objectForKey:session_key];
    if (session != nil) {
        if (session.closeSessionTimer != nil && [session.closeSessionTimer isValid]) {
            [session.closeSessionTimer invalidate];
            session.isVerified = YES;
            session.isStartP2PCalled = YES;
            NSLog(@"Session Verified");
        }
    }
}
-(void)removeSessionForFriendID:(NSString *)friendID withMediaType:(IDCallMediaType)mediaType
{
    NSString *session_key = [NSString stringWithFormat:@"%@_%lu",friendID,(unsigned long)mediaType];
    [[RISessionHandler sharedInstance] removeSessionForKey:session_key];
}
-(void)removeAllSession
{
    for (NSString *session_key in [[RISessionHandler sharedInstance].sessionMap allKeys]) {
        [[RISessionHandler sharedInstance] removeSessionForKey:session_key];
    }
}
-(void)removeAllSessionExceptFriendID:(NSString *)friendID withMediaType:(IDCallMediaType)mediaType
{
    NSString *ignor_session_key = [NSString stringWithFormat:@"%@_%lu",friendID,(unsigned long)mediaType];

    for (NSString *session_key in [[RISessionHandler sharedInstance].sessionMap allKeys]) {
        if (![session_key isEqualToString:ignor_session_key]) {
            
            [[RISessionHandler sharedInstance] removeSessionForKey:session_key];

        }
    }
}
-(void)removeSessionForKey:(NSString *)session_key
{
    RISession *session = [[RISessionHandler sharedInstance].sessionMap objectForKey:session_key];
    if (session != nil) {
        if (session.closeSessionTimer != nil && [session.closeSessionTimer isValid]) {
            [session.closeSessionTimer invalidate];
        }
        [session closeSession];
        [[RISessionHandler sharedInstance].sessionMap removeObjectForKey:session_key];
    }
}
-(void)sessionTimeoutWithInfo:(NSDictionary *)sessionInfo
{
    NSString *friendID = [sessionInfo objectForKey:kSessionFriendID];
    IDCallMediaType mediaType = [[sessionInfo objectForKey:kSessionMediaType] intValue];
    
    NSLog(@"Session Timeout for friendID: %@ and mediaType: %lu",friendID,(unsigned long)mediaType);
    
    NSString *session_key = [NSString stringWithFormat:@"%@_%lu",friendID,(unsigned long)mediaType];
    [[RISessionHandler sharedInstance] removeSessionForKey:session_key];
    
}
@end
