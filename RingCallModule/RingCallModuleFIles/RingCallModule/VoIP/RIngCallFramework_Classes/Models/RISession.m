//
//  RISession.m
//  RingCallModule
//
//  Created by Nagib Bin Azad on 10/14/15.
//  Copyright © 2015 Sumon. All rights reserved.
//

#import "RISession.h"
#import "RIConnectivityManager.h"
#import "RISessionHandler.h"
#import "RingCallConstants.h"

NSString const *kSessionFriendID = @"friendID";
NSString const *kSessionMediaType = @"mediaType";

@implementation RISession

- (void)dealloc
{
    self.friendID = nil;
    self.closeSessionTimer = nil;
    self.relayServerIP = nil;
    [super dealloc];

}
-(instancetype)initWithFriendID:(NSString *)sessionFriendID
                      mediaType:(IDCallMediaType)sessionMediaType
                 sessionTimeout:(NSInteger)timeout
                  relayServerIP:(NSString *)serverIPAddr
                relayServerPort:(int)serverPort
{
    self = [super init];
    
    if(self)
    {
        self.friendID = sessionFriendID;
        self.mediaType = sessionMediaType;
        self.sessionTimeout = timeout;
        self.relayServerIP = serverIPAddr;
        self.relayServerPort = serverPort;
    }
    return self;
}
+(instancetype)initWithFriendID:(NSString *)friendID
                      mediaType:(IDCallMediaType)mediaType
                 sessionTimeout:(NSInteger)timeout
                  relayServerIP:(NSString *)serverIPAddr
                relayServerPort:(int)serverPort
{
    return [[[RISession alloc] initWithFriendID:friendID
                                      mediaType:mediaType
                                 sessionTimeout:timeout
                                  relayServerIP:serverIPAddr
                                relayServerPort:serverPort] autorelease];
}

-(BOOL)createSession
{
    int success = [[RIConnectivityManager sharedInstance] createSession:self.friendID
                                                              mediaType:self.mediaType
                                                         relayServerIP:self.relayServerIP
                                                       relayServerPort:self.relayServerPort];
    if (success <= 0) {
        NSLog(@"Faild to create session on RIConnectivityManager");
        return NO;
    } else {
        NSLog(@"Successfully created session on RIConnectivityManager");
        self.closeSessionTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkSessionTimeout) userInfo:nil repeats:YES];
        return YES;
    }
}
-(void)closeSession
{
    int success = [[RIConnectivityManager sharedInstance] closeSession:self.friendID mediaType:self.mediaType];
    if (success <= 0) {
        NSLog(@"Faild to close session on RIConnectivityManager");
    } else {
        NSLog(@"Successfully closed session on RIConnectivityManager");
    }
}
-(void)reset
{
    if (self.closeSessionTimer != nil) {
        if ([self.closeSessionTimer isValid]) {
            [self.closeSessionTimer invalidate];
            self.closeSessionTimer = nil;
        }
    }
    self.sessionTimeout = SESSION_TIMEOUT;
    self.closeSessionTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkSessionTimeout) userInfo:nil repeats:YES];
}
-(void)checkSessionTimeout
{
    self.sessionTimeout--;
    if (self.sessionTimeout <= 0)
    {
        [self closeSession];
        [[RISessionHandler sharedInstance] sessionTimeoutWithInfo:[NSDictionary dictionaryWithObjects:@[self.friendID,[NSNumber numberWithInt:self.mediaType]] forKeys:@[kSessionFriendID,kSessionMediaType]]];
    }
}
@end
