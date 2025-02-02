//
//  Neon_Assembly.s
//  TestCamera 
//
//  Created by Rajib Chandra Das on 7/26/17.
//
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


NEON_ASM_FUNC_BEGIN convert_arm_neon

# r0: Ptr to destination data
# r1: Ptr to source data
# r2: Iteration count:

push   	    {r4-r5,lr}
lsr         r2, r2, #3

# build the three constants:
mov         r3, #77
mov         r4, #151
mov         r5, #28
vdup.8      d3, r3
vdup.8      d4, r4
vdup.8      d5, r5

.loop:

# load 8 pixels:
vld3.8      {d0-d2}, [r1]!

# do the weight average:
vmull.u8    q3, d0, d3
vmlal.u8    q3, d1, d4
vmlal.u8    q3, d2, d5

# shift and store:
vshrn.u16   d6, q3, #8
vst1.8      {d6}, [r0]!

subs        r2, r2, #1
bne         .loop
pop         { r4-r5, pc }

NEON_ASM_FUNC_END

NEON_ASM_FUNC_BEGIN add_arm_neon
# r0: Ptr to destination data
# r1: Ptr to source data
# r2: Iteration count:
push {r4-r5,lr}

add  r2, r2, #7
lsr  r2, r2, #3

#mov r4, #1
VMOV.U8 D1, #1


.loopA:
subs    r2, r2, #1
vld1.u8  {d0}, [r1]!

vadd.u8 d0, d0, d1

vst1.u8  {d0}, [r0]!

bne  .loopA

pop { r4-r5, pc }

NEON_ASM_FUNC_END

NEON_ASM_FUNC_BEGIN copy_arm_neon
# r0: Ptr to destination data
# r1: Ptr to source data
# r2: Iteration count:
push {r4-r5,lr}

.Copy_arm_neon_loop:
subs    r2, r2, #32
vld1.u8  {d0-d3}, [r0]!
vst1.u8  {d0-d3}, [r1]!
bne  .Copy_arm_neon_loop


pop { r4-r5, pc }

NEON_ASM_FUNC_END

NEON_ASM_FUNC_BEGIN convert_nv12_to_i420_arm_neon
# r0: Ptr to source data
# r1: Ptr to destination data
# r2: height
# r3: width
push {r4-r8,lr}
mul r4, r2, r3
mov r5, r4

### Y-Values
ands r8, r4, #7
beq .convert_nv12_to_i420_arm_neon_loop_Y
vld1.u8 {d0}, [r0], r8
vst1.u8 {d0}, [r1], r8
subs r4, r4, r8

.convert_nv12_to_i420_arm_neon_loop_Y:
vld1.u8  {d0}, [r0]!
vst1.u8  {d0}, [r1]!
subs    r4, r4, #8
bne  .convert_nv12_to_i420_arm_neon_loop_Y

mov r6, r0
mov r7, r0

### U-Values
lsrs r4, r5, #1
ands r8, r4, #15
beq .convert_nv12_to_i420_arm_neon_loop_U
vld2.u8 {d0,d1}, [r6], r8
subs r4, r4, r8
lsrs r8, r8, #1
vst1.u8 {d0}, [r1], r8

.convert_nv12_to_i420_arm_neon_loop_U:
vld2.u8 {d0, d1}, [r6]!
vst1.u8 {d0}, [r1]!
subs    r4, r4, #16
bne  .convert_nv12_to_i420_arm_neon_loop_U


### V-Values
lsrs r4, r5, #1
ands r8, r4, #15
beq .convert_nv12_to_i420_arm_neon_loop_V
vld2.u8 {d0,d1}, [r7], r8
subs r4, r4, r8
lsrs r8, r8, #1
vst1.u8 {d1}, [r1], r8

.convert_nv12_to_i420_arm_neon_loop_V:
vld2.u8 {d0, d1}, [r7]!
vst1.u8 {d1}, [r1]!
subs    r4, r4, #16
bne  .convert_nv12_to_i420_arm_neon_loop_V

pop { r4-r8, pc }

NEON_ASM_FUNC_END

.section	__TEXT,__cstring,cstring_literals
output:                               ; @.str
.asciz	"Is this ok.. The Value FF is: %d Yes I am done\n"

NEON_ASM_FUNC_BEGIN learn_arm_neon
#no parameters
push {r4-r8,lr}

mov r0, #0x4
mov r1, #0x2
mov r6, #0x8
mov r7, #0x16
vdup.u8 d0, r0
vmov.u8 d1, d0


bl add_function

mov r1, r6
ldr r0,=output
bl	_printf




vdup.8  q3, r1
vmov d0, r0, r1



vmov.32 r0, d0[1]

mov r0, #0xDDAA
mov r1, #0xFACD
vmov d1, r0, r1
vceq.u16 d2, d0, d1

mov r0, #0xCCFF
mov r1, #0xAADD

vmov d0, r0, r1

vqadd.u8 d1, d0, d0

vpaddl.u8 d0, d0
vpadal.u8 d0, d0


mov r4, #1
mov r5, #10
.rept 10
adds r4, r4, #1
.endr



pop { r4-r8, pc }
NEON_ASM_FUNC_END


NEON_ASM_FUNC_BEGIN crop_yuv420_arm_neon
#r0 src data
#r1 dst data
#r2 parameters sequence: { inHeight, inWidth, startXDiff, endXDiff, startYDiff, endYDiff, outHeight, outWidth}
push {r3-r11,lr}
vld1.u32 {d0}, [r2]!
vmov r3, r4, d0
vld1.u32 {d1}, [r2]!
vmov r5, r6, d1
vld1.u32 {d2}, [r2]!
vmov r7, r8, d2
vld1.u32 {d3}, [r2]!

#r3 = inHeight, r4 = inWidth, r5 = startXDiff and j, r6 = endXDiff, r7 = startYDiff and i, r8 = endYDiff
#r9 = using as a temporary variable

#Start Process Y
mul r9, r7, r4
add r0, r0, r9

sub r8, r3, r8
.crop_yuv420_arm_neon_Y_Height:

    vmov r5, r6, d1
    add r0, r0, r5
    sub r6, r4, r6

    sub r9, r6, r5

    ands r9, r9, #7
    beq .crop_yuv420_arm_neon_Y_Width
    vld1.u8 {d4}, [r0], r9
    vst1.u8 {d4}, [r1], r9
    add r5, r5, r9
    #add r0, r0, r9

    cmp r5, r6
    beq .crop_yuv420_arm_neon_Y_Width_end

    .crop_yuv420_arm_neon_Y_Width:
        vld1.u8 {d4}, [r0]!
        vst1.u8 {d4}, [r1]!

        add r5, r5, #8
        cmp r5, r6
        bne .crop_yuv420_arm_neon_Y_Width
.crop_yuv420_arm_neon_Y_Width_end:
    vmov r5, r6, d1
    add r0, r0, r6

    add r7, r7, #1
    cmp r7, r8
    bne .crop_yuv420_arm_neon_Y_Height

vmov r3, r4, d0
vmov r5, r6, d1
vmov r7, r8, d2

mul r9, r8, r4
add r0, r0, r9




vshr.u32 d0, d0, #1
vshr.u32 d1, d1, #1
vshr.u32 d2, d2, #1

mov r11, #0

#Now Ready to process UV
.crop_yuv420_arm_neon_UV_Process:
vmov r3, r4, d0
vmov r5, r6, d1
vmov r7, r8, d2

mul r9, r7, r4
add r0, r0, r9
sub r8, r3, r8
.crop_yuv420_arm_neon_UV_Height:

    vmov r5, r6, d1
    add r0, r0, r5
    sub r6, r4, r6

    sub r9, r6, r5
    ands r9, r9, #7
    beq .crop_yuv420_arm_neon_UV_Width
    vld1.u8 {d4}, [r0], r9
    vst1.u8 {d4}, [r1], r9

    add r5, r5, r9
    cmp r5, r6
    beq .crop_yuv420_arm_neon_UV_Width_end

    .crop_yuv420_arm_neon_UV_Width:
        vld1.u8 {d4}, [r0]!
        vst1.u8 {d4}, [r1]!
        add r5, r5, #8
        cmp r5, r6
        bne .crop_yuv420_arm_neon_UV_Width
    
    .crop_yuv420_arm_neon_UV_Width_end:
vmov r5, r6, d1
add r0, r0, r6
add r7, r7, #1
cmp r7, r8
bne .crop_yuv420_arm_neon_UV_Height

vmov r3, r4, d0
vmov r5, r6, d1
vmov r7, r8, d2

mul r9, r8, r4
add r0, r0, r9
add r11, r11, #1
cmp r11, #2
bne .crop_yuv420_arm_neon_UV_Process




pop { r3-r11, pc }
NEON_ASM_FUNC_END

NEON_ASM_FUNC_BEGIN CalculateSumOfLast64_ARM_NEON
#r0 First parameter, This is the address of <pData>
#r1 Second Parameter, This is the address of <ans>
push {r2-r8, lr}
mov r4, r0

mov r5, #192
.skipLoop:
vld1.u32 {d0}, [r4]!
subs r5, #2
bne .skipLoop

mov r8, #0
mov r5, #64
.calculationLoop:
vld1.u32 {d0}, [r4]!
vmov r7, r6, d0
add r8, r8, r6;
add r8, r8, r7;
subs r5, #2
bne .calculationLoop

str r8, [r1]

pop {r2-r8, pc}

NEON_ASM_FUNC_END

NEON_ASM_FUNC_BEGIN Reverse_array_arm_neon
push {r3-r8, lr}
pInData     .req    r0
iLen        .req    r1
pOutData    .req    r2
iOverlap    .req    r3
iTemp       .req    r4

add         pOutData,   pOutData,   iLen
add         pOutData,   pOutData,   #8
ands        iOverlap,   iLen,       #7

beq         loop_Reverse //if(iLen % 8 == 0) goto loop_Reverse

sub         pOutData,   pOutData,   #16
vld1.u8     {d0},       [pInData]!
vrev64.u8   d1,         d0
vst1.u8     {d1},       [pOutData]!
subs        iLen,       iLen,       iOverlap
beq Reverse_array_arm_neon_completed //if(iLen == 0) go to end

mov         iTemp,      #8
sub         iTemp,      iTemp,      iOverlap
sub         pInData,    pInData,    iTemp
add         pOutData,   pOutData,   iTemp

loop_Reverse:
    vld1.u8     {d0},       [pInData]!
    vrev64.u8   d1,         d0
    sub         pOutData,   pOutData, #16
    vst1.u8     {d1},       [pOutData]!
    subs        iLen,        #8
    bne loop_Reverse

Reverse_array_arm_neon_completed:

pop {r3-r8, pc}
NEON_ASM_FUNC_END

#int add_function(int a, int b);
add_function:
add r6, r6, r7
BX     lr


// Written by Jake 'Alquimista' LEE

NEON_ASM_FUNC_BEGIN Reverse_array_arm_neon_version2
// void Reverse_array_arm_neon(unsigned char* pInData, int iLen, unsigned char* pOutData);
pSrc    .req    r0
iLen    .req    r1
pDst    .req    r2
postInc .req    r3



add     pDst, pDst, iLen
mov     postInc, #-32
sub     pDst, pDst, #32
sub     iLen, iLen, #64     // "withholding tax"

1:
vld1.8      {d16, d17, d18, d19}, [pSrc]!
vld1.8      {d20, d21, d22, d23}, [pSrc]!
subs    iLen, iLen, #64

vrev64.8    q8, q8
vrev64.8    q9, q9
vrev64.8    q10, q10
vrev64.8    q11, q11

vswp        d19, d16
vswp        d18, d17
vswp        d23, d20
vswp        d22, d21

vst1.8      {d16, d17, d18, d19}, [pDst], postInc
vst1.8      {d20, d21, d22, d23}, [pDst], postInc

bpl     1b
add     pSrc, pSrc, iLen
cmp     iLen, #-64
sub     pDst, pDst, iLen
bxle    lr      // return
b       1b
NEON_ASM_FUNC_END

#endif


