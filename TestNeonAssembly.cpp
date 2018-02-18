//
//  TestNeonAssembly.cpp
//  TestCamera 
//
//  Created by Rajib Chandra Das on 7/26/17.
//
//

#include "TestNeonAssembly.hpp"
#include <arm_neon.h>

#include <algorithm>


TestNeonAssembly::TestNeonAssembly()
{
    param = new unsigned int[10];
}

TestNeonAssembly::~TestNeonAssembly()
{
    delete[] param;
}

void TestNeonAssembly::reference_convert (unsigned char * __restrict dest, unsigned char * __restrict src, int n)
{
    int i;
    for (i=0; i<n; i++)
    {
        int r = *src++; // load red
        int g = *src++; // load green
        int b = *src++; // load blue
        
        // build weighted average:
        int y = (r*77)+(g*151)+(b*28);
        
        // undo the scale by 256 and write to memory:
        *dest++ = (y>>8);
    }
}

void TestNeonAssembly::neon_intrinsic_convert (unsigned char * __restrict dest, unsigned char * __restrict src, int n)
{
    int i;
    uint8x8_t rfac = vdup_n_u8 (77);
    uint8x8_t gfac = vdup_n_u8 (151);
    uint8x8_t bfac = vdup_n_u8 (28);
    n/=8;
    
    for (i=0; i<n; i++)
    {
        uint16x8_t  temp;
        uint8x8x3_t rgb  = vld3_u8 (src);
        uint8x8_t result;
        
        temp = vmull_u8 (rgb.val[0],      rfac);
        temp = vmlal_u8 (temp,rgb.val[1], gfac);
        temp = vmlal_u8 (temp,rgb.val[2], bfac);
        
        result = vshrn_n_u16 (temp, 8);
        vst1_u8 (dest, result);
        src  += 8*3;
        dest += 8;
    }
}

void TestNeonAssembly::neon_assembly_convert (unsigned char*  __restrict dest, unsigned char*  __restrict src, int n)
{
    convert_arm_neon(dest,src,n);
}

void TestNeonAssembly::neon_assembly_Inc(unsigned char*  __restrict dest, unsigned char*  __restrict src, int n)
{
    add_arm_neon(dest,src,n);
}

void TestNeonAssembly::Copy_Assembly_Inc(unsigned char* __restrict src, unsigned char* __restrict dest, int iLen)
{
    copy_arm_neon(src, dest, iLen);
}

void TestNeonAssembly::convert_nv12_to_i420_assembly(unsigned char* __restrict src, unsigned char* __restrict dest, int iHeight, int iWidth)
{
    convert_nv12_to_i420_arm_neon(src, dest, iHeight, iWidth);
}

void TestNeonAssembly::learn()
{
    //learn_arm_neon();
}
void TestNeonAssembly::Crop_yuv420_assembly(unsigned char* src, int inHeight, int inWidth, int startXDiff, int endXDiff, int startYDiff, int endYDiff, unsigned char* dst, int &outHeight, int &outWidth)
{
    outHeight = inHeight - startYDiff - endYDiff;
    outWidth = inWidth - startXDiff - endXDiff;
    param[0] = inHeight;
    param[1] = inWidth;
    param[2] = startXDiff;
    param[3] = endXDiff;
    param[4] = startYDiff;
    param[5] = endYDiff;
    param[6] = outHeight;
    param[7] = outWidth;
    
    crop_yuv420_arm_neon(src, dst, param);
    //ARM_NEON_AARCH_64: 2017-10-05 15:52:02.894346 MediaEngine[1114:344013] TimeElapsed = 0, frames = 1016, totalDiff = 82 ms
    //ARM_NEON: 2017-08-26 19:45:28.245923 MediaEngine[442:110984] TimeElapsed = 0, frames = 1016, totalDiff = 123 ms
    //C++: 2017-08-26 19:46:39.203911 MediaEngine[445:111660] TimeElapsed = 0, frames = 1016, totalDiff = 588 ms
}
void TestNeonAssembly::CalculateSumOfLast64_assembly(unsigned int * pData, unsigned int *ans)
{
    CalculateSumOfLast64_ARM_NEON(pData, ans);
}

#define OPTIMIZATION

void TestNeonAssembly::Reverse_array(unsigned char* pInData, int iLen, unsigned char* pOutData)
{
    Reverse_array_arm_neon(pInData, iLen, pOutData);
    //Reverse_array_arm_neon_version2(pInData, iLen, pOutData);
   /*
#ifdef OPTIMIZATION
    std::reverse(pInData, pInData + iLen);
    memcpy(pOutData, pInData, iLen);
    
#else
    int indx = 0;
    for(int i=iLen-1; i>=0; i--)
    {
        pOutData[indx++] = pInData[i];
    }
#endif
    */
}
void TestNeonAssembly::Mirror_YUV420_Assembly(unsigned char *pInData, unsigned char *pOutData, int iHeight, int iWidth)
{
    mirror_YUV420_arm_neon(pInData, pOutData, iHeight, iWidth);
    //c++: IPhone6s --> 2017-11-04 17:20:28.030662+0600 MediaEngine[518:125677] mirrorYUVI420 TimeElapsed = 0, frames = 1000, totalDiff = 771
    //arm64: Iphone6s--> 2017-11-04 17:22:32.765089+0600 MediaEngine[522:126777] mirrorYUVI420 TimeElapsed = 1, frames = 1000, totalDiff = 130
    
    //c++: Ipod --> 2017-11-04 17:31:54.738 MediaEngine[240:30295] mirrorYUVI420 TimeElapsed = 1, frames = 1000, totalDiff = 1421
    //arm32: Ipod --> 2017-11-04 17:30:13.779 MediaEngine[234:29610] mirrorYUVI420 TimeElapsed = 0, frames = 1000, totalDiff = 1127
}

void TestNeonAssembly::DownScaleOneFourthAssembly(unsigned char *pInData, int iHeight, int iWidth, unsigned char *pOutData)
{
    down_scale_one_fourth_arm_neon(pInData, iHeight, iWidth, pOutData);
    //arm32: Ipod5G 2017-11-14 13:25:27.451 MediaEngine[256:28313] DownScaleOneFourth TimeElapsed = 4, frames = 1010, totalDiff = 4289
    //c++: Ipod5G 2017-11-14 13:28:33.492 MediaEngine[262:29125] DownScaleOneFourth TimeElapsed = 12, frames = 1010, totalDiff = 12282
    
    //arm64: Iphone6S 2017-11-13 17:14:00.506603+0600 MediaEngine[966:252105] DownScaleOneFourth TimeElapsed = 1, frames = 1065, totalDiff = 782
    //c++: Iphone6S2 017-11-13 17:15:51.738798+0600 MediaEngine[969:253245] DownScaleOneFourth TimeElapsed = 3, frames = 1048, totalDiff = 4324
}

void TestNeonAssembly::RotateI420_Assembly(unsigned char *pInput, int inHeight, int inWidth, unsigned char *pOutput, int &outHeight, int &outWidth, int rotationParameter)
{
    if(rotationParameter == 3) /*90 Degree rotation*/
    {
        Rotate90Degree_arm_neon_aarch64(pInput, pOutput, inHeight, inWidth);
        outHeight = inWidth;
        outWidth = inHeight;
        
        //Testing Device: iPhone 6
        //TheKing--> rotationI420 timediffsum = 994, framecounter = 1000 assembly arm64 debug
        //TheKing--> rotationI420 timediffsum = 1034, framecounter = 1000 assembly arm64 release
        
        //TheKing--> rotationI420 timediffsum = 2889, framecounter = 1000 c++ debug
        //TheKing--> rotationI420 timediffsum = 946, framecounter = 1000 c++ release
        
    }
}

void TestNeonAssembly::ne10_img_rotate_Assembly(unsigned char *pDst, unsigned char *pSrc, int iWidth, int iHeight)
{
    
#ifdef HAVE_NEON
    printf("TheKing--> ne10_img_rotate_Assembly HAVE_NEON\n");
    ne10_img_rotate_get_quad_rangle_subpix_rgba_neon(pDst, pSrc, iWidth, iHeight);
#endif
}
