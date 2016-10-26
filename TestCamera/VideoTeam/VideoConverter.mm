//
//  VideoConverter.cpp
//  TestCamera
//
//  Created by Apple on 10/18/15.
//
//

#include "VideoConverter.hpp"

#define WIDTH 640
#define HEIGHT 480

byte pTemporaryEncodedData[WIDTH*HEIGHT*3/2];
#include <sys/time.h>
#define printf(...)

extern unsigned int timeGetTime();

unsigned char m_pVPlane[640*480*3/2];
unsigned char m_pUPlane[640*480*3/2];

CVideoConverter::CVideoConverter()
{
    
    temporaryContext = [[CIContext contextWithOptions:nil]retain];
    iCiContextController =0;
    m_iTestCount = 0;
    
    for (int i = 0; i < 481; i++)
        for (int j = 0; j < 641; j++)
        {
            m_Multiplication[i][j] = i*j;
        }
}

UIImage* CVideoConverter::Convert_CMSampleBufferRef_To_UIImage(CMSampleBufferRef sampleBuffer)
{
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    return Convert_CVPixelBufferRef_To_UIImage(pixelBuffer);
    
}
#define USE_CONTEXT
//#define USE_UIGRAPHICS

int iUsiongTempContext = 1;
CIContext *myContext;


UIImage* CVideoConverter::Convert_CVPixelBufferRef_To_UIImage( CVPixelBufferRef pixelBuffer)
{
#ifdef USE_UIGRAPHICS
    {
        int w = CVPixelBufferGetWidth(pixelBuffer);
        int h = CVPixelBufferGetHeight(pixelBuffer);
        int r = CVPixelBufferGetBytesPerRow(pixelBuffer);
        int bytesPerPixel = r/w;
        
        CVPixelBufferLockBaseAddress(pixelBuffer,0);
        CVPixelBufferLockBaseAddress(pixelBuffer,1);
        byte *y_ch0 = (byte *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0); // Y-Plane = y_ch0
        byte *y_ch1 = (byte *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1); // UV-Plane = y_ch1
        CVPixelBufferUnlockBaseAddress(pixelBuffer,0);
        CVPixelBufferUnlockBaseAddress(pixelBuffer,1);
        //byte *buffer = (byte *)CVPixelBufferGetBaseAddress(pixelBuffer, 0);
        
        UIGraphicsBeginImageContext(CGSizeMake(w, h));
        
        CGContextRef c = UIGraphicsGetCurrentContext();
        
        byte* data = (byte *)CGBitmapContextGetData(c);
        memcpy(data, y_ch0, h * w);
        memcpy(data + h * w, y_ch1,  h * w / 2);

        UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        return img;
    }
#else
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    
#ifdef USE_CONTEXT
    if(iCiContextController == 0)
    {
        myContext = temporaryContext;
    }
    iCiContextController++;

    CGImageRef videoImage = [temporaryContext
                             createCGImage:ciImage
                             fromRect:CGRectMake(0, 0,
                                                 CVPixelBufferGetWidth(pixelBuffer),
                                                 CVPixelBufferGetHeight(pixelBuffer))];
#endif

#ifdef USE_CONTEXT
    UIImage *pImage = [[UIImage alloc] initWithCGImage:videoImage scale:1.0 orientation:UIImageOrientationUpMirrored];
#else
    UIImage *pImage = [[UIImage alloc] initWithCIImage:ciImage scale:1.0 orientation:UIImageOrientationLeftMirrored];
    
#endif
    
#ifdef USE_CONTEXT
    CGImageRelease(videoImage);
#endif
    return pImage;
#endif
    
}

/*
int CVideoConverter::Convert_YUVNV12_To_YUVI420(byte* yPlane, byte* uvPlane, byte* outData,int iHeight, int iWidth)
{
    
    int iFrameSize = iHeight * iWidth * 3 / 2;
    memcpy(outData, yPlane, iFrameSize * 2/3);
    
    byte * outdataUPlane = outData + iHeight * iWidth;
    byte * outdataVPlane = outData + iHeight * iWidth + iHeight * iWidth/4;
    
    int j = 0;
    int iPlaneSize = iFrameSize * 1/6;
    for(int i = 0; i < iPlaneSize; i++)
    {
        outdataUPlane[i] = uvPlane[j++];
        outdataVPlane[i] = uvPlane[j++];
    }
    
    return 1;
}
*/
void CVideoConverter::mirrorRotateAndConvertNV12ToI420(unsigned char *m_pFrame, unsigned char *pData, int iVideoHeight, int iVideoWidth)
{
    //Locker lock(*m_pColorConverterMutex);
    
    int iWidth = iVideoHeight;
    int iHeight = iVideoWidth;
    
    int i = 0;
    
    for (int x = iWidth - 1; x >-1; --x)
    {
        for (int y = 0; y <iHeight; ++y)
        {
            pData[i] = m_pFrame[m_Multiplication[y][iWidth] + x];
            i++;
        }
    }
    
    int halfWidth = iWidth / 2;
    int halfHeight = iHeight / 2;
    int dimention = m_Multiplication[iHeight][iWidth];
    int vIndex = dimention + m_Multiplication[halfHeight][halfWidth];
    
    for (int x = halfWidth - 1; x>-1; --x)
        for (int y = 0; y < halfHeight; ++y)
        {
            int ind = ( m_Multiplication[y][halfWidth] + x) * 2;
            pData[vIndex++] = m_pFrame[dimention + ind];
            pData[i++] = m_pFrame[dimention + ind + 1];
        }
}

int CVideoConverter::Convert_YUVI420_To_YUVNV12(unsigned char *convertingData, unsigned char *channel0, unsigned char *channel1,  int iVideoHeight, int iVideoWidth)
{
    /*
    int YPlaneLength = iVideoHeight*iVideoWidth;
    int VPlaneLength = YPlaneLength >> 2;
    int UVPlaneMidPoint = YPlaneLength + VPlaneLength;
    int UVPlaneEnd = UVPlaneMidPoint + VPlaneLength;
    
    
    memcpy(channel0, convertingData, YPlaneLength);
    
    int i, j, k;
    
    for (i = YPlaneLength, j = 0, k = UVPlaneMidPoint; i < UVPlaneMidPoint; i++, k++)
    {
        channel1[j++] = convertingData[i];
        channel1[j++] = convertingData[k];
    }
    
    */
    
    int i, j, k;
    
    int YPlaneLength = iVideoHeight*iVideoWidth;
    int VPlaneLength = YPlaneLength >> 2;
    int UVPlaneMidPoint = YPlaneLength + VPlaneLength;
    int UVPlaneEnd = UVPlaneMidPoint + VPlaneLength;
    
    memcpy(m_pUPlane, convertingData + YPlaneLength, VPlaneLength);
    
    for (i = YPlaneLength, j = 0, k = UVPlaneMidPoint; i < UVPlaneEnd; i += 2, j++, k++)
    {
        convertingData[i] = m_pUPlane[j];
        convertingData[i + 1] = convertingData[k];
    }
    
    return UVPlaneEnd;
}

int CVideoConverter::Convert_YUVNV12_To_YUVI420(byte* yPlane, byte* uvPlane, byte* convertingData, int iVideoHeight, int iVideoWidth)
{
    /*
    int iFrameSize = m_iHeight * m_iWidth * 3 / 2;
    
    memcpy(outData, yPlane, iFrameSize * 2/3);

    
    byte * outdataUPlane = outData + m_iHeight * m_iWidth;
    byte * outdataVPlane = outData + m_iHeight * m_iWidth + m_iHeight * m_iWidth/4;
    
    int j = 0;
    int iPlaneSize = iFrameSize * 1/6;
    for(int i = 0; i < iPlaneSize; i++)
    {
        outdataUPlane[i] = uvPlane[j++];
        outdataVPlane[i] = uvPlane[j++];
    }
    */
    
    int i, j, k;
    
    int YPlaneLength = iVideoHeight*iVideoWidth;
    int VPlaneLength = YPlaneLength >> 2;
    int UVPlaneMidPoint = YPlaneLength + VPlaneLength;
    int UVPlaneEnd = UVPlaneMidPoint + VPlaneLength;
    
    for (i = YPlaneLength, j = 0, k = i; i < UVPlaneEnd; i += 2, j++, k++)
    {
        m_pVPlane[j] = convertingData[i + 1];
        convertingData[k] = convertingData[i];
    }
    
    memcpy(convertingData + UVPlaneMidPoint, m_pVPlane, VPlaneLength);
    
    return UVPlaneEnd;
    return 1;
}

/*
int CVideoConverter::Convert_YUVNV12_To_YUVI420(unsigned char *pCameraData, unsigned char *convertingData, int iVideoHeight, int iVideoWidth)
{
    int YPlaneLength = iVideoHeight*iVideoWidth;
    int VPlaneLength = YPlaneLength >> 2;
    int UVPlaneMidPoint = YPlaneLength + VPlaneLength;
    int UVPlaneEnd = UVPlaneMidPoint + VPlaneLength;
    
    
    memcpy(convertingData, pCameraData, YPlaneLength);
    
    int i, j, k;
    
    for (i = YPlaneLength, j = YPlaneLength, k = UVPlaneMidPoint; i < UVPlaneMidPoint; i++, k++)
    {
        convertingData[i] = pCameraData[j++];
        convertingData[k] = pCameraData[j++];
    }
    
    return UVPlaneEnd;
}
*/



void CVideoConverter::RotateYUV420Degree90(byte *data, byte *yuv, int imageWidth, int imageHeight)
{
    int i = 0;
    for(int x = 0;x < imageWidth;x++)
    {
        for(int y = imageHeight-1;y >= 0;y--)
        {
            yuv[i] = data[y*imageWidth+x];
            i++;
        }
    }
    
    
    // Rotate the U and V color components
    i = imageWidth * imageHeight * 3/2-1;
    for(int x = imageWidth-1;x > 0;x=x-2)
    {
        for(int y = 0;y < imageHeight/2;y++)
        {
            yuv[i] = /*data[(imageWidth*imageHeight)+(y*imageWidth)+x]*/0;
            i--;
            yuv[i] = /*data[(imageWidth*imageHeight)+(y*imageWidth)+(x-1)]*/0;
            i--;
        }
    }
    
    return;
}

/*
int CVideoConverter::Convert_YUVI420_To_YUVNV12(byte* pData,  byte *y_ch0, byte* y_ch1, int iRenderHeight, int iRenderWidth)
{
    int iFrameSize = iRenderHeight * iRenderWidth * 3 / 2;
    byte *uPlane = pData + iFrameSize * 2/3;
    byte *vPlane = pData + iFrameSize * 2/3 + iFrameSize * 1/6;
    
    int j = 0;
    int iPlaneSize = iFrameSize * 1/6;
    for(int i = 0; i < iPlaneSize; i++)
    {
        y_ch1[j++] = uPlane[i];
        y_ch1[j++] = vPlane[i];
    }
    return 1;
}
*/


CVPixelBufferRef CVideoConverter::Convert_YUVNV12_To_CVPixelBufferRef(byte* y_ch0, byte* y_ch1, int iRenderHeight, int iRenderWidth)
{
    NSDictionary *pixelAttributes = @{(id)kCVPixelBufferIOSurfacePropertiesKey : @{}};
    CVPixelBufferRef pixelBuffer = NULL;
    
    CVReturn result = CVPixelBufferCreate(kCFAllocatorDefault,
                                          iRenderWidth,
                                          iRenderHeight,
                                          kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
                                          (__bridge CFDictionaryRef)(pixelAttributes),
                                          &pixelBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer,0);
    byte *yDestPlane = (byte*)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    memcpy(yDestPlane, y_ch0, iRenderWidth * iRenderHeight);
    
    
    byte *uvDestPlane = (byte*)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    memcpy(uvDestPlane, y_ch1, iRenderWidth * iRenderHeight / 2);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    if (result != kCVReturnSuccess) {
        NSLog(@"Unable to create cvpixelbuffer %d", result);
    }
    return pixelBuffer;
}

int CVideoConverter::Convert_UIImage_To_RGBA8(UIImage *pImage, byte** outBuf)
{
    return 1;
    
}

