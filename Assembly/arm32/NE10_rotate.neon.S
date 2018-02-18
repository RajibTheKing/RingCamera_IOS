#ifdef HAVE_NEON

.macro NEON_ASM_FUNC_BEGIN
.syntax unified
.text
.extern printf
.align 2
.arm
.thumb
.thumb_func
.globl _$0
_$0:
.endm

.macro NEON_ASM_FUNC_END
mov pc, lr
.endm

NEON_ASM_FUNC_BEGIN ne10_img_rotate_get_quad_rangle_subpix_rgba_neon

/*ARM Registers*/
/* long-term variable */
pDst             .req   r0
pSrc             .req   r1
dstHeight        .req   r4
srcStep          .req   r5
dstStep          .req   r6
countX           .req   r7
countY           .req   r8

/* short-term variable */
/* out of loopY */
srcWidth         .req   r2
srcHeight        .req   r3
dstWidth         .req   r9
pMatrix          .req   r10

/* in loopY */
ixs              .req   r2
iys              .req   r3
pTr0             .req   r9
pTr1             .req   r10

/* temp variable */
tmp0             .req   r11
tmp1             .req   r12





push        {r4-r12, lr}
vpush       {d8-d15}

/* load parameters from sp*/
ldr            dstWidth, [sp, #104]
ldr            dstHeight, [sp, #108]
ldr            pMatrix, [sp, #112]

lsl            srcStep, srcWidth, #2
lsl            dstStep, dstWidth, #2
vld3.f32       {d0, d1, d2}, [pMatrix]

/* set number of loop y  */
mov            countY, dstHeight

/* set NEON register for 1 and 4*/
mov            tmp0, #1
vdup.32        d7, tmp0
vcvt.f32.u32   d23, d7
vshl.s32       d16, d7, #2

vmov            d17, srcWidth, srcHeight
vsub.i32        d6, d17, d16
vsub.i32        d5, d17, d7

/* loop y start */
@cbz            countY, GetQuadrangleSubPixEnd

sub            tmp1, dstWidth, #1
vdup.32        d4, tmp1
vcvt.f32.u32   d4, d4
vmul.f32       d4, d0, d4
GetQuadrangleSubPixLoopY:

sub            tmp0, dstHeight, countY
vdup.32        d3, tmp0
vcvt.f32.u32   d3, d3

/* calculate xs, ys, xe, ye */
vmov.f32       d20, d2
vmla.f32       d20, d1, d3
vadd.f32       d21, d4, d20
vcvt.s32.f32   d22, d20
vcvt.s32.f32   d21, d21
vsub.s32       d16, d22, d7
vsub.s32       d21, d21, d7


vcgt.u32       d16, d6, d16
vcgt.u32       d17, d6, d21
vrev64.32      d30, d16
vrev64.32      d31, d17
vand.32        d16, d16, d30
vand.32        d17, d17, d31
vand.32        d18, d17, d16

/* set number of loop x  */
lsr            countX, dstStep, #2

GetQuadrangleSubPixLoopX:

vcvt.s32.f32   d22, d20
vcvt.f32.s32   d30, d22
vsub.f32       d8, d20, d30
vsub.f32       d9, d23, d8

vcgt.u32       d19, d5, d22
vrev64.32      d30, d19
vand.32        d19, d19, d30

vadd.f32       d20, d20, d0
vorr           d19, d19, d18

/* to avoid that ixs/iys is negative. this will result in bad address of pTr0/pTr1 */
vabs.s32       d22, d22
vmov           ixs, iys, d22
lsl            ixs, ixs, #2
mla            tmp0, srcStep, iys, ixs
add            pTr0, pSrc, tmp0
add            pTr1, pTr0, srcStep

vld1.8         {d26}, [pTr0]
vld1.8         {d28}, [pTr1]
vmovl.u8       q13, d26
vmovl.u8       q14, d28
vmovl.u16      q15, d26
vmovl.u16      q6, d28
vmovl.u16      q5, d27
vmovl.u16      q7, d29
vcvt.f32.u32   q15, q15
vcvt.f32.u32   q6, q6
vcvt.f32.u32   q5, q5
vcvt.f32.u32   q7, q7
vmul.f32       q13, q15, d9[0]
vmul.f32       q14, q6, d9[0]
vmla.f32       q13, q5, d8[0]
vmla.f32       q14, q7, d8[0]
vsub.f32       q15, q14, q13
vmla.f32       q13, q15, d8[1]
vcvt.u32.f32   q5, q13
vmovn.u32      d10, q5
vand.u32       d10, d10, d19
vmovn.u16      d10, q5
vst1.32        {d10[0]}, [pDst]!


subs           countX, countX, #1
bgt            GetQuadrangleSubPixLoopX


subs           countY, countY, #1
bgt            GetQuadrangleSubPixLoopY


GetQuadrangleSubPixEnd:
/*Return From Function*/
vpop           {d8-d15}
pop            {r4-r12, pc}

NEON_ASM_FUNC_END
#endif








