//
//  DownScaleDynamicAssembly_arm32.S
//  TestCamera
//
//  Created by Rajib Chandra Das on 7/18/18.
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




#endif
