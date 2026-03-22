# LC-3 Virtual Machine

<img width="100"  alt="image" src="https://github.com/user-attachments/assets/44938ee5-f985-418b-8927-2ab294a26cc6" />
<br/>
A LittleComputer-3 virtual machine implemented in Zig 0.15.2.

## Features

- All 16 LC-3 opcodes (ADD, AND, NOT, BR, JMP, JSR, LD, LDI, LDR, LEA, ST, STI, STR, TRAP, RES, RTI)
- Trap routines (GETC, OUT, PUTS, IN, PUTSP, HALT)
- Memory-mapped keyboard I/O (KBSR/KBDR)
- Raw terminal input mode with proper cleanup on exit and SIGINT

## Building

```sh
zig build
```

## Usage

```sh
zig build run -- <path-to-lc3-program.obj>
```

## Project Structure

```
src/
  main.zig              -- Entry point
  root.zig              -- Module exports
  core/
    vm.zig              -- VM core: run loop, opcode handlers, trap routines
    memory.zig          -- Memory with keyboard-mapped register support
    data.zig            -- Registers, opcodes, flags, trap codes
    utils.zig           -- Sign extension, endianness, terminal I/O, signal handling
    error.zig           -- Error types
```

## References

- [Write your Own Virtual Machine](https://www.jmeiners.com/lc3-vm/)
- [LC-3 ISA Specification](https://www.jmeiners.com/lc3-vm/supplies/lc3-isa.pdf)
