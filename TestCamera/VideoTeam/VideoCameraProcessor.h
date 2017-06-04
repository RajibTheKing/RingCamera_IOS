//
//  VideoCallProcessor.h
//  TestCamera 
//
//  Created by Apple on 11/16/15.
//
//

#ifndef VideoCallProcessor_h
#define VideoCallProcessor_h

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#include "RingBuffer.hpp"
#include <stdio.h>
#include <pthread.h>

#include "VideoConverter.hpp"
#include "Constants.h"
#include "MessageProcessor.hpp"
#include "Common.hpp"
#include "VideoThreadProcessor.h"
#include "VideoAPI.hpp"
#include "VideoSockets.h"
//#include "G729CodecNative.h"


@protocol ViewControllerDelegate <NSObject>
@required
-(int)RenderImage:(UIImage *)uiImageToDraw;
-(void)SetCameraResolution:(int)iHeight withWidth:(int)iWidth;
-(void)UpdateStatusMessage: (string)sMsg;
@end




@interface VideoCameraProcessor : UIViewController<VideoThreadProcessorDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>
{
    RingBuffer<byte> *m_pEncodeBuffer;
    int m_iCameraHeight;
    int m_iCameraWidth;
    
    int m_iRenderHeight;
    int m_iRenderWidth;
    
    dispatch_queue_t videoDataOutputQueue;
    CVideoConverter *m_pVideoConverter;
    VideoSockets *m_pVideoSockets;
    //VideoThreadProcessor *m_pVTP;
   
    
    id <ViewControllerDelegate> _delegate;
    CVideoAPI *m_pVideoAPI;
    //G729CodecNative *g_G729CodecNative;
    
    FILE *m_FileForDump;
    FILE *m_FileReadFromDump;
    bool m_bCheckCall;
}

@property float m_fR;
@property int m_Threashold;
@property bool m_bStartVideoSending;
@property long long m_lCameraInitializationStartTime;
+ (id)GetInstance;
- (id) init;

- (void)SetHeightAndWidth:(int)iHeight withWidth:(int)iHeight;
- (NSError *)InitializeCameraSession:(AVCaptureSession **)session
                    withDeviceOutput:(AVCaptureVideoDataOutput **)videoDataOutput
                           withLayer:(AVCaptureVideoPreviewLayer **)previewLayer
                          withHeight:(int *)iHeight
                           withWidth:(int *)iWidth;

- (void)SetCameraResolutionByNotification:(int)iHeight withWidth:(int)iWidth;
//-(G729CodecNative *)GetG729;
- (int)FrontConversion:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection;

- (void)WriteToFile:(unsigned char *)data dataLength:(int)datalen filePointer:(FILE *)fp;
- (void)InitializeFilePointer:(FILE *)fp fileName:(NSString *)fileName;
- (void)UpdateStatusMessage: (string)sMsg;

@property (nonatomic,strong) id delegate;



@end

static VideoCameraProcessor *m_pVideoCameraProcessor = nil;

#endif /* VideoCallProcessor_h */
