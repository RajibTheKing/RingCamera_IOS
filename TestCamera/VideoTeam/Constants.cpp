

#include "Constants.h"

int Constants::VOICE_BINDING_PORT;
int Constants::VOICE_REGISTER_PORT;
std::string Constants::CALL_ID;
std::string Constants::VOICE_SERVER_IP;
std::string Constants::AUTH_SERVER_IP; 
int Constants::AUTH_SERVER_PORT;

void Constants::setCallID(std::string callID)
{
//	CALL_ID = callID;
}

void Constants::setVoiceBindingPort(int port)
{
//	VOICE_BINDING_PORT = port;
}

int Constants::getVoiceBindingPort()
{
	return VOICE_BINDING_PORT;
}

void Constants::setVoiceServerIP(std::string IP)
{
//	VOICE_SERVER_IP = IP;
}
