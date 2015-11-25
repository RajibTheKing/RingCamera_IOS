//
//  RingCallAudioDelegate.h
//  RingCallModule
//
//  Created by Partho Biswas on 6/11/15.
//  Copyright (c) 2015 Partho Biswas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CallCommonDefs.h"
#import "RCCurrentCallInfoModel.h"


@protocol RingCallAudioDelegate <NSObject>

@required
- (void) ringCallAudioStarted;
- (void) ringCallAudioEnded;

- (void) ringToneStarted;
- (void) ringToneEnded;


@end
