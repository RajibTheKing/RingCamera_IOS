//
//  Crop_YUVNV12_YUVNV21_Assembly_arm32.S
//  TestCamera
//
//  Created by Rajib Chandra Das on 3/24/18.
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

NEON_ASM_FUNC_BEGIN Crop_YUVNV12_YUVNV21_arm_aarch32
#r0 src
#r1 dest
#r2 rest parameters

push {r3-r12, lr}

inHeight    .req r3
inWidth     .req r4
startXDiff  .req r5
endXDiff    .req r6
startYDiff  .req r7
endYDiff    .req r8
temp        .req r9
I           .req r10
J           .req r11
fragment    .req r12

VLD1.u32 {d0}, [r2]!
VLD1.u32 {d1}, [r2]!
VLD1.u32 {d2}, [r2]!

VMOV inHeight, inWidth, d0
VMOV startXDiff, endXDiff, d1
VMOV startYDiff, endYDiff, d2

##Calculation for Luminance
MUL temp, inWidth, startYDiff
ADD r0, r0, temp
MOV I, inHeight
SUB I, I, startYDiff
SUB I, I, endYDiff

Y_HEIGHT_LOOP:
    ADD r0, r0, startXDiff
    MOV J, inWidth
    SUB J, J, startXDiff
    SUB J, J, endXDiff

    ANDS fragment, J, #15

    BEQ Y_WIDTH_LOOP
    VLD1.u8 {q3}, [r0], fragment
    VST1.u8 {q3}, [r1], fragment
    SUB J, J, fragment

    Y_WIDTH_LOOP:
        VLD1.u8 {q3}, [r0]!
        VST1.u8 {q3}, [r1]!
        SUBS J, J, #16

        BNE Y_WIDTH_LOOP

    ADD r0, r0, endXdiff
    SUBS I, I, #1
    BNE Y_HEIGHT_LOOP

    MUL temp, inWidth, endYDiff
    ADD r0, r0, temp

##Calculation for UV
LSR startYDiff, startYDiff, #1
LSR endYDiff, endYDiff, #1

MUL temp, inWidth, startYDiff
ADD r0, r0, temp
MOV I, inHeight
LSR I, I, #1
SUB I, I, startYDiff
SUB I, I, endYDiff

UV_HEIGHT_LOOP:

    ADD r0, r0, startXDiff
    MOV J, inWidth
    SUB J, J, startXDiff
    SUB J, J, endXDiff
    ANDS fragment, J, #15

    BEQ UV_WIDTH_LOOP
    VLD1.u8 {q3}, [r0], fragment
    VST1.u8 {q3}, [r1], fragment
    SUB J, J, fragment

    UV_WIDTH_LOOP:
        VLD1.u8 {q3}, [r0]!
        VST1.u8 {q3}, [r1]!
        SUBS J, J, #16
        BNE UV_WIDTH_LOOP

    ADD r0, r0, endXdiff
    SUBS I, I, #1
    BNE UV_HEIGHT_LOOP

pop { r3-r12, pc }

NEON_ASM_FUNC_END

#endif
