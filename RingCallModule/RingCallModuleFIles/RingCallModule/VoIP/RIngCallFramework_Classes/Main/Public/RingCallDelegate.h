//
//  RingCallDelegate.h
//  CallFrameworkApp
//
//  Created by Partho Biswas on 3/10/15.
//  Copyright (c) 2015 Ring Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CallCommonDefs.h"
#import "RCCurrentCallInfoModel.h"
#import "RCAuthResponseInfoModel.h"

@protocol RingCallDelegate <NSObject>


@required

- (void) didReceiveBusyMessageForOutgoingCallwithCallInfo:(RCCurrentCallInfoModel *)callInfo busyMessage:(NSString *)busyMessage; //

- (void) didReceiveResponseWithCallInfo:(RCCurrentCallInfoModel *)callInfo; //

- (void) didReceiveRemotePushForIncomingCallWithCallInfo:(RCCurrentCallInfoModel *)callInfo;  //
- (void) didReceiveLocalPushForIncomingCallWithCallInfo:(RCCurrentCallInfoModel *)callInfo;  //

- (void) didReceiveErrorCodeFromAuth;  //
- (void) didReceiveErrorCodeForUnresponsiveAuth;  //
- (void) didReceiveErrorCodeForCallState:(CallResponseType)callState withCallID:(NSString *)callID; //

- (void) didSendCallHoldWithInfo:(RCCurrentCallInfoModel *)callInfo sendingTime:(NSDate *)sendingTime;
- (void) didSendCallUnholdWithInfo:(RCCurrentCallInfoModel *)callInfo sendingTime:(NSDate *)sendingTime;

- (void) ringCallShouldEndWithBusyMessage;  //

- (void) ringCallDidEndWithCallInfo:(RCCurrentCallInfoModel *)callInfo;  //
- (void) ringCallDidEndWithAuthInfo:(RCAuthResponseInfoModel *)authInfo;  //

- (void) showCallViewControllerWithCallInfo:(RCCurrentCallInfoModel *)callInfo completion:(void (^)(BOOL success))completionBlock; //

- (void) startBackgroundKeepAlive; //

- (void)p2pStatusChanged:(int)status forMediaType:(int)mediaType;

#pragma mark - Video call delegate

-(void) didReceiveVideoSignalWithtype:(CallResponseType) responseType;
-(void) didReceiveVideoFrame:(NSData *)videoFrame;

@end