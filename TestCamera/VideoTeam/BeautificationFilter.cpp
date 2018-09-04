//
//  BeautificationFilter.cpp
//  TestCamera
//
//  Created by Rajib Chandra Das on 4/3/18.
//

#include "BeautificationFilter.hpp"
#include <algorithm>
#include <math.h>
#include <stdlib.h>
using namespace std;
BeautificationFilter::BeautificationFilter()
{
    
    
}

BeautificationFilter::~BeautificationFilter()
{
    
}

BeautificationFilter* BeautificationFilter::GetInstance()
{
    if(g_BeautificationFilter == nullptr)
    {
        g_BeautificationFilter = new BeautificationFilter();
    }
    return g_BeautificationFilter;
}

bool hell = false;

void BeautificationFilter::doSharpen(unsigned char *pBlurConvertingData, int iHeight, int iWidth)
{
    int startWidth = (iWidth - iWidth) / 2 + 1;
    int endWidth = iWidth - startWidth + 1;
    
    for (int i = 1, iw = 0, iw2 = -iWidth; i <= iHeight; i++, iw += iWidth, iw2 += iWidth)
    {
        for (int j = startWidth; j <= endWidth; j++)
        {
            m_mean[i][j] = pBlurConvertingData[iw + j - 1];
            
            if (i > 2 && j>1 && j<endWidth)
            {
                pBlurConvertingData[iw2 + j - 1] = min(255, max(0, pBlurConvertingData[iw2 + j - 1] + (((m_mean[i - 1][j] << 2) - m_mean[i - 2][j] - m_mean[i][j] - m_mean[i - 1][j - 1] - m_mean[i - 1][j + 1]) >> 0)));
            }
        }
    }
}

void BeautificationFilter::doSharpen2(unsigned char *inData, int iHeight, int iWidth, unsigned char *outData)
{
    memcpy(outData, inData, iHeight * iWidth * 3 / 2);
    int temp, curIndex, curRow;
    for(int i=1; i<iHeight-1; i++)
    {
        curRow = i*iWidth;
        for(int j=1; j<iWidth-1; j++)
        {
            curIndex = curRow + j;
            m_Temp[curIndex]   = inData[curIndex] << 2;
            
            temp = inData[curIndex] << 2;
             temp   = temp - inData[curIndex - iWidth] - inData[curIndex + iWidth];
             temp   = temp - inData[curIndex + 1] - inData[curIndex - 1];
             temp   = temp >> 0;
             outData[curIndex]   = min(255, max(0, temp + inData[curIndex]));
            //outData[curIndex] = temp + inData[curIndex];
            
        }
    }
    
    /*
    for(int i=1; i<iHeight-1; i++)
    {
        curRow = i*iWidth;
        for(int j=1; j<iWidth-1; j++)
        {
            curIndex = curRow + j;
            m_Temp[curIndex]   = m_Temp[curIndex] - inData[curIndex - iWidth] - inData[curIndex + iWidth];

        }
    }
    for(int i=1; i<iHeight-1; i++)
    {
        curRow = i*iWidth;
        for(int j=1; j<iWidth-1; j++)
        {
            curIndex = curRow + j;
            m_Temp[curIndex]   = m_Temp[curIndex] - inData[curIndex + 1] - inData[curIndex - 1];
            
        }
    }
    
    for(int i=1; i<iHeight-1; i++)
    {
        curRow = i*iWidth;
        for(int j=1; j<iWidth-1; j++)
        {
            curIndex = curRow + j;
            m_Temp[curIndex]   = m_Temp[curIndex] >> 0;
            outData[curIndex]   = min(255, max(0, m_Temp[curIndex] + inData[curIndex]));
        }
    }
     */
    
}


