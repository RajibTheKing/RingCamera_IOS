//
//  MessageProcessor.hpp
//  TestCamera 
//
//  Created by Apple on 11/3/15.
//
//

#ifndef MessageProcessor_hpp
#define MessageProcessor_hpp

#include <stdio.h>
#include <iostream>
using namespace std;


#define byte unsigned char


class CMessageProcessor
{
public:
    CMessageProcessor();
    ~CMessageProcessor();
    
    static CMessageProcessor* GetInstance();
    
    void Handle_Signaling_Message(unsigned char* buffer, int iLen);
private:
    int ByteToInt(unsigned char* data, int &startIndex);
    void IntToByte(int val, unsigned char* data, int &startIndex);
    
};
static CMessageProcessor *m_pMessageProcessor = nullptr;

#endif /* MessageProcessor_hpp */
