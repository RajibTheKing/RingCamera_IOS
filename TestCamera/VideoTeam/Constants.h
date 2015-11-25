
#if !defined( _CONSTANTS_H_ )
#define _CONSTANTS_H_

#include <string>

class Constants
{

public:

	static int VOICE_BINDING_PORT;
	static std::string CALL_ID;
	static std::string VOICE_SERVER_IP;
	static std::string AUTH_SERVER_IP;
	static int VOICE_REGISTER_PORT;
	static int AUTH_SERVER_PORT;

	static const int VOICE_MEDIA = 0;
	static const int VOICE_REGISTER = 1;
	static const int VOICE_UNREGISTERED = 2;
	static const int VOICE_REGISTER_CONFIRMATION = 3;
	static const int NUMBER_OF_RESEND = 5;
	static const int REGISTER_RESEND_TIME = 30000;	

	static const int KEEPALIVE = 4;
	static const int CALLING = 5;
	static const int RINGING = 6;
	static const int IN_CALL = 7;
	static const int ANSWER = 8;
	static const int BUSY = 9;
	static const int CANCELED = 10;
	static const int CONNECTED = 11;
	static const int DISCONNECTED = 12;
	static const int BYE = 13;
	static const int IDEL = 14;
	static const int NO_ANSWER = 15;
	static const int USER_AVAILABLE = 16;
	static const int USER_NOT_AVAILABLE = 17;

	static const int VOICE_REGISTER_PUSH = 20;
	static const int VOICE_REGISTER_PUSH_CONFIRMATION = 21;
	static const int PUBLIC_ADDRESS_REQUEST = 100;
	static const int PUBLIC_ADDRESS_RESPONSE = 101;

	static const int PACKET_TYPE_LENGTH = 1;
	static const int PACKET_ID_LENGTH = 16;
	static const int PACKET_ID_LENGTH_LENGTH = 1;
	static const int USER_ID_LENGTH = 8;
	static const int FRIEND_ID_LENGTH = 8;

	static const int LOGIN = 110;
	static const int LOGIN_RESPONSE = 101;
	static const int LOGIN_OUT = 112;
	static const int LOGIN_OUT_RESPONSE = 111;
	static const int CALL_REQUEST = 102;
	static const int CALL_RESPONSE = 103;
	static const int KEEP_ALIVE_REQUEST = 115;

	static const int LOGIN_PACKET_LENGTH = PACKET_TYPE_LENGTH + USER_ID_LENGTH;
	static const int CALL_PACKET_LENGTH = PACKET_TYPE_LENGTH + USER_ID_LENGTH + FRIEND_ID_LENGTH;
	static const int SIGNALING_PACKET_LENGTH = PACKET_TYPE_LENGTH + USER_ID_LENGTH + FRIEND_ID_LENGTH + PACKET_ID_LENGTH_LENGTH + PACKET_ID_LENGTH;
	static const int AVAILABILITY_PACKET_LENGTH = PACKET_TYPE_LENGTH + FRIEND_ID_LENGTH + PACKET_ID_LENGTH_LENGTH + PACKET_ID_LENGTH;

	static void setCallID(std::string callID);
	static void setVoiceBindingPort(int port);
	static void setVoiceServerIP(std::string IP);

	static int getVoiceBindingPort();

};

#endif 