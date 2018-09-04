
#include "VideoBeautificationerTest.h"
#include <cmath>
#define NV21 21
#define NV12 12

#if defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR)

#import <sys/utsname.h> // import it in your header or implementation file.
//#import <UIKit/UIKit.h>

#endif

#define getMin(a,b) a<b?a:b
#define getMax(a,b) a>b?a:b

CVideoBeautificationerTest::CVideoBeautificationerTest(int iVideoHeight, int iVideoWidth, int nChannelType) :

m_nPreviousAddValueForBrightening(0),
m_nBrightnessPrecision(0),
m_EffectValue(10),
m_nChannelType(nChannelType)
{
    m_Step0Sigma = 128;
    m_Step1Sigma = 64;
    m_Step2Sigma = 32;
    m_Step3Sigma = 16;
    m_Step4Sigma = 8;
    
    m_Step0SigmaDigit = 7;
    m_Step1SigmaDigit = 6;
    m_Step2SigmaDigit = 5;
    m_Step3SigmaDigit = 4;
    m_Step4SigmaDigit = 3;
    
    m_nChannelSharpAmountDigit = 4;
    
#if defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR)
    
    m_sigma = m_Step1Sigma;
    
#elif defined(__ANDROID__)
    
    m_sigma = m_Step1Sigma;
    
#elif defined(DESKTOP_C_SHARP)
    
    m_sigma = m_Step2Sigma;
    
#else
    
    m_sigma = m_Step2Sigma;
    
#endif
    
#if defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR)
    
    m_sigmaDigit = m_Step1SigmaDigit;
    
#elif defined(__ANDROID__)
    
    m_sigmaDigit = m_Step1SigmaDigit;
    
#elif defined(DESKTOP_C_SHARP)
    
    m_sigmaDigit = m_Step2SigmaDigit;
    
#else
    
    m_sigmaDigit = m_Step2SigmaDigit;
    
#endif
    
#if defined(DESKTOP_C_SHARP)
    
    m_radius = 8;
    
#else
    
    m_radius = 5;
    
#endif
    
    m_rr = (m_radius << 1) + 1;
    m_pixels = m_rr * m_rr;
    
#if defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR)
    
    std::string sDeviceModel = getDeviceModel();
    //printf("TheKing--> GetDeviceModel = %s\n", sDeviceModel.c_str());
    m_nIsGreaterThen5s = isGreaterThanIphone5s();
    
    //printf("TheKing--> ansGot = %d\n", ansGot);
    
    if (m_nIsGreaterThen5s > 0)
    {
        m_sigma = m_Step0Sigma;
        m_sigmaDigit = m_Step0SigmaDigit;
    }
    else
    {
        m_sigma = m_Step1Sigma;
        m_sigmaDigit = m_Step1SigmaDigit;
    }
    
#endif
    
    m_nVideoHeight = iVideoHeight;
    m_nVideoWidth = iVideoWidth;
    
    GenerateUVIndex(m_nVideoHeight, m_nVideoWidth, NV12);
    
    string str = "";
    
    for (int y = 1; y <= 255; y++)
    {
        double gray = y;
        double sqrt_value = sqrt(gray);
        gray = gray / (0.89686516089772L + 0.002502159061032L*gray - 0.040292372843353L*sqrt_value);
        gray = gray<256.0L ? gray : 255.0L;
        
        //#if defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR)
        
        //modifYUV[y] = getMax(getMin(((unsigned char)1.1643*(gray - 24)), 255),0);
        
        int a = (int)getMin((1.1643*(gray - 24)), 255);
        int b = getMax(a,0);
        
        unsigned char c = (unsigned char)((double)y * 0.803921 + 50.0);
        
        modifYUV[y] = (unsigned char)c;
        
        //#else
        
        //       modifYUV[y] = gray;
        
        //#endif
        
    }
    
    
    boxesForGauss(1, 3);
    
    for (int i = 0; i < 256; i++)
    {
        m_square[i] = i*i;
    }
    
    for (int i = 0; i < 256; i++)
    {
        for (int j = 0; j < 2300; j++)
        {
            m_precSharpness[i][j] = (int)min(255., max(0., i + (10. * i - j)/8.));
        }
    }
    
    
    for (int i = 0; i < 641; i++)
    {
        for (int j = 0; j < 641; j++)
        {
            m_Multiplication[i][j] = i*j;
        }
    }
    
    int firstDif = 125 - 25;
    int secondDif = 225 - 125;
    
    for (int i = 0; i < 256; i++)
    {
        m_preBrightness[i] = i;
        m_preBrightnessNew[i] = i;
        
        if (i >= 25 && i <= 125)
        {
            m_preBrightness[i] += (i - 25) * BRIGHTNESS_SCALE_OLD / firstDif;
            m_preBrightnessNew[i] += (i - 25) * BRIGHTNESS_SCALE_NEW / firstDif;
        }
        else if (i >= 125 && i <= 225)
        {
            m_preBrightness[i] += (225 - i) * BRIGHTNESS_SCALE_OLD / secondDif;
            m_preBrightnessNew[i] += (225 - i) * BRIGHTNESS_SCALE_NEW / secondDif;
        }
    }
    
    for (int i = 0; i < 256; i++)
    {
        m_ucpreBrightness[i] = (unsigned char)m_preBrightness[i];
        m_ucpreBrightnessNew[i] = (unsigned char)m_preBrightnessNew[i];
    }
    
    memset(m_mean, m_nVideoHeight*m_nVideoWidth, 0);
    memset(m_variance, m_nVideoHeight*m_nVideoWidth, 0);
    
    luminaceHigh = 255;
    
    brightness_shift = 15;
    m_applyBeatification = 1;
    
    //m_pVideoBeautificationMutex.reset(new CLockHandler);
}

CVideoBeautificationerTest::~CVideoBeautificationerTest()
{
    
}


void CVideoBeautificationerTest::SetHeightWidth(int iVideoHeight, int iVideoWidth)
{
    m_nVideoHeight = iVideoHeight;
    m_nVideoWidth = iVideoWidth;
    
    GenerateUVIndex(m_nVideoHeight, m_nVideoWidth, NV12);
    
    memset(m_mean, m_nVideoHeight*m_nVideoWidth, 0);
    memset(m_variance, m_nVideoHeight*m_nVideoWidth, 0);
}

void CVideoBeautificationerTest::SetDeviceHeightWidth(int iVideoHeight, int iVideoWidth)
{
    m_iDeviceHeight = iVideoHeight;
    m_iDeviceWidth = iVideoWidth;
}

void CVideoBeautificationerTest::GenerateUVIndex(int iVideoHeight, int iVideoWidth, int dataFormat)
{
    //LOGE("fahad -->> ----------------- iHeight = %d, iWdith = %d", iVideoHeight, iVideoWidth);
    int iHeight = iVideoHeight;
    int iWidth = iVideoWidth;
    int yLength = iHeight * iWidth;
    int uLength = yLength / 2;
    
    int yConIndex = 0;
    int vIndex;
    int uIndex;
    vIndex = yLength + (yLength / 4);
    uIndex = yLength;
    
    
    //LOGE("fahad -->> ----------------- iHeight = %d, iWdith = %d , vIndex = %d, uIndex = %d, yLength = %d", iVideoHeight, iVideoWidth, vIndex, uIndex, yLength);
    int heightIndex = 1;
    for (int i = 0;;)
    {
        if (i == iWidth*heightIndex) {
            i += iWidth;
            heightIndex += 2;
        }
        if (i >= yLength) break;
        yConIndex = i;
        
        
        
        m_pUIndex[yConIndex] = uIndex;
        m_pUIndex[yConIndex + 1] = uIndex;
        m_pUIndex[yConIndex + iWidth] = uIndex;
        m_pUIndex[yConIndex + iWidth + 1] = uIndex;
        
        m_pVIndex[yConIndex] = vIndex;
        m_pVIndex[yConIndex + 1] = vIndex;
        m_pVIndex[yConIndex + iWidth] = vIndex;
        m_pVIndex[yConIndex + iWidth + 1] = vIndex;
        
        //LOGE("fahad -->> ----------------- iHeight = %d, iWdith = %d , vIndex = %d, uIndex = %d, yLength = %d", iVideoHeight, iVideoWidth, vIndex, uIndex, yLength);
        
        uIndex += 1;
        vIndex += 1;
        i += 2;
    }
}

void CVideoBeautificationerTest::MakeFrameBlur(unsigned char *convertingData, int iVideoHeight, int iVideoWidth)
{
    
}

void CVideoBeautificationerTest::MakeFrameBlurAndStore(unsigned char *convertingData, int iVideoHeight, int iVideoWidth)
{
    GaussianBlur_4thApproach(convertingData, m_pBluredImage, iVideoHeight, iVideoWidth, 2);
    memcpy(convertingData,  m_pBluredImage, iVideoHeight*iVideoWidth );
}

void CVideoBeautificationerTest::MakeFrameBeautiful(unsigned char *pixel)
{
    int iTotLen = m_nVideoWidth * m_nVideoHeight;
    int iLen = m_nVideoWidth * m_nVideoHeight;//(int)(modifData.length / 1.5);
    int totalYValue = 0;
    
    for (int i = 0; i<iLen; i++)
    {
        if (IsSkinPixel(pixel[i], m_pUIndex[pixel[i]], m_pVIndex[pixel[i]]))
        {
            pixel[i] = m_pBluredImage[i];
        }
        
        totalYValue += pixel[i];
        MakePixelBright(&pixel[i]);
        
    }
    
    
    
    int m_AverageValue = totalYValue / iLen;
    
    SetBrighteningValue(m_AverageValue, 10/*int brightnessPrecision*/);
    
    //IncreaseTemperatureOfFrame(pixel, m_nVideoHeight, m_nVideoWidth, 4);
    
}

bool CVideoBeautificationerTest::IsSkinPixel(unsigned char YPixel, unsigned char UPixel, unsigned char VPixel)
{
    if ((UPixel > 94 && UPixel < 126) && (VPixel > 134 && VPixel < 176))
    {
        return true;
    }
    
    return false;
}

void CVideoBeautificationerTest::StartBrightening(int iVideoHeight, int iVideoWidth, int nPrecision)
{
    m_nVideoHeight = iVideoHeight;
    m_nVideoWidth = iVideoWidth;
    m_nPreviousAddValueForBrightening = 0;
}


void CVideoBeautificationerTest::SetBrighteningValue(int m_AverageValue, int brightnessPrecision)
{
    if (m_AverageValue < 10)
    {
        m_nThresholdValue = 60;
    }
    else if (m_AverageValue < 15)
    {
        m_nThresholdValue = 65;
    }
    else if (m_AverageValue < 20)
    {
        m_nThresholdValue = 70;
    }
    else if (m_AverageValue < 30)
    {
        m_nThresholdValue = 85;
    }
    else if (m_AverageValue < 40)
    {
        m_nThresholdValue = 90;
    }
    else if (m_AverageValue < 50)
    {
        m_nThresholdValue = 95;
    }
    else if (m_AverageValue < 60)
    {
        m_nThresholdValue = 100;
    }
    else if (m_AverageValue < 70)
    {
        m_nThresholdValue = 110;
    }
    else if (m_AverageValue < 80)
    {
        m_nThresholdValue = 115;
    }
    else{
        m_nThresholdValue = 115;
    }
    
    m_nPreviousAddValueForBrightening = (m_nThresholdValue - m_AverageValue);
    m_nPreviousAddValueForBrightening = (m_nPreviousAddValueForBrightening >> 1);
    if (m_nPreviousAddValueForBrightening < 0)
        m_nPreviousAddValueForBrightening = 0;
    
    //m_nBrightnessPrecision = brightnessPrecision;
    m_nPreviousAddValueForBrightening += m_nBrightnessPrecision;
}

void CVideoBeautificationerTest::MakePixelBright(unsigned char *pixel)
{
    int iPixelValue = *pixel + m_nPreviousAddValueForBrightening;
    *pixel = getMin(iPixelValue, 255);
}

void CVideoBeautificationerTest::MakePixelBrightNew(unsigned char *pixel)
{
    *pixel = modifYUV[*pixel];//& 0xFF;
}

void CVideoBeautificationerTest::SetTemperatureThreshold(int nThreshold)
{
    
}

void CVideoBeautificationerTest::IncreaseTemperatureOfPixel(unsigned char *pixel)
{
    
}

void CVideoBeautificationerTest::StopBrightening()
{
    
}

void CVideoBeautificationerTest::SetBrightnessPrecision(int nPrecision)
{
    m_nBrightnessPrecision = nPrecision;
}

void CVideoBeautificationerTest::SetBlurScale(int nScale)
{
    m_nBlurScale = nScale;
}

void CVideoBeautificationerTest::MakeFrameBright(unsigned char *convertingData, int iVideoHeight, int iVideoWidth, int nPrecision)
{
    
}

void CVideoBeautificationerTest::IncreaseTemperatureOfFrame(unsigned char *convertingData, int iVideoHeight, int iVideoWidth,
                                                        unsigned char nThreshold)
{
    int startUIndex = iVideoHeight * iVideoWidth;
    int uLen = startUIndex + (startUIndex / 4);
    int vLen = startUIndex + (startUIndex / 2);
    for (int i = startUIndex; i <uLen; i++)
    {
        convertingData[i] = getMax(convertingData[i] - nThreshold, 0);
    }
    
    for (int i = uLen; i <vLen; i++)
    {
        convertingData[i] = getMin(convertingData[i] + nThreshold, 255);
    }
}

void CVideoBeautificationerTest::boxesForGauss(float sigma, int n)  // standard deviation, number of boxes
{
    float wIdeal = (float)sqrt((12 * sigma*sigma / n) + 1);  // Ideal averaging filter width
    int wl = (int)floor(wIdeal);
    if (wl % 2 == 0) wl--;
    int wu = wl + 2;
    
    float mIdeal = (12 * sigma*sigma - n*wl*wl - 4 * n*wl - 3 * n) / (-4 * wl - 4);
    int m = (int)floor(mIdeal + 0.5);
    
    // var sigmaActual = sqrt( (m*wl*wl + (n-m)*wu*wu - n)/12 );
    
    for (int i = 0; i<n; i++)
    {
        m_Sizes[i] = i<m ? wl : wu;
    }
    
    return;
}

void CVideoBeautificationerTest::GaussianBlur_4thApproach(unsigned char *scl, unsigned char *tcl, int h, int w, float r)
{
    boxBlur_4(scl, tcl, h, w, (m_Sizes[2] - 1) / 2);
    
}


void CVideoBeautificationerTest::boxBlur_4(unsigned char *scl, unsigned char *tcl, int h, int w, int r)
{
    boxBlurH_4(scl, tcl, h, w, r);
}

/*void CVideoBeautificationerTest::boxBlurH_4 (unsigned char *scl, unsigned char *tcl, int h, int w, int r)
 {
 int iarr = (r+r+1);
 for(int i=0; i<h; i++)
 {
 int ti = i*w, li = ti, ri = ti+r;
 int fv = scl[ti], lv = scl[ti+w-1], val = (r+1)*fv;
 
 for(int j=0; j<r; j++) val += scl[ti+j] ;
 for(int j=0  ; j<=r ; j++) {
 val += scl[ri++]  - fv;
 tcl[ti++] = ( unsigned char)(val/iarr) & 0xFF;
 }
 for(int j=r+1; j<w-r; j++) {
 val += scl[ri++]  - scl[li++] ;
 tcl[ti++] = (unsigned char)(val/iarr) & 0xFF;;
 }
 //for(int j=w-r; j<w  ; j++) { val += lv        - scl[li++];   tcl[ti++] = (unsigned char)floor(val*iarr + 0.5); }
 }
 }*/

void CVideoBeautificationerTest::boxBlurH_4(unsigned char *scl, unsigned char *tcl, int h, int w, int r)
{
    int iarr = (r + r + 1);
    for (int i = 0; i<h; i++)
    {
        int ti = m_Multiplication[i][w], li = ti, ri = ti + r;
        int fv = (scl[ti]), lv = (scl[ti + w - 1]), val = m_Multiplication[(r + 1)][fv];
        
        for (int j = 0; j<r; j++) val += (scl[ti + j]);
        for (int j = 0; j <= r; j++) { val += (scl[ri++]) - fv;   tcl[ti++] = (unsigned char)((unsigned char)(val / iarr) & 0xFF); }
        for (int j = r + 1; j<w - r; j++) {
            val += (scl[ri++]) - (scl[li++]);   tcl[ti++] = (unsigned char)((unsigned char)(val / iarr) & 0xFF);
        }
        for (int j = w - r; j<w; j++) {
            val += (scl[ri++]) - (scl[li++] );   tcl[ti++] = (unsigned char)((unsigned char)(val / iarr) & 0xFF);
        }//(unsigned char)floor(val*iarr + 0.5); }
    }
    //return tcl;
}

pair<int, int> CVideoBeautificationerTest::BeautificationFilter2(unsigned char *pBlurConvertingData, int iLen, int iHeight, int iWidth)
{
    //BeautyLocker lock(*m_pVideoBeautificationMutex);
    
    if (m_applyBeatification != 1)
    {
        pair<int, int> result = { 0, 0 };
        
        return result;
    }
    
    /*if (effectParam[0] != 0)m_sigma = effectParam[0];
     if (effectParam[1] != 0)m_radius = effectParam[1];
     if (effectParam[2] != 0)m_EffectValue = effectParam[2];*/
    
    //long long startSharpingTime = m_Tools.CurrentTimestamp();
    
#if defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR) || defined(__ANDROID__)
    //Do nothing
    //Not Needed Yet...
#else
    
    for (int i = 0; i <= iHeight; i++)
    {
        m_mean[i][0] = 0;
    }
    
    memset(m_mean, iWidth, 0);
    
    
    for (int i = 1, iw = 0; i <= iHeight; i++, iw += iWidth)
    {
        int tmp = 0;
        
        for (int j = 1; j <= iWidth; j++)
        {
            tmp += pBlurConvertingData[i * iWidth + j - 1];
            m_mean[i][j] = tmp + m_mean[i - 1][j];
            
            if (i > 2 && j > 2)
            {
                int indx = m_mean[i][j] - m_mean[i - 3][j] - m_mean[i][j - 3] + m_mean[i - 3][j - 3];
                
                pBlurConvertingData[iw + j - 2] = m_precSharpness[pBlurConvertingData[iw + j - 2]][indx];
            }
        }
    }
    
#endif
    
    //long long endSharpingTime = m_Tools.CurrentTimestamp();
    
    int ll = iHeight * iWidth;
    int totalYValue = 0;
    
    for (int i = 0; i < ll; i++)
    {
        totalYValue += pBlurConvertingData[i];
        
        if (pBlurConvertingData[i] >= luminaceHigh - m_nPreviousAddValueForBrightening)
            pBlurConvertingData[i] = luminaceHigh;
        else
            pBlurConvertingData[i] += m_nPreviousAddValueForBrightening;
        
        //pBlurConvertingData[i] = modifYUV[pBlurConvertingData[i]];
    }
    
    m_AvarageValue = totalYValue / ll;
    
    SetBrighteningValue(m_AvarageValue, 10);
    
    //long long endFilterTime = m_Tools.CurrentTimestamp();
    
    //LOGE("VideoBeautificcationer -->> sharpingTimeDiff = %lld, filterTimeDiff = %lld, totalTimeDiff =% lld", -(startSharpingTime - endSharpingTime), -(endSharpingTime - endFilterTime), -(startSharpingTime - endFilterTime));
    pair<int, int> result = { m_mean[iHeight][iWidth] / (iHeight*iWidth), m_variance[iHeight][iWidth] / (iHeight*iWidth) };
    return result;
}

pair<int, int> CVideoBeautificationerTest::BeautificationFilter(unsigned char *pBlurConvertingData, int iLen, int iHeight, int iWidth, bool doSharp)
{
    //BeautyLocker lock(*m_pVideoBeautificationMutex);
    
    if (m_applyBeatification != 1)
    {
        pair<int, int> result = { 0, 0 };
        
        return result;
    }
    
    /*if (effectParam[0] != 0)m_sigma = effectParam[0];
     if (effectParam[1] != 0)m_radius = effectParam[1];
     if (effectParam[2] != 0)m_EffectValue = effectParam[2];*/
    
    //long long startSharpingTime = m_Tools.CurrentTimestamp();
    
#if defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR) || defined(__ANDROID__)
    //Do nothing
    //Not Needed Yet...
#else
    
    for (int i = 0; i <= iHeight; i++)
    {
        m_mean[i][0] = 0;
    }
    
    memset(m_mean, iWidth, 0);
    
    if (doSharp)
    {
        for (int i = 1, iw = 0; i <= iHeight; i++, iw += iWidth)
        {
            int tmp = 0;
            
            for (int j = 1; j <= iWidth; j++)
            {
                tmp += pBlurConvertingData[i * iWidth + j - 1];
                m_mean[i][j] = tmp + m_mean[i - 1][j];
                
                if (i > 2 && j > 2)
                {
                    int indx = m_mean[i][j] - m_mean[i - 3][j] - m_mean[i][j - 3] + m_mean[i - 3][j - 3];
                    
                    pBlurConvertingData[iw + j - 2] = m_precSharpness[pBlurConvertingData[iw + j - 2]][indx];
                }
            }
        }
    }
    
#endif
    
    //long long endSharpingTime = m_Tools.CurrentTimestamp();
    
    for (int i = 0; i <= iHeight; i++)
    {
        m_mean[i][0] = 0;
        m_variance[i][0] = 0;
    }
    
    memset(m_mean, iWidth, 0);
    memset(m_variance, iWidth, 0);
    
    int tmp, tmp2;
    int totalYValue = 0;
    int yLen = iWidth * iHeight;
#if defined(__ANDROID__)
    /*int totalYValue = 0;*/
    //int yLen = iWidth * iHeight;
#endif
    
    for (int i = 1, iw = 0; i <= iHeight; i++, iw += iWidth)
    {
        tmp = 0, tmp2 = 0;
        m_mean[i][0] = 0;
        
        for (int j = 1; j <= iWidth; j++)
        {
            
#if defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR)
            
            //MakePixelBrightNew(&pBlurConvertingData[iw + j - 1]);
            
#elif defined(__ANDROID__)
            
            totalYValue += pBlurConvertingData[i];
            
            if (pBlurConvertingData[i] >= luminaceHigh - m_nPreviousAddValueForBrightening)
                pBlurConvertingData[i] = luminaceHigh;
            else
                pBlurConvertingData[i] += m_nPreviousAddValueForBrightening;
            
            //pBlurConvertingData[i] = modifYUV[pBlurConvertingData[i]];
            
#endif
            tmp += pBlurConvertingData[iw + j - 1];
            m_mean[i][j] = tmp + m_mean[i - 1][j];
            
            tmp2 += (pBlurConvertingData[iw + j - 1] * pBlurConvertingData[iw + j - 1]);
            m_variance[i][j] = tmp2 + m_variance[i - 1][j];
            
            //pBlurConvertingData[m_pUIndex[iw + j - 1]] -= 1;
            //pBlurConvertingData[m_pVIndex[iw + j - 1]] += 1;
        }
    }
    
    
    m_AvarageValue = totalYValue/yLen;
    
    SetBrighteningValue(m_AvarageValue, 10);
    
    int niHeight = iHeight - m_rr;
    int niWidth = iWidth - m_rr;
    int iw = m_radius * iWidth + m_radius;
    
    //m_sigma = 255 - m_mean[iHeight][iWidth] / (iHeight * iWidth);
    
    ////CLogPrinter_WriteLog(CLogPrinter::INFO, INSTENT_TEST_LOG_2, "sigma value " + m_Tools.getText(m_sigma));
    
    for (int hl = 0, hr = m_rr; hl < niHeight; hl++, hr++)
    {
        for (int wl = 0, wr = m_rr; wl < niWidth; wl++, wr++)
        {
            int miu = m_mean[hl][wl] + m_mean[hr][wr] - m_mean[hl][wr] - m_mean[hr][wl];
            int viu = m_variance[hl][wl] + m_variance[hr][wr] - m_variance[hl][wr] - m_variance[hr][wl];
            
            ////CLogPrinter_WriteLog(CLogPrinter::INFO, INSTENT_TEST_LOG_3, "viu " + m_Tools.getText(viu) + " alter " + m_Tools.getText(miu * miu / 121));
            
            //LOGE("viu %d miu %d\n",viu,miu/121*miu);
            
            
            double men = miu / m_pixels;
            double var = (viu - (miu * men)) / m_pixels;
            
            pBlurConvertingData[iw + wl] = min(255., max(0., (m_sigma * men + var * pBlurConvertingData[iw + wl]) / (var + m_sigma)));
            
        }
        iw += iWidth;
    }
    
    //long long endFilterTime = m_Tools.CurrentTimestamp();
    
    //LOGE("VideoBeautificcationer -->> sharpingTimeDiff = %lld, filterTimeDiff = %lld, totalTimeDiff =% lld", -(startSharpingTime - endSharpingTime), -(endSharpingTime - endFilterTime), -(startSharpingTime - endFilterTime));
    pair<int, int> result = { m_mean[iHeight][iWidth] / (iHeight*iWidth), m_variance[iHeight][iWidth] / (iHeight*iWidth) };
    return result;
}

bool CVideoBeautificationerTest::IsNotSkinPixel(unsigned char UPixel, unsigned char VPixel)
{
    return (UPixel <= 94 || UPixel >= 126 || VPixel <= 134 || VPixel >= 176);
}

pair<int, int> CVideoBeautificationerTest::BeautificationFilter(unsigned char *pBlurConvertingData, int iLen, int iHeight, int iWidth, int iNewHeight, int iNewWidth, bool doSharp)
{
    //BeautyLocker lock(*m_pVideoBeautificationMutex);
    
    if (m_applyBeatification != 1)
    {
        pair<int, int> result = { 0, 0 };
        
        return result;
    }
    
    /*if (effectParam[0] != 0)m_sigma = effectParam[0];
     if (effectParam[1] != 0)m_radius = effectParam[1];
     if (effectParam[2] != 0)m_EffectValue = effectParam[2];*/
    
    int startWidth = (iWidth - iNewWidth)/2 + 1;
    int endWidth = iWidth - startWidth + 1;
    
    int shiftDigit;
    
    if (m_nIsGreaterThen5s > 0)
    {
        shiftDigit = 2;
    }
    else
    {
        shiftDigit = 4;
    }
    
    //for (int i = 0; i <= iHeight; i++)
    //{
    //    m_mean[i][0] = 0;
    //}
    
    //memset(m_mean, iWidth, 0);
    /*
     for (int i = 1, iw = 0; i <= iHeight; i++, iw += iWidth)
     {
     for (int j = startWidth; j <= endWidth; j++)
     {
     m_mean[i][j] = pBlurConvertingData[iw + j - 1];
     }
     }
     */
    
#if defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR)
    
    if (doSharp)
        
#else
        
        if (doSharp)
            
#endif
            
        {
            for (int i = 1, iw = 0, iw2 = -iWidth; i <= iHeight; i++, iw += iWidth, iw2 += iWidth)
            {
                for (int j = startWidth; j <= endWidth; j++)
                {
                    m_mean[i][j] = pBlurConvertingData[iw + j - 1];
                    
                    if (i > 2 && j>1 && j<endWidth)
                    {
                        //if (pBlurConvertingData[m_pUIndex[iw2 + j - 1]] < 95 || pBlurConvertingData[m_pUIndex[iw2 + j - 1]] > 125 || pBlurConvertingData[m_pVIndex[iw2 + j - 2]] < 135 || pBlurConvertingData[m_pVIndex[iw2 + j - 2]] > 175)
#if defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR)
                        
                        pBlurConvertingData[iw2 + j - 1] = min(255, max(0, pBlurConvertingData[iw2 + j - 1] + (((m_mean[i - 1][j] << 2) - m_mean[i - 2][j] - m_mean[i][j] - m_mean[i - 1][j - 1] - m_mean[i - 1][j + 1]) >> shiftDigit)));
#elif defined(__ANDROID__)
                        pBlurConvertingData[iw2 + j - 1] = min(255, max(0, pBlurConvertingData[iw2 + j - 1] + (((m_mean[i - 1][j] << 2) - m_mean[i - 2][j] - m_mean[i][j] - m_mean[i - 1][j - 1] - m_mean[i - 1][j + 1]) >> 3)));
#else
                        pBlurConvertingData[iw2 + j - 1] = min(255, max(0, pBlurConvertingData[iw2 + j - 1] + (((m_mean[i - 1][j] << 2) - m_mean[i - 2][j] - m_mean[i][j] - m_mean[i - 1][j - 1] - m_mean[i - 1][j + 1]) >> 10)));
#endif
                    }
                }
            }
        }
    
    
    
    
    //for (int i = 0; i <= iHeight; i++)
    //{
    //    m_mean[i][startWidth - 1] = 0;
    //    m_variance[i][startWidth - 1] = 0;
    //}
    
    //memset(m_mean, iWidth, 0);
    //memset(m_variance, iWidth, 0);
    
    int tmp, tmp2;
    int totalYValue = 0;
    int yLen = iWidth * iHeight;
    
#if defined(__ANDROID__)
    /*int totalYValue = 0;*/
    //int yLen = iWidth * iHeight;
#endif
    
    for (int i = 1, iw = 0; i <= iHeight; i++, iw += iWidth)
    {
        tmp = 0, tmp2 = 0;
        m_mean[i][startWidth - 1] = 0;
        
        for (int j = startWidth; j <= endWidth; j++)
        {
            
#if defined(DESKTOP_C_SHARP)
            pBlurConvertingData[iw + j - 1] = max(0, pBlurConvertingData[iw + j - 1] - brightness_shift);
#endif
            
#if defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR)
            
            //MakePixelBrightNew(&pBlurConvertingData[iw + j - 1]);
            
            pBlurConvertingData[iw + j - 1] = m_ucpreBrightness[pBlurConvertingData[iw + j - 1]];
            
#else
            
            //if (pBlurConvertingData[iw + j - 1] >= luminaceHigh - m_nPreviousAddValueForBrightening)
            //    pBlurConvertingData[iw + j - 1] = luminaceHigh;
            //else
            //    pBlurConvertingData[iw + j - 1] += m_nPreviousAddValueForBrightening;
            
            //pBlurConvertingData[iw + j - 1] = modifYUV[pBlurConvertingData[iw + j - 1]];
            
            
            pBlurConvertingData[iw + j - 1] = m_ucpreBrightness[pBlurConvertingData[iw + j - 1]];
            
#endif
            
            
            
            totalYValue += pBlurConvertingData[iw + j - 1];
            
            
            tmp += pBlurConvertingData[iw + j - 1];
            m_mean[i][j] = tmp + m_mean[i - 1][j];
            
            tmp2 += (pBlurConvertingData[iw + j - 1] * pBlurConvertingData[iw + j - 1]);
            m_variance[i][j] = tmp2 + m_variance[i - 1][j];
            
#if defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR)
            
            pBlurConvertingData[m_pUIndex[iw + j - 1]] += 1;
            pBlurConvertingData[m_pVIndex[iw + j - 1]] -= 1;
#endif
            
        }
    }
    
    m_AvarageValue = totalYValue/yLen;
    
#if defined(__ANDROID__)
    
    if (m_AvarageValue < 50)
    {
        m_sigma = m_Step3Sigma;
        m_sigmaDigit = m_Step3SigmaDigit;
    }
    else if (m_AvarageValue < 100)
    {
        m_sigma = m_Step2Sigma;
        m_sigmaDigit = m_Step2SigmaDigit;
    }
    else
    {
        m_sigma = m_Step1Sigma;
        m_sigmaDigit = m_Step1SigmaDigit;
    }
    
#elif defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR)
    
    /*
     if (m_AvarageValue < 50)
     {
     m_sigma = m_Step2Sigma;
     m_sigmaDigit = m_Step2SigmaDigit;
     }
     else
     {
     if (m_nIsGreaterThen5s > 0)
     {
     m_sigma = m_Step0Sigma;
     m_sigmaDigit = m_Step0SigmaDigit;
     }
     else
     {
     m_sigma = m_Step1Sigma;
     m_sigmaDigit = m_Step1SigmaDigit;
     }
     }
     */
    
    if (m_nIsGreaterThen5s > 0)
    {
        
        m_sigma = (int)((16 * m_AvarageValue) / 25);
        
        m_sigma++;
        
        if(m_sigma > 128)
            m_sigma = 128;
        if(m_sigma < 32)
            m_sigma = 32;
        
        m_sigma-=5;
        
        /*
         if (m_AvarageValue < 50)
         {
         m_sigma = m_Step2Sigma;
         m_sigmaDigit = m_Step2SigmaDigit;
         }
         else if (m_AvarageValue < 100)
         {
         m_sigma = m_Step1Sigma;
         m_sigmaDigit = m_Step1SigmaDigit;
         }
         else
         {
         m_sigma = m_Step0Sigma;
         m_sigmaDigit = m_Step0SigmaDigit;
         }
         */
    }
    else
    {
        m_sigma = (int)((16 * m_AvarageValue) / 50);
        
        m_sigma++;
        
        if(m_sigma > 64)
            m_sigma = 64;
        if(m_sigma < 16)
            m_sigma = 16;
        
        
        /*
         if (m_AvarageValue < 50)
         {
         m_sigma = m_Step3Sigma;
         m_sigmaDigit = m_Step3SigmaDigit;
         }
         else if (m_AvarageValue < 100)
         {
         m_sigma = m_Step2Sigma;
         m_sigmaDigit = m_Step2SigmaDigit;
         }
         else
         {
         m_sigma = m_Step1Sigma;
         m_sigmaDigit = m_Step1SigmaDigit;
         }
         */
    }
    
#endif
    
    //SetBrighteningValue(m_AvarageValue, 10);
    
    int niHeight = iHeight - m_rr;
    int niWidth = endWidth - m_rr;
    int iw = m_radius * iWidth + m_radius;
    double sigmaPix = m_sigma * m_pixels;
    
    //m_sigma = 255 - m_mean[iHeight][iWidth] / (iHeight * iWidth);
    
    ////CLogPrinter_WriteLog(CLogPrinter::INFO, INSTENT_TEST_LOG_2, "sigma value " + m_Tools.getText(m_sigma));
    
    for (int hl = 0, hr = m_rr; hl < niHeight; hl++, hr++)
    {
        for (int wl = startWidth, wr = m_rr + startWidth; wl < niWidth; wl++, wr++)
        {
            int miu = m_mean[hl][wl] + m_mean[hr][wr] - m_mean[hl][wr] - m_mean[hr][wl];
            int viu = m_variance[hl][wl] + m_variance[hr][wr] - m_variance[hl][wr] - m_variance[hr][wl];
            
            //double men = miu / m_pixels;
            //double var = (viu - (miu * miu) / m_pixels) / m_pixels;
            //var = abs(var);
            
            //m_tmpPixel[iw + wl] = (m_sigma * men + var * pBlurConvertingData[iw + wl]) / (var + m_sigma);
            
            double var = viu - (miu * miu / m_pixels);
            
#if defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR)
            
            pBlurConvertingData[iw + wl] = min(255., max(0., ((miu * m_sigma) + var * pBlurConvertingData[iw + wl]) / (var + sigmaPix)));
            
#else
            
            pBlurConvertingData[iw + wl] = min(255., max(0., ((miu << m_sigmaDigit) + var * pBlurConvertingData[iw + wl]) / (var + sigmaPix)));
#endif
            
        }
        
        iw += iWidth;
    }
    
    //long long endFilterTime = m_Tools.CurrentTimestamp();
    
    //LOGE("VideoBeautificcationer -->> sharpingTimeDiff = %lld, filterTimeDiff = %lld, totalTimeDiff =% lld", -(startSharpingTime - endSharpingTime), -(endSharpingTime - endFilterTime), -(startSharpingTime - endFilterTime));
    
    pair<int, int> result = { m_mean[iHeight][iWidth] / (iHeight*iWidth), m_variance[iHeight][iWidth] / (iHeight*iWidth) };
    
    return result;
}

pair<int, int> CVideoBeautificationerTest::BeautificationFilterNew(unsigned char *pBlurConvertingData, int iLen, int iHeight, int iWidth, int iNewHeight, int iNewWidth, bool doSharp)
{
    //BeautyLocker lock(*m_pVideoBeautificationMutex);
    
    if (m_applyBeatification != 1)
    {
        pair<int, int> result = { 0, 0 };
        
        return result;
    }
    
    /*if (effectParam[0] != 0)m_sigma = effectParam[0];
     if (effectParam[1] != 0)m_radius = effectParam[1];
     if (effectParam[2] != 0)m_EffectValue = effectParam[2];*/
    
    int startWidth = (iWidth - iNewWidth) / 2 + 1;
    int endWidth = iWidth - startWidth + 1;
    
    int shiftDigit;
    
    if (m_nIsGreaterThen5s > 0)
    {
        shiftDigit = 3;
    }
    else
    {
        shiftDigit = 4;
    }
    
    //for (int i = 0; i <= iHeight; i++)
    //{
    //    m_mean[i][0] = 0;
    //}
    
    //memset(m_mean, iWidth, 0);
    /*
     for (int i = 1, iw = 0; i <= iHeight; i++, iw += iWidth)
     {
     for (int j = startWidth; j <= endWidth; j++)
     {
     m_mean[i][j] = pBlurConvertingData[iw + j - 1];
     }
     }
     */
    
#if defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR)
    
    if (doSharp)
        
#else
        
        if (doSharp)
            
#endif
            
        {
            for (int i = 1, iw = 0, iw2 = -iWidth; i <= iHeight; i++, iw += iWidth, iw2 += iWidth)
            {
                for (int j = startWidth; j <= endWidth; j++)
                {
                    m_mean[i][j] = pBlurConvertingData[iw + j - 1];
                    
                    if (i > 2 && j>1 && j<endWidth)
                    {
                        //if (pBlurConvertingData[m_pUIndex[iw2 + j - 1]] < 95 || pBlurConvertingData[m_pUIndex[iw2 + j - 1]] > 125 || pBlurConvertingData[m_pVIndex[iw2 + j - 2]] < 135 || pBlurConvertingData[m_pVIndex[iw2 + j - 2]] > 175)
#if defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR)
                        
                        pBlurConvertingData[iw2 + j - 1] = min(255, max(0, pBlurConvertingData[iw2 + j - 1] + (((m_mean[i - 1][j] << 2) - m_mean[i - 2][j] - m_mean[i][j] - m_mean[i - 1][j - 1] - m_mean[i - 1][j + 1]) >> shiftDigit)));
#elif defined(__ANDROID__)
                        //if (pBlurConvertingData[m_pUIndex[iw2 + j - 1]] < 95 || pBlurConvertingData[m_pUIndex[iw2 + j - 1]] > 125 || pBlurConvertingData[m_pVIndex[iw2 + j - 2]] < 135 || pBlurConvertingData[m_pVIndex[iw2 + j - 2]] > 175)
                        //        pBlurConvertingData[iw2 + j - 1] = min(255, max(0, pBlurConvertingData[iw2 + j - 1] + (((m_mean[i - 1][j] << 2) - m_mean[i - 2][j] - m_mean[i][j] - m_mean[i - 1][j - 1] - m_mean[i - 1][j + 1]) >> 2)));
                        //else
                        pBlurConvertingData[iw2 + j - 1] = min(255, max(0, pBlurConvertingData[iw2 + j - 1] + (((m_mean[i - 1][j] << 2) - m_mean[i - 2][j] - m_mean[i][j] - m_mean[i - 1][j - 1] - m_mean[i - 1][j + 1]) >> 3)));
#else
                        pBlurConvertingData[iw2 + j - 1] = min(255, max(0, pBlurConvertingData[iw2 + j - 1] + (((m_mean[i - 1][j] << 2) - m_mean[i - 2][j] - m_mean[i][j] - m_mean[i - 1][j - 1] - m_mean[i - 1][j + 1]) >> 10)));
#endif
                    }
                }
            }
        }
    
    
    
    
    //for (int i = 0; i <= iHeight; i++)
    //{
    //    m_mean[i][startWidth - 1] = 0;
    //    m_variance[i][startWidth - 1] = 0;
    //}
    
    //memset(m_mean, iWidth, 0);
    //memset(m_variance, iWidth, 0);
    
    int tmp, tmp2;
    int totalYValue = 0;
    int yLen = iWidth * iHeight;
    
#if defined(__ANDROID__)
    /*int totalYValue = 0;*/
    //int yLen = iWidth * iHeight;
#endif
    
    for (int i = 1, iw = 0; i <= iHeight; i++, iw += iWidth)
    {
        tmp = 0, tmp2 = 0;
        m_mean[i][startWidth - 1] = 0;
        
        for (int j = startWidth; j <= endWidth; j++)
        {
            
#if defined(DESKTOP_C_SHARP)
            pBlurConvertingData[iw + j - 1] = max(0, pBlurConvertingData[iw + j - 1] - brightness_shift);
#endif
            
#if defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR)
            
            //MakePixelBrightNew(&pBlurConvertingData[iw + j - 1]);
            
            pBlurConvertingData[iw + j - 1] = m_ucpreBrightnessNew[pBlurConvertingData[iw + j - 1]];
            
#else
            
            //if (pBlurConvertingData[iw + j - 1] >= luminaceHigh - m_nPreviousAddValueForBrightening)
            //    pBlurConvertingData[iw + j - 1] = luminaceHigh;
            //else
            //    pBlurConvertingData[iw + j - 1] += m_nPreviousAddValueForBrightening;
            
            //pBlurConvertingData[iw + j - 1] = modifYUV[pBlurConvertingData[iw + j - 1]];
            
            
            pBlurConvertingData[iw + j - 1] = m_ucpreBrightnessNew[pBlurConvertingData[iw + j - 1]];
            
#endif
            
            
            
            totalYValue += pBlurConvertingData[iw + j - 1];
            
            
            tmp += pBlurConvertingData[iw + j - 1];
            m_mean[i][j] = tmp + m_mean[i - 1][j];
            
            tmp2 += (pBlurConvertingData[iw + j - 1] * pBlurConvertingData[iw + j - 1]);
            m_variance[i][j] = tmp2 + m_variance[i - 1][j];
            /*
             //#if defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR)
             if (pBlurConvertingData[m_pUIndex[iw + j - 1]] < 95 || pBlurConvertingData[m_pUIndex[iw + j - 1]] > 125 || pBlurConvertingData[m_pVIndex[iw + j - 2]] < 135 || pBlurConvertingData[m_pVIndex[iw + j - 2]] > 175)
             {
             pBlurConvertingData[m_pUIndex[iw + j - 1]] += 0;
             pBlurConvertingData[m_pVIndex[iw + j - 1]] -= 0;
             }
             else
             {
             pBlurConvertingData[m_pUIndex[iw + j - 1]] += 1;
             pBlurConvertingData[m_pVIndex[iw + j - 1]] -= 1;
             }
             //#endif
             */
            
        }
    }
    
    m_AvarageValue = totalYValue / yLen;
    
    /*#if defined(__ANDROID__)
     
     if (m_AvarageValue < 50)
     {
     m_sigma = m_Step3Sigma;
     m_sigmaDigit = m_Step3SigmaDigit;
     }
     else if (m_AvarageValue < 100)
     {
     m_sigma = m_Step2Sigma;
     m_sigmaDigit = m_Step2SigmaDigit;
     }
     else
     {
     m_sigma = m_Step1Sigma;
     m_sigmaDigit = m_Step1SigmaDigit;
     }*/
    
    /*#elif defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR)*/
    
    /*
     if (m_AvarageValue < 50)
     {
     m_sigma = m_Step2Sigma;
     m_sigmaDigit = m_Step2SigmaDigit;
     }
     else
     {
     if (m_nIsGreaterThen5s > 0)
     {
     m_sigma = m_Step0Sigma;
     m_sigmaDigit = m_Step0SigmaDigit;
     }
     else
     {
     m_sigma = m_Step1Sigma;
     m_sigmaDigit = m_Step1SigmaDigit;
     }
     }
     */
    
    //if (m_nIsGreaterThen5s > 0)
    //{
    
    m_sigma = (int)((16 * m_AvarageValue) / 25);
    
    m_sigma++;
    
    if (m_sigma > 128)
        m_sigma = 128;
    if (m_sigma < 32)
        m_sigma = 32;
    
#if defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR)
    
    m_sigma -= 5;
    int ns_sigma = m_sigma - 25;
    if (ns_sigma <= 0)ns_sigma = 1;
    
#else
    
    m_sigma -= 10;
    int ns_sigma = m_sigma - 20;
    if (ns_sigma <= 0)ns_sigma = 1;
    
#endif
    
    /*
     if (m_AvarageValue < 50)
     {
     m_sigma = m_Step2Sigma;
     m_sigmaDigit = m_Step2SigmaDigit;
     }
     else if (m_AvarageValue < 100)
     {
     m_sigma = m_Step1Sigma;
     m_sigmaDigit = m_Step1SigmaDigit;
     }
     else
     {
     m_sigma = m_Step0Sigma;
     m_sigmaDigit = m_Step0SigmaDigit;
     }
     */
    //}
    /*else
     {
     m_sigma = (int)((16 * m_AvarageValue) / 50);
     
     m_sigma++;
     
     if(m_sigma > 64)
     m_sigma = 64;
     if(m_sigma < 16)
     m_sigma = 16;
     
     
     /*
     if (m_AvarageValue < 50)
     {
     m_sigma = m_Step3Sigma;
     m_sigmaDigit = m_Step3SigmaDigit;
     }
     else if (m_AvarageValue < 100)
     {
     m_sigma = m_Step2Sigma;
     m_sigmaDigit = m_Step2SigmaDigit;
     }
     else
     {
     m_sigma = m_Step1Sigma;
     m_sigmaDigit = m_Step1SigmaDigit;
     }
     */
    //}
    
    //#endif
    
    //SetBrighteningValue(m_AvarageValue, 10);
    
    int niHeight = iHeight - m_rr;
    int niWidth = endWidth - m_rr;
    int iw = m_radius * iWidth + m_radius;
    double sigmaPix = m_sigma * m_pixels;
    double ns_sigmaPix = ns_sigma * m_pixels;
    
    //m_sigma = 255 - m_mean[iHeight][iWidth] / (iHeight * iWidth);
    
    ////CLogPrinter_WriteLog(CLogPrinter::INFO, INSTENT_TEST_LOG_2, "sigma value " + m_Tools.getText(m_sigma));
    
    for (int hl = 0, hr = m_rr; hl < niHeight; hl++, hr++)
    {
        for (int wl = startWidth, wr = m_rr + startWidth; wl < niWidth; wl++, wr++)
        {
            int miu = m_mean[hl][wl] + m_mean[hr][wr] - m_mean[hl][wr] - m_mean[hr][wl];
            int viu = m_variance[hl][wl] + m_variance[hr][wr] - m_variance[hl][wr] - m_variance[hr][wl];
            
            //double men = miu / m_pixels;
            //double var = (viu - (miu * miu) / m_pixels) / m_pixels;
            //var = abs(var);
            
            //m_tmpPixel[iw + wl] = (m_sigma * men + var * pBlurConvertingData[iw + wl]) / (var + m_sigma);
            
            double var = viu - (miu * miu / m_pixels);
            
            //#if defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR)
            if (pBlurConvertingData[m_pUIndex[iw + wl]] < 95 || pBlurConvertingData[m_pUIndex[iw + wl]] > 125 || pBlurConvertingData[m_pVIndex[iw + wl]] < 135 || pBlurConvertingData[m_pVIndex[iw + wl]] > 175)
                pBlurConvertingData[iw + wl] = min(255., max(0., ((miu * ns_sigma) + var * pBlurConvertingData[iw + wl]) / (var + ns_sigmaPix)));
            else
                pBlurConvertingData[iw + wl] = min(255., max(0., ((miu * m_sigma) + var * pBlurConvertingData[iw + wl]) / (var + sigmaPix)));
            
            //#else
            
            //pBlurConvertingData[iw + wl] = min(255., max(0., ((miu << m_sigmaDigit) + var * pBlurConvertingData[iw + wl]) / (var + sigmaPix)));
            //#endif
            
        }
        
        iw += iWidth;
    }
    
    //long long endFilterTime = m_Tools.CurrentTimestamp();
    
    //LOGE("VideoBeautificcationer -->> sharpingTimeDiff = %lld, filterTimeDiff = %lld, totalTimeDiff =% lld", -(startSharpingTime - endSharpingTime), -(endSharpingTime - endFilterTime), -(startSharpingTime - endFilterTime));
    
    pair<int, int> result = { m_mean[iHeight][iWidth] / (iHeight*iWidth), m_variance[iHeight][iWidth] / (iHeight*iWidth) };
    
    return result;
}

pair<int, int> CVideoBeautificationerTest::BeautificationFilterForChannel(unsigned char *pBlurConvertingData, int iLen, int iHeight, int iWidth, int iNewHeight, int iNewWidth, bool doSharp)
{
    //BeautyLocker lock(*m_pVideoBeautificationMutex);
    
    if (m_applyBeatification != 1)
    {
        pair<int, int> result = { 0, 0 };
        
        return result;
    }
    
    /*if (effectParam[0] != 0)m_sigma = effectParam[0];
     if (effectParam[1] != 0)m_radius = effectParam[1];
     if (effectParam[2] != 0)m_EffectValue = effectParam[2];*/
    
    int startWidth = (iWidth - iNewWidth) / 2 + 1;
    int endWidth = iWidth - startWidth + 1;
    
    int shiftDigit;
    
    if (m_nIsGreaterThen5s > 0)
    {
        shiftDigit = 3;
    }
    else
    {
        shiftDigit = 4;
    }
    
    
    if (m_nChannelType == CHANNEL_TYPE_TV)
    {
        m_nChannelSharpAmountDigit = 2;
    }
    else
    {
        m_nChannelSharpAmountDigit = 3;
    }
    
    //CLogPrinter_LOG(CHANNEL_ENHANCE_LOG, "CVideoBeautificationerTest::BeautificationFilterForChannel m_nChannelType %d m_nChannelSharpAmountDigit %d", m_nChannelType, m_nChannelSharpAmountDigit);
    
    
#if defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR)
    
    if (doSharp)
        
#else
        
        if (doSharp)
            
#endif
            
        {
            for (int i = 1, iw = 0, iw2 = -iWidth; i <= iHeight; i++, iw += iWidth, iw2 += iWidth)
            {
                for (int j = startWidth; j <= endWidth; j++)
                {
                    m_mean[i][j] = pBlurConvertingData[iw + j - 1];
                    
                    if (i > 2 && j>1 && j<endWidth)
                    {
                        pBlurConvertingData[iw2 + j - 1] = min(255, max(0, pBlurConvertingData[iw2 + j - 1] + (((m_mean[i - 1][j] << 2) - m_mean[i - 2][j] - m_mean[i][j] - m_mean[i - 1][j - 1] - m_mean[i - 1][j + 1]) >> m_nChannelSharpAmountDigit)));
                    }
                }
            }
        }
    
    pair<int, int> result1 = { 1, 1 };
    
    return result1;
    
    
    //for (int i = 0; i <= iHeight; i++)
    //{
    //    m_mean[i][startWidth - 1] = 0;
    //    m_variance[i][startWidth - 1] = 0;
    //}
    
    //memset(m_mean, iWidth, 0);
    //memset(m_variance, iWidth, 0);
    
    int tmp, tmp2;
    int totalYValue = 0;
    int yLen = iWidth * iHeight;
    
#if defined(__ANDROID__)
    /*int totalYValue = 0;*/
    //int yLen = iWidth * iHeight;
#endif
    
    for (int i = 1, iw = 0; i <= iHeight; i++, iw += iWidth)
    {
        tmp = 0, tmp2 = 0;
        m_mean[i][startWidth - 1] = 0;
        
        for (int j = startWidth; j <= endWidth; j++)
        {
            
#if defined(DESKTOP_C_SHARP)
            pBlurConvertingData[iw + j - 1] = max(0, pBlurConvertingData[iw + j - 1] - brightness_shift);
#endif
            
#if defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR)
            
            //MakePixelBrightNew(&pBlurConvertingData[iw + j - 1]);
            
            pBlurConvertingData[iw + j - 1] = m_ucpreBrightnessNew[pBlurConvertingData[iw + j - 1]];
            
#else
            
            //if (pBlurConvertingData[iw + j - 1] >= luminaceHigh - m_nPreviousAddValueForBrightening)
            //    pBlurConvertingData[iw + j - 1] = luminaceHigh;
            //else
            //    pBlurConvertingData[iw + j - 1] += m_nPreviousAddValueForBrightening;
            
            //pBlurConvertingData[iw + j - 1] = modifYUV[pBlurConvertingData[iw + j - 1]];
            
            
            pBlurConvertingData[iw + j - 1] = m_ucpreBrightnessNew[pBlurConvertingData[iw + j - 1]];
            
#endif
            
            
            
            totalYValue += pBlurConvertingData[iw + j - 1];
            
            
            tmp += pBlurConvertingData[iw + j - 1];
            m_mean[i][j] = tmp + m_mean[i - 1][j];
            
            tmp2 += (pBlurConvertingData[iw + j - 1] * pBlurConvertingData[iw + j - 1]);
            m_variance[i][j] = tmp2 + m_variance[i - 1][j];
            /*
             //#if defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR)
             if (pBlurConvertingData[m_pUIndex[iw + j - 1]] < 95 || pBlurConvertingData[m_pUIndex[iw + j - 1]] > 125 || pBlurConvertingData[m_pVIndex[iw + j - 2]] < 135 || pBlurConvertingData[m_pVIndex[iw + j - 2]] > 175)
             {
             pBlurConvertingData[m_pUIndex[iw + j - 1]] += 0;
             pBlurConvertingData[m_pVIndex[iw + j - 1]] -= 0;
             }
             else
             {
             pBlurConvertingData[m_pUIndex[iw + j - 1]] += 1;
             pBlurConvertingData[m_pVIndex[iw + j - 1]] -= 1;
             }
             //#endif
             */
            
        }
    }
    
    m_AvarageValue = totalYValue / yLen;
    
    /*#if defined(__ANDROID__)
     
     if (m_AvarageValue < 50)
     {
     m_sigma = m_Step3Sigma;
     m_sigmaDigit = m_Step3SigmaDigit;
     }
     else if (m_AvarageValue < 100)
     {
     m_sigma = m_Step2Sigma;
     m_sigmaDigit = m_Step2SigmaDigit;
     }
     else
     {
     m_sigma = m_Step1Sigma;
     m_sigmaDigit = m_Step1SigmaDigit;
     }*/
    
    /*#elif defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR)*/
    
    /*
     if (m_AvarageValue < 50)
     {
     m_sigma = m_Step2Sigma;
     m_sigmaDigit = m_Step2SigmaDigit;
     }
     else
     {
     if (m_nIsGreaterThen5s > 0)
     {
     m_sigma = m_Step0Sigma;
     m_sigmaDigit = m_Step0SigmaDigit;
     }
     else
     {
     m_sigma = m_Step1Sigma;
     m_sigmaDigit = m_Step1SigmaDigit;
     }
     }
     */
    
    //if (m_nIsGreaterThen5s > 0)
    //{
    
    m_sigma = (int)((16 * m_AvarageValue) / 25);
    
    m_sigma++;
    
    if (m_sigma > 128)
        m_sigma = 128;
    if (m_sigma < 32)
        m_sigma = 32;
    
#if defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR)
    
    m_sigma -= 5;
    int ns_sigma = m_sigma - 25;
    if (ns_sigma <= 0)ns_sigma = 1;
    
#else
    
    m_sigma -= 10;
    int ns_sigma = m_sigma - 20;
    if (ns_sigma <= 0)ns_sigma = 1;
    
#endif
    
    /*
     if (m_AvarageValue < 50)
     {
     m_sigma = m_Step2Sigma;
     m_sigmaDigit = m_Step2SigmaDigit;
     }
     else if (m_AvarageValue < 100)
     {
     m_sigma = m_Step1Sigma;
     m_sigmaDigit = m_Step1SigmaDigit;
     }
     else
     {
     m_sigma = m_Step0Sigma;
     m_sigmaDigit = m_Step0SigmaDigit;
     }
     */
    //}
    /*else
     {
     m_sigma = (int)((16 * m_AvarageValue) / 50);
     
     m_sigma++;
     
     if(m_sigma > 64)
     m_sigma = 64;
     if(m_sigma < 16)
     m_sigma = 16;
     
     
     /*
     if (m_AvarageValue < 50)
     {
     m_sigma = m_Step3Sigma;
     m_sigmaDigit = m_Step3SigmaDigit;
     }
     else if (m_AvarageValue < 100)
     {
     m_sigma = m_Step2Sigma;
     m_sigmaDigit = m_Step2SigmaDigit;
     }
     else
     {
     m_sigma = m_Step1Sigma;
     m_sigmaDigit = m_Step1SigmaDigit;
     }
     */
    //}
    
    //#endif
    
    //SetBrighteningValue(m_AvarageValue, 10);
    
    int niHeight = iHeight - m_rr;
    int niWidth = endWidth - m_rr;
    int iw = m_radius * iWidth + m_radius;
    double sigmaPix = m_sigma * m_pixels;
    double ns_sigmaPix = ns_sigma * m_pixels;
    
    //m_sigma = 255 - m_mean[iHeight][iWidth] / (iHeight * iWidth);
    
    ////CLogPrinter_WriteLog(CLogPrinter::INFO, INSTENT_TEST_LOG_2, "sigma value " + m_Tools.getText(m_sigma));
    
    for (int hl = 0, hr = m_rr; hl < niHeight; hl++, hr++)
    {
        for (int wl = startWidth, wr = m_rr + startWidth; wl < niWidth; wl++, wr++)
        {
            int miu = m_mean[hl][wl] + m_mean[hr][wr] - m_mean[hl][wr] - m_mean[hr][wl];
            int viu = m_variance[hl][wl] + m_variance[hr][wr] - m_variance[hl][wr] - m_variance[hr][wl];
            
            //double men = miu / m_pixels;
            //double var = (viu - (miu * miu) / m_pixels) / m_pixels;
            //var = abs(var);
            
            //m_tmpPixel[iw + wl] = (m_sigma * men + var * pBlurConvertingData[iw + wl]) / (var + m_sigma);
            
            double var = viu - (miu * miu / m_pixels);
            
            //#if defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR)
            if (pBlurConvertingData[m_pUIndex[iw + wl]] < 95 || pBlurConvertingData[m_pUIndex[iw + wl]] > 125 || pBlurConvertingData[m_pVIndex[iw + wl]] < 135 || pBlurConvertingData[m_pVIndex[iw + wl]] > 175)
                pBlurConvertingData[iw + wl] = min(255., max(0., ((miu * ns_sigma) + var * pBlurConvertingData[iw + wl]) / (var + ns_sigmaPix)));
            else
                pBlurConvertingData[iw + wl] = min(255., max(0., ((miu * m_sigma) + var * pBlurConvertingData[iw + wl]) / (var + sigmaPix)));
            
            //#else
            
            //pBlurConvertingData[iw + wl] = min(255., max(0., ((miu << m_sigmaDigit) + var * pBlurConvertingData[iw + wl]) / (var + sigmaPix)));
            //#endif
            
        }
        
        iw += iWidth;
    }
    
    //long long endFilterTime = m_Tools.CurrentTimestamp();
    
    //LOGE("VideoBeautificcationer -->> sharpingTimeDiff = %lld, filterTimeDiff = %lld, totalTimeDiff =% lld", -(startSharpingTime - endSharpingTime), -(endSharpingTime - endFilterTime), -(startSharpingTime - endFilterTime));
    
    pair<int, int> result = { m_mean[iHeight][iWidth] / (iHeight*iWidth), m_variance[iHeight][iWidth] / (iHeight*iWidth) };
    
    return result;
}

void CVideoBeautificationerTest::setParameters(int *param)
{
    if (param[0] != 0)
    {
        m_sigma = param[0];
        m_sigmaDigit = log(m_sigma) / log(2);
    }
    if (param[1] != 0) brightness_shift = param[1];
    
    m_applyBeatification = param[2];
    
    m_rr = (m_radius << 1) + 1;
    
    m_pixels = m_rr * m_rr;
    
    //m_applyBeatification = param[3];
    
    //m_applyBeatification = 1;
    
    return;
}

int CVideoBeautificationerTest::TestVideoEffect(int *param, int size)
{
    //BeautyLocker lock(*m_pVideoBeautificationMutex);
    
    /*if (effectParam[0] != 0)m_sigma = effectParam[0];
     
     if (effectParam[1] != 0)m_radius = effectParam[1];
     
     if (effectParam[2] != 0)m_EffectValue = effectParam[2];*/
    
    memcpy(m_VideoEffectParam, param, size * sizeof(int));
    
    //BrightnessCalculation(m_VideoEffectParam[4], m_VideoEffectParam[5], m_VideoEffectParam[6], m_VideoEffectParam[7]);
    
    setParameters(m_VideoEffectParam);
    
    return 1;
}

void CVideoBeautificationerTest::BrightnessCalculation(int startPix, int endPix, int midPix, int highestChange)
{
    int firstDif = midPix - startPix;
    int secondDif = endPix - midPix;
    
    for (int i = 0; i < 256; i++)
    {
        m_preBrightness[i] = i;
        
        if (i >= startPix && i <= midPix)
        {
            m_preBrightness[i] += (i - startPix) * highestChange / firstDif;
        }
        else if (i >= midPix && i <= endPix)
        {
            m_preBrightness[i] += (endPix - i) * highestChange / secondDif;
        }
    }
    
    return;
}

#if defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR)

int CVideoBeautificationerTest::isGreaterThanIphone5s()
{
    string sDeviceInfo = getDeviceModel();
    //CLogPrinter::Log("TheKing--> Here Devicetype ");
    
    if(sDeviceInfo=="iPhone7,1" ||
       sDeviceInfo=="iPhone7,2" ||
       sDeviceInfo=="iPhone8,1" ||
       sDeviceInfo=="iPhone8,2" ||
       sDeviceInfo=="iPhone8,4" ||
       sDeviceInfo=="iPhone9,1" ||
       sDeviceInfo=="iPhone9,2" ||
       sDeviceInfo=="iPhone9,3" ||
       sDeviceInfo=="iPhone9,4")
    {
        return 1;
    }
    else if(sDeviceInfo=="iPhone1,1" ||
            sDeviceInfo=="iPhone1,2" ||
            sDeviceInfo=="iPhone2,1" ||
            sDeviceInfo=="iPhone3,1" ||
            sDeviceInfo=="iPhone3,3" ||
            sDeviceInfo=="iPhone4,1" ||
            sDeviceInfo=="iPhone5,1" ||
            sDeviceInfo=="iPhone5,2" ||
            sDeviceInfo=="iPhone5,3" ||
            sDeviceInfo=="iPhone5,4" ||
            sDeviceInfo=="iPhone6,1" ||
            sDeviceInfo=="iPhone6,2")
    {
        return 0;
    }
    else
    {
        return -1;
    }
    
}


std::string  CVideoBeautificationerTest::getDeviceModel()
{
#if defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR)
    /*
     //Simultor
     @"i386"      on 32-bit Simulator
     @"x86_64"    on 64-bit Simulator
     
     //iPhone
     @"iPhone1,1" on iPhone
     @"iPhone1,2" on iPhone 3G
     @"iPhone2,1" on iPhone 3GS
     @"iPhone3,1" on iPhone 4 (GSM)
     @"iPhone3,3" on iPhone 4 (CDMA/Verizon/Sprint)
     @"iPhone4,1" on iPhone 4S
     @"iPhone5,1" on iPhone 5 (model A1428, AT&T/Canada)
     @"iPhone5,2" on iPhone 5 (model A1429, everything else)
     @"iPhone5,3" on iPhone 5c (model A1456, A1532 | GSM)
     @"iPhone5,4" on iPhone 5c (model A1507, A1516, A1526 (China), A1529 | Global)
     @"iPhone6,1" on iPhone 5s (model A1433, A1533 | GSM)
     @"iPhone6,2" on iPhone 5s (model A1457, A1518, A1528 (China), A1530 | Global)
     @"iPhone7,1" on iPhone 6 Plus
     @"iPhone7,2" on iPhone 6
     @"iPhone8,1" on iPhone 6S
     @"iPhone8,2" on iPhone 6S Plus
     @"iPhone8,4" on iPhone SE
     @"iPhone9,1" on iPhone 7 (CDMA)
     @"iPhone9,3" on iPhone 7 (GSM)
     @"iPhone9,2" on iPhone 7 Plus (CDMA)
     @"iPhone9,4" on iPhone 7 Plus (GSM)
     
     //iPad 1
     @"iPad1,1" on iPad - Wifi (model A1219)
     @"iPad1,1" on iPad - Wifi + Cellular (model A1337)
     
     //iPad 2
     @"iPad2,1" - Wifi (model A1395)
     @"iPad2,2" - GSM (model A1396)
     @"iPad2,3" - 3G (model A1397)
     @"iPad2,4" - Wifi (model A1395)
     
     // iPad Mini
     @"iPad2,5" - Wifi (model A1432)
     @"iPad2,6" - Wifi + Cellular (model  A1454)
     @"iPad2,7" - Wifi + Cellular (model  A1455)
     
     //iPad 3
     @"iPad3,1" - Wifi (model A1416)
     @"iPad3,2" - Wifi + Cellular (model  A1403)
     @"iPad3,3" - Wifi + Cellular (model  A1430)
     
     //iPad 4
     @"iPad3,4" - Wifi (model A1458)
     @"iPad3,5" - Wifi + Cellular (model  A1459)
     @"iPad3,6" - Wifi + Cellular (model  A1460)
     
     //iPad AIR
     @"iPad4,1" - Wifi (model A1474)
     @"iPad4,2" - Wifi + Cellular (model A1475)
     @"iPad4,3" - Wifi + Cellular (model A1476)
     
     // iPad Mini 2
     @"iPad4,4" - Wifi (model A1489)
     @"iPad4,5" - Wifi + Cellular (model A1490)
     @"iPad4,6" - Wifi + Cellular (model A1491)
     
     // iPad Mini 3
     @"iPad4,7" - Wifi (model A1599)
     @"iPad4,8" - Wifi + Cellular (model A1600)
     @"iPad4,9" - Wifi + Cellular (model A1601)
     
     // iPad Mini 4
     @"iPad5,1" - Wifi (model A1538)
     @"iPad5,2" - Wifi + Cellular (model A1550)
     
     //iPad AIR 2
     @"iPad5,3" - Wifi (model A1566)
     @"iPad5,4" - Wifi + Cellular (model A1567)
     
     // iPad PRO 12.9"
     @"iPad6,3" - Wifi (model A1673)
     @"iPad6,4" - Wifi + Cellular (model A1674)
     @"iPad6,4" - Wifi + Cellular (model A1675)
     
     //iPad PRO 9.7"
     @"iPad6,7" - Wifi (model A1584)
     @"iPad6,8" - Wifi + Cellular (model A1652)
     
     //iPod Touch
     @"iPod1,1"   on iPod Touch
     @"iPod2,1"   on iPod Touch Second Generation
     @"iPod3,1"   on iPod Touch Third Generation
     @"iPod4,1"   on iPod Touch Fourth Generation
     @"iPod7,1"   on iPod Touch 6th Generation
     */
    
    struct utsname systemInfo;
    uname(&systemInfo);
    char *p = systemInfo.machine;
    
    //NSString *nsDeviceModel = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    std::string ans(p);
    
    return ans;
#else
    return "";
#endif
}

#endif



