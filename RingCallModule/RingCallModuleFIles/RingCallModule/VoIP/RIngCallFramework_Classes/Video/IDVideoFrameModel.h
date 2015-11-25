//
//  IDVideoFrameModel.h
//  videoScreenDemo
//
//  Created by Md Shahinur Rahman on 1/15/15.
//  Copyright (c) 2015 IPVision. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IDVideoFrameModel : NSObject

@property (nonatomic, strong) NSData *videoFrameData;
@property (nonatomic, assign) NSInteger currentFrameNumber;
@property (nonatomic, assign) NSInteger totalSingleFrameSequence;
@property (nonatomic, assign) NSInteger currentFrameSeqence;

@end
