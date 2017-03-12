
#include "ClientRenderingBuffer.h"

ClientRenderingBuffer::ClientRenderingBuffer() :

m_iPushIndex(0),
m_iPopIndex(0),
m_nQueueSize(0),
m_nQueueCapacity(MAX_VIDEO_RENDERER_BUFFER_SIZE)

{
	m_pRenderingBufferMutex.reset(new ClientLockHandler);
}

ClientRenderingBuffer::~ClientRenderingBuffer()
{
    m_pRenderingBufferMutex.reset();
}

void ClientRenderingBuffer::ResetBuffer()
{
	ClientLocker lock(*m_pRenderingBufferMutex);

	m_iPushIndex = 0;
	m_iPopIndex = 0;
	m_nQueueSize = 0;
}

int ClientRenderingBuffer::Queue(unsigned char *ucaDecodedVideoFrameData, int nLength,int nVideoHeight, int nVideoWidth,int nOrientation)
{
	ClientLocker lock(*m_pRenderingBufferMutex);
	memcpy(m_uc2aDecodedVideoDataBuffer[m_iPushIndex], ucaDecodedVideoFrameData, nLength);

	m_naBufferDataLengths[m_iPushIndex] = nLength;
	m_naBufferVideoHeights[m_iPushIndex] = nVideoHeight;
	m_naBufferVideoWidths[m_iPushIndex] = nVideoWidth;
	m_naBufferVideoOrientations[m_iPushIndex] = nOrientation;
    
	if (m_nQueueSize == m_nQueueCapacity)
    {
        IncreamentIndex(m_iPopIndex);

    }
    else
    { 
		m_nQueueSize++;      
    }
    
    IncreamentIndex(m_iPushIndex);
    
    return 1;
}

int ClientRenderingBuffer::DeQueue(unsigned char *ucaDecodedVideoFrameData, int &nrVideoHeight, int &nrVideoWidth, int &nOrientation)
{
	ClientLocker lock(*m_pRenderingBufferMutex);
	if (m_nQueueSize <= 0)
	{
		return -1;
	}
	else
	{
		int nLength;
		
		nLength = m_naBufferDataLengths[m_iPopIndex];
		nrVideoHeight = m_naBufferVideoHeights[m_iPopIndex];
		nrVideoWidth = m_naBufferVideoWidths[m_iPopIndex];
		nOrientation = m_naBufferVideoOrientations[m_iPopIndex];

		memcpy(ucaDecodedVideoFrameData, m_uc2aDecodedVideoDataBuffer[m_iPopIndex], nLength);
		//nrTimeDifferenceInQueue = m_Tools.CurrentTimestamp() - m_llaBufferInsertionTimes[m_iPopIndex];

		IncreamentIndex(m_iPopIndex);
        
		m_nQueueSize--;

		return nLength;
	}
}

void ClientRenderingBuffer::IncreamentIndex(int &irIndex)
{
	irIndex++;

	if (irIndex >= m_nQueueCapacity)
		irIndex = 0;
}

int ClientRenderingBuffer::GetQueueSize()
{
	ClientLocker lock(*m_pRenderingBufferMutex);

	return m_nQueueSize;
}
