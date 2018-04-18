//
//  ConvertNV21ToI420_arm32.S
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

NEON_ASM_FUNC_BEGIN ConvertNV21ToI420_arm_aarch32

#r0 src
#r1 dest
#r2 iVideoHeight
#r3 iVideoWidth

push {r4-r12, lr}

src                 .req r0
dest                .req r1
iVideoHeight        .req r2
iVideoWidth         .req r3
YPlaneLength        .req r4
VPlaneLength        .req r5
UVPlaneMidPoint     .req r6
UVPlaneLength       .req r7
I                   .req r8
J                   .req r9
fragment            .req r10
uDest               .req r11
vDest               .req r12

MUL YPlaneLength, iVideoHeight, iVideoWidth
LSR VPlaneLength, YPlaneLength, #2
ADD UVPlaneMidPoint, YPlaneLength, VPlaneLength
LSL UVPlaneLength, VPlaneLength, #1

ADD src, src, YPlaneLength
ADD dest, dest, YPlaneLength
MOV I, UVPlaneLength
MOV uDest, dest
MOV vDest, dest
ADD vDest, vDest, VPlaneLength


ANDS fragment, I, #31
BEQ LOOP

vld2.u8 {q0,q1}, [src], fragment
LSR fragment, fragment, #1
vst1.u8 {q1}, [uDest], fragment
vst1.u8 {q0}, [vDest], fragment
SUBS I, I, fragment
SUBS I, I, fragment


LOOP:
    vld2.u8 {q0,q1}, [src]!
    vst1.u8 {q1}, [uDest]!
    vst1.u8 {q0}, [vDest]!
    SUBS I, I, #32
    BNE LOOP

pop { r4-r12, pc }

NEON_ASM_FUNC_END

#endif
