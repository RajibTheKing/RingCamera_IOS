//
//  ConvertNV21ToI420_arm64.S
//  TestCamera
//
//  Created by Rajib Chandra Das on 3/24/18.
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

NEON_ARM_AACH64_FUNC_BEGIN ConvertNV21ToI420_arm_aarch64

#X0 src
#X1 dest
#X2 iVideoHeight
#X3 iVideoWidth

src                 .req x0
dest                .req x1
iVideoHeight        .req x2
iVideoWidth         .req x3
YPlaneLength        .req x4
VPlaneLength        .req x5
UVPlaneMidPoint     .req x6
UVPlaneLength       .req x7
I                   .req x8
J                   .req x9
fragment            .req x10
uDest               .req x11
vDest               .req x12

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
ld2 {v0.16b,v1.16b}, [src], fragment
LSR fragment, fragment, #1
st1 {v1.16b}, [uDest], fragment
st1 {v0.16b}, [vDest], fragment
SUBS I, I, fragment
SUBS I, I, fragment


LOOP:
    ld2 {v0.16b,v1.16b}, [src], #32
    st1 {v1.16b}, [uDest], #16
    st1 {v0.16b}, [vDest], #16
    SUBS I, I, #32
    BNE LOOP



NEON_ARM_AACH64_FUNC_END

#endif
