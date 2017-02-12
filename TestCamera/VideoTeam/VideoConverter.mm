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
int CVideoConverter::ConvertI420ToNV12(unsigned char *convertingData, int iVideoHeight, int iVideoWidth)
{
    //Locker lock(*m_pColorConverterMutex);
    
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
void CVideoConverter::mirrorRotateAndConvertNV12ToI420(unsigned char *m_pFrame, unsigned char *pData, int &iVideoHeight, int &iVideoWidth)
{
    //Locker lock(*m_pColorConverterMutex);
    
    int iWidth = iVideoWidth;
    int iHeight = iVideoHeight;
    
    int i = 0;
    
    for (int x = iWidth-1; x>=0 ; x--)
    {
        for (int y = 0; y <iHeight; y++)
        {
            int indx =m_Multiplication[y][iWidth] - x-1;
            if(indx<0)
                indx = iWidth-x-1;
            else if(indx >= (iHeight -1) * iWidth)
            {
                indx = iHeight-y;
            }
            
            pData[i] = m_pFrame[indx];
            i++;
        }
    }
    
    
    int halfWidth = iWidth / 2;
    int halfHeight = iHeight / 2;
    int dimention = m_Multiplication[iHeight][iWidth];
    int vIndex = dimention + m_Multiplication[halfHeight][halfWidth];
    
    for (int x = halfWidth-1; x>=0; x--)
        for (int y = 0; y < halfHeight; y++)
        {
            
            int ind = ( m_Multiplication[y][halfWidth] - x-1) * 2;
            if(ind<0) ind = (halfWidth-x-1)*2;
            
            pData[i++] = m_pFrame[dimention + ind];
            pData[vIndex++] = m_pFrame[dimention + ind + 1];
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
    CVPixelBufferLockBaseAddress(pixelBuffer,1);
    
    int iHeight = CVPixelBufferGetHeight(pixelBuffer);
    int iWidth = CVPixelBufferGetWidth(pixelBuffer);
    int bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    
    
    byte *base = (byte *)CVPixelBufferGetBaseAddress(pixelBuffer); // baseAddress
    byte *p1 = (byte *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0); // Y-Plane = y_ch0
    byte *p2 = (byte *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1); // UV-Plane = y_ch1
    
    int baseDiff = p1 - base;     //y_base = 64;
    int uv_y = p2-p1;       //uv_y = 176640;
    int delta = uv_y - iWidth*iHeight;
    int padding = delta /  iHeight; //Calculate Padding
    NSLog(@"THeKing: iHeight = %i, iWidth = %i, bytesPerRow = %i, ExtendedWidth = %i, (baseDiff,uv-y,delta) = (%i,%i,%i), padding = %i\n", iHeight , iWidth, bytesPerRow, bytesPerRow/4, baseDiff, uv_y, delta, padding);
    
    
    byte *yDestPlane = (byte*)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    //memcpy(yDestPlane, y_ch0, iRenderWidth * iRenderHeight);
    
    if(iHeight < iWidth )
    {
        padding = 0;
    }
    unsigned char *p = yDestPlane;
    for(int i=0;i<iHeight;i++)
    {
        memcpy(p + i * (iWidth+padding),  y_ch0 + i * iWidth, iWidth);
    }
    byte *uvDestPlane = (byte*)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    //memcpy(uvDestPlane, y_ch1, iRenderWidth * iRenderHeight / 2);
    
    
    p = uvDestPlane;
    for(int i=0; i*iWidth < (iHeight*iWidth>>1); i++)
    {
        memcpy(p +i * (iWidth+padding) , y_ch1 +  i * iWidth , iWidth);
    }

    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 1);
    
    if (result != kCVReturnSuccess) {
        NSLog(@"Unable to create cvpixelbuffer %d", result);
    }
    return pixelBuffer;
}

int CVideoConverter::Convert_UIImage_To_RGBA8(UIImage *pImage, byte** outBuf)
{
    return 1;
    
}

int CVideoConverter::DownScaleVideoData(byte* pData, int &iHeight, int &iWidth, byte* outputData)
{
    
    int YPlaneLength = iHeight*iWidth;
    int indx = 0;

    for(int i=0;i<iHeight;i+=4)
    {
        for(int j=0;j<iWidth;j+=2)
        {
            outputData[indx++] = pData[i*iWidth + j];
        }
        
        for(int j=0;j<iWidth;j+=2)
        {
            outputData[indx++] = pData[(i+1)*iWidth + j];
        }
    }
    
    byte*p = pData+YPlaneLength;
    
    for(int i=0;i<iHeight/2;i+=2)
    {
        for(int j=0;j<iWidth;j+=4)
        {
            outputData[indx++] = p[i*iWidth + j];
            outputData[indx++] = p[i*iWidth + j+1];
        }
    }
    
    //cout<<"CurrentLen = "<<indx<<endl;
    
    iHeight = iHeight>>1;
    iWidth = iWidth>>1;
    
    
    return indx;
    
}

int CVideoConverter::DownScaleVideoDataWithAverage(byte* pData, int &iHeight, int &iWidth, byte* outputData)
{
    
    int YPlaneLength = iHeight*iWidth;
    int indx = 0;
    
    for(int i=0;i<iHeight;i+=4)
    {
        for(int j=0;j<iWidth;j+=2)
        {
            //outputData[indx++] = pData[i*iWidth + j];
            
            int w,x,y,z;
            w = pData[i*iWidth + j];
            x = pData[i*iWidth + j+2];
            y = pData[(i+2)*iWidth + j];
            z = pData[(i+2)*iWidth + j+2];
            int avg = (w+x+y+z)/4;
            outputData[indx++] = (byte)avg;
            
        }
        
        for(int j=0;j<iWidth;j+=2)
        {
            int I = i+1;
            
            int w,x,y,z;
            w = pData[I*iWidth + j];
            x = pData[I*iWidth + j+2];
            y = pData[(I+2)*iWidth + j];
            z = pData[(I+2)*iWidth + j+2];
            int avg = (w+x+y+z)/4;
            outputData[indx++] = (byte)avg;
        }
    }
    
    byte*p = pData+YPlaneLength;
    for(int i=0;i<iHeight/2;i+=2)
    {
        for(int j=0;j<iWidth;j+=4)
        {
            int w,x,y,z, J, avg;
            
            
            w = p[i*iWidth + j];
            x = p[i*iWidth + j+2];
            y = p[(i+1)*iWidth + j];
            z = p[(i+1)*iWidth + j+2];
            avg = (w+x+y+z)/4;
            outputData[indx++] = (byte)avg;
            //outputData[indx++] = p[i*iWidth + j];
            
            J = j+1;
            w = p[i*iWidth + J];
            x = p[i*iWidth + J+2];
            y = p[(i+1)*iWidth + J];
            z = p[(i+1)*iWidth + J+2];
            avg = (w+x+y+z)/4;
            outputData[indx++] = (byte)avg;
            //outputData[indx++] = p[i*iWidth + j+1];
        }
    }
    
    cout<<"CurrentLen = "<<indx<<endl;
    
    iHeight = iHeight>>1;
    iWidth = iWidth>>1;
    
    
    return indx;
    
}


int CVideoConverter::DownScaleVideoDataWithAverageVersion2(byte* pData, int &iHeight, int &iWidth, byte* outputData)
{
    
    int YPlaneLength = iHeight*iWidth;
    int indx = 0;
    
    for(int i=0;i<iHeight;i+=4)
    {
        for(int j=0;j<iWidth;j+=2)
        {
            //outputData[indx++] = pData[i*iWidth + j];
            int w,x,y,z;
            if(j%2==0)
            {
                w = pData[i*iWidth + j];
                x = pData[i*iWidth + j+1];
                y = pData[(i+1)*iWidth + j];
                z = pData[(i+1)*iWidth + j+1];
                int avg = (w+x+y+z)/4;
                outputData[indx++] = (byte)avg;
            }
            else
            {
                w = pData[i*iWidth + j+1];
                x = pData[i*iWidth + j+2];
                y = pData[(i+1)*iWidth + j+1];
                z = pData[(i+1)*iWidth + j+2];
                int avg = (w+x+y+z)/4;
                outputData[indx++] = (byte)avg;
            }
        }
        
        for(int j=0;j<iWidth;j+=2)
        {
            int I = i+1;
            
            int w,x,y,z;
            if(j%2==0)
            {
                w = pData[(I+1)*iWidth + j];
                x = pData[(I+1)*iWidth + j+1];
                y = pData[(I+2)*iWidth + j];
                z = pData[(I+2)*iWidth + j+1];
                int avg = (w+x+y+z)/4;
                outputData[indx++] = (byte)avg;
            }
            else
            {
                w = pData[(I+1)*iWidth + j+1];
                x = pData[(I+1)*iWidth + j+2];
                y = pData[(I+2)*iWidth + j+1];
                z = pData[(I+2)*iWidth + j+2];
                int avg = (w+x+y+z)/4;
                outputData[indx++] = (byte)avg;
            }
        }
    }
    
    byte*p = pData+YPlaneLength;
    for(int i=0;i<iHeight/2;i+=2)
    {
        for(int j=0;j<iWidth;j+=4)
        {
            int w,x,y,z, J, avg;
            
            
            w = p[i*iWidth + j];
            x = p[i*iWidth + j+2];
            y = p[(i+1)*iWidth + j];
            z = p[(i+1)*iWidth + j+2];
            avg = (w+x+y+z)/4;
            outputData[indx++] = (byte)avg;
            
            J = j+1;
            w = p[i*iWidth + J];
            x = p[i*iWidth + J+2];
            y = p[(i+1)*iWidth + J];
            z = p[(i+1)*iWidth + J+2];
            avg = (w+x+y+z)/4;
            outputData[indx++] = (byte)avg;
        }
    }
    
    cout<<"CurrentLen = "<<indx<<endl;
    
    iHeight = iHeight>>1;
    iWidth = iWidth>>1;
    
    
    return indx;
    
}

float arrWght[352][352][10][10];
float arrWsum[352][352];
int g_first = 0;
void CVideoConverter::GaussianBlur(unsigned char* scl, unsigned char* tcl, int h, int w, float r)
{
    float rs = ceil(r * 2.57);     // significant radius
    
    rs = 1;
    if(g_first == 0)
    {
        g_first = 1;
        for(int i=0; i<h; i++)
        {
            
            for(int j=0; j<w; j++)
            {
                float val = 0, wsum = 0;
                
                for(int iy = i-rs; iy<i+rs+1; iy++)
                {
                    for(int ix = j-rs; ix<j+rs+1; ix++)
                    {
                        int x = min(w-1, max(0, ix));
                        int y = min(h-1, max(0, iy));
                        int dsq = (ix-j)*(ix-j)+(iy-i)*(iy-i);
                        
                        float wght = exp( -dsq / (2*r*r) ) / (3.1416*2*r*r);
                        
                        arrWght[i][j][x % w][y % h] = wght;
                        
                        val += scl[y*w+x] * arrWght[i][j][x % w][y % h];
                        
                        wsum += wght;
                        
                    }
                }
                
                arrWsum[i][j] = wsum;
                
                
                tcl[i*w+j] = (unsigned char)floor(val/arrWsum[i][j] + 0.5);
            }
        }
    
    }
    else
    {
        for(int i=0; i<h; i++)
        {
            
            for(int j=0; j<w; j++)
            {
                float val = 0, wsum = 0;
                
                for(int iy = i-rs; iy<i+rs+1; iy++)
                {
                    for(int ix = j-rs; ix<j+rs+1; ix++)
                    {
                        int x = min(w-1, max(0, ix));
                        int y = min(h-1, max(0, iy));
                        
                        //int dsq = (ix-j)*(ix-j)+(iy-i)*(iy-i);
                        //float wght = exp( -dsq / (2*r*r) ) / (3.1416*2*r*r);
                        
                        //arrWght[i][j][x % h][y % w] = wght;
                        
                        val += scl[y*w+x] * arrWght[i][j][x % w][y % h];
                        
                        //wsum += wght;
                        
                    }
                }
                
                //arrWsum[i][j] = wsum;
                
                
                tcl[i*w+j] = (unsigned char)floor(val/arrWsum[i][j] + 0.5);
            }
        }
        
    }
}

int sizes[3];

void CVideoConverter::boxesForGauss(float sigma, int n)  // standard deviation, number of boxes
{
    float wIdeal = sqrt((12*sigma*sigma/n)+1);  // Ideal averaging filter width
    int wl = floor(wIdeal);  if(wl%2==0) wl--;
    int wu = wl+2;
				
    float mIdeal = (12*sigma*sigma - n*wl*wl - 4*n*wl - 3*n)/(-4*wl - 4);
    int m = floor(mIdeal + 0.5);
    
    // var sigmaActual = Math.sqrt( (m*wl*wl + (n-m)*wu*wu - n)/12 );
				
    for(int i=0; i<n; i++)
    {
        sizes[i]=i<m?wl:wu;
    }
    
    return;
}

void CVideoConverter::GaussianBlur_4thApproach(unsigned char* scl, unsigned char* tcl, int h, int w, float r)
{
    boxesForGauss(r, 3);

    //boxBlur_4 (scl, tcl, h, w, (sizes[0]-1)/2);
    //boxBlur_4 (tcl, scl, h, w, (sizes[1]-1)/2);
    boxBlur_4 (scl, tcl, h, w, (sizes[2]-1)/2);
}


void CVideoConverter::boxBlur_4 (unsigned char *scl, unsigned char *tcl, int h, int w, int r)
{
    //for(var i=0; i<scl.length; i++) tcl[i] = scl[i];
    
    boxBlurH_4(tcl, scl, h, w, r);
    //boxBlurT_4(scl, tcl, h, w, r);
}

void CVideoConverter::boxBlurH_4 (unsigned char *scl, unsigned char *tcl, int h, int w, int r)
{
    int iarr = (r+r+1);
    for(int i=0; i<h; i++)
    {
        int ti = i*w, li = ti, ri = ti+r;
        int fv = scl[ti], lv = scl[ti+w-1], val = (r+1)*fv;
        
        for(int j=0; j<r; j++) val += scl[ti+j];
        for(int j=0  ; j<=r ; j++) { val += scl[ri++] - fv       ;   tcl[ti++] = (unsigned char)(val/iarr); }
        for(int j=r+1; j<w-r; j++) { val += scl[ri++] - scl[li++];   tcl[ti++] = (unsigned char)(val/iarr); }
        //for(int j=w-r; j<w  ; j++) { val += lv        - scl[li++];   tcl[ti++] = (unsigned char)floor(val*iarr + 0.5); }
    }
}
void CVideoConverter::boxBlurT_4 (unsigned char *scl, unsigned char *tcl, int h, int w, int r)
{
    float iarr = (1*1.0) / ((r+r+1)*1.0);
    
    for(int i=0; i<w; i++)
    {
        int ti = i, li = ti, ri = ti+r*w;
        int fv = scl[ti], lv = scl[ti+w*(h-1)], val = (r+1)*fv;
        
        for(int j=0; j<r; j++) val += scl[ti+j*w];
        for(int j=0  ; j<=r ; j++) { val += scl[ri] - fv     ;  tcl[ti] = (unsigned char)floor(val*iarr + 0.5);  ri+=w; ti+=w; }
        for(int j=r+1; j<h-r; j++) { val += scl[ri] - scl[li];  tcl[ti] = (unsigned char)floor(val*iarr + 0.5);  li+=w; ri+=w; ti+=w; }
        for(int j=h-r; j<h  ; j++) { val += lv      - scl[li];  tcl[ti] = (unsigned char)floor(val*iarr + 0.5);  li+=w; ti+=w; }
    }
}


void CVideoConverter::EnhanceTemperature (unsigned char *scl, int iHeight, int iWidth, int iThreshold)
{
    
    //if((yVal > 65 && yVal < 170) &&(uVal > 85 && uVal < 180) && (vVal > 85 && vVal < 180))
        
        
    int iLen = iHeight * iWidth * 3 / 2;
    int iStartInd = iHeight*iWidth;
    
    int increase = 0;
    for(int i=iStartInd; i<iLen; i++)
    {
        if(i%2==0)
        {
            //Changing U data
            scl[i] = scl[i]-iThreshold < 0 ? 0 : scl[i]-iThreshold;
        }
        else
        {
            //Changing V Data
            scl[i] = scl[i]+iThreshold > 255 ? 255 : scl[i]+iThreshold;
        }
        
        scl[i] = scl[i]+increase>255? 255:scl[i]+increase;
    }
}

int yuCon[352*288];
int yvCon[352*288];


void CVideoConverter::generateUVIndex(int imageWidth, int imageHeight)
{
    int iHeight = imageHeight;
    int iWidth = imageWidth;
    int yLength = iHeight * iWidth;
    int uLength = yLength/2;
    
    int yConIndex = 0;
    int vIndex = yLength + 1;
    int uIndex = yLength;
    int heightIndex = 1;
    
    for(int i = 0;  ;)
    {
        if(i == iWidth*heightIndex)
        {
            i+=iWidth;
            heightIndex+=2;
        }
        if(i>=yLength) break;
        yConIndex = i;
        
        yuCon[yConIndex] = uIndex;
        yuCon[yConIndex + 1] = uIndex;
        yuCon[yConIndex + iWidth] = uIndex;
        yuCon[yConIndex + iWidth + 1] = uIndex;
        
        yvCon[yConIndex] = vIndex;
        yvCon[yConIndex + 1] = vIndex;
        yvCon[yConIndex + iWidth] = vIndex;
        yvCon[yConIndex + iWidth + 1] = vIndex;
        
        
        uIndex += 2;
        vIndex += 2;
        i+=2;
    }
}

#define CLIP(X) ( (X) > 255 ? 255 : (X) < 0 ? 0 : X)

#define C(Y) ( (Y) - 16  )
#define D(U) ( (U) - 128 )
#define E(V) ( (V) - 128 )

#define YUV2R(Y, U, V) CLIP(( 298 * C(Y)              + 409 * E(V) + 128) >> 8)
#define YUV2G(Y, U, V) CLIP(( 298 * C(Y) - 100 * D(U) - 208 * E(V) + 128) >> 8)
#define YUV2B(Y, U, V) CLIP(( 298 * C(Y) + 516 * D(U)              + 128) >> 8)


void CVideoConverter::DetectAndShowOnlySkin(unsigned char *pRawYuv, int iHeight, int iWidth)
{
    generateUVIndex(iHeight, iWidth);
    int iLen = iHeight * iWidth * 3 / 2;
    
    int Y,U,V, uIndex, vIndex, R, G, B;
    
    for(int i=0;i<iHeight*iWidth;i++)
    {
        Y = (int)pRawYuv[i];
        uIndex = yuCon[i];
        vIndex = yvCon[i];
        
        U = (int)pRawYuv[uIndex];
        V = (int)pRawYuv[vIndex];
        
        /*R = Y + 1.140 * V;
        G = Y - 0.395 * U - 0.581 * V;
        B = Y + 2.032 * U;*/
        
        /*Y = 0.299R + 0.587G + 0.114B
         U = 0.492 (B-Y)
         V = 0.877 (R-Y)*/
        
        
        
        /*R = (int)(R < 0 ? 0 : R > 255 ? 255 : R);
        G = (int)(G < 0 ? 0 : G > 255 ? 255 : G);
        B = (int)(B < 0 ? 0 : B > 255 ? 255 : B);*/
        
        R = YUV2R(Y,U,V);
        G = YUV2G(Y,U,V);
        B = YUV2B(Y,U,V);
        
        
       /*cout<<"Y,U,V = "<<Y<<", "<<U<<", "<<V<<" --> ";
        cout<<"R,G,B = "<<R<<", "<<G<<", "<<B<<endl;*/
        
        //if(!isSkin(R,G,B))
        if((U>=95 && U<=125) && ( V >=135 && V<=175))
        {
            
        }
        else
        {
            pRawYuv[i] = (unsigned char) 100;
            pRawYuv[uIndex] = (unsigned char) 185;
            pRawYuv[vIndex] = (unsigned char) 239;
            
            pRawYuv[i] = (unsigned char) 0;
            pRawYuv[uIndex] = (unsigned char) 0;
            pRawYuv[vIndex] = (unsigned char) 0;
        }
    }
    
}

bool CVideoConverter::isSkin2(int R, int G, int B)
{
    return R > 60 && (G < R * 0.85) && (B < R * 0.7) && (G > R * 0.4) && (B > R * 0.2);
}

bool CVideoConverter::isSkin (int r, int g, int b)
{
    
    // classify based on RGB
    bool rgbClassifier = ((r > 95) && (g > 40 && g < 100) && (b > 20) && ((getMax(r, g, b) - getMin(r, g, b)) > 15) && (getAbs(r - g) > 15) && (r > g) && (r > b));
    
    // classify based on normalized RGB
    int sum = r + g + b;
    
    float nr = (r / sum), ng = (g / sum), nb = (b / sum);
    
    bool normRgbClassifier = (((nr / ng) > 1.185) && (((r * b) / (pow(r + g + b, 2))) > 0.107) && (((r * g) / (pow(r + g + b, 2))) > 0.112));
    
    // classify based on hue
    float h = 0,
    mx = getMax(r, g, b),
    mn = getMin(r, g, b),
    dif = mx - mn;
    
    if (mx == r)
    {
        h = (g - b) / dif;
    }
    else if (mx == g)
    {
        h = 2 + ((g - r) / dif);
    }
    else
    {
        h = 4 + ((r - g) / dif);
    }
    
    h = h * 60;
    
    if (h < 0)
    {
        h = h + 360;
    }
    
    float s = 1 - (3 * ((getMin(r, g, b)) / (r + g + b)));
    
    bool hsvClassifier = (h > 0 && h < 35 && s > 0.23 && s < 0.68);
    
    //cout<<"rgb,norm,hsv = "<<rgbClassifier<<","<<normRgbClassifier<<","<<hsvClassifier<<endl;
    
    // match either of the classifiers
    return (rgbClassifier || normRgbClassifier || hsvClassifier); // 
}



int tmp[10];
void CVideoConverter::ChangeBlock_9x9_To_4x4(unsigned char *inData, int iHeight, int iWidth, int i, int j, int iNewHeight, int iNewWidth, int m, int n, unsigned char *outData, int iw)
{
    int tmpindx = 0, x, y;
    
    x = inData[iw + j];
    y = inData[iw + j+1];
    tmp[tmpindx++] = (x+y)>>1;
    
    x = inData[iw + j+2];
    y = inData[iw + j+1];
    tmp[tmpindx++] = (x+y)>>1;
    
    iw += iWidth;
    x = inData[iw + j];
    y = inData[iw + j+1];
    tmp[tmpindx++] = (x+y)>>1;
    
    x = inData[iw + j+2];
    y = inData[iw + j+1];
    tmp[tmpindx++] = (x+y)>>1;
    
    iw += iWidth;
    x = inData[iw + j];
    y = inData[iw + j+1];
    tmp[tmpindx++] = (x+y)>>1;
    
    x = inData[iw + j+2];
    y = inData[iw + j+1];
    tmp[tmpindx++] = (x+y)>>1;
    
    
    
    
    outData[m*iNewWidth + n] = (tmp[0] + tmp[2]) >> 1;
    outData[m*iNewWidth + n+1] = (tmp[1] + tmp[3]) >> 1;
    outData[(m+1)*iNewWidth + n] = (tmp[2] + tmp[4]) >> 1;
    outData[(m+1)*iNewWidth + n+1] = (tmp[3] + tmp[5]) >> 1;
    
}

int CVideoConverter::DownScale_3_2_YUV420(unsigned char* pData, int &iHeight, int &iWidth, unsigned char* outputData)
{
    int YPlaneLength = iHeight*iWidth;
    int UPlaneLength = YPlaneLength >> 2;
    
    int iNewWidth, iNewHeight;
    iNewWidth = (iWidth * 2) / 3;
    iNewHeight = (iHeight * 2) / 3;
    
    int m = 0, n=0;
    
    for(int i=0, iw = 0, m=0;i+2<iHeight; i+=3, m+=2, iw += iWidth + iWidth + iWidth)
    {
        for(int j=0, n=0; j+2<iWidth; j+=3, n+=2)
        {
            ChangeBlock_9x9_To_4x4(pData, iHeight, iWidth, i, j, iNewHeight, iNewWidth, m, n, outputData, iw);
            
        }
    }
    
    int uIndex = iNewHeight * iNewWidth;
    int Hello = uIndex;
    int shiftedHello = Hello>>2;
    int vIndex = uIndex + shiftedHello;
    
    int halfWidth, halfheight, newHalfWidth, newHalfHeight;
    
    halfWidth = iWidth>>1;
    halfheight = iHeight>>1;
    newHalfWidth = iNewWidth>>1;
    newHalfHeight = iNewHeight>>1;
    
    for(int i=0, iw = 0, m=0;i<halfheight; i+=3, m+=2, iw += halfWidth + halfWidth + halfWidth)
    {
        for(int j=0, n=0; j<halfWidth; j+=3, n+=2)
        {
            ChangeBlock_9x9_To_4x4(pData + YPlaneLength, halfheight, halfWidth, i, j, newHalfHeight, newHalfWidth, m, n, outputData + uIndex, iw);
            
            ChangeBlock_9x9_To_4x4(pData + YPlaneLength + UPlaneLength, halfheight, halfWidth, i, j, newHalfHeight, newHalfWidth, m, n, outputData + vIndex, iw);
            
        }
    }
    
    iHeight = iNewHeight;
    iWidth = iNewWidth;
    printf("Finally Scaling, iNewHeight = %d, iNewWidth = %d, Actual H:W = %d:%d, uIndex = %d, vIndex = %d\n", iNewHeight, iNewWidth, iHeight, iWidth, uIndex, vIndex);
    printf("Scaling Done\n");
    return iNewHeight*iNewWidth*3/2;
}





int CVideoConverter::getMin(int a, int b, int c)
{
    return min(a,min(b,c));
}
int CVideoConverter::getAbs(int a)
{
    if(a<0) return a*(-1);
    return a;
}
int CVideoConverter::getMax(int a, int b, int c)
{
    return max(a,max(b,c));
}




