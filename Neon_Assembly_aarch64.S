//
//  IPV-MediaEngine
//  color_converter_arm_neon_aarch64.s
//
//
//  Created by Rajib Chandra Das on 7/26/17.
//
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

.section	__TEXT,__cstring,cstring_literals
output:                               ; @.str
.asciz	"Is this ok.. The Value FF is: %d Yes I am done\n"

NEON_ARM_AACH64_FUNC_BEGIN convert_nv12_to_i420_arm_neon
# x0: Ptr to source data
# x1: Ptr to destination data
# x2: height
# x3: width
MUL X4, X2, X3
MOV X5, X4

### Y-Values
ANDS X8, X4, #15
BEQ .convert_nv12_to_i420_arm_neon_loop_Y
LD1 {V0.16B}, [X0], X8
ST1 {V0.16B}, [X1], X8
SUBS X4, X4, X8
.convert_nv12_to_i420_arm_neon_loop_Y:
LD1 {V0.16B}, [X0], #16
ST1 {V0.16B}, [X1], #16
SUBS X4, X4, #16
BNE .convert_nv12_to_i420_arm_neon_loop_Y

MOV X6, X0
MOV X7, X0

### U-Values
LSR X4, X5, #1
ANDS X8, X4, #31
BEQ .convert_nv12_to_i420_arm_neon_loop_U
LD2 {V0.16B,V1.16B}, [X6], X8
SUBS X4, X4, X8
LSR X8, X8, #1
ST1 {V0.16B}, [X1], X8

.convert_nv12_to_i420_arm_neon_loop_U:

LD2 {V0.16B, V1.16B}, [X6], #32
ST1 {V0.16B}, [X1], #16
SUBS    X4, X4, #32
BNE  .convert_nv12_to_i420_arm_neon_loop_U


### V-Values
LSR X4, X5, #1
ANDS X8, X4, #31
BEQ .convert_nv12_to_i420_arm_neon_loop_V
LD2 {V0.16B,V1.16B}, [X7], X8
SUBS X4, X4, X8
LSR X8, X8, #1
ST1 {V1.16B}, [X1], X8

.convert_nv12_to_i420_arm_neon_loop_V:
LD2 {V0.16B, V1.16B}, [X7], #32
ST1 {V1.16B}, [X1], #16
SUBS X4, X4, #32
BNE  .convert_nv12_to_i420_arm_neon_loop_V

NEON_ARM_AACH64_FUNC_END



NEON_ARM_AACH64_FUNC_BEGIN crop_yuv420_arm_neon
#X0 src data
#X1 dst data
#X2 parameters sequence: { inHeight, inWidth, startXDiff, endXDiff, startYDiff, endYDiff, outHeight, outWidth}

LD1 {V0.4S}, [X2], #16
UMOV W3, V0.S[0]
UMOV W4, V0.S[1]
UMOV W5, V0.S[2]
UMOV W6, V0.S[3]

LD1 {V1.2S}, [X2], #8
UMOV W7, V1.S[0]
UMOV W8, V1.S[1]
#r3 = inHeight, r4 = inWidth, r5 = startXDiff and j, r6 = endXDiff, r7 = startYDiff and i, r8 = endYDiff
#r9 = using as a temporary variable

#Start Process Y
MUL W9, W7, W4
ADD X0, X0, X9
SUB W8, W3, W8

.crop_yuv420_arm_neon_Y_Height:
UMOV W5, V0.S[2]
UMOV W6, V0.S[3]

ADD X0, X0, X5
SUB W6, W4, W6
SUB W9, W6, W5

ANDS W9, W9, #15
BEQ .crop_yuv420_arm_neon_Y_Width
LD1 {V4.16B}, [X0], X9
ST1 {V4.16B}, [X1], X9
ADD W5, W5, W9
#add r0, r0, r9
CMP W5, W6
BEQ .crop_yuv420_arm_neon_Y_Width_end

.crop_yuv420_arm_neon_Y_Width:
LD1 {V4.16B}, [X0], #16
ST1 {V4.16B}, [X1], #16

ADD W5, W5, #16
CMP W5, W6
BNE .crop_yuv420_arm_neon_Y_Width
.crop_yuv420_arm_neon_Y_Width_end:
UMOV W5, V0.S[2]
UMOV W6, V0.S[3]
ADD X0, X0, X6

ADD W7, W7, #1
CMP W7, W8
BNE .crop_yuv420_arm_neon_Y_Height

UMOV W3, V0.S[0]
UMOV W4, V0.S[1]
UMOV W5, V0.S[2]
UMOV W6, V0.S[3]
UMOV W7, V1.S[0]
UMOV W8, V1.S[1]

MUL W9, W8, W4
ADD X0, X0, X9

USHR V0.4S, V0.4S, #1
USHR V1.2S, V1.2S, #1
MOV W11, #0

#Now Ready to process UV
.crop_yuv420_arm_neon_UV_Process:
UMOV W3, V0.S[0]
UMOV W4, V0.S[1]
UMOV W5, V0.S[2]
UMOV W6, V0.S[3]
UMOV W7, V1.S[0]
UMOV W8, V1.S[1]

MUL W9, W7, W4
ADD X0, X0, X9
SUB W8, W3, W8
.crop_yuv420_arm_neon_UV_Height:
UMOV W5, V0.S[2]
UMOV W6, V0.S[3]
ADD X0, X0, X5
SUB W6, W4, W6

SUB W9, W6, W5
ANDS W9, W9, #15
BEQ .crop_yuv420_arm_neon_UV_Width
LD1 {V4.16B}, [X0], X9
ST1 {V4.16B}, [X1], X9

ADD W5, W5, W9
CMP W5, W6
BEQ .crop_yuv420_arm_neon_UV_Width_end

.crop_yuv420_arm_neon_UV_Width:
LD1 {V4.16B}, [X0], #16
ST1 {V4.16B}, [X1], #16
ADD W5, W5, #16
CMP W5, W6
BNE .crop_yuv420_arm_neon_UV_Width

.crop_yuv420_arm_neon_UV_Width_end:
UMOV W5, V0.S[2]
UMOV W6, V0.S[3]
ADD X0, X0, X6
ADD W7, W7, #1
CMP W7, W8
BNE .crop_yuv420_arm_neon_UV_Height

UMOV W3, V0.S[0]
UMOV W4, V0.S[1]
UMOV W5, V0.S[2]
UMOV W6, V0.S[3]
UMOV W7, V1.S[0]
UMOV W8, V1.S[1]

MUL W9, W8, W4
ADD X0, X0, X9
ADD W11, W11, #1
CMP W11, #2
BNE .crop_yuv420_arm_neon_UV_Process

MOV X14, #69

MOV W1, W14




NEON_ARM_AACH64_FUNC_END



NEON_ARM_AACH64_FUNC_BEGIN convert_arm_neon

NEON_ARM_AACH64_FUNC_END



NEON_ARM_AACH64_FUNC_BEGIN add_arm_neon

NEON_ARM_AACH64_FUNC_END


NEON_ARM_AACH64_FUNC_BEGIN copy_arm_neon

NEON_ARM_AACH64_FUNC_END


NEON_ARM_AACH64_FUNC_BEGIN learn_arm_neon

NEON_ARM_AACH64_FUNC_END


NEON_ARM_AACH64_FUNC_BEGIN CalculateSumOfLast64_ARM_NEON

NEON_ARM_AACH64_FUNC_END

NEON_ARM_AACH64_FUNC_BEGIN Reverse_array_arm_neon
pInData     .req    x0
iLen        .req    x1
pOutData    .req    x2
iOverlap    .req    x3
iTemp       .req    x4

add         pOutData,   pOutData,   iLen
add         pOutData,   pOutData,   #8
ands        iOverlap,   iLen,       #7

beq         loop_Reverse //if(iLen % 8 == 0) goto loop_Reverse

sub         pOutData,   pOutData,   #16
ld1     {V0.8B},       [pInData], iOverlap
rev64   V1.8B,         V0.8B
st1     {V1.8B},       [pOutData], #8
subs        iLen,       iLen,       iOverlap
beq Reverse_array_arm_neon_completed //if(iLen == 0) go to end

mov         iTemp,      #8
sub         iTemp,      iTemp,      iOverlap
sub         pInData,    pInData,    iTemp
add         pOutData,   pOutData,   iTemp

loop_Reverse:
LD1     {V0.8B},       [pInData], #8
rev64   V1.8B,         V0.8B
sub         pOutData,   pOutData, #16
st1     {V1.8B},       [pOutData], #8
subs        iLen,    iLen,    #8
bne loop_Reverse

Reverse_array_arm_neon_completed:
NEON_ARM_AACH64_FUNC_END

branchCheck:


#endif


