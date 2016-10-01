//
//  RingCallAudioManager.h
//  Ring Audio Handler
//
//  Created by Partho Biswas on 10/13/14.
//  Copyright (c) 2014 IPVision Ltd. All rights reserved.
//

@protocol AudioControllerDelegate;

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <MediaPlayer/MediaPlayer.h>
#include "CallCommonDefs.h"

#include <stdio.h>
#include <string.h>

#import <AVFoundation/AVFoundation.h>
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>
#import <sys/sysctl.h>

#include "Common.h"

#ifndef max
#define max( a, b ) ( ((a) > (b)) ? (a) : (b) )
#endif

#ifndef min
#define min( a, b ) ( ((a) < (b)) ? (a) : (b) )
#endif


@interface RingCallAudioManager : NSObject <AVAudioPlayerDelegate>

@property(nonatomic, readwrite) bool isAudioUnitRunning;
@property(nonatomic, readwrite) bool isLocalRingBackToneEnabled;
@property(nonatomic, readwrite) bool isCallHoldToneEnabled;
@property(nonatomic, readonly) bool isMuted;
@property(nonatomic, readonly) bool isSpeakerEnabled;
@property(nonatomic, readonly) bool isVibrating;
@property(nonatomic, readonly) bool isRIngtonePlaying;
@property(nonatomic, readonly) bool isSilenceTonePlaying;
@property(nonatomic, readonly) bool isAudioRecordingForIM;
@property(nonatomic, readwrite) float currentSystemVolumeLevel;
@property(nonatomic, readwrite) float receivedRtpCount;
@property(nonatomic, readonly) float signalStatusPercentageByReceivedRtpRate;

//Timer for send RTP
@property (retain, nonatomic) NSTimer *rtpSenderTimer;


+ (RingCallAudioManager *) sharedInstance;
- (void) start;
- (void) stop;
- (void) startRecordAndPlayAudio ;
- (void) stopRecordAndPlayAudio;
- (void) rtpSendingTimerMethod;
- (void) processReceivedRTPPacket:(NSData *)receivedRTP;
- (void) processAudio: (AudioBufferList*) bufferList;
- (void) receiverAudio:(Byte *) audio WithLen:(int)len;

//- (void) recordDataPullingMethod;
- (BOOL) iOSVersion6ToUpper;

- (void) resetRTPQueue;

// For ring back tone
- (void) playRingBackTone;
- (void) stopRingBackTone;

// For ringtone
- (void) PlayRingTone;
- (void) PlayRingToneWithVibration:(BOOL)isVibrationEnabled;
- (void) StopRingTone;
- (void) updateRingToneVolumeLevel:(float)volumeLevel withSilence:(BOOL)isSilenced andVibration:(BOOL)vibratChoice;
- (void) PlayRingToneViaPCM;
- (void) StopRingToneViaPCM;

// For silence tone
- (void) PlaySilenceTone;
- (void) StopSilenceTone;

// For Keep Alive silence tone
//- (void) StartKeepAliveSilenceTone;
//- (void) StopKeepAliveSilenceTone;

// For call hold tone
- (void) playCallHoldTone;
- (void) stopCallHoldTone;

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

- (void) AudioMute;
- (void) AudioUnMute;

- (void) AudioStartBTAudio;
- (void) AudioStopBTAudio;

- (void) closeG729Codec;

- (void) AudioInitialiseForNewCall;


// Audio Utils
- (float) getVolumeLevel;
//- (BOOL) isCallRingerMuted;
- (Byte *) short2byte:(short *)shorts size:(int)size resultSize:(int)resultSize;
- (short *) byte2short:(Byte *)bytes size:(int)size resultSize:(int)resultSize;
- (void) listAllLocalFiles;
- (void) createFileWithName:(NSString *)fileName;
- (void) deleteFileWithName:(NSString *)fileName;
- (void) renameFileWithName:(NSString *)srcName toName:(NSString *)dstName;
- (void) readFileWithName:(NSString *)fileName;
- (void) writeString:(NSString *)content toFile:(NSString *)fileName;
- (AudioBufferList *) getBufferListFromData: (NSData *) data;
- (NSData *) getDataFromBufferList:(AudioBufferList *)bufferList;

- (NSAttributedString *) calculateSignalStrengthByReceivedRtpRateForTimeInterval;
//- (NSAttributedString *) getSignalStatusStringByReceivedRtpRate;
//- (NSAttributedString *) getInstantSignalStatusStringByReceivedRtpRate;

- (void) playSystemSound:(SystemSound)systemSound;
- (void) playCallModuleTone:(CallModuleTone) callModuleTone;

- (void) playMyReceivedAudioData:(short *)data withLength:(int)iLen;

- (void) createAndGetPCMfromotherFormat;
- (void) setAudioOutputSpeaker:(BOOL)enabled;

void WriteToFileV(byte *pData, int iLen);




@end


