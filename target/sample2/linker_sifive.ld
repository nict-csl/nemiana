/*ENTRY(_start)*/
ENTRY(_start);
EXTERN(abort);

_Min_heap_size  = 0x0010;
_Min_stack_size = 0x0010;
/*
*
*        flash (rxai!w) : ORIGIN = 0x08000000, LENGTH = 128k
*        ram   (wxa!ri) : ORIGIN = 0x20000000, LENGTH = 32K
*/
MEMORY
{
    rom   : ORIGIN = 0x20010000, LENGTH = 0x8000
    ram   : ORIGIN = 0x80000000, LENGTH = 0x4000
}

SECTIONS
{
    /* text: Program code section */
    .init : {
       KEEP(*(.init))
       *(.boot);

    } >rom
   . = ALIGN( 0x10 );
   .text :
    {
        *(.text. text.*);
	*(.comment);
    } >rom
    . = ALIGN( 0x10 );
    /* rodata: Read-only data */
    .rodata :
    {
        *(.rdata .rodata. rodata.*);
    } >ram
    . = ALIGN( 0x10 );
    .eh_frame :
    {
        *(.eh_frame .eh_frame.*);
    } >ram
    . = ALIGN( 0x10 );
    /* data: Writable data */
    .data :
    {
        *(.data .data.* .sdata);
    } >ram
    . = ALIGN( 0x10 );
    _bss_start = .;
    .bss :
    {
        *(.bss .bss.*);
    } >ram
    _bss_end = .;
    _heap_start = . ;
    . += _Min_heap_size;
    _heap_end = .;
    . = ALIGN( 0x10 );
    .riscv.attributes 0: { *(.riscv.attributes) }
}
