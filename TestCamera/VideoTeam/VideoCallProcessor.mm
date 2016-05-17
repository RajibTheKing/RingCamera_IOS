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
    
    m_pVTP =  [VideoThreadProcessor GetInstance];
    m_pVTP.delegate = self;
    
    _m_bStartVideoSending = false;
    m_pVideoConverter = new CVideoConverter();
    
    g_G729CodecNative = new G729CodecNative();
    
    int iRet = g_G729CodecNative->Open();
    cout <<  "Open returned " << iRet << "\n";
    
    [self InitializeFilePointer:m_FileForDump fileName:@"YuvTest.yuv"];
    
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
- (void) InitializeVideoEngine:(long long) lUserId
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
    
    NSString *nsServerIP =  @"38.127.68.60"  /*@"192.168.57.155"@"192.168.2.53"*/;
    cout<<"Check--> sRemoteIP = "<<m_sRemoteIP<<endl;
    
    //m_pVideoAPI->SetLoggingState(true,5);
    
    int iRet;

    iRet = (int)m_pVideoAPI->CreateSession(lFriendId, (int)1/*Audio*/,  [VideoCallProcessor convertStringIPtoLongLong:nsServerIP], lFriendId);
    cout<<"CreateSession, Audio, iRet = "<<iRet<<endl;
    iRet = (int)m_pVideoAPI->CreateSession(lFriendId, (int)2/*Video*/,  [VideoCallProcessor convertStringIPtoLongLong:nsServerIP], lFriendId);
    cout<<"CreateSession, Video, iRet = "<<iRet<<endl;
    
    CVideoAPI::GetInstance()->SetRelayServerInformation(200, (int)1/*Audio*/,  [VideoCallProcessor convertStringIPtoLongLong:nsServerIP], iFriendPort);
    
    CVideoAPI::GetInstance()->SetRelayServerInformation(200, (int)2/*Video*/,  [VideoCallProcessor convertStringIPtoLongLong:nsServerIP], iFriendPort);
    

    iRet = m_pVideoAPI->StartAudioCall(200);
    iRet = m_pVideoAPI->StartVideoCall(200,m_iCameraHeight, m_iCameraWidth,0); //Added NetworkType
    
    
    //iRet = m_pVideoAPI->CheckDeviceCapability(200, m_iCameraHeight, m_iCameraWidth);
    //m_bCheckCall = true;
    
    [m_pVTP SetVideoAPI:m_pVideoAPI];
    [m_pVideoSockets SetVideoAPI:m_pVideoAPI];
    [m_pVideoSockets SetUserID:lUserId];
    
    /*dispatch_queue_t SendDummyDataQ = dispatch_queue_create("SendDummyDataQ",DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(SendDummyDataQ, ^{
        [self SendDummyData];
    });*/
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
- (void)SetWidthAndHeight:(int)iWidth withHeight:(int)iHeight
{
    m_iCameraHeight = iWidth;
    m_iCameraWidth = iHeight;
    
    [m_pVTP SetWidthAndHeight:iHeight withHeight:iWidth];
    
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
        if(*iHeight == 352 && *iWidth==288)
        {
            [*session setSessionPreset:AVCaptureSessionPreset352x288];
        }
        else if(*iHeight == 640 && *iWidth == 480)
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
        
        
        [self SetWidthAndHeight:*iHeight withHeight:*iWidth];
        
        m_pEncodeBuffer = new RingBuffer<byte>(m_iCameraWidth,m_iCameraHeight,5);
        [m_pVTP SetEncodeBuffer:m_pEncodeBuffer];
        
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

- (void)StopCheckCapability
{
    [self.delegate StopCheckCapability];
}
- (void)CheckCapabilityAgain
{

    [self.delegate StopCheckCapability];
    [self.delegate CheckCapabilityAgain];
    
}
- (void)ReInitializeCamera:(int)iHeight withWidth:(int)iWidth
{
    cout<<"Here inside video call processor, sendint info to view controller to reinitialize"<<endl;
    [self.delegate ReinitializeCameraFromViewController:iHeight withWidth:iWidth];
    
}
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    
    //if(!_m_bStartVideoSending) return;
    
    [self FrontConversion: sampleBuffer fromConnection:connection];
}


int tempCounter = 0;
- (int)FrontConversion:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if(tempCounter == 0)
    {
        cout<<"First Frame after camera Initialization = "<<[self GetTimeStamp2] - _m_lCameraInitializationStartTime<<endl;
    }
    
    tempCounter++;
    printf("Rajib_Check: Inside FrontConversion\n");
    
    
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    [connection setVideoMirrored:false];
    
    
    usleep(15*1000);
    
    //if(m_bCheckCall == true && tempCounter>200) return 0;
    
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

    int iRet = CVideoAPI::GetInstance()->SendVideoData(200, pRawYuv, m_iCameraHeight * m_iCameraWidth * 3 / 2, 0,3);
    //cout<<"Rajib_Check: SendVideoDataV, DataLen = "<<m_iCameraHeight * m_iCameraWidth * 3 / 2<<", iRet = "<<iRet<<endl;
    
    printf("Rajib_Check: Trying to SendVideoDataV\n");
    
    /*
    if(tempCounter<500)
    {
        printf("TheKing--> tempCounter = %d\n", tempCounter);
        tempCounter++;
        ConvertNV12ToI420(pRawYuv, m_iCameraHeight, m_iCameraWidth);
        
        [self WriteToFile:pRawYuv dataLength:m_iCameraHeight * m_iCameraWidth * 3 / 2 filePointer:m_FileForDump];
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
    printf("Writing to yuv");
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

-(long long)GetTimeStamp2
{
    namespace sc = std::chrono;
    auto time = sc::system_clock::now(); // get the current time
    auto since_epoch = time.time_since_epoch(); // get the duration since epoch
    // I don't know what system_clock returns
    // I think it's uint64_t nanoseconds since epoch
    // Either way this duration_cast will do the right thing
    auto millis = sc::duration_cast<sc::milliseconds>(since_epoch);
    long long now = millis.count(); // just like java (new Date()).getTime();
    return now;
}


- (void)dealloc {
    [super dealloc];
}
@end
