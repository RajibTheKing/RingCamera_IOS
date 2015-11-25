//
//  AudioRouter.h
//  Ring Audio Handler
//
//  Created by Partho Biswas on 10/13/14.
//  Copyright (c) 2014 IPVision Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface AudioRouter : NSObject <CBCentralManagerDelegate> {
    
}


// this class is a singleton class.
+ (AudioRouter *) getiOS_AudioRouterInstance;

+ (void) initAudioSessionRouting;
+ (void) switchToDefaultHardware;
+ (void) forceOutputToBuiltInSpeakers;

+ (BOOL) muteAudio:(AudioUnit) audioUnit;
+ (BOOL) unMuteAudio:(AudioUnit) audioUnit;

+ (void) startBTAudio;
+ (void) stopBTAudio;

+ (NSString*) getAudioSessionInput;
+ (NSString*) getAudioSessionOutput;
+ (NSString*) getAudioSessionRoute ;

@end
