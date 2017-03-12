
#ifndef _RENDERING_BUFFER_H_
#define _RENDERING_BUFFER_H_

#include "SmartPointer.h"
#include "LockHandler.h"
#include "Common.hpp"

#define MAX_VIDEO_RENDERER_BUFFER_SIZE 30
#define MAX_VIDEO_RENDERER_FRAME_SIZE (MAXWIDTH * MAXHEIGHT * 3 / 2)

class ClientRenderingBuffer
{

public:

	ClientRenderingBuffer();
	~ClientRenderingBuffer();

	int Queue(int iFrameNumber, unsigned char *ucaDecodedVideoFrameData, int nLength, long long llCaptureTimeDifference, int nVideoHeight, int nVideoWidth, int nOrientation);
	int DeQueue(int &irFrameNumber, long long &llrCaptureTimeDifference, unsigned char *ucaDecodedVideoFrameData, int &nrVideoHeight, int &nrVideoWidth,
				int &nrTimeDifferenceInQueue, int &nOrientation);
	void IncreamentIndex(int &irIndex);
	int GetQueueSize();
	void ResetBuffer();

private:

	int m_iPushIndex;
	int m_iPopIndex;
	int m_nQueueCapacity;
	int m_nQueueSize;


	unsigned char m_uc2aDecodedVideoDataBuffer[MAX_VIDEO_RENDERER_BUFFER_SIZE][MAX_VIDEO_RENDERER_FRAME_SIZE];

	int m_naBufferDataLengths[MAX_VIDEO_RENDERER_BUFFER_SIZE];
	int m_naBufferFrameNumbers[MAX_VIDEO_RENDERER_BUFFER_SIZE];
	int m_naBufferVideoHeights[MAX_VIDEO_RENDERER_BUFFER_SIZE];
	int m_naBufferVideoWidths[MAX_VIDEO_RENDERER_BUFFER_SIZE];
	int m_naBufferVideoOrientations[MAX_VIDEO_RENDERER_BUFFER_SIZE];
	
	long long m_llaBufferInsertionTimes[MAX_VIDEO_RENDERER_BUFFER_SIZE];
	long long m_llaBufferCaptureTimeDifferences[MAX_VIDEO_RENDERER_BUFFER_SIZE];

	SmartPointer<CLockHandler> m_pRenderingBufferMutex;
};

#endif 
