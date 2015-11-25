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
    
    
    void prepareLoginRequestMessageR(string username, string friendname, byte* outMessage);
    void prepareLoginRequestMessage( string username, byte *message);
    void prepareCallRequestMessage( byte* message, string username, string friendname);
    
private:
    void setMessageType( byte* message, byte messageType );
    int pushAttributeR( byte* message, string attribute, int  index, byte attributeType);
    int pushAttribute( byte* message, string attribute, int index, byte attributeType );
    void intToByteArray(int value, byte* outMessage);
    
};
#endif /* MessageProcessor_hpp */
