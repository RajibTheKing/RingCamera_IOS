//
//  DownScaleDynamicAssembly_arm64.S
//  TestCamera
//
//  Created by Rajib Chandra Das on 7/18/18.
//
#if defined(HAVE_NEON_AARCH64)

.macro NEON_ARM_AACH64_FUNC_BEGIN
.text
.extern printf
.align 2
.globl _$0
_$0:
.endm

.macro NEON_ARM_AACH64_FUNC_END
ret
.endm


//for (int i = 1, iw = inWidth; i<inHeight; i++, iw += inWidth)
//{
//    CumulativeSum2[i*inWidth] = (int)(CumulativeSum2[ (i - 1) * inWidth] + pData[iw]);
//}

NEON_ARM_AACH64_FUNC_BEGIN InitializeCumulativeSumForY_arm_aarch64
inHeight            .req    x0
inWidth             .req    x1
pData               .req    x2
CumulativeSumY      .req    x3
I                   .req    x10
J                   .req    x11
iw                  .req    x4
temp                .req    x5

MOV I, inHeight
MOV J, inWidth
MOV iw, inWidth
MOV temp, pData

LD1 {V0.16B}, [temp], #16


Y_HEIGHT_LOOP:






NEON_ARM_AACH64_FUNC_END


#endif
