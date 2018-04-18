//
//  Crop_YUVNV12_YUVNV21_Assembly_arm64.S
//  TestCamera
//
//  Created by Rajib Chandra Das on 3/18/18.
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

NEON_ARM_AACH64_FUNC_BEGIN 


NEON_ARM_AACH64_FUNC_BEGIN Crop_YUVNV12_YUVNV21_arm_aarch64
#X0 src
#X1 dest
#X2 rest parameters

inHeight    .req W3
inHeightX   .req X3
inWidth     .req W4
inWidthX    .req X4
startXDiff  .req W5
startXDiffX .req X5
endXDiff    .req W6
endXDiffX   .req X6
startYDiff  .req W7
startYDiffX .req X7
endYDiff    .req W8
endYDiffX   .req X8
temp        .req W9
tempX       .req X9
I           .req W10
J           .req W11
halfH       .req W12
halfW       .req W13
halfStartYDiff          .req W14
halfEndYDiff            .req W15
fragment    .req    W16
fragmentX   .req    X16


LD1 {V0.4S}, [X2], #16
LD1 {V1.4S}, [X2], #16
UMOV inHeight   , V0.S[0]
UMOV inWidth    , V0.S[1]
UMOV startXDiff , V0.S[2]
UMOV endXDiff   , V0.S[3]
UMOV startYDiff , V1.S[0]
UMOV endYDiff   , V1.S[1]


##Calculation for Luminance
MUL temp, inWidth, startYDiff
ADD X0, X0, tempX
MOV I, inHeight
SUB I, I, startYDiff
SUB I, I, endYDiff

Y_HEIGHT_LOOP:
    ADD X0, X0, startXDiffX
    MOV J, inWidth
    SUB J, J, startXDiff
    SUB J, J, endXDiff
ANDS fragment, J, #15
BEQ Y_WIDTH_LOOP
LD1 {V3.16B}, [X0], fragmentX
ST1 {V3.16B}, [X1], fragmentX
SUB J, J, fragment

        Y_WIDTH_LOOP:
            LD1 {V3.16B}, [X0], #16
            ST1 {V3.16B}, [X1], #16
            SUBS J, J, #16
            BNE Y_WIDTH_LOOP
    ADD X0, X0, endXdiffX
    SUBS I, I, #1
    BNE Y_HEIGHT_LOOP
MUL temp, inWidth, endYDiff
ADD X0, X0, tempX

##Calculation for UV
LSR halfH, inHeight, #1
LSR halfW, inWidth, #1
LSR halfStartYDiff, startYDiff, #1
LSR halfEndYDiff, endYDiff, #1

MUL temp, inWidth, halfStartYDiff
ADD X0, X0, tempX
MOV I, halfH
SUB I, I, halfStartYDiff
SUB I, I, halfEndYDiff

UV_HEIGHT_LOOP:
    ADD X0, X0, startXDiffX
    MOV J, inWidth
    SUB J, J, startXDiff
    SUB J, J, endXDiff
ANDS fragment, J, #15
BEQ UV_WIDTH_LOOP
LD1 {V3.16B}, [X0], fragmentX
ST1 {V3.16B}, [X1], fragmentX
SUB J, J, fragment

    UV_WIDTH_LOOP:
        LD1 {V3.16B}, [X0], #16
        ST1 {V3.16B}, [X1], #16
        SUBS J, J, #16
        BNE UV_WIDTH_LOOP
    ADD X0, X0, endXdiffX
    SUBS I, I, #1
    BNE UV_HEIGHT_LOOP

NEON_ARM_AACH64_FUNC_END

#endif
