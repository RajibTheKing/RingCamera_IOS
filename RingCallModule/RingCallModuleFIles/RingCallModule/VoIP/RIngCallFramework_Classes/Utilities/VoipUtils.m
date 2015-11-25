//
//  VoipUtils.m
//  ringID
//
//  Created by Partho Biswas on 11/3/14.
//
//

#import "VoipUtils.h"
#import <objc/runtime.h>
#import <ifaddrs.h>
#import <net/if.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>

#import <RingCommon/Reachability.h>

#pragma mark - CALL MODULE RELATED KEYS
const NSString *KEY_CALL_ID = @"callID";
const NSString *KEY_CALL_INITIATION_TIME = @"tm";
int TYPE_FREE_CALL_FIRST = 174;
int TYPE_PUSH_ACK = 223;
int TYPE_CALL_LOG = 224; // "callLog";
int TYPE_CALL_LOG_SINGLE_FRIEND = 36; // "callLogSingleFriend";


// The following variables are only for CallModule. Comment this out to avoid redefinition of global variable if the module source is in main project. Uncomment the following block if the call framework is saparate.

const NSString *KEY_ACTION_CALL = @"actn";
const NSString *KEY_SUCCESS_CALL = @"sucs";
const NSString *KEY_PRESENCE_CALL = @"psnc";
const NSString *KEY_SWITCH_IP_CALL = @"swIp";
const NSString *KEY_SWITCH_PORT_CALL = @"swPr";
const NSString *KEY_APP_TYPE_CALL = @"apt";
const NSString *KEY_DEVICE_CALL = @"dvc";
const NSString *KEY_RINGID_DEVICE_TOKEN = @"dt";

//const NSString *KEY_DEVICE_UNIQUE_ID = @"did";
const NSString *KEY_FRIEND_ID_CALL = @"fndId";
const NSString *KEY_PACKET_ID_CALL = @"pckId";
const NSString *KEY_SESSION_ID_CALL = @"sId";
const NSString *KEY_FRIEND_NAME = @"fn";
const NSString *KEY_FRIEND_IDC = @"idc";
const NSString *KEY_FRIEND_CONNECT_WITH = @"cw";
const NSString *KEY_FRIEND_MOOD = @"mood";
const NSString *KEY_FRIEND_RC = @"rc";
const NSString *KEY_FRIEND_MESSAGE = @"mg";
const NSString *KEY_CALL_MEDIA_TYPE= @"calT";

// THESE ARE ONLY FOR CALL MODULE
const NSString *IS_FROM_REMOTE_PUSH = @"isFromRemotePush";
const NSString *IS_FROM_LOCAL_PUSH = @"isFromLocalPush";
//const NSString *KEY_PACKET_ID_FROM_SERVER = @"pckFs";
const NSString *KEY_CALL_TIME = @"caTm";
const NSString *KEY_CALL_DURATION = @"calD";
const NSString *KEY_CALL_TYPE = @"calT";
const NSString *KEY_STATUS_CODE =@"sCode";

@implementation VoipUtils


void RUN_ON_UI_THREAD(dispatch_block_t block)
{
    if ([NSThread isMainThread])
    {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
//        dispatch_async(dispatch_get_main_queue(), block);
    }
}

+ (void)popModalsToRootFrom:(UIViewController*)aVc {
    if(aVc.parentViewController == nil) {
        return;
    }
    else {
        [VoipUtils popModalsToRootFrom:aVc.parentViewController];  // recursive call to this method
        
        [aVc.parentViewController dismissViewControllerAnimated:NO completion:nil];
        
        
//        aVc.parentViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
//        aVc.parentViewController.view.alpha = 1.0;
//        [UIView animateWithDuration:1.5
//                         animations:^{aVc.parentViewController.view.alpha  = 0.0;}];
    }
}

+ (void)popModalsFrom:(UIViewController*)aVc popCount:(int)count {
    if(aVc.parentViewController == nil || count == 0) {
        return;
    }
    else {
        [VoipUtils popModalsFrom:aVc.parentViewController popCount:count-1];  // recursive call to this method
        [aVc.parentViewController dismissViewControllerAnimated:NO completion:nil];
    }
}


+ (void) writeToTextFile:(id)txtToWrite {
    NSString *text = [NSString stringWithFormat:@"%@",txtToWrite];
    
    NSMutableString *string = [[[NSMutableString alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/Callog.txt", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]]] autorelease];
    if (!string) string = [[[NSMutableString alloc] init] autorelease];
    [string appendFormat:@"%@\r\n", text];
    [string writeToFile:[NSString stringWithFormat:@"%@/Callog.txt", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]] atomically:YES encoding:NSUTF8StringEncoding error:nil];
}


//  It only tests the modem speed
+(double)getRouterLinkSpeed
{
    BOOL   success;
    struct ifaddrs *addrs;
    const struct ifaddrs *cursor;
    const struct if_data *networkStatisc;
    
    double linkSpeed = 0;
    
    NSString *name = nil;
    
    success = getifaddrs(&addrs) == 0;
    if (success)
    {
        cursor = addrs;
        while (cursor != NULL)
        {
            name=[NSString stringWithFormat:@"%s",cursor->ifa_name];
            
            if (cursor->ifa_addr->sa_family == AF_LINK)
            {
                if ([name hasPrefix:@"en"])
                {
                    networkStatisc = (const struct if_data *) cursor->ifa_data;
                    linkSpeed = networkStatisc->ifi_baudrate;
                }
            }
            cursor = cursor->ifa_next;
        }
        freeifaddrs(addrs);
    }
    
    return linkSpeed;
}



//Add this utility method in your class.
+ (NSDictionary *) dictionaryWithPropertiesOfObject:(id)obj
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    unsigned count;
    objc_property_t *properties = class_copyPropertyList([obj class], &count);
    
    for (int i = 0; i < count; i++) {
        NSString *key = [NSString stringWithUTF8String:property_getName(properties[i])];
        [dict setObject:[obj valueForKey:key] forKey:key];
    }
    
    free(properties);
    
    return [NSDictionary dictionaryWithDictionary:dict];
}

/*
+ (NSDictionary *) dictionaryWithPropertiesOfObject:(id)obj
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    unsigned count;
    objc_property_t *properties = class_copyPropertyList([obj class], &count);
    
    for (int i = 0; i < count; i++) {
        NSString *key = [NSString stringWithUTF8String:property_getName(properties[i])];
        Class classObject = NSClassFromString([key capitalizedString]);
        
        id object = [obj valueForKey:key];
        
        if (classObject) {
            id subObj = [self dictionaryWithPropertiesOfObject:object];
            [dict setObject:subObj forKey:key];
        }
        else if([object isKindOfClass:[NSArray class]])
        {
            NSMutableArray *subObj = [NSMutableArray array];
            for (id o in object) {
                [subObj addObject:[self dictionaryWithPropertiesOfObject:o] ];
            }
            [dict setObject:subObj forKey:key];
        }
        else
        {
            if(object) [dict setObject:object forKey:key];
        }
    }
    
    free(properties);
    return [NSDictionary dictionaryWithDictionary:dict];
}
*/


+ (BOOL)isInternetReachable
{
    Reachability *reachibility = [Reachability reachabilityForInternetConnection];
    [reachibility startNotifier];
    
    if ([reachibility currentReachabilityStatus] != NotReachable) {
        return  YES;
    } else {
        
        long long int prevTimeInt = [[[NSUserDefaults standardUserDefaults] objectForKey:@"LastShowTime"] longLongValue];
        long long int currentTimeInt = [[NSDate date] timeIntervalSince1970];
        if (prevTimeInt < (currentTimeInt - 30) || prevTimeInt == 0) {
            
            
            [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]] forKey:@"LastShowTime"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
        }
        return NO;
    }
}

+ (BOOL)isInternConnectionAvailable
{
    Reachability *reachibility = [Reachability reachabilityForInternetConnection];
    [reachibility startNotifier];
    
    if ([reachibility currentReachabilityStatus] != NotReachable && [[NSUserDefaults standardUserDefaults] boolForKey: @"isReachable"]) {
        return  YES;
    } else {
        
        long long int prevTimeInt = [[[NSUserDefaults standardUserDefaults] objectForKey:@"LastShowTime"] longLongValue];
        long long int currentTimeInt = [[NSDate date] timeIntervalSince1970];
        if (prevTimeInt < (currentTimeInt - 30) || prevTimeInt == 0) {
            
            [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]] forKey:@"LastShowTime"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        return NO;
    }
}


+(int)getUniqueKey:(NSData *)data startIndex:(int)start_index
{
    int result = 0;
    const uint8_t * bytes = [data bytes];
    result += (bytes[start_index++] & 0xFF) << 24;
    result += (bytes[start_index++] & 0xFF) << 16;
    result += (bytes[start_index++] & 0xFF) << 8;
    result += (bytes[start_index] & 0xFF);
    
    return result;
}


+ (UIViewController*) getTopMostViewController
{
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(window in windows) {
            if (window.windowLevel == UIWindowLevelNormal) {
                break;
            }
        }
    }
    
    for (UIView *subView in [window subviews])
    {
        UIResponder *responder = [subView nextResponder];
        
        //added this block of code for iOS 8 which puts a UITransitionView in between the UIWindow and the UILayoutContainerView
        if ([responder isEqual:window])
        {
            //this is a UITransitionView
            if ([[subView subviews] count])
            {
                UIView *subSubView = [subView subviews][0]; //this should be the UILayoutContainerView
                responder = [subSubView nextResponder];
            }
        }
        
        if([responder isKindOfClass:[UIViewController class]]) {
            return [self topViewController: (UIViewController *) responder];
        }
    }
    
    return nil;
}

+ (UIViewController *) topViewController: (UIViewController *) controller
{
    BOOL isPresenting = NO;
    do {
        // this path is called only on iOS 6+, so -presentedViewController is fine here.
        UIViewController *presented = [controller presentedViewController];
        isPresenting = presented != nil;
        if(presented != nil) {
            controller = presented;
        }
        
    } while (isPresenting);
    
    return controller;
}


+ (bool) isOnCDMAorGSMCall {
    /*
     Returns TRUE/YES if the user is currently on a phone call
     */
    
    CTCallCenter *callCenterLocal = [[[CTCallCenter alloc] init] autorelease];
    for (CTCall *call in callCenterLocal.currentCalls)  {
        if ((call.callState == CTCallStateConnected) || (call.callState == CTCallStateDialing) || (call.callState == CTCallStateIncoming) || (call.callState == CTCallStateDisconnected)) {
            return YES;
        }
    }
    return NO;
}


+ (bool) isOnRingCall {
    /*
     Returns TRUE/YES if the user is currently on a phone call
     */
    
    CTCallCenter *callCenterLocal = [[[CTCallCenter alloc] init] autorelease];
    for (CTCall *call in callCenterLocal.currentCalls)  {
        if ((call.callState == CTCallStateConnected) || (call.callState == CTCallStateDialing) || (call.callState == CTCallStateIncoming)) {
            return YES;
        }
    }
    return NO;
}



/*
// Comment this out to avoid redefinition of global variable. Uncomment the loffowing block if the call framework is saparate.

#pragma mark - OBSERVER CONSTANT
//NSString *CALL_IP_PORT = @"CALL_IP_PORT";

#pragma mark - KEY VALUES

NSString *KEY_PACKET_TYPE = @"pt";
NSString *KEY_MESSAGE_DATE = @"mDate";

#pragma mark - TYPE
int TYPE_CALL_START = 132; // "call_start";
int TYPE_UPDATE_CALL_START = 332; // "call_start";
int TYPE_CALL_END = 133; // "call_end";
int TYPE_UPDATE_CALL_END = 333; // "call_end";

// Notification message types
int TYPE_FREE_CALL_SECOND = 132;
int TYPE_RECEIVED_CALL_RESPONSE = 374;


float BUSY_TIME_DURATION = 10.0;
float CALL_PROCESSING_DURATION = 30.0;
NSString *ERROR_MESSAGE = @"ERROR";
NSString *NETWORK_PROBLEM = @"Please check your network connection.";



#pragma mark-OTHER CONSTANTS
//---------------OTHER-------------------------

NSString *SUCCESS_MESSAGE_FOR_SIGN_UP = @"Sign up successful";
NSString *FAILURE_MESSAGE_FOR_SIGN_UP = @"Sign up couldn't be completed";
//NSString *SYSTEM_VERSION = @"SYSTEM_VERSION";

//ERROR MESSAGES
NSString *ARE_YOU_SURE = @"Are you sure ";
NSString *COM_PORT_PROBLEM = @"Currently unable to communicate with server";

NSString *SIGN_OUT_NOTIFICAITON = @"you want to sign out of 24FnF?";
NSString *EXIT_NOTIFICAITON = @"to exit?";
NSString *CANCEL_NOTIFICAITON = @"to cancel?";
NSString *REJECT_NOTIFICAITON = @"to reject?";
NSString *REMOVE_NOTIFICAITON = @"to remove?";
NSString *DELETE_NOTIFICAITON = @"to delete?";
NSString *CALL_TERMINATION_NOTIFICAITON = @"Previous call will be terminated?";
NSString *ERROR_IN_UPLOAD_NOTIFICAITON = @"Can not upload image";
NSString *NO_LONGER_FRIEND_NOTIFICAITON = @"This friend is no longer in your contacts";
NSString *CALL_LIMIT_NOTIFICATION = @"You have reached your call limit for today";
NSString *NO_FRIEND = @"No friend";
NSString *NOT_SLECTED_FRIEND = @"Friend not selected";
NSString *OFFLINE_NOTIFICATION = @"You are currently offline";
NSString *GROUP_CREATE_SUCCESS = @"Group created successfully";
NSString *GROUP_EDIT_SUCCESS = @"Group edited successfully";
NSString *DELETE_SUCCESS = @" deleted successfully";
NSString *INVALID_GROUP_NAME = @"Please enter valid group name";
NSString *NO_GROUP_MEMBER = @"Need member in group";
NSString *CAN_NOT_UPLOAD_IMAGE = @"Can not upload image";
NSString *NEW_MEMBER_ADDED = @"New members added successfully";
NSString *GROUP_EDITED_SUCCESSFULLY = @"Group edited successfully";
NSString *CAN_NOT_CREATE_GROUP = @"Can not create group";
NSString *INCOMMING_REQUEST = @"Incomming request";
NSString *PENDING_REQUEST = @"Pending request";
NSString *TRY_AGAIN_MSG = @"Please Try Again Later.";


//KEYS
#pragma mark - KEYS
+(id)AUTH_SERVER_IP{
    return @"authServerIP";
}
+(id)AUTHENTICATION_AND_KEEP_ALIVE_PORT{
    return @"keepAlivePort";
}
+(id)CALLING_PORT{
    return @"voicePort";
}

+(id)CONFIRMATION_PORT{
    return @"confirmationPort";
}

+(id)REQUEST_PORT{
    return @"requestPort";
}
+(id)UPDATE_PORT{
    return @"updatePort";
}


NSString *KEY_IS_PICKED = @"ispc";
NSString *KEY_PUSH_ENABLED = @"pen";
NSString *KEY_PHONE_NO = @"phN";
NSString *KEY_PHONE_NO_LOG = @"phN";

NSString *DEVICE_TOKEN = @"_DEVICE_TOKEN";
NSString *KEY_DEVICE_TOKEN = @"iToken";
*/








@end
