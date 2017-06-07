//
//  MessageProcessor.cpp
//  TestCamera 
//
//  Created by Apple on 11/3/15.
//
//

#include "MessageProcessor.hpp"



CMessageProcessor::CMessageProcessor()
{
    
}
CMessageProcessor::~CMessageProcessor()
{
    
}

CMessageProcessor* CMessageProcessor::GetInstance()
{
    if(m_pMessageProcessor == nullptr)
    {
        m_pMessageProcessor = new CMessageProcessor();
    }
    return m_pMessageProcessor;
}

void CMessageProcessor::Handle_Signaling_Message(unsigned char* buffer, int iLen)
{
    
}



