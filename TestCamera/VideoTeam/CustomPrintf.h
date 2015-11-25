
#include <stdio.h>
#include <stdarg.h>


static void CustomPrintf(const char* format, ...)
{
    
    
    
     NSFileHandle *handle;
     NSArray *Docpaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
     NSString *documentsDirectory = [Docpaths objectAtIndex:0];
     NSString *filePathyuv = [documentsDirectory stringByAppendingPathComponent:@"MyOutput.txt"];
     handle = [NSFileHandle fileHandleForUpdatingAtPath:filePathyuv];
     char *filePathChar = (char*)[filePathyuv UTF8String];
     
     
     //freopen(filePathChar, "w+", stdout);
     
    
    
    
	static FILE *g_sfpLogFile = fopen(filePathChar, "w");
//#ifdef OUTPUT_PRINTF_TO_LOG
	//if(!g_sfpLogFile && CSettings::GetInstance()->m_bLoggingEnabled)
	{
		//g_sfpLogFile = fopen(filePathChar, "w+");
		if(g_sfpLogFile){
			fprintf(g_sfpLogFile, "=========== Log file opened for camapp (" __DATE__ ")============\n");
		}
	}
//#endif
	//std::string sTime = SGetTimeInMS();
	va_list argptr;
	va_start(argptr, format);	
	if(g_sfpLogFile){
		//fprintf(g_sfpLogFile, "[%s] ", sTime.c_str());
		vfprintf(g_sfpLogFile, format, argptr);
		fflush(g_sfpLogFile);		
	}
	//fprintf(stdout, "[%s] ", sTime.c_str());
	//vfprintf(stdout, format, argptr);
	va_end(argptr);
}

#define printf(...) CustomPrintf(__VA_ARGS__) 
