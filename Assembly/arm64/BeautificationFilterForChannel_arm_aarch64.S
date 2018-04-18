//
//  BeautificationFilterForChannel_arm_aarch64.S
//  TestCamera
//
//  Created by Rajib Chandra Das on 4/1/18.
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

NEON_ARM_AACH64_FUNC_BEGIN BeautificationFilterForChannel_arm_aarch64

#X0 inData
#X1 param {iHeight, iWidth}
#X2 outData
#X3 tempShortArray

src                 .req x0
dest                .req x2
iHeight             .req x4
iWidth              .req x5
rightData           .req x6
leftData            .req x7
UVPlaneMidPoint     .req x8
UVPlaneLength       .req x9
I                   .req x10
J                   .req x11
fragment            .req x12
prevRow             .req x13
nextRow             .req x14
temp                .req w15
tempX               .req X15

LD1 {V0.4S}, [X1], #16
UMOV W4     , V0.S[0]
UMOV W5     , V0.S[1]

MOV V0.S[0], W4
MOV prevRow, src
ADD src, src, iWidth
ADD nextRow, src, iWidth
MOV I, #2

MOV temp, #0
DUP V9.16B, temp

MOV temp, #255
DUP V10.8H, temp

MOV fragment, #8
MOV tempX, iWidth
SUB tempX, tempX, #2
HEIGHT_LOOP:

    MOV J, #2
    MOV fragment, #1

    MOV leftData, src
    MOV rightData, src
    ADD rightData, rightData, #2

    LD1 {V1.16B}, [src], fragment
    LD1 {V2.16B}, [prevRow], fragment
    LD1 {V3.16B}, [nextRow], fragment
    ST1 {V1.16B}, [dest], fragment

    ANDS fragment, tempX, 7
    BEQ WIDTH_LOOP
    LD1 {V1.8B}, [src], fragment
    LD1 {V2.8B}, [prevRow], fragment
    LD1 {V3.8B}, [nextRow], fragment
    LD1 {V6.8B}, [leftData], fragment
    LD1 {V7.8B}, [rightData], fragment

    UADDL V4.8H, V9.8B, V1.8B
    SHL V4.8H, V4.8H, #2
    USUBW V4.8H, V4.8H, V2.8B
    USUBW V4.8H, V4.8H, V3.8B
    USUBW V4.8H, V4.8H, V6.8B
    USUBW V4.8H, V4.8H, V7.8B
#SHL V4.8H, V4.8H, #1
    UADDW V4.8H, V4.8H, V1.8B

    SMIN V4.8H, V4.8H, V10.8H
    SMAX V4.8H, V4.8H, V9.8H

    SHL V4.8H, V4.8H, #8
    ADDHN V5.8B, V4.8H, V9.8H
    ST1 {V5.8B}, [dest], fragment

    ADD J, J, fragment


    WIDTH_LOOP:
        MOV fragment, #8
        LD1 {V1.8B}, [src], fragment
        LD1 {V2.8B}, [prevRow], fragment
        LD1 {V3.8B}, [nextRow], fragment
        LD1 {V6.8B}, [leftData], fragment
        LD1 {V7.8B}, [rightData], fragment

        UADDL V4.8H, V9.8B, V1.8B
        SHL V4.8H, V4.8H, #2
        USUBW V4.8H, V4.8H, V2.8B
        USUBW V4.8H, V4.8H, V3.8B
        USUBW V4.8H, V4.8H, V6.8B
        USUBW V4.8H, V4.8H, V7.8B
#SHL V4.8H, V4.8H, #1
        UADDW V4.8H, V4.8H, V1.8B

        SMIN V4.8H, V4.8H, V10.8H
        SMAX V4.8H, V4.8H, V9.8H

        SHL V4.8H, V4.8H, #8
        ADDHN V5.8B, V4.8H, V9.8H
        ST1 {V5.8B}, [dest], fragment

        ADD J, J, fragment
        CMP J, iWidth
        BNE WIDTH_LOOP

        MOV fragment, #1
        LD1 {V1.16B}, [src], fragment
        LD1 {V2.16B}, [prevRow], fragment
        LD1 {V3.16B}, [nextRow], fragment
        ST1 {V1.16B}, [dest], fragment


ADD I, I, #1
CMP I, iHeight
BNE HEIGHT_LOOP


NEON_ARM_AACH64_FUNC_END


#endif
