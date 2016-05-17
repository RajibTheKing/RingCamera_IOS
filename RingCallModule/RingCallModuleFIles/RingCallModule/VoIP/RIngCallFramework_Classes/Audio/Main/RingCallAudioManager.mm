//
//  IosAudioController.m
//  Ring Audio Handler
//
//  Created by Partho Biswas on 10/13/14.
//  Copyright (c) 2014 IPVision Ltd. All rights reserved.
//

#import "RingCallAudioManager.h"
#import <AudioToolbox/AudioToolbox.h>
#import "SharkfoodMuteSwitchDetector.h"

#import "BufferQueue.h"
//#import "G729Wrapper.h"
#import "TPCircularBuffer.h"
#import "AudioRouter.h"
#import "CallSocketCommunication.h"
#import "VoipConstants.h"
#import "RingCallConstants.h"
#import "IDCallManager.h"
#import "VoipUtils.h"
#import "RIConnectivityManager.h"

#include "VideoSockets.h"
#include "VideoCallProcessor.h"
#include "VideoAPI.hpp"


#define IS_IPHONE ([[[UIDevice currentDevice] model] isEqualToString:@"iPhone"])
#define IS_IPOD ([[[UIDevice currentDevice] model] isEqualToString:@"iPod touch"])
#define IS_IPAD ([[[UIDevice currentDevice] model] isEqualToString:@"iPad"])

#define kOutputBus 0
#define kInputBus 1

VideoSockets *pVideoSocket;
VideoCallProcessor *pVideoCallProcessor;

AVAudioSession* audioSession;

static RingCallAudioManager *sharedInstance = nil;

//G729Wrapper* g729EncoderDecoder;
byte bAudioEncodeBuffer[10000];
byte bAudioBuffer[10000];
short shortArray[10000];

void checkStatus(int status){
    if (status) {
        printf("Status not 0! %d\n", status);
    }
}


@interface RingCallAudioManager () {
    AudioComponentInstance audioUnit;
    AudioBuffer tempBuffer; // this will hold the latest data from the microphone
    TPCircularBuffer recordedPCMBuffer;
    TPCircularBuffer receivedPCMBuffer;
    
    TPCircularBuffer ringBackTonePCMBuffer;
    Byte *g711RingBackToneBuffer;
    unsigned long g711RingBackToneDataLength;
    
    TPCircularBuffer callHoldTonePCMBuffer;
    Byte *G711callHoldToneBuffer;
    unsigned long G711callHoldToneDataLength;
    
    TPCircularBuffer ringTonePCMBuffer;
    Byte *G711ringToneBuffer;
    unsigned long G711ringToneDataLength;
    
    
}

@property (readonly) AudioComponentInstance audioUnit;
@property (readonly) AudioComponent inputComponent;
@property (readonly) AudioComponentDescription audioComponentDescription;
@property (readonly) AudioStreamBasicDescription audioStreamBasicDescription;
@property (readonly) AudioBuffer tempBuffer;
@property (retain, readwrite) BufferQueue* pcmRcordedData;


@property (nonatomic,strong) SharkfoodMuteSwitchDetector* silenceSwitchDetector;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) AVAudioPlayer *imAudioPlayer;
@property (nonatomic, strong) AVAudioPlayer *silenceTonePlayer;
@property (nonatomic, strong) NSURL *recordedFileUrlForIM;
@property (nonatomic, strong) NSMutableData *recordedFinalDataForIM;
@property (nonatomic, strong) NSMutableArray *systemAudioFileList;
@property(nonatomic, assign) float sentRtpCount;

@end


@implementation RingCallAudioManager

@synthesize audioUnit, inputComponent, audioComponentDescription, audioStreamBasicDescription, tempBuffer, pcmRcordedData, isAudioUnitRunning, isLocalRingBackToneEnabled, audioPlayer, isMuted, isSpeakerEnabled, silenceTonePlayer, currentSystemVolumeLevel, isVibrating, isRIngtonePlaying, isAudioRecordingForIM, recordedFileUrlForIM, recordedFinalDataForIM, isSilenceTonePlaying, receivedRtpCount, signalStatusPercentageByReceivedRtpRate, isCallHoldToneEnabled, sentRtpCount;

NSFileHandle *G729RingtoneFile;
NSMutableData *G729RingtoneNSData;
unsigned long G729RingtoneFileDataLength;
unsigned long G729RingtoneFileCurrentDataLength;
NSTimer *vibrationTimmer;
NSTimer *networkStrengthCheckTimmer;
BOOL isRingToneSilenceSwitchSilenced;
MPMusicPlaybackState musicPlaybackState;


+(RingCallAudioManager *)sharedInstance
{
    pVideoSocket = [VideoSockets GetInstance];
    pVideoCallProcessor = [VideoCallProcessor GetInstance];
    
    if (sharedInstance == nil) {
        sharedInstance = [[RingCallAudioManager alloc] init];
    }
    return sharedInstance;
}
/**
 Initialize the audioUnit and allocate our own temporary buffer.
 The temporary buffer will hold the latest data coming in from the microphone,
 and will be copied to the output when this is requested.
 */
- (id) init {
    self = [super init];
    
    pcmRcordedData = [[BufferQueue alloc] init];
    //g729EncoderDecoder = [[G729Wrapper alloc]init];
    
    [self setUpAudioUnit];
    
    // Allocate our own buffers (1 channel, 16 bits per sample, thus 16 bits per frame, thus 2 bytes per frame).
    // Practice learns the buffers used contain 512 frames, if this changes it will be fixed in processAudio.
    tempBuffer.mNumberChannels = 1;
    
    tempBuffer.mDataByteSize = 1024 * 2;
    tempBuffer.mData = malloc( 1024 * 2 );
    
    // SIlence Switch detector call back block.
    self.silenceSwitchDetector = [SharkfoodMuteSwitchDetector shared];
    self.silenceSwitchDetector.silentNotify = ^(BOOL silent){
        
        if (!isAudioRecordingForIM) {
            isRingToneSilenceSwitchSilenced = silent;
            [self UpdateIsRingToneSilenceSwitchSilenced];
            [self updateRingToneVolumeLevel:currentSystemVolumeLevel withSilence:isRingToneSilenceSwitchSilenced andVibration:VIBRATE_ON_TINGTONE];
            if (silent) {
                
            } else {
                
            }
        }
    };
    
    isAudioUnitRunning = false;
    isLocalRingBackToneEnabled = false;
    isCallHoldToneEnabled = false;
    isMuted = false;
    isRingToneSilenceSwitchSilenced = [self getIsRingToneSilenceSwitchSilenced];
    isSpeakerEnabled = false;
    currentSystemVolumeLevel = [self getVolumeLevel];
    isVibrating = false;
    isRIngtonePlaying = false;
    isAudioRecordingForIM = false;
    isSilenceTonePlaying = false;
    musicPlaybackState = MPMusicPlaybackStateStopped;
    receivedRtpCount = 0.0f;
    sentRtpCount = 0.0f;
    signalStatusPercentageByReceivedRtpRate = 0.0f;
    
    [self loadSystemAudioFileList];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioUnitInterruptionHandler:) name:AVAudioSessionInterruptionNotification object:[AVAudioSession sharedInstance]];
    
    return self;
}


- (void) setUpAudioUnit {
    
    OSStatus status;
    
    // Describe audio component
    audioComponentDescription.componentType = kAudioUnitType_Output;
    audioComponentDescription.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
    audioComponentDescription.componentFlags = 0;
    audioComponentDescription.componentFlagsMask = 0;
    audioComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    if (inputComponent) {
        inputComponent = nil;
    }
    // Get component
    inputComponent = AudioComponentFindNext(NULL, &audioComponentDescription);
    
    
    if (audioUnit) {
        audioUnit = nil;
    }
    // Get audio units
    status = AudioComponentInstanceNew(inputComponent, &audioUnit);
    checkStatus(status);
    
    // Enable IO for recording
    UInt32 flag = 1;
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Input,
                                  kInputBus,
                                  &flag,
                                  sizeof(flag));
    checkStatus(status);
    
    // Enable IO for playback
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Output,
                                  kOutputBus,
                                  &flag,
                                  sizeof(flag));
    checkStatus(status);
    
    // Describe format
    audioStreamBasicDescription.mSampleRate			= AUDIO_SAMPLE_RATE;
    audioStreamBasicDescription.mFormatID			= kAudioFormatLinearPCM;
    //    audioStreamBasicDescription.mFormatFlags		= kAudioFormatFlagsCanonical | kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioStreamBasicDescription.mFormatFlags		=  kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioStreamBasicDescription.mFramesPerPacket	= AUDIO_FRAMES_PER_PACKET;
    audioStreamBasicDescription.mChannelsPerFrame	= AUDIO_CHANNELS_PER_FRAME;
    audioStreamBasicDescription.mBitsPerChannel		= AUDIO_BITS_PER_CHANNEL;
    audioStreamBasicDescription.mBytesPerPacket		= AUDIO_BYTES_PER_PACKET;
    audioStreamBasicDescription.mBytesPerFrame		= AUDIO_BYTES_PER_FRAME;
    
    // Apply format
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &audioStreamBasicDescription,
                                  sizeof(audioStreamBasicDescription));
    checkStatus(status);
    
    
    
    /* Make sure that your application can receive remote control
     * events by adding the code:
     *     [[UIApplication sharedApplication]
     *      beginReceivingRemoteControlEvents];
     * Otherwise audio unit will fail to restart while your
     * application is in the background mode.
     */
    
    
    /* Make sure we set the correct audio category before restarting */
    UInt32 audioCategory = kAudioSessionCategory_PlayAndRecord;
    status = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
                                     sizeof(audioCategory),
                                     &audioCategory);
    
    checkStatus(status);
    
    
    
    
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  kOutputBus,
                                  &audioStreamBasicDescription,
                                  sizeof(audioStreamBasicDescription));
    checkStatus(status);
    
    
    // Set input callback
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = recordingCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_SetInputCallback,
                                  kAudioUnitScope_Global,
                                  kInputBus,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    checkStatus(status);
    
    // Set output callback
    callbackStruct.inputProc = playbackCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Global,
                                  kOutputBus,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    checkStatus(status);
    
    // Disable buffer allocation for the recorder (optional - do this if we want to pass in our own)
    flag = 0;
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_ShouldAllocateBuffer,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &flag,
                                  sizeof(flag));
    
}




/**
 Start the audioUnit. This means data will be provided from
 the microphone, and requested for feeding to the speakers, by
 use of the provided callbacks.
 */
- (void) start {
    
    if (self->recordedPCMBuffer.buffer == NULL) {
        TPCircularBufferInit(&recordedPCMBuffer, Recorded_TPCircularBuffer_SIZE);
    }
    
    if (self->receivedPCMBuffer.buffer == NULL) {
        TPCircularBufferInit(&receivedPCMBuffer, Received_TPCircularBuffer_SIZE);
    }
    
    if ([[MPMusicPlayerController iPodMusicPlayer] playbackState] == MPMusicPlaybackStatePlaying) {
        musicPlaybackState = MPMusicPlaybackStateInterrupted;
    }
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES]; // Disables Auto-Lick feature
    [self resetRTPQueue];
    if (isAudioUnitRunning) {
        return;
    }
    
    if (!isAudioRecordingForIM) {
        
        //    This will enable the proximity monitoring.
        UIDevice *device = [UIDevice currentDevice];
        device.proximityMonitoringEnabled = YES;
        
        
       // [g729EncoderDecoder open];
    }
    
    
    OSStatus status;
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    //    [audioSession setActive:YES error:nil];
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    
    
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
    
    
    //    Initialise the audio unit
    status = AudioUnitInitialize(audioUnit);
    checkStatus(status);
    
    //    Starts the Audio Unit
    status = AudioOutputUnitStart(audioUnit);
    checkStatus(status);
    
    if (self.isSpeakerEnabled) {
        [self AudioForceOutputToBuiltInSpeakers];
    }
    
    
    isAudioUnitRunning = true;
}

/**
 Stop the audioUnit
 */
- (void) stop {
    
    if ([[UIApplication sharedApplication] isIdleTimerDisabled]) {
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO]; // Enables Auto-Lick feature
    }
    
    [self resetRTPQueue];
    if (!isAudioUnitRunning) {
        return;
    }
    
    if (!isAudioRecordingForIM) {
        //    This will disable the proximity monitoring.
        UIDevice *device = [UIDevice currentDevice];
        device.proximityMonitoringEnabled = NO;
    }
    
    OSStatus status;
    
    //    Stops the Audio Unit
    status = AudioOutputUnitStop(audioUnit);
    checkStatus(status);
    
    
    //    Deactivates the audio session
    //    [[AVAudioSession sharedInstance] setActive:NO error:nil]; // Replacement for iOS 7
    [audioSession setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    checkStatus(status);
    
    //    Uninitialise the Audio Unit
    status = AudioUnitUninitialize(audioUnit);
    checkStatus(status);
    
    isAudioUnitRunning = false;
    
    /*if (!isAudioRecordingForIM) {
        [g729EncoderDecoder close];
#if STATE_DEVELOPMENT
        NSLog(@"Codec has been sropped...");
#endif
    }*/
    
    TPCircularBufferCleanup(&recordedPCMBuffer);
    TPCircularBufferCleanup(&receivedPCMBuffer);
}


- (BOOL)iOSVersion6ToUpper {
    NSString *ver = [[UIDevice currentDevice] systemVersion];
    float ver_float = [ver floatValue];
    if (ver_float < 6.0) {
        return NO;
    }
    else {
        return YES;
    }
}

/**
 This callback is called when new audio data from the microphone is
 available.
 */
static OSStatus recordingCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    
    // Because of the way our audio format (setup below) is chosen:
    // we only need 1 buffer, since it is mono
    // Samples are 16 bits = 2 bytes.
    // 1 frame includes only 1 sample
    
    RingCallAudioManager *THIS = sharedInstance;
    
    // This block is for playing Ring Back Tone And Ring Tone.
    if ((THIS->isLocalRingBackToneEnabled) || (THIS->isCallHoldToneEnabled) || (THIS->isRIngtonePlaying)) {
        return 1;
    }
    
    
    AudioBuffer buffer;
    buffer.mNumberChannels = 1;
    buffer.mDataByteSize = inNumberFrames * 2;
    buffer.mData = malloc( inNumberFrames * 2 );
    
    // Put buffer in a AudioBufferList
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0] = buffer;
    
    // Then:
    // Obtain recorded samples
    
    OSStatus status;
    
    status = AudioUnitRender([sharedInstance audioUnit],
                             ioActionFlags,
                             inTimeStamp,
                             inBusNumber,
                             inNumberFrames,
                             &bufferList);
    checkStatus(status);
    
    // Now, we have the samples we just read sitting in buffers in bufferList
    // Process the new data
    [sharedInstance processAudio:&bufferList];
    
    
    // release the malloc'ed data in the buffer we created earlier
    free(bufferList.mBuffers[0].mData);
    
    return noErr;
}

/**
 This callback is called when the audioUnit needs new data to play through the
 speakers. If you don't have any, just don't write anything in the buffers
 */
static OSStatus playbackCallback(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData) {
    
    // Notes: ioData contains buffers (may be more than one!)
    // Fill them up as much as you can. Remember to set the size value in each buffer to match how
    // much data is in the buffer.
    RingCallAudioManager *THIS = sharedInstance;
    
    
    // If we are recording audio for IM then we don't need to execute playback callback.
    if (THIS->isAudioRecordingForIM) {
        return 1;
    }
    
    for (int i=0; i < ioData->mNumberBuffers; i++) { // in practice we will only ever have 1 buffer, since audio format is mono
        AudioBuffer buffer = ioData->mBuffers[i];
        
        
        int availabeBytes;
        UInt32 size;
        SInt16 *temp = NULL;
        
        
        
        if ( THIS->isLocalRingBackToneEnabled) {
            // This block is for playing Ring Back Tone
            availabeBytes = THIS->ringBackTonePCMBuffer.fillCount;
            size = min((int)buffer.mDataByteSize, (int)availabeBytes);
            if (size == 0) {
                TPCircularBufferProduceBytes(&THIS->ringBackTonePCMBuffer, THIS->g711RingBackToneBuffer, (int32_t)THIS->g711RingBackToneDataLength);
                return 1;
            }
            
            temp = (SInt16 *)TPCircularBufferTail(&THIS->ringBackTonePCMBuffer, &availabeBytes);
            if (temp == NULL) {
#if STATE_DEVELOPMENT
                NSLog(@"TPCircularBufferTail Failed ");
#endif
                return 1;
            }
            memcpy(buffer.mData, temp, size);
            buffer.mDataByteSize = size;
            TPCircularBufferConsume(&THIS->ringBackTonePCMBuffer, size);
            return noErr;
        } else if (THIS->isCallHoldToneEnabled) {
            // This block is for playing Call Hold Tone
            availabeBytes = THIS->callHoldTonePCMBuffer.fillCount;
            size = min((int)buffer.mDataByteSize, (int)availabeBytes);
            if (size == 0) {
                TPCircularBufferProduceBytes(&THIS->callHoldTonePCMBuffer, THIS->G711callHoldToneBuffer, (int32_t)THIS->G711callHoldToneDataLength);
                return 1;
            }
            
            temp = (SInt16 *)TPCircularBufferTail(&THIS->callHoldTonePCMBuffer, &availabeBytes);
            if (temp == NULL) {
#if STATE_DEVELOPMENT
                NSLog(@"TPCircularBufferTail Failed ");
#endif
                return 1;
            }
            memcpy(buffer.mData, temp, size);
            buffer.mDataByteSize = size;
            TPCircularBufferConsume(&THIS->callHoldTonePCMBuffer, size);
            return noErr;
        } else if (THIS->isRIngtonePlaying && isRingTonePlayingUsingAudioUnit == 1) {
            // This block is for playing Ring Tone
            availabeBytes = THIS->ringTonePCMBuffer.fillCount;
            size = min((int)buffer.mDataByteSize, (int)availabeBytes);
            if (size == 0) {
                TPCircularBufferProduceBytes(&THIS->ringTonePCMBuffer, THIS->G711ringToneBuffer, (int32_t)THIS->G711ringToneDataLength);
                return 1;
            }
            
            temp = (SInt16 *)TPCircularBufferTail(&THIS->ringTonePCMBuffer, &availabeBytes);
            if (temp == NULL) {
#if STATE_DEVELOPMENT
                NSLog(@"TPCircularBufferTail Failed ");
#endif
                return 1;
            }
            memcpy(buffer.mData, temp, size);
            buffer.mDataByteSize = size;
            TPCircularBufferConsume(&THIS->ringTonePCMBuffer, size);
            return noErr;
        }
        
        
        availabeBytes = THIS->receivedPCMBuffer.fillCount;
        size = min((int)buffer.mDataByteSize, (int)availabeBytes);
        if (size == 0) {
            return 1;
        }
        
        temp = (SInt16 *)TPCircularBufferTail(&THIS->receivedPCMBuffer, &availabeBytes);
        if (temp == NULL) {
            return 1;
        }
        memcpy(buffer.mData, temp, size);
        buffer.mDataByteSize = size;
        TPCircularBufferConsume(&THIS->receivedPCMBuffer, size);
    }
    return noErr;
}


- (void) resetRTPQueue
{
    TPCircularBufferClear(&receivedPCMBuffer);
    TPCircularBufferClear(&recordedPCMBuffer);
}


/**
 Change this funtion to decide what is done with incoming
 audio data from the microphone.
 Right now we copy it to our own temporary buffer.
 */
- (void) processAudio: (AudioBufferList*) bufferList{
    
    
    if (isAudioRecordingForIM) {
        //        NSData *tempRecordedData = [NSData dataWithBytes:bufferList->mBuffers[0].mData length:bufferList->mBuffers[0].mDataByteSize];
        //        [recordedFinalDataForIM appendData:tempRecordedData];
        [recordedFinalDataForIM appendData:[self getDataFromBufferList:bufferList]];
    } else {
        bool isRecordedBufferProduceBytes = false;
        isRecordedBufferProduceBytes = TPCircularBufferProduceBytes(&recordedPCMBuffer, bufferList->mBuffers[0].mData, bufferList->mBuffers[0].mDataByteSize);
        
        
        if (!isRecordedBufferProduceBytes) {
//#if STATE_DEVELOPMENT
            NSLog(@"---------------------- Recorded RTP push faild ----------------------");
//#endif
        } else {
//#if STATE_DEVELOPMENT
            //        NSLog(@"---------------------- Recorded RTP push Succeeded ----------------------");
//#endif
        }
    }
}


-(void) processRTPPacketToSent
{
    int availableBytes;
    //iProcessRTPPacketCounter++;
    void *buffer = TPCircularBufferTail(&recordedPCMBuffer, &availableBytes);
    //if(iProcessRTPPacketCounter%2==0) return;
    
    if (availableBytes)
    {
        if( availableBytes > AUDIO_MAXIMUM_PACKET_LENGTH) {
         
         int randomRawDataPacketSize = (arc4random()%10)*160;
         availableBytes = AUDIO_MINIMUM_PACKET_LENGTH + randomRawDataPacketSize;
         } else if (availableBytes >= AUDIO_MINIMUM_PACKET_LENGTH && availableBytes <= AUDIO_MAXIMUM_PACKET_LENGTH) {
         availableBytes = (availableBytes/160)*160;
         // RICallLog(@"general Length : %d",dataLength);
         } else {
         // Data not enough to send ignor this case..
         return;
         }
        
        /*
        if(availableBytes >= AUDIO_FIXED_PACKET_LENGTH)
        {
            availableBytes = AUDIO_FIXED_PACKET_LENGTH;
        }
        else
        {
            // Data not enough to send ignor this case..
            return;
        }
         */
        
        short shortArray[availableBytes];
        memcpy(shortArray, buffer, availableBytes);
        
        int success = -1;
        //success = [[RIConnectivityManager sharedInstance] sendAudioData:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.callID  audioData:shortArray dataSize:availableBytes/2];
        
        success = CVideoAPI::GetInstance()->SendAudioDataV(200, shortArray, availableBytes/2);
        
        //[[RingCallAudioManager sharedInstance] playMyReceivedAudioData:shortArray withLength:availableBytes/2];
        
        
        cout<<"TheKing-------> SendingAudio = "<<availableBytes/2<<endl;
        
        if (success < 0) {
            //RICallLog(@"Faild to send audio data...................");
        } else {
           // RICallLog(@"Audio data sent to callID: %@ IP:%@ voiceBibdPort:%d",[IDCallManager sharedInstance].currentCallInfoModel.callInfo.callID, [IDCallManager sharedInstance].currentCallInfoModel.callInfo.callServerInfo.voicehostIPAddress, [IDCallManager sharedInstance].currentCallInfoModel.callInfo.callServerInfo.voiceBindingPort);
        }
        
        sentRtpCount++;
        TPCircularBufferConsume(&recordedPCMBuffer, availableBytes);
        
        memset(shortArray, 0, sizeof(shortArray));
    }
}
- (void) playMyReceivedAudioData:(short *)data withLength:(int)iLen
{
    //TPCircularBufferProduceBytes(&receivedPCMBuffer, data, iLen*2);
    //    TPCircularBufferProduceBytes(&receivedPCMBuffer, data, iLen*2);
    
    bool isBufferProduceBytes = false;
    
    @try {
        isBufferProduceBytes = TPCircularBufferProduceBytes(&receivedPCMBuffer, data, iLen*2);
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@", exception);
    }
    
    if (!isBufferProduceBytes) {
        NSLog(@"---------------------- Incoming RTP push faild ----------------------");
    }
}

-(void)processReceivedRTPPacket:(NSData *)receivedRTP
{
    
    NSUInteger len = [receivedRTP length];
    byte* byteData = (byte*)[receivedRTP bytes];
    
    cout<<"Rajib_Check: trying to push audio received rtp"<<endl;
    
    long long lUser = [[VideoCallProcessor GetInstance] GetUserId];
    
    
    cout<<"RingCallAudioManager:: VideoAPI->PushAudioForDecoding --> "<<"lUser = "<<lUser<<", len = "<<len<<endl;
    CVideoAPI::GetInstance()->PushAudioForDecoding(lUser, byteData, len);
    
    /*
    //memcpy(shortArray, byteData, len);
    
    int iDecLen = [pVideoCallProcessor GetG729]->Decode(byteData, len, shortArray);
    
    //Rajib: Method to Play Data
    TPCircularBufferProduceBytes(&receivedPCMBuffer, shortArray, iDecLen * 2);
    */
    
    /*
    RAJIB: Operation Closed to Test Our Data
    NSData *rtpWithGarbage = [receivedRTP subdataWithRange:NSMakeRange(1, receivedRTP.length - 1)];
    unsigned long rowRTPlength = rtpWithGarbage.length - rtpWithGarbage.length % 10 ;
    NSData *rowRTPData = [rtpWithGarbage subdataWithRange:NSMakeRange(0, (int)rowRTPlength)];
    
    //    NSLog(@"Received RTP Size: %lu",(unsigned long)rowRTPData.length);
    
    [self receiverAudio:(Byte *)[rowRTPData bytes] WithLen:(int)rowRTPData.length];
    
    receivedRtpCount++;
//    [self startNetworkStrengthCheckTimmer]; //MARK: we are not using netork strenght timmer for checking strength. SO remove it.
     
     */
}


- (void) receiverAudio:(Byte *)audio WithLen:(int)len
{
    /*
    short receivedShort[len*8];
    bool isBufferProduceBytes = false;
    memset(receivedShort, 0, sizeof(receivedShort));
    Byte bytesToDecode[len];
    memcpy(bytesToDecode, audio, len);
    @try {
        int numberOfDecodedShorts = [g729EncoderDecoder decodeWithG729:bytesToDecode andSize:len andEncodedPCM:receivedShort];
        isBufferProduceBytes = TPCircularBufferProduceBytes(&receivedPCMBuffer, receivedShort, (numberOfDecodedShorts*2));
    }
    @catch (NSException *exception) {
#if STATE_DEVELOPMENT
        NSLog(@"Exception: %@", exception);
#endif
    }
    
    if (!isBufferProduceBytes) {
#if STATE_DEVELOPMENT
        NSLog(@"---------------------- Incoming RTP push faild ----------------------");
#endif
    }
    */
}

-(void)startRecordAndPlayAudio
{
    [self stopRecordAndPlayAudio];
    [[RingCallAudioManager sharedInstance] start];
    self.rtpSenderTimer = [NSTimer scheduledTimerWithTimeInterval:RTP_SENDING_TIME_INTERVAL target:self selector:@selector(rtpSendingTimerMethod) userInfo:nil repeats:YES];
}

-(void)stopRecordAndPlayAudio
{
    if (self.rtpSenderTimer && self.rtpSenderTimer.isValid) {
        [self.rtpSenderTimer invalidate];
        self.rtpSenderTimer = nil;
        [[RingCallAudioManager sharedInstance] stop];
    }
}


// This method will be fired when sending each RTP packet. YES, offcourse if we use NSTimer.
//RAJIB:
//int sleeptime = 1000;
-(void)rtpSendingTimerMethod
{
  //   NSLog(@"rtpSendingTimerMethod 1");
 //   usleep(sleeptime);
 //   sleeptime += 100;
    [self processRTPPacketToSent];
    
   
    /*
    
    if(data != nil && data.length >= RECEIVE_AUDIO_MINIMUM_PACKET_LENGTH) {
        
        RCCallInfoModel *idCallDTO = [IDCallManager sharedInstance].currentCallInfoModel.callInfo;
        
        if (idCallDTO.callServerInfo.voicehostIPAddress != nil && idCallDTO.callServerInfo.voiceBindingPort > 0) {
            
            if (isConnectivityModuleEnabled == 1)
            {
                
                
                if ([[RIConnectivityManager sharedInstance] send:data friendId:[IDCallManager sharedInstance].currentCallInfoModel.callingFrnId mediaType:MEDIA_TYPE_AUDIO] > 0) {
                } else {
                    NSLog(@"***Faild to send RTP data...");
                }
            }
            else
            {
                [[CallSocketCommunication sharedInstance].udpSocket send:data toHost:idCallDTO.callServerInfo.voicehostIPAddress Port:idCallDTO.callServerInfo.voiceBindingPort];
            }
            
            sentRtpCount++;
        }
        
#if STATE_DEVELOPMENT
        //NSLog(@"Sending RTP data to IP:%@ and Port:%d and friend:%@", idCallDTO.callServerInfo.voicehostIPAddress, idCallDTO.callServerInfo.voiceBindingPort, [IDCallManager sharedInstance].currentCallInfoModel.callingFrnId);
#endif
    }
     */
}


- (void) playRingBackTone
{/*
    if (!isLocalRingBackToneEnabled) {
        if ([[MPMusicPlayerController iPodMusicPlayer] playbackState] == MPMusicPlaybackStatePlaying) {
            musicPlaybackState = MPMusicPlaybackStateInterrupted;
        }
        
        //        G729 encoded ring back tone
        NSString* filePath = [RESOURCE_BUNDLE pathForResource:RING_BACK_TONE_FILE_NAME ofType:RING_BACK_TONE_FILE_TYPE];
        G729RingtoneFile = [NSFileHandle fileHandleForReadingAtPath:filePath];
        
        if (G729RingtoneFile == nil)
        {
#if STATE_DEVELOPMENT
            NSLog(@"Failed to open file");
#endif
        }
        
        [g729EncoderDecoder open];
        G729RingtoneNSData = [NSMutableData dataWithContentsOfFile:filePath];
        G729RingtoneFileDataLength = [G729RingtoneNSData length];
        const char* fileBytes = (const char*)[G729RingtoneNSData bytes];
        int numberOf200chunk = (int)G729RingtoneFileDataLength / 200;
        
        TPCircularBufferInit(&ringBackTonePCMBuffer, (int)G729RingtoneFileDataLength*16);
        g711RingBackToneBuffer = (Byte*)malloc(G729RingtoneFileDataLength*16);
        
        int g729index, g711index;
        g729index = g711index = 0;
        for (int i=0; i<numberOf200chunk; i++) {
            short decodedShort[1600];
            Byte _200ByteG729[200];
            memcpy(_200ByteG729, fileBytes+g729index, 200);
            g729index += 200;
            //        int numberOfDecodedShorts = [g729EncoderDecoder decodeWithG729:_200ByteG729 andSize:200 andEncodedPCM:decodedShort];
            [g729EncoderDecoder decodeWithG729:_200ByteG729 andSize:200 andEncodedPCM:decodedShort];
            memcpy(g711RingBackToneBuffer+g711index, decodedShort, 3200);
            g711index += 3200;
        }
        g711RingBackToneDataLength = g711index;
        [g729EncoderDecoder close];
        
        [self start];
        
        TPCircularBufferClear(&ringBackTonePCMBuffer);
        TPCircularBufferProduceBytes(&ringBackTonePCMBuffer, g711RingBackToneBuffer, (int32_t)g711RingBackToneDataLength);
        isLocalRingBackToneEnabled = true;
    }
  */
}


- (void) stopRingBackTone
{
    if (isLocalRingBackToneEnabled) {
        isLocalRingBackToneEnabled = false;
        [self resetRTPQueue];
        if (musicPlaybackState == MPMusicPlaybackStateInterrupted && ([IDCallManager sharedInstance].currentCallInfoModel.packetType != CallResponseType_ANSWER))
        {
            [[MPMusicPlayerController iPodMusicPlayer] play];
            musicPlaybackState = MPMusicPlaybackStatePlaying;
        }
        
        [self stop];
        
        g711RingBackToneBuffer = nil;
        TPCircularBufferCleanup(&ringBackTonePCMBuffer);
        g711RingBackToneDataLength = 0;
    }
}


- (void) playCallHoldTone
{
    if (!G711callHoldToneBuffer) {
        // manage and load Call Hold tone PCM buffer
        NSString *callHoldToneFilePath = [RESOURCE_BUNDLE pathForResource:CALL_HOLD_TONE_FILE_NAME ofType:CALL_HOLD_TONE_FILE_TYPE];
        NSFileHandle *callHoldToneFile = [NSFileHandle fileHandleForReadingAtPath:callHoldToneFilePath];
        
        if (callHoldToneFile == nil)
        {
#if STATE_DEVELOPMENT
            NSLog(@"Failed to open file");
#endif
        }
        
        NSMutableData *callHoldToneNSData;
        callHoldToneNSData = [NSMutableData dataWithContentsOfFile:callHoldToneFilePath];
        G711callHoldToneDataLength = [callHoldToneNSData length];
        const char* callHoldToneFileBytes = (const char*)[callHoldToneNSData bytes];
        
        TPCircularBufferInit(&callHoldTonePCMBuffer, (int)G711callHoldToneDataLength);
        G711callHoldToneBuffer = (Byte*)malloc(G711callHoldToneDataLength);
        
        memcpy(G711callHoldToneBuffer, callHoldToneFileBytes, G711callHoldToneDataLength);
        
        TPCircularBufferProduceBytes(&callHoldTonePCMBuffer, G711callHoldToneBuffer, (int32_t)G711callHoldToneDataLength);
    }
    
    isCallHoldToneEnabled = true;
}


- (void) stopCallHoldTone
{
    if (isCallHoldToneEnabled) {
        isCallHoldToneEnabled = false;
        [self resetRTPQueue];
        
        G711callHoldToneBuffer = nil;
        TPCircularBufferCleanup(&callHoldTonePCMBuffer);
        G711callHoldToneDataLength = 0;
    }
}

-(void) PlayRingTone
{
    [[IDCallManager sharedInstance] notifyRingToneStartedDelegate];
    
    if (isRingTonePlayingUsingAudioUnit == 1) {
        [self PlayRingToneViaPCM];
    } else {
        [self PlayRingToneWithVibration:VIBRATE_ON_TINGTONE];
    }
}


- (void) PlayRingToneWithVibration:(BOOL)isVibrationEnabled
{
    isVibrating = isVibrationEnabled;
    
    [self playSoundFXnamed:RING_TONE_FILE_NAME type:RING_TONE_FILE_TYPE WithLoop:RING_TONE_FILE_PLAY_LOOP AndVibration:isVibrationEnabled];
}


-(BOOL) playSoundFXnamed:(NSString*)vSFXName type:(NSString*)type WithLoop:(int)vLoop AndVibration:(BOOL)isVibrationEnabled
{
    NSError *error;
    
    NSString* filePath = [RESOURCE_BUNDLE pathForResource:vSFXName ofType:type];
    
    //    NSBundle* bundle = RESOURCE_BUNDLE;
    //    NSString* bundleDirectory = (NSString*)[bundle bundlePath];
    currentSystemVolumeLevel = [self getVolumeLevel];
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    if ([[UIApplication sharedApplication] applicationState]!= UIApplicationStateBackground) {
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES]; // Disables Auto-Lock feature
    }
    
    //    NSURL *url = [NSURL fileURLWithPath:[bundleDirectory stringByAppendingPathComponent:vSFXName]];
    //    NSURL *url = [NSURL URLWithString:filePath];
    
    BOOL success = NO;
    UInt32 doSetProperty;
    
    if (self.audioPlayer == nil) {
        
        
        //        NSLog(@"Ringtone File Path: %@",filePath);
        NSFileHandle *ringtoneFile;
        ringtoneFile = [NSFileHandle fileHandleForReadingAtPath:filePath];
        if (ringtoneFile == nil)
        {
            //            NSLog(@"Failed to open file");
        }
        //        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        NSData *ringToneData = [NSData dataWithContentsOfFile:filePath];
        self.audioPlayer = [[[AVAudioPlayer alloc] initWithData:ringToneData error:&error] autorelease];
        
        
        
        if ([[MPMusicPlayerController iPodMusicPlayer] playbackState] == MPMusicPlaybackStatePlaying) {
            musicPlaybackState = MPMusicPlaybackStateInterrupted;
        }
        
        
        //        [audioSession setActive:NO error:nil];
        //        [audioSession setActive:YES error:nil];
        [audioSession setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
        [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
        
        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
            
            if ([[MPMusicPlayerController iPodMusicPlayer] playbackState] == MPMusicPlaybackStatePlaying) {
                musicPlaybackState = MPMusicPlaybackStateInterrupted;
                [[MPMusicPlayerController iPodMusicPlayer] pause];
                doSetProperty = TRUE;
            }
            else if ([audioSession isOtherAudioPlaying])
            {
                doSetProperty = FALSE;
                //                [audioSession setCategory: AVAudioSessionCategoryPlayAndRecord error:nil];
            } else {
                doSetProperty = TRUE;
                //                [audioSession setCategory:AVAudioSessionCategoryPlayback error: nil];
            }
        }
        else {
            doSetProperty = FALSE;
            //            [audioSession setCategory:AVAudioSessionCategoryPlayback error: nil];
        }
        [audioSession setCategory: AVAudioSessionCategoryPlayAndRecord error:nil];
        AudioSessionSetProperty (kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof(doSetProperty), &doSetProperty);
        
        
        BOOL success = [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
        
        
    }
    
    
    if (!self.audioPlayer.isPlaying) {
        if ( vLoop > 0 ) {
            self.audioPlayer.numberOfLoops = vLoop;
        } else {
            self.audioPlayer.numberOfLoops = -1; // Set any negative integer value to loop the sound indefinitely until you call the stop method.
        }
        
        success = [self.audioPlayer play];
        //        NSLog(success ? @"success: YES" : @"success: NO");
        [audioSession overrideOutputAudioPort:kAudioSessionOverrideAudioRoute_Speaker error:nil];
        
        
        if (success) {
            isRIngtonePlaying = true;
            
            if (isRingToneSilenceSwitchSilenced) {
                [self.audioPlayer setVolume:0.0]; // sets system volume
            } else {
                [self.audioPlayer setVolume:currentSystemVolumeLevel]; // sets system volume
            }
            
            //            NSLog(@"currentSystemVolumeLevel: %f", currentSystemVolumeLevel);
            
#if STATE_DEVELOPMENT
            NSLog(@"----------------------------Ring Tone Started");
#endif
            if (isVibrationEnabled) {
                [self startVibrationTimmer];
            }
        }
    } else {
        
#if STATE_DEVELOPMENT
        NSLog(@"----------------------------Ring Tone already Started");
#endif
        success = YES;
    }
    
    return success;
}

-(void) StopRingTone
{
    [[IDCallManager sharedInstance] notifyRingToneEndedDelegate];
    
    if (isRingTonePlayingUsingAudioUnit == 1) {
        [self StopRingToneViaPCM];
        return;
    }
    
    
    
    
    if ([self.audioPlayer isPlaying]) {
        
        
        [self.audioPlayer stop];
        isRIngtonePlaying = false;
        self.audioPlayer = nil;
        [self stop];
        if (isVibrating) {
            [self stopVibrationTimmer];
        }
#if STATE_DEVELOPMENT
        NSLog(@"----------------------------Ring Tone Stopped");
#endif
        
        if (musicPlaybackState == MPMusicPlaybackStateInterrupted && ([IDCallManager sharedInstance].currentCallInfoModel.currentCallState != CallResponseType_ANSWER))
        {
            [[MPMusicPlayerController iPodMusicPlayer] play];
            musicPlaybackState = MPMusicPlaybackStatePlaying;
        }
        else if ([IDCallManager sharedInstance].currentCallInfoModel.currentCallState == CallResponseType_ANSWER)
        {
            //            [[AVAudioSession sharedInstance] setActive:YES error:nil];
            [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
        }
        else
        {
            UInt32 doSetProperty = TRUE;
            [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord error: nil];
            AudioSessionSetProperty (kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof(doSetProperty), &doSetProperty);
            [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
            //            [[AVAudioSession sharedInstance] setActive:NO error:nil];
            [audioSession setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
            
        }
    }
}


- (void) updateRingToneVolumeLevel:(float)volumeLevel withSilence:(BOOL)isSilenced andVibration:(BOOL)vibratChoice
{
    if ([self.audioPlayer isPlaying]) {
        
        if (isSilenced) {
            [self.audioPlayer setVolume:0.0]; // sets system volume
        } else {
            [self.audioPlayer setVolume:volumeLevel]; // sets system volume
        }
        /*
         if (vibratChoice) {
         if ((vibrationTimmer = nil)) {
         [self startVibrationTimmer];
         }
         } else {
         [self stopVibrationTimmer];
         }
         */
    }
}

- (void) PlayRingToneViaPCM
{
    [self start];
    
    
    // ------------ Setup audio settings ------------
//    BOOL success = NO;
    UInt32 doSetProperty;
    NSError *error;
    currentSystemVolumeLevel = [self getVolumeLevel];
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    if ([[UIApplication sharedApplication] applicationState]!= UIApplicationStateBackground) {
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES]; // Disables Auto-Lock feature
    }
    
    if ([[MPMusicPlayerController iPodMusicPlayer] playbackState] == MPMusicPlaybackStatePlaying) {
        musicPlaybackState = MPMusicPlaybackStateInterrupted;
    }
    
    
//    [audioSession setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
//    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
        
        if ([[MPMusicPlayerController iPodMusicPlayer] playbackState] == MPMusicPlaybackStatePlaying) {
            musicPlaybackState = MPMusicPlaybackStateInterrupted;
            [[MPMusicPlayerController iPodMusicPlayer] pause];
            doSetProperty = TRUE;
        }
        else if ([audioSession isOtherAudioPlaying])
        {
            doSetProperty = FALSE;
        } else {
            doSetProperty = TRUE;
        }
    }
    else {
        doSetProperty = FALSE;
    }
    [audioSession setCategory: AVAudioSessionCategoryPlayAndRecord error:nil];
    AudioSessionSetProperty (kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof(doSetProperty), &doSetProperty);
    BOOL success = [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
    // --------------------------------------------


    if (!G711ringToneBuffer) {
        // manage and load Call Hold tone PCM buffer
        NSString *ringToneFilePath = [RESOURCE_BUNDLE pathForResource:RING_TONE_RAW_FILE_NAME ofType:RING_TONE_RAW_FILE_TYPE];
        NSFileHandle *ringToneFile = [NSFileHandle fileHandleForReadingAtPath:ringToneFilePath];
        
        if (ringToneFile == nil)
        {
#if STATE_DEVELOPMENT
            NSLog(@"Failed to open file");
#endif
        }
        
        NSMutableData *ringToneNSData;
        ringToneNSData = [NSMutableData dataWithContentsOfFile:ringToneFilePath];
        G711ringToneDataLength = [ringToneNSData length];
        const char* ringToneFileBytes = (const char*)[ringToneNSData bytes];
        
        TPCircularBufferInit(&ringTonePCMBuffer, (int)G711ringToneDataLength);
        G711ringToneBuffer = (Byte*)malloc(G711ringToneDataLength);
        
        memcpy(G711ringToneBuffer, ringToneFileBytes, G711ringToneDataLength);
        
        TPCircularBufferProduceBytes(&ringTonePCMBuffer, G711ringToneBuffer, (int32_t)G711ringToneDataLength);
    }
    
    isRIngtonePlaying = true;
}


- (void) StopRingToneViaPCM
{
    if (isRIngtonePlaying) {
        isRIngtonePlaying = false;
        [self resetRTPQueue];
        
        G711ringToneBuffer = nil;
        TPCircularBufferCleanup(&ringTonePCMBuffer);
        G711ringToneDataLength = 0;
        
//        [self stop];
        
        // ------------ Resume audio settings ------------
        if (musicPlaybackState == MPMusicPlaybackStateInterrupted && ([IDCallManager sharedInstance].currentCallInfoModel.currentCallState != CallResponseType_ANSWER))
        {
            [[MPMusicPlayerController iPodMusicPlayer] play];
            musicPlaybackState = MPMusicPlaybackStatePlaying;
        }
        else if ([IDCallManager sharedInstance].currentCallInfoModel.currentCallState == CallResponseType_ANSWER)
        {
            [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
        }
        else
        {
            UInt32 doSetProperty = TRUE;
            [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord error: nil];
            AudioSessionSetProperty (kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof(doSetProperty), &doSetProperty);
            [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
            [audioSession setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
        }
        // -----------------------------------------------
    }
}

-(void) PlaySilenceTone
{
    [self playSilenceSoundFXnamed:SILENCE_TONE_FILE_NAME type:SILENCE_TONE_FILE_TYPE Loop:SILENCE_TONE_FILE_PLAY_LOOP];
}

-(BOOL) playSilenceSoundFXnamed:(NSString*)vSFXName type:(NSString*)type Loop: (int) vLoop
{
    
    //MARK: If we use RingCallModuleResource.bundle then we should use this block. And we should use RingCallModuleResource.bundle
    NSBundle* bundle = RESOURCE_BUNDLE;
    NSString* bundleDirectory = (NSString*)[bundle bundlePath];
    NSString* filePath = [RESOURCE_BUNDLE pathForResource:vSFXName ofType:type];
    NSURL *url = [NSURL URLWithString:filePath];
    
    NSError *error;
    BOOL success = NO;
    
    
    if (self.silenceTonePlayer == nil) {
        self.silenceTonePlayer = [[[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error] autorelease];
        self.silenceTonePlayer.delegate = self;
        //        [[AVAudioSession sharedInstance] setActive:YES error:nil]; // This line is casing the stop of music played while we disconnect the call in background.
        
        
        UInt32 doSetProperty = TRUE;
        [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord error: nil];
        AudioSessionSetProperty (kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof(doSetProperty), &doSetProperty);
        //        [[AVAudioSession sharedInstance] overrideOutputAudioPort:kAudioSessionOverrideAudioRoute_Speaker error:nil];
        //        NSLog(@"Current Audio Route: %@", [AudioSessionManager sharedInstance].audioRoute);
        
        
        MPMusicPlaybackState playbackStateLocal = [[MPMusicPlayerController iPodMusicPlayer] playbackState];
        if (playbackStateLocal == MPMusicPlaybackStatePaused || playbackStateLocal == MPMusicPlaybackStatePlaying || playbackStateLocal == MPMusicPlaybackStateInterrupted) {
            //            [[AVAudioSession sharedInstance] overrideOutputAudioPort:kAudioSessionOverrideAudioRoute_None error:nil];
        }
        else {
            [[AVAudioSession sharedInstance] overrideOutputAudioPort:kAudioSessionOverrideAudioRoute_Speaker error:nil];
        }
        
        if ( vLoop > 0 ) {
            self.silenceTonePlayer.numberOfLoops = vLoop;
        } else {
            self.silenceTonePlayer.numberOfLoops = -1; // Set any negative integer value to loop the sound indefinitely until you call the stop method.
        }
        
        success = [self.silenceTonePlayer play];
        isSilenceTonePlaying = true;
        
        if (!success) {
            isSilenceTonePlaying = false;
            //            NSLog(@"----------------------------Silence player faild to start. self.silenceTonePlayer: %@  AND  self.silenceTonePlayer.isPlaying: %@",self.silenceTonePlayer ,self.silenceTonePlayer.isPlaying ? @"Yes" : @"No");
        }
    }
    
    //    NSLog(self.silenceTonePlayer.isPlaying ? @"silenceTonePlayer.isPlaying: Yes" : @"silenceTonePlayer.isPlaying: No");
    return success;
}

-(void) StopSilenceTone
{
    if ([self.silenceTonePlayer isPlaying]) {
        
        [self.silenceTonePlayer stop];
        isSilenceTonePlaying = false;
        
        //        NSLog(@"----------------------------Silence player Stopped");
    }
    if (self.silenceTonePlayer) {
        isSilenceTonePlaying = false;
        self.silenceTonePlayer = nil;
        
        /*
         // This block should be commented out.
         UInt32 doSetProperty = TRUE;
         [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord error: nil];
         AudioSessionSetProperty (kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof(doSetProperty), &doSetProperty);
         */
        
        //        [[AVAudioSession sharedInstance] setActive:NO error:nil];
        [audioSession setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
        [self stop];
    }
    
    //    NSLog(self.silenceTonePlayer.isPlaying ? @"silenceTonePlayer.isPlaying: Yes" : @"silenceTonePlayer.isPlaying: No");
}


- (void) startAudioRecordingForIM
{
    
    self.recordedFinalDataForIM = [[[NSMutableData alloc] init] autorelease];
    
    isAudioRecordingForIM = true;
    [self resetRTPQueue];
    [self start];
}

- (NSURL *) stopAudioRecordingForIMandReturnRecordedFilePathWithFileName:(NSString *)fileNameWithOutExt
{
    [self stop];
    [self resetRTPQueue];
    isAudioRecordingForIM = false;
    NSString *fullFileName = [NSString stringWithFormat:@"%@.pcm",fileNameWithOutExt];
    
    //    [self createFileWithName:AUDIO_IM_RECORDED_RAW_FILE_FULL_NAME];
    [self createFileWithName:fullFileName];
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString *soundFilePath = [docsDir stringByAppendingPathComponent:fullFileName];
    [self.recordedFinalDataForIM writeToFile:soundFilePath atomically:YES];
    recordedFileUrlForIM = [NSURL fileURLWithPath:soundFilePath];
    
    recordedFinalDataForIM = nil;
    return recordedFileUrlForIM;
}

- (NSURL *) getG729EncodedDataFileFromPCMdataFileWithPath:(NSURL *)filePath
{
    /*
    if (!filePath) {
        return nil;
    }
    
    NSMutableData *chatAudioPCMNSData;
    unsigned long chatAudioPCMFileDataLength;
    
    chatAudioPCMNSData = [NSMutableData dataWithContentsOfURL:filePath];
    chatAudioPCMFileDataLength = [chatAudioPCMNSData length];
    const char* fileBytes = (const char*)[chatAudioPCMNSData bytes];
    
    short shortArrayForPCMData[chatAudioPCMFileDataLength/2];
    memcpy(shortArrayForPCMData, fileBytes, chatAudioPCMFileDataLength);
    int g729EncodedBytesLength = ceil(chatAudioPCMFileDataLength/16);
    Byte g729EncodedBytes[g729EncodedBytesLength];
    
    
    [g729EncoderDecoder open];
    int encodedLength = [g729EncoderDecoder encodeWithPCM:shortArrayForPCMData andSize:(int)sizeof(shortArrayForPCMData)/sizeof(shortArrayForPCMData[0]) andEncodedG729:g729EncodedBytes];
    [g729EncoderDecoder close];
    
    
    NSData *g729EncodedData = [NSData dataWithBytes:g729EncodedBytes length:sizeof(g729EncodedBytes)];
    
    
    //    [self createFileWithName:AUDIO_IM_RECORDED_ENCODED_FILE_FULL_NAME];
    NSString *encodedFileName = [[[filePath path] lastPathComponent] stringByDeletingPathExtension];
    NSString *encodedFileFullName = [NSString stringWithFormat:@"%@.g729",encodedFileName];
    [self createFileWithName:encodedFileFullName];
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString *soundFilePath = [docsDir stringByAppendingPathComponent:encodedFileFullName];
    
    [g729EncodedData writeToFile:soundFilePath atomically:YES];
    NSURL *g729EncodedDataPath = [NSURL fileURLWithPath:soundFilePath];
    
    
    return g729EncodedDataPath;
     */
    return nil;
}

- (NSString *) getPCMdataPathFromG729EncodedDataFileWithPath:(NSURL *)filePath
{
    /*
    if (!filePath) {
        return nil;
    }
    
    NSData *chatAudioData = [NSData dataWithContentsOfURL:filePath];
    unsigned long chatAudioG729DataLength = [chatAudioData length];
    short decodedShort[chatAudioG729DataLength*16];
    
    [g729EncoderDecoder open];
    int decodedLength = [g729EncoderDecoder decodeWithG729:(Byte *)[chatAudioData bytes] andSize:(int)chatAudioG729DataLength andEncodedPCM:decodedShort];
    [g729EncoderDecoder close];
    // Byte G711chatAudioData[decodedLength*2];
    
    NSUInteger len = decodedLength*2;
    Byte *byteData = [self short2byte:decodedShort size:decodedLength resultSize:decodedLength*2];
    NSData *decodecAudioData = [NSData dataWithBytes:byteData length:len];
    free(byteData);
    NSString *pcmFileName = [[[filePath path] lastPathComponent] stringByDeletingPathExtension];
    NSString *pcmFileFullName = [NSString stringWithFormat:@"%@.pcm",pcmFileName];
    
    //    [self createFileWithName:AUDIO_IM_RECORDED_RAW_FILE_FULL_NAME];
    [self createFileWithName:pcmFileFullName];
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString *soundFilePath = [docsDir stringByAppendingPathComponent:pcmFileFullName];
    [decodecAudioData writeToFile:soundFilePath atomically:YES];
    
    
    return soundFilePath;
    */
    return nil;
}


- (NSURL *) getAndCreatePlayableFileFromPcmData:(NSString *)filePath
{
    
    if (!filePath) {
        return nil;
    }
    
    NSString *wavFileName = [[filePath lastPathComponent] stringByDeletingPathExtension];
    NSString *wavFileFullName = [NSString stringWithFormat:@"%@.wav",wavFileName];
    
    //    [self createFileWithName:AUDIO_IM_WAV_FILE_FULL_NAME];
    [self createFileWithName:wavFileFullName];
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString *wavFilePath = [docsDir stringByAppendingPathComponent:wavFileFullName];
    
    //    NSLog(@"PCM file path : %@",filePath);
    
    FILE *fout;
    
    short NumChannels = AUDIO_CHANNELS_PER_FRAME;
    short BitsPerSample = AUDIO_BITS_PER_CHANNEL;
    int SamplingRate = AUDIO_SAMPLE_RATE;
    int numOfSamples = (int)[[NSData dataWithContentsOfFile:filePath] length];
    
    int ByteRate = NumChannels*BitsPerSample*SamplingRate/8;
    short BlockAlign = NumChannels*BitsPerSample/8;
    int DataSize = NumChannels*numOfSamples*BitsPerSample/8;
    int chunkSize = 16;
    //    int totalSize = 36 + DataSize;
    int totalSize = 46 + DataSize;
    short audioFormat = 1; //  ??
    
    if((fout = fopen([wavFilePath cStringUsingEncoding:1], "w")) == NULL)
    {
        printf("Error opening out file ");
    }
    
    fwrite("RIFF", sizeof(char), 4,fout);
    fwrite(&totalSize, sizeof(int), 1, fout);
    fwrite("WAVE", sizeof(char), 4, fout);
    fwrite("fmt ", sizeof(char), 4, fout);
    fwrite(&chunkSize, sizeof(int),1,fout);
    fwrite(&audioFormat, sizeof(short), 1, fout);
    fwrite(&NumChannels, sizeof(short),1,fout);
    fwrite(&SamplingRate, sizeof(int), 1, fout);
    fwrite(&ByteRate, sizeof(int), 1, fout);
    fwrite(&BlockAlign, sizeof(short), 1, fout);
    fwrite(&BitsPerSample, sizeof(short), 1, fout);
    fwrite("data", sizeof(char), 4, fout);
    fwrite(&DataSize, sizeof(int), 1, fout);
    
    /*
     size_t n;
     while((n = fread(buffer, 1, sizeof(buffer), fin)) > 0) {
     if(n != fwrite(buffer, 1, n, fout)) {
     perror("fwrite");
     }
     }
     if(n < 0) {
     perror("fread");
     }
     */
    
    fclose(fout);
    
    
    NSMutableData *pamdata = [NSMutableData dataWithContentsOfFile:filePath];
    NSFileHandle *handle;
    handle = [NSFileHandle fileHandleForUpdatingAtPath:wavFilePath];
    [handle seekToEndOfFile];
    [handle writeData:pamdata];
    [handle closeFile];
    
    return [NSURL URLWithString:wavFilePath];
}


- (void) playAudioFromIMwithFilePath:(NSURL *)pathUrl
{
    
    if (!pathUrl) {
        return ;
    }
    
    if (!self.imAudioPlayer) {
        NSError *error;
        
        self.imAudioPlayer = [[[AVAudioPlayer alloc] initWithContentsOfURL:pathUrl error:&error] autorelease];
        
        
        //set up audio session
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryPlayback error:NULL];
        
        UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
        AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,sizeof (audioRouteOverride),&audioRouteOverride);
        
        
        [self.imAudioPlayer setVolume:1.0];
        [self.imAudioPlayer setDelegate:self];
        [self.imAudioPlayer setNumberOfLoops:0];
        [self.imAudioPlayer prepareToPlay];
        
        
        //and whereever you want to play the sound, call the lines below
        //        float currentVolume=[MPMusicPlayerController applicationMusicPlayer].volume; //grab current User volume
        //        [[MPMusicPlayerController applicationMusicPlayer] setVolume:1.0];//set system vol to max
        
        
        [self.imAudioPlayer play];
        
        //        [[MPMusicPlayerController applicationMusicPlayer] setVolume:1.0];
        //        OSStatus status = AudioUnitSetParameter(audioUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Global, kOutputBus, 1.0, 0);
        //        AudioQueueSetParameter(audioUnit, kAudioQueueParam_Volume, 1.0);
        
        [[RingCallAudioManager sharedInstance] AudioForceOutputToBuiltInSpeakers];
    }
}


- (void) AudioInitAudioSessionRouting
{
    [AudioRouter initAudioSessionRouting];
    [self resetRTPQueue];
}

- (void) AudioSwitchToDefaultHardware
{
    [AudioRouter switchToDefaultHardware];
    isSpeakerEnabled = false;
    [self resetRTPQueue];
}

- (void) AudioForceOutputToBuiltInSpeakers
{
    [AudioRouter forceOutputToBuiltInSpeakers];
    isSpeakerEnabled = true;
    [self resetRTPQueue];
}

- (void) AudioMute
{
    isMuted = [AudioRouter muteAudio:audioUnit];
    [self resetRTPQueue];
}

- (void) AudioUnMute
{
    isMuted = [AudioRouter unMuteAudio:audioUnit];
    [self resetRTPQueue];
}


- (void) AudioStartBTAudio
{
    [AudioRouter startBTAudio];
    [self resetRTPQueue];
}

- (void) AudioStopBTAudio
{
    [AudioRouter stopBTAudio];
    [self resetRTPQueue];
}


- (void) closeG729Codec
{
   // [g729EncoderDecoder close];
}



- (void) AudioInitialiseForNewCall
{
    
    [self stopRecordAndPlayAudio];
    [self AudioSwitchToDefaultHardware];
    [self stopNetworkStrengthCheckTimmer];
    [self stopVibrationTimmer];
    
    if (isMuted) {
        [self AudioUnMute];
    }
    
    if (isLocalRingBackToneEnabled) {
        [self stopRingBackTone];
    }
    
    if (isCallHoldToneEnabled) {
        [self stopCallHoldTone];
    }
    
    if (isRIngtonePlaying) {
        [self StopRingTone];
    }
    
    if (isAudioUnitRunning) {
        [self stop];
    }
    
//    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
//        if (!isSilenceTonePlaying) {
//            //            [self PlaySilenceTone];
//        }
//    } else {
//        if (isSilenceTonePlaying) {
//            //            [self StopSilenceTone];
//        }
//    }
    
    if (musicPlaybackState == MPMusicPlaybackStateInterrupted && ([IDCallManager sharedInstance].currentCallInfoModel.currentCallState != CallResponseType_ANSWER))
    {
        [[MPMusicPlayerController iPodMusicPlayer] play];
        musicPlaybackState = MPMusicPlaybackStatePlaying;
    }
    
    //    This will disable the proximity monitoring.
    UIDevice *device = [UIDevice currentDevice];
    device.proximityMonitoringEnabled = NO;
    
    [self restartAudioUnit];
}

- (void) restartAudioUnit
{
    
    if (isAudioRecordingForIM || isAudioUnitRunning || audioUnit) {
#if STATE_DEVELOPMENT
        NSLog(@"Already have audioUnit. SO will reinitialise it....");
#endif
        AudioComponentInstanceDispose(audioUnit);
        [self setUpAudioUnit];
    } else {
#if STATE_DEVELOPMENT
        NSLog(@"Doesn't have audioUnit. So will initialise it...");
#endif
        [self setUpAudioUnit];
    }
}

- (float) getVolumeLevel
{
    /*
     MPVolumeView *slide = [MPVolumeView new];
     UISlider *volumeViewSlider;
     
     for (UIView *view in [slide subviews]){
     if ([[[view class] description] isEqualToString:@"MPVolumeSlider"]) {
     volumeViewSlider = (UISlider *) view;
     }
     }
     
     float val = [volumeViewSlider value];
     NSLog(@"output volume via MPVolumeView: %f dB", val);
     */
    
    
    float val = [[AVAudioSession sharedInstance] outputVolume];
    //     NSLog(@"Output volume via AVAudioSession: %f dB", val);
    
    
    /*
     Float32 val;
     UInt32 dataSize = sizeof(Float32);
     AudioSessionGetProperty (
     kAudioSessionProperty_CurrentHardwareOutputVolume,
     &dataSize,
     &val
     );
     NSLog(@"output volume via AU: %f dB", val);
     */
    
    return val;
}


- (void) setIsRingToneSilenceSwitchSilenced:(BOOL)isSilenced
{
    isRingToneSilenceSwitchSilenced  = isSilenced;
}

- (void) UpdateIsRingToneSilenceSwitchSilenced
{
    isRingToneSilenceSwitchSilenced  = [[SharkfoodMuteSwitchDetector shared] isMute];
}


- (BOOL) getIsRingToneSilenceSwitchSilenced
{
    return [[SharkfoodMuteSwitchDetector shared] isMute];
}


- (NSString *)machine
{
    static NSString *machine = nil;
    
    // we keep name around (its like 10 bytes....) forever to stop lots of little mallocs;
    if(machine == nil)
    {
        char * name = nil;
        size_t size;
        
        // Set 'oldp' parameter to NULL to get the size of the data
        // returned so we can allocate appropriate amount of space
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        
        // Allocate the space to store name
        name = (char*)malloc(size);
        
        // Get the platform name
        sysctlbyname("hw.machine", name, &size, NULL, 0);
        
        // Place name into a string
        machine = [NSString stringWithUTF8String:name];
        // Done with this
        free(name);
    }
    
    return machine;
}

-(BOOL)hasVibration
{
    NSString * machine = [self machine];
    
    if([[machine uppercaseString] rangeOfString:@"IPHONE"].location != NSNotFound)
    {
        return YES;
    }
    
    return NO;
}

-(void) startVibration
{
    if (isRIngtonePlaying) {
        if ([self hasVibration]) {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        }
    }
}

-(void) startVibrationTimmer
{
    if ((vibrationTimmer != nil) && (vibrationTimmer.isValid)) {
        vibrationTimmer = [NSTimer
                           scheduledTimerWithTimeInterval:0.8f
                           target:self
                           selector:@selector(startVibration)
                           userInfo:nil
                           repeats:YES];
    }
}

-(void) stopVibrationTimmer
{
    if (vibrationTimmer) {
        [vibrationTimmer invalidate];
        vibrationTimmer = nil;
        isVibrating = false;
    }
}

-(void) startNetworkStrengthCheckTimmer
{
    if (!networkStrengthCheckTimmer  && !networkStrengthCheckTimmer.isValid) {
        networkStrengthCheckTimmer = [NSTimer
                                      scheduledTimerWithTimeInterval:NET_STRENGHT_CHECK_TIME_INTERVAL
                                      target:self
                                      selector:@selector(calculateSignalStrengthByReceivedRtpRate)
                                      userInfo:nil
                                      repeats:YES];
    }
}

-(void) stopNetworkStrengthCheckTimmer
{
    if ((networkStrengthCheckTimmer)  && (networkStrengthCheckTimmer.isValid)) {
        [networkStrengthCheckTimmer invalidate];
        networkStrengthCheckTimmer = nil;
    }
}

#pragma mark AVAudioPlayerDelegate methods

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    
    if (player == _imAudioPlayer) {
        [[RingCallAudioManager sharedInstance] AudioSwitchToDefaultHardware];
        _imAudioPlayer = nil;
    }
}

/* audioPlayerBeginInterruption: is called when the audio session has been interrupted while the player was playing. The player will have been paused. */
- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player {
    if (player == self.silenceTonePlayer) {
#if STATE_DEVELOPMENT
        NSLog(@"silenceTonePlayer BeginInterruption");
#endif
        //        [self StopSilenceTone];
        //        [self PlaySilenceTone];
    }
}

/* audioPlayerEndInterruption:withOptions: is called when the audio session interruption has ended and this player had been interrupted while playing. */
/* Currently the only flag is AVAudioSessionInterruptionFlags_ShouldResume. */
- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player withOptions:(NSUInteger)flags {
    if (player == self.silenceTonePlayer) {
#if STATE_DEVELOPMENT
        NSLog(@"silenceTonePlayer EndInterruption");
#endif
        if (self.isSilenceTonePlaying) {
            //            [self StopSilenceTone];
            //            [self PlaySilenceTone];
        }
    }
}


#pragma mark RemoteControlEvents methodes

-(BOOL)canBecomeFirstResponder {
    return YES;
}

-(void) startRemoteControlEvents {
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
}

-(void) endRemoteControlEvents {
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
}

-(void)remoteControlReceivedWithEvent:(UIEvent *)event {
    switch (event.subtype) {
        case UIEventSubtypeRemoteControlTogglePlayPause:
            NSLog(@"UIEventSubtypeRemoteControlTogglePlayPause");
            [self StopRingTone];
            break;
        case UIEventSubtypeRemoteControlPlay:
            NSLog(@"UIEventSubtypeRemoteControlPlay");
            [self StopRingTone];
            break;
        case UIEventSubtypeRemoteControlPause:
            NSLog(@"UIEventSubtypeRemoteControlPause");
            [self StopRingTone];
            break;
        case UIEventSubtypeRemoteControlNextTrack:
            NSLog(@"UIEventSubtypeRemoteControlNextTrack");
            [self StopRingTone];
            break;
        case UIEventSubtypeRemoteControlPreviousTrack :
            NSLog(@"UIEventSubtypeRemoteControlPreviousTrack");
            [self StopRingTone];
            break;
        case UIEventSubtypeRemoteControlStop :
            NSLog(@"UIEventSubtypeRemoteControlStop");
            [self StopRingTone];
            break;
        default:
            break;
    }
}

#pragma mark AVAudioSessionDelegate methods

//Interruption handler
- (void) audioUnitInterruptionHandler: (NSNotification*) aNotification
{
    NSDictionary *interuptionDict = aNotification.userInfo;
    NSNumber* interuptionType = (NSNumber*)[interuptionDict valueForKey:AVAudioSessionInterruptionTypeKey];
    
    if([interuptionType intValue] == AVAudioSessionInterruptionTypeBegan)
    {
        if ([IDCallManager sharedInstance].currentCallInfoModel.packetType == CallResponseType_VOICE_MEDIA) {
            [[IDCallManager sharedInstance] performCallHold];
            //            NSLog(@"---------------------------------CAll_HOLD sent...");
        } else if ([RingCallAudioManager sharedInstance].isSilenceTonePlaying) {
            //            NSLog(@"---------------------------------Stop SilenceTone...");
            [[RingCallAudioManager sharedInstance] StopSilenceTone];
        }
    }
    else if ([interuptionType intValue] == AVAudioSessionInterruptionTypeEnded)
    {
        if ([IDCallManager sharedInstance].currentCallInfoModel.packetType == CallResponseType_VOICE_CALL_HOLD) {
            [[IDCallManager sharedInstance] performCallUnhold];
            //            NSLog(@"---------------------------------CAll_UNHOLD sent...");
        }
        else if (([IDCallManager sharedInstance].currentCallInfoModel.currentCallState == CallResponseType_Auth) && ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground)) {
            
            //            NSLog(@"---------------------------------Start KeepAlive...");
            [[IDCallManager sharedInstance] callDelegateToStartBackgroundKeepAlive];
            [[NSNotificationCenter defaultCenter] postNotificationName:CTCallStateDisconnected object:self userInfo:nil]; // This one is working
        }
    }
}


- (Byte *) short2byte:(short *)shorts size:(int)size resultSize:(int)resultSize {
    Byte *bytes = (Byte *)malloc(sizeof(Byte)*resultSize);
    for (int i = 0; i < size; i++)
    {
        bytes[i * 2] = (Byte) (shorts[i] & 0x00FF);
        bytes[(i * 2) + 1] = (Byte) (shorts[i] >> 8);
        shorts[i] = 0;
    }
    return bytes;
}


- (short *) byte2short:(Byte *)bytes size:(int)size resultSize:(int)resultSize {
    short *shorts = (short *)malloc(sizeof(short)*resultSize);
    printf("shorts: \n");
    for (int i=0; i < size/2; i++){
        shorts[i] = (bytes[i*2+1] << 8) | bytes[i*2];
        printf("%u, ", shorts[i]);
        //shorts[i] *= 3;
    }
    printf("\n");
    return shorts;
}

- (void) listAllLocalFiles
{
    // Fetch directory path of document for local application.
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    // NSFileManager is the manager organize all the files on device.
    NSFileManager *manager = [NSFileManager defaultManager];
    // This function will return all of the files' Name as an array of NSString.
    NSArray *files = [manager contentsOfDirectoryAtPath:documentsDirectory error:nil];
    // Log the Path of document directory.
    //    NSLog(@"Directory: %@", documentsDirectory);
    // For each file, log the name of it.
    for (NSString *file in files) {
        //        NSLog(@"File at: %@", file);
    }
}

- (void)createFileWithName:(NSString *)fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    // 1st, This funcion could allow you to create a file with initial contents.
    // 2nd, You could specify the attributes of values for the owner, group, and permissions.
    // Here we use nil, which means we use default values for these attibutes.
    // 3rd, it will return YES if NSFileManager create it successfully or it exists already.
    if ([manager createFileAtPath:filePath contents:nil attributes:nil]) {
        //        NSLog(@"Created the File Successfully.");
    } else {
        //        NSLog(@"Failed to Create the File");
    }
}


- (void)deleteFileWithName:(NSString *)fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    // Have the absolute path of file named fileName by joining the document path with fileName, separated by path separator.
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    // Need to check if the to be deleted file exists.
    if ([manager fileExistsAtPath:filePath]) {
        NSError *error = nil;
        // This function also returnsYES if the item was removed successfully or if path was nil.
        // Returns NO if an error occurred.
        [manager removeItemAtPath:filePath error:&error];
        if (error) {
            //            NSLog(@"There is an Error: %@", error);
        }
    } else {
        //        NSLog(@"File %@ doesn't exists", fileName);
    }
}


- (void) renameFileWithName:(NSString *)srcName toName:(NSString *)dstName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePathSrc = [documentsDirectory stringByAppendingPathComponent:srcName];
    NSString *filePathDst = [documentsDirectory stringByAppendingPathComponent:dstName];
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePathSrc]) {
        NSError *error = nil;
        [manager moveItemAtPath:filePathSrc toPath:filePathDst error:&error];
        if (error) {
            //            NSLog(@"There is an Error: %@", error);
        }
    } else {
        //        NSLog(@"File %@ doesn't exists", srcName);
    }
}

/* This function read content from the file named fileName.
 */
- (void)readFileWithName:(NSString *)fileName
{
    // Fetch directory path of document for local application.
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    // Have the absolute path of file named fileName by joining the document path with fileName, separated by path separator.
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
    
    // NSFileManager is the manager organize all the files on device.
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]) {
        // Start to Read.
        NSError *error = nil;
        NSString *content = [NSString stringWithContentsOfFile:filePath encoding:NSStringEncodingConversionAllowLossy error:&error];
        //        NSLog(@"File Content: %@", content);
        
        if (error) {
            //            NSLog(@"There is an Error: %@", error);
        }
    } else {
        //        NSLog(@"File %@ doesn't exists", fileName);
    }
}

/* This function Write "content" to the file named fileName.
 */
- (void) writeString:(NSString *)content toFile:(NSString *)fileName
{
    // Fetch directory path of document for local application.
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    // Have the absolute path of file named fileName by joining the document path with fileName, separated by path separator.
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
    
    // NSFileManager is the manager organize all the files on device.
    NSFileManager *manager = [NSFileManager defaultManager];
    // Check if the file named fileName exists.
    if ([manager fileExistsAtPath:filePath]) {
        NSError *error = nil;
        
        [content writeToFile:filePath atomically:YES encoding:NSStringEncodingConversionAllowLossy error:&error];
        // If error happens, log it.
        if (error) {
            //            NSLog(@"There is an Error: %@", error);
        }
    } else {
        // If the file doesn't exists, log it.
        //        NSLog(@"File %@ doesn't exists", fileName);
    }
    
    // This function could also be written without NSFileManager checking on the existence of file,
    // since the system will atomatically create it for you if it doesn't exist.
}


-(AudioBufferList *) getBufferListFromData: (NSData *) data
{
    if (data.length > 0)
    {
        NSUInteger len = [data length];
        //I guess you can use Byte*, void* or Float32*. I am not sure if that makes any difference.
        Byte * byteData = (Byte*) malloc (len);
        memcpy (byteData, [data bytes], len);
        if (byteData)
        {
            AudioBufferList * theDataBuffer =(AudioBufferList*)malloc(sizeof(AudioBufferList) * 1);
            theDataBuffer->mNumberBuffers = 1;
            theDataBuffer->mBuffers[0].mDataByteSize = (UInt32)len;
            theDataBuffer->mBuffers[0].mNumberChannels = 1;
            theDataBuffer->mBuffers[0].mData = byteData;
            // Read the data into an AudioBufferList
            return theDataBuffer;
        }
    }
    return nil;
}

- (NSData *) getDataFromBufferList:(AudioBufferList *)bufferList
{
    AudioBuffer audioBuffer = bufferList->mBuffers[0];
    Float32 *frame = (Float32*)audioBuffer.mData;
    
    NSMutableData *data=[[[NSMutableData alloc] init] autorelease];
    [data appendBytes:frame length:audioBuffer.mDataByteSize];
    
    return data;
}

- (NSAttributedString *) calculateSignalStrengthByReceivedRtpRateForTimeInterval {
    RCCurrentCallInfoModel *currentCallInfo = [IDCallManager sharedInstance].currentCallInfoModel;
    
    NSMutableAttributedString *signalStatusStrByReceivedRtpRate = nil;
    
    signalStatusPercentageByReceivedRtpRate = ceil((receivedRtpCount/sentRtpCount)*100);
//    NSLog(@"***Percentage:          %f",signalStatusPercentageByReceivedRtpRate);
//    NSLog(@"***receivedRtpCount:    %f",receivedRtpCount);
//    NSLog(@"***sentRtpCount:        %f",sentRtpCount);
//    NSLog(@"====================================================================");
    
    
    if ([VoipUtils isInternConnectionAvailable]) {
        
        /*
        if (!signalStatusPercentageByReceivedRtpRate || (signalStatusPercentageByReceivedRtpRate == 0) || [[NSString stringWithFormat:@"%f",signalStatusPercentageByReceivedRtpRate] isEqualToString:@"nan"]) {
            NSLog(@"Percentage not available");
            
            signalStatusStrByReceivedRtpRate = [[[NSMutableAttributedString alloc] initWithString:@"Network: Average"] autorelease];
            [signalStatusStrByReceivedRtpRate addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:(40/255.0) green:(40/255.0) blue:(40/255.0) alpha:0.8f] range:NSMakeRange(0, 8)];
            [signalStatusStrByReceivedRtpRate addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:(255/255.0) green:(175/255.0) blue:(0/255.0) alpha:1.0f] range:NSMakeRange(9, signalStatusStrByReceivedRtpRate.length - 9)];
            
            
            receivedRtpCount = 0.0f;
            sentRtpCount = 0.0f;
            return signalStatusStrByReceivedRtpRate;
        }
        */
        
        
        if ([IDCallManager sharedInstance].currentCallInfoModel.currentCallState == CallResponseType_VOICE_CALL_HOLD || [IDCallManager sharedInstance].currentCallInfoModel.currentCallState == CallResponseType_VOICE_CALL_HOLD_CONFIRMATION) {
            return nil;
        }
        
        
        
        if (signalStatusPercentageByReceivedRtpRate >= 80.0) {
            signalStatusStrByReceivedRtpRate = [[[NSMutableAttributedString alloc] initWithString:@"Network: Excellent"] autorelease];
            [IDCallManager sharedInstance].currentCallInfoModel.networkStrength = NetworkStrength_Excellent;
            [signalStatusStrByReceivedRtpRate addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:(40/255.0) green:(40/255.0) blue:(40/255.0) alpha:0.8f] range:NSMakeRange(0, 8)];
            [signalStatusStrByReceivedRtpRate addAttribute:NSForegroundColorAttributeName value:[UIColor greenColor] range:NSMakeRange(9, signalStatusStrByReceivedRtpRate.length - 9)];
        }
        else if ((signalStatusPercentageByReceivedRtpRate >= 65.0) && (signalStatusPercentageByReceivedRtpRate < 80.0)) {
            signalStatusStrByReceivedRtpRate = [[[NSMutableAttributedString alloc] initWithString:@"Network: Good     "] autorelease];
            [IDCallManager sharedInstance].currentCallInfoModel.networkStrength = NetworkStrength_Good;
            [signalStatusStrByReceivedRtpRate addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:(40/255.0) green:(40/255.0) blue:(40/255.0) alpha:0.8f] range:NSMakeRange(0, 8)];
            [signalStatusStrByReceivedRtpRate addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:(0/255.0) green:(205/255.0) blue:(0/255.0) alpha:1.0f] range:NSMakeRange(9, signalStatusStrByReceivedRtpRate.length - 9)];
        }
        else if ((signalStatusPercentageByReceivedRtpRate >= 50.0) && (signalStatusPercentageByReceivedRtpRate < 65.0)) {
            signalStatusStrByReceivedRtpRate = [[[NSMutableAttributedString alloc] initWithString:@"Network: Average  "] autorelease];
            [IDCallManager sharedInstance].currentCallInfoModel.networkStrength = NetworkStrength_Average;
            [signalStatusStrByReceivedRtpRate addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:(40/255.0) green:(40/255.0) blue:(40/255.0) alpha:0.8f] range:NSMakeRange(0, 8)];
            [signalStatusStrByReceivedRtpRate addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:(255/255.0) green:(175/255.0) blue:(0/255.0) alpha:1.0f] range:NSMakeRange(9, signalStatusStrByReceivedRtpRate.length - 9)];
        }
        else if ((signalStatusPercentageByReceivedRtpRate >= 10.0) && (signalStatusPercentageByReceivedRtpRate < 50.0)) {
            signalStatusStrByReceivedRtpRate = [[[NSMutableAttributedString alloc] initWithString:@"Network: Poor     "] autorelease];
            [IDCallManager sharedInstance].currentCallInfoModel.networkStrength = NetworkStrength_Poor;
            [signalStatusStrByReceivedRtpRate addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:(40/255.0) green:(40/255.0) blue:(40/255.0) alpha:0.8f] range:NSMakeRange(0, 8)];
            [signalStatusStrByReceivedRtpRate addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(9, signalStatusStrByReceivedRtpRate.length - 9)];
        }
        else if (signalStatusPercentageByReceivedRtpRate < 10.0) {
            signalStatusStrByReceivedRtpRate = [[[NSMutableAttributedString alloc] initWithString:@"Network: Reconnecting..."] autorelease];
            [IDCallManager sharedInstance].currentCallInfoModel.networkStrength = NetworkStrength_Poor;
            [signalStatusStrByReceivedRtpRate addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:(40/255.0) green:(40/255.0) blue:(40/255.0) alpha:0.8f] range:NSMakeRange(0, 8)];
            [signalStatusStrByReceivedRtpRate addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(9, signalStatusStrByReceivedRtpRate.length - 9)];
        }
    } else {
        //if Internet is not available
        signalStatusStrByReceivedRtpRate = [[[NSMutableAttributedString alloc] initWithString:@"Network: Not Reachable. Reconnecting..."] autorelease];
        [IDCallManager sharedInstance].currentCallInfoModel.networkStrength = NetworkStrength_NotReachable;
        [signalStatusStrByReceivedRtpRate addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:(40/255.0) green:(40/255.0) blue:(40/255.0) alpha:0.8f] range:NSMakeRange(0, 8)];
        [signalStatusStrByReceivedRtpRate addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(9, signalStatusStrByReceivedRtpRate.length - 9)];
    }
    
    
    receivedRtpCount = 0.0f;
    sentRtpCount = 0.0f;
    
    return signalStatusStrByReceivedRtpRate;
}

//- (NSAttributedString *) getSignalStatusStringByReceivedRtpRate
//{
//    NSMutableAttributedString *attrStr = [[[NSMutableAttributedString alloc] initWithAttributedString:self.signalStatusStrByReceivedRtpRate] autorelease];
//    return attrStr;
//}
//
//- (NSAttributedString *) getInstantSignalStatusStringByReceivedRtpRate
//{
//    [self calculateSignalStrengthByReceivedRtpRate];
//    NSMutableAttributedString *attrStr = [[[NSMutableAttributedString alloc] initWithAttributedString:self.signalStatusStrByReceivedRtpRate] autorelease];
//    return attrStr;
//}


- (void) loadSystemAudioFileList {
    self.systemAudioFileList = [[[NSMutableArray alloc] init] autorelease];
    
    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    NSURL *directoryURL = [NSURL URLWithString:@"/System/Library/Audio/UISounds"];
    NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
    
    NSDirectoryEnumerator *enumerator = [fileManager
                                         enumeratorAtURL:directoryURL
                                         includingPropertiesForKeys:keys
                                         options:0
                                         errorHandler:^(NSURL *url, NSError *error) {
                                             // Handle the error.
                                             // Return YES if the enumeration should continue after the error.
                                             return YES;
                                         }];
    
    for (NSURL *url in enumerator) {
        NSError *error;
        NSNumber *isDirectory = nil;
        if (! [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
            // handle error
        }
        else if (! [isDirectory boolValue]) {
            [self.systemAudioFileList addObject:url];
        }
    }
}

- (void) playSystemSound:(SystemSound) systemSound {
    
    long soundId;
    
    switch (systemSound) {
        case SystemSound_Busy:
            soundId = 0;
            break;
        case SystemSound_Error:
            soundId = 50;
            break;
            
        default:
            soundId = 0;
            break;
    }
    
    [self AudioSwitchToDefaultHardware]; // Swtch sound to microphone.
    
    SystemSoundID systemSoundID;
    AudioServicesCreateSystemSoundID(( CFURLRef)[self.systemAudioFileList objectAtIndex:soundId],&systemSoundID);
    AudioServicesPlaySystemSound(systemSoundID);
    
    //    NSLog(@"systemSoundID: %ld",(long)systemSoundID);
    //    NSLog(@"soundId: %ld",(long)soundId);
}



- (void) playCallModuleTone:(CallModuleTone) callModuleTone
{
    NSBundle* bundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"RingCallModuleResource" withExtension:@"bundle"]];
    NSString* filePath = @"";
    
    switch (callModuleTone) {
        case CallModuleTone_None:
            filePath = @"";
            break;
        case CallModuleTone_Busy:
            filePath = @"";
            break;
        case CallModuleTone_Error:
            filePath = @"";
            break;
        case CallModuleTone_Waiting:
            //            filePath = [bundle pathForResource:@"call_waiting_01" ofType:@"mp3"];
            filePath = [bundle pathForResource:@"off" ofType:@"wav"];
            break;
            
        default:
            break;
    }
    
    NSURL* url = [NSURL URLWithString:filePath];
    SystemSoundID systemSoundID;
    NSError *setCategoryError = nil;
    if (![[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&setCategoryError]) {
#if STATE_DEVELOPMENT
        NSLog(@"Faild to play SystemSoundID...");
#endif
    }
    
    if(!IS_IPHONE) {
        //        UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
        //        AudioSessionSetProperty (kAudioSessionProperty_AudioCategory, sizeof (sessionCategory),  &sessionCategory);
        BOOL success = [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&setCategoryError];
        if(!success)
        {
#if STATE_DEVELOPMENT
            NSLog(@"error doing outputaudioportoverride - %@", [setCategoryError localizedDescription]);
#endif
        }
    } else {
        if (isSpeakerEnabled) {
            [[RingCallAudioManager sharedInstance] AudioForceOutputToBuiltInSpeakers];
        } else {
            [[RingCallAudioManager sharedInstance] AudioSwitchToDefaultHardware];
        }
    }
    
    AudioServicesCreateSystemSoundID(( CFURLRef)url, &systemSoundID);
    AudioServicesPlaySystemSound(systemSoundID);
    
    [self AudioInitialiseForNewCall];
}



- (void) createAndGetPCMfromotherFormat {
    
    NSString *callHoldToneFilePath = [RESOURCE_BUNDLE pathForResource:@"ringtone-8000" ofType:@"wav"];
    NSFileHandle *callHoldToneFile = [NSFileHandle fileHandleForReadingAtPath:callHoldToneFilePath];
    if (callHoldToneFile == nil)
    {
#if STATE_DEVELOPMENT
        NSLog(@"Failed to open file");
#endif
    }
    
    NSMutableData *callHoldToneNSData;
    callHoldToneNSData = [NSMutableData dataWithContentsOfFile:callHoldToneFilePath];
    //    unsigned long G711callHoldToneDataLength = [callHoldToneNSData length];
    //    const char* callHoldToneFileBytes = (const char*)[callHoldToneNSData bytes];
    NSData *dataWithoutHeader = [callHoldToneNSData subdataWithRange:NSMakeRange(60, callHoldToneNSData.length-60)];
    
    // Use GCD's background queue
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        // Generate the file path
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",RING_TONE_RAW_FILE_NAME, RING_TONE_RAW_FILE_TYPE]];
        
        // Save it into file system
        [dataWithoutHeader writeToFile:dataPath atomically:YES];
    });

}
FILE *fp2;
bool isFpOpen = false;

void WriteToFileV(byte *pData, int iLen)
{
    
    
    if(isFpOpen == false)
    {
        isFpOpen = true;
        NSFileHandle *handle;
        NSArray *Docpaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [Docpaths objectAtIndex:0];
        NSString *filePathyuv = [documentsDirectory stringByAppendingPathComponent:@"AudioSecondAttempt33.g729"];
        handle = [NSFileHandle fileHandleForUpdatingAtPath:filePathyuv];
        char *filePathcharyuv = (char*)[filePathyuv UTF8String];
        fp2 = fopen(filePathcharyuv, "wb");
    }
    
    printf("Writing to File\n");
    fwrite(pData, 1, iLen, fp2);
}


/**
 Clean up.
 */
- (void) dealloc
{
    AudioUnitUninitialize(audioUnit);
    free(tempBuffer.mData);
    self.pcmRcordedData = nil;
    self.silenceTonePlayer = nil;
    self.silenceSwitchDetector = nil;
    self.audioPlayer = nil;
    self.imAudioPlayer = nil;
    self.recordedFileUrlForIM = nil;
    self.recordedFinalDataForIM = nil;
    self.systemAudioFileList = nil;
    [super dealloc];
}

@end
