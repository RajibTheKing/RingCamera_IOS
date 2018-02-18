
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



NEON_ARM_AACH64_FUNC_BEGIN Rotate90Degree_arm_neon_aarch64
pInData     .req        x0
pOutData    .req        x1
iHeight     .req        x2
iWidth      .req        x3
row         .req        x4
col         .req        x5
pTempData   .req        W6
temp        .req        x8
halfH       .req        x9
halfW       .req        x10
uData       .req        x11
vData       .req        x12
uDataOut    .req        x13
vDataOut    .req        x14



mov col , iWidth
sub col, col, #1

WidthLoop:

    mov row, #0

    HeightLoop:
        mov temp, row
        mul temp, temp, iWidth
        add temp, temp, col


        LDRB pTempData, [pInData, temp]
        STRB pTempData, [pOutData], #1


        adds row, row, #1
        cmp row, iHeight
        bne HeightLoop

    sub col, col, #1
    cmp col, #-1
    bne WidthLoop

//Initialize uData
mul temp, iHeight, iWidth
mov uData, pInData
add uData, uData, temp

//Initialize vData
LSR halfH, iHeight, #1
LSR halfW, iWidth,  #1
mul temp, halfH, halfW
mov vData, uData
add vData, vData, temp

mov uDataOut, pOutData
mov vDataOut, pOutData
add vDataOut, vDataOut, temp

mov col , halfW
sub col, col, #1

WidthLoop_UV:

    mov row, #0

    HeightLoop_UV:
        mov temp, row
        mul temp, temp, halfW
        add temp, temp, col


        LDRB pTempData, [uData, temp]
        STRB pTempData, [uDataOut], #1

        LDRB pTempData, [vData, temp]
        STRB pTempData, [vDataOut], #1


        adds row, row, #1
        cmp row, halfH
        bne HeightLoop_UV

    sub col, col, #1
    cmp col, #-1
bne WidthLoop_UV



NEON_ARM_AACH64_FUNC_END

#endif


