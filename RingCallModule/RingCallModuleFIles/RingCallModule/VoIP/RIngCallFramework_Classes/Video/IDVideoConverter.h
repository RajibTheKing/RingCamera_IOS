//
//  IDVideoConverter.h
//  RingCallModule
//
//  Created by Nagib Bin Azad on 12/6/15.
//  Copyright © 2015 Sumon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface IDVideoConverter : NSObject

+ (NSData *)convertSampleBufferToData:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection;
+ (UIImage *)convertReceivedDataToUIImage:(unsigned char *)receivedData withHeight:(int)iVideoHeight withWidth:(int)iVideoWidth;

@end
