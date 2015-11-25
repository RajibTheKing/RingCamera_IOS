//
//  RingCallManager.h
//  CallFrameworkApp
//
//  Created by Partho Biswas on 3/18/15.
//  Copyright (c) 2015 Ring Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RCCurrentCallInfoModel.h"
#import "RCAuthResponseInfoModel.h"
#import "RingCallDelegate.h"
#import "RingCallAudioDelegate.h"
#import "VoipUtils.h"

@interface RingCallManager : NSObject


@property (nonatomic, assign)  id <RingCallDelegate> callManagerDelegate;
@property (nonatomic, assign)  id <RingCallAudioDelegate> callManagerAudioDelegate;
@property (nonatomic, strong, readonly) RCCurrentCallInfoModel *currentCallInfoModel;



+ (RingCallManager *) sharedInstance;
+ (void) destroyRingCallManager;
- (void) initialiseConnectivityFrameworkWith:(NSString *)userID sessionID:(NSString *)sessionID authServerIP:(NSString *)authServerIP authServerPort:(int)authServerPort;


- (void) initialiseRingCallModuleForNewCallWithAuthInfo:(RCAuthResponseInfoModel *)authResponseInfo callType:(IDCallType)callType callFrom:(IDCallFrom)callFrom userID:(NSString *)userID withCallDelegate:(id <RingCallDelegate>)callDelegate andAudioDelegate:(id <RingCallAudioDelegate>)audioDelegate callOperationType:(Call_Operation_Type) callOperationType;

- (void) setIncomoingInfoFrom374:(RCAuthResponseInfoModel *)tempDict withCallFrom:(IDCallFrom)callFrom userID:(NSString *)userID freiendID:(NSString *)fndID;

- (void) checkGSMorCDMAcallAndTakeProperAction;
- (NSString *) generateNewCallID;
- (BOOL) prepareRingCallModuleForNewCallWithFriendId:(NSString *)friendID callID:(NSString *)callID userID:(NSString *)userID;
- (BOOL) prepareRingCallModuleForRedialCall;

- (void) sendVoiceRegisterPushNotificationMessageWithUserFullName:(NSString *)userFullName callingFrnDeviceToken:(NSString *)deviceToken;

- (void) performCallHold;
- (void) performCallUnhold;

- (void) performCallAnswerForCallType:(IDCallType) callType;
- (void) performCallEnd;
- (void) performCallEndWithBusyMessage:(NSString *)msg;

- (void) performCallRedialingToNumber:(NSString *)phoneNumber userID:(NSString *)userID;

- (void) performCallCancelAutomatically;

- (void) performCallDropOnApplicationTermination;

- (void) initialiseCallStateForNewCall;

- (void) setSpeakerEnable:(BOOL)enable;
- (void) setMuteEnable:(BOOL)enable;

// for Video

-(void) performVideoCallStart;
-(void) performVideoCallEnd;
-(void) performVideoCallInterruptedEnd;
-(void) stopAllVideoProcess;
-(void) sendVideoKeepAliveWithRepeated:(BOOL) isRepeated;
-(void) stopSendVideoKeepAlive;

- (void)interfaceChanged;
- (void)reinitializeSocket;

//- (NSAttributedString *) getNetworkStatus;

/*
// For endoding, decoding, playing and recording audio for IM
- (void) startAudioRecordingForIM;
- (NSURL *) stopAudioRecordingForIMandReturnRecordedFilePathWithFileName:(NSString *)fileNameWithOutExt;

- (NSURL *) getG729EncodedDataFileFromPCMdataFileWithPath:(NSURL *)filePath;
- (NSString *) getPCMdataPathFromG729EncodedDataFileWithPath:(NSURL *)filePath;
- (NSURL *) getAndCreatePlayableFileFromPcmData:(NSString *)filePath;
- (void) playAudioFromIMwithFilePath:(NSURL *)pathUrl;

//  Methodes for audio routing
- (void) AudioInitAudioSessionRouting;
- (void) AudioSwitchToDefaultHardware;
- (void) AudioForceOutputToBuiltInSpeakers;

// For silence tone
- (void) PlaySilenceTone;
- (void) StopSilenceTone;
*/



@end
