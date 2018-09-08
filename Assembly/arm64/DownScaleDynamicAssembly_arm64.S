//
//  DownScaleDynamicAssembly_arm64.S
//  TestCamera
//
//  Created by Rajib Chandra Das on 7/18/18.
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




NEON_ARM_AACH64_FUNC_BEGIN InitializeCumulativeSumForY_arm_aarch64
inHeight            .req    x0
inWidth             .req    x1
pData               .req    x2
CumulativeSumY      .req    x3
I                   .req    x12
J                   .req    x11
iw                  .req    x4
ptrToData           .req    x5
ptrToSum            .req    x6
value               .req    x7
value2              .req    x10
valueW               .req    w7
value2W              .req    w10
indx1               .req    x8
indx2               .req    x9

MOV I, #1
MOV iw, inWidth
MOV ptrToData, pData
MOV ptrToSum, CumulativeSumY


LDR value, [ptrToData]
AND value, value, 0xFF
STR value, [ptrToSum]

Y_HEIGHT_LOOP:
    MOV indx1 , I
    MUL indx1, indx1, inWidth
    LSL indx1, indx1, #2

    MOV indx2, I
    SUB indx2, indx2, #1
    MUL indx2, indx2, inWidth
    LSL indx2, indx2, #2

    ADD ptrToData, pData, iw
    LDR value , [ptrToData]
    AND value, value, 0xFF

    ADD ptrToSum, CumulativeSumY, indx2
    LDR value2, [ptrToSum]
    ADD value, value, value2


    ADD ptrToSum, CumulativeSumY, indx1
    //LSL value, value, #32
    STR valueW, [ptrToSum]

    ADD I, I, #1
    ADD iw, iw, inWidth
    CMP I, inHeight

    bne Y_HEIGHT_LOOP


MOV J, #1

X_WIDTH_LOOP:

    ADD ptrToData, pData, J
    LDR valueW, [ptrToData]
    AND valueW, valueW, 0xFF

    MOV indx1, J
    SUB indx1, indx1, #1
    LSL indx1, indx1, #2

    ADD ptrToSum, CumulativeSumY, indx1
    LDR value2W, [ptrToSum]

    ADD valueW, valueW, value2W

    MOV indx2, J
    LSL indx2, indx2, #2
    ADD ptrToSum, CumulativeSumY, indx2
    STR valueW, [ptrToSum]

    ADD J, J, #1
    CMP J, inWidth
    BNE X_WIDTH_LOOP



MOV I , #1
MOV iw, inWidth
MOV ptrToSum, CumulativeSumY
MOV ptrToData, pData

HeightLoop:
    MOV J, #1
    WidthLoop:
        MOV indx1 , #4
        LD1 {V0.4S}, [ptrToSum], #16
        LD1 {V1.8B}, [ptrToData], indx1

        



NEON_ARM_AACH64_FUNC_END

//for (int i = 1, iw = inWidth; i<inHeight; i++, iw += inWidth)
//{
//    for (int j = 1; j<inWidth; j++)
//    {
//        CumulativeSum2[i * inWidth + j] = (int)(CumulativeSum2[i * inWidth + (j - 1)] + CumulativeSum2[(i - 1) * inWidth + j] - CumulativeSum2[(i - 1) * inWidth + (j - 1)] + pData[iw + j]);
//    }
//}



#endif
