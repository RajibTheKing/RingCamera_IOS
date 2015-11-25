//
//  IDCallMakePacket.m
//  ringID
//
//  Created by Partho Biswas on 1/25/15.
//
//

#import "IDCallMakePacket.h"

#import "VoipUtils.h"



@implementation IDCallMakePacket




#pragma mark - CALL LOG
//CALL LOG
+ (NSMutableDictionary *)makeCallLogPacket {
    NSMutableDictionary *packetRequest = [[[NSMutableDictionary alloc]init] autorelease];
    
    [packetRequest setObject:[NSNumber numberWithInt:TYPE_CALL_LOG] forKey:KEY_ACTION_CALL];
    [packetRequest setObject:[self randomNumber] forKey:KEY_PACKET_ID_CALL];
    [packetRequest setObject:[self getSessionId] forKey:KEY_SESSION_ID_CALL];
    
    return packetRequest;
}

//CALL LOG SINGLE FRIEND
+ (NSMutableDictionary *)makeCallLogSingleFriendPacket:(NSString *)friendId {
    NSMutableDictionary *packetRequest = [[[NSMutableDictionary alloc]init] autorelease];
    
    [packetRequest setObject:[NSNumber numberWithInt:TYPE_CALL_LOG_SINGLE_FRIEND] forKey:KEY_ACTION_CALL];
    [packetRequest setObject:friendId forKey:KEY_FRIEND_ID_CALL];
    [packetRequest setObject:[self randomNumber] forKey:KEY_PACKET_ID_CALL];
    [packetRequest setObject:[self getSessionId] forKey:KEY_SESSION_ID_CALL];
    
    return packetRequest;
}




#pragma mark CALL PACKETS

+ (NSMutableDictionary *)makePushAck:(NSString *)callID
{
   	NSMutableDictionary *packetRequest = [[[NSMutableDictionary alloc]init] autorelease];
    
    [packetRequest setObject:[NSNumber numberWithInt:TYPE_PUSH_ACK] forKey:KEY_ACTION_CALL];
    [packetRequest setObject:[self randomNumber] forKey:KEY_PACKET_ID_CALL];
    [packetRequest setObject:[self getSessionId] forKey:KEY_SESSION_ID_CALL];
    if (callID) [packetRequest setObject:callID forKey:KEY_CALL_ID];
    
    return packetRequest;
    
}
+ (NSMutableDictionary *)makeOutGoingCallPacket:(NSString *)friendId byCallID:(NSString *) callID
{
    NSMutableDictionary *packetRequest = [[[NSMutableDictionary alloc]init] autorelease];
    
    [packetRequest setObject:[NSNumber numberWithInt:TYPE_FREE_CALL_FIRST] forKey:KEY_ACTION_CALL];
    [packetRequest setObject:[self randomNumber] forKey:KEY_PACKET_ID_CALL];
    [packetRequest setObject:[self getSessionId] forKey:KEY_SESSION_ID_CALL];
    [packetRequest setObject:friendId forKey:KEY_FRIEND_ID_CALL];
    [packetRequest setObject:callID forKey:KEY_CALL_ID];
    
    return packetRequest;
}


/**
 *  makeRegisterPacketForFreeCall
 *
 *  @param packetType     CallPacketType enum value on Utils.h
 *  @param userIdentity   caller ring ID
 *  @param friendIdentity friend ring ID
 *
 *  @return
 */
+(NSData *) makeRegisterPacketForFreeCall:(int) packetType  userIdentity:(NSString *) userIdentity friendIdentity: (NSString *) friendIdentity withCallID:(NSString *) callID
{
    if (userIdentity && friendIdentity && callID) {
        if(!friendIdentity)return nil;
        
        unsigned long long long_userIdentity = [userIdentity longLongValue];
        unsigned long long long_friendIdentity = [friendIdentity longLongValue];
        
        unsigned char *callIDByte = (unsigned char *)[callID dataUsingEncoding:NSUTF8StringEncoding].bytes;
        callIDByte[callID.length] = '\0';
        
        unsigned long totalDataLenght = 2 + 8 +  [callID dataUsingEncoding:NSUTF8StringEncoding].length + 8; // thie size of "unsigned long long" is 8 byte and that's why we are adding 8 here for both userID and firendID.
        
        Byte data[totalDataLenght];
        int i = 0;
        
        data[i++] = packetType;
        
        data[i++] = (long_userIdentity >> 56) & 0xFF;
        data[i++] = (long_userIdentity >> 48) & 0xFF;
        data[i++] = (long_userIdentity >> 40) & 0xFF;
        data[i++] = (long_userIdentity >> 32) & 0xFF;
        data[i++] = (long_userIdentity >> 24) & 0xFF;
        data[i++] = (long_userIdentity >> 16) & 0xFF;
        data[i++] = (long_userIdentity >> 8) & 0xFF;
        data[i++] = long_userIdentity & 0xFF;
        
        data[i++] = (long_friendIdentity >> 56) & 0xFF;
        data[i++] = (long_friendIdentity >> 48) & 0xFF;
        data[i++] = (long_friendIdentity >> 40) & 0xFF;
        data[i++] = (long_friendIdentity >> 32) & 0xFF;
        data[i++] = (long_friendIdentity >> 24) & 0xFF;
        data[i++] = (long_friendIdentity >> 16) & 0xFF;
        data[i++] = (long_friendIdentity >> 8) & 0xFF;
        data[i++] = long_friendIdentity & 0xFF;
        
        data[i++] = [callID dataUsingEncoding:NSUTF8StringEncoding].length;
        
        for (int n = 0; n < [callID dataUsingEncoding:NSUTF8StringEncoding].length; n++) {
            data[i++] = callIDByte[n];
        }
        
        return [NSData dataWithBytes:data length:totalDataLenght];
    }
    else {
        return nil;
    }
    
}


/**
 *  makeUnRegisterPacketForCall
 *
 *  @param packetType   CallPacketType enum value on Utils.h
 *  @param userIdentity Call user ringID
 *
 *  @return packet Data
 */
+(NSData *) makeUnRegisterPacketForCall:(int) packetType userIdentity:(NSString *) userIdentity
{
    if (userIdentity == nil) {  //Need to check. Just a temporary solution to stop crashing
        return nil;
    }
    
    NSNumberFormatter * numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
    NSNumber *number_userIdentity = [numberFormatter numberFromString:userIdentity];
    unsigned long long long_userIdentity = [number_userIdentity unsignedLongLongValue];
    
    unsigned long totalDataLenght = 1 + 8;
    
    Byte data[totalDataLenght];
    int i = 0;
    data[i++] = packetType;
    
    data[i++] = (long_userIdentity >> 56) & 0xFF;
    data[i++] = (long_userIdentity >> 48) & 0xFF;
    data[i++] = (long_userIdentity >> 40) & 0xFF;
    data[i++] = (long_userIdentity >> 32) & 0xFF;
    data[i++] = (long_userIdentity >> 24) & 0xFF;
    data[i++] = (long_userIdentity >> 16) & 0xFF;
    data[i++] = (long_userIdentity >> 8) & 0xFF;
    data[i++] = long_userIdentity & 0xFF;
    
    return [NSData dataWithBytes:data length:totalDataLenght];
    
}

/**
 *  makeCallSignalingPacket
 *
 *  @param packetType   packetType CallPacketType enum value on Utils.h
 *  @param packetID     call packet ID
 *  @param userIdentity Call user ringID
 *
 *  @return packet Data
 */
// We are not using  this method any more.
//+(NSData *) makeCallSignalingPacket:(int) packetType  userIdentity:(NSString *) userIdentity friendIdentity: (NSString *) friendIdentity
//{
//    if (userIdentity && friendIdentity) {
//        NSString *packetID = [self randomNumber];
//        
//        unsigned char *packetIdByte = (unsigned char *)[packetID dataUsingEncoding:NSUTF8StringEncoding].bytes;
//        unsigned char *userIdentityByte = (unsigned char *)[userIdentity dataUsingEncoding:NSUTF8StringEncoding].bytes;
//        unsigned char *frndIdByte = (unsigned char *)[friendIdentity dataUsingEncoding:NSUTF8StringEncoding].bytes;
//        
//        packetIdByte[packetID.length] = '\0';
//        userIdentityByte[userIdentity.length] = '\0';
//        frndIdByte[friendIdentity.length]='\0';
//        
//        unsigned long totalDataLenght = 4 + [userIdentity dataUsingEncoding:NSUTF8StringEncoding].length +  [packetID dataUsingEncoding:NSUTF8StringEncoding].length + [friendIdentity dataUsingEncoding:NSUTF8StringEncoding].length;
//        
//        Byte data[totalDataLenght];
//        int i = 0;
//        
//        data[i++] = packetType;
//        data[i++] = [packetID dataUsingEncoding:NSUTF8StringEncoding].length;
//        
//        for (int n = 0; n < [packetID dataUsingEncoding:NSUTF8StringEncoding].length; n++) {
//            data[i++] = packetIdByte[n];
//        }
//        
//        data[i++] =  [userIdentity dataUsingEncoding:NSUTF8StringEncoding].length;
//        
//        for (int n = 0; n < [userIdentity dataUsingEncoding:NSUTF8StringEncoding].length; n++) {
//            data[i++] = userIdentityByte[n];
//        }
//        
//        data[i++] = [friendIdentity dataUsingEncoding:NSUTF8StringEncoding].length;
//        
//        for (int n = 0; n < [friendIdentity dataUsingEncoding:NSUTF8StringEncoding].length; n++) {
//            data[i++] = frndIdByte[n];
//        }
//        
//        return [NSData dataWithBytes:data length:totalDataLenght];
//    }
//    else {
//        return nil;
//    }
//    
//}


/**
 *  makeCallSignalingPacket
 *
 *  @param packetType   packetType CallPacketType enum value on Utils.h
 *  @param packetID     call packet ID
 *  @param userIdentity Call user ringID
 *
 *  @return packet Data
 */

+(NSData *) makeCallSignalingRingingPacket:(int) packetType packetID:(NSString *) pkID userIdentity:(NSString *) userIdentity friendIdentity: (NSString *) friendIdentity
{
    if (pkID && userIdentity && friendIdentity) {
        NSString *packetID = pkID;
        
        unsigned long long long_userIdentity = [userIdentity longLongValue];
        unsigned long long long_friendIdentity = [friendIdentity longLongValue];
        
        unsigned char *packetIdByte = (unsigned char *)[packetID dataUsingEncoding:NSUTF8StringEncoding].bytes;
        packetIdByte[packetID.length] = '\0';
        
        unsigned long totalDataLenght = 2 + 8 +  [packetID dataUsingEncoding:NSUTF8StringEncoding].length + 8;
        
        Byte data[totalDataLenght];
        int i = 0;
        
        data[i++] = packetType;
        
        data[i++] = (long_userIdentity >> 56) & 0xFF;
        data[i++] = (long_userIdentity >> 48) & 0xFF;
        data[i++] = (long_userIdentity >> 40) & 0xFF;
        data[i++] = (long_userIdentity >> 32) & 0xFF;
        data[i++] = (long_userIdentity >> 24) & 0xFF;
        data[i++] = (long_userIdentity >> 16) & 0xFF;
        data[i++] = (long_userIdentity >> 8) & 0xFF;
        data[i++] = long_userIdentity & 0xFF;
        
        data[i++] = (long_friendIdentity >> 56) & 0xFF;
        data[i++] = (long_friendIdentity >> 48) & 0xFF;
        data[i++] = (long_friendIdentity >> 40) & 0xFF;
        data[i++] = (long_friendIdentity >> 32) & 0xFF;
        data[i++] = (long_friendIdentity >> 24) & 0xFF;
        data[i++] = (long_friendIdentity >> 16) & 0xFF;
        data[i++] = (long_friendIdentity >> 8) & 0xFF;
        data[i++] = long_friendIdentity & 0xFF;
        
        data[i++] = [packetID dataUsingEncoding:NSUTF8StringEncoding].length;
        
        for (int n = 0; n < [packetID dataUsingEncoding:NSUTF8StringEncoding].length; n++) {
            data[i++] = packetIdByte[n];
        }
        
        return [NSData dataWithBytes:data length:totalDataLenght];
    }
    else {
        return nil;
    }
}







+(NSData *) makeCallBusyMessagePacket:(int) packetType packetID:(NSString *) pkID userIdentity:(NSString *) userIdentity friendIdentity: (NSString *) friendIdentity withMessage:(NSString *)message
{
    if (pkID && userIdentity && friendIdentity && message) {
        NSString *packetID = pkID;
        
        NSNumberFormatter * numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
        NSNumber *number_userIdentity = [numberFormatter numberFromString:userIdentity];
        unsigned long long long_userIdentity = [number_userIdentity unsignedLongLongValue];
        NSNumber *number_friendIdentity = [numberFormatter numberFromString:friendIdentity];
        unsigned long long long_friendIdentity = [number_friendIdentity unsignedLongLongValue];
        
        unsigned char *packetIdByte = (unsigned char *)[packetID dataUsingEncoding:NSUTF8StringEncoding].bytes;
        unsigned char *messageByte = (unsigned char *)[message dataUsingEncoding:NSUTF8StringEncoding].bytes;
        
        packetIdByte[packetID.length] = '\0';
        messageByte[message.length]='\0';
        
        
        unsigned long totalDataLenght = 3 + 8 +  [packetID dataUsingEncoding:NSUTF8StringEncoding].length + 8 + [message dataUsingEncoding:NSUTF8StringEncoding].length;
        
        Byte data[totalDataLenght];
        int i = 0;
        
        data[i++] = packetType;
        
        data[i++] = (long_userIdentity >> 56) & 0xFF;
        data[i++] = (long_userIdentity >> 48) & 0xFF;
        data[i++] = (long_userIdentity >> 40) & 0xFF;
        data[i++] = (long_userIdentity >> 32) & 0xFF;
        data[i++] = (long_userIdentity >> 24) & 0xFF;
        data[i++] = (long_userIdentity >> 16) & 0xFF;
        data[i++] = (long_userIdentity >> 8) & 0xFF;
        data[i++] = long_userIdentity & 0xFF;
        
        data[i++] = (long_friendIdentity >> 56) & 0xFF;
        data[i++] = (long_friendIdentity >> 48) & 0xFF;
        data[i++] = (long_friendIdentity >> 40) & 0xFF;
        data[i++] = (long_friendIdentity >> 32) & 0xFF;
        data[i++] = (long_friendIdentity >> 24) & 0xFF;
        data[i++] = (long_friendIdentity >> 16) & 0xFF;
        data[i++] = (long_friendIdentity >> 8) & 0xFF;
        data[i++] = long_friendIdentity & 0xFF;
        
        data[i++] = [packetID dataUsingEncoding:NSUTF8StringEncoding].length;
        
        for (int n = 0; n < [packetID dataUsingEncoding:NSUTF8StringEncoding].length; n++) {
            data[i++] = packetIdByte[n];
        }
        
        data[i++] = [message dataUsingEncoding:NSUTF8StringEncoding].length;
        
        for (int n = 0; n < [message dataUsingEncoding:NSUTF8StringEncoding].length; n++) {
            data[i++] = messageByte[n];
        }
        
        return [NSData dataWithBytes:data length:totalDataLenght];
    }
    else {
        return nil;
    }
}


+(NSData *) makeVoiceRegisterPushRequestPacket:(int)packetType  packetID:(NSString *)pkID userIdentity:(NSString *)userIdentity userFullName:(NSString *)userName friendIdentity:(NSString *)friendIdentity friendPlatform:(int)platform friendOnlineStatus:(int)onlineStatus friendAppType:(int)appType friendDeviceToken:(NSString *)devTok
{
    if (packetType && pkID && userIdentity && userName && friendIdentity && platform && devTok) {
        
        NSNumberFormatter * numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
        NSNumber *number_userIdentity = [numberFormatter numberFromString:userIdentity];
        unsigned long long long_userIdentity = [number_userIdentity unsignedLongLongValue];
        NSNumber *number_friendIdentity = [numberFormatter numberFromString:friendIdentity];
        unsigned long long long_friendIdentity = [number_friendIdentity unsignedLongLongValue];
        
        unsigned char *packetIdByte = (unsigned char *)[pkID dataUsingEncoding:NSUTF8StringEncoding].bytes;
        unsigned char *userNameByte = (unsigned char *)[userName dataUsingEncoding:NSUTF8StringEncoding].bytes;
        unsigned char *devTokByte = (unsigned char *)[devTok dataUsingEncoding:NSUTF8StringEncoding].bytes;
        
        packetIdByte[pkID.length] = '\0';
        userNameByte[userName.length]='\0';
        devTokByte[devTok.length]='\0';
        
//        unsigned long totalDataLenght = 1 + 1 + [pkID dataUsingEncoding:NSUTF8StringEncoding].length + 8 + 1 + [userName dataUsingEncoding:NSUTF8StringEncoding].length + 8 + 1 + 2 + [devTok dataUsingEncoding:NSUTF8StringEncoding].length;
        unsigned long totalDataLenght = 1 + 8 + 8 + 1 + [pkID dataUsingEncoding:NSUTF8StringEncoding].length + 1 + [userName dataUsingEncoding:NSUTF8StringEncoding].length + 1 + 1 + 1 + 2 + [devTok dataUsingEncoding:NSUTF8StringEncoding].length;

        Byte data[totalDataLenght];
        int i = 0;
        
        data[i++] = packetType;
        
        data[i++] = (long_userIdentity >> 56) & 0xFF;
        data[i++] = (long_userIdentity >> 48) & 0xFF;
        data[i++] = (long_userIdentity >> 40) & 0xFF;
        data[i++] = (long_userIdentity >> 32) & 0xFF;
        data[i++] = (long_userIdentity >> 24) & 0xFF;
        data[i++] = (long_userIdentity >> 16) & 0xFF;
        data[i++] = (long_userIdentity >> 8) & 0xFF;
        data[i++] = long_userIdentity & 0xFF;
        
        data[i++] = (long_friendIdentity >> 56) & 0xFF;
        data[i++] = (long_friendIdentity >> 48) & 0xFF;
        data[i++] = (long_friendIdentity >> 40) & 0xFF;
        data[i++] = (long_friendIdentity >> 32) & 0xFF;
        data[i++] = (long_friendIdentity >> 24) & 0xFF;
        data[i++] = (long_friendIdentity >> 16) & 0xFF;
        data[i++] = (long_friendIdentity >> 8) & 0xFF;
        data[i++] = long_friendIdentity & 0xFF;
        
        data[i++] = [pkID dataUsingEncoding:NSUTF8StringEncoding].length;
        
        for (int n = 0; n < [pkID dataUsingEncoding:NSUTF8StringEncoding].length; n++) {
            data[i++] = packetIdByte[n];
        }
        
        data[i++] = [userName dataUsingEncoding:NSUTF8StringEncoding].length;
        
        for (int n = 0; n < [userName dataUsingEncoding:NSUTF8StringEncoding].length; n++) {
            data[i++] = userNameByte[n];
        }
        
        data[i++] = platform;
        
        //TODO: Add Friend Online status+ Friend APP Type here
        data[i++] = onlineStatus;
        data[i++] = appType;
        
        data[i++] =  [IDCallMakePacket bit_rolNum:(int)[devTok dataUsingEncoding:NSUTF8StringEncoding].length Cnt:8];
        data[i++] =  [devTok dataUsingEncoding:NSUTF8StringEncoding].length;
        
        for (int n = 0; n < [devTok dataUsingEncoding:NSUTF8StringEncoding].length; n++) {
            data[i++] = devTokByte[n];
        }
        
        return [NSData dataWithBytes:data length:totalDataLenght];
        
    } else {
        return nil;
    }
    
    return nil;
}


+(NSData *) makeVoiceRegisterPushConfirmationPacket:(int)packetType  packetID:(NSString *)pkID friendIdentity:(NSString *)friendIdentity
{
    if (packetType && pkID && friendIdentity) {
        
        NSNumberFormatter * numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
        NSNumber *number_friendIdentity = [numberFormatter numberFromString:friendIdentity];
        unsigned long long long_friendIdentity = [number_friendIdentity unsignedLongLongValue];
        
        unsigned char *packetIdByte = (unsigned char *)[pkID dataUsingEncoding:NSUTF8StringEncoding].bytes;
        packetIdByte[pkID.length] = '\0';
        
        unsigned long totalDataLenght = 1 + 1 + [pkID dataUsingEncoding:NSUTF8StringEncoding].length + 8;
        
        Byte data[totalDataLenght];
        int i = 0;
        
        data[i++] = packetType;
        
        data[i++] = (long_friendIdentity >> 56) & 0xFF;
        data[i++] = (long_friendIdentity >> 48) & 0xFF;
        data[i++] = (long_friendIdentity >> 40) & 0xFF;
        data[i++] = (long_friendIdentity >> 32) & 0xFF;
        data[i++] = (long_friendIdentity >> 24) & 0xFF;
        data[i++] = (long_friendIdentity >> 16) & 0xFF;
        data[i++] = (long_friendIdentity >> 8) & 0xFF;
        data[i++] = long_friendIdentity & 0xFF;

        data[i++] = [pkID dataUsingEncoding:NSUTF8StringEncoding].length;
        
        for (int n = 0; n < [pkID dataUsingEncoding:NSUTF8StringEncoding].length; n++) {
            data[i++] = packetIdByte[n];
        }
        
        return [NSData dataWithBytes:data length:totalDataLenght];
        
    } else {
        return nil;
    }
    
    return nil;
}


+ (NSString *)getBusyMessage: (NSData *) data
{
    int totalRead = 1;
    
    totalRead += 16;
    //    int userIDLength = CFSwapInt32LittleToHost(*(int*)([[data subdataWithRange:NSMakeRange(totalRead, 1)] bytes]));
    //    totalRead++;
    //    totalRead += userIDLength;
    //
    //    int fndIDLength = CFSwapInt32LittleToHost(*(int*)([[data subdataWithRange:NSMakeRange(totalRead, 1)] bytes]));
    //    totalRead++;
    //    totalRead += fndIDLength;
    int packetIDLength = CFSwapInt32LittleToHost(*(int*)([[data subdataWithRange:NSMakeRange(totalRead, 1)] bytes]));
    totalRead++;
    totalRead += packetIDLength;
    

    
    int messageLength = CFSwapInt32LittleToHost(*(int*)([[data subdataWithRange:NSMakeRange(totalRead, 1)] bytes]));
    totalRead++;
    
    NSString *message = [[[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(totalRead,messageLength)] encoding:NSUTF8StringEncoding] autorelease];
    
    return message;
    
}


#pragma mark- Video Call

+(NSData *) getPacketForVideoCallBy:(int) packetType userIdentity:(NSString *) userIdentity friendID:(NSString *) frnID
{
    if (userIdentity == nil) {
        return nil;
    }
    unsigned char *friendIdByte = (unsigned char *)[frnID dataUsingEncoding:NSUTF8StringEncoding].bytes;
    
    unsigned char *userIdentityByte = (unsigned char *)[userIdentity dataUsingEncoding:NSUTF8StringEncoding].bytes;
    userIdentityByte[userIdentity.length] = '\0';
    friendIdByte[frnID.length] = '\0';
    
    int totalDataLenght =(int) ( 3 + [userIdentity dataUsingEncoding:NSUTF8StringEncoding].length + [frnID dataUsingEncoding:NSUTF8StringEncoding].length);
    
    Byte data[totalDataLenght];
    int i = 0;
    data[i++] = packetType;
    
    data[i++] = [frnID dataUsingEncoding:NSUTF8StringEncoding].length;
    
    for (int n = 0; n < [frnID dataUsingEncoding:NSUTF8StringEncoding].length; n++) {
        data[i++] = friendIdByte[n];
    }
    data[i++] =  [userIdentity dataUsingEncoding:NSUTF8StringEncoding].length;
    
    for (int n = 0; n < [userIdentity dataUsingEncoding:NSUTF8StringEncoding].length; n++) {
        data[i++] = userIdentityByte[n];
    }
    
    return [NSData dataWithBytes:data length:totalDataLenght];
}

// this method for video end signal with extra byte
+(NSData *) makeVideoCallSignalingPacket:(int) packetType packetID:(NSString *) pkID userIdentity:(NSString *) userIdentity friendIdentity: (NSString *) friendIdentity withExtraByte:(BOOL) status
{
    if (pkID && userIdentity && friendIdentity) {
        NSString *packetID = pkID;
        
        unsigned long long long_userIdentity = [userIdentity longLongValue];
        unsigned long long long_friendIdentity = [friendIdentity longLongValue];
        
        unsigned char *packetIdByte = (unsigned char *)[packetID dataUsingEncoding:NSUTF8StringEncoding].bytes;
        packetIdByte[packetID.length] = '\0';
        
        unsigned long totalDataLenght = 1+8+8+1+[packetID dataUsingEncoding:NSUTF8StringEncoding].length+1;
        
        Byte data[totalDataLenght];
        int i = 0;
        
        data[i++] = packetType;
        
        data[i++] = (long_userIdentity >> 56) & 0xFF;
        data[i++] = (long_userIdentity >> 48) & 0xFF;
        data[i++] = (long_userIdentity >> 40) & 0xFF;
        data[i++] = (long_userIdentity >> 32) & 0xFF;
        data[i++] = (long_userIdentity >> 24) & 0xFF;
        data[i++] = (long_userIdentity >> 16) & 0xFF;
        data[i++] = (long_userIdentity >> 8) & 0xFF;
        data[i++] = long_userIdentity & 0xFF;
        
        data[i++] = (long_friendIdentity >> 56) & 0xFF;
        data[i++] = (long_friendIdentity >> 48) & 0xFF;
        data[i++] = (long_friendIdentity >> 40) & 0xFF;
        data[i++] = (long_friendIdentity >> 32) & 0xFF;
        data[i++] = (long_friendIdentity >> 24) & 0xFF;
        data[i++] = (long_friendIdentity >> 16) & 0xFF;
        data[i++] = (long_friendIdentity >> 8) & 0xFF;
        data[i++] = long_friendIdentity & 0xFF;
        
        data[i++] = [packetID dataUsingEncoding:NSUTF8StringEncoding].length;
        
        for (int n = 0; n < [packetID dataUsingEncoding:NSUTF8StringEncoding].length; n++) {
            data[i++] = packetIdByte[n];
        }
        
        if (status) {
            data[i++] = packetType;
        }
        
        return [NSData dataWithBytes:data length:totalDataLenght];
    }
    else {
        return nil;
    }
}


+(NSData *)getDataFromInteger:(NSInteger) frameNumber
{
    unsigned char data[4];
    unsigned long number =frameNumber ;
    
    data[0] = (number >> 24) & 0xFF;
    data[1] = (number >> 16) & 0xFF;
    data[2] = (number >> 8) & 0xFF;
    data[3] = number & 0xFF;
    
    return [NSData dataWithBytes:data length:4];
}

+(int)getUniqueKey:(NSData *)data startIndex:(NSInteger)start_index
{
    int result = 0;
    const uint8_t * bytes = [data bytes];
    result += (bytes[start_index++] & 0xFF) << 24;
    result += (bytes[start_index++] & 0xFF) << 16;
    result += (bytes[start_index++] & 0xFF) << 8;
    result += (bytes[start_index] & 0xFF);
    
    return result;
}


#pragma mark- Utilities
+ (NSString *) randomNumber {
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
    long long time = interval * 1000;
    int randomNumber = 1+arc4random()%1000;
    return [NSString stringWithFormat:@"%lld%d", time,randomNumber];
}

+ (NSString *)getSessionId {
    NSString *sessionId = [[NSUserDefaults standardUserDefaults]objectForKey:@"SESSION_ID_RING"];
    
    return sessionId;
}

+(NSData *)getByteFromInt:(int)number{
    
    unsigned char bytes[4];
    unsigned long n = number;
    
    bytes[0] = (n >> 24) & 0xFF;
    bytes[1] = (n >> 16) & 0xFF;
    bytes[2] = (n >> 8) & 0xFF;
    bytes[3] = n & 0xFF;
    
    return [NSData dataWithBytes:bytes length:4];
}

+(NSData *)getEightByteDataFromInteger:(int) frameNumber
{
    unsigned char data[8];
    unsigned long long number =frameNumber ;
    
    data[0] = (number >> 56) & 0xFF;
    data[1] = (number >> 48) & 0xFF;
    data[2] = (number >> 40) & 0xFF;
    data[3] = (number >> 32) & 0xFF;
    data[4] = (number >> 24) & 0xFF;
    data[5] = (number >> 16) & 0xFF;
    data[6] = (number >> 8) & 0xFF;
    data[7] = number & 0xFF;
    
    return [NSData dataWithBytes:data length:8];
}


+(NSString *) makeKeyStringWithCallID:(NSString *) callID andSignalType:(NSInteger) type
{
    return [NSString stringWithFormat:@"k_%ld%@",(long)type,callID];
    
}


+ (int) FloatToInt:(float)f
{
    int ret;
    memcpy( &ret, &f, sizeof( float ) );
    return ret;
}

+ (int) bit_rolNum:(int)num Cnt:(int) cnt
{
    return (num << cnt) | ((num & 0xFFFFFFFFL) >> (32 - cnt));
}

+ (int) bit_rolForGroupIdNum:(int)num Cnt:(int) cnt
{
    return (num << cnt) | ((num & 0xFFFFFFFFL) >> (64 - cnt));
}


@end
