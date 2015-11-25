//
//  IDCallManager.h
//  ringID
//
//  Created by Partho Biswas on 1/12/15.
//
//



#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#include <sys/types.h>   // for type
#include <sys/socket.h>  // for socket API
#include <netinet/in.h>  // for address
#include <arpa/inet.h>   // for sockaddr_in
#include <stdio.h>       // for printf()
#include <stdlib.h>      // for atoi()
#include <string.h>      // for strlen()
#include <unistd.h>      // for close()

#import "CallCommonDefs.h"
#import "RCCurrentCallInfoModel.h"
#import "RCAuthResponseInfoModel.h"
#import "IDCallMakePacket.h"

#import "RingCallDelegate.h"
#import "RingCallAudioDelegate.h"




@interface IDCallManager : NSObject <UIActionSheetDelegate, UIAlertViewDelegate, AVAudioPlayerDelegate>

@property (nonatomic, assign)  id <RingCallDelegate> callManagerDelegate;
@property (nonatomic, assign)  id <RingCallAudioDelegate> callManagerAudioDelegate;

@property (nonatomic, strong, readwrite) RCCurrentCallInfoModel *currentCallInfoModel;

@property (nonatomic, assign, readonly) BOOL isValidSignal;
@property (nonatomic, assign, readonly) BOOL isCallInProgress;
@property (nonatomic, assign) BOOL isGsmInterruption;

+ (IDCallManager *) sharedInstance;
+ (void) destroyIDCallManager;
- (void) releaseConnectivityLibraryAferSessionCreation;
- (void) initialiseConnectivityFrameworkWith:(NSString *)userID sessionID:(NSString *)sessionID authServerIP:(NSString *)authServerIP authServerPort:(int)authServerPort;



- (BOOL) prepareRingCallModuleForNewCallWithFriendId:(NSString *)friendID callID:(NSString *)callID userID:(NSString *)userID ;

- (void) initialiseRingCallModuleForNewCallWithAuthInfo:(RCAuthResponseInfoModel *)authResponseInfo callType:(IDCallType)callType callFrom:(IDCallFrom)callFrom userID:(NSString *)userID callOperationType:(Call_Operation_Type) callOperationType;


- (NSString *) generateNewCallID;

- (void) processCallSignal:(NSData *) data;

- (void) checkGSMorCDMAcallAndTakeProperAction;
- (void) volumeChanged:(NSNotification *)notification;
- (void) sendVoiceRegisterPushNotificationMessageWithUserFullName:(NSString *)userFullName callingFrnDeviceToken:(NSString *)deviceToken;

- (void) setIncomoingInfoFrom374:(RCAuthResponseInfoModel *)tempDict withCallFrom:(IDCallFrom)callFrom userID:(NSString *)userID freiendID:(NSString *)fndID;

- (void) receivedErrorCodeFromAuth;
- (void) receivedErrorCodeForUnresponsiveAuth;
- (void) receivedErrorCodeForCallState:(CallResponseType)callState withCallID:(NSString *)callID;

- (void) performCallHold;
- (void) performCallUnhold;

- (void) performCallAnswerForCallType:(IDCallType) callType;
- (void) performCallEnd;
- (void) performCallEndWithBusyMessage:(NSString *)msg;

- (void) performCallRedialingToNumber:(NSString *)phoneNumber userID:(NSString *)userID;
- (BOOL) prepareRingCallModuleForRedialCall;

- (void) performCallCancelAutomatically;

- (void) performCallDropOnApplicationTermination;

//- (void) unregisterMessageSend;
- (void) updateNetworkType:(NSDictionary *) networkDict;

- (void) initialiseCallStateForNewCall;
- (void) notifyRingCallAudioEndedDelegate;
- (void) notifyRingToneStartedDelegate;
- (void) notifyRingToneEndedDelegate;

- (void) setSpeakerEnable:(BOOL)enable;
- (void) setMuteEnable:(BOOL)enable;

- (void) callDelegateToStartBackgroundKeepAlive;
- (void) p2pStatusChanged:(int)status forMediaType:(int)mediaType;
- (void) startKeepAliveWithVoiceServer;
- (void) stopKeepAliveWithVoiceServerForCallID:(NSString *)callID;
- (long long) getLong64AtOffset:(NSInteger)offset fromData:(NSData *)processedData;

// For Video call
+(BOOL) isInterruptedEndSignal:(NSData*)data;
-(void) sendVideoCallInterruptedEndSignal;
-(void) sendVideoCallStartRequestAtVoiceBindPort;
-(void) sendVideoBindPortRequestAtRegisterPort;
-(void) sendVideoCallEndRequestAtVideoBindPort;
-(void) sendVideoKeepAliveRequestAtVideoBindPortEnableInfiniteRepeat:(BOOL)shouldRepeat;
-(void) stopSendVideoKeepAlive;

-(void) processVideoSignalData:(NSData *) data;
//-(void) receivedVideoSignal:(CallResponseType) responseType;
//-(void) receivedVideoData:(NSData *) videoFrameData;
-(void) stopVideoCallProcess;

@end
