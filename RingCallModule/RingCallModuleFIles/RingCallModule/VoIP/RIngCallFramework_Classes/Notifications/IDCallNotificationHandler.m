//
//  IDCallNotificationHandler.m
//  ringID
//
//  Created by Partho Biswas on 2/25/15.
//  Copyright (c) 2015 IPVision Canada Inc. All rights reserved.
//

#import "IDCallNotificationHandler.h"
#import "RIConnectivityManager.h"
#import <RingCommon/Reachability.h>
#import "RingCallConstants.h"


static IDCallNotificationHandler *sharedInstance = nil;


@interface IDCallNotificationHandler ()

//@property (nonatomic,assign)  id <RingCallDelegate> callManagerDelegate;
//@property (nonatomic, strong) CallScreenViewController  *callScreenView;
@property (nonatomic, strong) NSString *callStatusString;
@property (nonatomic, retain) Reachability * reach;

@end


@implementation IDCallNotificationHandler

#pragma mark- Singleton related Methodes

+(IDCallNotificationHandler *)sharedInstance
{
    if (sharedInstance == nil) {
        sharedInstance = [[IDCallNotificationHandler alloc] init];
    }
    return sharedInstance;
}

- (id) init {
    self = [super init];
    
    // Initialise default valuse.
    //    self.callScreenView = [[IDCallManager sharedInstance] callViewController];
    self.callStatusString = nil;
    self.isNotificationHandlerListening = false;
    
    return self;
}

+ (void) destroyIDCallNotificationHandler
{
    if (sharedInstance) {
        
        // Release member variables
        
        [sharedInstance release];
        sharedInstance = nil;
    }
}

- (void) startNotificationHandler {
    [[IDCallNotificationHandler sharedInstance] stopNotificationHandler];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getErrorReceiveForCallState:) name:@"CALL_STATE_ERROR" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getErrorCodeFromAuth) name:@"CALL_ERROR_FROM_AUTH" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getErroAuthDidnotResponse) name:@"AUTH_NOT_RESPONSE_FOR_CALL" object:nil];
}

- (void) stopNotificationHandler {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CALL_STATE_ERROR" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CALL_ERROR_FROM_AUTH" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AUTH_NOT_RESPONSE_FOR_CALL" object:nil];
}


#pragma mark- Notification Observer related Methodes

-(void) getErrorCodeFromAuth
{
    //    self.callScreenView.callModel.callType = RICallTypeDialled;
    //    self.callStatusString = @"User might be offline!";
    //    [self updateCallScreenUI];
    //
    //    [self.callScreenView performSelector:@selector(callViewDismiss) withObject:nil afterDelay:1];
    
    
    
    //    [self.callManagerDelegate didReceiveErrorCodeFromAuth];
    [[IDCallManager sharedInstance] receivedErrorCodeFromAuth];
}

-(void) getErroAuthDidnotResponse
{
    //    self.callScreenView.callModel.callType = RICallTypeDialled;
    //    self.callStatusString = @"Please try later!";
    //    [self updateCallScreenUI];
    //
    //    [self.callScreenView performSelector:@selector(callViewDismiss) withObject:nil afterDelay:1];
    
    //    [self.callManagerDelegate didReceiveErrorCodeForUnresponsiveAuth];
    [[IDCallManager sharedInstance] receivedErrorCodeForUnresponsiveAuth];
    
}

-(void)getErrorReceiveForCallState : (NSNotification *) notification  //TODO:  Replace this methode from this class
{
    NSDictionary* userInfo = notification.userInfo;
    int callState = ((NSNumber*)userInfo[@"callState"]).intValue;
    NSString *callID = [NSString stringWithString:[userInfo objectForKey:@"callID"]];
    switch (callState) {
        case CallResponseType_CALLING:
        {
            NSData *packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_CANCELED packetID:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.callID userIdentity:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.userIdentity friendIdentity:[IDCallManager sharedInstance].currentCallInfoModel.callingFrnId];
            
            //            CallSocketCommunication *callSendReceiveTimer = [CallSocketCommunication sharedInstance];
            //            [callSendReceiveTimer sendPacket:packet withHostAddress:[IDCurrentCallServerDTO sharedInstance].voicehostIPAddress withPort:[IDCurrentCallServerDTO sharedInstance].voiceBindingPort];
            
            
            
            if (isConnectivityModuleEnabled == 1) {
                [[RIConnectivityManager sharedInstance] sendTo:packet friendID:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.friendIdentity destinationIPaddress:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress destinationPort:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort mediaType:MEDIA_TYPE_AUDIO];
            } else {
                [[CallSocketCommunication sharedInstance].udpSocket send:packet toHost:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort];
            }
            
            [IDCallManager sharedInstance].currentCallInfoModel.currentCallState = CallResponseType_CANCELED;
            [[RingCallAudioManager sharedInstance] stopRingBackTone];
            
            
            //            [self performSelector:@selector(showRedialScreen) withObject:nil afterDelay:1.0f];
        }
            break;
        case CallResponseType_ANSWER:
        {
            NSData *packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_DISCONNECTED packetID:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.callID userIdentity:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.userIdentity friendIdentity:[IDCallManager sharedInstance].currentCallInfoModel.callingFrnId];
            
            //            CallSocketCommunication *callSendReceiveTimer = [CallSocketCommunication sharedInstance];
            //            [callSendReceiveTimer sendPacket:packet withHostAddress:[IDCurrentCallServerDTO sharedInstance].voicehostIPAddress withPort:[IDCurrentCallServerDTO sharedInstance].voiceBindingPort];
            
            
            if (isConnectivityModuleEnabled == 1) {
                [[RIConnectivityManager sharedInstance] sendTo:packet friendID:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.friendIdentity destinationIPaddress:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress destinationPort:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort mediaType:MEDIA_TYPE_AUDIO];
            } else {
                [[CallSocketCommunication sharedInstance].udpSocket send:packet toHost:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort];
            }
            
            
            [IDCallManager sharedInstance].currentCallInfoModel.currentCallState = CallResponseType_DISCONNECTED;
            
            //            self.callScreenView.callModel.callType = RICallTypeMissed;
            
            if ([IDCallManager sharedInstance].currentCallInfoModel.callInfo.currentCallType == IDCallTypeIncomming) {
                [[RingCallAudioManager sharedInstance] StopRingTone];
            }
            //            self.callStatusString = @"Call Canceled!";
            //            [self.callScreenView performSelector:@selector(callViewDismiss) withObject:nil afterDelay:1];
        }
            break;
        case CallResponseType_CANCELED:
            //[self callViewDismiss];
            break;
        case CallResponseType_BUSY:
            // [self callViewDismiss];
            break;
        case CallResponseType_BYE:
            //[self callViewDismiss];
            
            break;
        case CallResponseType_VOICE_REGISTER:
        {
            //            self.callStatusLabel.text = @"Please try again later!";
            //            [self performSelector:@selector(callViewDismiss) withObject:nil afterDelay:1];
        }
            break;
        case CallResponseType_Auth:
            //            self.callStatusString = @"Contact might be offline, Please try again later!";
            //            [self.callScreenView performSelector:@selector(callViewDismiss) withObject:nil afterDelay:2];
            break;
        default:
            break;
    }
    
    
    CallResponseType receivedCallState = (CallResponseType) callState;
    
    //    [self.callManagerDelegate didReceiveErrorCodeForCallState:receivedCallState];
    [[IDCallManager sharedInstance] receivedErrorCodeForCallState:receivedCallState withCallID:callID];
}

#pragma mark- Class Member Methodes
//
//- (void) updateCallScreenUI {
//    RUN_ON_UI_THREAD(^{
//        
//        self.callScreenView.callStatusLabel.text = self.callStatusString;
//        
//    });
//}


@end
