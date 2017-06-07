//
//  MessageProcessor.cpp
//  TestCamera 
//
//  Created by Apple on 11/3/15.
//
//

#include "MessageProcessor.hpp"
#include "Constants.h"
#include "TestCameraViewController.h"
#include <stdlib.h>
#include <stdio.h>
#include <string>


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
    string str((char *)buffer, iLen);
    int startIndex = 1;
    
    cout<<"Handle_Signaling_Message -->";
    for(int i=0;i<iLen;i++)
    {
        printf("%X ", buffer[i]);
    }
    cout<<endl;
    
    if(buffer[0] ==  Constants::REPLY_REGISTER_MESSAGE)
    {
        int userID = ByteToInt(buffer, startIndex);
        char cConvertedCharArray[12];
        sprintf(cConvertedCharArray, "%d", userID);
        string sValue = "UserID = " + std::string(cConvertedCharArray);
        [[TestCameraViewController GetInstance] UpdateUserID:sValue];
        
    }
    
}

int CMessageProcessor::ByteToInt(unsigned char* data, int &startIndex)
{
    int ret = 0;
    
    ret += (int) (data[startIndex++] & 0xFF) << 24;
    ret += (int) (data[startIndex++] & 0xFF) << 16;
    ret += (int) (data[startIndex++] & 0xFF) << 8;
    ret += (int) (data[startIndex++] & 0xFF);
    
    return ret;
}

void CMessageProcessor::IntToByte(int val, unsigned char* data, int &startIndex)
{
    data[startIndex++] = (unsigned char) ((val >> 24) & 0xFF);
    data[startIndex++] = (unsigned char) ((val >> 16) & 0xFF);
    data[startIndex++] = (unsigned char) ((val >> 8) & 0xFF);
    data[startIndex++] = (unsigned char) ((val >> 0) & 0xFF);
    
}



