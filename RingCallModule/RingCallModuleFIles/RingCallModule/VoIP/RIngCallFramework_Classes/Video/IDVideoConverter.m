//
//  IDVideoConverter.m
//  RingCallModule
//
//  Created by Nagib Bin Azad on 12/6/15.
//  Copyright © 2015 Sumon. All rights reserved.
//

#import "IDVideoConverter.h"
#import "RingCallConstants.h"
#import <CoreImage/CoreImage.h>
#import <UIKit/UIKit.h>
#import "RIConnectivityManager.h"
#import "IDVideoOperation.h"

#define USE_CONTEXT
unsigned char pRawYuv[MAXWIDTH * MAXHEIGHT*3/2 + 10];
unsigned char baVideoRenderBufferUVChannel [MAXWIDTH * MAXHEIGHT/2];
CIContext *tempContext;
@implementation IDVideoConverter

+ (NSData *)convertSampleBufferToData:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
        
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    int iVideoHeight = (int)CVPixelBufferGetHeight(imageBuffer);
    int iVideoWidth = (int)CVPixelBufferGetWidth(imageBuffer);
    
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    CVPixelBufferLockBaseAddress(imageBuffer,1);
    
    unsigned char *y_ch0 = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    unsigned char *y_ch1 = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1);
    
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    CVPixelBufferUnlockBaseAddress(imageBuffer,1);
    
    int YPlaneLength = iVideoHeight*iVideoWidth;
    int VPlaneLength = YPlaneLength >> 2;
    
    memcpy(pRawYuv, y_ch0, YPlaneLength);
    memcpy(pRawYuv+YPlaneLength, y_ch1, VPlaneLength+VPlaneLength);
    NSData *data = [NSData dataWithBytes:pRawYuv length:iVideoHeight * iVideoWidth * 3 / 2];
    
    return data;
}

+ (UIImage *)convertReceivedDataToUIImage:(unsigned char *)receivedData withHeight:(int)iVideoHeight withWidth:(int)iVideoWidth
{
        if (!receivedData) {
            NSLog(@"received data NULL");
            return nil;
        }
        int YPlaneLength = iVideoHeight*iVideoWidth;
        int VPlaneLength = YPlaneLength >> 2;
        memcpy(baVideoRenderBufferUVChannel, receivedData + YPlaneLength, VPlaneLength + VPlaneLength);
     
        CVPixelBufferRef pixelBuffer = [[self class] convert_YUVNV12_To_CVPixelBufferRefWithChannel0:receivedData channel1:baVideoRenderBufferUVChannel renderHeight:iVideoHeight renderWidth:iVideoWidth];
        
        UIImage *renderImage =  [[self class] convert_CVPixelBufferRef_To_UIImage:pixelBuffer];
        
        CVPixelBufferRelease(pixelBuffer);
        
        return renderImage;
    

}
+ (CVPixelBufferRef) convert_YUVNV12_To_CVPixelBufferRefWithChannel0:(unsigned char*) y_ch0 channel1: (unsigned char*) y_ch1 renderHeight:(int) iRenderHeight renderWidth:(int) iRenderWidth
{
    NSDictionary *pixelAttributes = @{(id)kCVPixelBufferIOSurfacePropertiesKey : @{}};
    CVPixelBufferRef pixelBuffer = NULL;
    CVReturn result = CVPixelBufferCreate(kCFAllocatorDefault,
                                          iRenderWidth,
                                          iRenderHeight,
                                          kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
                                          (__bridge CFDictionaryRef)(pixelAttributes),
                                          &pixelBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer,0);
    unsigned char *yDestPlane = (unsigned char*)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    memcpy(yDestPlane, y_ch0, iRenderWidth * iRenderHeight);
    
    
    unsigned char *uvDestPlane = (unsigned char*)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    memcpy(uvDestPlane, y_ch1, iRenderWidth * iRenderHeight / 2);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    if (result != kCVReturnSuccess) {
        NSLog(@"Unable to create cvpixelbuffer %d", result);
    }
    return pixelBuffer;
}
+ (UIImage*) convert_CVPixelBufferRef_To_UIImage:(CVPixelBufferRef) pixelBuffer
{
#ifdef USE_UIGRAPHICS
    {
        int w = CVPixelBufferGetWidth(pixelBuffer);
        int h = CVPixelBufferGetHeight(pixelBuffer);
        int r = CVPixelBufferGetBytesPerRow(pixelBuffer);
        int bytesPerPixel = r/w;
        
        CVPixelBufferLockBaseAddress(pixelBuffer,0);
        CVPixelBufferLockBaseAddress(pixelBuffer,1);
        unsigned char *y_ch0 = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0); // Y-Plane = y_ch0
        unsigned char *y_ch1 = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1); // UV-Plane = y_ch1
        CVPixelBufferUnlockBaseAddress(pixelBuffer,0);
        CVPixelBufferUnlockBaseAddress(pixelBuffer,1);
        //unsigned char *buffer = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer, 0);
        
        UIGraphicsBeginImageContext(CGSizeMake(w, h));
        
        CGContextRef c = UIGraphicsGetCurrentContext();
        
        unsigned char* data = (unsigned char *)CGBitmapContextGetData(c);
        memcpy(data, y_ch0, h * w);
        memcpy(data + h * w, y_ch1,  h * w / 2);
        
        UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        return img;
    }
#else
    CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer];
    
#ifdef USE_CONTEXT
    if ([IDVideoOperation sharedManager].renderContext == nil) {
        [IDVideoOperation sharedManager].renderContext = [CIContext contextWithOptions:nil];
    }
    CGImageRef videoImage = [[IDVideoOperation sharedManager].renderContext
                             createCGImage:ciImage
                             fromRect:CGRectMake(0, 0,
                                                 CVPixelBufferGetWidth(pixelBuffer),
                                                 CVPixelBufferGetHeight(pixelBuffer))];
#endif
    
#ifdef USE_CONTEXT
    UIImage *pImage = [[[UIImage alloc] initWithCGImage:videoImage] autorelease];/* scale:1.0 orientation:UIImageOrientationLeftMirrored*/
#else
    UIImage *pImage = [[[UIImage alloc] initWithCIImage:ciImage scale:1.0 orientation:UIImageOrientationLeftMirrored] autorelease];
    
#endif
    
#ifdef USE_CONTEXT
    CGImageRelease(videoImage);
    [ciImage release];
#endif
    return pImage;
#endif
    
}
@end
