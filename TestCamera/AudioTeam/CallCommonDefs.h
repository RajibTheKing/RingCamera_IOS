//
//  CallCommonDefs.h
//  ringID
//
//  Created by Partho Biswas on 3/5/15.
//  Copyright (c) 2015 IPVision Canada Inc. All rights reserved.
//

#ifndef ringID_CallCommonDefs_h
#define ringID_CallCommonDefs_h

typedef NS_ENUM(NSUInteger, Call_Operation_Type) {
    Call_Operation_Type__General = 0,
    Call_Operation_Type__SendBusyAfterReg
};

typedef NS_ENUM(NSUInteger, CallResponseType) {
    CallResponseType_VOICE_MEDIA = 0,                   //0
    CallResponseType_VOICE_REGISTER,                    //1
    CallResponseType_VOICE_UNREGISTERED,                //2
    CallResponseType_VOICE_REGISTER_CONFIRMATION,       //3
    CallResponseType_KEEPALIVE,                         //4
    CallResponseType_CALLING,                           //5
    CallResponseType_RINGING,                           //6
    CallResponseType_IN_CALL,                           //7
    CallResponseType_ANSWER,                            //8
    CallResponseType_BUSY,                              //9
    CallResponseType_CANCELED,                          //10
    CallResponseType_CONNECTED,                         //11
    CallResponseType_DISCONNECTED,                      //12
    CallResponseType_BYE,                               //13
    CallResponseType_Auth,                              //14
    CallResponseType_NO_ANSWER,                         //15
    CallResponseType_USER_AVAILABLE,                    //16
    CallResponseType_USER_NOT_AVAILABLE,                //17
    CallResponseType_IN_CALL_CONFIRMATION,              //18
    CallResponseType_Testing,                           //19
    CallResponseType_VOICE_REGISTER_PUSH,               //20
    CallResponseType_VOICE_REGISTER_PUSH_CONFIRMATION,  //21
    CallResponseType_VOICE_CALL_HOLD,                   //22
    CallResponseType_VOICE_CALL_HOLD_CONFIRMATION,      //23
    CallResponseType_VOICE_CALL_UNHOLD,                 //24
    CallResponseType_VOICE_UNHOLD_CONFIRMATION,         //25
    CallResponseType_VOICE_BUSY_MESSAGE,                //26
    CallResponseType_VOICE_BUSY_MESSAGE_CONFIRMATION,   //27
    
    CallResponseType_VideoMedia = 39,                   //39
    CallResponseType_VIDEO_BINDING_PORT,                //40
    CallResponseType_VIDEO_BINDING_PORT_CONFIRMATION,   //41
    CallResponseType_VIDEO_CALL_START,                  //42
    CallResponseType_VIDEO_CALL_START_CONFIRMATION,     //43
    CallResponseType_VIDEO_KEEPALIVE,                   //44
    CallResponseType_VIDEO_CALL_END,                    //45
    CallResponseType_VIDEO_CALL_END_CONFIRMATION,       //46
    CallResponseType_VIDEO_CALL_BOTH_END               //47 use this signal for interuption handle and when got dismiss video view 

};

typedef NS_ENUM(NSUInteger, RIPlatformType) {
    RIPlatformType_None = 0,
    RIPlatformType_Desktop,
    RIPlatformType_Android,
    RIPlatformType_iOS,
    RIPlatformType_WindowsPhone,
    RIPlatformType_Web
};

typedef NS_ENUM(NSUInteger, IDCallType) {
    IDCallTypeUndefine = 0,
    IDCallTypeOutGoing,
    IDCallTypeIncomming
};

typedef NS_ENUM(NSUInteger, IDVideoCallActive) {
    IDVideoCallActiveNone = 0,
    IDVideoCallActiveForOutgoing,
    IDVideoCallActiveForIncomming,
    IDVideoCallActiveForBothEnd
};

typedef NS_ENUM(NSUInteger, IDCallFrom) {
    IDCallFromGeneral = 0,
    IDCallFromRemotePush,
    IDCallFromLocalPush
};

typedef NS_ENUM(NSUInteger, MSGType) {
    MSGTypeBUSYMSG1 = 0,
    MSGTypeBUSYMSG2,
    MSGTypeBUSYMSG3,
    MSGTypeBUSYMSG4,
    MSGTypeBUSYMSG5,
    MSGTypeBUSYMSG6,
    MSGTypeBUSYMSG7
};

typedef NS_ENUM(NSUInteger, IDVoIPCallType) {
    IDVoIPCallTypeRingID = 0,
    IDVoIPCallTypeTermination
};

typedef NS_ENUM(NSUInteger, NetworkStrength) {
    NetworkStrength_Average = 0,
    NetworkStrength_Excellent,
    NetworkStrength_Good,
    NetworkStrength_Poor,
    NetworkStrength_NotReachable
};

typedef NS_ENUM(NSUInteger, SystemSound) {
    SystemSound_None = 0,
    SystemSound_Busy,
    SystemSound_Error
};

typedef NS_ENUM(NSUInteger, CallModuleTone) {
    CallModuleTone_None = 0,
    CallModuleTone_Busy,
    CallModuleTone_Error,
    CallModuleTone_Waiting
};


typedef NS_ENUM(NSUInteger, IDCallMediaType) {
    IDCallMediaType_Unknown = 0,
    IDCallMediaType_Voice,
    IDCallMediaType_Video,
    IDCallMediaType_Chat,
    IDCallMediaType_FileTransfer
};


typedef NS_ENUM(NSUInteger, IDNetworkType) {
    IDCallMediaType_None = 1,
    IDCallMediaType_2G,
    IDCallMediaType_3G,
    IDCallMediaType_LTE,
    IDCallMediaType_WiFi
};



#endif
