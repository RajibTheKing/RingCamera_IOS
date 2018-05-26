//
//  BeautificationFilterForChannel_arm_aarch32.S
//  TestCamera
//
//  Created by Rajib Chandra Das on 4/1/18.
//
#ifdef HAVE_NEON

.macro NEON_ASM_FUNC_BEGIN
.syntax unified
.text
.extern printf
.align 2
.arm
.globl _$0
_$0:
.endm

.macro NEON_ASM_FUNC_END
mov pc, lr
.endm

NEON_ASM_FUNC_BEGIN BeautificationFilterForChannel_arm_aarch32
#r0 inData
#r1 param {iHeight, iWidth}
#r2 outData
#r3 tempShortArray
push {r4-r12, lr}

src                 .req r0
dest                .req r2
iHeight             .req r1
iWidth              .req r3
prevRow             .req r4
nextRow             .req r5
I                   .req r6
J                   .req r7
tempX               .req r8
fragment            .req r9
rightData           .req r10
leftData            .req r11

VLD1.u32 {d0}, [r1]!
VMOV iHeight, iWidth, d0

MOV prevRow, src
ADD src, src, iWidth
ADD nextRow, src, iWidth
MOV I, #2

MOV tempX, #0
VDUP.u16 Q0, tempX
MOV tempX, #255
VDUP.u16 Q1, tempX

MOV fragment, #8
MOV tempX, iWidth
SUB tempX, tempX, #2

HEIGHT_LOOP:
    MOV J, #2
    MOV fragment, #1

    MOV leftData, src
    MOV rightData, src
    ADD rightData, rightData, #2

    VLD1.u8 {Q2}, [src], fragment
    VLD1.u8 {Q3}, [prevRow], fragment
    VLD1.u8 {Q4}, [nextRow], fragment
    VST1.u8 {Q2}, [dest], fragment
    ANDS fragment, tempX, 7

    BEQ WIDTH_LOOP

    VLD1.u8 {d4}, [src], fragment
    VADDL.u8 Q4, d0, d4
    VSHL.u16 Q4, Q4, #2
    VLD1.u8 {d6}, [prevRow], fragment
    VSUBW.u8 Q4, Q4, d6
    VLD1.u8 {d6}, [nextRow], fragment
    VSUBW.u8 Q4, Q4, d6
    VLD1.u8 {d6}, [leftData], fragment
    VSUBW.u8 Q4, Q4, d6
    VLD1.u8 {d6}, [rightData], fragment
    VSUBW.u8 Q4, Q4, d6

    VADDW.u8 Q4, Q4, d4

    VMIN.s16 Q4, Q4, Q1
    VMAX.s16 Q4, Q4, Q0


    VSHL.u16 Q4, Q4, #8
    VADDHN.u16 d12, Q4, Q0
    VST1.u8 {d12}, [dest], fragment
    ADD J, J, fragment

    WIDTH_LOOP:
        MOV fragment, #8
        VLD1.u8 {d4}, [src], fragment
        VADDL.u8 Q4, d0, d4
        VSHL.u16 Q4, Q4, #2
        VLD1.u8 {d6}, [prevRow], fragment
        VSUBW.u8 Q4, Q4, d6
        VLD1.u8 {d6}, [nextRow], fragment
        VSUBW.u8 Q4, Q4, d6
        VLD1.u8 {d6}, [leftData], fragment
        VSUBW.u8 Q4, Q4, d6
        VLD1.u8 {d6}, [rightData], fragment
        VSUBW.u8 Q4, Q4, d6

        VADDW.u8 Q4, Q4, d4

        VMIN.s16 Q4, Q4, Q1
        VMAX.s16 Q4, Q4, Q0


        VSHL.u16 Q4, Q4, #8
        VADDHN.u16 d12, Q4, Q0
        VST1.u8 {d12}, [dest], fragment

        ADD J, J, fragment

        CMP J, iWidth
        BNE WIDTH_LOOP

    MOV fragment, #1
    VLD1.u8 {Q2}, [src], fragment
    VLD1.u8 {Q3}, [prevRow], fragment
    VLD1.u8 {Q4}, [nextRow], fragment
    VST1.u8 {Q2}, [dest], fragment

ADD I, I, #1
CMP I, iHeight
BNE HEIGHT_LOOP

pop { r4-r12, pc }

NEON_ASM_FUNC_END
#endif
