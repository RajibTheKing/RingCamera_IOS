//
//  VideoCallProcessor.m
//  TestCamera 
//
//  Created by Apple on 11/16/15.
//
//




#import <Foundation/Foundation.h>
#include "VideoCallProcessor.h"


#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <AssertMacros.h>
#import <AssetsLibrary/AssetsLibrary.h>
#include <stdio.h>





#include <pthread.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <netdb.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <arpa/inet.h>

#include <sstream>
#include <queue>


byte baVideoRenderBufferUVChannel [MAXWIDTH * MAXHEIGHT/2];
byte pRawYuv[MAXWIDTH * MAXHEIGHT*3/2 + 10];

template class RingBuffer<int>;
template class RingBuffer<byte>;


int g_iDEBUG_INFO = 1;
string g_sLOG_PATH = "Document/VideoEngine.log";

@implementation VideoCallProcessor

- (id) init
{
    self = [super init];
    NSLog(@"Inside Video Controller Constructor");
    //m_pVideoCallProcessor = nil;
    
    m_pVideoThreadProcessor =  [[VideoThreadProcessor alloc] init];
    m_pVideoThreadProcessor.delegate = self;
    
    _m_bStartVideoSending = false;
    m_pVideoConverter = new CVideoConverter();
    
    g_G729CodecNative = new G729CodecNative();
    
    int iRet = g_G729CodecNative->Open();
    cout <<  "Open returned " << iRet << "\n";
    
    
    return self;
}

+ (id)GetInstance
{
    if(!m_pVideoCallProcessor)
    {
        cout<<"Video_Team: m_pVideoCallProcessor Initialized"<<endl;
        
        m_pVideoCallProcessor = [[VideoCallProcessor alloc] init];
        
    }
    return m_pVideoCallProcessor;
}

- (void) Initialize:(long long)lUserId
{
    m_lUserId = lUserId;
    [self InitializeVideoEngine:lUserId];
}
- (void)SetRemoteIP:(string)sRemoteIP
{
    m_sRemoteIP = sRemoteIP;
}
- (void)SetFriendId:(long long)lFriendId
{
    m_lFriendId = lFriendId;
}
-(long long)GetUserId
{
    return m_lUserId;
}
-(long long)GetFriendId
{
    return m_lFriendId;
}
-(G729CodecNative *)GetG729
{
    return g_G729CodecNative;
}
- (void) InitializeVideoEngine:(long long) lUserId
{
    m_pVideoAPI =  CVideoAPI::GetInstance();
    
    
    cout<<"VideoCallProcessor:: VideoAPI->Init --> "<<"lUser = "<<lUserId<<endl;
    if(m_pVideoAPI->Init(100, g_sLOG_PATH.c_str(), g_iDEBUG_INFO) == 1)
    {
        printf("myVideoAPI Initialized\n");
        
        //string sAuthServerIP = m_sRemoteIP;
        //int iAuthServerPort = 32321;
        //string sAppSessionId = "12345678";
        //long long lFriendId = 200;
        
        ///bool bRet = m_pVideoAPI->SetAuthenticationServer(sAuthServerIP, iAuthServerPort, sAppSessionId);
        //cout<<"SetAuthenticationServer, bRet = "<<bRet<<endl;
        
        
        
        
    }
    else
    {
        printf("myVideoAPI is not Initialized\n");
    }
    //352x288
    /*printf("Check: m_iCameraHeight = %d, m_iCameraWidth = %d\n", m_iCameraHeight, m_iCameraWidth);
    m_pVideoAPI->StartVideoCall(200,m_iCameraHeight, m_iCameraWidth);
    
    cout<<"VideoCallProcessor:: VideoAPI->StartAudioCall --> "<<"lUser = "<<lUserId<<endl;
    m_pVideoAPI->StartAudioCall(200);*/
    
    string sAuthServerIP = "38.127.68.60";
    int iAuthServerPort = 10001;
    string sAppSessionId = "12345678";
    long long lFriendId = 200;
    long long lServerIP = /*645874748*/ 1011121958;
    int iFriendPort = 60003;
    NSString *nsServerIP = @"38.127.68.60";
    cout<<"Check--> sRemoteIP = "<<m_sRemoteIP<<endl;
    int iRet = (int)m_pVideoAPI->CreateSession(lFriendId, (int)2/*Video*/,  [VideoCallProcessor convertStringIPtoLongLong:nsServerIP], 20000);
    cout<<"CreateSession, iRet = "<<iRet<<endl;
    iRet = (int)m_pVideoAPI->CreateSession(lFriendId, (int)1/*Video*/,  [VideoCallProcessor convertStringIPtoLongLong:nsServerIP], 20000);
    
    return;
    
    CVideoAPI::GetInstance()->SetRelayServerInformation(200, (int)1/*Audio*/,  lServerIP, iFriendPort);
    
    CVideoAPI::GetInstance()->SetRelayServerInformation(200, (int)2/*Video*/,  lServerIP, iFriendPort);
    
    
    
    
    
    printf("Check: m_iCameraHeight = %d, m_iCameraWidth = %d\n", m_iCameraHeight, m_iCameraWidth);
    m_pVideoAPI->StartVideoCall(200,m_iCameraHeight, m_iCameraWidth);
    
    cout<<"VideoCallProcessor:: VideoAPI->StartAudioCall --> "<<"lUser = "<<lUserId<<endl;
    m_pVideoAPI->StartAudioCall(200);
    
    
    
    //m_pVideoAPI->SetRelayServerInformation(lFriendId, (int)2/*Audio*/,  m_sRemoteIP, 15000);
    
    [m_pVideoThreadProcessor SetVideoAPI:m_pVideoAPI];
    [m_pVideoSockets SetVideoAPI:m_pVideoAPI];
    [m_pVideoSockets SetUserID:lUserId];
     
    
}


- (void)SetWidthAndHeight:(int)iWidth withHeight:(int)iHeight
{
    m_iCameraHeight = iWidth;
    m_iCameraWidth = iHeight;
    [m_pVideoThreadProcessor SetWidthAndHeight:iHeight withHeight:iWidth];
    
}

- (void)SetWidthAndHeightForRendering:(int)iWidth withHeight:(int)iHeight
{
    m_iRenderHeight = iHeight;
    m_iRenderWidth = iWidth;
}




- (void)SetVideoSockets:(VideoSockets *)pVideoSockets
{
    m_pVideoSockets = pVideoSockets;
}




- (void)StartAllThreads
{
    m_pVideoThreadProcessor.bRenderThreadActive = true;
    
    m_pVideoThreadProcessor.bEncodeThreadActive = true;
    
    /*dispatch_queue_t EncoderQ = dispatch_queue_create("EncoderQ",DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(EncoderQ, ^{
        [m_pVideoThreadProcessor EncodeThread];
    });*/
    
    
    dispatch_queue_t RenderThreadQ = dispatch_queue_create("RenderThreadQ",DISPATCH_QUEUE_CONCURRENT);
     dispatch_async(RenderThreadQ, ^{
     [m_pVideoThreadProcessor RenderThread];
     });
    
}

- (void)CloseAllThreads
{
    m_pVideoThreadProcessor.bRenderThreadActive = false;
    
    m_pVideoThreadProcessor.bEncodeThreadActive = false;
    //CVideoAPI::GetInstance()->StopVideoCallV(m_lUserId);
    //CVideoAPI::GetInstance()->ReleaseV();

}


- (NSError *)InitializeCameraSession:(AVCaptureSession **)session
                    withDeviceOutput:(AVCaptureVideoDataOutput **)videoDataOutput
                           withLayer:(AVCaptureVideoPreviewLayer **)previewLayer
                          withHeight:(int *)iHeight
                           withWidth:(int *)iWidth
{
    
    NSError *error = nil;
    NSDictionary *colorOutputSettings;
    
    *session = [AVCaptureSession new];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        [*session setSessionPreset:AVCaptureSessionPreset352x288];
        
        *iHeight = 352;
        *iWidth = 288;
        
        [self SetWidthAndHeight:*iHeight withHeight:*iWidth];
        m_pEncodeBuffer = new RingBuffer<byte>(m_iCameraWidth,m_iCameraHeight,5);
        [m_pVideoThreadProcessor SetEncodeBuffer:m_pEncodeBuffer];
        
    }
    else
        [*session setSessionPreset:AVCaptureSessionPresetPhoto];
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    

    if ( [*session canAddInput:deviceInput] )
        [*session addInput:deviceInput];
    
    *videoDataOutput = [AVCaptureVideoDataOutput new];
    
    
    
    //Video Setting For RGBA Data
    //colorOutputSettings = [NSDictionary dictionaryWithObject:
    //								   [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    //Video Setting for YUV Data
    colorOutputSettings = [NSDictionary dictionaryWithObject:
                           [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    [*videoDataOutput setVideoSettings:colorOutputSettings];
    [*videoDataOutput setAlwaysDiscardsLateVideoFrames:YES]; // discard if the data output queue is blocked (as we process the still image)
    
    
    
    
    if ( [*session canAddOutput:*videoDataOutput] )
    {
        [*session addOutput:*videoDataOutput];
    }
    
    
    [[*videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:NO];
    
    
    
    videoDataOutputQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    [*videoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
    
    
    *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:*session];
    [*previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
    [*previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    
    
    
    AVCaptureDevicePosition desiredPosition;
    /*if (isUsingFrontFacingCamera)
        desiredPosition = AVCaptureDevicePositionBack;
    else
        desiredPosition = AVCaptureDevicePositionFront;
     */
    desiredPosition = AVCaptureDevicePositionFront;
    
    
    for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if ([d position] == desiredPosition) {
            [[*previewLayer session] beginConfiguration];
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
            for (AVCaptureInput *oldInput in [[*previewLayer session] inputs]) {
                [[*previewLayer session] removeInput:oldInput];
            }
            [[*previewLayer session] addInput:input];
            [[*previewLayer session] commitConfiguration];
            break;
        }
    }
    
    
    return error;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    
    if(!_m_bStartVideoSending) return;
    [self FrontConversion: sampleBuffer fromConnection:connection];
}


- (int)FrontConversion:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    printf("Rajib_Check: Inside FrontConversion\n");

    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    [connection setVideoMirrored:true];
    
    
    usleep(15*1000);
    
    //### Step 2: Controlling FPS, Currently disabled
    //[connection setVideoMinFrameDuration:CMTimeMake(1, 15.0)];
    //[connection setVideoMaxFrameDuration:CMTimeMake(1, 17.0)];
    
    
    
    CVImageBufferRef IB = CMSampleBufferGetImageBuffer(sampleBuffer);
    int iHeight = CVPixelBufferGetHeight(IB);
    int iWidth = CVPixelBufferGetWidth(IB);
    m_iCameraHeight = iHeight;
    m_iCameraWidth = iWidth;
    
    printf("VideoTeam_Check: iHeight = %d, iWidth = %d\n", iHeight , iWidth);
    CVPixelBufferLockBaseAddress(IB,0);
    CVPixelBufferLockBaseAddress(IB,1);
    byte *y_ch0 = (byte *)CVPixelBufferGetBaseAddressOfPlane(IB, 0); // Y-Plane = y_ch0
    byte *y_ch1 = (byte *)CVPixelBufferGetBaseAddressOfPlane(IB, 1); // UV-Plane = y_ch1
    
    //byte *pCameraData = (byte *)malloc(m_iCameraHeight * m_iCameraWidth * 3 / 2);
    //memcpy(pCameraData, y_ch0, bytesPerRow0);
    //memcpy(pCameraData + bytesPerRow0, y_ch1, bytesPerRow1);
    CVPixelBufferUnlockBaseAddress(IB,0);
    CVPixelBufferUnlockBaseAddress(IB,1);
    
    
    //int iWritebleIndex[1];
    //byte* pRawYuv = m_pEncodeBuffer->getWritableAddress(iWritebleIndex);
    
    //m_pVideoConverter->Convert_YUVNV12_To_YUVI420(pCameraData, pRawYuv, m_iCameraHeight, m_iCameraWidth);
    
    int iVideoHeight = m_iCameraHeight;
    int iVideoWidth = m_iCameraWidth;
    int YPlaneLength = iVideoHeight*iVideoWidth;
    int VPlaneLength = YPlaneLength >> 2;
    //int UVPlaneMidPoint = YPlaneLength + VPlaneLength;
    //int UVPlaneEnd = UVPlaneMidPoint + VPlaneLength;
    
    memcpy(pRawYuv, y_ch0, YPlaneLength);
    memcpy(pRawYuv+YPlaneLength, y_ch1, VPlaneLength+VPlaneLength);
    
    //m_pVideoConverter->Convert_YUVNV12_To_YUVI420(y_ch0, y_ch1, pRawYuv, m_iCameraHeight, m_iCameraWidth);
    //m_pEncodeBuffer->setIndexStatus(iWritebleIndex[0], AVAILABLE_TO_READ);
    
    printf("Rajib_Check: Front Bits  --> ");
    for(int i=0;i<20;i++)
        printf("%d ", pRawYuv[i]);
    printf("\n");
    //m_pVideoAPI->EncodeAndTransferV(m_lUserId, pRawYuv, m_iCameraHeight * m_iCameraWidth * 3 / 2);
    
    m_pVideoAPI->SendVideoDataV(200, pRawYuv, m_iCameraHeight * m_iCameraWidth * 3 / 2);
    return 0;
}





- (void)BackConversion:(byte*)pRenderBuffer //Delegate from RenderThread
{
    @autoreleasepool {
        if(!pRenderBuffer)
        {
            printf("Inside BackConversion--> pData is NULL\n");
            return;
        }
        
        int iRet;
        
        
        //iRet = m_pVideoConverter->Convert_YUVI420_To_YUVNV12(pRenderBuffer, pRenderBuffer, baVideoRenderBufferUVChannel, m_iRenderHeight, m_iRenderWidth);
        
        int iVideoHeight = m_iRenderHeight;
        int iVideoWidth = m_iRenderWidth;
        int YPlaneLength = iVideoHeight*iVideoWidth;
        int VPlaneLength = YPlaneLength >> 2;
        int UVPlaneMidPoint = YPlaneLength + VPlaneLength;
        int UVPlaneEnd = UVPlaneMidPoint + VPlaneLength;
        memcpy(baVideoRenderBufferUVChannel, pRenderBuffer + YPlaneLength, VPlaneLength + VPlaneLength);
               
        
        printf("Check inside backconversion: ");
        for(int i=0;i<20;i++)
            printf("%d ", pRenderBuffer[i]);
        printf("\n");
        CVPixelBufferRef pixelBuffer;
        pixelBuffer = m_pVideoConverter->Convert_YUVNV12_To_CVPixelBufferRef(pRenderBuffer, baVideoRenderBufferUVChannel, m_iRenderHeight, m_iRenderWidth);
        
        
        
        UIImage *Mynnnimage = m_pVideoConverter->Convert_CVPixelBufferRef_To_UIImage(pixelBuffer);
        
        CVPixelBufferRelease(pixelBuffer);
        
        [self.delegate RenderImage:Mynnnimage];
        
        return; //Success
    }
    
}



+(long long)convertStringIPtoLongLong:(NSString *)ipAddr
{
    struct in_addr addr;
    long long ip = 0;
    if (inet_aton([ipAddr UTF8String], &addr) != 0)
    {
        ip = addr.s_addr;
    }
    return ip;
}


- (void)dealloc {
    [super dealloc];
}
@end
