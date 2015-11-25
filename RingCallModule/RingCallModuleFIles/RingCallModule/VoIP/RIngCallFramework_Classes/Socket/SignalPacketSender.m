//
//  SignalPacketSender.m
//  CallFrameworkApp
//
//  Created by Nagib Bin Azad on 2/26/15.
//  Copyright (c) 2015 Ring Inc. All rights reserved.
//

#import "SignalPacketSender.h"

#import "VoipUtils.h"


typedef NS_ENUM(NSInteger, SocketErrorCode)
{
    SocketErrorInvalidIP = 0,
    SocketErrorInvalidPort,
    SocketErrorInvalidKey
};

@interface SignalPacketSender()<CallPacketSenderDelegate>

@property (nonatomic, copy) void (^successBlock)(BOOL success);
@property (nonatomic, copy) void (^failureBlock)(NSError *error);

@end

@implementation SignalPacketSender



@synthesize sentPacketMap;


+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance = nil;
    dispatch_once(&once, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    
    
    return sharedInstance;
}

-(id) init
{
    self = [super init];
    
    if (self)
    {
        self.sentPacketMap = [[[NSMutableDictionary alloc] init] autorelease];
    }
    
    return self;
}

- (void)sendPacket:(SignalPacket *)packet forPacketType:(RingCallPacketType) packetType onSuccess:(void (^)(BOOL finished))success onFailure:(void (^)(NSError *error))failure
{
    BOOL sending_success = [self sendPacket:packet packetType:packetType];
    if (sending_success) success(YES);
    else failure([self errorWithCode:(packet.ipAddress == nil ? SocketErrorInvalidIP : (packet.port == 0 ? SocketErrorInvalidPort : SocketErrorInvalidKey))]);
    
    
}

- (void)stopSendingPacketForKey:(NSString *)key onSuccess:(void (^)(BOOL finished))success onFailure:(void (^)(NSError *error))failure
{
    
    BOOL stop_success = [self stopSendingPacketForKey:key];
    if (stop_success) success(YES);
    else failure([self errorWithCode:SocketErrorInvalidKey]);
    
}

- (void)stopSendingPacketForCallerID:(NSString *)callerID withSignalType:(CallResponseType)signalType onSuccess:(void (^)(BOOL finished))success onFailure:(void (^)(NSError *error))failure{

    BOOL stop_success = [self stopSendingPacketForKey:[NSString stringWithFormat:@"%@_%d",callerID,signalType]];
    if (stop_success) success(YES);
    else failure([self errorWithCode:SocketErrorInvalidKey]);

}

- (BOOL)sendPacket:(SignalPacket *)packet packetType:(RingCallPacketType) packetType
{
    BOOL success = NO;
    if (packet.ipAddress == nil || packet.port == 0 || packet.timerIdentifier == nil)
    {
        success = NO;
    }
    else
    {
        
        //Send data to server
        CallPacketSenderWithTimer *packetSenderWithTimer = [CallPacketSenderWithTimer initWithPacket:packet];
        packetSenderWithTimer.delegate = self;
        packetSenderWithTimer.packetType = packetType;
        [packetSenderWithTimer startSending];
        [self.sentPacketMap setObject:packetSenderWithTimer forKey:packet.timerIdentifier];
        success = YES;
    }
    return success;

}


- (BOOL)stopSendingPacketForKey:(NSString *)key
{
    BOOL success = NO;
    if (key == nil) {
        success = NO;
    }
    else
    {
        CallPacketSenderWithTimer *packetSenderWithTimer = [self.sentPacketMap objectForKey:key];
        if (packetSenderWithTimer == nil)
        {
            success = NO;
        }
        else
        {
            success = YES;
            [packetSenderWithTimer stopSending];
            [self.sentPacketMap removeObjectForKey:key];
        }
    }
    return success;
}
#pragma mark - Error Handling
- (NSError *)errorWithCode:(SocketErrorCode)errorCode
{
    NSString *errorString = @"";
    
    switch (errorCode)
    {
        case SocketErrorInvalidIP:
            
            errorString = CALL_SOCKET_INVALID_IP_ADDRESS_ERROR;

            break;
            
        case SocketErrorInvalidPort:
            
            errorString = CALL_SOCKET_INVALID_PORT_ERROR;
            
            break;
            
        case SocketErrorInvalidKey:
            
            errorString = CALL_SOCKET_INVALID_KEY_ERROR;
            
            break;
            
           }
    
    NSError *error = nil;
    
    if (errorString) {
        error = [NSError errorWithDomain:CALL_SOCKET_ERROR_DOMAIN code:errorCode userInfo:@{NSLocalizedDescriptionKey:errorString}];
    }
    
    return error;
}
#pragma mark - CallPacketSenderDelegate

- (void)didFinishSendingPacketWithKey:(NSString *)key
{
    [self.sentPacketMap removeObjectForKey:key];
}

#pragma mark - Life Cycle

/// Ensure user that never called
-(void)dealloc
{
    // I'm never called!
    [super dealloc];
}

/// Ensure user that retain count never increased
- (id)retain {
    return self;
}

/// Replace the retain counter so we can never release this object.
- (NSUInteger)retainCount {
    return NSUIntegerMax;
}

// This function is empty, as we don't want to let the user release this object.
- (oneway void)release {
    
}

//Do nothing, other than return the shared instance - as this is expected from autorelease.
- (id)autorelease {
    return self;
}

@end
