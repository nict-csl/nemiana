.option norvc
.section .boot, "ax",@progbits
.global _start
.global abort
_start:
	li  x1, 0x10
	li  x2, 0x20
	li  x3, 0x30
	li  x4, 0x40
	li  x5, 0x50
	li  x6, 0x60
	li  x7, 0x70
	li  x8, 0x80
	li  x9, 0x90		
	li  x10, 0x100
	li  x11, 0x110	
	li  x12, 0x110
	li  x13, 0x130
	li  x14, 0x140
	li  x15, 0x150
	li  x16, 0x100
	li  x17, 0xDEADBEEF
	li  x18, 0x0ABCDEF
	li  x19, 0x121212
	li  x20, 0x234567
	li  x21, 0x210
	li  x22, 0x220
	li  x23, 0x230
	li  x24, 0x240
	li  x25, 0x250
	li  x26, 0x260
	li  x27, 0x270
	li  x28, 0x280
	li  x29, 0x290		
	li  x30, 0x300
	li  x31, 0x310	
	/* Set up stack pointer. */
	li sp,0x0
/*	li sp,0x80010000*/
	li sp,0x80004000
/*	li sp,0x20008000 */

    /* Now jump to the rust world; __start_rust.  */
    j       notmain

	.globl PUT32
PUT32:
	sw x11, (x10)
	ret

	.globl GET32
GET32:
	lw x10, (x10)
	ret

/* */
/* ret = *a0; *a0 = a1 */	
/*
	.globl AMOSWAP
AMOSWAP:
	amoswap.w x10, x11, (x10)
        ret	
*/
