//
//  BeautificationFilter.hpp
//  TestCamera
//
//  Created by Rajib Chandra Das on 4/3/18.
//

#ifndef BeautificationFilter_hpp
#define BeautificationFilter_hpp
#include <iostream>
#include <stdio.h>
class BeautificationFilter
{
public:
    BeautificationFilter();
    ~BeautificationFilter();
    static BeautificationFilter* GetInstance();
    void doSharpen(unsigned char *pBlurConvertingData, int iHeight, int iWidth);
    void doSharpen2(unsigned char *inData, int iHeight, int iWidth, unsigned char *outData);
    
    
    int m_mean[640][640];
    int m_Temp[640*640*3/2];
};
static BeautificationFilter *g_BeautificationFilter = nullptr;
#endif /* BeautificationFilter_hpp */
