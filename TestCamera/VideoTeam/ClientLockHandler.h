
#ifndef _CLIENT_LOCK_HANDLER_H_
#define _CLIENT_LOCK_HANDLER_H_

#include <stdio.h>
#include <mutex>

#ifdef __APPLE__
#include <pthread.h>
#endif

class ClientLocker;

class ClientLockHandler
{

public:

	ClientLockHandler();
	~ClientLockHandler();

	std::mutex* GetMutex();
	void Lock();
	void UnLock();

private:

	std::mutex *m_pMutex;
};

class ClientLocker
{

public:

	ClientLocker(ClientLockHandler& m):

	mutex(m) 

	{ 
		mutex.Lock(); 
	}

	~ClientLocker()
	{ 
		mutex.UnLock(); 
	}

private:

	ClientLockHandler& mutex;
};


#endif

