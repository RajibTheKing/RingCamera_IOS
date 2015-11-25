//
//  IDCallManager.m
//  ringID
//
//  Created by Partho Biswas on 1/12/15.
//
//

#import "IDCallManager.h"

#import "RingCallConstants.h"
#import "VoipConstants.h"
#import "CallPacketSenderWithTimer.h"
#import "IDCallSignalBuffer.h"
#import "SignalPacketSender.h"
#import "RingCallAudioManager.h"
#import "CallPacketProcessor.h"
#import "CallSocketCommunication.h"
#import "IDCallSignalBuffer.h"
#import "IDCallMakePacket.h"
#import "VoipUtils.h"
#import <RingCommon/Reachability.h>
#import <SystemConfiguration/CaptiveNetwork.h>

#import "IDCallNotificationHandler.h"
#import "RIConnectivityManager.h"
//#import "ReceiveVideoFrameProcessor.h"
//#import "SendVideoFrameProcessor.h"
#import "IDVideoOperation.h"
#import "RISessionHandler.h"

@interface IDCallManager ()

@property (nonatomic, assign, readwrite) BOOL isValidSignal;
@property (nonatomic, assign, readwrite) BOOL isCallInProgress;

@property (nonatomic,strong) NSDate *callHoldSendingTime;
@property (nonatomic,strong) NSDate *callUnholdSendingTime;
@property (nonatomic,strong) CTCallCenter *callCenter;
@property (nonatomic, assign) int voiceBindingPort;
@property (nonatomic, assign) int videoBindingPort;

@property (nonatomic,assign)    NSInteger currentReceiveFrame;
@property (nonatomic, retain)   NSMutableArray *currentVideoFrame;

@property (nonatomic,strong) NSString *currentBSSID;

@end

@implementation IDCallManager

static id sharedInstance = nil;

@synthesize currentCallInfoModel;

bool is174Received = false;
bool is374Received = false;

+(IDCallManager *)sharedInstance
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[IDCallManager alloc] init];
    });
    
    //[[IDCallManager sharedInstance] setSpeakerEnable:true];
    return sharedInstance;
}

- (id) init {
    self = [super init];
    
    [CallPacketProcessor sharedInstance] ;
    [RingCallAudioManager sharedInstance];
    [[CallSocketCommunication sharedInstance] reinitializeSocket];
    self.currentCallInfoModel = [[[RCCurrentCallInfoModel alloc] init] autorelease];
    [self checkGSMorCDMAcallAndTakeProperAction];
    
    self.isCallInProgress = NO;
    self.voiceBindingPort = 0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(volumeChanged:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    
    // These are system notofication
    //    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callReceived:) name:CTCallStateIncoming object:nil];
    //    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callConnected:) name:CTCallStateConnected object:nil];
    //    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gsmCallEnded) name:CTCallStateDisconnected object:nil];
    
    [self detectCellulerNetworkConnectionType];
    CFArrayRef myArray = CNCopySupportedInterfaces();
    if (myArray != nil){
        NSDictionary* myDict = (NSDictionary *) CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(myArray, 0));
        if (myDict!=nil){
            self.currentBSSID=[myDict valueForKey:@"BSSID"];
            
            self.currentCallInfoModel.networkType = IDCallMediaType_WiFi;
        } else {
            self.currentBSSID = nil;
        }
    } else {
        self.currentBSSID = nil;
    }
    NSLog(@"self.currentCallInfoModel.networkType: %lu", (unsigned long)self.currentCallInfoModel.networkType);
    
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), //center
                                    NULL, // observer
                                    onNotifyCallback, // callback
                                    CFSTR("com.apple.system.config.network_change"), // event name
                                    NULL, // object
                                    CFNotificationSuspensionBehaviorCoalesce);
    

    
    return self;
}

static void onNotifyCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    NSString* notifyName = (NSString*)name;
    
    // this check should really only be necessary if you reuse this one callback method
    //  for multiple Darwin notification events
    if ([notifyName isEqualToString:@"com.apple.system.config.network_change"]) {
        // use the Captive Network API to get more information at this point
        //  http://stackoverflow.com/a/4714842/119114
        
        CFArrayRef myArray = CNCopySupportedInterfaces();
        NSDictionary* networkDict = (NSDictionary *) CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(myArray, 0));
        [[IDCallManager sharedInstance] updateNetworkType:networkDict];
        
    } else {
        NSLog(@"intercepted %@", notifyName);
    }
}


- (void) initialiseConnectivityFrameworkWith:(NSString *)userID sessionID:(NSString *)sessionID authServerIP:(NSString *)authServerIP authServerPort:(int)authServerPort {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *logDirectory = [NSString stringWithFormat:@"%@/IPVengine.log",documentsDirectory];
    
    if ([[RIConnectivityManager sharedInstance] init:userID sourceLogFilePath:logDirectory logLevel:5]) {
        NSLog(@"Successfully initialised RIConnectivityManager...");
        
        if (authServerIP && sessionID) {
            [[RIConnectivityManager sharedInstance] setAuthenticationServerWith:authServerIP withPort:authServerPort withSessionId:sessionID];
        }
        
    } else {
        NSLog(@"Faild to initialise RIConnectivityManager...");
    }
}

+ (void) destroyIDCallManager
{
    if (sharedInstance) {
        
        if (isConnectivityModuleEnabled == 1) {
            [[IDCallManager sharedInstance] releaseConnectivityLibraryAferSessionCreation];
        }
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
        [sharedInstance release];
        sharedInstance = nil;
    }
}

- (void) releaseConnectivityLibraryAferSessionCreation {
    [[RISessionHandler sharedInstance] removeSessionForFriendID:self.currentCallInfoModel.callInfo.friendIdentity withMediaType:IDCallMediaType_Voice];
    //[[RIConnectivityManager sharedInstance] closeSession:self.currentCallInfoModel.callInfo.friendIdentity mediaType:MEDIA_NAME];
    [[RIConnectivityManager sharedInstance] releaseLib];
}






- (void) initialiseRingCallModuleForNewCallWithAuthInfo:(RCAuthResponseInfoModel *)authResponseInfo callType:(IDCallType)callType callFrom:(IDCallFrom)callFrom userID:(NSString *)userID  callOperationType:(Call_Operation_Type) callOperationType {
    
    if (callType == IDCallTypeOutGoing) {
        is174Received = true;
    } else {
        is374Received = true;
    }
    
//    NSLog(@"initialiseRingCallModuleForNewCallWithAuthInfo Voice Server IP: %@",self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress);
//    NSLog(@"isSImultaniousCall: %d", self.currentCallInfoModel.isSimultaneousCall);
    
    self.currentCallInfoModel.callOperationType = callOperationType;
    
//    NSLog(@"callOperationType = %lu", (unsigned long)callOperationType);
//    NSLog(@"self.currentCallInfoModel.callOperationType = %lu", (unsigned long)self.currentCallInfoModel.callOperationType);
    
    if([self.callManagerAudioDelegate respondsToSelector:@selector(ringCallAudioStarted)]) {
        [self.callManagerAudioDelegate ringCallAudioStarted];
    }
    
    switch (callType) {
        case IDCallTypeOutGoing:
        {
            [self userDidReceiveResponseForOutgoingCallWithInfo:authResponseInfo userID:userID];
        }
            break;
        case IDCallTypeIncomming:
        {
            [self userDidReceiveResponseForIncommingCallWithInfo:authResponseInfo userID:userID friendID:authResponseInfo.friendIdentity callFrom:callFrom];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark- Out going Call response get 174

-(void)userDidReceiveResponseForOutgoingCallWithInfo:(RCAuthResponseInfoModel *)callInfo userID:(NSString *)userID
{
    [[IDCallNotificationHandler sharedInstance] startNotificationHandler];
    
    if(callInfo.success  == 1) {
        
        NSString *switchIp = callInfo.voicehostIPAddress;
        int switchPort = callInfo.voiceRegisterport;
        int callingFrndDvcPlat = callInfo.callingFrnDevicePlatformCode;
        NSString *callID = callInfo.callID;
        long long callInitiationTime = callInfo.callInitiationTime;
        
        self.currentCallInfoModel.callInfo.callServerInfo.callInitiationTime = callInitiationTime;
        self.currentCallInfoModel.callingFriendName = callInfo.friendName;
        self.currentCallInfoModel.callInfo.currentCallType = IDCallTypeOutGoing;
        self.currentCallInfoModel.callInfo.currentCallMediaType = callInfo.currentCallMediaType;
       
        RCCallInfoModel *outgoingCallDTO = [[IDCallSignalBuffer sharedInstance].callList objectForKey:callID];
        
        if (outgoingCallDTO != nil)
        {
            outgoingCallDTO.callServerInfo.voicehostIPAddress = switchIp;
            outgoingCallDTO.callServerInfo.voiceRegisterport = switchPort;
            outgoingCallDTO.callingFrnDevicePlatformCode = callingFrndDvcPlat;
            outgoingCallDTO.friendDeviceToken = callInfo.deviceToken;
            outgoingCallDTO.responseType = CallResponseType_VOICE_REGISTER;
            outgoingCallDTO.callServerInfo.callInitiationTime = callInitiationTime;
            outgoingCallDTO.appTypeOfFriend = callInfo.appTypeOfFriend;
            outgoingCallDTO.presence = callInfo.presence;
            outgoingCallDTO.friendName = callInfo.friendName;
            outgoingCallDTO.friendsAppMode = callInfo.friendsAppMode;
            outgoingCallDTO.friendsIDC = callInfo.friendsIDC;
            
            self.currentCallInfoModel.callingFrnId = callInfo.friendIdentity;
            if (callInfo.friendsIDC && callInfo.connectWith) {
                self.currentCallInfoModel.callingFriendName = callInfo.connectWith;
                outgoingCallDTO.friendIdentity = callInfo.friendIdentity;
                outgoingCallDTO.friendName = callInfo.connectWith;
            }
            
            if (isConnectivityModuleEnabled == 1) {
                BOOL result = [[RISessionHandler sharedInstance] addSessionForFriendID:outgoingCallDTO.friendIdentity withMediaType:IDCallMediaType_Voice relayServerIP:outgoingCallDTO.callServerInfo.voicehostIPAddress relayServerPort:outgoingCallDTO.callServerInfo.voiceRegisterport sessionTimeout:SESSION_TIMEOUT];//createSession:outgoingCallDTO.friendIdentity mediaType:MEDIA_NAME relayServerIP:outgoingCallDTO.callServerInfo.voicehostIPAddress relayServerPort:outgoingCallDTO.callServerInfo.voiceRegisterport];
                if (result == NO) {
                    NSLog(@"Faild to create session on IDCallManager");
                } else {
                    NSLog(@"Successfully created session on IDCallManager");
                }
            }
            
            NSData *packet = [IDCallMakePacket makeRegisterPacketForFreeCall:CallResponseType_VOICE_REGISTER userIdentity:userID friendIdentity:outgoingCallDTO.friendIdentity withCallID:outgoingCallDTO.callID];
            
            
            SignalPacket *packetToSent = [[[SignalPacket alloc] initWithIpAddress:outgoingCallDTO.callServerInfo.voicehostIPAddress Port:outgoingCallDTO.callServerInfo.voiceRegisterport SendingPacket:packet NumberOfRepeat:4 TimeInterval:3 InfiniteTimerEnabled:NO friendId:outgoingCallDTO.friendIdentity] autorelease];
            
            [[SignalPacketSender sharedInstance] sendPacket:packetToSent forPacketType:RingCallPacketTypeAudio onSuccess:^(BOOL finished) {
                //                NSLog(@"********** CallResponseType_VOICE_REGISTER sent successfully **********");
            } onFailure:^(NSError *error) {
                //                NSLog(@"********** CallResponseType_VOICE_REGISTER sending failed **********");
            }];
            
        }
        
    } else {
        if (callInfo.friendsRC == 1) {
            
//            if (![callInfo.friendIdentity isEqualToString:self.currentCallInfoModel.callInfo.friendIdentity]) {
//            if ((![callInfo.friendIdentity isEqualToString:self.currentCallInfoModel.callInfo.friendIdentity]) || (self.currentCallInfoModel.currentCallState != CallResponseType_CONNECTED || self.currentCallInfoModel.currentCallState != CallResponseType_ANSWER) || (self.currentCallInfoModel.packetType != CallResponseType_CONNECTED || self.currentCallInfoModel.packetType != CallResponseType_ANSWER)) {
            
//            NSLog(@"Voice Server IP: %@",self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress);
//            NSLog(@"isSImultaniousCall: %d", self.currentCallInfoModel.isSimultaneousCall);
            
            if (is374Received) {
                NSLog(@"Already 374 received. so will return from here");
                return;
            }
            
            if ((![callInfo.friendIdentity isEqualToString:self.currentCallInfoModel.callInfo.friendIdentity]) && (self.currentCallInfoModel.currentCallState != CallResponseType_CONNECTED || self.currentCallInfoModel.currentCallState != CallResponseType_ANSWER) && (self.currentCallInfoModel.packetType != CallResponseType_CONNECTED || self.currentCallInfoModel.packetType != CallResponseType_ANSWER)) {
                [self performCallEnd];
                if([self.callManagerDelegate respondsToSelector:@selector(ringCallDidEndWithAuthInfo:)]) {
                    [self.callManagerDelegate ringCallDidEndWithAuthInfo:callInfo];
                }
            } else {
                
            }
            
        } else if (callInfo.friendsAppMode == 2) {
            
            if (self.currentCallInfoModel.currentCallState == CallResponseType_Auth) {
                if([self.callManagerDelegate respondsToSelector:@selector(ringCallDidEndWithAuthInfo:)]) {
                    callInfo.message = @"Do not disturb!";
                    [self.callManagerDelegate ringCallDidEndWithAuthInfo:callInfo];
                }
            }
            
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"CALL_ERROR_FROM_AUTH" object:callInfo];
        }
    }
    
}

#pragma mark- Incomming Call response get 374

- (void) userDidReceiveResponseForIncommingCallWithInfo:(RCAuthResponseInfoModel *)callInfo userID:(NSString *)userID friendID:(NSString *)friendID callFrom:(IDCallFrom)callFrom
{
    
    [[IDCallNotificationHandler sharedInstance] startNotificationHandler];
    
    if((callInfo.success  == 1) || (callFrom == IDCallFromRemotePush) || (self.currentCallInfoModel.callOperationType != Call_Operation_Type__General)) {
        
        // If the friend ID of incomming call is not in the friend list then we do nothing. SO the caller will get user offline.
        if (friendID == nil) {
            return;
        }
        NSLog(@"********** userDidReceiveResponseForIncommingCallWithInfo Called **********");
        NSString *callID = callInfo.callID;
        NSString *friendIdentity = callInfo.friendIdentity;
        NSString *userIdentity = userID;
        NSString *voicehostIPAddress = callInfo.voicehostIPAddress;
        int voiceRegisterport = callInfo.voiceRegisterport;
        
//        self.currentCallInfoModel.callingFriendName = callInfo.friendName;
//        self.currentCallInfoModel.callInfo.currentCallType = IDCallTypeIncomming;
        self.currentCallInfoModel.callInfo.currentCallMediaType = callInfo.currentCallMediaType;
        
        if (self.isCallInProgress && self.currentCallInfoModel.callingFrnId && (![self.currentCallInfoModel.callingFrnId isEqualToString:friendIdentity])) {
            
            if (isConnectivityModuleEnabled == 1) {
                BOOL result = [[RISessionHandler sharedInstance] addSessionForFriendID:friendIdentity withMediaType:IDCallMediaType_Voice relayServerIP:voicehostIPAddress relayServerPort:voiceRegisterport sessionTimeout:SESSION_TIMEOUT];//[[RIConnectivityManager sharedInstance] createSession:friendIdentity mediaType:MEDIA_NAME relayServerIP:voicehostIPAddress relayServerPort:voiceRegisterport];
                if (result == NO) {
                    NSLog(@"Faild to create session on IDCallManager");
                } else {
                    NSLog(@"Successfully created session on IDCallManager");
                }
            }
            

            
            NSData *packet = nil;
            packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_IN_CALL packetID:callID  userIdentity:userIdentity friendIdentity:friendIdentity];
            
            SignalPacket *packetToSent = [[[SignalPacket alloc] initWithIpAddress:voicehostIPAddress Port:voiceRegisterport SendingPacket:packet NumberOfRepeat:5 TimeInterval:3 InfiniteTimerEnabled:NO friendId:callInfo.friendIdentity] autorelease];
            
            [[SignalPacketSender sharedInstance] sendPacket:packetToSent forPacketType:RingCallPacketTypeAudio onSuccess:^(BOOL finished) {
                //                NSLog(@"********** Packet Sent successfully **********");
            } onFailure:^(NSError *error) {
                //                NSLog(@"********** Packet Sending Failed **********");
            }];
            
            return;
        }
        else if ([VoipUtils isOnCDMAorGSMCall]) {
            
            if (isConnectivityModuleEnabled == 1) {
                BOOL result = [[RISessionHandler sharedInstance] addSessionForFriendID:friendIdentity withMediaType:IDCallMediaType_Voice relayServerIP:voicehostIPAddress relayServerPort:voiceRegisterport sessionTimeout:SESSION_TIMEOUT];//[[RIConnectivityManager sharedInstance] createSession:friendIdentity mediaType:MEDIA_NAME relayServerIP:voicehostIPAddress relayServerPort:voiceRegisterport];
                if (result == NO) {
                    NSLog(@"Faild to create session on IDCallManager");
                } else {
                    NSLog(@"Successfully created session on IDCallManager");
                }
            }
            
            
            NSData *packet = nil;
            packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_IN_CALL packetID:callID  userIdentity:userIdentity friendIdentity:friendIdentity];
            
            SignalPacket *packetToSent = [[[SignalPacket alloc] initWithIpAddress:voicehostIPAddress Port:voiceRegisterport SendingPacket:packet NumberOfRepeat:5 TimeInterval:3 InfiniteTimerEnabled:NO friendId:callInfo.friendIdentity] autorelease];
            
            [[SignalPacketSender sharedInstance] sendPacket:packetToSent forPacketType:RingCallPacketTypeAudio onSuccess:^(BOOL finished) {
                //                NSLog(@"********** Packet Sent successfully **********");
            } onFailure:^(NSError *error) {
                //                NSLog(@"********** Packet Sending Failed **********");
            }];
            
            [self callDelegateToStartBackgroundKeepAlive];
            
            return;
        }
        else {
            [self setIncomoingInfoFrom374:callInfo withCallFrom:callFrom userID:userID freiendID:friendID];
        }
    }
}


#pragma mark - Process Call Signalling

-(void) processCallSignal:(NSData *) data
{
    int totalRead = 0;
    
    @try {
        self.currentCallInfoModel.packetType = CFSwapInt32LittleToHost(*(int*)([[data subdataWithRange:NSMakeRange(totalRead, 1)] bytes]));
    }
    @catch (NSException *exception) {
        NSLog(@"-----------------------  Packet type not valid for RingCallModule  -----------------------");
        return;
    }
    
    
    if (self.currentCallInfoModel.packetType != CallResponseType_VOICE_MEDIA) {
        NSLog(@"Receive Packet Type:%lu",(unsigned long)self.currentCallInfoModel.packetType);

        if (![IDCallManager getCallSignalingPacketInfo:data]) {
#if STATE_DEVELOPMENT
            NSLog(@"-----------------------  Faild to process call signal  -----------------------");
#endif
            return;
        }
    }
    
    self.isValidSignal = YES;
    

#if STATE_DEVELOPMENT
    if (self.currentCallInfoModel.packetType != CallResponseType_VOICE_MEDIA) {
        
        
        switch (self.currentCallInfoModel.packetType)
        {
            case CallResponseType_VOICE_MEDIA:
                NSLog(@"Call Received State : CallResponseType_VOICE_MEDIA");
                
                break;
            case CallResponseType_VOICE_REGISTER:
                NSLog(@"Call Received State : CallResponseType_VOICE_REGISTER");
                
                break;
            case CallResponseType_VOICE_UNREGISTERED:
                NSLog(@"Call Received State : CallResponseType_VOICE_UNREGISTERED");
                
                break;
            case CallResponseType_VOICE_REGISTER_CONFIRMATION:
                NSLog(@"Call Received State : CallResponseType_VOICE_REGISTER_CONFIRMATION");
                
                break;
            case CallResponseType_KEEPALIVE:
                NSLog(@"Call Received State : CallResponseType_KEEPALIVE");
                
                break;
            case CallResponseType_CALLING:
                NSLog(@"Call Received State : CallResponseType_CALLING");
                
                break;
            case CallResponseType_RINGING:
                NSLog(@"Call Received State : CallResponseType_RINGING");
                
                break;
            case CallResponseType_IN_CALL:
                NSLog(@"Call Received State : CallResponseType_IN_CALL");
                
                break;
            case CallResponseType_ANSWER:
                NSLog(@"Call Received State : CallResponseType_ANSWER");
                
                break;
            case CallResponseType_BUSY:
                NSLog(@"Call Received State : CallResponseType_BUSY");
                
                break;
            case CallResponseType_CANCELED:
                NSLog(@"Call Received State : CallResponseType_CANCELED");
                
                break;
            case CallResponseType_CONNECTED:
                NSLog(@"Call Received State : CallResponseType_CONNECTED");
                
                break;
            case CallResponseType_DISCONNECTED:
                NSLog(@"Call Received State : CallResponseType_DISCONNECTED");
                
                break;
            case CallResponseType_BYE:
                NSLog(@"Call Received State : CallResponseType_BYE");
                
                break;
            case CallResponseType_Auth:
                NSLog(@"Call Received State : CallResponseType_Auth");
                
                break;
            case CallResponseType_NO_ANSWER:
                NSLog(@"Call Received State : CallResponseType_NO_ANSWER");
                
                break;
            case CallResponseType_USER_AVAILABLE:
                NSLog(@"Call Received State : CallResponseType_USER_AVAILABLE");
                
                break;
            case CallResponseType_USER_NOT_AVAILABLE:
                NSLog(@"Call Received State : CallResponseType_USER_NOT_AVAILABLE");
                
                break;
            case CallResponseType_IN_CALL_CONFIRMATION:
                NSLog(@"Call Received State : CallResponseType_IN_CALL_CONFIRMATION");
                
                break;
            case CallResponseType_Testing:
                NSLog(@"Call Received State : CallResponseType_Testing");
                
                break;
            case CallResponseType_VOICE_REGISTER_PUSH:
                NSLog(@"Call Received State : CallResponseType_VOICE_REGISTER_PUSH");
                
                break;
            case CallResponseType_VOICE_REGISTER_PUSH_CONFIRMATION:
                NSLog(@"Call Received State : CallResponseType_VOICE_REGISTER_PUSH_CONFIRMATION");
                
                break;
            case CallResponseType_VOICE_CALL_HOLD:
            {
                NSLog(@"Call Received State : CallResponseType_VOICE_CALL_HOLD");
                
            }
                break;
            case CallResponseType_VOICE_CALL_HOLD_CONFIRMATION:
            {
                NSLog(@"Call Received State : CallResponseType_VOICE_CALL_HOLD_CONFIRMATION");
                
            }
                break;
            case CallResponseType_VOICE_CALL_UNHOLD:
            {
                NSLog(@"Call Received State : CallResponseType_VOICE_CALL_UNHOLD");
                
            }
                break;
            case CallResponseType_VOICE_UNHOLD_CONFIRMATION:
            {
                NSLog(@"Call Received State : CallResponseType_VOICE_UNHOLD_CONFIRMATION");
                
            }
                break;
            default:
                break;
        }
        
    }
#endif

    
    
    
    switch (self.currentCallInfoModel.packetType) {
            
        case CallResponseType_VOICE_MEDIA:  //MARK: CallResponseType_VOICE_MEDIA
        {
            if (self.currentCallInfoModel.currentCallState == CallResponseType_CONNECTED || self.currentCallInfoModel.currentCallState == CallResponseType_ANSWER) {
                
                NSString* answerTimerKey = [IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.callInfo.callID andSignalType:CallResponseType_ANSWER];
                [[SignalPacketSender sharedInstance] stopSendingPacketForKey:answerTimerKey onSuccess:^(BOOL finished) {
                    //CallResponseType_VOICE_MEDIA Sending Timmer Stopped Successfully
                } onFailure:^(NSError *error) {
                    //CallResponseType_VOICE_MEDIA Sending Timmer Failed To Stop
                }];
                [[RingCallAudioManager sharedInstance] processReceivedRTPPacket:data];
            } else {
                self.isValidSignal = NO ;
            }
        }
            break;
            
        case CallResponseType_VOICE_REGISTER_CONFIRMATION:  //MARK: CallResponseType_VOICE_REGISTER_CONFIRMATION
        {
            NSString* callRegisterTimerKey = [IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.packetID andSignalType:CallResponseType_VOICE_REGISTER];
            [[SignalPacketSender sharedInstance] stopSendingPacketForKey:callRegisterTimerKey onSuccess:^(BOOL finished) {
                //Packet Sending Timmer Stopped Successfully
            } onFailure:^(NSError *error) {
                //Packet Sending Timmer Failed To Stop
            }];
            
            RCCallInfoModel *incomingCallDTO = [[IDCallSignalBuffer sharedInstance].callList objectForKey:self.currentCallInfoModel.packetID];
            if (incomingCallDTO != nil)
            {
                
                //                incomingCallDTO.callServerInfo.voiceBindingPort = [IDCallManager sharedInstance].currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort;
                incomingCallDTO.callServerInfo.voiceBindingPort = [IDCallManager sharedInstance].voiceBindingPort;
                incomingCallDTO.responseType = CallResponseType_VOICE_REGISTER_CONFIRMATION;
                
                if (isConnectivityModuleEnabled == 1) {
                    [[RIConnectivityManager sharedInstance] setRelayServerInformation:incomingCallDTO.friendIdentity  mediaType:MEDIA_TYPE_AUDIO relayServerIP:incomingCallDTO.callServerInfo.voicehostIPAddress relayServerPort:self.voiceBindingPort];
                }
                
              
                NSData *packetkeepalive = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_KEEPALIVE packetID:incomingCallDTO.callID userIdentity:incomingCallDTO.userIdentity friendIdentity:incomingCallDTO.friendIdentity];
                
                SignalPacket *packetToSent = [[[SignalPacket alloc] initWithIpAddress:incomingCallDTO.callServerInfo.voicehostIPAddress Port:incomingCallDTO.callServerInfo.voiceBindingPort SendingPacket:packetkeepalive NumberOfRepeat:6 TimeInterval:5 InfiniteTimerEnabled:NO friendId:incomingCallDTO.friendIdentity] autorelease];
                
                [[SignalPacketSender sharedInstance] sendPacket:packetToSent forPacketType:RingCallPacketTypeAudio onSuccess:^(BOOL finished) {
                    //Packet Sent successfully
                } onFailure:^(NSError *error) {
                    //Packet Sending Failed
                }];
                
                if (incomingCallDTO.currentCallType == IDCallTypeOutGoing ) {
                    
                    self.currentCallInfoModel.callInfo.callID = incomingCallDTO.callID;
                    self.currentCallInfoModel.callInfo.userIdentity = incomingCallDTO.userIdentity;
                    self.currentCallInfoModel.callInfo.friendIdentity = incomingCallDTO.friendIdentity;
                    self.currentCallInfoModel.callInfo.friendDeviceToken = incomingCallDTO.friendDeviceToken;
                    self.currentCallInfoModel.callingFrnId = incomingCallDTO.friendIdentity;
                    self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort = incomingCallDTO.callServerInfo.voiceBindingPort;
                    self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress = incomingCallDTO.callServerInfo.voicehostIPAddress;
                    self.currentCallInfoModel.callInfo.callServerInfo.voiceRegisterport = incomingCallDTO.callServerInfo.voiceRegisterport;
                    
                    self.currentCallInfoModel.callInfo.callingFrnDevicePlatformCode = incomingCallDTO.callingFrnDevicePlatformCode;
                    self.currentCallInfoModel.callInfo.appTypeOfFriend = incomingCallDTO.appTypeOfFriend;
                    self.currentCallInfoModel.callInfo.presence = incomingCallDTO.presence;
                    
                    NSLog(@"Call_Operation_Type__General: %lu", (unsigned long)self.currentCallInfoModel.callOperationType);
                    
                    switch (self.currentCallInfoModel.callOperationType) {
                            
                        case Call_Operation_Type__General:
                            
                            if (self.currentCallInfoModel.callInfo.presence == 3) {
                                
                                [[RingCallAudioManager sharedInstance] playRingBackTone];

                            }
                            
                            incomingCallDTO.responseType = CallResponseType_CALLING;
                            self.currentCallInfoModel.currentCallState = incomingCallDTO.responseType;
                            NSData *packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_CALLING packetID:incomingCallDTO.callID userIdentity:incomingCallDTO.userIdentity friendIdentity:incomingCallDTO.friendIdentity];
                            
                            SignalPacket *packetToSent = [[[SignalPacket alloc] initWithIpAddress:incomingCallDTO.callServerInfo.voicehostIPAddress Port:incomingCallDTO.callServerInfo.voiceBindingPort SendingPacket:packet NumberOfRepeat:10 TimeInterval:3 InfiniteTimerEnabled:NO friendId:incomingCallDTO.friendIdentity] autorelease];
                            
                            [[SignalPacketSender sharedInstance] sendPacket:packetToSent forPacketType:RingCallPacketTypeAudio  onSuccess:^(BOOL finished) {
#if STATE_DEVELOPMENT
                                NSLog(@"CallResponseType_CALLING Packet Sent successfully");
#endif
                            } onFailure:^(NSError *error) {
#if STATE_DEVELOPMENT
                                NSLog(@"CallResponseType_CALLING Packet Sending Failed");
#endif
                            }];
                            [[IDCallManager sharedInstance] performSelector:@selector(sendVoiceregisterPush) withObject:nil afterDelay:15.0];
                            break;
                            
                        case Call_Operation_Type__SendBusyAfterReg:
                            if([self.callManagerDelegate respondsToSelector:@selector(ringCallShouldEndWithBusyMessage)]) {
                                [self.callManagerDelegate ringCallShouldEndWithBusyMessage];
                            }
                            
                            break;
                            
                            
                        default:
                            break;
                    }
                    
                }
                else
                {
                    currentCallInfoModel.callInfo.currentCallFrom = incomingCallDTO.currentCallFrom;
                }
            }
            else
            {
                self.isValidSignal = NO;
            }
        }
            break;
            
        case CallResponseType_CALLING:  //MARK: CallResponseType_CALLING
        {
            RCCallInfoModel *incomingCallDTO = [[[RCCallInfoModel alloc] init] autorelease];
            incomingCallDTO = [[IDCallSignalBuffer sharedInstance].callList objectForKey:self.currentCallInfoModel.packetID];
            
            if (incomingCallDTO != nil)
            {
                if(self.isCallInProgress)
                {
                    if ([self.currentCallInfoModel.callInfo.callID isEqualToString:incomingCallDTO.callID])
                    {
                        NSData *packet = nil;
                        
                        if (self.currentCallInfoModel.currentCallState == CallResponseType_RINGING) {
                            NSLog(@"---------------------Will send ringing(normal call)...");
                            packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_RINGING packetID:self.currentCallInfoModel.callInfo.callID userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callingFrnId];
                        } else if (self.currentCallInfoModel.currentCallState == CallResponseType_CONNECTED) {
                            NSLog(@"---------------------Will send connected(normal call)...");
                            packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_CONNECTED packetID:self.currentCallInfoModel.callInfo.callID userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callingFrnId];
                        } else {
                            NSLog(@"---------------------Will send ringing(normal call)...");
                            packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_RINGING packetID:incomingCallDTO.callID userIdentity:incomingCallDTO.userIdentity friendIdentity:incomingCallDTO.friendIdentity];
                        }
                        
                        if (isConnectivityModuleEnabled == 1) {
                            [[RIConnectivityManager sharedInstance] sendTo:packet friendID:incomingCallDTO.friendIdentity destinationIPaddress:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress destinationPort:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort mediaType:MEDIA_TYPE_AUDIO];
                        } else {
                            [[CallSocketCommunication sharedInstance].udpSocket send:packet toHost:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort];

                        }
                        
                        self.isValidSignal = NO;
                        return;
                    }
                    else if ([incomingCallDTO.friendIdentity isEqualToString:self.currentCallInfoModel.callingFrnId])
                    {
                        // Both caller and callee are calling each other at the same time. So send connected directly.
                        
                        NSLog(@"---------------------Will send connected(if both are calling each other)...");
                        
                        NSData *packet = nil;
                        NSString* callRegisterTimerKey =[IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.callInfo.callID andSignalType:CallResponseType_VOICE_REGISTER];
                        
                        [[SignalPacketSender sharedInstance] stopSendingPacketForKey:callRegisterTimerKey onSuccess:^(BOOL finished) {
                            //Packet Sending Timmer Stopped Successfully
                        } onFailure:^(NSError *error) {
                            //Packet Sending Timmer Failed To Stop
                        }];
                        
                        NSString* callingTimerKey =[IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.callInfo.callID andSignalType:CallResponseType_CALLING];
                        
                        [[SignalPacketSender sharedInstance] stopSendingPacketForKey:callingTimerKey onSuccess:^(BOOL finished) {
                            //Packet Sending Timmer Stopped Successfully
                        } onFailure:^(NSError *error) {
                            //Packet Sending Timmer Failed To Stop
                        }];
                        
                        
                        [self stopKeepAliveWithVoiceServerForCallID:self.currentCallInfoModel.callInfo.callID];
                        [self stopKeepAliveWithVoiceServerForCallID:incomingCallDTO.callID];
                        
                        
      
                        if (self.currentCallInfoModel.callInfo.callServerInfo.callInitiationTime > 0 && self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress && self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort && (incomingCallDTO.callServerInfo.callInitiationTime > self.currentCallInfoModel.callInfo.callServerInfo.callInitiationTime) && self.currentCallInfoModel.callInfo.presence != 3) {
                            NSLog(@"Will take currentCallDTO");
                            NSLog(@"Because currentCallServerDTO.callInitiationTime:%lld is smaller than incomingCallDTO.callInitiationTime:%lld",self.currentCallInfoModel.callInfo.callServerInfo.callInitiationTime,incomingCallDTO.callServerInfo.callInitiationTime);
                            
                            self.currentCallInfoModel.packetType = CallResponseType_ANSWER;
                            self.currentCallInfoModel.callInfo.callingFrnDevicePlatformCode = incomingCallDTO.callingFrnDevicePlatformCode;
                            self.currentCallInfoModel.callingFriendName = incomingCallDTO.friendName;
                            self.currentCallInfoModel.callInfo.currentCallType = IDCallTypeOutGoing;
                            
                            if (isConnectivityModuleEnabled == 1) {
                                [[RIConnectivityManager sharedInstance] startP2PCall:self.currentCallInfoModel.callInfo.friendIdentity  mediaType:MEDIA_TYPE_AUDIO isCaller:true];
                                [[RISessionHandler sharedInstance] verifySessionForFriendID:self.currentCallInfoModel.callInfo.friendIdentity withMediaType:IDCallMediaType_Voice];
                                NSLog(@"startp2pcall has been called 3");
                            }
                            
                        }
                        else {
                            NSLog(@"will take incomingCallDTO");
                            NSLog(@"Because incomingCallDTO.callInitiationTime:%lld is smaller than currentCallServerDTO.callInitiationTime:%lld",incomingCallDTO.callServerInfo.callInitiationTime,self.currentCallInfoModel.callInfo.callServerInfo.callInitiationTime);
                            
                            if (incomingCallDTO.callServerInfo.voiceBindingPort > 0) {
                                
                                self.currentCallInfoModel.callInfo.callID = incomingCallDTO.callID;
                                self.currentCallInfoModel.packetType = CallResponseType_ANSWER;
                                self.currentCallInfoModel.callInfo.userIdentity = incomingCallDTO.userIdentity;
                                self.currentCallInfoModel.callInfo.friendIdentity = incomingCallDTO.friendIdentity;
                                self.currentCallInfoModel.callingFrnId = incomingCallDTO.friendIdentity;
                                self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort = incomingCallDTO.callServerInfo.voiceBindingPort;
                                self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress = incomingCallDTO.callServerInfo.voicehostIPAddress;
                                self.currentCallInfoModel.callInfo.callServerInfo.voiceRegisterport = incomingCallDTO.callServerInfo.voiceRegisterport;
                                self.currentCallInfoModel.callInfo.callingFrnDevicePlatformCode = incomingCallDTO.callingFrnDevicePlatformCode;
                                self.currentCallInfoModel.callInfo.appTypeOfFriend = incomingCallDTO.appTypeOfFriend;
                                self.currentCallInfoModel.callInfo.presence = incomingCallDTO.presence;
                                self.currentCallInfoModel.callingFriendName = incomingCallDTO.friendName;
                                self.currentCallInfoModel.callInfo.currentCallType = IDCallTypeIncomming;
                                
                                [[IDCallSignalBuffer sharedInstance] dequeueForKey:self.currentCallInfoModel.callInfo.callID];
                                
                                if (isConnectivityModuleEnabled == 1) {
                                    [[RIConnectivityManager sharedInstance] startP2PCall:self.currentCallInfoModel.callInfo.friendIdentity  mediaType:MEDIA_TYPE_AUDIO isCaller:false];
                                    [[RISessionHandler sharedInstance] verifySessionForFriendID:self.currentCallInfoModel.callInfo.friendIdentity withMediaType:IDCallMediaType_Voice];

                                    NSLog(@"startp2pcall has been called 4");
                                }
                                
                            } else {
                                
                            }
                        }
                        
                        if ([self checkValidResponse])
                        {
                           self.currentCallInfoModel.isSimultaneousCall = YES;
                        }
                        else
                           self.currentCallInfoModel.isSimultaneousCall = YES;
                        
                        if (self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort > 0) {
                            
                            if (self.currentCallInfoModel.callInfo.currentCallType == IDCallTypeOutGoing) {
                                packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_CONNECTED packetID:self.currentCallInfoModel.callInfo.callID userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callingFrnId];
                                
                                SignalPacket *packetToSent = [[[SignalPacket alloc] initWithIpAddress:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort SendingPacket:packet NumberOfRepeat:0 TimeInterval:3 InfiniteTimerEnabled:NO friendId:self.currentCallInfoModel.callInfo.friendIdentity] autorelease];
                                
                                [[SignalPacketSender sharedInstance] sendPacket:packetToSent forPacketType:RingCallPacketTypeAudio  onSuccess:^(BOOL finished) {
                                    //Packet Sent successfully
                                } onFailure:^(NSError *error) {
                                    //Packet Sending Failed
                                }];
  
                            }
                            
#if STATE_DEVELOPMENT
                            //                            NSLog(@"-------------------Sent CONNECTED from calling block with callID:%@ userID:%@ friendID:%@ IP:%@ port:%d", currentCallDTO.callID, currentCallDTO.userIdentity, currentCallDTO.friendIdentity, currentCallServerDTO.voicehostIPAddress, currentCallServerDTO.voiceBindingPort);
#endif
                            if (self.currentCallInfoModel.currentCallState == CallResponseType_CONNECTED) {
                                self.isValidSignal = NO ;
                                return;
                            } else {
                                self.isValidSignal = YES ;
                                self.currentCallInfoModel.currentCallState = CallResponseType_CONNECTED;
                                
                                if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
                                    //                                    [[RingCallAudioManager sharedInstance] StopSilenceTone];
                                }
                                //                                else {
                                //                                    [[RingCallAudioManager sharedInstance] PlayRingTone];
                                //                                }
                                
                                
                                if (![RingCallAudioManager sharedInstance].isAudioUnitRunning) {
                                    [[RingCallAudioManager sharedInstance] startRecordAndPlayAudio];
                                }
                                
                                if ([RingCallAudioManager sharedInstance].isLocalRingBackToneEnabled) {
                                    [[RingCallAudioManager sharedInstance] stopRingBackTone];
                                }
                                
                                if ([RingCallAudioManager sharedInstance].isRIngtonePlaying) {
                                    [[RingCallAudioManager sharedInstance] StopRingTone];
                                }
                                
                                
                                [self stopKeepAliveWithVoiceServerForCallID:self.currentCallInfoModel.callInfo.callID];
                            }
                        }
                    }
                    else
                    {
                        //                        NSLog(@"---------------------Will send in-call from Calling block...");
                        NSData *packet = nil;
                        packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_IN_CALL packetID:incomingCallDTO.callID  userIdentity:incomingCallDTO.userIdentity friendIdentity:incomingCallDTO.friendIdentity];
                        
                        if (isConnectivityModuleEnabled == 1) {
                            [[RIConnectivityManager sharedInstance] sendTo:packet friendID:incomingCallDTO.friendIdentity destinationIPaddress:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress destinationPort:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort mediaType:MEDIA_TYPE_AUDIO];
                        } else {
                            [[CallSocketCommunication sharedInstance].udpSocket send:packet toHost:incomingCallDTO.callServerInfo.voicehostIPAddress Port:incomingCallDTO.callServerInfo.voiceRegisterport];
                        }
                        
                        
#if STATE_DEVELOPMENT
                        //                        NSLog(@"----------------- incomingCallDTO.callID: %@", incomingCallDTO.callID);
                        //                        NSLog(@"----------------- incomingCallDTO.userIdentity: %@", incomingCallDTO.userIdentity);
                        //                        NSLog(@"----------------- incomingCallDTO.friendIdentity: %@", incomingCallDTO.friendIdentity);
                        //                        NSLog(@"---------------------Sent in-call to IP: %@ and Port: %d", incomingCallDTO.voicehostIPAddress, incomingCallDTO.voiceRegisterport);
#endif
                        
                        
                        self.isValidSignal = NO;
                        return;
                    }
                    
                }
                else {
                    
                    if (incomingCallDTO.callServerInfo.voiceBindingPort > 0) {
                        
                        
                        self.currentCallInfoModel.callInfo.callID = incomingCallDTO.callID;
                        self.currentCallInfoModel.callInfo.userIdentity = incomingCallDTO.userIdentity;
                        self.currentCallInfoModel.callInfo.friendIdentity = incomingCallDTO.friendIdentity;
                        self.currentCallInfoModel.callingFrnId = incomingCallDTO.friendIdentity;
                        self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort = incomingCallDTO.callServerInfo.voiceBindingPort;
                        self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress = incomingCallDTO.callServerInfo.voicehostIPAddress;
                        self.currentCallInfoModel.callInfo.callServerInfo.voiceRegisterport = incomingCallDTO.callServerInfo.voiceRegisterport;
                        self.currentCallInfoModel.callInfo.currentCallFrom = incomingCallDTO.currentCallFrom;
                        self.currentCallInfoModel.callInfo.appTypeOfFriend = incomingCallDTO.appTypeOfFriend;
                        self.currentCallInfoModel.callInfo.presence = incomingCallDTO.presence;
                        self.currentCallInfoModel.callingFriendName = incomingCallDTO.friendName;
                        self.currentCallInfoModel.callInfo.currentCallType = IDCallTypeIncomming;
                        
                        if (self.currentCallInfoModel.callOperationType == Call_Operation_Type__SendBusyAfterReg) {
                            
                            if([self.callManagerDelegate respondsToSelector:@selector(ringCallShouldEndWithBusyMessage)]) {
                                [self.callManagerDelegate ringCallShouldEndWithBusyMessage];
                            }

                        } else {
                            self.currentCallInfoModel.currentCallState = incomingCallDTO.responseType;
                            incomingCallDTO.responseType = CallResponseType_RINGING;
                            
                            if([self.callManagerDelegate respondsToSelector:@selector(showCallViewControllerWithCallInfo:completion:)]) {
                                [self.callManagerDelegate showCallViewControllerWithCallInfo:self.currentCallInfoModel completion:^(BOOL success) {
                                    if (success) {
                                        NSLog(@"Success");
                                        
                                        self.isValidSignal = YES;
                                        self.isCallInProgress = YES;
                                        
                                        self.currentCallInfoModel.callInfo.currentCallType = IDCallTypeIncomming;
                                        self.currentCallInfoModel.currentCallState = CallResponseType_RINGING;
                                        
                                        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
                                            //                            [[RingCallAudioManager sharedInstance] StopSilenceTone];
                                        } else {
                                            [[RingCallAudioManager sharedInstance] PlayRingTone];
                                        }
                                        
                                        
                                        NSData *packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_RINGING packetID:self.currentCallInfoModel.callInfo.callID userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callingFrnId];
                                        
                                        if (isConnectivityModuleEnabled == 1) {
                                            [[RIConnectivityManager sharedInstance] sendTo:packet friendID:incomingCallDTO.friendIdentity destinationIPaddress:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress destinationPort:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort mediaType:MEDIA_TYPE_AUDIO];
                                        } else {
                                            [[CallSocketCommunication sharedInstance].udpSocket send:packet toHost:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort];

                                        }
                                        
                                        for (NSString *callId in [[IDCallSignalBuffer sharedInstance].callList allKeys]) // Stop all other keep alives
                                        {
                                            if (![callId isEqualToString:self.currentCallInfoModel.callInfo.callID])
                                            {
                                                [self stopKeepAliveWithVoiceServerForCallID:callId];
                                            }
                                        }
                                        
                                        if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground) {
                                            // App is not in background.
                                            
                                            // Directly sends answer if the call is from remote push message.
                                            if ((incomingCallDTO.responseType == CallResponseType_RINGING) && (incomingCallDTO.currentCallFrom == IDCallFromRemotePush)) {
                                                
                                                [[RingCallAudioManager sharedInstance] StopRingTone];
                                                
                                                [self.callManagerDelegate didReceiveRemotePushForIncomingCallWithCallInfo:self.currentCallInfoModel];
                                                
                                            }
                                        }
                                        else {
                                            // App is in background state.
                                            incomingCallDTO.currentCallFrom = IDCallFromLocalPush;
                                            self.currentCallInfoModel.callInfo.currentCallFrom = incomingCallDTO.currentCallFrom;
                                            
                                            //                            [[RingCallAudioManager sharedInstance] StopSilenceTone];
                                            //                            [self showLocalNotificationForIncomingCall:currentCallDTO.callingFrnId];
                                            [self.callManagerDelegate didReceiveLocalPushForIncomingCallWithCallInfo:self.currentCallInfoModel];
                                        }
                                        
                                    } else {
                                        NSLog(@"Faild");
                                    }
                                }];
                            }
                        }
                        
                    }
                }
            }
            else
            {
                self.isValidSignal = NO;
            }
        }
            
            break;
        case CallResponseType_RINGING:  //MARK: CallResponseType_RINGING
        {
            if ( self.currentCallInfoModel.currentCallState == CallResponseType_CALLING || [self checkValidResponse] ) {
                
                if (self.currentCallInfoModel.currentCallState == CallResponseType_CALLING)
                [[RingCallAudioManager sharedInstance] playRingBackTone];
                
                NSString* callingTimerKey =[IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.callInfo.callID andSignalType:CallResponseType_CALLING];
                
                [[SignalPacketSender sharedInstance] stopSendingPacketForKey:callingTimerKey onSuccess:^(BOOL finished) {
                    //Packet Sending Timmer Stopped Successfully
                } onFailure:^(NSError *error) {
                    //Packet Sending Timmer Failed To Stop
                }];
                [NSObject cancelPreviousPerformRequestsWithTarget:[IDCallManager sharedInstance] selector:@selector(sendVoiceregisterPush) object:nil];
            } else {
                self.isValidSignal = NO ;
            }
        }
            break;
            
        case CallResponseType_IN_CALL:  //MARK: CallResponseType_IN_CALL
        {
            if (self.currentCallInfoModel.currentCallState == CallResponseType_CALLING || self.currentCallInfoModel.currentCallState == CallResponseType_VOICE_REGISTER_CONFIRMATION || self.currentCallInfoModel.currentCallState == CallResponseType_VOICE_REGISTER  ) {
                
                NSData *packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_IN_CALL_CONFIRMATION packetID:self.currentCallInfoModel.callInfo.callID userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callingFrnId];
                
                if (isConnectivityModuleEnabled) {
                    [[RIConnectivityManager sharedInstance] sendTo:packet friendID:self.currentCallInfoModel.callInfo.friendIdentity destinationIPaddress:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress destinationPort:self.currentCallInfoModel.callInfo.callServerInfo.voiceRegisterport mediaType:MEDIA_TYPE_AUDIO];
                } else {
                    [[CallSocketCommunication sharedInstance].udpSocket send:packet toHost:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:self.currentCallInfoModel.callInfo.callServerInfo.voiceRegisterport];

                }
                
                
                NSString* callingTimerKey =[IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.callInfo.callID andSignalType:CallResponseType_CALLING];
                
                [[SignalPacketSender sharedInstance] stopSendingPacketForKey:callingTimerKey onSuccess:^(BOOL finished) {
                    //Packet Sending Timmer Stopped Successfully
                } onFailure:^(NSError *error) {
                    //Packet Sending Timmer Failed To Stop
                }];
                
                [self stopKeepAliveWithVoiceServerForCallID:self.currentCallInfoModel.callInfo.callID];
                
                NSString * friendID = self.currentCallInfoModel.callInfo.friendIdentity;
                //                NSLog(@"In_CALL from : %@",friendID);
                if (![self.currentCallInfoModel.callingFrnId isEqualToString:friendID]) {
                    self.isValidSignal = NO;
                }
            } else {
                self.isValidSignal = NO ;
            }
        }
            break;
        case CallResponseType_ANSWER :  //MARK: CallResponseType_ANSWER
        {
            RCCallInfoModel *incomingCallDTO = [[IDCallSignalBuffer sharedInstance].callList objectForKey:self.currentCallInfoModel.packetID];
            
            if (self.currentCallInfoModel.callInfo.currentCallType == IDCallTypeIncomming) {
                return;
            }
            
            if (self.currentCallInfoModel.currentCallState == CallResponseType_CALLING && [self checkValidResponse]) {
                
                [NSObject cancelPreviousPerformRequestsWithTarget:[IDCallManager sharedInstance] selector:@selector(sendVoiceregisterPush) object:nil];
                NSData *packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_CONNECTED packetID:self.currentCallInfoModel.callInfo.callID userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callingFrnId];
                
                
                SignalPacket *packetToSent = [[[SignalPacket alloc] initWithIpAddress:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort SendingPacket:packet NumberOfRepeat:0 TimeInterval:3 InfiniteTimerEnabled:NO friendId:self.currentCallInfoModel.callingFrnId] autorelease];
                
                [[SignalPacketSender sharedInstance] sendPacket:packetToSent forPacketType:RingCallPacketTypeAudio onSuccess:^(BOOL finished) {
                    //Packet Sent successfully
                } onFailure:^(NSError *error) {
                    //Packet Sending Failed
                }];
                
                if (self.currentCallInfoModel.currentCallState == CallResponseType_CONNECTED) {
                    self.isValidSignal = NO ;
                } else {
                    self.isValidSignal = YES ;
                    self.currentCallInfoModel.currentCallState = CallResponseType_CONNECTED;
                    
                    [[RingCallAudioManager sharedInstance] stopRingBackTone];
                    [[RingCallAudioManager sharedInstance] startRecordAndPlayAudio];
                    
                    if (isConnectivityModuleEnabled == 1) {
                       [[RIConnectivityManager sharedInstance] startP2PCall:self.currentCallInfoModel.callInfo.friendIdentity  mediaType:MEDIA_TYPE_AUDIO isCaller:true];
                        [[RISessionHandler sharedInstance] verifySessionForFriendID:self.currentCallInfoModel.callInfo.friendIdentity withMediaType:IDCallMediaType_Voice];

                        NSLog(@"startp2pcall has been called 1");
                    }
                    
                   
                    
                    [self stopKeepAliveWithVoiceServerForCallID:self.currentCallInfoModel.callInfo.callID];
                    
                    NSString* callingTimerKey =[IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.callInfo.callID andSignalType:CallResponseType_CALLING];
                    
                    [[SignalPacketSender sharedInstance] stopSendingPacketForKey:callingTimerKey onSuccess:^(BOOL finished) {
                        //Packet Sending Timmer Stopped Successfully
                    } onFailure:^(NSError *error) {
                        //Packet Sending Timmer Failed To Stop
                    }];
                }
            }
            else if (self.currentCallInfoModel.currentCallState == CallResponseType_CONNECTED && [self.currentCallInfoModel.callInfo.callID isEqualToString:incomingCallDTO.callID]) {
                self.isValidSignal = NO ;
                
                NSData *packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_CONNECTED packetID:self.currentCallInfoModel.callInfo.callID userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callingFrnId];
                
                SignalPacket *packetToSent = [[[SignalPacket alloc] initWithIpAddress:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort SendingPacket:packet NumberOfRepeat:0 TimeInterval:3 InfiniteTimerEnabled:NO friendId:self.currentCallInfoModel.callInfo.friendIdentity] autorelease];
                
                [[SignalPacketSender sharedInstance] sendPacket:packetToSent forPacketType:RingCallPacketTypeAudio onSuccess:^(BOOL finished) {
                    //Packet Sent successfully
                } onFailure:^(NSError *error) {
                    //Packet Sending Failed
                }];
                
                //                NSLog(@"Send connected packet again if it misses........");
                
                [self stopKeepAliveWithVoiceServerForCallID:self.currentCallInfoModel.callInfo.callID];
                
                NSString* callingTimerKey =[IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.callInfo.callID andSignalType:CallResponseType_CALLING];
                
                [[SignalPacketSender sharedInstance] stopSendingPacketForKey:callingTimerKey onSuccess:^(BOOL finished) {
                    //Packet Sending Timmer Stopped Successfully
                } onFailure:^(NSError *error) {
                    //Packet Sending Timmer Failed To Stop
                }];
                
                //                NSLog(@"-----------------------Other party didn't get my CONNECTED packet. So sending again...");
            }
            else {
                self.isValidSignal = NO ;
            }
        }
            break;
        case CallResponseType_BUSY:  //MARK: CallResponseType_BUSY
        {
            if ((self.currentCallInfoModel.currentCallState == CallResponseType_CALLING || self.currentCallInfoModel.currentCallState == CallResponseType_DISCONNECTED) && [self checkValidResponse] ) {
                
                NSData *packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_DISCONNECTED packetID:self.currentCallInfoModel.callInfo.callID userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callingFrnId];
                
                if (isConnectivityModuleEnabled == 1) {
                    [[RIConnectivityManager sharedInstance] sendTo:packet friendID:self.currentCallInfoModel.callInfo.friendIdentity destinationIPaddress:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress destinationPort:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort mediaType:MEDIA_TYPE_AUDIO];
                } else {
                    [[CallSocketCommunication sharedInstance].udpSocket send:packet toHost:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort];

                }
                
                
                if (self.currentCallInfoModel.currentCallState == CallResponseType_DISCONNECTED) {
                    self.isValidSignal = NO;
                } else {
                    self.isValidSignal = YES ;
                    self.currentCallInfoModel.currentCallState = CallResponseType_DISCONNECTED;
                    
                    self.currentCallInfoModel.callInfo.currentCallType = IDCallTypeUndefine;
                    [[RingCallAudioManager sharedInstance] stopRingBackTone];
                    
                    [self stopKeepAliveWithVoiceServerForCallID:self.currentCallInfoModel.callInfo.callID];
                    
                    NSString* callingTimerKey =[IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.callInfo.callID andSignalType:CallResponseType_CALLING];
                    
                    [[SignalPacketSender sharedInstance] stopSendingPacketForKey:callingTimerKey onSuccess:^(BOOL finished) {
                        //Packet Sending Timmer Stopped Successfully
                    } onFailure:^(NSError *error) {
                        //Packet Sending Timmer Failed To Stop
                    }];
                }
                
                self.currentCallInfoModel.isValidCall = NO;
            } else {
                self.isValidSignal = NO ;
            }
        }
            break;
        case CallResponseType_CANCELED:  //MARK: CallResponseType_CANCELED
        {
            if ((self.currentCallInfoModel.currentCallState == CallResponseType_RINGING || self.currentCallInfoModel.currentCallState == CallResponseType_ANSWER || self.currentCallInfoModel.currentCallState == CallResponseType_VOICE_REGISTER_CONFIRMATION || self.currentCallInfoModel.currentCallState == CallResponseType_DISCONNECTED) && [self checkValidResponse]) {
                
                NSData *packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_DISCONNECTED packetID:self.currentCallInfoModel.callInfo.callID userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callingFrnId];
                
                if (isConnectivityModuleEnabled == 1) {
                    [[RIConnectivityManager sharedInstance] sendTo:packet friendID:self.currentCallInfoModel.callInfo.friendIdentity destinationIPaddress:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress destinationPort:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort mediaType:MEDIA_TYPE_AUDIO];
                } else {
                    [[CallSocketCommunication sharedInstance].udpSocket send:packet toHost:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort];
                }
                
                
                if (self.currentCallInfoModel.currentCallState == CallResponseType_DISCONNECTED) {
                    self.isValidSignal = NO;
                } else {
                    self.isValidSignal = YES ;
                    self.currentCallInfoModel.currentCallState = CallResponseType_DISCONNECTED;
                    self.currentCallInfoModel.callInfo.currentCallType = IDCallTypeUndefine;
                    
                    if (self.currentCallInfoModel.callInfo.currentCallType == IDCallTypeIncomming ) {
                        [[RingCallAudioManager sharedInstance] StopRingTone];
                        
                        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
                            //                            [[RingCallAudioManager sharedInstance] PlaySilenceTone];
                        }
                    }
                    
                    [self stopKeepAliveWithVoiceServerForCallID:self.currentCallInfoModel.callInfo.callID];
                    
                    NSString* callingTimerKey =[IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.callInfo.callID andSignalType:CallResponseType_CALLING];
                    
                    [[SignalPacketSender sharedInstance] stopSendingPacketForKey:callingTimerKey onSuccess:^(BOOL finished) {
                        //Packet Sending Timmer Stopped Successfully
                    } onFailure:^(NSError *error) {
                        //Packet Sending Timmer Failed To Stop
                    }];
                    
                    NSString* answerTimerKey =[IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.callInfo.callID andSignalType:CallResponseType_ANSWER];
                    
                    [[SignalPacketSender sharedInstance] stopSendingPacketForKey:answerTimerKey onSuccess:^(BOOL finished) {
                        //Packet Sending Timmer Stopped Successfully
                    } onFailure:^(NSError *error) {
                        //Packet Sending Timmer Failed To Stop
                    }];
                }
                
                self.currentCallInfoModel.isValidCall = NO;
            } else {
                self.isValidSignal = NO ;
            }
        }
            break;
        case CallResponseType_CONNECTED:  //MARK: CallResponseType_CONNECTED
        {
            RCCallInfoModel *incomingCallDTO = [[[RCCallInfoModel alloc] init] autorelease];
            incomingCallDTO = [[IDCallSignalBuffer sharedInstance].callList objectForKey:self.currentCallInfoModel.packetID];
            
            if(incomingCallDTO == nil) {
                incomingCallDTO = self.currentCallInfoModel.callInfo;
            }
            
            /*
            if (self.currentCallInfoModel.callInfo.callServerInfo.callInitiationTime > 0 && self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress && self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort && (incomingCallDTO.callServerInfo.callInitiationTime > self.currentCallInfoModel.callInfo.callServerInfo.callInitiationTime)) {
                NSLog(@"CallResponseType_CONNECTED Will take currentCallDTO");
                NSLog(@"Because currentCallServerDTO.callInitiationTime:%lld is smaller than incomingCallDTO.callInitiationTime:%lld",self.currentCallInfoModel.callInfo.callServerInfo.callInitiationTime,incomingCallDTO.callServerInfo.callInitiationTime);
            }
            else {
                NSLog(@"CallResponseType_CONNECTED will take incomingCallDTO");
                NSLog(@"Because incomingCallDTO.callInitiationTime:%lld is smaller than currentCallServerDTO.callInitiationTime:%lld",incomingCallDTO.callServerInfo.callInitiationTime,self.currentCallInfoModel.callInfo.callServerInfo.callInitiationTime);
            }
            */
            
            if ((self.currentCallInfoModel.currentCallState == CallResponseType_ANSWER || self.currentCallInfoModel.currentCallState == CallResponseType_CALLING) && [self checkValidResponse])
            {
                self.isValidSignal = YES ;
                self.currentCallInfoModel.currentCallState = CallResponseType_CONNECTED;
                
                if (![RingCallAudioManager sharedInstance].isAudioUnitRunning) {
                    [[RingCallAudioManager sharedInstance] startRecordAndPlayAudio];
                }
                
                
                [[RingCallAudioManager sharedInstance] stopRingBackTone];
                
                [[RingCallAudioManager sharedInstance] StopRingTone];
                
                
                NSString* callingTimerKey =[IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.callInfo.callID andSignalType:CallResponseType_CALLING];
                
                [[SignalPacketSender sharedInstance] stopSendingPacketForKey:callingTimerKey onSuccess:^(BOOL finished) {
                    //Packet Sending Timmer Stopped Successfully
                } onFailure:^(NSError *error) {
                    //Packet Sending Timmer Failed To Stop
                }];
                
                
                [self stopKeepAliveWithVoiceServerForCallID:self.currentCallInfoModel.callInfo.callID];
                
                NSString* answerTimerKey =[IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.callInfo.callID andSignalType:CallResponseType_ANSWER];
                
                [[SignalPacketSender sharedInstance] stopSendingPacketForKey:answerTimerKey onSuccess:^(BOOL finished) {
                    //Packet Sending Timmer Stopped Successfully
                } onFailure:^(NSError *error) {
                    //Packet Sending Timmer Failed To Stop
                }];
                
            } else if (([self.currentCallInfoModel.callingFrnId isEqualToString:incomingCallDTO.friendIdentity]) && (![self.currentCallInfoModel.callInfo.callID isEqualToString:incomingCallDTO.callID]))
            {
                //                NSLog(@"Invalid signal but both currentCallDTO.callingFrnId and incomingCallDTO.friendIdentity arfe same, so will accept CONNECTED signal...");
                self.isValidSignal = YES ;
                self.currentCallInfoModel.currentCallState = CallResponseType_CONNECTED;
                
                [[RingCallAudioManager sharedInstance] StopRingTone];
                
                NSString* callingTimerKey =[IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.callInfo.callID andSignalType:CallResponseType_CALLING];
                
                [[SignalPacketSender sharedInstance] stopSendingPacketForKey:callingTimerKey onSuccess:^(BOOL finished) {
                    //Packet Sending Timmer Stopped Successfully
                } onFailure:^(NSError *error) {
                    //Packet Sending Timmer Failed To Stop
                }];
                
                
                [self stopKeepAliveWithVoiceServerForCallID:self.currentCallInfoModel.callInfo.callID];
                [self stopKeepAliveWithVoiceServerForCallID:incomingCallDTO.callID];
                
                
                self.currentCallInfoModel.callInfo.callID = incomingCallDTO.callID;
                self.currentCallInfoModel.packetType = CallResponseType_ANSWER;
                self.currentCallInfoModel.callInfo.userIdentity = incomingCallDTO.userIdentity;
                self.currentCallInfoModel.callInfo.friendIdentity = incomingCallDTO.friendIdentity;
                self.currentCallInfoModel.callingFrnId = incomingCallDTO.friendIdentity;
                self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort = incomingCallDTO.callServerInfo.voiceBindingPort;
                self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress = incomingCallDTO.callServerInfo.voicehostIPAddress;
                self.currentCallInfoModel.callInfo.callServerInfo.voiceRegisterport = incomingCallDTO.callServerInfo.voiceRegisterport;
                self.currentCallInfoModel.callInfo.callingFrnDevicePlatformCode = incomingCallDTO.callingFrnDevicePlatformCode;
                self.currentCallInfoModel.callInfo.appTypeOfFriend = incomingCallDTO.appTypeOfFriend;
                self.currentCallInfoModel.callInfo.presence = incomingCallDTO.presence;
                
                [[IDCallSignalBuffer sharedInstance] dequeueForKey:self.currentCallInfoModel.callInfo.callID];
                
            } else {
                
                self.isValidSignal = NO ;
                
                NSString* callingTimerKey =[IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.callInfo.callID andSignalType:CallResponseType_CALLING];
                
                [[SignalPacketSender sharedInstance] stopSendingPacketForKey:callingTimerKey onSuccess:^(BOOL finished) {
                    //Packet Sending Timmer Stopped Successfully
                } onFailure:^(NSError *error) {
                    //Packet Sending Timmer Failed To Stop
                }];
                
                
                [self stopKeepAliveWithVoiceServerForCallID:self.currentCallInfoModel.callInfo.callID];
		[self stopKeepAliveWithVoiceServerForCallID:incomingCallDTO.callID];
            }
            
            
            if (self.isValidSignal && [RingCallAudioManager sharedInstance].isRIngtonePlaying && ![RingCallAudioManager sharedInstance].isAudioUnitRunning) {
                [[RingCallAudioManager sharedInstance] StopRingTone];
                [[RingCallAudioManager sharedInstance] startRecordAndPlayAudio];
            }
            
        }
            break;
        case CallResponseType_DISCONNECTED:  //MARK: CallResponseType_DISCONNECTED
        {
            if ((self.currentCallInfoModel.currentCallState == CallResponseType_CANCELED || self.currentCallInfoModel.currentCallState == CallResponseType_BUSY || self.currentCallInfoModel.currentCallState  == CallResponseType_BYE) && [self checkValidResponse]) {
                
                self.isValidSignal = YES ;
                self.currentCallInfoModel.callInfo.currentCallType = IDCallTypeUndefine;
                
                if (self.currentCallInfoModel.callInfo.currentCallType == IDCallTypeIncomming ) {
                    [[RingCallAudioManager sharedInstance] StopRingTone];
                    
                    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
                        //                        [[RingCallAudioManager sharedInstance] PlaySilenceTone];
                    }
                } else {
                    [[RingCallAudioManager sharedInstance] stopRingBackTone];
                }
                
                NSString* busytimerKey =[IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.callInfo.callID andSignalType:CallResponseType_BUSY];
                
                [[SignalPacketSender sharedInstance] stopSendingPacketForKey:busytimerKey onSuccess:^(BOOL finished) {
                    //Packet Sending Timmer Stopped Successfully
                } onFailure:^(NSError *error) {
                    //Packet Sending Timmer Failed To Stop
                }];
                
                NSString*  canceltimerKey =[IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.callInfo.callID andSignalType:CallResponseType_CANCELED];
                
                [[SignalPacketSender sharedInstance] stopSendingPacketForKey:canceltimerKey onSuccess:^(BOOL finished) {
#if STATE_DEVELOPMENT
                    NSLog(@"CallResponseType_CANCELED Timmer Stopped Successfully");
#endif
                } onFailure:^(NSError *error) {
#if STATE_DEVELOPMENT
                    NSLog(@"CallResponseType_CANCELED Timmer Failed To Stop");
#endif
                }];
                
                NSString*  byetimerKey =[IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.callInfo.callID andSignalType:CallResponseType_BYE];
                
                [[SignalPacketSender sharedInstance] stopSendingPacketForKey:byetimerKey onSuccess:^(BOOL finished) {
                    //Packet Sending Timmer Stopped Successfully
                } onFailure:^(NSError *error) {
                    //Packet Sending Timmer Failed To Stop
                }];
                
                [self stopKeepAliveWithVoiceServerForCallID:self.currentCallInfoModel.callInfo.callID];
                
                NSString* callingTimerKey =[IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.callInfo.callID andSignalType:CallResponseType_CALLING];
                
                [[SignalPacketSender sharedInstance] stopSendingPacketForKey:callingTimerKey onSuccess:^(BOOL finished) {
                    //Packet Sending Timmer Stopped Successfully
                } onFailure:^(NSError *error) {
                    //Packet Sending Timmer Failed To Stop
                }];
                
                self.currentCallInfoModel.isValidCall = NO;
                
                if (isConnectivityModuleEnabled == 1) {
                    //[[RIConnectivityManager sharedInstance] closeSession:self.currentCallInfoModel.callInfo.friendIdentity mediaType:MEDIA_NAME];
                    [[RISessionHandler sharedInstance] removeSessionForFriendID:self.currentCallInfoModel.callInfo.friendIdentity withMediaType:IDCallMediaType_Voice];

                }
                
            }
            else {
                self.isValidSignal = NO ;
            }
        }
            break;
        case CallResponseType_BYE:  //MARK: CallResponseType_BYE
        {
            if ((self.currentCallInfoModel.currentCallState == CallResponseType_CONNECTED || self.currentCallInfoModel.currentCallState == CallResponseType_VOICE_CALL_HOLD || self.currentCallInfoModel.currentCallState == CallResponseType_ANSWER || self.currentCallInfoModel.currentCallState == CallResponseType_DISCONNECTED || self.currentCallInfoModel.currentCallState == CallResponseType_CALLING) && [self checkValidResponse]) {
                
                
                NSData *packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_DISCONNECTED packetID:self.currentCallInfoModel.callInfo.callID userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callingFrnId];
                
                if (isConnectivityModuleEnabled == 1) {
                    [[RIConnectivityManager sharedInstance] sendTo:packet friendID:self.currentCallInfoModel.callInfo.friendIdentity destinationIPaddress:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress destinationPort:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort mediaType:MEDIA_TYPE_AUDIO];
                }
                else {
                    [[CallSocketCommunication sharedInstance].udpSocket send:packet toHost:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort];
                }
                
                
                
                if (self.currentCallInfoModel.currentCallState == CallResponseType_DISCONNECTED) {
                    self.isValidSignal = NO;
                } else {
                    self.isValidSignal = YES ;
                    self.currentCallInfoModel.currentCallState = CallResponseType_DISCONNECTED;
                    self.currentCallInfoModel.callInfo.currentCallType = IDCallTypeUndefine;
                }
                
                self.currentCallInfoModel.isValidCall = NO;
            } else {
                self.isValidSignal = NO ;
            }
        }
            break;
        case CallResponseType_NO_ANSWER:  //MARK: CallResponseType_NO_ANSWER
        {
            if ((self.currentCallInfoModel.currentCallState == CallResponseType_CALLING) && [self checkValidResponse]) {
                
                NSData *packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_DISCONNECTED packetID:self.currentCallInfoModel.callInfo.callID userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callingFrnId];
                
                if (isConnectivityModuleEnabled == 1) {
                    [[RIConnectivityManager sharedInstance] sendTo:packet friendID:self.currentCallInfoModel.callInfo.friendIdentity destinationIPaddress:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress destinationPort:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort mediaType:MEDIA_TYPE_AUDIO];
                } else {
                    [[CallSocketCommunication sharedInstance].udpSocket send:packet toHost:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort];
                }
                
                
                
                if (self.currentCallInfoModel.currentCallState == CallResponseType_DISCONNECTED) {
                    self.isValidSignal = NO;
                } else {
                    self.isCallInProgress = NO;
                    self.isValidSignal = YES ;
                    self.currentCallInfoModel.currentCallState = CallResponseType_DISCONNECTED;
                    
                    [[RingCallAudioManager sharedInstance] stopRingBackTone];
                    
                    [self stopKeepAliveWithVoiceServerForCallID:self.currentCallInfoModel.callInfo.callID];
                    
                    NSString* callingTimerKey =[IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.callInfo.callID andSignalType:CallResponseType_CALLING];
                    
                    [[SignalPacketSender sharedInstance] stopSendingPacketForKey:callingTimerKey onSuccess:^(BOOL finished) {
                        //Packet Sending Timmer Stopped Successfully
                    } onFailure:^(NSError *error) {
                        //Packet Sending Timmer Failed To Stop
                    }];
                }
                
                self.currentCallInfoModel.isValidCall = NO;
            }  else {
                self.isValidSignal = NO ;
            }
        }
            break;
        case CallResponseType_USER_AVAILABLE:
        {
            
        }
            break;
        case CallResponseType_USER_NOT_AVAILABLE:
        {
            
        }
            break;
        case CallResponseType_IN_CALL_CONFIRMATION:  //MARK: CallResponseType_IN_CALL_CONFIRMATION
        {
            NSString* inCallConfirmationTimerKey =[IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.packetID andSignalType:CallResponseType_IN_CALL];
            
            [[SignalPacketSender sharedInstance] stopSendingPacketForKey:inCallConfirmationTimerKey onSuccess:^(BOOL finished) {
                //Packet Sending Timmer Stopped Successfully
            } onFailure:^(NSError *error) {
                //Packet Sending Timmer Failed To Stop
            }];
            
//            RCCallInfoModel *incomingCallDTO = [[[RCCallInfoModel alloc] init] autorelease];
//            incomingCallDTO = [[IDCallSignalBuffer sharedInstance].callList objectForKey:self.currentCallInfoModel.packetID];
//            NSLog(@"------------- incomingCallDTO: %@",incomingCallDTO);
            
            if (isConnectivityModuleEnabled == 1) {
                //[[RIConnectivityManager sharedInstance] closeSession:self.currentCallInfoModel.callInfo.friendIdentity mediaType:MEDIA_NAME];
                [[RISessionHandler sharedInstance] removeSessionForFriendID:self.currentCallInfoModel.callInfo.friendIdentity withMediaType:IDCallMediaType_Voice];

            }
            
            
//            NSLog(@"------------- CLoase session from incall for(self.currentCallInfoModel.callingFrnId): %@",self.currentCallInfoModel.callingFrnId);
//            NSLog(@"------------- CLoase session from incall for(self.currentCallInfoModel.callInfo.friendIdentity): %@",self.currentCallInfoModel.callInfo.friendIdentity);
            
            self.isValidSignal = NO ;
        }
            break;
        case CallResponseType_VOICE_REGISTER_PUSH:  //MARK: CallResponseType_VOICE_REGISTER_PUSH
        {
            
            self.isValidSignal = NO ;
        }
            break;
        case CallResponseType_VOICE_REGISTER_PUSH_CONFIRMATION:  //MARK: CallResponseType_VOICE_REGISTER_PUSH_CONFIRMATION
        {
            NSString* voicePushConfirmationTimerKey =[IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.callInfo.callID andSignalType:CallResponseType_VOICE_REGISTER_PUSH];
            
            
            [[SignalPacketSender sharedInstance] stopSendingPacketForKey:voicePushConfirmationTimerKey onSuccess:^(BOOL finished) {
                //Packet Sending Timmer Stopped Successfully
            } onFailure:^(NSError *error) {
                //Packet Sending Timmer Failed To Stop
            }];
            
            self.isValidSignal = NO ;
        }
            break;
            /*
             case CallResponseType_VOICE_IGNORE :
             {
             if ([currentCallDTO.callID isEqualToString:currentCallServerDTO.packetID]) {
             
             NSString* callregisterTimerKey =[IDCallMakePacket makeKeyStringWithCallID:currentCallDTO.callID andSignalType:CallResponseType_VOICE_REGISTER];
             NSTimer *callregisterTimer =(NSTimer *) [[CallSocketCommunication sharedInstance].packetSend objectForKey:callregisterTimerKey];
             if (callregisterTimer && [callregisterTimer isValid]) {
             [callregisterTimer invalidate];
             callregisterTimer = nil;
             [[CallSocketCommunication sharedInstance].packetSend removeObjectForKey:callregisterTimerKey];
             }
             
             NSData *packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_VOICE_IGNORE_CONFIRMATION packetID:currentCallDTO.callID userIdentity:currentCallDTO.userIdentity friendIdentity:currentCallDTO.friendIdentity];
             [[CallSocketCommunication sharedInstance].udpSocket send:packet toHost:currentCallServerDTO.voicehostIPAddress Port:currentCallServerDTO.voiceRegisterport];
             
             self.isValidSignal = YES ;
             currentCallDTO.packetType = CallResponseType_CANCELED;
             currentCallDTO.currentCallType = IDCallTypeUndefine;
             currentCallDTO.currentCallState = CallResponseType_Auth;
             } else {
             self.isValidSignal = NO ;
             }
             }
             break;
             case CallResponseType_VOICE_IGNORE_CONFIRMATION :
             {
             NSString* voiceIgnorConfirmationTimerKey =[IDCallMakePacket makeKeyStringWithCallID:currentCallDTO.callID andSignalType:CallResponseType_VOICE_IGNORE];
             NSTimer *voiceIgnorConfirmationTimer =(NSTimer *) [[CallSocketCommunication sharedInstance].packetSend objectForKey:voiceIgnorConfirmationTimerKey];
             if (voiceIgnorConfirmationTimer && [voiceIgnorConfirmationTimer isValid]) {
             [voiceIgnorConfirmationTimer invalidate];
             voiceIgnorConfirmationTimer = nil;
             [[CallSocketCommunication sharedInstance].packetSend removeObjectForKey:voiceIgnorConfirmationTimerKey];
             }
             
             self.isValidSignal = NO ;
             }
             break;
             */
        case CallResponseType_VOICE_CALL_HOLD: //MARK: CallResponseType_VOICE_CALL_HOLD
        {
//            RCCallInfoModel *incomingCallDTO = [[IDCallSignalBuffer sharedInstance].callList objectForKey:self.currentCallInfoModel.packetID];
            RCCallInfoModel *incomingCallDTO = nil;
            incomingCallDTO = self.currentCallInfoModel.callInfo;
            self.currentCallInfoModel.isCallHoldSignalSent = NO;
            
            if ((self.currentCallInfoModel.currentCallState == CallResponseType_CONNECTED || self.currentCallInfoModel.currentCallState == CallResponseType_VOICE_CALL_UNHOLD) && [self checkValidResponse]) {
                
                
                self.currentCallInfoModel.currentCallState = CallResponseType_VOICE_CALL_HOLD; //Change current call state to HOLD.
                self.isValidSignal = YES;
                
                //Start Keeplive timer until get unhold
                NSData *packetkeepalive = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_KEEPALIVE packetID:incomingCallDTO.callID userIdentity:incomingCallDTO.userIdentity friendIdentity:incomingCallDTO.friendIdentity];
                
                
                SignalPacket *packetToSent = [[[SignalPacket alloc] initWithIpAddress:incomingCallDTO.callServerInfo.voicehostIPAddress Port:incomingCallDTO.callServerInfo.voiceBindingPort SendingPacket:packetkeepalive NumberOfRepeat:0 TimeInterval:5 InfiniteTimerEnabled:YES friendId:incomingCallDTO.friendIdentity] autorelease];
                
                [[SignalPacketSender sharedInstance] sendPacket:packetToSent forPacketType:RingCallPacketTypeAudio  onSuccess:^(BOOL finished) {
                    //Packet Sent successfully
                } onFailure:^(NSError *error) {
                    //Packet Sending Failed
                }];
                
                //Send HOLD CONFIRMATION
                NSData *packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_VOICE_CALL_HOLD_CONFIRMATION packetID:incomingCallDTO.callID userIdentity:incomingCallDTO.userIdentity friendIdentity:incomingCallDTO.friendIdentity];
                
                if (isConnectivityModuleEnabled == 1) {
                    [[RIConnectivityManager sharedInstance] sendTo:packet friendID:incomingCallDTO.friendIdentity destinationIPaddress:incomingCallDTO.callServerInfo.voicehostIPAddress destinationPort:incomingCallDTO.callServerInfo.voiceBindingPort mediaType:MEDIA_TYPE_AUDIO];
                } else {
                    [[CallSocketCommunication sharedInstance].udpSocket send:packet toHost:incomingCallDTO.callServerInfo.voicehostIPAddress Port:incomingCallDTO.callServerInfo.voiceBindingPort];
                }
                
                
                
                
                //Stop RTP Timer in call screen and play hold tone.
                if ([RingCallAudioManager sharedInstance].rtpSenderTimer && [RingCallAudioManager sharedInstance].rtpSenderTimer.isValid) {
                    [[RingCallAudioManager sharedInstance].rtpSenderTimer invalidate];
                    [RingCallAudioManager sharedInstance].rtpSenderTimer = nil;
                    //                    [[RingCallAudioManager sharedInstance] resetRTPQueue];
                    //                    [[RingCallAudioManager sharedInstance] playCallHoldTone];
                }
                
                //                [[RingCallAudioManager sharedInstance] resetRTPQueue];
                //                [[RingCallAudioManager sharedInstance] playCallHoldTone];
                
                [[RingCallAudioManager sharedInstance] stop];
                sleep(2);
                [[RingCallAudioManager sharedInstance] start];
                [[RingCallAudioManager sharedInstance] resetRTPQueue];
                [[RingCallAudioManager sharedInstance] playCallHoldTone];
                //                [[RingCallAudioManager sharedInstance]  startRecordAndPlayAudio];
            }
            else if (self.currentCallInfoModel.currentCallState == CallResponseType_VOICE_CALL_HOLD && [self checkValidResponse]){
                //Send HOLD CONFIRMATION
                NSData *packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_VOICE_CALL_HOLD_CONFIRMATION packetID:incomingCallDTO.callID userIdentity:incomingCallDTO.userIdentity friendIdentity:incomingCallDTO.friendIdentity];
                
                if (isConnectivityModuleEnabled == 1) {
                    [[RIConnectivityManager sharedInstance] sendTo:packet friendID:incomingCallDTO.friendIdentity destinationIPaddress:incomingCallDTO.callServerInfo.voicehostIPAddress destinationPort:incomingCallDTO.callServerInfo.voiceBindingPort mediaType:MEDIA_TYPE_AUDIO];
                } else {
                    [[CallSocketCommunication sharedInstance].udpSocket send:packet toHost:incomingCallDTO.callServerInfo.voicehostIPAddress Port:incomingCallDTO.callServerInfo.voiceBindingPort];

                }
                
                
                self.isValidSignal = NO;
                
            }
            else{
                
                self.isValidSignal = NO;
            }
        }
            break;
        case CallResponseType_VOICE_CALL_HOLD_CONFIRMATION: //MARK: CallResponseType_VOICE_CALL_HOLD_CONFIRMATION
        {
            //Stop sending hold packet
            NSString* voiceCallHoldTimerKey =[IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.callInfo.callID andSignalType:CallResponseType_VOICE_CALL_HOLD];
            
            [[SignalPacketSender sharedInstance] stopSendingPacketForKey:voiceCallHoldTimerKey onSuccess:^(BOOL finished) {
                //Packet Sending Timmer Stopped Successfully
            } onFailure:^(NSError *error) {
                //Packet Sending Timmer Failed To Stop
            }];
            
            self.isValidSignal = NO ;
        }
            break;
        case CallResponseType_VOICE_CALL_UNHOLD:  //MARK: CallResponseType_VOICE_CALL_UNHOLD
        {
            RCCallInfoModel *incomingCallDTO = [[IDCallSignalBuffer sharedInstance].callList objectForKey:self.currentCallInfoModel.packetID];
            
            if (incomingCallDTO == nil) {
                incomingCallDTO = self.currentCallInfoModel.callInfo;
            }
            
            if (self.currentCallInfoModel.currentCallState == CallResponseType_VOICE_CALL_HOLD && [self checkValidResponse] && !self.currentCallInfoModel.isCallHoldSignalSent && (self.isGsmInterruption)) {
#if STATE_DEVELOPMENT
                NSLog(@"CallResponseType_VOICE_CALL_UNHOLD received. But we are in GSM call so will send Call Hold again...");
#endif
                self.currentCallInfoModel.currentCallState = CallResponseType_CONNECTED; //Change current call state to UNHOLD.
                [self performCallHold];
                self.isValidSignal = NO;
            } else {
                if (self.currentCallInfoModel.currentCallState == CallResponseType_VOICE_CALL_HOLD && [self checkValidResponse] && !self.currentCallInfoModel.isCallHoldSignalSent) {
                    
                    
                    //                    if (![RingCallAudioManager sharedInstance].isAudioUnitRunning) {
                    //                        //                    NSLog(@"Restart audio unit...");
                    //
                    //                        [[RingCallAudioManager sharedInstance] stop];
                    //                        [[RingCallAudioManager sharedInstance] start];
                    //                    }
                    
                    
                    self.currentCallInfoModel.currentCallState = CallResponseType_CONNECTED; //Change current call state to UNHOLD.
                    self.isValidSignal = YES;
                    //Stop Keeplive timer until get unhold
                    [self stopKeepAliveWithVoiceServerForCallID:self.currentCallInfoModel.callInfo.callID];
                    
                    //Send UNHOLD CONFIRMATION
                    NSData *packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_VOICE_UNHOLD_CONFIRMATION packetID:incomingCallDTO.callID userIdentity:incomingCallDTO.userIdentity friendIdentity:incomingCallDTO.friendIdentity];
                    
                    if (isConnectivityModuleEnabled == 1) {
                        [[RIConnectivityManager sharedInstance] sendTo:packet friendID:incomingCallDTO.friendIdentity destinationIPaddress:incomingCallDTO.callServerInfo.voicehostIPAddress destinationPort:incomingCallDTO.callServerInfo.voiceBindingPort mediaType:MEDIA_TYPE_AUDIO];
                    } else {
                        [[CallSocketCommunication sharedInstance].udpSocket send:packet toHost:incomingCallDTO.callServerInfo.voicehostIPAddress Port:incomingCallDTO.callServerInfo.voiceBindingPort];
                    }
                    
                    //Start RTP Timer in call screen and stop hold tone.
                    if (![RingCallAudioManager sharedInstance].rtpSenderTimer) {
                        [[RingCallAudioManager sharedInstance] stopCallHoldTone];
                        [[RingCallAudioManager sharedInstance] stop];
                        sleep(2);
                        [[RingCallAudioManager sharedInstance] start];
                        [[RingCallAudioManager sharedInstance] resetRTPQueue];
                        [RingCallAudioManager sharedInstance].rtpSenderTimer = [NSTimer scheduledTimerWithTimeInterval:RTP_SENDING_TIME_INTERVAL target:[RingCallAudioManager sharedInstance] selector:@selector(rtpSendingTimerMethod) userInfo:nil repeats:YES];
                    }
                    
                }
                else if (self.currentCallInfoModel.currentCallState == CallResponseType_VOICE_CALL_UNHOLD && [self checkValidResponse]){
                    //Send HOLD CONFIRMATION
                    NSData *packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_VOICE_UNHOLD_CONFIRMATION packetID:incomingCallDTO.callID userIdentity:incomingCallDTO.userIdentity friendIdentity:incomingCallDTO.friendIdentity];
                    
                    if (isConnectivityModuleEnabled == 1) {
                        [[RIConnectivityManager sharedInstance] sendTo:packet friendID:incomingCallDTO.friendIdentity destinationIPaddress:incomingCallDTO.callServerInfo.voicehostIPAddress destinationPort:incomingCallDTO.callServerInfo.voiceBindingPort mediaType:MEDIA_TYPE_AUDIO];
                    } else {
                        [[CallSocketCommunication sharedInstance].udpSocket send:packet toHost:incomingCallDTO.callServerInfo.voicehostIPAddress Port:incomingCallDTO.callServerInfo.voiceBindingPort];
                    }
                    
                    
                    
                    self.isValidSignal = NO;
                    
                }
                else{
                    
                    self.isValidSignal = NO;
                }
            }
            
        }
            break;
        case CallResponseType_VOICE_UNHOLD_CONFIRMATION:  //MARK: CallResponseType_VOICE_UNHOLD_CONFIRMATION
        {
            if ((self.currentCallInfoModel.currentCallState == CallResponseType_VOICE_CALL_UNHOLD) && [self checkValidResponse]) {
                //Stop sending unhold packet
                self.currentCallInfoModel.currentCallState = CallResponseType_CONNECTED;
                
                NSString* voiceCallUnholdTimerKey =[IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.callInfo.callID andSignalType:CallResponseType_VOICE_CALL_UNHOLD];
                
                
                [[SignalPacketSender sharedInstance] stopSendingPacketForKey:voiceCallUnholdTimerKey onSuccess:^(BOOL finished) {
                    
                    
//                    [[RingCallAudioManager sharedInstance] stop];
//                    sleep(2);
//                    [[RingCallAudioManager sharedInstance] stopCallHoldTone];
//                    [[RingCallAudioManager sharedInstance] resetRTPQueue];
//                    [[RingCallAudioManager sharedInstance] startRecordAndPlayAudio];
                    
                    //Start RTP Timer in call screen and stop hold tone.
                    if (![RingCallAudioManager sharedInstance].rtpSenderTimer) {
                        [[RingCallAudioManager sharedInstance] stopCallHoldTone];
                        [[RingCallAudioManager sharedInstance] stop];
                        sleep(2);
                        [[RingCallAudioManager sharedInstance] start];
                        [[RingCallAudioManager sharedInstance] resetRTPQueue];
                        [[RingCallAudioManager sharedInstance] startRecordAndPlayAudio];
//                        [RingCallAudioManager sharedInstance].rtpSenderTimer = [NSTimer scheduledTimerWithTimeInterval:RTP_SENDING_TIME_INTERVAL target:[RingCallAudioManager sharedInstance] selector:@selector(rtpSendingTimerMethod) userInfo:nil repeats:YES];
                    }
                    
                    
                    NSLog(@"********** CallResponseType_VOICE_CALL_UNHOLD Sending Timmer Stopped Successfully **********");
                    self.isValidSignal = YES;
                    
                } onFailure:^(NSError *error) {
                    NSLog(@"********** CallResponseType_VOICE_CALL_UNHOLD Sending Timmer Failed To Stop **********");
                }];
                
            } else {
                self.isValidSignal = NO ;
            }
            
        }
            break;
        case CallResponseType_VOICE_BUSY_MESSAGE:  //MARK: CallResponseType_VOICE_BUSY_MESSAGE
        {
            
            if ((self.currentCallInfoModel.currentCallState == CallResponseType_CALLING) && [self checkValidResponse] ) {
                
                NSData *busy_message_confirmation_packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_VOICE_BUSY_MESSAGE_CONFIRMATION packetID:self.currentCallInfoModel.callInfo.callID userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callingFrnId];
                
                if (isConnectivityModuleEnabled == 1) {
                    [[RIConnectivityManager sharedInstance] sendTo:busy_message_confirmation_packet friendID:self.currentCallInfoModel.callInfo.friendIdentity destinationIPaddress:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress destinationPort:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort mediaType:MEDIA_TYPE_AUDIO];
                } else {
                    [[CallSocketCommunication sharedInstance].udpSocket send:busy_message_confirmation_packet toHost:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort];
                }
                
                
                
                NSData *packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_DISCONNECTED packetID:self.currentCallInfoModel.callInfo.callID userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callingFrnId];
                
                if (isConnectivityModuleEnabled == 1) {
                    [[RIConnectivityManager sharedInstance] sendTo:packet friendID:self.currentCallInfoModel.callInfo.friendIdentity destinationIPaddress:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress destinationPort:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort mediaType:MEDIA_TYPE_AUDIO];
                } else {
                    [[CallSocketCommunication sharedInstance].udpSocket send:packet toHost:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort];
                }
                
                
                
                if (self.currentCallInfoModel.currentCallState == CallResponseType_DISCONNECTED) {
                    self.isValidSignal = NO;
                } else {
                    self.isValidSignal = YES ;
                    self.currentCallInfoModel.currentCallState = CallResponseType_DISCONNECTED;
                    
                    self.currentCallInfoModel.callInfo.currentCallType = IDCallTypeUndefine;
                    
                    [self stopKeepAliveWithVoiceServerForCallID:self.currentCallInfoModel.callInfo.callID];
                    
                    NSString* callingTimerKey =[IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.callInfo.callID andSignalType:CallResponseType_CALLING];
                    
                    [[SignalPacketSender sharedInstance] stopSendingPacketForKey:callingTimerKey onSuccess:^(BOOL finished) {
                        //Packet Sending Timmer Stopped Successfully
                    } onFailure:^(NSError *error) {
                        //Packet Sending Timmer Failed To Stop
                    }];
                    
                    //Notify user and insert into chat DB
                    NSString *busyMessage = [IDCallMakePacket getBusyMessage:data];
                    [self.callManagerDelegate didReceiveBusyMessageForOutgoingCallwithCallInfo:self.currentCallInfoModel busyMessage:busyMessage];
                }
                
                self.currentCallInfoModel.isValidCall = NO;
            } else {
                self.isValidSignal = NO ;
            }
            
        }
            break;
        case CallResponseType_VOICE_BUSY_MESSAGE_CONFIRMATION:  //MARK: CallResponseType_VOICE_BUSY_MESSAGE_CONFIRMATION
        {
            NSString* busyMessageTimerKey =[IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.callInfo.callID andSignalType:CallResponseType_VOICE_BUSY_MESSAGE];
            
            [[SignalPacketSender sharedInstance] stopSendingPacketForKey:busyMessageTimerKey onSuccess:^(BOOL finished) {
                //Packet Sending Timmer Stopped Successfully
            } onFailure:^(NSError *error) {
                //Packet Sending Timmer Failed To Stop
            }];
            
            self.isValidSignal = NO ;
        }
            break;
            
        case CallResponseType_VIDEO_CALL_START: //MARK: CallResponseType_VIDEO_CALL_START
        {
            if([self checkValidResponse]) {
                self.isValidSignal = YES;
                
                if (isConnectivityModuleEnabled == 1) {
                    BOOL result = [[RISessionHandler sharedInstance] addSessionForFriendID:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.friendIdentity withMediaType:IDCallMediaType_Video relayServerIP:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress relayServerPort:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort sessionTimeout:SESSION_TIMEOUT];//createSession:outgoingCallDTO.friendIdentity mediaType:MEDIA_NAME relayServerIP:outgoingCallDTO.callServerInfo.voicehostIPAddress relayServerPort:outgoingCallDTO.callServerInfo.voiceRegisterport];
                    if (result == NO) {
                        NSLog(@"Faild to create video session on IDCallManager");
                    } else {
                        NSLog(@"Successfully created video session on IDCallManager");
                    }
                }

                [self sendVideoBindPortRequestAtRegisterPort];
                NSData *start_confirmation_packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_VIDEO_CALL_START_CONFIRMATION packetID:self.currentCallInfoModel.callInfo.callID userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callingFrnId];
                if (isConnectivityModuleEnabled == 1) {
                    [[RIConnectivityManager sharedInstance] sendTo:start_confirmation_packet friendID:[IDCallManager sharedInstance].currentCallInfoModel.callingFrnId destinationIPaddress:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress destinationPort:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort mediaType:MEDIA_TYPE_AUDIO];
                }
                else
                {
                    [[CallSocketCommunication sharedInstance].udpSocket send:start_confirmation_packet toHost:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort];
                }
            } else {
                self.isValidSignal = NO;

            }
        }
            break;
        case CallResponseType_VIDEO_CALL_START_CONFIRMATION: //MARK: CallResponseType_VIDEO_CALL_START_CONFIRMATION
        {
            NSString* VideoCallStartTimerKey =[IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.callInfo.callID andSignalType:CallResponseType_VIDEO_CALL_START];
            
            [[SignalPacketSender sharedInstance] stopSendingPacketForKey:VideoCallStartTimerKey onSuccess:^(BOOL finished) {
                //Packet Sending Timmer Stopped Successfully
            } onFailure:^(NSError *error) {
                //Packet Sending Timmer Failed To Stop
            }];
            self.isValidSignal = YES;
        }
            break;
        case CallResponseType_VIDEO_BINDING_PORT_CONFIRMATION: //MARK: CallResponseType_VIDEO_BINDING_PORT_CONFIRMATION
            self.isValidSignal = NO;

            if([self checkValidResponse]) {
                if ([IDCallManager sharedInstance].voiceBindingPort>0) {
                    
                    if (isConnectivityModuleEnabled == 1) {
                        
                        [[RIConnectivityManager sharedInstance] setRelayServerInformation:self.currentCallInfoModel.callInfo.friendIdentity  mediaType:MEDIA_TYPE_VIDEO relayServerIP:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress relayServerPort:self.videoBindingPort];
                        if ([[RISessionHandler sharedInstance] getSessionForFriendID:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.friendIdentity withMediaType:IDCallMediaType_Video].isStartP2PCalled == NO) {
                            
                            [[RIConnectivityManager sharedInstance] startP2PCall:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.friendIdentity mediaType:MEDIA_TYPE_VIDEO isCaller:([IDCallManager sharedInstance].currentCallInfoModel.callInfo.currentCallType == 1 ? true : false)];

                        }
                        
                        [[RISessionHandler sharedInstance] verifySessionForFriendID:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.friendIdentity withMediaType:IDCallMediaType_Video];
                    }
                    
                    NSString* videoBindPortTimerKey =[IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.callInfo.callID andSignalType:CallResponseType_VIDEO_BINDING_PORT];
                    
                    [[SignalPacketSender sharedInstance] stopSendingPacketForKey:videoBindPortTimerKey onSuccess:^(BOOL finished) {
                        //Packet Sending Timmer Stopped Successfully
                    } onFailure:^(NSError *error) {
                        //Packet Sending Timmer Failed To Stop
                    }];
                    self.currentCallInfoModel.callInfo.callServerInfo.videoBindingPort = [IDCallManager sharedInstance].videoBindingPort;
                    
                    [[RIVideoMediaSocket sharedInstance] startVideoSocketOpreration];
                    
//                    [self sendVideoKeepAliveRequestAtVideoBindPortEnableInfiniteRepeat:NO];
                    
                }
            }
            break;
        default:
            break;
    }
    
    if (self.isValidSignal) {
        [self.callManagerDelegate didReceiveResponseWithCallInfo:self.currentCallInfoModel];
    }
}

-(void) processVideoSignalData:(NSData *) data
{
    if (data.length) {
        NSInteger totalRead = 0;
        @try {
            NSInteger packetType = CFSwapInt32LittleToHost(*(int*)([[data subdataWithRange:NSMakeRange(totalRead, 1)] bytes]));
            
            if (packetType == CallResponseType_VideoMedia) {
                
                totalRead++;
                NSInteger frameNumber = [IDCallMakePacket getUniqueKey:data startIndex:totalRead];
                totalRead = 5;
                NSInteger totalSequenceNumber = CFSwapInt32LittleToHost(*(int*)([[data subdataWithRange:NSMakeRange(totalRead, 1)] bytes]));
                totalRead++;
                NSInteger sequenceNumber = CFSwapInt32LittleToHost(*(int*)([[data subdataWithRange:NSMakeRange(totalRead, 1)] bytes]));
                totalRead++;
                NSData *sequenceFrameData = [NSMutableData dataWithData:[data subdataWithRange:NSMakeRange(totalRead, data.length - totalRead)]];
                
                if (sequenceNumber == 1) {
                    if (self.currentVideoFrame == nil) {
                        self.currentVideoFrame = [NSMutableArray array];
                    } else {
                        [self.currentVideoFrame removeAllObjects];
                    }
                    
                    self.currentReceiveFrame = frameNumber;
                }
                
                if (self.currentVideoFrame && (self.currentVideoFrame.count+1) == sequenceNumber && self.currentReceiveFrame == frameNumber) {
                    [self.currentVideoFrame insertObject:sequenceFrameData atIndex:sequenceNumber-1];
                    
                    if (sequenceNumber == totalSequenceNumber) {
                        //  NSData* myData = [NSKeyedArchiver archivedDataWithRootObject:self.currentVideoFrame];
                        NSMutableData *recientVideoFrame = [NSMutableData data];
                        //NSLog(@"Play opponient video frame length:%ld",(unsigned long)self.currentVideoFrame.count);
                        for (int counter = 0; counter < self.currentVideoFrame.count; counter++) {
                            [recientVideoFrame appendData:[self.currentVideoFrame objectAtIndex:counter]];
                        }
                        [self.callManagerDelegate didReceiveVideoFrame:(NSData *)recientVideoFrame];
                    }
                }
            } else {
                NSLog(@"Video packetType:%ld",(long)packetType);
                if (packetType == CallResponseType_VIDEO_CALL_END) {
                    
                    NSData *start_confirmation_packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_VIDEO_CALL_END_CONFIRMATION packetID:self.currentCallInfoModel.callInfo.callID userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callingFrnId];
                    
                    if (isConnectivityModuleEnabled == 1) {
                        [[RIConnectivityManager sharedInstance] sendTo:start_confirmation_packet friendID:self.currentCallInfoModel.callInfo.friendIdentity destinationIPaddress:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress  destinationPort:(int)self.currentCallInfoModel.callInfo.callServerInfo.videoBindingPort mediaType:MEDIA_TYPE_VIDEO];
                    } else {
                        [[RIVideoMediaSocket sharedInstance] sendVideoDataWith:start_confirmation_packet toHost:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:self.currentCallInfoModel.callInfo.callServerInfo.videoBindingPort];
                    }
                    
                    BOOL status = [IDCallManager isInterruptedEndSignal:data];
                    if (status) {
                        packetType = CallResponseType_VIDEO_CALL_BOTH_END;
                    }
                    
                } else if(packetType == CallResponseType_VIDEO_CALL_END_CONFIRMATION) {
                    
                    NSString* videoCallEndTimerKey =[IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.callInfo.callID andSignalType:CallResponseType_VIDEO_CALL_END];
                    
                    [[SignalPacketSender sharedInstance] stopSendingPacketForKey:videoCallEndTimerKey onSuccess:^(BOOL finished) {
                        //Packet Sending Timmer Stopped Successfully
                    } onFailure:^(NSError *error) {
                        //Packet Sending Timmer Failed To Stop
                    }];
                    
                } else {
                    // do nothing
                }
                
                [self.callManagerDelegate didReceiveVideoSignalWithtype:packetType];
            }
        }
        @catch (NSException *exception) {
            
        }
        @finally {
            
        }
    }
}


- (NSString *) generateNewCallID
{
    return [IDCallMakePacket randomNumber];
}


// This method is not being used currently, but will be used later.
- (void) showCallViewController {
    RCCallInfoModel *incomingCallDTO = [[[RCCallInfoModel alloc] init] autorelease];
    incomingCallDTO = [[IDCallSignalBuffer sharedInstance].callList objectForKey:self.currentCallInfoModel.packetID];
    
    if([self.callManagerDelegate respondsToSelector:@selector(showCallViewControllerWithCallInfo:completion:)]) {
        [self.callManagerDelegate showCallViewControllerWithCallInfo:self.currentCallInfoModel completion:^(BOOL success) {
            if (success) {
                NSLog(@"Success");
                
                self.isValidSignal = YES;
                self.isCallInProgress = YES;
                
                self.currentCallInfoModel.callInfo.currentCallType = IDCallTypeIncomming;
                self.currentCallInfoModel.currentCallState = CallResponseType_RINGING;
                
                if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
                    //                            [[RingCallAudioManager sharedInstance] StopSilenceTone];
                } else {
                    [[RingCallAudioManager sharedInstance] PlayRingTone];
                }
                
                
                NSData *packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_RINGING packetID:self.currentCallInfoModel.callInfo.callID userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callingFrnId];
                
                if (isConnectivityModuleEnabled == 1) {
                    [[RIConnectivityManager sharedInstance] sendTo:packet friendID:self.currentCallInfoModel.callingFrnId destinationIPaddress:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress destinationPort:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort mediaType:MEDIA_TYPE_AUDIO];
                }
                else
                {
                    [[CallSocketCommunication sharedInstance].udpSocket send:packet toHost:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort];

                }
                
                for (NSString *callId in [[IDCallSignalBuffer sharedInstance].callList allKeys]) // Stop all other keep alives
                {
                    if (![callId isEqualToString:self.currentCallInfoModel.callInfo.callID])
                    {
                        [self stopKeepAliveWithVoiceServerForCallID:callId];
                    }
                }
                
                if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground) {
                    // App is not in background.
                    
                    // Directly sends answer if the call is from remote push message.
                    if ((incomingCallDTO.responseType == CallResponseType_RINGING) && (incomingCallDTO.currentCallFrom == IDCallFromRemotePush)) {
                        
                        [[RingCallAudioManager sharedInstance] StopRingTone];
                        
                        [self.callManagerDelegate didReceiveRemotePushForIncomingCallWithCallInfo:self.currentCallInfoModel];
                        
                    }
                }
                else {
                    // App is in background state.
                    incomingCallDTO.currentCallFrom = IDCallFromLocalPush;
                    self.currentCallInfoModel.callInfo.currentCallFrom = incomingCallDTO.currentCallFrom;
                    
                    //                            [[RingCallAudioManager sharedInstance] StopSilenceTone];
                    //                            [self showLocalNotificationForIncomingCall:currentCallDTO.callingFrnId];
                    [self.callManagerDelegate didReceiveLocalPushForIncomingCallWithCallInfo:self.currentCallInfoModel];
                }
                
            } else {
                NSLog(@"Faild");
            }
        }];
    }
}

- (BOOL) prepareRingCallModuleForNewCallWithFriendId:(NSString *)friendID callID:(NSString *)callID userID:(NSString *)userID 
{
    if ([VoipUtils isOnCDMAorGSMCall] || self.isCallInProgress) {
        return NO;
    }
    
    [[IDCallNotificationHandler sharedInstance] startNotificationHandler];
    
    [CallSocketCommunication sharedInstance];
    self.isCallInProgress = YES;
    self.currentCallInfoModel.callInfo.currentCallType = IDCallTypeOutGoing;
    self.currentCallInfoModel.callInfo.userIdentity = userID;
    self.currentCallInfoModel.packetType = CallResponseType_Auth;
    self.currentCallInfoModel.currentCallState = CallResponseType_Auth;
    self.currentCallInfoModel.callingFrnId = friendID;
    self.currentCallInfoModel.callInfo.callServerInfo.callInitiationTime = 0;
    self.currentCallInfoModel.callInfo.callID = callID;
    
    // Enqueue the call signal.
    RCCallInfoModel *outgingCallDTO = [[RCCallInfoModel alloc] init];
    outgingCallDTO.callID = callID;
    outgingCallDTO.friendIdentity = friendID;
    outgingCallDTO.userIdentity = userID;
    outgingCallDTO.currentCallType = IDCallTypeOutGoing;
    outgingCallDTO.responseType = CallResponseType_Auth;
    outgingCallDTO.callServerInfo.voiceBindingPort = 0;
    [[IDCallSignalBuffer sharedInstance] enqueue:outgingCallDTO forKey:outgingCallDTO.callID];
    [outgingCallDTO release];
    
    return YES;
}



#pragma mark - For handling CDMA/GSM call

- (void) checkGSMorCDMAcallAndTakeProperAction
{
    self.callCenter = [[[CTCallCenter alloc] init] autorelease];
    self.callCenter.callEventHandler = ^(CTCall* call)
    {
        
        NSDictionary *dict = [NSDictionary dictionaryWithObject:call.callState forKey:@"callState"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CTCallStateDidChange" object:self userInfo:dict];
        
        if (call.callState == CTCallStateDisconnected)
        {
#if STATE_DEVELOPMENT
            NSLog(@"GSM Call has been disconnected");
#endif
            sleep(2);
            self.isGsmInterruption = NO;
            
            if (([IDCallManager sharedInstance].self.currentCallInfoModel.currentCallState == CallResponseType_Auth) && ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground)) {
                
                [self callDelegateToStartBackgroundKeepAlive];
            }
            
            if (self.currentCallInfoModel.isCallHoldSignalSent) {
                [self performCallUnhold];
            }
        }
        else if (call.callState == CTCallStateConnected)
        {
#if STATE_DEVELOPMENT
            NSLog(@"GSM Call has just been connected");
#endif
        }
        else if((call.callState == CTCallStateIncoming) || (call.callState == CTCallStateDialing))
        {
#if STATE_DEVELOPMENT
            NSLog(@"GSM Call is incoming or dialing");
#endif
            self.isGsmInterruption = YES;
            
            if (([RingCallAudioManager sharedInstance].isSilenceTonePlaying) && ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground)) {
                //                [[RingCallAudioManager sharedInstance] StopSilenceTone];
            }
            
            if ((self.currentCallInfoModel.currentCallState == CallResponseType_CALLING) ||
                (self.currentCallInfoModel.currentCallState == CallResponseType_RINGING) ||
                (self.currentCallInfoModel.currentCallState == CallResponseType_VOICE_REGISTER) ||
                (self.currentCallInfoModel.currentCallState == CallResponseType_VOICE_REGISTER_CONFIRMATION))
            {
                [self.callManagerDelegate ringCallDidEndWithCallInfo:self.currentCallInfoModel];
            }
            else if ((self.currentCallInfoModel.currentCallState == CallResponseType_CONNECTED))
            {
                [self performCallHold];
            }
        }
        else
        {
            
            if (([IDCallManager sharedInstance].self.currentCallInfoModel.currentCallState == CallResponseType_Auth) && ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground)) {
                
                [self callDelegateToStartBackgroundKeepAlive];
            }
        }
    };
}


// Currently not used.
- (void) gsmCallEnded {
    if (([IDCallManager sharedInstance].self.currentCallInfoModel.currentCallState == CallResponseType_Auth) && ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground)) {
        
        [self callDelegateToStartBackgroundKeepAlive];
    }
}


#pragma mark - For handling Volume Changed Event

- (void)volumeChanged:(NSNotification *)notification{
    NSDictionary*dict=notification.userInfo;
    float newVolume = [[dict objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
    
    [[RingCallAudioManager sharedInstance] setCurrentSystemVolumeLevel:newVolume];
}


#pragma mark - Send Voice Register Push
-(void) sendVoiceregisterPush
{
    if ([IDCallManager sharedInstance].currentCallInfoModel.callInfo.friendDeviceToken && [IDCallManager sharedInstance].currentCallInfoModel.callInfo.friendDeviceToken.length && [IDCallManager sharedInstance].currentCallInfoModel.callInfo.callingFrnDevicePlatformCode != RIPlatformType_Desktop && [IDCallManager sharedInstance].currentCallInfoModel.callInfo.callingFrnDevicePlatformCode != RIPlatformType_Web) {
        [[IDCallManager sharedInstance] sendVoiceRegisterPushNotificationMessageWithUserFullName:[IDCallManager sharedInstance].currentCallInfoModel.callingFriendName callingFrnDeviceToken:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.friendDeviceToken];

    }
}
- (void) sendVoiceRegisterPushNotificationMessageWithUserFullName:(NSString *)userFullName callingFrnDeviceToken:(NSString *)deviceToken
{
    NSData *packet = [IDCallMakePacket makeVoiceRegisterPushRequestPacket:CallResponseType_VOICE_REGISTER_PUSH packetID:self.currentCallInfoModel.packetID userIdentity:self.currentCallInfoModel.callInfo.userIdentity userFullName:userFullName friendIdentity:self.currentCallInfoModel.callingFrnId friendPlatform:self.currentCallInfoModel.callInfo.callingFrnDevicePlatformCode friendOnlineStatus:self.currentCallInfoModel.callInfo.presence friendAppType:self.currentCallInfoModel.callInfo.appTypeOfFriend friendDeviceToken:deviceToken];
    
    if (packet) {
        
        SignalPacket *packetToSent = [[[SignalPacket alloc] initWithIpAddress:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:self.currentCallInfoModel.callInfo.callServerInfo.voiceRegisterport SendingPacket:packet NumberOfRepeat:4 TimeInterval:5 InfiniteTimerEnabled:NO friendId:self.currentCallInfoModel.callInfo.friendIdentity] autorelease];
        
        [[SignalPacketSender sharedInstance] sendPacket:packetToSent forPacketType:RingCallPacketTypeAudio  onSuccess:^(BOOL finished) {
            //Packet Sent successfully
        } onFailure:^(NSError *error) {
            //Packet Sending Failed
        }];
        
#if STATE_DEVELOPMENT
        NSLog(@"********** VOICE_REGISTER_PUSH SENT **********");
#endif
    }
}




- (void) setIncomoingInfoFrom374:(RCAuthResponseInfoModel *)callInfo withCallFrom:(IDCallFrom)callFrom userID:(NSString *)userID freiendID:(NSString *)fndID
{
    NSLog(@"********** setIncomoingInfoFrom374 Called **********");
    [CallSocketCommunication sharedInstance];
    RCCallInfoModel *incomingCallDTO = [[[RCCallInfoModel alloc] init] autorelease];
    
    RCServerInfoModel *infoModel = [[[RCServerInfoModel alloc] init] autorelease];
    infoModel.voicehostIPAddress = callInfo.voicehostIPAddress;
    infoModel.voiceRegisterport = callInfo.voiceRegisterport;
    infoModel.voiceBindingPort = 0;
    
    incomingCallDTO.callID = callInfo.callID;
    incomingCallDTO.friendIdentity = callInfo.friendIdentity;
    incomingCallDTO.userIdentity = userID;
    incomingCallDTO.callServerInfo = infoModel;
    incomingCallDTO.callServerInfo.voiceRegisterport = callInfo.voiceRegisterport;
    incomingCallDTO.currentCallType = IDCallTypeIncomming;
    incomingCallDTO.responseType = CallResponseType_VOICE_REGISTER;
    incomingCallDTO.currentCallFrom = callFrom;
    incomingCallDTO.callServerInfo.voiceBindingPort = 0;
    incomingCallDTO.appTypeOfFriend = callInfo.appTypeOfFriend;
    incomingCallDTO.presence = callInfo.presence;
    incomingCallDTO.friendName = callInfo.friendName;
    incomingCallDTO.friendsAppMode = callInfo.friendsAppMode;
    incomingCallDTO.friendsIDC = callInfo.friendsIDC;
    
    if (incomingCallDTO.currentCallFrom != IDCallFromRemotePush) {
        incomingCallDTO.callServerInfo.callInitiationTime = callInfo.callInitiationTime;
    }
    
    [[IDCallSignalBuffer sharedInstance] enqueue:incomingCallDTO forKey:incomingCallDTO.callID];
    
    
    if (isConnectivityModuleEnabled == 1) {
        BOOL result = [[RISessionHandler sharedInstance] addSessionForFriendID:incomingCallDTO.friendIdentity withMediaType:IDCallMediaType_Voice relayServerIP:incomingCallDTO.callServerInfo.voicehostIPAddress relayServerPort:incomingCallDTO.callServerInfo.voiceRegisterport sessionTimeout:SESSION_TIMEOUT];//[[RIConnectivityManager sharedInstance] createSession:incomingCallDTO.friendIdentity mediaType:MEDIA_NAME relayServerIP:incomingCallDTO.callServerInfo.voicehostIPAddress relayServerPort:incomingCallDTO.callServerInfo.voiceRegisterport];
        if (result == NO) {
            NSLog(@"Faild to create session on IDCallManager");
        } else {
            NSLog(@"Successfully created session on IDCallManager");
        }
    }
    
    
    
    NSData *packet = [IDCallMakePacket makeRegisterPacketForFreeCall:CallResponseType_VOICE_REGISTER userIdentity:incomingCallDTO.userIdentity friendIdentity:incomingCallDTO.friendIdentity withCallID:incomingCallDTO.callID];
    
    if (packet) {
        
        SignalPacket *packetToSent = [[[SignalPacket alloc] initWithIpAddress:incomingCallDTO.callServerInfo.voicehostIPAddress Port:incomingCallDTO.callServerInfo.voiceRegisterport SendingPacket:packet NumberOfRepeat:4 TimeInterval:3 InfiniteTimerEnabled:NO friendId:incomingCallDTO.friendIdentity] autorelease];
        
        [[SignalPacketSender sharedInstance] sendPacket:packetToSent forPacketType:RingCallPacketTypeAudio  onSuccess:^(BOOL finished) {
            //Packet Sent successfully
        } onFailure:^(NSError *error) {
            //Packet Sending Failed
        }];
    }
}


#pragma mark - For handling Error Responses.

- (void) receivedErrorCodeFromAuth {
    [self.callManagerDelegate didReceiveErrorCodeFromAuth];
}

- (void) receivedErrorCodeForUnresponsiveAuth {
    [self.callManagerDelegate didReceiveErrorCodeForUnresponsiveAuth];
}

- (void) receivedErrorCodeForCallState:(CallResponseType)callState withCallID:(NSString *)callID {
    [self.callManagerDelegate didReceiveErrorCodeForCallState:callState withCallID:callID];
}



#pragma mark - Utility Methodes

+ (bool) getCallSignalingPacketInfo: (NSData *) data
{
    bool success = false;
    
    @try {
        int totalRead = 1;
        
        unsigned long long long_friendId = [[IDCallManager sharedInstance] getLong64AtOffset:totalRead fromData:data];
        NSString *str_friendId = [NSString stringWithFormat:@"%llu",long_friendId];
        [IDCallManager sharedInstance].currentCallInfoModel.callInfo.friendIdentity = str_friendId;
        totalRead += 8;
        
        if ([IDCallManager sharedInstance].currentCallInfoModel.packetType != CallResponseType_VOICE_REGISTER_CONFIRMATION && [IDCallManager sharedInstance].currentCallInfoModel.packetType != CallResponseType_VIDEO_BINDING_PORT_CONFIRMATION && [IDCallManager sharedInstance].currentCallInfoModel.packetType != CallResponseType_VOICE_REGISTER_PUSH_CONFIRMATION) {
            totalRead += 8;
        }
        
        int packetIDLength = CFSwapInt32LittleToHost(*(int*)([[data subdataWithRange:NSMakeRange(totalRead, 1)] bytes]));
        totalRead++;
        [IDCallManager sharedInstance].currentCallInfoModel.packetID = [[[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(totalRead,packetIDLength)] encoding:NSUTF8StringEncoding] autorelease];
        totalRead += packetIDLength;
        
        if ([IDCallManager sharedInstance].currentCallInfoModel.packetType == CallResponseType_VOICE_REGISTER_CONFIRMATION) {
            [IDCallManager sharedInstance].voiceBindingPort = [VoipUtils getUniqueKey:data startIndex:totalRead];
        } else if ([IDCallManager sharedInstance].currentCallInfoModel.packetType == CallResponseType_VIDEO_BINDING_PORT_CONFIRMATION) {
            [IDCallManager sharedInstance].videoBindingPort = [VoipUtils getUniqueKey:data startIndex:totalRead];
        }
        
        success = true;
    }
    @catch (NSException *exception) {
        success = false;
    }
    @finally {
        return success;
    }
}


+(BOOL) isInterruptedEndSignal:(NSData*)data
{
    BOOL status = NO;

    int totalRead = 0;
    
    int packetType = CFSwapInt32LittleToHost(*(int*)([[data subdataWithRange:NSMakeRange(totalRead, 1)] bytes]));

    totalRead = 1;
    totalRead += 8;     // for friend ID 8 byte
    totalRead += 8;     // for user ID 8 byte
    int packetIDLength = CFSwapInt32LittleToHost(*(int*)([[data subdataWithRange:NSMakeRange(totalRead, 1)] bytes]));
    totalRead++;
    totalRead += packetIDLength;
    if (data.length>totalRead) {
        int extraByte = CFSwapInt32LittleToHost(*(int*)([[data subdataWithRange:NSMakeRange(totalRead, 1)] bytes]));
        if (extraByte== packetType) {
            status = YES;
        }
    }
    
    return status;
}



- (long long) getLong64AtOffset:(NSInteger)offset fromData:(NSData *)processedData
{
    NSData *data = [processedData subdataWithRange:NSMakeRange(offset, 8)];
    NSUInteger len = [data length];
    Byte *byteData = (Byte*)malloc(len);
    memcpy(byteData, [data bytes], len);
    
    long long l = 0;
    
    l |= byteData[0] & 0xFF;
    l <<= 8;
    l |= byteData[1] & 0xFF;
    l <<= 8;
    l |= byteData[2] & 0xFF;
    l <<= 8;
    l |= byteData[3] & 0xFF;
    l <<= 8;
    l |= byteData[4] & 0xFF;
    l <<= 8;
    l |= byteData[5] & 0xFF;
    l <<= 8;
    l |= byteData[6] & 0xFF;
    l <<= 8;
    l |= byteData[7] & 0xFF;
    
    return l;
}



-(BOOL) checkValidResponse
{
    if (self.currentCallInfoModel.callInfo.callID && [self.currentCallInfoModel.callInfo.callID isEqualToString:self.currentCallInfoModel.packetID] ) {
        self.isValidSignal = YES ;
        
//        if (self.currentCallInfoModel.isSimultaneousCall) {
//            return self.currentCallInfoModel.isSimultaneousCall;
//        } else {
//            return self.isValidSignal;
//        }
#if STATE_DEVELOPMENT
        NSLog(@"Valid Response callID : %@",self.currentCallInfoModel.packetID);
#endif
    } else {
#if STATE_DEVELOPMENT
        NSLog(@"InValid Response callID : %@",self.currentCallInfoModel.packetID);
#endif
        self.isValidSignal = NO ;
    }
   return self.isValidSignal;
//    if (self.currentCallInfoModel.isSimultaneousCall) {
//        return self.currentCallInfoModel.isSimultaneousCall;
//    } else {
//        return self.isValidSignal;
//    }
}


- (void)sendKeepAliveUntilUnhold:(NSTimer *)timer
{
    NSArray *timerInfoArray = [NSArray arrayWithArray:timer.userInfo];
    if (timerInfoArray.count) {
        RCCallInfoModel *incomingCallDTO = (RCCallInfoModel *)[timerInfoArray objectAtIndex:1];
        
        if (isConnectivityModuleEnabled == 1) {
            [[RIConnectivityManager sharedInstance] sendTo:[timerInfoArray objectAtIndex:0] friendID:incomingCallDTO.friendIdentity destinationIPaddress:incomingCallDTO.callServerInfo.voicehostIPAddress destinationPort:incomingCallDTO.callServerInfo.voiceBindingPort mediaType:MEDIA_TYPE_AUDIO];
        } else {
            [[CallSocketCommunication sharedInstance].udpSocket send:[timerInfoArray objectAtIndex:0] toHost:incomingCallDTO.callServerInfo.voicehostIPAddress Port:incomingCallDTO.callServerInfo.voiceBindingPort];
        }
        
    }
    
    
}

- (void) performCallHold {
    if ((self.currentCallInfoModel.currentCallState == CallResponseType_CONNECTED))
    {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (self.isCallInProgress) {
                
                //Start Sending HOLD signal
                self.currentCallInfoModel.currentCallState = CallResponseType_VOICE_CALL_HOLD;
                self.callHoldSendingTime = [NSDate date];
                if([self.callManagerDelegate respondsToSelector:@selector(didSendCallHoldWithInfo:sendingTime:)]) {
                    [self.callManagerDelegate didSendCallHoldWithInfo:self.currentCallInfoModel sendingTime:self.callHoldSendingTime];
                }
                
                
                
                NSData *packet = nil;
                packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_VOICE_CALL_HOLD packetID:self.currentCallInfoModel.callInfo.callID  userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callInfo.friendIdentity];
                
                
                SignalPacket *packetToSent = [[[SignalPacket alloc] initWithIpAddress:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort SendingPacket:packet NumberOfRepeat:5 TimeInterval:3 InfiniteTimerEnabled:NO friendId:self.currentCallInfoModel.callInfo.friendIdentity] autorelease];
                
                [[SignalPacketSender sharedInstance] sendPacket:packetToSent forPacketType:RingCallPacketTypeAudio onSuccess:^(BOOL finished) {
#if STATE_DEVELOPMENT
                    NSLog(@"CallResponseType_VOICE_CALL_HOLD Packet Sent successfully");
#endif
                } onFailure:^(NSError *error) {
#if STATE_DEVELOPMENT
                    NSLog(@"CallResponseType_VOICE_CALL_HOLD Packet Sent faild");
#endif
                }];
                
                self.currentCallInfoModel.isCallHoldSignalSent = TRUE;
                
                //Start sending keep alive in hold state
                NSData *packetkeepalive = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_KEEPALIVE packetID:self.currentCallInfoModel.callInfo.callID userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callInfo.friendIdentity];
                
                SignalPacket *keepalivePacketToSent = [[[SignalPacket alloc] initWithIpAddress:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort SendingPacket:packetkeepalive NumberOfRepeat:0 TimeInterval:5 InfiniteTimerEnabled:YES friendId:self.currentCallInfoModel.callInfo.friendIdentity] autorelease];
                
                [[SignalPacketSender sharedInstance] sendPacket:keepalivePacketToSent forPacketType:RingCallPacketTypeAudio onSuccess:^(BOOL finished) {
                    //Packet Sent successfully
                } onFailure:^(NSError *error) {
                    //Packet Sending Failed
                }];
                
                
                if ([RingCallAudioManager sharedInstance].rtpSenderTimer && [RingCallAudioManager sharedInstance].rtpSenderTimer.isValid) {
                    [[RingCallAudioManager sharedInstance].rtpSenderTimer invalidate];
                    [RingCallAudioManager sharedInstance].rtpSenderTimer = nil;
                    [[RingCallAudioManager sharedInstance] resetRTPQueue];
                }
            }
        }];
    }
}

- (void) performCallUnhold {
    if ((self.currentCallInfoModel.currentCallState == CallResponseType_VOICE_CALL_HOLD) && (self.currentCallInfoModel.isCallHoldSignalSent)) {
        
        //Start Sending UNHOLD signal
        self.currentCallInfoModel.currentCallState = CallResponseType_VOICE_CALL_UNHOLD;
        //        self.currentCallInfoModel.currentCallState = CallResponseType_CONNECTED;
        self.callUnholdSendingTime = [NSDate date];
        if([self.callManagerDelegate respondsToSelector:@selector(didSendCallUnholdWithInfo:sendingTime:)]) {
            [self.callManagerDelegate didSendCallUnholdWithInfo:self.currentCallInfoModel sendingTime:self.callUnholdSendingTime];
        }
        
        
        NSData *packet = nil;
        packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_VOICE_CALL_UNHOLD packetID:self.currentCallInfoModel.callInfo.callID  userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callInfo.friendIdentity];
        
        
        SignalPacket *packetToSent = [[[SignalPacket alloc] initWithIpAddress:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort SendingPacket:packet NumberOfRepeat:5 TimeInterval:3 InfiniteTimerEnabled:NO friendId:self.currentCallInfoModel.callInfo.friendIdentity] autorelease];
        [[SignalPacketSender sharedInstance] sendPacket:packetToSent forPacketType:RingCallPacketTypeAudio  onSuccess:^(BOOL finished) {
#if STATE_DEVELOPMENT
            NSLog(@"CallResponseType_VOICE_CALL_UNHOLD Packet Sent successfully");
#endif
        } onFailure:^(NSError *error) {
#if STATE_DEVELOPMENT
            NSLog(@"CallResponseType_VOICE_CALL_UNHOLD Packet Sending Failed");
#endif
        }];
        
        //Stop Keeplive timer.
        [self stopKeepAliveWithVoiceServerForCallID:self.currentCallInfoModel.callInfo.callID];

        //Start RTP Timer in call screen and stop hold tone.
        if (![RingCallAudioManager sharedInstance].rtpSenderTimer) {
            [[RingCallAudioManager sharedInstance] stopCallHoldTone];
            [[RingCallAudioManager sharedInstance] stop];
            sleep(2);
            [[RingCallAudioManager sharedInstance] start];
            [[RingCallAudioManager sharedInstance] resetRTPQueue];
            [[RingCallAudioManager sharedInstance] startRecordAndPlayAudio];
            //                        [RingCallAudioManager sharedInstance].rtpSenderTimer = [NSTimer scheduledTimerWithTimeInterval:RTP_SENDING_TIME_INTERVAL target:[RingCallAudioManager sharedInstance] selector:@selector(rtpSendingTimerMethod) userInfo:nil repeats:YES];
        }

    }
}


- (void) performCallEnd {
    
    [[RingCallAudioManager sharedInstance] stopRecordAndPlayAudio];
//    RCCallInfoModel *idCallDTO = [[RCCallInfoModel alloc] init];
    RCCallInfoModel *idCallDTO = nil;
    idCallDTO = self.currentCallInfoModel.callInfo;
    
    if([[IDCallSignalBuffer sharedInstance].callList valueForKey:self.currentCallInfoModel.callInfo.callID] != nil) {
        // The key existed...
        idCallDTO = [[[IDCallSignalBuffer sharedInstance].callList objectForKey:self.currentCallInfoModel.callInfo.callID] retain];
    }
    
    
    NSString* callregisterTimerKey =[IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.callInfo.callID andSignalType:CallResponseType_VOICE_REGISTER];
    
    [[SignalPacketSender sharedInstance] stopSendingPacketForKey:callregisterTimerKey onSuccess:^(BOOL finished) {
        //Packet Sending Timmer Stopped Successfully
    } onFailure:^(NSError *error) {
        //Packet Sending Timmer Failed To Stop
    }];
    
    [self stopKeepAliveWithVoiceServerForCallID:self.currentCallInfoModel.callInfo.callID];
    
    NSString* callingTimerKey =[IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.callInfo.callID andSignalType:CallResponseType_CALLING];
    
    [[SignalPacketSender sharedInstance] stopSendingPacketForKey:callingTimerKey onSuccess:^(BOOL finished) {
        //Packet Sending Timmer Stopped Successfully
    } onFailure:^(NSError *error) {
        //Packet Sending Timmer Failed To Stop
    }];
    
    
    if (idCallDTO.userIdentity!= nil && idCallDTO.friendIdentity != nil && idCallDTO.callServerInfo.voicehostIPAddress != nil && idCallDTO.callID != nil)
    {
        
        NSData *packet = nil;
        SignalPacket *packetToSent;
        
        if(self.currentCallInfoModel.callInfo.currentCallType == IDCallTypeOutGoing && self.currentCallInfoModel.currentCallState != CallResponseType_CONNECTED && (self.currentCallInfoModel.currentCallState == CallResponseType_VOICE_REGISTER_CONFIRMATION || self.currentCallInfoModel.currentCallState == CallResponseType_CALLING))
        {
            packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_CANCELED packetID:self.currentCallInfoModel.callInfo.callID userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callingFrnId];
            
            self.currentCallInfoModel.currentCallState = CallResponseType_CANCELED;
            
        }
        else if(self.currentCallInfoModel.packetType == CallResponseType_VOICE_MEDIA || self.currentCallInfoModel.currentCallState == CallResponseType_VOICE_CALL_HOLD || self.currentCallInfoModel.currentCallState == CallResponseType_CONNECTED)
        {
            packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_BYE packetID:self.currentCallInfoModel.callInfo.callID userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callingFrnId];
            self.currentCallInfoModel.currentCallState = CallResponseType_BYE;
            [NSObject cancelPreviousPerformRequestsWithTarget:[IDCallManager sharedInstance] selector:@selector(sendVoiceregisterPush) object:nil];
        }
        else if (self.currentCallInfoModel.packetType != CallResponseType_VOICE_MEDIA && (self.currentCallInfoModel.callInfo.currentCallType == IDCallTypeIncomming))
        {
            packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_BUSY packetID:self.currentCallInfoModel.callInfo.callID userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callingFrnId];
            self.currentCallInfoModel.currentCallState = CallResponseType_BUSY;
        }
        
        if(packet) {
            
            packetToSent = [[[SignalPacket alloc] initWithIpAddress:idCallDTO.callServerInfo.voicehostIPAddress Port:idCallDTO.callServerInfo.voiceBindingPort SendingPacket:packet NumberOfRepeat:3 TimeInterval:3 InfiniteTimerEnabled:NO friendId:idCallDTO.friendIdentity] autorelease];
            
            [[SignalPacketSender sharedInstance] sendPacket:packetToSent forPacketType:RingCallPacketTypeAudio  onSuccess:^(BOOL finished) {
                //Packet Sent successfully
            } onFailure:^(NSError *error) {
                //Packet Sending Failed
            }];
        }
    }
    
    if([[IDCallSignalBuffer sharedInstance].callList valueForKey:self.currentCallInfoModel.callInfo.callID] != nil) {
        // contains  that callID
        [[IDCallSignalBuffer sharedInstance].callList removeObjectForKey:self.currentCallInfoModel.callInfo.callID];
    }
}


- (void) performCallAnswerForCallType:(IDCallType) callType {
    
    if (callType == IDCallTypeIncomming) {
        NSData * packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_ANSWER packetID:self.currentCallInfoModel.callInfo.callID userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callingFrnId];
        
        self.currentCallInfoModel.currentCallState = CallResponseType_ANSWER;
        [[RingCallAudioManager sharedInstance] AudioSwitchToDefaultHardware];
        
        SignalPacket *packetToSent = [[[SignalPacket alloc] initWithIpAddress:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort SendingPacket:packet NumberOfRepeat:5 TimeInterval:3 InfiniteTimerEnabled:NO friendId:self.currentCallInfoModel.callInfo.friendIdentity] autorelease];
        
        [[SignalPacketSender sharedInstance] sendPacket:packetToSent forPacketType:RingCallPacketTypeAudio  onSuccess:^(BOOL finished) {
            //Packet Sent successfully
        } onFailure:^(NSError *error) {
            //Packet Sending Failed
        }];
    }
    
    [[RingCallAudioManager sharedInstance] StopRingTone];
    [[RingCallAudioManager sharedInstance] startRecordAndPlayAudio];
//    self.currentCallInfoModel.currentCallState = CallResponseType_CONNECTED;
    
    [self stopKeepAliveWithVoiceServerForCallID:self.currentCallInfoModel.callInfo.callID];
    
    if (isConnectivityModuleEnabled == 1) {
        [[RIConnectivityManager sharedInstance] startP2PCall:self.currentCallInfoModel.callInfo.friendIdentity mediaType:MEDIA_TYPE_AUDIO isCaller:false];
        [[RISessionHandler sharedInstance] verifySessionForFriendID:self.currentCallInfoModel.callInfo.friendIdentity withMediaType:IDCallMediaType_Voice];

        NSLog(@"startp2pcall has been called 2");
    }
    
}


- (void) performCallEndWithBusyMessage:(NSString *)msg {
    NSLog(@"Message: %@",msg);
    if (self.currentCallInfoModel.callInfo.currentCallType == IDCallTypeIncomming && [RingCallAudioManager sharedInstance].isRIngtonePlaying) {
        [[RingCallAudioManager sharedInstance] StopRingTone];
    }
    
    NSData *packet = nil;
    if ((msg == nil) || ([msg isEqualToString:@""])) {
        packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_BUSY packetID:self.currentCallInfoModel.callInfo.callID userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callingFrnId];
        
        self.currentCallInfoModel.currentCallState = CallResponseType_BUSY;
        
        SignalPacket *packetToSent = [[[SignalPacket alloc] initWithIpAddress:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort SendingPacket:packet NumberOfRepeat:4 TimeInterval:1 InfiniteTimerEnabled:NO friendId:self.currentCallInfoModel.callInfo.friendIdentity] autorelease];
        
        [[SignalPacketSender sharedInstance] sendPacket:packetToSent forPacketType:RingCallPacketTypeAudio  onSuccess:^(BOOL finished) {
            //Packet Sent successfully
        } onFailure:^(NSError *error) {
            //Packet Sending Failed
        }];
    }
    else {
        packet = [IDCallMakePacket makeCallBusyMessagePacket:CallResponseType_VOICE_BUSY_MESSAGE packetID:self.currentCallInfoModel.callInfo.callID userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callingFrnId withMessage:msg];
        
        self.currentCallInfoModel.currentCallState = CallResponseType_BUSY;
        
        SignalPacket *packetToSent = [[[SignalPacket alloc] initWithIpAddress:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort SendingPacket:packet NumberOfRepeat:4 TimeInterval:1 InfiniteTimerEnabled:NO friendId:self.currentCallInfoModel.callInfo.friendIdentity] autorelease];
        
        [[SignalPacketSender sharedInstance] sendPacket:packetToSent forPacketType:RingCallPacketTypeAudio  onSuccess:^(BOOL finished) {
            //Packet Sent successfully
        } onFailure:^(NSError *error) {
            //Packet Sending Failed
        }];
        
        NSLog(@"Message: %@",msg);
    }
}


- (void) performCallRedialingToNumber:(NSString *)phoneNumber userID:(NSString *)userID {
    
    if (self.currentCallInfoModel.callInfo.friendIdentity != nil && self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress != nil) {
        if (self.currentCallInfoModel.callInfo.currentCallType == IDCallTypeOutGoing ) {
            
            self.currentCallInfoModel.currentCallState = CallResponseType_CALLING;
            self.currentCallInfoModel.packetType = CallResponseType_VOICE_REGISTER_CONFIRMATION;
            
            
            NSData *packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_CALLING packetID:self.currentCallInfoModel.callInfo.callID userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callingFrnId];
            
            SignalPacket *packetToSent = [[[SignalPacket alloc] initWithIpAddress:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort SendingPacket:packet NumberOfRepeat:10 TimeInterval:3 InfiniteTimerEnabled:NO friendId:self.currentCallInfoModel.callInfo.friendIdentity] autorelease];
            
            [[SignalPacketSender sharedInstance] sendPacket:packetToSent forPacketType:RingCallPacketTypeAudio  onSuccess:^(BOOL finished) {
                //Packet Sent successfully
            } onFailure:^(NSError *error) {
                //Packet Sending Failed
            }];
            
        }
    }
    /*
     else {
     // Need to check this. But surely we need to do some work here.
     NSString *newCallID = [[IDCallManager sharedInstance] generateNewCallID];
     
     [self initiateVoIPCallWithFriendId:phoneNumber callID:newCallID userID:userID isVideoCall:NO];
     }
     */
}

- (BOOL) prepareRingCallModuleForRedialCall {
    if ([VoipUtils isOnCDMAorGSMCall]) {
        return NO;
    } else {
        self.isCallInProgress = NO;
        return YES;
    }
}


- (void) performCallCancelAutomatically {
    NSData *packet = nil;
    
    NSString* callingTimerKey =[IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.callInfo.callID andSignalType:CallResponseType_CALLING];
    [[SignalPacketSender sharedInstance] stopSendingPacketForKey:callingTimerKey onSuccess:^(BOOL finished) {
        //Packet Sending Timmer Stopped Successfully
    } onFailure:^(NSError *error) {
        //Packet Sending Timmer Failed To Stop
    }];
    
    
    
    if (self.currentCallInfoModel.callInfo.currentCallType == IDCallTypeOutGoing) {
        packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_CANCELED packetID:self.currentCallInfoModel.callInfo.callID userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callingFrnId];
        self.currentCallInfoModel.currentCallState = CallResponseType_CANCELED;
    } else {
        packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_NO_ANSWER packetID:self.currentCallInfoModel.callInfo.callID userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callingFrnId];
        self.currentCallInfoModel.currentCallState = CallResponseType_NO_ANSWER;
    }
    
    if (isConnectivityModuleEnabled == 1) {
        [[RIConnectivityManager sharedInstance] sendTo:packet friendID:self.currentCallInfoModel.callInfo.friendIdentity destinationIPaddress:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress destinationPort:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort mediaType:MEDIA_TYPE_AUDIO];
    } else {
        [[CallSocketCommunication sharedInstance].udpSocket send:packet toHost:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort];
    }
    
}


- (void) performCallDropOnApplicationTermination {
    
    if (self.isCallInProgress) {
        
        NSData *packet = nil;
        if([IDCallManager sharedInstance].currentCallInfoModel.currentCallState == CallResponseType_VOICE_REGISTER_CONFIRMATION || [IDCallManager sharedInstance].currentCallInfoModel.currentCallState == CallResponseType_CALLING || ([IDCallManager sharedInstance].currentCallInfoModel.callInfo.currentCallType == IDCallTypeOutGoing && [IDCallManager sharedInstance].currentCallInfoModel.packetType != CallResponseType_VOICE_MEDIA)) {
            
            packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_CANCELED packetID:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.callID userIdentity:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.userIdentity friendIdentity:[IDCallManager sharedInstance].currentCallInfoModel.callingFrnId];
            
        } else if([IDCallManager sharedInstance].currentCallInfoModel.packetType == CallResponseType_VOICE_MEDIA) {
            packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_BYE packetID:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.callID userIdentity:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.userIdentity friendIdentity:[IDCallManager sharedInstance].currentCallInfoModel.callingFrnId];
            [NSObject cancelPreviousPerformRequestsWithTarget:[IDCallManager sharedInstance] selector:@selector(sendVoiceregisterPush) object:nil];
            
        } else if ([IDCallManager sharedInstance].currentCallInfoModel.packetType != CallResponseType_VOICE_MEDIA && ([IDCallManager sharedInstance].currentCallInfoModel.callInfo.currentCallType == IDCallTypeIncomming)) {
            packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_BUSY packetID:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.callID userIdentity:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.userIdentity friendIdentity:[IDCallManager sharedInstance].currentCallInfoModel.callingFrnId];
            
        }
        
        if(packet) {
            for (int i = 0; i < 3; i++) {
                
                if (isConnectivityModuleEnabled == 1) {
                    [[RIConnectivityManager sharedInstance] sendTo:packet friendID:self.currentCallInfoModel.callInfo.friendIdentity destinationIPaddress:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress destinationPort:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort mediaType:MEDIA_TYPE_AUDIO];
                } else {
                    [[CallSocketCommunication sharedInstance].udpSocket send:packet toHost:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort];

                }
            }
        }
    }
    
}

/*
 -(void) unregisterMessageSend
 {
 if (currentCallDTO.userIdentity != nil) {
 
 NSData *packet = [IDCallMakePacket makeUnRegisterPacketForCall:CallResponseType_VOICE_UNREGISTERED userIdentity:currentCallDTO.userIdentity ];
 
 SignalPacket *packetToSent = [[[SignalPacket alloc] init] autorelease];
 packetToSent.dataToSent = packet;
 packetToSent.ipAddress = currentCallServerDTO.voicehostIPAddress;
 packetToSent.port = currentCallServerDTO.voiceRegisterport;
 packetToSent.repeatCount = 3;
 packetToSent.interval = 4.0f;
 packetToSent.timerIdentifier = [IDCallMakePacket makeKeyStringWithCallID:callID andSignalType:CallResponseType_VOICE_UNREGISTERED];
 
 [[SignalPacketSender sharedInstance] sendPacket:packetToSent onSuccess:^(BOOL finished) {
 NSLog(@"********** Packet Sent successfully **********");
 } onFailure:^(NSError *error) {
 NSLog(@"********** Packet Sending Failed **********");
 }];
 }
 }
 */


- (void) initialiseCallStateForNewCall {
    
    NSString* answerTimerKey = [IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.callInfo.callID andSignalType:CallResponseType_ANSWER];
    [[SignalPacketSender sharedInstance] stopSendingPacketForKey:answerTimerKey onSuccess:^(BOOL finished) {
        //CallResponseType_VOICE_MEDIA Sending Timmer Stopped Successfully
    } onFailure:^(NSError *error) {
        //CallResponseType_VOICE_MEDIA Sending Timmer Failed To Stop
    }];
    
    self.currentCallInfoModel.callInfo.connectivityEventType = RIConnectivityEventType_None;
    [self stopKeepAliveWithVoiceServerForCallID:self.currentCallInfoModel.callInfo.callID];
    
    if (isConnectivityModuleEnabled == 1) {
        //[[RIConnectivityManager sharedInstance] closeSession:self.currentCallInfoModel.callInfo.friendIdentity mediaType:MEDIA_NAME];
        [[RISessionHandler sharedInstance] removeSessionForFriendID:self.currentCallInfoModel.callInfo.friendIdentity withMediaType:IDCallMediaType_Voice];
        
        if (isConnectivityModuleEnabled == 1) {
            [[RISessionHandler sharedInstance] removeSessionForFriendID:self.currentCallInfoModel.callInfo.friendIdentity withMediaType:IDCallMediaType_Video];
        }

    }
    
    NSLog(@"------------- CLoase session from incall for(self.currentCallInfoModel.callInfo.friendIdentity): %@",self.currentCallInfoModel.callInfo.friendIdentity);

    
    [[RingCallAudioManager sharedInstance] AudioInitialiseForNewCall];
    [[IDCallNotificationHandler sharedInstance] stopNotificationHandler];
    self.currentCallInfoModel.callInfo.currentCallType = IDCallTypeUndefine; // reset current call type
    self.currentCallInfoModel.currentCallState = CallResponseType_Auth;
    self.currentCallInfoModel.packetType = CallResponseType_Auth;
    self.currentCallInfoModel.callOperationType = Call_Operation_Type__General;
    self.currentCallInfoModel.isCallHoldSignalSent = NO;
    self.currentCallInfoModel.isValidCall = NO;
    self.currentCallInfoModel.isSimultaneousCall = NO;
    self.isCallInProgress = NO;
    self.callHoldSendingTime = nil;
    self.callUnholdSendingTime = nil;
    
    [self notifyRingCallAudioEndedDelegate];
    
//    self.currentCallInfoModel.networkType = IDCallMediaType_None;
    self.currentCallInfoModel.packetID = @"";
    self.currentCallInfoModel.networkStrength = NetworkStrength_Average;
    //    self.currentCallInfoModel.callingFrnId = @"";
    self.currentCallInfoModel.callInfo.callingFrnDevicePlatformCode = 0;
    //    self.currentCallInfoModel.callInfo.callID = @"";
    self.currentCallInfoModel.callInfo.friendIdentity = @"";
    self.currentCallInfoModel.callInfo.userIdentity = @"";
    self.currentCallInfoModel.callInfo.responseType = CallResponseType_Auth;
    self.currentCallInfoModel.callInfo.currentCallType = IDCallTypeUndefine;
    self.currentCallInfoModel.callInfo.currentCallFrom = IDCallFromGeneral;
    self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress = nil;
    self.currentCallInfoModel.callInfo.appTypeOfFriend = 0;
    self.currentCallInfoModel.callInfo.presence = 0;
    self.currentCallInfoModel.callInfo.callServerInfo.voiceRegisterport = 0;
    self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort = 0;
    self.currentCallInfoModel.callInfo.callServerInfo.callInitiationTime = 0;
    
    is174Received = false;
    is374Received = false;
}

- (void) notifyRingCallAudioEndedDelegate {
    if([self.callManagerAudioDelegate respondsToSelector:@selector(ringCallAudioEnded)]) {
        [self.callManagerAudioDelegate ringCallAudioEnded];
    }
}

- (void) notifyRingToneStartedDelegate {
    if([self.callManagerAudioDelegate respondsToSelector:@selector(ringToneStarted)]) {
        [self.callManagerAudioDelegate ringToneStarted];
    }
}

- (void) notifyRingToneEndedDelegate {
    if([self.callManagerAudioDelegate respondsToSelector:@selector(ringToneEnded)]) {
        [self.callManagerAudioDelegate ringToneEnded];
    }
}


- (void) setSpeakerEnable:(BOOL)enable {
    if (enable) {
        [[RingCallAudioManager sharedInstance] AudioForceOutputToBuiltInSpeakers];
    } else {
        [[RingCallAudioManager sharedInstance] AudioSwitchToDefaultHardware];
    }
}

- (void) setMuteEnable:(BOOL)enable {
    if (enable) {
        [[RingCallAudioManager sharedInstance] AudioMute];
    } else {
        [[RingCallAudioManager sharedInstance] AudioUnMute];
    }
}


//- (NSAttributedString *) getNetworkStatus {
//    return [[RingCallAudioManager sharedInstance] getSignalStatusStringByReceivedRtpRate];
//}

- (void) callDelegateToStartBackgroundKeepAlive {
    
    // Call delegate
    if([self.callManagerDelegate respondsToSelector:@selector(startBackgroundKeepAlive)]){
        [self.callManagerDelegate startBackgroundKeepAlive];
    }
    
}

- (void) updateNetworkType:(NSDictionary *) networkDict {
    NSLog(@"Network Array: %@",networkDict);
    NSLog(@"Network Dictionary: %@",networkDict);
    NSLog(@"Current BSSID: %@",self.currentBSSID);
    NSLog(@"New BSSID: %@",[networkDict valueForKey:@"BSSID"]);
    
    if (!networkDict && self.currentBSSID) {
        NSLog(@"BSSID Changed from Wifi to Celluler");
        self.currentBSSID = nil;
                    [[RIConnectivityManager sharedInstance] performSelectorInBackground:@selector(InterfaceChanged) withObject:nil];

        [self detectCellulerNetworkConnectionType];
    }
    else if (!networkDict && !self.currentBSSID) {
        NSLog(@"BSSID Changed from celluler to celluler");
                    [[RIConnectivityManager sharedInstance] performSelectorInBackground:@selector(InterfaceChanged) withObject:nil];
        
        [self detectCellulerNetworkConnectionType];
    }
    else if (networkDict && !self.currentBSSID) {
        NSLog(@"BSSID Changed from celluler to wifi");
        self.currentBSSID = [networkDict valueForKey:@"BSSID"];
                    [[RIConnectivityManager sharedInstance] performSelectorInBackground:@selector(InterfaceChanged) withObject:nil];
        
        self.currentCallInfoModel.networkType = IDCallMediaType_WiFi;
    }
    else if (networkDict && self.currentBSSID && ![self.currentBSSID isEqualToString:[networkDict valueForKey:@"BSSID"]]) {
        NSLog(@"BSSID Changed from wifi to wifi");
        self.currentBSSID = [networkDict valueForKey:@"BSSID"];
                    [[RIConnectivityManager sharedInstance] performSelectorInBackground:@selector(InterfaceChanged) withObject:nil];
        
        self.currentCallInfoModel.networkType = IDCallMediaType_WiFi;
    }
    
    

    NSLog(@"self.currentCallInfoModel.networkType: %lu", (unsigned long)self.currentCallInfoModel.networkType);
}


- (BOOL)isNetworkConnectionFast {
    CTTelephonyNetworkInfo *telephonyInfo = [CTTelephonyNetworkInfo new];
    NSString *radioAccessTechnology = telephonyInfo.currentRadioAccessTechnology;
    
    if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyGPRS]) {
        return NO;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyEdge]) {
        return NO;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyWCDMA]) {
        return YES;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyHSDPA]) {
        return YES;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyHSUPA]) {
        return YES;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMA1x]) {
        return NO;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0]) {
        return YES;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA]) {
        return YES;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB]) {
        return YES;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyeHRPD]) {
        return YES;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyLTE]) {
        return YES;
    }
    
    return YES;
}


- (void) detectCellulerNetworkConnectionType {
    CTTelephonyNetworkInfo *telephonyInfo = [CTTelephonyNetworkInfo new];
    NSString *radioAccessTechnology = telephonyInfo.currentRadioAccessTechnology;
    
    if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyGPRS]) {
        self.currentCallInfoModel.networkType = IDCallMediaType_2G;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyEdge]) {
        self.currentCallInfoModel.networkType = IDCallMediaType_2G;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyWCDMA]) {
        self.currentCallInfoModel.networkType = IDCallMediaType_3G;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyHSDPA]) {
        self.currentCallInfoModel.networkType = IDCallMediaType_3G;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyHSUPA]) {
        self.currentCallInfoModel.networkType = IDCallMediaType_3G;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMA1x]) {
        self.currentCallInfoModel.networkType = IDCallMediaType_2G;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0]) {
        self.currentCallInfoModel.networkType = IDCallMediaType_3G;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA]) {
        self.currentCallInfoModel.networkType = IDCallMediaType_3G;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB]) {
        self.currentCallInfoModel.networkType = IDCallMediaType_3G;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyeHRPD]) {
        self.currentCallInfoModel.networkType = IDCallMediaType_3G;
    } else if ([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyLTE]) {
        self.currentCallInfoModel.networkType = IDCallMediaType_LTE;
    }
}



- (void) startKeepAliveWithVoiceServer {
    NSLog(@"startKeepAliveWithVoiceServer");
    
    //Start sending keep alive in hold state
    NSData *packetkeepalive = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_KEEPALIVE packetID:self.currentCallInfoModel.callInfo.callID userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callInfo.friendIdentity];
    
    SignalPacket *keepalivePacketToSent = [[[SignalPacket alloc] initWithIpAddress:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort SendingPacket:packetkeepalive NumberOfRepeat:0 TimeInterval:5 InfiniteTimerEnabled:YES friendId:self.currentCallInfoModel.callInfo.friendIdentity] autorelease];
    
    [[SignalPacketSender sharedInstance] sendPacket:keepalivePacketToSent forPacketType:RingCallPacketTypeAudio onSuccess:^(BOOL finished) {
        NSLog(@"CallResponseType_KEEPALIVE sent to ID: %@ Port: %d FriendID: %@", self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress, self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort, self.currentCallInfoModel.callInfo.friendIdentity);
    } onFailure:^(NSError *error) {
        NSLog(@"CallResponseType_KEEPALIVE sending faild.");
    }];

}

- (void) stopKeepAliveWithVoiceServerForCallID:(NSString *)callID {
    NSLog(@"stopKeepAliveWithVoiceServer");
    
    if (isConnectivityModuleEnabled == 1 && self.currentCallInfoModel.callInfo.connectivityEventType == RIConnectivityEventType_P2P_COMMUNICATION_ESTABLISHED && self.currentCallInfoModel.currentCallState == CallResponseType_CONNECTED) {
        NSLog(@"Will return from stopKeepAliveWithVoiceServer");
        return;
    }
    
    NSString* keepAliveTimerKey =[IDCallMakePacket makeKeyStringWithCallID:callID andSignalType:CallResponseType_KEEPALIVE];
    
    [[SignalPacketSender sharedInstance] stopSendingPacketForKey:keepAliveTimerKey onSuccess:^(BOOL finished) {
        NSLog(@"CallResponseType_KEEPALIVE sending STOPPED succesfully.");
    } onFailure:^(NSError *error) {
        NSLog(@"CallResponseType_KEEPALIVE sending faild to STOP.");
    }];
}



#pragma  mark - Video Call Signal

-(void) sendVideoCallStartRequestAtVoiceBindPort
{
    NSData *packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_VIDEO_CALL_START packetID:self.currentCallInfoModel.callInfo.callID userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callingFrnId];

     SignalPacket *packetToSent = [[[SignalPacket alloc] initWithIpAddress:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort SendingPacket:packet NumberOfRepeat:5 TimeInterval:3 InfiniteTimerEnabled:NO friendId:self.currentCallInfoModel.callInfo.friendIdentity] autorelease];
    
    [[SignalPacketSender sharedInstance] sendPacket:packetToSent forPacketType:RingCallPacketTypeAudio  onSuccess:^(BOOL finished) {
        //Packet Sent successfully
    } onFailure:^(NSError *error) {
        //Packet Sending Failed
    }];
    
    if (isConnectivityModuleEnabled == 1) {
        BOOL result = [[RISessionHandler sharedInstance] addSessionForFriendID:[IDCallManager sharedInstance].currentCallInfoModel.callingFrnId withMediaType:IDCallMediaType_Video relayServerIP:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress relayServerPort:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort sessionTimeout:SESSION_TIMEOUT];//createSession:outgoingCallDTO.friendIdentity mediaType:MEDIA_NAME relayServerIP:outgoingCallDTO.callServerInfo.voicehostIPAddress relayServerPort:outgoingCallDTO.callServerInfo.voiceRegisterport];
        if (result == NO) {
            NSLog(@"Faild to create video session on IDCallManager");
        } else {
            NSLog(@"Successfully created video session on IDCallManager");
        }
    }
    
    [self sendVideoBindPortRequestAtRegisterPort];
}

-(void) sendVideoBindPortRequestAtRegisterPort
{
    
    NSData *packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_VIDEO_BINDING_PORT packetID:self.currentCallInfoModel.callInfo.callID userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callingFrnId];
    // self.currentCallInfoModel.currentCallState = CallResponseType_BUSY;
    
    SignalPacket *packetToSent = [[[SignalPacket alloc] initWithIpAddress:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:self.currentCallInfoModel.callInfo.callServerInfo.voiceRegisterport SendingPacket:packet NumberOfRepeat:4 TimeInterval:3 InfiniteTimerEnabled:NO friendId:self.currentCallInfoModel.callInfo.friendIdentity] autorelease];
    NSLog(@"IP:%@ port:%d",self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress,self.currentCallInfoModel.callInfo.callServerInfo.voiceRegisterport);
    
    [[SignalPacketSender sharedInstance] sendPacket:packetToSent forPacketType:RingCallPacketTypeAudio onSuccess:^(BOOL finished) {
        //Packet Sent successfully
    } onFailure:^(NSError *error) {
        //Packet Sending Failed
    }];

    
}

-(void) sendVideoCallEndRequestAtVideoBindPort
{
    NSData *packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_VIDEO_CALL_END packetID:self.currentCallInfoModel.callInfo.callID userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callingFrnId];
    //self.currentCallInfoModel.currentCallState = CallResponseType_BUSY;
    
    
    SignalPacket *packetToSent = [[[SignalPacket alloc] initWithIpAddress:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:self.currentCallInfoModel.callInfo.callServerInfo.videoBindingPort SendingPacket:packet NumberOfRepeat:4 TimeInterval:3 InfiniteTimerEnabled:NO friendId:self.currentCallInfoModel.callInfo.friendIdentity] autorelease];
    
    NSLog(@"Bind Port: AudiO:%d Video:%d",self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort,self.currentCallInfoModel.callInfo.callServerInfo.videoBindingPort);
    
    
    [[SignalPacketSender sharedInstance] sendPacket:packetToSent forPacketType:RingCallPacketTypeVideo onSuccess:^(BOOL finished) {
        //Packet Sent successfully
    } onFailure:^(NSError *error) {
        //Packet Sending Failed
    }];
}


-(void) sendVideoCallInterruptedEndSignal
{
    NSData *packet = [IDCallMakePacket makeVideoCallSignalingPacket:CallResponseType_VIDEO_CALL_END packetID:self.currentCallInfoModel.callInfo.callID userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callingFrnId withExtraByte:YES];
    //self.currentCallInfoModel.currentCallState = CallResponseType_BUSY;
    
    
    SignalPacket *packetToSent = [[[SignalPacket alloc] initWithIpAddress:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:self.currentCallInfoModel.callInfo.callServerInfo.videoBindingPort SendingPacket:packet NumberOfRepeat:4 TimeInterval:3 InfiniteTimerEnabled:NO friendId:self.currentCallInfoModel.callInfo.friendIdentity] autorelease];
    
    NSLog(@"Bind Port: AudiO:%d Video:%d",self.currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort,self.currentCallInfoModel.callInfo.callServerInfo.videoBindingPort);
    
    [[SignalPacketSender sharedInstance] sendPacket:packetToSent forPacketType:RingCallPacketTypeVideo onSuccess:^(BOOL finished) {
        //Packet Sent successfully
    } onFailure:^(NSError *error) {
        //Packet Sending Failed
    }];
}



-(void) sendVideoKeepAliveRequestAtVideoBindPortEnableInfiniteRepeat:(BOOL)shouldRepeat
{
    NSData *packet = [IDCallMakePacket makeCallSignalingRingingPacket:CallResponseType_VIDEO_KEEPALIVE packetID:self.currentCallInfoModel.callInfo.callID userIdentity:self.currentCallInfoModel.callInfo.userIdentity friendIdentity:self.currentCallInfoModel.callingFrnId];
   
    //self.currentCallInfoModel.currentCallState = CallResponseType_BUSY;
    
    
    SignalPacket *packetToSent = [[[SignalPacket alloc] initWithIpAddress:self.currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress Port:self.currentCallInfoModel.callInfo.callServerInfo.videoBindingPort SendingPacket:packet NumberOfRepeat:(shouldRepeat ? 0 : 4) TimeInterval:(shouldRepeat ? 15 : 1) InfiniteTimerEnabled:shouldRepeat friendId:self.currentCallInfoModel.callingFrnId] autorelease];

    [[SignalPacketSender sharedInstance] sendPacket:packetToSent forPacketType:RingCallPacketTypeVideo  onSuccess:^(BOOL finished) {
        //Packet Sent successfully
    } onFailure:^(NSError *error) {
        //Packet Sending Failed
    }];
}

-(void) stopSendVideoKeepAlive
{
    NSString* videoBindPortTimerKey =[IDCallMakePacket makeKeyStringWithCallID:self.currentCallInfoModel.callInfo.callID andSignalType:CallResponseType_VIDEO_KEEPALIVE];
    
    [[SignalPacketSender sharedInstance] stopSendingPacketForKey:videoBindPortTimerKey onSuccess:^(BOOL finished) {
        //Packet Sending Timmer Stopped Successfully
    } onFailure:^(NSError *error) {
        //Packet Sending Timmer Failed To Stop
    }];
}


-(void) stopVideoCallProcess
{
//    if (isConnectivityModuleEnabled == 1) {
//        [[RISessionHandler sharedInstance] removeSessionForFriendID:self.currentCallInfoModel.callInfo.friendIdentity withMediaType:IDCallMediaType_Video];
//    }
    
    [[RIVideoMediaSocket sharedInstance] closeVideoSocket];
}
#pragma mark P2P

- (void)p2pStatusChanged:(int)status forMediaType:(int)mediaType
{
    if ([self.callManagerDelegate respondsToSelector:@selector(p2pStatusChanged:forMediaType:)]) {
        [self.callManagerDelegate p2pStatusChanged:status forMediaType:mediaType];
    }
}



@end
