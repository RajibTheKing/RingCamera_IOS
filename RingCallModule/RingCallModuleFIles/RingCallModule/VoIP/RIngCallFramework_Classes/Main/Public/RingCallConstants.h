//
//  RingCallConstants.h
//  CallFrameworkApp
//
//  Created by Partho Biswas on 3/18/15.
//  Copyright (c) 2015 Ring Inc. All rights reserved.
//

#ifndef CallFrameworkApp_RingCallConstants_h
#define CallFrameworkApp_RingCallConstants_h

#define RESOURCE_BUNDLE_NAME  @"RingCallModuleResource"
#define RESOURCE_BUNDLE_EXTENSION  @"bundle"
#define RESOURCE_BUNDLE [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:RESOURCE_BUNDLE_NAME withExtension:RESOURCE_BUNDLE_EXTENSION]]

#define KEEP_ALIVE_SILENCE_TONE_FILE_NAME  @"SilenceTone_7Sec"
#define KEEP_ALIVE_SILENCE_TONE_FILE_TYPE  @"aiff"

#define CALL_HOLD_TONE_FILE_NAME  @"CallHoldTone"
#define CALL_HOLD_TONE_FILE_TYPE  @"pcm"

#define RING_TONE_RAW_FILE_NAME  @"RingToneRawData"
#define RING_TONE_RAW_FILE_TYPE  @"pcm"

#define RING_TONE_FILE_NAME  @"ringing"
#define RING_TONE_FILE_TYPE  @"caf"

#define SILENCE_TONE_FILE_NAME  @"silence-10sec"
#define SILENCE_TONE_FILE_TYPE  @"mp3"

#define isRingTonePlayingUsingAudioUnit  1 // 1 means yes, 0 means no(if no, that means ring tone is playing using AVFoundation)

#define isConnectivityModuleEnabled  1 // 1 means yes, 0 means no(if no, that means the app is using it's own socket)

#define MEDIA_TYPE_AUDIO 1
#define MEDIA_TYPE_VIDEO  2

#define CALL_MAX_PACKET_SIZE                                 2048
#define SESSION_TIMEOUT                                 90

#endif
