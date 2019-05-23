MEMORY
{
    ram (rwx) : ORIGIN = 0x00000000, LENGTH = 0x00010000 /* 64 KB */
}
SECTIONS
{
    . = 0x0;
    .text : {
        *(.text)
    } > ram
    .data : ALIGN(0x1000) {
        *(.data)
    } > ram
    .bss : {
        *(.bss)
    } > ram
}
