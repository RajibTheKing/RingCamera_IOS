//
//  RIConnectivityManager.m
//  ringID
//
//  Created by Nagib Bin Azad on 9/7/15.
//  Copyright (c) 2015 IPVision Canada Inc. All rights reserved.
//

#import "RIConnectivityManager.h"
//#import "ObjectiveCInterFace.h"
//#import <IPVConnectivityDllStatic/ObjectiveCInterFace.h>
//#import "../header/ObjectiveCInterFace.h"
#import "RIConnectivityAdapter.h"
#import "IDCallManager.h"
#import "CallPacketProcessor.h"
#import "IDVideoOperation.h"

@implementation RIConnectivityManager

+(RIConnectivityManager *)sharedInstance
{
    static id sharedInstance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[RIConnectivityManager alloc] init];
    });
    
    
    return sharedInstance;
}

-(id)init
{
    if (self = [super init])
    {
        self.queue_packet = [[[NSMutableArray alloc] init] autorelease];
        [CallPacketProcessor sharedInstance]; //different thread
    }
    return self;
}

-(BOOL)init:(NSString *) friendID sourceLogFilePath:(NSString *) sLogFilePath logLevel:(int) logLevel
{
    return [RIConnectivityAdapter init:[friendID longLongValue] sourceLogFilePath:sLogFilePath logLevel:logLevel];
}

-(BOOL)initializeLibrary:(NSString *) friendID
{
    return [RIConnectivityAdapter initializeLibrary:[friendID longLongValue]];
}

-(int)createSession:(NSString *) friendID mediaType:(int) sMedia relayServerIP:(NSString *) relayServerIP relayServerPort:(int)relayServerPort
{
    return [RIConnectivityAdapter createSession:[friendID longLongValue] mediaType:(MediaType)sMedia relayServerIP:relayServerIP relayServerPort:relayServerPort];
}

-(BOOL)closeSession:(NSString *) friendID mediaType:(int) sMedia
{
    return [RIConnectivityAdapter closeSession:[friendID longLongValue] mediaType:(MediaType)sMedia];
}

-(void)setRelayServerInformation:(NSString *) friendID mediaType:(int) sMedia relayServerIP:(NSString *) relayServerIP relayServerPort:(int)relayServerPort
{
    [RIConnectivityAdapter setRelayServerInformation:[friendID longLongValue] mediaType:(MediaType)sMedia relayServerIPAddress:relayServerIP relayServerPort:relayServerPort];
}

-(void)startP2PCall:(NSString *) friendID mediaType:(int) sMedia isCaller:(bool)isCaller
{
    [RIConnectivityAdapter startP2PCall:[friendID longLongValue] mediaType:(MediaType)sMedia isCaller:isCaller];
}

-(void)sendTo:(NSData *)data friendID:(NSString *) friendID destinationIPaddress:(NSString *)dstIPaddr destinationPort:(int)dstPort mediaType:(int)mediaType
{
    [RIConnectivityAdapter sendTo:[friendID longLongValue] mediaType:(MediaType)mediaType data:data length:(int)data.length destinationAddress:dstIPaddr destinationPort:dstPort];
}

- (int)send:(NSData *)data friendId:(NSString *) frinedID mediaType:(int)mediaType{

    return [RIConnectivityAdapter send:[frinedID longLongValue] mediaType:(MediaType)mediaType data:data length:(int)data.length];
}

-(BOOL)setAuthenticationServerWith:(NSString *)authIp withPort:(int)port withSessionId:(NSString *)appSessionId {

    return [RIConnectivityAdapter setAuthenticationServerWith:authIp withPort:port withSessionId:appSessionId];
}

- (void)releaseLib {
    NSLog(@"releaseLib");
    [RIConnectivityAdapter releaseLib];
}

- (void)InterfaceChanged {
    if (isConnectivityModuleEnabled == 1) {
        NSLog(@"InterfaceChanged: Notified RIConnectivityAdapter");
        [RIConnectivityAdapter InterfaceChanged];
    }
}

void notifyClientMethodIos(int eventType)
{
    NSLog(@"notifyClientMethodIos");
}

void notifyClientMethodForFriendIos(int eventType, IPVLongType friendName, int iMedia)
{
    switch (eventType) {
        case RIConnectivityEventType_P2P_COMMUNICATION_ESTABLISHED:
        {
            NSLog(@"RIConnectivityEventType_P2P_COMMUNICATION_ESTABLISHED");
            if (iMedia == MEDIA_TYPE_VIDEO) {
                [IDVideoOperation sharedManager].sequenceLength = 1000;
            }
            [IDCallManager sharedInstance].currentCallInfoModel.callInfo.connectivityEventType = RIConnectivityEventType_P2P_COMMUNICATION_ESTABLISHED;
            [[IDCallManager sharedInstance] startKeepAliveWithVoiceServer];
            
            NSLog(@"KeepAlive Started");
            
            [[IDCallManager sharedInstance] p2pStatusChanged:RIConnectivityEventType_P2P_COMMUNICATION_ESTABLISHED forMediaType:iMedia];
            
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success!" message:@"P2P call established!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
//            [alert show];

        }
            break;
            
        case RIConnectivityEventType_P2P_COMMUNICATION_FAILED:
        {
            NSLog(@"RIConnectivityEventType_P2P_COMMUNICATION_FAILED");
            if (iMedia == MEDIA_TYPE_VIDEO) {
                [IDVideoOperation sharedManager].sequenceLength = 500;
            }

            [IDCallManager sharedInstance].currentCallInfoModel.callInfo.connectivityEventType = RIConnectivityEventType_P2P_COMMUNICATION_FAILED;
            [[IDCallManager sharedInstance] stopKeepAliveWithVoiceServerForCallID:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.callID];
            
            NSLog(@"KeepAlive Stopped");
            [[IDCallManager sharedInstance] p2pStatusChanged:RIConnectivityEventType_P2P_COMMUNICATION_FAILED forMediaType:iMedia];

//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Faild!" message:@"P2P call failed!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
//            [alert show];
        }
            break;
            
        case RIConnectivityEventType_RELAY_COMMUNICATION_ESTABLISHED:
        {
            NSLog(@"RIConnectivityEventType_RELAY_COMMUNICATION_ESTABLISHED");
            if (iMedia == MEDIA_TYPE_VIDEO) {
                [IDVideoOperation sharedManager].sequenceLength = 500;
            }

            [IDCallManager sharedInstance].currentCallInfoModel.callInfo.connectivityEventType = RIConnectivityEventType_RELAY_COMMUNICATION_ESTABLISHED;
            [[IDCallManager sharedInstance] stopKeepAliveWithVoiceServerForCallID:[IDCallManager sharedInstance].currentCallInfoModel.callInfo.callID];
            
            NSLog(@"KeepAlive Stopped");
            [[IDCallManager sharedInstance] p2pStatusChanged:RIConnectivityEventType_RELAY_COMMUNICATION_ESTABLISHED forMediaType:iMedia];

        }
            break;
            
        case RIConnectivityEventType_BEST_INTERFACE_DETECTED:
        {
            [[IDCallManager sharedInstance] p2pStatusChanged:RIConnectivityEventType_BEST_INTERFACE_DETECTED forMediaType:iMedia];

        }
            break;
        case RIConnectivityEventType_FIREWALL_DETECTED:
        {
            [[IDCallManager sharedInstance] p2pStatusChanged:RIConnectivityEventType_FIREWALL_DETECTED forMediaType:iMedia];

        }
            break;
        case RIConnectivityEventType_NETWORK_PROBLEM:
        {
            [[IDCallManager sharedInstance] p2pStatusChanged:RIConnectivityEventType_NETWORK_PROBLEM forMediaType:iMedia];

        }
            break;
        case RIConnectivityEventType_INTERFACE_CHANGED:
        {
            [[IDCallManager sharedInstance] p2pStatusChanged:RIConnectivityEventType_INTERFACE_CHANGED forMediaType:iMedia];

        }
            break;

        default:
            break;
    }
    
}
void notifyClientMethodWithReceivedIos(int eventType, IPVLongType friendName, int iMedia, int dataLenth, unsigned char data[])
{
    NSData *receivedData = [NSData dataWithBytes:data length:dataLenth];
    if (receivedData != nil) {
        if (iMedia == MEDIA_TYPE_AUDIO) {
            [[RIConnectivityManager sharedInstance].queue_packet push:receivedData];
        }
        else if (iMedia == MEDIA_TYPE_VIDEO)
        {
            [[IDVideoOperation sharedManager] addReceiveVideoDataOnQueue:receivedData];
        }
        else
        {
        //Not defined yet
        }
       //  [[IDCallManager sharedInstance] processCallSignal:receivedData];
    }
}

-(void)dealloc
{
    self.queue_packet = nil;
    [super dealloc];
}
@end
