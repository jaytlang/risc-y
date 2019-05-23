/* This linker script provides the following symbols:
 *  _end        - the start of the heap
 *  _heap_limit - the end of the heap
 *  _stack_top  - the top of the stack
 */

OUTPUT_ARCH( "riscv" )
ENTRY( _start )

MEMORY
{
    ram (rwx) : ORIGIN = 0x00000000, LENGTH = 0x00010000 /* 64 KB */
}

SECTIONS
{
    .text.init : {
        /* put the .text.init section at the begining */
        KEEP( *(.text.init) )
    } > ram
    .text : {
        *(.text)
    } > ram

    /* data segment */
    .sdata : {
        *(.srodata.cst16
          .srodata.cst8
          .srodata.cst4
          .srodata.cst2
          .srodata*
          .sdata
          .sdata.*
          .gnu.linkonce.s.*)
    } > ram
    .rodata : {
        *(.rodata*)
    } > ram
    .data : {
        _gp = .;
        *(.data)
    } > ram

    /* bss segment */
    .sbss : {
        *(.sbss
          .sbss.*
          .gnu.linkonce.sb.*
          .scommon)
    } > ram
    .bss : {
        *(.bss)
    } > ram

    /* no thread-local data segments */
    /* this includes .tdata* and .tbss* */

    .heap : {
        /* End of uninitalized data segement */
        _end = .;
        *(.heap*)
        _heap_limit = .;
    } > ram

    /DISCARD/ : {
        *(.debug*)
    }

    _stack_top = ORIGIN(ram) + LENGTH(ram);
}

