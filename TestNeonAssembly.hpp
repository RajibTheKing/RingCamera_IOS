//
//  TestNeonAssembly.hpp
//  TestCamera 
//
//  Created by Rajib Chandra Das on 7/26/17.
//
//

#ifndef TestNeonAssembly_hpp
#define TestNeonAssembly_hpp

#include <stdio.h>
#include <iostream>

//#include "Neon_Assembly.s"

extern "C"
{
    void convert_arm_neon( unsigned char*  __restrict dest, unsigned char* __restrict src, int n);
    void add_arm_neon(unsigned char*  __restrict dest, unsigned char*  __restrict src, int n);
    void copy_arm_neon(unsigned char* __restrict src, unsigned char* __restrict dest, int iLen);
    void convert_nv12_to_i420_arm_neon(unsigned char* __restrict src, unsigned char* __restrict dest, int iHeight, int iWidth);
    void learn_arm_neon();
    void crop_yuv420_arm_neon(unsigned char* __restrict src, unsigned char* __restrict dst, unsigned int* __restrict param);
    void Crop_YUVNV12_YUVNV21_arm_aarch64(unsigned char* __restrict src, unsigned char* __restrict dst, unsigned int* __restrict param);
    void Crop_YUVNV12_YUVNV21_arm_aarch32(unsigned char* __restrict src, unsigned char* __restrict dst, unsigned int* __restrict param);
    void CalculateSumOfLast64_ARM_NEON(unsigned int* __restrict pData, unsigned int* __restrict ans);
    void Reverse_array_arm_neon(unsigned char* pInData, int iLen, unsigned char* pOutData);
    void Reverse_array_arm_neon_version2(unsigned char* pInData, int iLen, unsigned char* pOutData);
    void mirror_YUV420_arm_neon(unsigned char *pInData, unsigned char *pOutData, int iHeight, int iWidth);
    
    int ConvertNV21ToI420_arm_aarch64(unsigned char *convertingData, unsigned char *outputData, int iVideoHeight, int iVideoWidth);
    int ConvertNV21ToI420_arm_aarch32(unsigned char *convertingData, unsigned char *outputData, int iVideoHeight, int iVideoWidth);
    
    void BeautificationFilterForChannel_arm_aarch64(unsigned char *inData, unsigned int* param, unsigned char* outData, unsigned short* tempShortArray);
    void BeautificationFilterForChannel_arm_aarch32(unsigned char *inData, unsigned int* param, unsigned char* outData, unsigned short* tempShortArray);
    
    void down_scale_one_fourth_arm_neon(unsigned char *pInData, int iHeight, int iWidth, unsigned char *pOutData);
    void Rotate90Degree_arm_neon_aarch64(unsigned char *pInData, unsigned char *pOutData, int iHeight, int iWidth);
    void ne10_img_rotate_get_quad_rangle_subpix_rgba_neon(unsigned char *pDst, unsigned char *pSrc, int iWidth, int iHeight);
    
}


class TestNeonAssembly
{
public:
    TestNeonAssembly();
    ~TestNeonAssembly();

    static TestNeonAssembly* GetInstance();
    
    void reference_convert (unsigned char* __restrict dest, unsigned char* __restrict src, int n);
    void neon_intrinsic_convert (unsigned char* __restrict dest, unsigned char* __restrict src, int n);
    void neon_assembly_convert (unsigned char*  __restrict dest, unsigned char* __restrict src, int n);
    void neon_assembly_Inc(unsigned char*  __restrict dest, unsigned char*  __restrict src, int n);
    void Copy_Assembly_Inc(unsigned char* __restrict src, unsigned char* __restrict dest, int iLen);
    void convert_nv12_to_i420_assembly(unsigned char* __restrict src, unsigned char* __restrict dest, int iHeight, int iWidth);
    void learn();
    void Crop_yuv420_assembly(unsigned char* src, int inHeight, int inWidth, int startXDiff, int endXDiff, int startYDiff, int endYDiff, unsigned char* dst, int &outHeight, int &outWidth);
    void Crop_YUVNV12_YUVNV21_assembly(unsigned char* pData, int inHeight, int inWidth, int startXDiff, int endXDiff, int startYDiff, int endYDiff, unsigned char* outputData, int &outHeight, int &outWidth);
    void CalculateSumOfLast64_assembly(unsigned int * pData, unsigned int *ans);
    void Reverse_array(unsigned char* pInData, int iLen, unsigned char* pOutData);
    void Mirror_YUV420_Assembly(unsigned char *pInData, unsigned char *pOutData, int iHeight, int iWidth);
    void DownScaleOneFourthAssembly(unsigned char *pInData, int iHeight, int iWidth, unsigned char *pOutData);
    
    void BeautificationFilterForChannel_assembly(unsigned char *pBlurConvertingData, int iHeight, int iWidth);

    
    int ConvertNV21ToI420_assembly(unsigned char *convertingData, int iVideoHeight, int iVideoWidth);
    
    void RotateI420_Assembly(unsigned char *pInput, int inHeight, int inWidth, unsigned char *pOutput, int &outHeight, int &outWidth, int rotationParameter);
    
    
    void ne10_img_rotate_Assembly(unsigned char *pDst, unsigned char *pSrc, int iWidth, int iHeight);
    
    //unsigned char *m_pTempArray2;
    unsigned char m_pTempCharArray[640 * 480 * 3];
    unsigned short m_pTempShortArray[640 * 480 * 3];
    
    unsigned int* __restrict param;
};
static TestNeonAssembly *g_TestNeonAssembly = nullptr;


#endif /* TestNeonAssembly_hpp */
