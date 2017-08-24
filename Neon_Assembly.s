//
//  Neon_Assembly.s
//  TestCamera 
//
//  Created by Rajib Chandra Das on 7/26/17.
//
//

.syntax unified
.text
.macro NEON_ASM_FUNC_BEGIN
.align 2
.arm
.globl _$0
_$0:
.endm

.macro NEON_ASM_FUNC_END
mov pc, lr
.endm


NEON_ASM_FUNC_BEGIN convert_asm_neon

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

NEON_ASM_FUNC_BEGIN add_asm_neon
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

NEON_ASM_FUNC_BEGIN copy_asm_neon
# r0: Ptr to destination data
# r1: Ptr to source data
# r2: Iteration count:
push {r4-r5,lr}

.Copy_asm_neon_loop:
subs    r2, r2, #32
vld1.u8  {d0-d3}, [r0]!
vst1.u8  {d0-d3}, [r1]!
bne  .Copy_asm_neon_loop


pop { r4-r5, pc }

NEON_ASM_FUNC_END

NEON_ASM_FUNC_BEGIN convert_nv12_to_i420_asm_neon
# r0: Ptr to source data
# r1: Ptr to destination data
# r2: height
# r3: width
push {r4-r8,lr}
mul r4, r2, r3
mov r5, r4

### Y-Values
ands r8, r4, #7
beq .convert_nv12_to_i420_asm_neon_loop_Y
vld1.u8 {d0}, [r0], r8
vst1.u8 {d0}, [r1], r8
subs r4, r4, r8

.convert_nv12_to_i420_asm_neon_loop_Y:
vld1.u8  {d0}, [r0]!
vst1.u8  {d0}, [r1]!
subs    r4, r4, #8
bne  .convert_nv12_to_i420_asm_neon_loop_Y

mov r6, r0
mov r7, r0

### U-Values
lsrs r4, r5, #1
ands r8, r4, #15
beq .convert_nv12_to_i420_asm_neon_loop_U
vld2.u8 {d0,d1}, [r6], r8
subs r4, r4, r8
lsrs r8, r8, #1
vst1.u8 {d0}, [r1], r8

.convert_nv12_to_i420_asm_neon_loop_U:
vld2.u8 {d0, d1}, [r6]!
vst1.u8 {d0}, [r1]!
subs    r4, r4, #16
bne  .convert_nv12_to_i420_asm_neon_loop_U


### V-Values
lsrs r4, r5, #1
ands r8, r4, #15
beq .convert_nv12_to_i420_asm_neon_loop_V
vld2.u8 {d0,d1}, [r7], r8
subs r4, r4, r8
lsrs r8, r8, #1
vst1.u8 {d1}, [r1], r8

.convert_nv12_to_i420_asm_neon_loop_V:
vld2.u8 {d0, d1}, [r7]!
vst1.u8 {d1}, [r1]!
subs    r4, r4, #16
bne  .convert_nv12_to_i420_asm_neon_loop_V

pop { r4-r8, pc }

NEON_ASM_FUNC_END

NEON_ASM_FUNC_BEGIN learn_asm_neon
#no parameters
push {r4-r8,lr}
mov r0, #0x4
mov r1, #0x2
add r2, r0, r1, LSL #1

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


#for(int i=startYDiff; i<(inHeight-endYDiff); i++)
#{
#    for(int j=startXDiff; j<(inWidth-endXDiff); j++)
#    {
#        outputData[indx++] = pData[i*inWidth + j];
#    }
#}
NEON_ASM_FUNC_BEGIN crop_yuv420_arm_neon
#r0 src data
#r1 dst data
#r2 parameters sequence: { inHeight, inWidth, startXDiff, endXDiff, startYDiff, endYDiff }
push {r3-r11,lr}
vld1.u32 {d0}, [r2]!
vmov r3, r4, d0
vld1.u32 {d1}, [r2]!
vmov r5, r6, d1
vld1.u32 {d2}, [r2]!
vmov r7, r8, d2

#r3 = inHeight, r4 = inWidth, r5 = startXDiff and j, r6 = endXDiff, r7 = startYDiff and i, r8 = endYDiff
#r9 = using as a temporary variable

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
    vld1.u8 {d3}, [r0], r9
    vst1.u8 {d3}, [r1], r9
    add r5, r5, r9
    #add r0, r0, r9


    .crop_yuv420_arm_neon_Y_Width:
        vld1.u8 {d3}, [r0]!
        vst1.u8 {d3}, [r1]!

        add r5, r5, #8
        cmp r5, r6
        bne .crop_yuv420_arm_neon_Y_Width

    vmov r5, r6, d1
    add r0, r0, r6

    add r7, r7, #1
    cmp r7, r8
    bne .crop_yuv420_arm_neon_Y_Height

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
