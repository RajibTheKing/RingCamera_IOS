
#include "ClientLockHandler.h"

ClientLockHandler::ClientLockHandler() :
m_pMutex(NULL)

{
	m_pMutex = new std::mutex;
}

ClientLockHandler::~ClientLockHandler()
{
/*	
	if (m_pMutex != NULL)
	{
		delete m_pMutex;

		m_pMutex = NULL;
	}
*/
}

std::mutex* ClientLockHandler::GetMutex()
{
	if (NULL == m_pMutex)
		return NULL;

	return m_pMutex;
}

void ClientLockHandler::Lock()
{
	if (NULL == m_pMutex)
		return;

	m_pMutex->lock();
}

void ClientLockHandler::UnLock()
{
	if (NULL == m_pMutex)
		return;

	m_pMutex->unlock();
}
