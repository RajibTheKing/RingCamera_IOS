//
//  RICommonUtils.h
//  RingCommon
//
//  Created by Md Shahinur Rahman on 3/25/15.
//  Copyright (c) 2015 IPVision. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RICommonUtils : NSObject


/*!
 @function   getIntValueFrom
 @abstract   Returns a NSInteger value .
 
 @param      data
 A data containing attributes that specify the requested value.
 
 @param      index
 Index Specify starting point of get value from Data .
 
 @param      length
 Length specified, how many byte read from index and convert to NSInteger.
 NB:Valid length 1,2 and 4

 
 @result     This function will return a NSInteger .
 */

-(NSInteger) getIntValueFrom:(NSData *)data index:(int)index length:(int) length;




@end
