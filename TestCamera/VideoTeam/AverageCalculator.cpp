
#include "AverageCalculator.h"


CAverageCalculator::CAverageCalculator(string sTag)
{
    m_nCounter = 0;
    m_dAvg = 0.0;
    m_llTotalValue = 0;
    m_sTag = sTag;
    
}
void CAverageCalculator::Reset()
{
    m_nCounter = 0;
    m_dAvg = 0.0;
}
void CAverageCalculator::UpdateData(long long nValue)
{
    m_nCounter++;
    m_llTotalValue+=nValue;
}
double CAverageCalculator::GetAverage()
{
    m_dAvg = (m_llTotalValue*1.0)/(m_nCounter*1.0);
    return m_dAvg;
}

long long CAverageCalculator::GetTotal()
{
    return m_llTotalValue;
}


