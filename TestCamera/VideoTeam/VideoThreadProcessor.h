//
//  VideoThreadProcessor.h
//  TestCamera 
//
//  Created by Apple on 11/17/15.
//
//

#ifndef VideoThreadProcessor_h
#define VideoThreadProcessor_h

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>


#include "Common.hpp"
#include "RingBuffer.hpp"
#include "VideoAPI.hpp"
#include "AverageCalculator.h" 
#include "ClientLockHandler.h"

class ClientRenderingBuffer;

@protocol VideoThreadProcessorDelegate <NSObject>
@required
- (void)ReInitializeCamera;
- (void)BackConversion:(byte*)pRenderBuffer;
- (void)SetWidthAndHeightForRendering:(int)iWidth withHeight:(int)iHeight;
@end

@interface VideoThreadProcessor : NSObject
{
    RingBuffer<byte> *pEncodeBuffer;
    ClientRenderingBuffer *m_pClientRenderingBuffer;
    unsigned char m_pRenderingData[MAXWIDTH*MAXWIDTH*3/2];
    
    pthread_mutex_t pmEncodeMutex;
    int m_iCameraHeight;
    int m_iCameraWidth;
    int m_iFrameNumber;
    CAverageCalculator  *m_pRenderingAvg;
    id <VideoThreadProcessorDelegate> _delegate;

}

@property bool bRenderThreadActive;
@property bool bEncodeThreadActive;
@property bool bEventThreadActive;
@property (nonatomic,strong) id delegate;




- (id) init;
+ (id)GetInstance;
- (void)SetEncodeBuffer:(RingBuffer<byte> *)pBuffer;
- (void)RenderThread;
- (void)EncodeThread;
- (void)EventThread;
- (void)PushIntoClientRenderingBuffer:(unsigned char *)pData withLen:(int)iLen withHeight:(int)iHeight withWidth:(int)iWidth withOrientation:(int)iOrientation;
@end



static VideoThreadProcessor *m_pVideoThreadProcessor = nil;

#endif /* VideoThreadProcessor_h */
