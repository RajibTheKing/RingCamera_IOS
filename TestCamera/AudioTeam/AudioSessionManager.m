//
//  AudioSessionManager.m
//
//  Copyright 2011 Jawbone Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <AudioToolbox/AudioToolbox.h>

#import "AudioSessionManager.h"

@interface AudioSessionManager () {	// private
	NSString	*mMode;
    
	BOOL		 mBluetoothDeviceAvailable;
	BOOL		 mHeadsetDeviceAvailable;
    
	NSArray		*mAvailableAudioDevices;
}

@property (nonatomic, assign)		BOOL			 bluetoothDeviceAvailable;
@property (nonatomic, assign)		BOOL			 headsetDeviceAvailable;
@property (nonatomic, strong)		NSArray			*availableAudioDevices;

@end

NSString *kAudioSessionManagerMode_Record       = @"AudioSessionManagerMode_Record";
NSString *kAudioSessionManagerMode_Playback     = @"AudioSessionManagerMode_Playback";

NSString *kAudioSessionManagerDevice_Headset    = @"AudioSessionManagerDevice_Headset";
NSString *kAudioSessionManagerDevice_Bluetooth  = @"AudioSessionManagerDevice_Bluetooth";
NSString *kAudioSessionManagerDevice_Phone      = @"AudioSessionManagerDevice_Phone";
NSString *kAudioSessionManagerDevice_Speaker    = @"AudioSessionManagerDevice_Speaker";

// use normal logging if custom macros don't exist
#ifndef NSLogWarn
    #define NSLogWarn NSLog
#endif

#ifndef NSLogError
    #define NSLogError NSLog
#endif

#ifndef NSLogDebug
    #define LOG_LEVEL 3
    #define NSLogDebug(frmt, ...)    do{ if(LOG_LEVEL >= 4) NSLog((frmt), ##__VA_ARGS__); } while(0)
#endif

@implementation AudioSessionManager

@synthesize headsetDeviceAvailable      = mHeadsetDeviceAvailable;
@synthesize bluetoothDeviceAvailable    = mBluetoothDeviceAvailable;
@synthesize availableAudioDevices       = mAvailableAudioDevices;

#pragma mark -
#pragma mark Singleton

#pragma mark - Singleton

#define SYNTHESIZE_SINGLETON_FOR_CLASS(classname) \
+ (classname*)sharedInstance { \
static classname* __sharedInstance; \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
__sharedInstance = [[classname alloc] init]; \
}); \
return __sharedInstance; \
}

SYNTHESIZE_SINGLETON_FOR_CLASS(AudioSessionManager);

- (id)init
{
	if ((self = [super init])) {
		mMode = kAudioSessionManagerMode_Playback;
	}
    
	return self;
}

#pragma mark private functions

- (BOOL)configureAudioSessionWithDesiredAudioRoute:(NSString *)desiredAudioRoute
{
	NSLogDebug(@"current mode: %@", mMode);
	
	AVAudioSession *audioSession = [AVAudioSession sharedInstance];
	NSError *err;
	
	// close down our current session...
	[audioSession setActive:NO error:nil];
	
    if ((mMode == kAudioSessionManagerMode_Record) && !audioSession.inputAvailable) {
		NSLogWarn(@"device does not support recording");
		return NO;
    }
    
    /*
     * Need to always use AVAudioSessionCategoryPlayAndRecord to redirect output audio per
     * the "Audio Session Programming Guide", so we only use AVAudioSessionCategoryPlayback when
     * !inputIsAvailable - which should only apply to iPod Touches without external mics.
     */
    NSString *audioCat = ((mMode == kAudioSessionManagerMode_Playback) && !audioSession.inputAvailable) ?
    AVAudioSessionCategoryPlayback : AVAudioSessionCategoryPlayAndRecord;
    
	if (![audioSession setCategory:audioCat withOptions:((desiredAudioRoute == kAudioSessionManagerDevice_Bluetooth) ? AVAudioSessionCategoryOptionAllowBluetooth : 0) error:&err]) {
		NSLogWarn(@"unable to set audioSession category: %@", err);
		return NO;
	}
	
    // Set our session to active...
	if (![audioSession setActive:YES error:&err]) {
		NSLogWarn(@"unable to set audio session active: %@", err);
		return NO;
	}
    
	if (desiredAudioRoute == kAudioSessionManagerDevice_Speaker) {
        // replace AudiosessionSetProperty (deprecated from iOS7) with AVAudioSession overrideOutputAudioPort
		[audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&err];
	}
	
	// Display our current route...
	NSLogDebug(@"current route: %@", self.audioRoute);
	
	return YES;
}

- (BOOL)detectAvailableDevices
{
	// called on startup to initialize the devices that are available...
	NSLogDebug(@"detectAvailableDevices");
	
	AVAudioSession *audioSession = [AVAudioSession sharedInstance];
	NSError *err;
	
	// close down our current session...
	[audioSession setActive:NO error:nil];
    
    // start a new audio session. Without activation, the default route will always be (inputs: null, outputs: Speaker)
    [audioSession setActive:YES error:nil];
    
	// Open a session and see what our default is...
	if (![audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth error:&err]) {
		NSLogWarn(@"unable to set audioSession category: %@", err);
		return NO;
	}
	
	// Check for a wired headset...
    AVAudioSessionRouteDescription *currentRoute = [audioSession currentRoute];
    for (AVAudioSessionPortDescription *output in currentRoute.outputs) {
        if ([[output portType] isEqualToString:AVAudioSessionPortHeadphones]) {
            self.headsetDeviceAvailable = YES;
        } else if ([self isBluetoothDevice:[output portType]]) {
            self.bluetoothDeviceAvailable = YES;
        }
    }
    // In case both headphones and bluetooth are connected, detect bluetooth by inputs
    // Condition: iOS7 and Bluetooth input available
    if ([audioSession respondsToSelector:@selector(availableInputs)]) {
        for (AVAudioSessionPortDescription *input in [audioSession availableInputs]){
            if ([self isBluetoothDevice:[input portType]]){
                self.bluetoothDeviceAvailable = YES;
                break;
            }
        }
    }
    
	if (self.headsetDeviceAvailable) {
		NSLogDebug(@"Found Headset");
    }
	
	if (self.bluetoothDeviceAvailable) {
		NSLogDebug(@"Found Bluetooth");
    }
	
	return YES;
}

- (void)currentRouteChanged:(NSNotification *)notification
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    NSInteger changeReason = [[notification.userInfo objectForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    
    AVAudioSessionRouteDescription *oldRoute = [notification.userInfo objectForKey:AVAudioSessionRouteChangePreviousRouteKey];
    NSString *oldOutput = [[oldRoute.outputs objectAtIndex:0] portType];
    AVAudioSessionRouteDescription *newRoute = [audioSession currentRoute];
    NSString *newOutput = [[newRoute.outputs objectAtIndex:0] portType];
    
    switch (changeReason) {
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
        {
            if ([oldOutput isEqualToString:AVAudioSessionPortHeadphones]) {
                
                self.headsetDeviceAvailable = NO;
                // Special Scenario:
                // when headphones are plugged in before the call and plugged out during the call
                // route will change to {input: MicrophoneBuiltIn, output: Receiver}
                // manually refresh session and support all devices again.
                [audioSession setActive:NO error:nil];
                [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth error:nil];
                [audioSession setMode:AVAudioSessionModeVoiceChat error:nil];
                [audioSession setActive:YES error:nil];
                
                
            } else if ([self isBluetoothDevice:oldOutput]) {
                
                BOOL showBluetooth = NO;
                // Additional checking for iOS7 devices (more accurate)
                // when multiple blutooth devices connected, one is no longer available does not mean no bluetooth available
                if ([audioSession respondsToSelector:@selector(availableInputs)]) {
                    NSArray *inputs = [audioSession availableInputs];
                    for (AVAudioSessionPortDescription *input in inputs){
                        if ([self isBluetoothDevice:[input portType]]){
                            showBluetooth = YES;
                            break;
                        }
                    }
                }
                if (!showBluetooth) {
                    self.bluetoothDeviceAvailable = NO;
                }
            }
        }
            break;
            
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
        {
            if ([self isBluetoothDevice:newOutput]) {
                self.bluetoothDeviceAvailable = YES;
            } else if ([newOutput isEqualToString:AVAudioSessionPortHeadphones]) {
                self.headsetDeviceAvailable = YES;
            }
        }
            break;
            
        case AVAudioSessionRouteChangeReasonOverride:
        {
            if ([self isBluetoothDevice:oldOutput]) {
                if ([audioSession respondsToSelector:@selector(availableInputs)]) {
                    BOOL showBluetooth = NO;
                    NSArray *inputs = [audioSession availableInputs];
                    for (AVAudioSessionPortDescription *input in inputs){
                        if ([self isBluetoothDevice:[input portType]]){
                            showBluetooth = YES;
                            break;
                        }
                    }
                    if (!showBluetooth) {
                        self.bluetoothDeviceAvailable = NO;
                    }
                } else if ([newOutput isEqualToString:AVAudioSessionPortBuiltInReceiver]) {
                    
                    self.bluetoothDeviceAvailable = NO;
                }
            }
        }
            break;
            
        default:
            break;
    }
}

- (BOOL)isBluetoothDevice:(NSString*)portType {
    
    return ([portType isEqualToString:AVAudioSessionPortBluetoothA2DP] ||
            [portType isEqualToString:AVAudioSessionPortBluetoothHFP]);
}

#pragma mark public methods

- (void)start
{
	[self detectAvailableDevices];
	
	[self configureAudioSessionWithDesiredAudioRoute:kAudioSessionManagerDevice_Bluetooth];
	
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(currentRouteChanged:)
                                                 name:AVAudioSessionRouteChangeNotification object:nil];
}

#pragma mark public methods/properties

- (BOOL)changeMode:(NSString *)value
{
	if (mMode == value)
		return YES;
	
	mMode = value;
	
	return [self configureAudioSessionWithDesiredAudioRoute:kAudioSessionManagerDevice_Bluetooth];
}

- (NSString *)audioRoute
{
	AVAudioSessionRouteDescription *currentRoute = [[AVAudioSession sharedInstance] currentRoute];
    NSString *output = [[currentRoute.outputs objectAtIndex:0] portType];
    
    if ([output isEqualToString:AVAudioSessionPortBuiltInReceiver]) {
        return kAudioSessionManagerDevice_Phone;
    } else if ([output isEqualToString:AVAudioSessionPortBuiltInSpeaker]) {
        return kAudioSessionManagerDevice_Speaker;
    } else if ([output isEqualToString:AVAudioSessionPortHeadphones]) {
        return kAudioSessionManagerDevice_Headset;
    } else if ([self isBluetoothDevice:output]) {
        return kAudioSessionManagerDevice_Bluetooth;
    } else {
        return @"Unknown Device";
    }
}

- (void)setBluetoothDeviceAvailable:(BOOL)value
{
	if (mBluetoothDeviceAvailable == value) {
		return;
    }
	
	mBluetoothDeviceAvailable = value;
	
	self.availableAudioDevices = nil;
}

- (void)setHeadsetDeviceAvailable:(BOOL)value
{
	if (mHeadsetDeviceAvailable == value) {
		return;
    }
	
	mHeadsetDeviceAvailable = value;
	
	self.availableAudioDevices = nil;
}

- (void)setAudioRoute:(NSString *)audioRoute
{
	if ([self audioRoute] == audioRoute) {
		return;
    }
	
	[self configureAudioSessionWithDesiredAudioRoute:audioRoute];
}

- (BOOL)phoneDeviceAvailable
{
	return YES;
}

- (BOOL)speakerDeviceAvailable
{
	return YES;
}

- (NSArray *)availableAudioDevices
{
	if (!mAvailableAudioDevices) {
		NSMutableArray *devices = [[[NSMutableArray alloc] initWithCapacity:4] autorelease];
		
		if (self.bluetoothDeviceAvailable)
			[devices addObject:kAudioSessionManagerDevice_Bluetooth];
        
		if (self.headsetDeviceAvailable)
			[devices addObject:kAudioSessionManagerDevice_Headset];
        
		if (self.speakerDeviceAvailable)
			[devices addObject:kAudioSessionManagerDevice_Speaker];
        
		if (self.phoneDeviceAvailable)
			[devices addObject:kAudioSessionManagerDevice_Phone];
		
		self.availableAudioDevices = devices;
	}
	
	return mAvailableAudioDevices;
}

@end

