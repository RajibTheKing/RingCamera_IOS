//
//  VoipUtils.h
//  ringID
//
//  Created by Partho Biswas on 11/3/14.
//
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>


@interface VoipUtils : NSObject

void RUN_ON_UI_THREAD(dispatch_block_t block);

+ (void) popModalsToRootFrom:(UIViewController*)aVc;
+ (void) popModalsFrom:(UIViewController*)aVc popCount:(int)count;
+ (void) writeToTextFile:(id)txtToWrite;
+ (NSDictionary *) dictionaryWithPropertiesOfObject:(id)obj;

+ (BOOL) isInternetReachable;
+ (BOOL) isInternConnectionAvailable;
+ (int) getUniqueKey:(NSData *)data startIndex:(int)start_index;

+ (UIViewController*) getTopMostViewController;

+ (bool) isOnCDMAorGSMCall;
+ (bool) isOnRingCall;

#pragma mark - CALL MODULE RELATED KEYS
extern NSString *KEY_CALL_ID;
extern NSString *KEY_CALL_INITIATION_TIME;
extern int TYPE_FREE_CALL_FIRST;
extern int TYPE_PUSH_ACK;
extern int TYPE_CALL_LOG;
extern int TYPE_CALL_LOG_SINGLE_FRIEND;


// The following variables are only fro CallModule. Comment this out to avoid redefinition of global variable if the module source is in main project. Uncomment the following block if the call framework is saparate.

extern NSString *KEY_ACTION_CALL;
extern NSString *KEY_SUCCESS_CALL;
extern NSString *KEY_PRESENCE_CALL;
extern NSString *KEY_SWITCH_IP_CALL;
extern NSString *KEY_SWITCH_PORT_CALL;
extern NSString *KEY_APP_TYPE_CALL;
extern NSString *KEY_DEVICE_CALL;
extern const NSString *KEY_RINGID_DEVICE_TOKEN;
extern NSString *KEY_FRIEND_ID_CALL;
extern NSString *KEY_PACKET_ID_CALL;
extern NSString *KEY_SESSION_ID_CALL;
extern NSString *KEY_FRIEND_NAME;
extern NSString *KEY_FRIEND_IDC;
extern NSString *KEY_FRIEND_CONNECT_WITH;
extern NSString *KEY_FRIEND_MOOD;
extern NSString *KEY_FRIEND_RC;
extern NSString *KEY_FRIEND_MESSAGE;
extern NSString *KEY_CALL_MEDIA_TYPE;



#define CALL_SOCKET_ERROR_DOMAIN @"ringid.com.callsocketerror.domain"

#define CALL_SOCKET_INVALID_IP_ADDRESS_ERROR       NSLocalizedString(@"Invalid IP Address", @"IP Address cannot be nil")
#define CALL_SOCKET_INVALID_PORT_ERROR       NSLocalizedString(@"Invalid Port", @"Port cannot be nil")
#define CALL_SOCKET_INVALID_KEY_ERROR       NSLocalizedString(@"Invalid key", @"packet ID cannot be nil")



#define RING_BACK_TONE_FILE_NAME  @"RingBack-5.0-2"
#define RING_BACK_TONE_FILE_TYPE  @"729"

#define RING_TONE_FILE_FULL_NAME  @"ringing.caf"
#define RING_TONE_FILE_NAME  @"ringing"
#define RING_TONE_FILE_TYPE  @"caf"
#define RING_TONE_FILE_PLAY_LOOP  1 // 1 means, the file will run 2 times.

#define SILENCE_TONE_FILE_NAME  @"silence-10sec"
#define SILENCE_TONE_FILE_TYPE  @"mp3"
//#define SILENCE_TONE_FILE_FULL_NAME  @"ring_splash_tone.mp3" // It's for testing purpose.

#define SILENCE_TONE_FILE_PLAY_LOOP  -1 // -1 means, the file play forever.

#define RTP_SENDING_TIME_INTERVAL  0.1 // 0.1 means 100 milisecond
#define NET_STRENGHT_CHECK_TIME_INTERVAL  5 // 1 means 1 milisecond

#define NUMBER_OF_MAX_GARBAGE 5

#define Received_TPCircularBuffer_SIZE 20000
#define Recorded_TPCircularBuffer_SIZE 10000

//#define CALL_DROP_INDICATOR_COUNTER_TIME  15 // if we don't get RTP for CALL_DROP_INDICATOR_COUNTER_TIME second then the call will drop


// Audio settings.
#define AUDIO_SAMPLE_RATE 8000
#define AUDIO_FRAMES_PER_PACKET 1
#define AUDIO_CHANNELS_PER_FRAME 1
#define AUDIO_BITS_PER_CHANNEL 16 // as known as bit depth.
#define AUDIO_BYTES_PER_PACKET 2
#define AUDIO_BYTES_PER_FRAME 2


// Audio packet settings.
#define AUDIO_MINIMUM_PACKET_LENGTH 1600 // after encoding in G729.
#define AUDIO_MAXIMUM_PACKET_LENGTH 3040 // after encoding in G729.
#define RECEIVE_AUDIO_MINIMUM_PACKET_LENGTH 100

#define AUDIO_FIXED_PACKET_LENGTH 1920
#define VIBRATE_ON_TINGTONE YES

extern const NSString *IS_FROM_REMOTE_PUSH;
extern const NSString *IS_FROM_LOCAL_PUSH;
//const NSString *KEY_PACKET_ID_FROM_SERVER = @"pckFs";
extern const NSString *KEY_CALL_TIME;
extern const NSString *KEY_CALL_DURATION;
extern const NSString *KEY_CALL_TYPE;
extern const NSString *KEY_STATUS_CODE;

@end
