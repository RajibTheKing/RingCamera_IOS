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


//void CColorConverter::mirrorYUVI420(unsigned char *pInData, unsigned char *pOutData, int iHeight, int iWidth)
NEON_ASM_FUNC_BEGIN mirror_YUV420_arm_neon
push {r4-r8, lr}
pInData     .req    r0
pOutData    .req    r1
iHeight     .req    r2
iWidth      .req    r3
iYlen       .req    r4
iUVlen      .req    r5
iH          .req    r6
iOverlap    .req    r7
iTemp       .req    r8
iLen        .req    r9


mov         iH,         0
mirror_YUV420_Y_Hloop:
    mov         iLen,       iWidth
    add         pOutData,   pOutData,   iLen
    add         pOutData,   pOutData,   #8
    ands        iOverlap,   iLen,       #7
    beq         mirror_YUV420_loop_Reverse //if(iLen % 8 == 0) goto mirror_YUV420_loop_Reverse

    sub         pOutData,   pOutData,   #16
    vld1.u8     {d0},       [pInData]!
    vrev64.u8   d1,         d0
    vst1.u8     {d1},       [pOutData]!
    subs        iLen,       iLen,       iOverlap
    beq mirror_YUV420_Reverse_array_completed //if(iLen == 0) go to end

    mov         iTemp,      #8
    sub         iTemp,      iTemp,      iOverlap
    sub         pInData,    pInData,    iTemp
    add         pOutData,   pOutData,   iTemp

    mirror_YUV420_loop_Reverse:
        vld1.u8     {d0},       [pInData]!
        vrev64.u8   d1,         d0
        sub         pOutData,   pOutData, #16
        vst1.u8     {d1},       [pOutData]!
        subs        iLen,        #8
        bne mirror_YUV420_loop_Reverse

    mirror_YUV420_Reverse_array_completed:

    sub         pOutData,   pOutData,   #8
    add         pOutData,   pOutData,   iWidth
    add         iH,         iH,         #1
    cmp         iH,         iHeight

    bne mirror_YUV420_Y_Hloop //Height Loop for Y Data


mov         iH,         0
lsr         iWidth,     iWidth,     #1
mirror_YUV420_UV_Hloop:
mov         iLen,       iWidth
add         pOutData,   pOutData,   iLen
add         pOutData,   pOutData,   #8
ands        iOverlap,   iLen,       #7
beq         mirror_YUV420_loop_UV_Reverse //if(iLen % 8 == 0) goto mirror_YUV420_loop_UV_Reverse

sub         pOutData,   pOutData,   #16
vld1.u8     {d0},       [pInData]!
vrev64.u8   d1,         d0
vst1.u8     {d1},       [pOutData]!
subs        iLen,       iLen,       iOverlap
beq mirror_YUV420_Reverse_array_UV_completed //if(iLen == 0) go to end

mov         iTemp,      #8
sub         iTemp,      iTemp,      iOverlap
sub         pInData,    pInData,    iTemp
add         pOutData,   pOutData,   iTemp

mirror_YUV420_loop_UV_Reverse:
vld1.u8     {d0},       [pInData]!
vrev64.u8   d1,         d0
sub         pOutData,   pOutData, #16
vst1.u8     {d1},       [pOutData]!
subs        iLen,        #8
bne mirror_YUV420_loop_UV_Reverse

mirror_YUV420_Reverse_array_UV_completed:

sub         pOutData,   pOutData,   #8
add         pOutData,   pOutData,   iWidth
add         iH,         iH,         #1
cmp         iH,         iHeight

bne mirror_YUV420_UV_Hloop //Height Loop for uv Data






pop {r4-r8, pc}
NEON_ASM_FUNC_END

#endif


