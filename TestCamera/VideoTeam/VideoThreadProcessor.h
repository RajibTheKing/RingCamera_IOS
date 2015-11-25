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


#include "Common.h"
#include "RingBuffer.hpp"
#include "VideoAPI.hpp"

@protocol VideoThreadProcessorDelegate <NSObject>
@required
- (void)BackConversion:(byte*)pRenderBuffer;
- (void)SetWidthAndHeightForRendering:(int)iWidth withHeight:(int)iHeight;
@end

@interface VideoThreadProcessor : NSObject
{
    RingBuffer<byte> *pEncodeBuffer;
    CVideoAPI *m_pVideoAPI;
    
    pthread_mutex_t pmEncodeMutex;
    int m_iCameraHeight;
    int m_iCameraWidth;
    int m_iFrameNumber;
    
    id <VideoThreadProcessorDelegate> _delegate;

}

@property bool bRenderThreadActive;
@property bool bEncodeThreadActive;
@property (nonatomic,strong) id delegate;




- (id) init;
- (void)SetWidthAndHeight:(int)iWidth withHeight:(int)iHeight;
- (void)SetVideoAPI:(CVideoAPI *)pVideoAPI;

- (void)SetEncodeBuffer:(RingBuffer<byte> *)pBuffer;
- (void)RenderThread;
- (void)EncodeThread;

@end


#endif /* VideoThreadProcessor_h */
