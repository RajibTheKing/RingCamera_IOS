//
//  RIConnectivityManager.h
//  ringID
//
//  Created by Nagib Bin Azad on 9/7/15.
//  Copyright (c) 2015 IPVision Canada Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RingCommon/NSMutableArray+QueueAdditions.h>
#import "RingCallAudioManager.h"

typedef NS_ENUM(NSUInteger, RIConnectivityEventType)
{
    RIConnectivityEventType_None = 0,
    RIConnectivityEventType_BEST_INTERFACE_DETECTED = 100,
    RIConnectivityEventType_FIREWALL_DETECTED,
    RIConnectivityEventType_NETWORK_PROBLEM,
    RIConnectivityEventType_INTERFACE_CHANGED,
    RIConnectivityEventType_P2P_COMMUNICATION_ESTABLISHED,
    RIConnectivityEventType_P2P_COMMUNICATION_FAILED,
    RIConnectivityEventType_RELAY_COMMUNICATION_ESTABLISHED,
    RIConnectivityEventType_DATA_RECEIVED
};

@interface RIConnectivityManager : NSObject

@property (nonatomic, retain) NSMutableArray *queue_packet;

+(RIConnectivityManager *)sharedInstance;


-(BOOL)init:(NSString *) friendID sourceLogFilePath:(NSString *) sLogFilePath logLevel:(int) logLevel;
-(BOOL)initializeLibrary:(NSString *) friendID;
-(int)createSession:(NSString *) friendID mediaType:(int) sMedia relayServerIP:(NSString *) relayServerIP relayServerPort:(int)relayServerPort;
-(BOOL)closeSession:(NSString *) friendID mediaType:(int) sMedia;
-(void)setRelayServerInformation:(NSString *) friendID mediaType:(int) sMedia relayServerIP:(NSString *) relayServerIP relayServerPort:(int)relayServerPort;
-(void)startP2PCall:(NSString *) friendID mediaType:(int) sMedia isCaller:(bool)isCaller;
-(void)sendTo:(NSData *)data friendID:(NSString *) friendID destinationIPaddress:(NSString *)dstIPaddr destinationPort:(int)dstPort mediaType:(int)mediaType;
- (int)send:(NSData *)data friendId:(NSString *) frinedID mediaType:(int)mediaType;
- (void)releaseLib;
- (BOOL)setAuthenticationServerWith:(NSString *)authIp withPort:(int)port withSessionId:(NSString *)appSessionId;

- (void)InterfaceChanged;

@end
