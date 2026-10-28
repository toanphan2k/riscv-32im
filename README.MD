# RISC-V RV32IM Core

> Note: This document was generated with AI assistance and may be updated manually as the project evolves.

This repository contains a simple SystemVerilog implementation of a 32-bit RISC-V processor based on the RV32IM instruction set.

The design targets the RV32I base integer ISA and includes the M extension for integer multiplication and division. It is intended as a learning-oriented reference for understanding the RISC-V architecture and a simple hardware datapath implementation.

## Features

- 32-bit RISC-V integer core
- RV32I base instruction set support
- RV32M multiplication and division support
- ALU and control logic implemented in SystemVerilog
- Pipeline stage organization with separate decode, execute, memory, and write-back logic
- Instruction and architecture documentation included in the docs folder

## Project Structure

- `rtl/core/` – processor core implementation and stage logic
- `rtl/pkg/` – package definitions and shared data structures
- `tb/` – basic testbenches for verification
- `docs/` – ISA and microarchitecture references

## Supported Instruction Groups

- Arithmetic and logical instructions
- Control-flow instructions (`BEQ`, `BNE`, `JAL`, `JALR`)
- Memory access instructions (`LW`, `SW`, `LB`, `SB`, etc.)
- Shift and compare operations
- Integer multiply/divide instructions from the M extension

## Example Use

This project is useful for:

- studying RISC-V ISA encoding and execution flow
- understanding a simple RV32IM datapath design
- experimenting with SystemVerilog CPU architecture
- extending the core with additional features or peripherals

## Documentation

See the files in the `docs/` directory for architecture overviews and instruction-set references:

- `docs/RISCV_ISA_Architect.md`
- `docs/instruction_set.md`

## RAM design and stack layout
This project uses a byte-addressable RAM that is physically organized as 32-bit words. Each word contains four bytes, so the byte address is mapped as:

- word index = byte address >> 2
- byte within word = byte address & 0x3

Example memory layout for the 4 KiB word-addressed RAM (16 KiB total, because 4096 words x 4 bytes):

| RISC-V byte address | RAM word index | Byte within word | Meaning |
|---|---:|---:|---|
| 0x0000 | 0 | 0 | start of RAM |
| 0x0001 | 0 | 1 | byte 1 of word 0 |
| 0x0002 | 0 | 2 | byte 2 of word 0 |
| 0x0003 | 0 | 3 | byte 3 of word 0 |
| 0x0004 | 1 | 0 | start of next word |
| ... | ... | ... | ... |
| 0x3FFC | 4095 | 0 | last word, byte 0 |
| 0x3FFD | 4095 | 1 | last word, byte 1 |
| 0x3FFE | 4095 | 2 | last word, byte 2 |
| 0x3FFF | 4095 | 3 | last byte of RAM |
| 0x4000 | — | — | stack pointer (`x2` / `sp`) starts here |

This means the RAM covers addresses from 0x0000 to 0x3FFF. The stack pointer register `x2` is initialized to `0x00004000` in this design, which is just above the RAM region. In RISC-V convention, the stack grows downward, so when the processor pushes data onto the stack it uses addresses below `0x4000` (for example, `0x3FFC`, `0x3FF8`, etc.).

### Stack Pointer (x2)
- Register: `x2`
- ABI name: `sp` (stack pointer)
- Reset value in this design: `0x00004000`
- Meaning: start of the stack area; stack grows toward lower addresses

In other words, the stack begins at the top of the available data memory and descends as functions allocate space and save registers.

## Notes

This is a compact educational implementation rather than a full commercial processor. It is best suited for learning, simulation, and architectural experimentation.
