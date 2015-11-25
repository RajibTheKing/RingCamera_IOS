//
//  RingBuffer.hpp
//  TestCamera 
//
//  Created by Apple on 10/19/15.
//
//

#ifndef RingBuffer_hpp
#define RingBuffer_hpp

#include <stdio.h>
#include <iostream>
#include <pthread.h>
#include "common.h"
using namespace std;

#define AVAILABLE_TO_WRITE	0
#define NOT_AVAILABLE		1
#define AVAILABLE_TO_READ	2


template <class A_Type> class RingBuffer
{
    A_Type **Q;
    pthread_mutex_t pmRinBufferMutex;
    
    int *m_pStatus;
    
    
public:
    int m_iWritableIndex;
    int m_iRowSize, m_iQSize;
    RingBuffer(int iHeight, int iWidth, int iQSize);
    RingBuffer(int iRowSize, int iQSize);
    ~RingBuffer();
    
    
    A_Type * getReadableAddress(int *index,int no=0);
    A_Type * getWritableAddress(int *index,int no=0);
    void setIndexStatus(int index, int statusNumber);
    void showQ();
    
};



#endif /* RingBuffer_hpp */
