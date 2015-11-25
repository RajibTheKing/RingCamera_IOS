//
//  IDCallMakePacket.h
//  ringID
//
//  Created by Partho Biswas on 1/25/15.
//
//

#import <Foundation/Foundation.h>
//#import "CallCommonDefs.h"
//#import <AddressBook/AddressBook.h>
//#import "IDCallManager.h"

@interface IDCallMakePacket : NSObject


// CALL LOG
+ (NSMutableDictionary *) makeCallLogPacket;
+ (NSMutableDictionary *) makeCallLogSingleFriendPacket:(NSString *)friendId;

// Calling Authintication
+ (NSMutableDictionary *) makePushAck:(NSString *)callID;
+ (NSMutableDictionary *) makeOutGoingCallPacket:(NSString *)friendId byCallID:(NSString *) callID;

// New Call Packet generator
+ (NSData *) makeRegisterPacketForFreeCall:(int) packetType  userIdentity:(NSString *) userIdentity friendIdentity: (NSString *) friendIdentity withCallID:(NSString *) callID;

+ (NSData *) makeCallSignalingRingingPacket:(int) packetType packetID:(NSString *) pkID userIdentity:(NSString *) userIdentity friendIdentity: (NSString *) friendIdentity;
+ (NSData *) makeCallBusyMessagePacket:(int) packetType packetID:(NSString *) pkID userIdentity:(NSString *) userIdentity friendIdentity: (NSString *) friendIdentity withMessage:(NSString *)message;
+ (NSData *) makeUnRegisterPacketForCall:(int) packetType userIdentity:(NSString *) userIdentity;


// Push notification request packet for calling.
+ (NSData *) makeVoiceRegisterPushRequestPacket:(int)packetType  packetID:(NSString *)pkID userIdentity:(NSString *)userIdentity userFullName:(NSString *)userName friendIdentity:(NSString *)friendIdentity friendPlatform:(int)platform friendOnlineStatus:(int)onlineStatus friendAppType:(int)appType friendDeviceToken:(NSString *)devTok;
+ (NSData *) makeVoiceRegisterPushConfirmationPacket:(int)packetType  packetID:(NSString *)pkID friendIdentity:(NSString *)friendIdentity;

+ (NSString *) randomNumber;
+ (NSString *) makeKeyStringWithCallID:(NSString *) callID andSignalType:(NSInteger) type;
+ (NSString *) getBusyMessage: (NSData *) data;

// VIdeo signal packet
+ (NSData *) getPacketForVideoCallBy:(int) packetType userIdentity:(NSString *) userIdentity friendID:(NSString *) frnID;
+ (NSData *) makeVideoCallSignalingPacket:(int) packetType packetID:(NSString *) pkID userIdentity:(NSString *) userIdentity friendIdentity: (NSString *) friendIdentity withExtraByte:(BOOL) status;

+ (NSData *)getDataFromInteger:(NSInteger) frameNumber;
+(int)getUniqueKey:(NSData *)data startIndex:(NSInteger)start_index
;
// Utilities
+ (int) FloatToInt:(float)f;
+ (int) bit_rolNum:(int)num Cnt:(int) cnt;
+ (int) bit_rolForGroupIdNum:(int)num Cnt:(int) cnt;

@end
