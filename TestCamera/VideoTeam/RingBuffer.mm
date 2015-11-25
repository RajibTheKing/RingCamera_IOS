//
//  RingBuffer.cpp
//  TestCamera 
//
//  Created by Apple on 10/19/15.
//
//
#include "RingBuffer.hpp"

template <class A_Type> RingBuffer<A_Type>::RingBuffer(int iHeight, int iWidth, int iQSize)
{
    m_iRowSize = iHeight * iWidth * 3 / 2 + 1;
    m_iQSize = iQSize;
    
    
    m_iWritableIndex = 0;
    pthread_mutex_init(&pmRinBufferMutex, NULL);
    Q = new A_Type*[iQSize];
    m_pStatus = new int[iQSize];
    memset(m_pStatus, 0, sizeof 4*m_iQSize);
    for (int i = 0; i < iQSize; i++)
    {
        Q[i] = new A_Type[m_iRowSize];
        memset(Q[i], 0, m_iRowSize * sizeof(A_Type));
    }
}

template <class A_Type> RingBuffer<A_Type>::RingBuffer(int iRowSize, int iQSize)
{
    m_iRowSize = iRowSize;
    m_iQSize = iQSize;
    m_iWritableIndex = 0;
    pthread_mutex_init(&pmRinBufferMutex, NULL);
    Q = new A_Type *[iQSize];
    m_pStatus = new int[iQSize];
    memset(m_pStatus, 0, sizeof 4 * m_iQSize);
    for (int i = 0; i < iQSize; i++)
    {
        Q[i] = new A_Type[m_iRowSize];
        memset(Q[i], 0, m_iRowSize * sizeof(A_Type));
    }
}

template <class A_Type> RingBuffer<A_Type>::~RingBuffer()
{
    delete[] m_pStatus;
    for (int i = 0; i < m_iQSize; i++)
    {
        delete Q[i];
    }
    delete Q;
}


template <class A_Type> A_Type *  RingBuffer<A_Type>::getWritableAddress(int *index,int no)
{
    pthread_mutex_lock(&pmRinBufferMutex);
    if(no)
    {
        printf("m_iWritableIndex: %d\n",m_iWritableIndex);
        for(int i=0;i<5;i++)printf("%d ",m_pStatus[i]);printf("\n");
    }
    while (1 == m_pStatus[m_iWritableIndex])
    {
        ++m_iWritableIndex;
        if (m_iWritableIndex == m_iQSize)
            m_iWritableIndex = 0;
    }
    
    *index = m_iWritableIndex;
    ++m_iWritableIndex;
    if (m_iWritableIndex == m_iQSize)
        m_iWritableIndex = 0;
    m_pStatus[*index] = 1;
    if(no)printf("_+_+_+_+_+ Writable---ind: %d\n",*index);
    pthread_mutex_unlock(&pmRinBufferMutex);
    
    return Q[*index];
    
}

template <class A_Type> A_Type *  RingBuffer<A_Type>::getReadableAddress(int *index,int no)
{
    pthread_mutex_lock(&pmRinBufferMutex);
    if(no)
    {
        printf("m_iWritableIndex: %d\n",m_iWritableIndex);
        for(int i=0;i<5;i++)printf("%d ",m_pStatus[i]);printf("\n");
    }
    *index = m_iWritableIndex;
    for (int i = 0; i < m_iQSize; ++i)
    {
        if (2 == m_pStatus[*index])
        {
            m_pStatus[*index] = 1;
            if(no)printf("_+_+_+_+_+ Readable ind: %d\n",*index);
            pthread_mutex_unlock(&pmRinBufferMutex);
            return Q[*index];
        }
        ++(*index);
        if (*index == m_iQSize)
            *index = 0;
    }
    *index = -1;
    if(no)printf("_+_+_+_+_+ R ind: %d\n",*index);
    pthread_mutex_unlock(&pmRinBufferMutex);
    return NULL;
}

template <class A_Type> void  RingBuffer<A_Type>::setIndexStatus(int index, int statusNumber){
    pthread_mutex_lock(&pmRinBufferMutex);
    m_pStatus[index] = statusNumber;
    if(statusNumber==AVAILABLE_TO_WRITE)
        memset(Q[index],0,sizeof(Q[index]));
    pthread_mutex_unlock(&pmRinBufferMutex);
}


template <class A_Type> void  RingBuffer<A_Type>::showQ(){
    cout << endl << endl;
    cout << "Index: " << m_iWritableIndex << endl;
    for (int i = 0; i < m_iQSize; ++i)
    {
        cout << (int)Q[i][0] << " [" << m_pStatus[i] << "]\t";
    }
    cout << endl;
}

template class RingBuffer<int>;
template class RingBuffer<byte>;
