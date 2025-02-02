//
//  VideoConverter.hpp
//  TestCamera
//
//  Created by Apple on 10/18/15.
//
//

#ifndef VideoConverter_hpp
#define VideoConverter_hpp

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <AssertMacros.h>
#import <AssetsLibrary/AssetsLibrary.h>

#include <stdio.h>
#include <iostream>
#include <string>
#include <stdio.h>
#include <queue>

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
#include "common.hpp"



using namespace std;



class CVideoConverter
{
public:
    CVideoConverter();
    ~CVideoConverter();
    
    
    void RotateYUV420Degree90(byte *data, byte *yuv, int imageWidth, int imageHeight);
    
    UIImage* Convert_CMSampleBufferRef_To_UIImage(CMSampleBufferRef sampleBuffer);
    UIImage* Convert_CVPixelBufferRef_To_UIImage(CVPixelBufferRef pixelBuffer);
    //int Convert_YUVNV12_To_YUVI420(byte* pCameraData, byte* outData, int m_iHeight = 0, int m_iWidth = 0);
    int Convert_YUVNV12_To_YUVI420(byte* convertingData, int m_iHeight, int m_iWidth);
    int Convert_YUVI420_To_YUVNV12(byte* pData,  byte *y_ch0, byte* y_ch1,int iRenderHeight, int iRenderWidth);
    CVPixelBufferRef Convert_YUVNV12_To_CVPixelBufferRef(byte* y_ch0, byte* y_ch1, int iRenderHeight, int iRenderWidth);
    void mirrorRotateAndConvertNV12ToI420(unsigned char *m_pFrame, unsigned char *pData, int &iVideoHeight, int &iVideoWidth);
    void mirrorYUVI420(unsigned char *pFrame, unsigned char *pData, int iHeight, int iWidth);
    int ConvertI420ToNV12(unsigned char *convertingData, int iVideoHeight, int iVideoWidth);
    int ConvertI420ToNV21(unsigned char *convertingData, int iVideoHeight, int iVideoWidth);
    int ConvertNV21ToI420(unsigned char *convertingData, int iVideoHeight, int iVideoWidth);
    
    int Convert_UIImage_To_RGBA8(UIImage *pImage, byte** outBuf);
    void GaussianBlur(unsigned char* scl, unsigned char* tcl, int h, int w, float r);
    
    
    void boxesForGauss(float sigma, int n);
    void GaussianBlur_4thApproach(unsigned char* scl, unsigned char* tcl, int h, int w, float r);
    void boxBlur_4 (unsigned char *scl, unsigned char *tcl, int h, int w, int r);
    void boxBlurH_4 (unsigned char *scl, unsigned char *tcl, int h, int w, int r);
    void boxBlurT_4 (unsigned char *scl, unsigned char *tcl, int h, int w, int r);
    void EnhanceTemperature (unsigned char *scl, int iHeight, int iWidth, int iThreshold);
    
    void generateUVIndex(int imageWidth, int imageHeight);
    void DetectAndShowOnlySkin(unsigned char *pRawYuv, int iHeight, int iWidth);
    bool isSkin (int r, int g, int b);
    int getMin(int a, int b, int c);
    int getAbs(int a);
    int getMax(int a, int b, int c);
    bool isSkin2(int R, int G, int B);
    
    void ChangeBlock_9x9_To_4x4(unsigned char *inData, int iHeight, int iWidth, int i, int j, int iNewHeight, int iNewWidth, int m, int n, unsigned char *outData, int iw);
    int DownScale_3_2_YUV420(unsigned char* pData, int &iHeight, int &iWidth, unsigned char* outputData);
    
    int DownScaleYUV420_Dynamic(unsigned char* pData, int &iHeight, int &iWidth, unsigned char* outputData, int diff);
    
    
    
    void SendPakcetFragments(byte*data, int iLen);
    void ReceiveFullFrame(byte*data, int iLen, int frameNumber);
    
    int DownScaleVideoData(byte* pData, int &iHeight, int &iWidth, byte* outputData);
    int DownScaleVideoDataWithAverage(byte* pData, int &iHeight, int &iWidth, byte* outputData);
    int DownScaleVideoDataWithAverageVersion2(byte* pData, int &iHeight, int &iWidth, byte* outputData);
    int Crop_YUV420(unsigned char* pData, int inHeight, int inWidth, int startXDiff, int endXDiff, int startYDiff, int endYDiff, unsigned char* outputData, int &outHeight, int &outWidth);
    int Crop_YUVNV12_YUVNV21(unsigned char* pData, int inHeight, int inWidth, int startXDiff, int endXDiff, int startYDiff, int endYDiff, unsigned char* outputData, int &outHeight, int &outWidth);
    int DownScaleYUVNV12_YUVNV21_OneFourth(unsigned char* pData, int &iHeight, int &iWidth, unsigned char* outputData);
    int RotateI420(byte *pInput, int inHeight, int inWidth, byte *pOutput, int &outHeight, int &outWidth, int rotationParameter);
    
    int DownScaleYUV420_Dynamic_Version222(unsigned char* pData, int inHeight, int inWidth, unsigned char* outputData, int outHeight, int outWidth);
    void InitializeCumulativeSumForY(int inHeight, int inWidth, unsigned char *pData);
    void InitializeCumulativeSumForUV(int halfH, int halfW, unsigned char *p, unsigned char *q);
    int DownScaleYData(int MaximumFraction, int inHeight, int inWidth, int outHeight, int outWidth, int factorH,
                       int fractionH, int factorW, int fractionW, unsigned char *pData, unsigned char *outputData);
    int DownScaleUVData(int MaximumFraction, int halfH, int factorH, int fractionH, int halfW, int factorW, int fractionW, int outHeight, int outWidth,
                        unsigned char *p, unsigned char *q, int uIndex, int vIndex, unsigned char *outputData);
    
    CIContext *temporaryContext, *temporaryContext2;
    
    int m_iHeight;
    int m_iWidth;
    int m_iVideoSesson;
    int m_iUserId;
    int m_iTestCount;
    int iCiContextController;
    
    int m_Multiplication[640][640];
    
    int ServerFd;
    struct sockaddr_in Server;
    
    
    
};

#endif /* VideoConverter_hpp */
