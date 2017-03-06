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
byte pScaledVideo[MAXWIDTH * MAXHEIGHT*3/2 + 10];

template class RingBuffer<int>;
template class RingBuffer<byte>;


int g_iDEBUG_INFO = 1;
string g_sLOG_PATH = "Document/VideoEngine.log";

#define USE_FORCE_HIGH_FPS_INITIALIZATION


@implementation VideoCallProcessor

- (id) init
{
    self = [super init];
    NSLog(@"Inside Video Controller Constructor");
    //m_pVideoCallProcessor = nil;
    
    m_pVTP =  [VideoThreadProcessor GetInstance];
    m_pVTP.delegate = self;
    
    _m_bStartVideoSending = false;
    m_pVideoConverter = new CVideoConverter();
    
    g_G729CodecNative = new G729CodecNative();
    
    int iRet = g_G729CodecNative->Open();
    cout <<  "Open returned " << iRet << "\n";
    
    m_nsServerIP = @"";
    
    long long currentTime = CurrentTimeStamp()%10000;
    char charCurrentTime[50];
    sprintf(charCurrentTime, "%lld", currentTime);
    string sWriteFileName = "YuvTest_" + string(charCurrentTime) + ".yuv";
    NSString* nsWriteFileName = [NSString stringWithUTF8String:sWriteFileName.c_str()];
    
    [self InitializeFilePointer:m_FileForDump fileName:nsWriteFileName];
    
    NSFileHandle *handle;
    NSArray *Docpaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [Docpaths objectAtIndex:0];
    NSString *filePathyuv = [documentsDirectory stringByAppendingPathComponent:@"test_chunk.mp4"];
    handle = [NSFileHandle fileHandleForUpdatingAtPath:filePathyuv];
    char *filePathcharyuv = (char*)[filePathyuv UTF8String];
    m_FileReadFromDump = fopen(filePathcharyuv, "rb");
    _m_fR = 2;
    _m_Threashold=0;
    
    /*unsigned char c;
    while(fscanf(m_FileReadFromDump, "%u", &c)==1)
    {
        
    }*/

    
    _m_iLoudSpeakerEnable=0;
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

- (int) Initialize:(long long)lUserId withServerIP:(NSString *)sMyIP
{
    m_lUserId = lUserId;
    m_nsServerIP = sMyIP;
    
    return [self InitializeVideoEngine:lUserId];
}
- (void)SetRemoteIP:(string)sRemoteIP
{
    m_sRemoteIP = sRemoteIP;
}
- (void)SetFriendPort:(int)iPort
{
    m_iActualFriendPort = iPort;
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
- (int)InitializeVideoEngine:(long long) lUserId
{
    m_pVideoAPI =  CVideoAPI::GetInstance();
    
    
    cout<<"VideoCallProcessor:: VideoAPI->Init --> "<<"lUser = "<<lUserId<<endl;
    if(m_pVideoAPI->Init(100, g_sLOG_PATH.c_str(), g_iDEBUG_INFO) == 1)
    {
        printf("myVideoAPI Initialized\n");
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
    
    int iAuthServerPort = 10001;
    string sAppSessionId = "12345678";
    long long lFriendId = 200;
    long long lServerIP = /*645874748*/ 1011121958;
    int iFriendPort = m_iActualFriendPort;
    
    //NSString *nsServerIP =  @"38.127.68.60"/*@"192.168.57.113"*/;
    //NSString *nsServerIP =  @"192.168.57.104";
    
    NSString *nsServerIP = m_nsServerIP;
    
    cout<<"Check--> sRemoteIP = "<<m_sRemoteIP<<endl;
    
    //m_pVideoAPI->SetLoggingState(true,5);
    string sActualServerIP = [m_nsServerIP UTF8String];
    
    VideoSockets::GetInstance()->InitializeSocket("192.168.67.100", m_iActualFriendPort);
    
    VideoSockets::GetInstance()->StartDataReceiverThread();
    
    
    int iRet;
    
#if 1
    iRet = (int)m_pVideoAPI->CreateSession(lFriendId, (int)1/*Audio*/,  [VideoCallProcessor convertStringIPtoLongLong:nsServerIP], lFriendId);
    cout<<"CreateSession, Audio, iRet = "<<iRet<<endl;
    iRet = (int)m_pVideoAPI->CreateSession(lFriendId, (int)2/*Video*/,  [VideoCallProcessor convertStringIPtoLongLong:nsServerIP], lFriendId);
    cout<<"CreateSession, Video, iRet = "<<iRet<<endl;
    
    CVideoAPI::GetInstance()->SetRelayServerInformation(200, (int)1/*Audio*/,  [VideoCallProcessor convertStringIPtoLongLong:nsServerIP], iFriendPort);
    
    CVideoAPI::GetInstance()->SetRelayServerInformation(200, (int)2/*Video*/,  [VideoCallProcessor convertStringIPtoLongLong:nsServerIP], iFriendPort);
    
    cout<<"Here height and width = "<<m_iCameraHeight<<", "<<m_iCameraWidth<<endl;
    
    if(m_iCameraHeight * m_iCameraWidth == 288 * 352)
        CVideoAPI::GetInstance()->SetDeviceCapabilityResults(207, 640, 480, 352, 288);
    else
        CVideoAPI::GetInstance()->SetDeviceCapabilityResults(205, 640, 480, 352, 288);
    
    
   
    
    if(m_iActualFriendPort == 60001)
        iRet = m_pVideoAPI->StartAudioCall(200, SERVICE_TYPE_LIVE_STREAM);
    else
        iRet = m_pVideoAPI->StartAudioCall(200, SERVICE_TYPE_LIVE_STREAM);
    
   
    
    //iRet = m_pVideoAPI->StartAudioCall(200, SERVICE_TYPE_CALL);
    
    int iRetStartVideoCall;
    
    
    /*
    if(m_iActualFriendPort == 60001)
        iRetStartVideoCall = m_pVideoAPI->StartVideoCall(200,320, 180, SERVICE_TYPE_LIVE_STREAM, ENTITY_TYPE_PUBLISHER, 500);
    else
        iRetStartVideoCall = m_pVideoAPI->StartVideoCall(200,320, 180, SERVICE_TYPE_LIVE_STREAM, ENTITY_TYPE_VIEWER, 500);
    */
    if(m_iActualFriendPort == 60001)
        iRetStartVideoCall = m_pVideoAPI->StartVideoCall(200,m_iCameraHeight, m_iCameraWidth, SERVICE_TYPE_LIVE_STREAM, ENTITY_TYPE_PUBLISHER, 500);
    else
        iRetStartVideoCall = m_pVideoAPI->StartVideoCall(200,m_iCameraHeight, m_iCameraWidth, SERVICE_TYPE_LIVE_STREAM, ENTITY_TYPE_VIEWER, 500);
    
    //iRetStartVideoCall = m_pVideoAPI->StartVideoCall(200,352, 288, SERVICE_TYPE_CALL, ENTITY_TYPE_CALLER);
    
    
    
    NSLog(@"StartVideoCaLL returned, iRet = %d", iRet);
    //iRet = m_pVideoAPI->CheckDeviceCapability(200, m_iCameraHeight, m_iCameraWidth);
    //m_bCheckCall = true;
#endif
    
    [m_pVTP SetVideoAPI:m_pVideoAPI];
    /*dispatch_queue_t SendDummyDataQ = dispatch_queue_create("SendDummyDataQ",DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(SendDummyDataQ, ^{
        [self SendDummyData];
    });*/
    return 1;
}

-(void)SendDummyData
{
    while(true)
    {
        if(!pRawYuv) cout<<"pRaw is NuLL"<<endl;
        if(m_pVideoAPI == NULL) cout<<"m_pVideoAPI is NULL"<<endl;
        
        
        //m_iCameraHeight = 640;
        //m_iCameraWidth = 480;
        /*
        for(int i=0;i<m_iCameraHeight * m_iCameraWidth * 3 / 2; i++)
        {
            pRawYuv[i] = rand()%255;
            
        }*/
        int iRet = -1;
        iRet = m_pVideoAPI->SendVideoDataV(200, pRawYuv, m_iCameraHeight * m_iCameraWidth * 3 / 2,0,3);
        //cout<<"ClientEnd--> iRet = "<<iRet<<", Size = "<<m_iCameraHeight * m_iCameraWidth * 3 / 2<<endl;
        usleep(60*1000);
    }
}
- (void)SetHeightAndWidth:(int)iHeight withWidth:(int)iWidth
{
    m_iCameraHeight = iHeight;
    m_iCameraWidth = iWidth;
    
    [m_pVTP SetHeightAndWidth:iHeight withWidth:iWidth];
    
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
    m_pVTP.bRenderThreadActive = true;
    
    m_pVTP.bEncodeThreadActive = true;
    
    m_pVTP.bEventThreadActive = true;
    
    /*dispatch_queue_t EncoderQ = dispatch_queue_create("EncoderQ",DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(EncoderQ, ^{
        [m_pVTP EncodeThread];
    });*/
    
    
    dispatch_queue_t RenderThreadQ = dispatch_queue_create("RenderThreadQ",DISPATCH_QUEUE_CONCURRENT);
     dispatch_async(RenderThreadQ, ^{
         [m_pVTP RenderThread];
     });
    
    dispatch_queue_t EventThreadQ = dispatch_queue_create("EventThreadQ",DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(EventThreadQ, ^{
        [m_pVTP EventThread];
    });
}

- (void)CloseAllThreads
{
    m_pVTP.bRenderThreadActive = false;
    
    m_pVTP.bEncodeThreadActive = false;
    
    m_pVTP.bEventThreadActive = false;
    
    VideoSockets::GetInstance()->StopDataReceiverThread();
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
        if(*iHeight * *iWidth== 288 * 352)
        {
            [*session setSessionPreset:AVCaptureSessionPreset352x288];
            //[*session setSessionPreset:AVCaptureSessionPreset1280x720];
            
        }
        else if(*iHeight * *iWidth == 480 * 640)
        {
            [*session setSessionPreset:AVCaptureSessionPreset640x480];
        }
        else
        {
            cout<<"Error: Resolution Is not in Correct Format"<<endl;
        }
        
        //*iHeight = 352;
        //*iWidth = 288;
        
        //[*session setSessionPreset:AVCaptureSessionPreset640x480];
        //*iHeight = 640;
        //*iWidth = 480;
        
        
        [self SetHeightAndWidth:*iHeight withWidth:*iWidth];
        
        m_pEncodeBuffer = new RingBuffer<byte>(m_iCameraWidth,m_iCameraHeight,5);
        [m_pVTP SetEncodeBuffer:m_pEncodeBuffer];
        
    }
    else
        [*session setSessionPreset:AVCaptureSessionPresetPhoto];
    
    
    /*AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    

    if ( [*session canAddInput:deviceInput] )
        [*session addInput:deviceInput];
    */
    
    *videoDataOutput = [AVCaptureVideoDataOutput new];
    
    
    
    //Video Setting For RGBA Data
    //colorOutputSettings = [NSDictionary dictionaryWithObject:
    //								   [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    //Video Setting for YUV Data
    colorOutputSettings = [NSDictionary dictionaryWithObject:
                           [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    [*videoDataOutput setVideoSettings:colorOutputSettings];
    [*videoDataOutput setAlwaysDiscardsLateVideoFrames:NO]; // discard if the data output queue is blocked (as we process the still image)

    [[*videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:NO];
    [[*videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:AVCaptureVideoOrientationPortrait];
    
    
    
    AVCaptureConnection *conn = [*videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    NSLog(@"Trying to Set AVCaptureVideoOrientationPortrait");
    if([conn isVideoOrientationSupported])
    {
        NSLog(@"Setting VideoOrientation with AVCaptureVideoOrientationPortrait");
        [conn setVideoOrientation:AVCaptureVideoOrientationPortrait];
    }
    
    
    
    
    if ( [*session canAddOutput:*videoDataOutput] )
    {
        [*session addOutput:*videoDataOutput];
    }
    
    
    
    
    
    videoDataOutputQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    [*videoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
    

    
    *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:*session];
    [*previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
    [*previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    
    //[*previewLayer setOrientation:AVCaptureVideoOrientationPortrait];
    
    
    
    
    
    
    
    
    AVCaptureDevicePosition desiredPosition;
    desiredPosition = AVCaptureDevicePositionFront;
    //desiredPosition = AVCaptureDevicePositionBack;
    

#ifdef USE_FORCE_HIGH_FPS_INITIALIZATION
    for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo])
    {
        if ([d position] == desiredPosition)
        {
            [[*previewLayer session] beginConfiguration];
            
            
            //d.activeVideoMinFrameDuration = CMTimeMake(1, (int32_t)30);
            
            //d->activeVideoMaxFrameDuration = CMTimeMake(1, (int32_t)30);
            
            //[d setActiveVideoMaxFrameDuration:CMTimeMake(1, (int32_t)30)];
            
            if ([AVCaptureDevice respondsToSelector:@selector(requestAccessForMediaType: completionHandler:)]) {
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                    // Will get here on both iOS 7 & 8 even though camera permissions weren't required
                    // until iOS 8. So for iOS 7 permission will always be granted.
                    if (granted) {
                        // Permission has been granted. Use dispatch_async for any UI updating
                        // code because this block may be executed in a thread.
                        dispatch_async(dispatch_get_main_queue(), ^{
                            //[self doStuff];
                            NSLog(@"Here 1");
                            if ([d lockForConfiguration:nil]) {
                                
                                NSLog(@"selected format");
                                //d.activeFormat = selectedFormat;
                                d.activeVideoMinFrameDuration = CMTimeMake(1, (int32_t)30);
                                d.activeVideoMaxFrameDuration = CMTimeMake(1, (int32_t)30);
                                [d unlockForConfiguration];
                            }
                            
                        });
                    } else {
                        // Permission has been denied.
                        NSLog(@"selected Permission has been denied.");
                    }
                }];
            } else {
                // We are on iOS <= 6. Just do what we need to do.
                //[self doStuff];
                NSLog(@"We are on iOS <= 6. Just do what we need to do.");
            }
            
            
            
            
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
            
            for (AVCaptureInput *oldInput in [[*previewLayer session] inputs])
            {
                [[*previewLayer session] removeInput:oldInput];
            }
            
            [[*previewLayer session] addInput:input];
            [[*previewLayer session] commitConfiguration];
            break;
        }
    }
#else
    for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo])
    {
        if ([d position] == desiredPosition)
        {
            [[*previewLayer session] beginConfiguration];
            
            /*for (AVCaptureInput *oldInput in [[*previewLayer session] inputs])
            {
                [[*previewLayer session] removeInput:oldInput];
            }*/
            
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
            [[*previewLayer session] addInput:input];
            [[*previewLayer session] commitConfiguration];
        }
        
    }
    //Do Nothing
#endif
    
    
   
    
    return error;
}


- (void)SetCameraResolutionByNotification:(int)iHeight withWidth:(int)iWidth
{

    [self.delegate SetCameraResolutionByNotification:iHeight withWidth:iWidth];
    
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    
    //if(!_m_bStartVideoSending) return;
    
    [self FrontConversion: sampleBuffer fromConnection:connection];
}

- (void)UpdateStatusMessage: (string)sMsg
{
    [self.delegate UpdateStatusMessage:sMsg];
}
int tempCounter = 0;
int stride = 352;
byte newData[640*480*3/2];

- (int)FrontConversion:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{

    
    
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    [connection setVideoMirrored:false];

    //usleep(15*1000);
    //### Step 2: Controlling FPS, Currently disabled
    //[connection setVideoMinFrameDuration:CMTimeMake(1, 15.0)];
    //[connection setVideoMaxFrameDuration:CMTimeMake(1, 17.0)];
    
    
    CVImageBufferRef IB = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(IB,0);
    CVPixelBufferLockBaseAddress(IB,1);
    
    int iHeight = CVPixelBufferGetHeight(IB);
    int iWidth = CVPixelBufferGetWidth(IB);
    int bytesPerRow = CVPixelBufferGetBytesPerRow(IB);
    
    m_iCameraHeight = iHeight;
    m_iCameraWidth = iWidth;
    
    byte *base = (byte *)CVPixelBufferGetBaseAddress(IB); // baseAddress
    byte *y_ch0 = (byte *)CVPixelBufferGetBaseAddressOfPlane(IB, 0); // Y-Plane = y_ch0
    byte *y_ch1 = (byte *)CVPixelBufferGetBaseAddressOfPlane(IB, 1); // UV-Plane = y_ch1
    
    int baseDiff = y_ch0 - base;     //y_base = 64;
    int uv_y = y_ch1-y_ch0;       //uv_y = 176640;
    int delta = uv_y - iWidth*iHeight;
    int padding = delta /  iHeight; //Calculate Padding
    //NSLog(@"VideoTeam_Check: iHeight = %i, iWidth = %i, bytesPerRow = %i, ExtendedWidth = %i, (baseDiff,uv-y,delta) = (%i,%i,%i) R = %f\n", iHeight , iWidth, bytesPerRow, bytesPerRow/4, baseDiff, uv_y, delta, _m_fR);
    //if(iHeight == 288) return 0;
    
    
    int iVideoHeight = m_iCameraHeight;
    int iVideoWidth = m_iCameraWidth;
    int YPlaneLength = iVideoHeight*iVideoWidth;
    int VPlaneLength = YPlaneLength >> 2;
    
    unsigned char *p = pRawYuv;
    for(int i=0;i<iVideoHeight;i++)
    {
        memcpy(p + i * iVideoWidth, y_ch0 + i * (iVideoWidth+padding), iVideoWidth);
    }
    
    p = p + YPlaneLength;
    for(int i=0; i*iVideoWidth < (VPlaneLength*2); i++)
    {
        memcpy(p + i * iVideoWidth, y_ch1 + i * (iVideoWidth+padding), iVideoWidth);
    }
    
        
    //memcpy(pRawYuv, y_ch0, YPlaneLength);
    //memcpy(pRawYuv+YPlaneLength, y_ch1, VPlaneLength+VPlaneLength);

    //
    
    CVPixelBufferUnlockBaseAddress(IB,0);
    CVPixelBufferUnlockBaseAddress(IB,1);
    
    
    /*****
     *DownScale 2 / 3
     ***/
    /*int iNewHeight = m_iCameraHeight, iNewWidth = m_iCameraWidth;
     memcpy(pScaledVideo, pRawYuv, iNewHeight*iNewWidth*3/2);
    long long llDownSclae_3_2_Now = CurrentTimeStamp();
     m_pVideoConverter->DownScale_3_2_YUV420(pRawYuv, iNewHeight, iNewWidth, pScaledVideo);
    printf("long long llDownSclae_3_2_Now = CurrentTimeStamp(); needed = %lld\n", CurrentTimeStamp() - llDownSclae_3_2_Now);
     m_iCameraWidth = iNewWidth;
     m_iCameraHeight = iNewHeight;
     memcpy(pRawYuv, pScaledVideo, iNewHeight*iNewWidth*3/2);
    */
    
    
    /*****
    *DownScaleTest Code
    ***/
    /*int iNewHeight = m_iCameraHeight, iNewWidth = m_iCameraWidth;
    memcpy(pScaledVideo, pRawYuv, iNewHeight*iNewWidth*3/2);
    long long llDownScale = CurrentTimeStamp();
    m_pVideoConverter->DownScaleVideoDataWithAverageVersion2(pRawYuv, iNewHeight, iNewWidth, pScaledVideo);
    printf("DownScaleVideoDataWithAverage needed = %lld\n", CurrentTimeStamp() - llDownScale);
    m_iCameraWidth = iNewWidth;
    m_iCameraHeight = iNewHeight;
    memcpy(pRawYuv, pScaledVideo, iNewHeight*iNewWidth*3/2);
    
    m_pVideoConverter->DownScaleVideoDataWithAverageVersion2(pRawYuv, iNewHeight, iNewWidth, pScaledVideo);
    printf("DownScaleVideoDataWithAverage needed = %lld\n", CurrentTimeStamp() - llDownScale);
    m_iCameraWidth = iNewWidth;
    m_iCameraHeight = iNewHeight;
    memcpy(pRawYuv, pScaledVideo, iNewHeight*iNewWidth*3/2);
    */
    
    
    
    /*****
     *GaussianBlur
     **/
    /*
    long long now = CurrentTimeStamp();
    int iNewHeight = m_iCameraHeight, iNewWidth = m_iCameraWidth;
    memcpy(pScaledVideo, pRawYuv, iNewHeight*iNewWidth*3/2);
    m_pVideoConverter->GaussianBlur_4thApproach(pScaledVideo, pRawYuv, iNewHeight, iNewWidth, _m_fR);
    m_iCameraWidth = iNewWidth;
    m_iCameraHeight = iNewHeight;
    memcpy(pRawYuv, pScaledVideo, iNewHeight*iNewWidth*3/2);
    cout<<"GaussianBlur_4thApproach Time needed = "<<CurrentTimeStamp() - now<<endl;
    
    */
    
    /*****
     *Enhance Temperature
     **/
    /*int iNewHeight = m_iCameraHeight, iNewWidth = m_iCameraWidth;
     memcpy(pScaledVideo, pRawYuv, iNewHeight*iNewWidth*3/2);
    m_pVideoConverter->EnhanceTemperature(pRawYuv, iNewHeight, iNewWidth, _m_Threashold);*/
    
    
    /******
     * Detect Skin
     ***/
    //int iNewHeight = m_iCameraHeight, iNewWidth = m_iCameraWidth;
    //m_pVideoConverter->DetectAndShowOnlySkin(pRawYuv, iNewHeight, iNewWidth);
    

    int iRet = CVideoAPI::GetInstance()->SendVideoData(200, pRawYuv, m_iCameraHeight * m_iCameraWidth * 3 / 2, 0,3);
    
    
    
    //Sending to OwnReceiving Thread Directly using VideoAPI
    //m_pVideoConverter->mirrorRotateAndConvertNV12ToI420(pRawYuv, newData, iVideoHeight, iVideoWidth);
    //m_pVideoConverter->ConvertI420ToNV12(newData, iVideoHeight, iVideoWidth);
    
    
    
    /*
    CVideoAPI::GetInstance()->m_iReceivedHeight = iVideoHeight;
    CVideoAPI::GetInstance()->m_iReceivedWidth = iVideoWidth;
    CVideoAPI::GetInstance()->ReceiveFullFrame(pRawYuv, m_iCameraHeight * m_iCameraWidth * 3 / 2);
    */
    
    /*
    //Sending to OwnViewer Directly
    m_iRenderHeight = iVideoHeight;
    m_iRenderWidth = iVideoWidth;
    [self BackConversion:pRawYuv];
    */
    
    //cout<<"Rajib_Check: SendVideoDataV, DataLen = "<<m_iCameraHeight * m_iCameraWidth * 3 / 2<<", iRet = "<<iRet<<endl;
    
    //printf("Rajib_Check: Trying to SendVideoDataV\n");
    
    /*
    if(tempCounter<300)
    {
        //printf("TheKing--> tempCounter = %d\n", tempCounter);
        //cout<<"TheKing--> tempCounter = "<<tempCounter<<endl;
        tempCounter++;
        
        //ConvertNV12ToI420(pRawYuv, m_iCameraHeight, m_iCameraWidth);
        
        //byte newData[352*288*3/2];
        
        //m_pVideoConverter->mirrorRotateAndConvertNV12ToI420(pRawYuv, newData, iVideoHeight, iVideoWidth);
        
        [self WriteToFile:pRawYuv dataLength:m_iCameraHeight * m_iCameraWidth * 3 / 2 filePointer:m_FileForDump];
    }
    else
    {
        cout<<"DONE!!"<<endl;
        [self UpdateStatusMessage:"FileWrite Completed!!!!"];
    }
    */
    return 0;
}

int ConvertNV12ToI420(unsigned char *convertingData, int iheight, int iwidth)
{
    
    int m_iVideoHeight = iheight;
    int m_iVideoWidth = iwidth;
    int m_YPlaneLength = m_iVideoHeight*m_iVideoWidth;
    int m_VPlaneLength = m_YPlaneLength >> 2;
    int m_UVPlaneMidPoint = m_YPlaneLength + m_VPlaneLength;
    int m_UVPlaneEnd = (m_UVPlaneMidPoint + m_VPlaneLength);
    
    
    int i, j, k;
    
    unsigned char m_pVPlane[iheight * iwidth * 3 / 2 + 100];
    
    for (i = m_YPlaneLength, j = 0, k = i; i < m_UVPlaneEnd; i += 2, j++, k++)
    {
        m_pVPlane[j] = convertingData[i + 1];
        convertingData[k] = convertingData[i];
    }
    
    memcpy(convertingData + m_UVPlaneMidPoint, m_pVPlane, m_VPlaneLength);
    
    return m_UVPlaneEnd;
}




- (void)BackConversion:(byte*)pRenderBuffer //Delegate from RenderThread
{
    /*
    if(tempCounter<300)
    {
        tempCounter++;
        [self WriteToFile:pRenderBuffer dataLength:m_iRenderHeight * m_iRenderWidth * 3 / 2 filePointer:m_FileForDump];
    }
    else
    {
        cout<<"DONE!!"<<endl;
        [self UpdateStatusMessage:"FileWrite Completed!!!!"];
    }
    */
    
    @autoreleasepool {
        if(!pRenderBuffer)
        {
            printf("Inside BackConversion--> pData is NULL\n");
            return;
        }
        
        int iRet;
        
        //[self WriteToFile:pRenderBuffer dataLength:m_iRenderHeight * m_iRenderWidth * 3 / 2 filePointer:m_FileForDump];
        
        //iRet = m_pVideoConverter->Convert_YUVI420_To_YUVNV12(pRenderBuffer, pRenderBuffer, baVideoRenderBufferUVChannel, m_iRenderHeight, m_iRenderWidth);
        
        int iVideoHeight = m_iRenderHeight;
        int iVideoWidth = m_iRenderWidth;
        
        int YPlaneLength = iVideoHeight*iVideoWidth;
        int VPlaneLength = YPlaneLength >> 2;
        int UVPlaneMidPoint = YPlaneLength + VPlaneLength;
        int UVPlaneEnd = UVPlaneMidPoint + VPlaneLength;
        
        memcpy(baVideoRenderBufferUVChannel, pRenderBuffer + YPlaneLength, VPlaneLength + VPlaneLength);
               
        /*
        printf("Check inside backconversion: ");
        for(int i=0;i<20;i++)
            printf("%d ", pRenderBuffer[i]);
        printf("\n");
        */
        CVPixelBufferRef pixelBuffer;
        pixelBuffer = m_pVideoConverter->Convert_YUVNV12_To_CVPixelBufferRef(pRenderBuffer, pRenderBuffer+YPlaneLength, m_iRenderHeight, m_iRenderWidth);
        
        
        
        UIImage *Mynnnimage = m_pVideoConverter->Convert_CVPixelBufferRef_To_UIImage(pixelBuffer);
        
        CVPixelBufferRelease(pixelBuffer);
        
        [self.delegate RenderImage:Mynnnimage];
        
        return; //Success
    }
    
}


- (void)InitializeFilePointer:(FILE *)fp fileName:(NSString *)fileName
{
    NSFileHandle *handle;
    NSArray *Docpaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [Docpaths objectAtIndex:0];
    NSString *filePathyuv = [documentsDirectory stringByAppendingPathComponent:fileName];
    handle = [NSFileHandle fileHandleForUpdatingAtPath:filePathyuv];
    char *filePathcharyuv = (char*)[filePathyuv UTF8String];
    m_FileForDump = fopen(filePathcharyuv, "wb");
}

- (void)WriteToFile:(unsigned char *)data dataLength:(int)datalen filePointer:(FILE *)fp
{
    printf("Writing to yuv\n");
    fwrite(data, 1, datalen, m_FileForDump);
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
