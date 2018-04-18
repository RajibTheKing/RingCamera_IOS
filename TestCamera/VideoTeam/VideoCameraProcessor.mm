//
//  VideoCallProcessor.m
//  TestCamera 
//
//  Created by Apple on 11/16/15.
//
//




#import <Foundation/Foundation.h>
#include "VideoCameraProcessor.h"
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
#include "TestNeonAssembly.hpp"
#include "BeautificationFilter.hpp"

byte baVideoRenderBufferUVChannel [MAXWIDTH * MAXHEIGHT/2];
byte pRawYuv[MAXWIDTH * MAXHEIGHT*3/2 + 10];
byte pOutPutTest[MAXWIDTH * MAXHEIGHT*3/2 + 10];
byte pScaledVideo[MAXWIDTH * MAXHEIGHT*3/2 + 10];

template class RingBuffer<int>;
template class RingBuffer<byte>;


int g_iDEBUG_INFO = 1;
string g_sLOG_PATH = "Document/VideoEngine.log";

#define USE_FORCE_HIGH_FPS_INITIALIZATION


@implementation VideoCameraProcessor

- (id) init
{
    self = [super init];
    NSLog(@"Inside Video Controller Constructor");
    
    VideoThreadProcessor *pVideoThreadProcessor = [VideoThreadProcessor GetInstance];
    pVideoThreadProcessor.delegate = self;
    
    _m_bStartVideoSending = false;
    m_pVideoConverter = new CVideoConverter();
    
    //g_G729CodecNative = new G729CodecNative();
    //int iRet = g_G729CodecNative->Open();
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

    return self;
}

+ (id)GetInstance
{
    if(m_pVideoCameraProcessor == nil)
    {
        cout<<"Video_Team: m_pVideoCallProcessor Initialized"<<endl;
        
        m_pVideoCameraProcessor = [[VideoCameraProcessor alloc] init];
        
    }
    return m_pVideoCameraProcessor;
}

/*
-(G729CodecNative *)GetG729
{
    return g_G729CodecNative;
}
*/


- (void)SetHeightAndWidth:(int)iHeight withWidth:(int)iWidth
{
    m_iCameraHeight = iHeight;
    m_iCameraWidth = iWidth;
}

- (void)SetWidthAndHeightForRendering:(int)iWidth withHeight:(int)iHeight
{
    m_iRenderHeight = iHeight;
    m_iRenderWidth = iWidth;
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
        }
        else if(*iHeight * *iWidth == 480 * 640)
        {
            [*session setSessionPreset:AVCaptureSessionPreset640x480];
        }
        else if(*iHeight * *iWidth == 1280 * 720)
        {
            [*session setSessionPreset:AVCaptureSessionPreset1280x720];
        }
        else if(*iHeight * *iWidth == 1080 * 1920)
        {
            [*session setSessionPreset:AVCaptureSessionPreset1920x1080];
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
                           [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
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
long long totalDIff = 0;
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
    
    /*****
     *DownScale_OneFourthCheck
     m_pVideoConverter->DownScaleYUVNV12_YUVNV21_OneFourth(pRawYuv, iVideoHeight, iVideoWidth, pOutPutTest);
     ***/
    
    
//#define RESIZE_ENABLE
    int iNewHeight = 320, iNewWidth = 238;
#ifdef RESIZE_ENABLE
    /*****
     *DynamicResizeTest
     **/
    //long long startTime = CurrentTimeStamp();
    m_pVideoConverter->Convert_YUVNV12_To_YUVI420(pRawYuv, m_iCameraHeight, m_iCameraWidth);
    m_pVideoConverter->DownScaleYUV420_Dynamic(pRawYuv, m_iCameraHeight, m_iCameraWidth, pScaledVideo, iNewHeight,iNewWidth);
    iVideoWidth = iNewWidth;
    iVideoHeight = iNewHeight;
    memcpy(pRawYuv, pScaledVideo, iNewHeight*iNewWidth*3/2);
    m_pVideoConverter->ConvertI420ToNV12(pRawYuv, iVideoHeight, iVideoWidth);
    //NSLog(@"TimeElapsed = %lld", CurrentTimeStamp() - startTime);
#endif
    
   
    
    
    
    
    
    
    printf("TheKing--> Got VideoData len = %d, H:W = %d:%d\n", iVideoHeight * iVideoWidth * 3 / 2, iVideoHeight, iVideoWidth);

    
    

    
#define ASSEMBLY_TEST
    
#ifndef ASSEMBLY_TEST
    int iRet = CVideoAPI::GetInstance()->SendVideoData(200, pRawYuv, m_iCameraHeight * m_iCameraWidth * 3 / 2, 0,3);

    
#else
    
    //TestNeonAssembly ts;
    
    TestNeonAssembly *ts = TestNeonAssembly::GetInstance();
    //ts.convert_nv12_to_i420_assembly(pRawYuv, pOutPutTest, iVideoHeight, iVideoWidth);
    //m_pVideoConverter->Convert_YUVNV12_To_YUVI420(pRawYuv, m_iCameraHeight, m_iCameraWidth);
    
    
    
    //memcpy(pRawYuv, pOutPutTest, iVideoWidth*iVideoHeight*3/2);
    //memset(pOutPutTest, 0, sizeof(pOutPutTest));
    
    
    //m_pVideoConverter->Crop_YUV420(pRawYuv, iVideoHeight, iVideoWidth, 12, 10, 22, 28, pOutPutTest, iNewHeight, iNewWidth);
    //ts.Crop_yuv420_assembly(pRawYuv, iVideoHeight, iVideoWidth, 0, 0, 0, 0, pOutPutTest, iNewHeight, iNewWidth);
    //ts.Crop_yuv420_assembly(pRawYuv, iVideoHeight, iVideoWidth, 26, 22, 0, 0, pOutPutTest, iNewHeight, iNewWidth);
    
    
    //m_pVideoConverter->Crop_YUVNV12_YUVNV21(pRawYuv, iVideoHeight, iVideoWidth, 12, 10, 22, 28, pOutPutTest, iNewHeight, iNewWidth);
    //ts.Crop_YUVNV12_YUVNV21_assembly(pRawYuv, iVideoHeight, iVideoWidth, 12, 10, 22, 28, pOutPutTest, iNewHeight, iNewWidth);
    //ts.Crop_YUVNV12_YUVNV21_assembly(pRawYuv, iVideoHeight, iVideoWidth, 0, 188, 0, 252, pOutPutTest, iNewHeight, iNewWidth);
    
    //memcpy(pRawYuv, pOutPutTest, iVideoHeight * iVideoWidth * 3 / 2);
    
    //m_pVideoConverter->Crop_YUVNV12_YUVNV21(pRawYuv, iVideoHeight, iVideoWidth, 8, 8, 8, 8, pOutPutTest, iNewHeight, iNewWidth);
    //m_pVideoConverter->Convert_YUVNV12_To_YUVI420(unsigned char *convertingData, <#int m_iHeight#>, <#int m_iWidth#>)

    //ts->ConvertNV21ToI420_assembly(pRawYuv, iVideoHeight, iVideoWidth);
    //m_pVideoConverter->ConvertNV21ToI420(pRawYuv, iVideoHeight, iVideoWidth);

    
    //m_pVideoConverter->ConvertI420ToNV12(pRawYuv, iVideoHeight, iVideoWidth);
    
    
    long long startTime = CurrentTimeStamp();

    //ts->BeautificationFilterForChannel_assembly(pRawYuv, iVideoHeight*iVideoWidth*3/2, iVideoHeight, iVideoWidth);
    //BeautificationFilter::GetInstance()->doSharpen(pRawYuv, iVideoHeight, iVideoWidth);
    //TheKing--> Sharpen timediffsum = 1499, framecounter = 500
    
    //BeautificationFilter::GetInstance()->doSharpen2(pRawYuv, iVideoHeight, iVideoWidth, pOutPutTest);
    TestNeonAssembly::GetInstance()->BeautificationFilterForChannel_assembly(pRawYuv,  iVideoHeight, iVideoWidth);
    //TheKing--> Sharpen timediffsum = 783, framecounter = 500
    
    long long timeDiff = CurrentTimeStamp() - startTime;
    static long long timediffsum = 0;
    timediffsum+=timeDiff;
    printf("TheKing--> Sharpen timediffsum = %lld, framecounter = %d\n", timediffsum, ++tempCounter);
    //iVideoHeight = iNewHeight;
    //iVideoWidth = iNewWidth;
    

    //memcpy(pRawYuv, pOutPutTest, iVideoWidth*iVideoHeight*3/2);
   //memset(pOutPutTest, 0, sizeof(pOutPutTest));
    //printf("TheKing--> Sending2 len = %d, H:W = %d:%d\n", iVideoHeight * iVideoWidth * 3 / 2, iVideoHeight, iVideoWidth);

    //ts.Mirror_YUV420_Assembly(pRawYuv, pOutPutTest, iVideoHeight, iVideoWidth);
    //m_pVideoConverter->mirrorYUVI420(pRawYuv, pOutPutTest, iVideoHeight, iVideoWidth);


    
    //m_pVideoConverter->RotateI420(pRawYuv, iVideoHeight, iVideoWidth, pOutPutTest, iNewHeight, iNewWidth, 3/*90 Degree*/);
    //ts.RotateI420_Assembly(pRawYuv, iVideoHeight, iVideoWidth, pOutPutTest, iNewHeight, iNewWidth, 3/*90 degree*/);
    
    

    
    //iVideoHeight = iNewHeight;
    //iVideoWidth = iNewWidth;
    
    //m_pVideoConverter->ConvertI420ToNV12(pOutPutTest, iVideoHeight, iVideoWidth);
    
    /*
    //Starting downscale oneFourth
    memcpy(pRawYuv, pOutPutTest, iVideoWidth*iVideoHeight*3/2);
    memset(pOutPutTest, 0, sizeof(pOutPutTest));
    long long startTime = CurrentTimeStamp();
    m_pVideoConverter->DownScaleYUVNV12_YUVNV21_OneFourth(pRawYuv, iVideoHeight, iVideoWidth, pOutPutTest);
    //ts.DownScaleOneFourthAssembly(pRawYuv, iVideoHeight, iVideoWidth, pOutPutTest);
    long long diff = CurrentTimeStamp() - startTime;
    totalDIff+=diff;
    tempCounter++;
    NSLog(@"DownScaleOneFourth TimeElapsed = %lld, frames = %d, totalDiff = %lld", diff, tempCounter, totalDIff);
    iVideoWidth>>=2;
    iVideoHeight>>=2;
    //ending downscale oneFourth
    */
    
    
    
    
    //CVideoAPI::GetInstance()->m_iReceivedHeight = iVideoHeight;
    //CVideoAPI::GetInstance()->m_iReceivedWidth = iVideoWidth;
    //CVideoAPI::GetInstance()->ReceiveFullFrame(pRawYuv, iVideoHeight * iVideoWidth * 3 / 2);
    
    
    
    //Sending to OwnViewer Directly
    m_iRenderHeight = iVideoHeight;
    m_iRenderWidth = iVideoWidth;
    [self BackConversion:pRawYuv];
    string sStatusMessage = "Height = " + CVideoAPI::GetInstance()->IntegertoStringConvert(iVideoHeight) +
                            ", Width = " + CVideoAPI::GetInstance()->IntegertoStringConvert(iVideoWidth);
    [self UpdateStatusMessage:sStatusMessage];
    
    //cout<<"Rajib_Check: SendVideoDataV, DataLen = "<<m_iCameraHeight * m_iCameraWidth * 3 / 2<<", iRet = "<<iRet<<endl;
    
    //printf("Rajib_Check: Trying to SendVideoDataV\n");
#endif
    
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



- (void)dealloc {
    [super dealloc];
}
@end
