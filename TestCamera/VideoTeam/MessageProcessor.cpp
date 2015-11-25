//
//  MessageProcessor.cpp
//  TestCamera 
//
//  Created by Apple on 11/3/15.
//
//

#include "MessageProcessor.hpp"


byte AUTH_SERVER_REGISTATION_REQUEST = 100;
byte AUTH_SERVER_REGISTATION_RESPONSE = 101;

byte VIDEO_SERVER_REGISTATION_REQUEST = 30;
byte VIDEO_SERVER_REGISTATION_RESPONSE = 31;


byte CALL_REQUEST = 102;
byte CALL_RESPONSE = 103;

byte USER_NAME = 100;
byte FRIEND_NAME = 101;

byte PEER_INFORMATION = 120;

string SERVER_ADDRESS = "192.168.8.31";
int SERVER_PORT = 10001;
int VIDEO_DATA = 33;

int CALL_ESTABLISHMENT_EVENT = 2;
int CALL_ESTABLISHMENT_SUCESS = 10;



CMessageProcessor::CMessageProcessor()
{
    
}
CMessageProcessor::~CMessageProcessor()
{
    
}


void CMessageProcessor::prepareLoginRequestMessageR(string username, string friendname, byte* message)
{
    if(!message) return;
    
    int iLength = 1 + 1 + username.size() + 1 + friendname.size();
    
    //unsigned char* message = (unsigned char*) malloc(iLength);
    int index = 1;
    
    setMessageType( message, VIDEO_SERVER_REGISTATION_REQUEST );
    index = pushAttributeR( message, friendname, index, USER_NAME );
    index = pushAttributeR( message, username, index, USER_NAME );
    
    for(int i=0;i<iLength ; i++)
        printf("%u\n", message[i]);

    return;
}

void CMessageProcessor::prepareLoginRequestMessage( string username, byte *message)
{
    int iLength = 1 + 4 + username.size();
    
    int index = 1;
    
    setMessageType( message, AUTH_SERVER_REGISTATION_REQUEST );
    pushAttribute( message, username, index, USER_NAME);
    
    cout<<"Rajib_Check: Final output: "<<endl;
    for(int i=0;i<iLength ; i++)
        printf("%d ", (int)message[i]);
    
    printf("\n");
    
    
    return;
}

int CMessageProcessor::pushAttribute( byte* message, string attribute, int index, byte attributeType )
{
    size_t attributeLength = attribute.size();
    
    size_t attributeLengthInbyteLength = 2;
    byte* attributeLengthInbyte = (byte*)malloc(attributeLengthInbyteLength);
    
    
    
    //setMessageType( message, 676 );
    intToByteArray( attributeLength, attributeLengthInbyte);
    
    printf("b4\n");
    
    byte* attributeInByte = (byte*)malloc(attributeLength);
    cout<<"Attribute Length = "<<attributeLength<<endl;
    

#if 1
    for(int i=0;i<attributeLength;i++)
        attributeInByte[i] = (byte)attribute[i];
    
    
    printf("attributeInByte = %s\n", (char *)attributeInByte);
    
    message[index++] = 0;
    message[index++] = attributeType;
    
    //System.arraycopy( attributeLengthInbyte, 0, message, index, attributeLengthInbyte.length );
    memcpy(message+index, attributeLengthInbyte, attributeLengthInbyteLength);
    
    index += attributeLengthInbyteLength;
    
    //System.arraycopy( attributeInByte, 0, message, index, attributeInByte.length );
    
    
    memcpy(message+index, attributeInByte, attributeLength);
    index += attributeLength;
    
    return index;
#endif
}




void CMessageProcessor::setMessageType( byte* message, byte messageType )
{
    printf("in setMessageType= \n" );
    message[0] = messageType;
    
}
int CMessageProcessor::pushAttributeR( byte* message, string attribute, int index, byte attributeType)
{
    int attributeLength = attribute.size();
    printf("Attribute length = %d\n", attributeLength);
    
    
    byte* attributeInByte = (byte*)attribute.c_str();
    
    message[index++] = (byte)attributeLength;

    
    memcpy(message+index, attributeInByte, attributeLength);
    index += attributeLength;
    cout<<"Returning index = "<<index<<endl;
    return index;
    
    
}


void CMessageProcessor::prepareCallRequestMessage( byte* message, string username, string friendname)
{
    int index = 1;
    
    //byte[] message = new byte[ 1 + 4 + username.length() + 4 + friendname.length() + 4 + sdp.length() ];
    
    setMessageType( message, CALL_REQUEST );
    index = pushAttribute( message, username, index, USER_NAME );
    index = pushAttribute( message, friendname, index, FRIEND_NAME );
    
    return;
}


void CMessageProcessor::intToByteArray(int value, byte* outMessage)
{
    printf("In intToByteArray\n");
    outMessage[0] = (byte)(value>>8);
    outMessage[1] = (byte)value;
    
    
    
    /*
    return new byte[]
    {
        (byte)(value >>> 8),
        (byte)value
    };
     */
    
}
