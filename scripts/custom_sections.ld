_RamSize    = 0x2000; /* RAM section - 4KB */
_StackSize  = 0x1000; /* Reserve half of RAM for the stack - 2KB */
_RamStart   = 0x0;

MEMORY {
    RAM (rwx) : ORIGIN = _RamStart, LENGTH = _RamSize
}

SECTIONS {
    PROVIDE(__stack_top = ORIGIN(RAM) + LENGTH(RAM));
    .text : {
        *(.text._start)
        *(.text .text*)
        *(.rodata .rodata*)
        _etext = .;
    }

    .bss (NOLOAD) :
    {
        _sbss = .;
        *(.bss .bss*)
        *(COMMON)
        _ebss = .;
    }

    .data :
    {
        _sdata = .;
        *(.data .data*)
        _edata = .;
    }

    .stack (NOLOAD) :
    {
        . = ALIGN(4);
        _sstack = .;
        . = . + _StackSize;
        . = ALIGN(4);
        _estack = .;
    }

    _end = .;
}