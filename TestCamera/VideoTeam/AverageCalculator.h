
#ifndef _AVERAGE_CALCULATOR_
#define _AVERAGE_CALCULATOR_
#include<iostream>
using namespace std;

class CVideoCallSession;

class CAverageCalculator
{
public:
    CAverageCalculator(string sTag);
    void Reset();
    void UpdateData(long long nValue);
    double GetAverage();
    long long GetTotal();

    
private:
    double m_dAvg;
    int m_nCounter;
    long long m_llTotalValue;
    string m_sTag;
    
};


#endif //_AVERAGE_CALCULATOR_
