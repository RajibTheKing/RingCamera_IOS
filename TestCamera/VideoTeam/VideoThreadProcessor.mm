//
//  VideoThreadProcessor.m
//  TestCamera 
//
//  Created by Apple on 11/17/15.
//
//

#import <Foundation/Foundation.h>
#include "VideoThreadProcessor.h"

@implementation VideoThreadProcessor

byte baVideoRenderBuffer[MAXWIDTH * MAXHEIGHT * 3 / 2 + 100];
byte baCurrentEncodedData[MAXWIDTH * MAXHEIGHT * 3 / 2];

- (id) init
{
    self = [super init];
    NSLog(@"Inside VideoThreadProcessor Constructor");
    _bRenderThreadActive = false;
    _bEncodeThreadActive = false;
    _bEventThreadActive = false;
    m_iFrameNumber = 0;
    return self;
}

- (void)SetVideoAPI:(CVideoAPI *)pVideoAPI
{
    m_pVideoAPI = pVideoAPI;
}

+ (id)GetInstance
{
    if(!m_pVideoThreadProcessor)
    {
        cout<<"Video_Team: m_pVideoThreadProcessor Initialized"<<endl;
        
        m_pVideoThreadProcessor = [[VideoThreadProcessor alloc] init];
        
    }
    return m_pVideoThreadProcessor;
}


- (void)SetEncodeBuffer:(RingBuffer<byte> *)pBuffer
{
    pEncodeBuffer = pBuffer;
}


- (void)SetWidthAndHeight:(int)iWidth withHeight:(int)iHeight
{
    m_iCameraHeight = iWidth;
    m_iCameraWidth = iHeight;
}

- (void)EventThread
{
    @autoreleasepool
    {
        printf("Starting EventThread....\n");
        
        while(_bEventThreadActive)
        {
            
            if(m_pVideoAPI->m_EventQueue.empty())
            {
                usleep(5*1000);
                continue;
            }
            
            int iEvent;
            iEvent = m_pVideoAPI->m_EventQueue.front();
            m_pVideoAPI->m_EventQueue.pop();
            
            if(m_pVideoAPI->m_bReInitialized == false && iEvent == 206)
            {
                //[[VideoCallProcessor GetInstance] ReInitializeCamera];
                
                [self.delegate ReInitializeCamera];
                m_pVideoAPI->m_bReInitialized = true;
                
            }
            usleep(1000);
            break;
            
        }
        
    }

}

- (void)RenderThread
{
    @autoreleasepool {
        printf("Starting RenderThread....\n");
        
        while(_bRenderThreadActive)
        {
            //break;
            printf("QQQ.size() = %lu\n", m_pVideoAPI->m_RenderQueue.size());
            
            if(m_pVideoAPI->m_RenderQueue.empty())
            {
                usleep(5*1000);
                continue;
            }
            
            byte *pGotData;
            
            while(m_pVideoAPI->m_RenderQueue.size() > 5)
            {
                pthread_mutex_lock(&m_pVideoAPI->pRenderQueueMutex);
                pGotData = m_pVideoAPI->m_RenderQueue.front();
                free(pGotData);
                m_pVideoAPI->m_RenderQueue.pop();
                m_pVideoAPI->m_RenderDataLenQueue.pop();
                pthread_mutex_unlock(&m_pVideoAPI->pRenderQueueMutex);
            }
            if(m_pVideoAPI->m_RenderQueue.empty())
            {
                usleep(5*1000);
                continue;
            }
            pGotData = m_pVideoAPI->m_RenderQueue.front();
            int iLen = m_pVideoAPI->m_RenderDataLenQueue.front();
            
            int height = CVideoAPI::GetInstance()->m_iReceivedHeight;
            int width = CVideoAPI::GetInstance()->m_iReceivedWidth;
            
            //int height = 640;
            //int width = 480;
            
            printf("Inside renderthread, iLen = %d --> ", iLen);
            for(int i=0;i<20;i++)
            {
                printf("%d ", pGotData[i]);
            }
            printf("\n");
            if(iLen>=MAX_FRAME_SIZE || iLen < 0)
            {
                if(pGotData)
                    free(pGotData);
                continue;
            }
            memcpy(baVideoRenderBuffer, pGotData, iLen);
            //int iDecodedDataLen = m_pVideoAPI->DecodeV(200, pGotData , iLen, baVideoRenderBuffer , height, width);
            
            pthread_mutex_lock(&m_pVideoAPI->pRenderQueueMutex);
            if(!m_pVideoAPI->m_RenderQueue.empty())
            {
                m_pVideoAPI->m_RenderQueue.pop();
            }
            if(!m_pVideoAPI->m_RenderDataLenQueue.empty())
            {
                m_pVideoAPI->m_RenderDataLenQueue.pop();
            }
            
            pthread_mutex_unlock(&m_pVideoAPI->pRenderQueueMutex);
            
            if(height > 0 && width > 0)
            {
                [self.delegate SetWidthAndHeightForRendering:width withHeight:height];
                [self.delegate BackConversion:baVideoRenderBuffer];
                
            }
            if(pGotData!= NULL)
            free(pGotData);
            usleep(1000);
            
            
        }
        
        while(!m_pVideoAPI->m_RenderQueue.empty())
        {
            byte *pGotData;
            pthread_mutex_lock(&m_pVideoAPI->pRenderQueueMutex);
            pGotData = m_pVideoAPI->m_RenderQueue.front();
            free(pGotData);
            m_pVideoAPI->m_RenderQueue.pop();

            pthread_mutex_unlock(&m_pVideoAPI->pRenderQueueMutex);
        }
        while(!m_pVideoAPI->m_RenderDataLenQueue.empty())
        {
            m_pVideoAPI->m_RenderDataLenQueue.pop();
        }
    }
}
/*
- (void)EncodeThread
{
    printf("\nStarting EncodeThread....\n");
    
    
    while(_bEncodeThreadActive)
    {
        @autoreleasepool {
            
            int indx;
            
            pthread_mutex_lock(&pmEncodeMutex);
            byte* pDataNow = pEncodeBuffer->getReadableAddress(&indx);
            pthread_mutex_unlock(&pmEncodeMutex);
            if(!pDataNow)
            {
                usleep(5000);
                //printf("Encoder Waiting\n");
                continue;
            }
            
            
            //### Processing Camera Raw Data to Encode
            int iFrameSize = m_iCameraWidth * m_iCameraHeight * 3 / 2;
            
            //printf("VideoTeam_Check: Inside EncodeThread m_iCameraWidth = %d, m_iCameraHeight = %d\n", m_iCameraWidth, m_iCameraHeight);
            
            int iEncodedDataLen = m_pVideoAPI->EncodeV(200, pDataNow, iFrameSize, baCurrentEncodedData);
            
            printf("VideoTeam_Check: Inside EncodeDataLen %d\n", iEncodedDataLen);
            
            
            //### Processing Encoded Data to List of small Packets
            baCurrentEncodedData[0] = 33; //Adding Media Type
            for(int i=0;i<20;i++)
                printf("%d ", baCurrentEncodedData[i]);
            printf("\n");
            
            unsigned char *pData = baCurrentEncodedData+1;
            
            m_pVideoAPI->ParseFrameIntoPacketsV(200, pData, iEncodedDataLen, m_iFrameNumber++);
            pEncodeBuffer->setIndexStatus(indx, AVAILABLE_TO_WRITE);
            
        }
        
    }
    
    printf("\nClosing EncodeThread...\n");
}
*/

@end