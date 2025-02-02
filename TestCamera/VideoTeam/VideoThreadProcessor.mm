//
//  VideoThreadProcessor.m
//  TestCamera 
//
//  Created by Apple on 11/17/15.
//
//

#import <Foundation/Foundation.h>
#include "VideoThreadProcessor.h"
#include "ClientRenderingBuffer.h"
#include "VideoCameraProcessor.h"


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
    m_pRenderingAvg = new CAverageCalculator("RenderignAverage");
    m_pClientRenderingBuffer = new ClientRenderingBuffer();
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

- (void)EventThread
{
    @autoreleasepool
    {
        printf("Starting EventThread....\n");
        
        while(_bEventThreadActive)
        {
            
            if(CVideoAPI::GetInstance()->m_EventQueue.empty())
            {
                usleep(5*1000);
                continue;
            }
            
            int iEvent;
            iEvent = CVideoAPI::GetInstance()->m_EventQueue.front();
            CVideoAPI::GetInstance()->m_EventQueue.pop();
            
            if(CVideoAPI::GetInstance()->m_bReInitialized == false && iEvent == 206)
            {
                //[[VideoCallProcessor GetInstance] ReInitializeCamera];
                
                [self.delegate ReInitializeCamera];
                CVideoAPI::GetInstance()->m_bReInitialized = true;
                
            }
            usleep(1000);
            break;
            
        }
        
    }

}
- (void)PushIntoClientRenderingBuffer:(unsigned char *)pData withLen:(int)iLen withHeight:(int)iHeight withWidth:(int)iWidth withOrientation:(int)iOrientation
{
    m_pClientRenderingBuffer->Queue(pData, iLen, iHeight, iWidth, iOrientation);
}


- (void)RenderThread
{
    int frameSize, videoHeight, videoWidth, orientation;
    long long llPrevTime;
    
    @autoreleasepool
    {
        while (_bRenderThreadActive)
        {
            //CLogPrinter_WriteLog(CLogPrinter::INFO, THREAD_LOG ,"CVideoRenderingThread::RenderingThreadProcedure() RUNNING RenderingThreadProcedure method");
            
            if (m_pClientRenderingBuffer->GetQueueSize() == 0)
            {
                SOSleep(10);
                continue;
            }
            else
            {
                frameSize = m_pClientRenderingBuffer->DeQueue(m_pRenderingData, videoHeight, videoWidth, orientation);
                
                if(videoHeight > 0 && videoWidth > 0)
                {
                    llPrevTime = CurrentTimeStamp();
                    [self.delegate SetWidthAndHeightForRendering:videoWidth withHeight:videoHeight];
                    [self.delegate BackConversion:m_pRenderingData];
                    m_pRenderingAvg->UpdateData(CurrentTimeStamp() - llPrevTime);
                }
            }
        }
   
    }
}


/**
 *
 *Previous Implementation
 */
/*
- (void)RenderThread
{
    @autoreleasepool {
        printf("Starting RenderThread....\n");
        long long llPrevTime = -1;
        int kounter = 0;
        while(_bRenderThreadActive)
        {
            //break;
            //printf("QQQ.size() = %lu\n", CVideoAPI::GetInstance()->m_RenderQueue.size());
            
            if(CVideoAPI::GetInstance()->m_RenderQueue.empty())
            {
                usleep(5*1000);
                continue;
            }
            
            byte *pGotData;
            
            while(CVideoAPI::GetInstance()->m_RenderQueue.size() > 5)
            {
                pthread_mutex_lock(&CVideoAPI::GetInstance()->pRenderQueueMutex);
                pGotData = CVideoAPI::GetInstance()->m_RenderQueue.front();
                free(pGotData);
                CVideoAPI::GetInstance()->m_RenderQueue.pop();
                CVideoAPI::GetInstance()->m_RenderDataLenQueue.pop();
                pthread_mutex_unlock(&CVideoAPI::GetInstance()->pRenderQueueMutex);
            }
            if(CVideoAPI::GetInstance()->m_RenderQueue.empty())
            {
                usleep(5*1000);
                continue;
            }
            pGotData = CVideoAPI::GetInstance()->m_RenderQueue.front();
            int iLen = CVideoAPI::GetInstance()->m_RenderDataLenQueue.front();
            
            int height = CVideoAPI::GetInstance()->m_iReceivedHeight;
            int width = CVideoAPI::GetInstance()->m_iReceivedWidth;
            
            //int height = 640;
            //int width = 480;
 
            printf("\n");
            if(iLen>=MAX_FRAME_SIZE || iLen < 0)
            {
                if(pGotData)
                    free(pGotData);
                continue;
            }
            memcpy(baVideoRenderBuffer, pGotData, iLen);
            //int iDecodedDataLen = CVideoAPI::GetInstance()->DecodeV(200, pGotData , iLen, baVideoRenderBuffer , height, width);
            
            pthread_mutex_lock(&CVideoAPI::GetInstance()->pRenderQueueMutex);
            if(!CVideoAPI::GetInstance()->m_RenderQueue.empty())
            {
                CVideoAPI::GetInstance()->m_RenderQueue.pop();
            }
            if(!CVideoAPI::GetInstance()->m_RenderDataLenQueue.empty())
            {
                CVideoAPI::GetInstance()->m_RenderDataLenQueue.pop();
            }
            
            pthread_mutex_unlock(&CVideoAPI::GetInstance()->pRenderQueueMutex);
            
            if(height > 0 && width > 0)
            {
                kounter++;
                llPrevTime = CurrentTimeStamp();
                [self.delegate SetWidthAndHeightForRendering:width withHeight:height];
                [self.delegate BackConversion:baVideoRenderBuffer];
                m_pRenderingAvg->UpdateData(CurrentTimeStamp() - llPrevTime);
                
                if(kounter%100==0)
                    cout<<"RenderingAverage : "<<m_pRenderingAvg->GetAverage()<<endl;
                
            }
            if(pGotData!= NULL)
            free(pGotData);
            usleep(1000);
            
            
        }
        
        while(!CVideoAPI::GetInstance()->m_RenderQueue.empty())
        {
            byte *pGotData;
            pthread_mutex_lock(&CVideoAPI::GetInstance()->pRenderQueueMutex);
            pGotData = CVideoAPI::GetInstance()->m_RenderQueue.front();
            free(pGotData);
            CVideoAPI::GetInstance()->m_RenderQueue.pop();

            pthread_mutex_unlock(&CVideoAPI::GetInstance()->pRenderQueueMutex);
        }
        while(!CVideoAPI::GetInstance()->m_RenderDataLenQueue.empty())
        {
            CVideoAPI::GetInstance()->m_RenderDataLenQueue.pop();
        }
    }
}
*/


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
            
            int iEncodedDataLen = CVideoAPI::GetInstance()->EncodeV(200, pDataNow, iFrameSize, baCurrentEncodedData);
            
            printf("VideoTeam_Check: Inside EncodeDataLen %d\n", iEncodedDataLen);
            
            
            //### Processing Encoded Data to List of small Packets
            baCurrentEncodedData[0] = 33; //Adding Media Type
            for(int i=0;i<20;i++)
                printf("%d ", baCurrentEncodedData[i]);
            printf("\n");
            
            unsigned char *pData = baCurrentEncodedData+1;
            
            CVideoAPI::GetInstance()->ParseFrameIntoPacketsV(200, pData, iEncodedDataLen, m_iFrameNumber++);
            pEncodeBuffer->setIndexStatus(indx, AVAILABLE_TO_WRITE);
            
        }
        
    }
    
    printf("\nClosing EncodeThread...\n");
}
*/
@end
