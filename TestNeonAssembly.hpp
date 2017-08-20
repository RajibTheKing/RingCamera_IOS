//
//  TestNeonAssembly.hpp
//  TestCamera 
//
//  Created by Rajib Chandra Das on 7/26/17.
//
//

#ifndef TestNeonAssembly_hpp
#define TestNeonAssembly_hpp

#include <stdio.h>
//#include "Neon_Assembly.s"

extern "C"
{
    void convert_asm_neon( unsigned char*  __restrict dest, unsigned char* __restrict src, int n);
    void add_asm_neon(unsigned char*  __restrict dest, unsigned char*  __restrict src, int n);
    void copy_asm_neon(unsigned char* __restrict src, unsigned char* __restrict dest, int iLen);
    void convert_nv12_to_i420_asm_neon(unsigned char* __restrict src, unsigned char* __restrict dest, int iHeight, int iWidth);
    
    
}


class TestNeonAssembly
{
public:
    TestNeonAssembly();
    ~TestNeonAssembly();
    
    void reference_convert (unsigned char* __restrict dest, unsigned char* __restrict src, int n);
    void neon_intrinsic_convert (unsigned char* __restrict dest, unsigned char* __restrict src, int n);
    void neon_assembly_convert (unsigned char*  __restrict dest, unsigned char* __restrict src, int n);
    void neon_assembly_Inc(unsigned char*  __restrict dest, unsigned char*  __restrict src, int n);
    void Copy_Assembly_Inc(unsigned char* __restrict src, unsigned char* __restrict dest, int iLen);
    void convert_nv12_to_i420_assembly(unsigned char* __restrict src, unsigned char* __restrict dest, int iHeight, int iWidth);
    
};

#endif /* TestNeonAssembly_hpp */
