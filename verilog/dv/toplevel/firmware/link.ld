OUTPUT_ARCH(riscv)

MEMORY {
 ram (rwx) : ORIGIN = 0x00000000, LENGTH = 0x800 /* 2048 Bytes */
 flash (rx): ORIGIN = 0x02200000, LENGTH = 0x400000 /* 4MB */
}

SECTIONS {

    .text :
    {
        . = ALIGN(4);
        *(.reset_vector*)
        *(.text)
        *(.text*)
        *(.rodata)
        *(.rodata*)
        *(.srodata)
        *(.srodata*)
        . = ALIGN(4);
        _etext = .;
        _sidata = _etext;
    } >flash


    .data : AT ( _sidata )
    {
        . = ALIGN(4);
        _sdata = .;
        _ram_start = .;
        *(.data)
        *(.data*)
        *(.sdata)
        *(.sdata*)
        . = ALIGN(4);
        _edata = .;
    } >ram


    .bss :
    {
        . = ALIGN(4);
        _sbss = .;
        *(.bss)
        *(.bss*)
        *(.sbss)
        *(.sbss*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = .;
    } >ram


    .heap :
    {
        . = ALIGN(4);
        _heap_start = .;
    } >ram

    . = ALIGN(4);
    end = .;
}

PROVIDE(_stack = ORIGIN(ram) + LENGTH(ram));
