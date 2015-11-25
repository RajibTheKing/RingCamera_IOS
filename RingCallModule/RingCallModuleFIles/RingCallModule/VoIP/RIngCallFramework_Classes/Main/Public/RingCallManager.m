//
//  RingCallManager.m
//  CallFrameworkApp
//
//  Created by Partho Biswas on 3/18/15.
//  Copyright (c) 2015 Ring Inc. All rights reserved.
//

#import "RingCallManager.h"
#import "IDCallManager.h"
#import "RingCallAudioManager.h"
#import "CallSocketCommunication.h"
#import <SystemConfiguration/CaptiveNetwork.h>



static RingCallManager *sharedInstance = nil;



@interface RingCallManager ()

@property (nonatomic, strong) IDCallManager *callManager;
@property (nonatomic, strong) RingCallAudioManager *audioManager;

@end




@implementation RingCallManager

@synthesize callManager, currentCallInfoModel, callManagerDelegate, audioManager, callManagerAudioDelegate;

+(RingCallManager *)sharedInstance
{
    if (sharedInstance == nil)
    {
        sharedInstance = [[RingCallManager alloc] init];
    }
    return sharedInstance;
}

- (id) init {
    self = [super init];
    
    callManager = [IDCallManager sharedInstance];
    audioManager = [RingCallAudioManager sharedInstance];
    currentCallInfoModel = callManager.currentCallInfoModel;
    callManagerDelegate = callManager.callManagerDelegate;
    callManagerAudioDelegate = callManager.callManagerAudioDelegate;
    
    return self;
}

- (void) initialiseConnectivityFrameworkWith:(NSString *)userID sessionID:(NSString *)sessionID authServerIP:(NSString *)authServerIP authServerPort:(int)authServerPort {
    [callManager initialiseConnectivityFrameworkWith:userID sessionID:sessionID authServerIP:authServerIP authServerPort:authServerPort];
}

+ (void) destroyRingCallManager
{
    if (sharedInstance) {
        
        [[CallSocketCommunication sharedInstance] closeSocket];
        [IDCallManager destroyIDCallManager];
        [sharedInstance release];
        sharedInstance = nil;
    }
}
- (void)interfaceChanged
{
    [[RIConnectivityManager sharedInstance] InterfaceChanged];
    
//    NSString *currentBSSID = @"";
//    if (self.currentCallInfoModel.networkType == IDCallMediaType_WiFi) {
//        CFArrayRef myArray = CNCopySupportedInterfaces();
//        if (myArray != nil){
//            NSDictionary* myDict = (NSDictionary *) CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(myArray, 0));
//            if (myDict!=nil){
//                currentBSSID=[myDict valueForKey:@"SSID"];
//            }
//        }
//    }
//    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
//    [dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss.SSS"];
//    NSString *currentTime = [dateFormatter stringFromDate:[NSDate date]];
//    NSString *toWrite = [NSString stringWithFormat:@"InterfaceChanged API got fired for callID: %@ current network type: %lu  and time: %@ and SSID: %@", self.currentCallInfoModel.callInfo.callID, (unsigned long)self.currentCallInfoModel.networkType, currentTime, currentBSSID];
//    [VoipUtils writeToTextFile:toWrite];
//    NSLog(@"%@",toWrite);
}
- (void)reinitializeSocket
{
    [[CallSocketCommunication sharedInstance] reinitializeSocket];
}

- (void) initialiseRingCallModuleForNewCallWithAuthInfo:(RCAuthResponseInfoModel *)authResponseInfo callType:(IDCallType)callType callFrom:(IDCallFrom)callFrom userID:(NSString *)userID withCallDelegate:(id <RingCallDelegate>)callDelegate andAudioDelegate:(id <RingCallAudioDelegate>)audioDelegate callOperationType:(Call_Operation_Type) callOperationType {
    
    [callManager setCallManagerDelegate:callDelegate];
    [callManager setCallManagerAudioDelegate:audioDelegate];
    [callManager initialiseRingCallModuleForNewCallWithAuthInfo:authResponseInfo callType:callType callFrom:callFrom userID:userID callOperationType:callOperationType];
    

}

- (void) setIncomoingInfoFrom374:(RCAuthResponseInfoModel *)tempDict withCallFrom:(IDCallFrom)callFrom userID:(NSString *)userID freiendID:(NSString *)fndID {
    [callManager setIncomoingInfoFrom374:tempDict withCallFrom:callFrom userID:userID freiendID:fndID];
}


- (void) checkGSMorCDMAcallAndTakeProperAction {
    [callManager checkGSMorCDMAcallAndTakeProperAction];
}

- (NSString *) generateNewCallID {
    return [callManager generateNewCallID];
}

- (BOOL) prepareRingCallModuleForNewCallWithFriendId:(NSString *)friendID callID:(NSString *)callID userID:(NSString *)userID {
    return [callManager prepareRingCallModuleForNewCallWithFriendId:friendID callID:callID userID:userID ];
}

- (BOOL) prepareRingCallModuleForRedialCall {
    return [callManager prepareRingCallModuleForRedialCall];
}


- (void) sendVoiceRegisterPushNotificationMessageWithUserFullName:(NSString *)userFullName callingFrnDeviceToken:(NSString *)deviceToken {
    [callManager sendVoiceRegisterPushNotificationMessageWithUserFullName:userFullName callingFrnDeviceToken:deviceToken];
}


- (void) performCallHold {
    [callManager performCallHold];
}

- (void) performCallUnhold {
    [callManager performCallUnhold];
}


- (void) performCallAnswerForCallType:(IDCallType) callType {
    [callManager performCallAnswerForCallType:callType];
}

- (void) performCallEnd {
    [callManager performCallEnd];
}

- (void) performCallEndWithBusyMessage:(NSString *)msg {
    [callManager performCallEndWithBusyMessage:msg];
}


- (void) performCallRedialingToNumber:(NSString *)phoneNumber userID:(NSString *)userID {
    [callManager performCallRedialingToNumber:phoneNumber userID:userID];
}


- (void) performCallCancelAutomatically {
    [callManager performCallCancelAutomatically];
}


- (void) performCallDropOnApplicationTermination {
    [callManager performCallDropOnApplicationTermination];
}


- (void) initialiseCallStateForNewCall {
    [callManager initialiseCallStateForNewCall];
}


- (void) setSpeakerEnable:(BOOL)enable {
    [callManager setSpeakerEnable:enable];
}

- (void) setMuteEnable:(BOOL)enable {
    [callManager setMuteEnable:enable];
}

#pragma mark - Video Call

-(void) performVideoCallStart
{
    [callManager sendVideoCallStartRequestAtVoiceBindPort];
}

-(void) performVideoCallEnd
{
    [callManager sendVideoCallEndRequestAtVideoBindPort];
}

-(void) performVideoCallInterruptedEnd
{
    [callManager sendVideoCallInterruptedEndSignal];
}

-(void) stopAllVideoProcess
{
    [callManager stopVideoCallProcess];
}

-(void) sendVideoKeepAliveWithRepeated:(BOOL) isRepeated
{
    [callManager sendVideoKeepAliveRequestAtVideoBindPortEnableInfiniteRepeat:isRepeated];
}

-(void) stopSendVideoKeepAlive
{
    [callManager stopSendVideoKeepAlive];
}

//- (NSAttributedString *) getNetworkStatus {
//    return [callManager getNetworkStatus];
//}


/*
- (void) startAudioRecordingForIM {
    [audioManager startAudioRecordingForIM];
}

- (NSURL *) stopAudioRecordingForIMandReturnRecordedFilePathWithFileName:(NSString *)fileNameWithOutExt {
    return [audioManager stopAudioRecordingForIMandReturnRecordedFilePathWithFileName:fileNameWithOutExt];
}

- (NSURL *) getG729EncodedDataFileFromPCMdataFileWithPath:(NSURL *)filePath {
    return [audioManager getG729EncodedDataFileFromPCMdataFileWithPath:filePath];
}

- (NSString *) getPCMdataPathFromG729EncodedDataFileWithPath:(NSURL *)filePath {
    return [audioManager getPCMdataPathFromG729EncodedDataFileWithPath:filePath];
}

- (NSURL *) getAndCreatePlayableFileFromPcmData:(NSString *)filePath {
    return [audioManager getAndCreatePlayableFileFromPcmData:filePath];
}

- (void) playAudioFromIMwithFilePath:(NSURL *)pathUrl {
    [audioManager playAudioFromIMwithFilePath:pathUrl];
}


//  Methodes for audio routing
- (void) AudioInitAudioSessionRouting{
    [audioManager AudioInitAudioSessionRouting];
}


- (void) AudioSwitchToDefaultHardware {
    [audioManager AudioSwitchToDefaultHardware];
}


- (void) AudioForceOutputToBuiltInSpeakers{
    [audioManager AudioForceOutputToBuiltInSpeakers];
}

// For silence tone
- (void) PlaySilenceTone {
    [audioManager PlaySilenceTone];
}

- (void) StopSilenceTone {
    [audioManager StopSilenceTone];
}
*/




@end
