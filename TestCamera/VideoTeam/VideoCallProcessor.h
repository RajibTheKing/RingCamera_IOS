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
#include "common.h"
#include "VideoThreadProcessor.h"
#include "VideoAPI.hpp"
#include "VideoSockets.h"
#include "G729CodecNative.h" 


@protocol ViewControllerDelegate <NSObject>
@required
-(int)RenderImage:(UIImage *)uiImageToDraw;
@end




@interface VideoCallProcessor : UIViewController<VideoThreadProcessorDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>
{
    RingBuffer<byte> *m_pEncodeBuffer;
    int m_iCameraHeight;
    int m_iCameraWidth;
    long long m_lUserId;
    int m_iRenderHeight;
    int m_iRenderWidth;
    dispatch_queue_t videoDataOutputQueue;
    
    CVideoConverter *m_pVideoConverter;
    VideoSockets *m_pVideoSockets;
    
   
    
    id <ViewControllerDelegate> _delegate;
    VideoThreadProcessor *m_pVideoThreadProcessor;
    
    

    CVideoAPI *m_pVideoAPI;
    G729CodecNative *g_G729CodecNative;
}



@property bool m_bStartVideoSending;

+ (id)GetInstance;

- (id) init;
- (void) Initialize : (long long)lUserId;
- (void) InitializeVideoEngine:(long long) lUserId;

- (void)SetWidthAndHeight:(int)iWidth withHeight:(int)iHeight;

- (void)SetVideoSockets:(VideoSockets *)pVideoSockets;

- (void)StartAllThreads;
- (void)CloseAllThreads;
- (NSError *)InitializeCameraSession:(AVCaptureSession **)session
                    withDeviceOutput:(AVCaptureVideoDataOutput **)videoDataOutput
                           withLayer:(AVCaptureVideoPreviewLayer **)previewLayer
                          withHeight:(int *)iHeight
                           withWidth:(int *)iWidth;
-(G729CodecNative *)GetG729;

- (int)FrontConversion:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection;

@property (nonatomic,strong) id delegate;



@end

static VideoCallProcessor *m_pVideoCallProcessor = nil;

#endif /* VideoCallProcessor_h */
