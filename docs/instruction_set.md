# RISC-V RV32IM Instruction Set Specification & Synthesis Netlist Reference

This document provides the complete instruction set tables for **RV32I (Base Integer)** and **RV32M (Standard Multiplication & Division Extension)**, official specification source references, and conceptual structural diagrams of the design.

---

## 1. Specification Sources & Authoritative References

The instruction encoding, behavioral semantics, and corner cases implemented in this core are referenced directly from the official **RISC-V International Ratified Specifications**:

1. **Volume I: Unprivileged Instruction Set Architecture (Document Version 20191213 / Ratified)**
   - *Authors*: Andrew Waterman, Krste Asanović (UC Berkeley & RISC-V International).
   - *Reference*: Chapter 2 (*RV32I Base Integer Instruction Set, Version 2.1*) & Chapter 7 (*"M" Standard Extension for Integer Multiplication and Division, Version 2.0*).
   - *Link*: [https://riscv.org/technical/specifications/](https://riscv.org/technical/specifications/)
2. **Computer Organization and Design RISC-V Edition (Patterson & Hennessy)**
   - Standard 5-stage classic RISC pipeline reference datapath, hazard management, and forwarding topologies.
3. **Patterson, D. A., & Waterman, A.**
   - *The RISC-V Reader: An Open Architecture Atlas* (Reference Card & Instruction Map).

---

## 2. RV32I Base Integer Instruction Set Table

All RV32I instructions are 32 bits wide. Register addresses `rd`, `rs1`, `rs2` are 5 bits ($x0 \dots x31$).

| Instruction | Format | `funct7` [31:25] | `rs2` [24:20] | `rs1` [19:15] | `funct3` [14:12] | `rd` [11:7] | `opcode` [6:0] | Operation Description |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **LUI** | U | `imm[31:25]` | `imm[24:20]` | `imm[19:15]` | `imm[14:12]` | `rd` | `0110111` | $R[rd] = \text{imm} \ll 12$ |
| **AUIPC** | U | `imm[31:25]` | `imm[24:20]` | `imm[19:15]` | `imm[14:12]` | `rd` | `0010111` | $R[rd] = PC + (\text{imm} \ll 12)$ |
| **JAL** | J | `imm[20\|10:5]` | `imm[4:1\|11]` | `imm[19:15]` | `imm[14:12]` | `rd` | `1101111` | $R[rd] = PC + 4; \ PC = PC + \text{imm}$ |
| **JALR** | I | `imm[11:5]` | `imm[4:0]` | `rs1` | `000` | `rd` | `1100111` | $R[rd] = PC + 4; \quad PC = (R[rs1] + \text{imm}) \ \&\sim 1$ |
| **BEQ** | B | `imm[12\|10:5]` | `rs2` | `rs1` | `000` | `imm[4:1\|11]` | `1100011` | if ($R[rs1] == R[rs2]$) $PC = PC + \text{imm}$ |
| **BNE** | B | `imm[12\|10:5]` | `rs2` | `rs1` | `001` | `imm[4:1\|11]` | `1100011` | if ($R[rs1] \neq R[rs2]$) $PC = PC + \text{imm}$ |
| **BLT** | B | `imm[12\|10:5]` | `rs2` | `rs1` | `100` | `imm[4:1\|11]` | `1100011` | if ($R[rs1] < R[rs2]$ signed) $PC = PC + \text{imm}$ |
| **BGE** | B | `imm[12\|10:5]` | `rs2` | `rs1` | `101` | `imm[4:1\|11]` | `1100011` | if ($R[rs1] \ge R[rs2]$ signed) $PC = PC + \text{imm}$ |
| **BLTU** | B | `imm[12\|10:5]` | `rs2` | `rs1` | `110` | `imm[4:1\|11]` | `1100011` | if ($R[rs1] < R[rs2]$ unsigned) $PC = PC + \text{imm}$ |
| **BGEU** | B | `imm[12\|10:5]` | `rs2` | `rs1` | `111` | `imm[4:1\|11]` | `1100011` | if ($R[rs1] \ge R[rs2]$ unsigned) $PC = PC + \text{imm}$ |
| **LB** | I | `imm[11:5]` | `imm[4:0]` | `rs1` | `000` | `rd` | `0000011` | $R[rd] = \text{SignExt}(M_1(R[rs1] + \text{imm}))$ |
| **LH** | I | `imm[11:5]` | `imm[4:0]` | `rs1` | `001` | `rd` | `0000011` | $R[rd] = \text{SignExt}(M_2(R[rs1] + \text{imm}))$ |
| **LW** | I | `imm[11:5]` | `imm[4:0]` | `rs1` | `010` | `rd` | `0000011` | $R[rd] = M_4(R[rs1] + \text{imm})$ |
| **LBU** | I | `imm[11:5]` | `imm[4:0]` | `rs1` | `100` | `rd` | `0000011` | $R[rd] = \text{ZeroExt}(M_1(R[rs1] + \text{imm}))$ |
| **LHU** | I | `imm[11:5]` | `imm[4:0]` | `rs1` | `101` | `rd` | `0000011` | $R[rd] = \text{ZeroExt}(M_2(R[rs1] + \text{imm}))$ |
| **SB** | S | `imm[11:5]` | `rs2` | `rs1` | `000` | `imm[4:0]` | `0100011` | $M_1(R[rs1] + \text{imm}) = R[rs2][7:0]$ |
| **SH** | S | `imm[11:5]` | `rs2` | `rs1` | `001` | `imm[4:0]` | `0100011` | $M_2(R[rs1] + \text{imm}) = R[rs2][15:0]$ |
| **SW** | S | `imm[11:5]` | `rs2` | `rs1` | `010` | `imm[4:0]` | `0100011` | $M_4(R[rs1] + \text{imm}) = R[rs2][31:0]$ |
| **ADDI** | I | `imm[11:5]` | `imm[4:0]` | `rs1` | `000` | `rd` | `0010011` | $R[rd] = R[rs1] + \text{imm}$ (via CLA) |
| **SLTI** | I | `imm[11:5]` | `imm[4:0]` | `rs1` | `010` | `rd` | `0010011` | $R[rd] = (R[rs1] < \text{imm}) \ ? \ 1 : 0$ |
| **SLTIU** | I | `imm[11:5]` | `imm[4:0]` | `rs1` | `011` | `rd` | `0010011` | $R[rd] = (R[rs1] <_u \text{imm}) \ ? \ 1 : 0$ |
| **XORI** | I | `imm[11:5]` | `imm[4:0]` | `rs1` | `100` | `rd` | `0010011` | $R[rd] = R[rs1] \oplus \text{imm}$ |
| **ORI** | I | `imm[11:5]` | `imm[4:0]` | `rs1` | `110` | `rd` | `0010011` | $R[rd] = R[rs1] \lor \text{imm}$ |
| **ANDI** | I | `imm[11:5]` | `imm[4:0]` | `rs1` | `111` | `rd` | `0010011` | $R[rd] = R[rs1] \land \text{imm}$ |
| **SLLI** | I | `0000000` | `shamt[4:0]` | `rs1` | `001` | `rd` | `0010011` | $R[rd] = R[rs1] \ll \text{shamt}$ |
| **SRLI** | I | `0000000` | `shamt[4:0]` | `rs1` | `101` | `rd` | `0010011` | $R[rd] = R[rs1] \gg \text{shamt}$ (logical) |
| **SRAI** | I | `0100000` | `shamt[4:0]` | `rs1` | `101` | `rd` | `0010011` | $R[rd] = R[rs1] \ggg \text{shamt}$ (arithmetic) |
| **ADD** | R | `0000000` | `rs2` | `rs1` | `000` | `rd` | `0110011` | $R[rd] = R[rs1] + R[rs2]$ (via CLA) |
| **SUB** | R | `0100000` | `rs2` | `rs1` | `000` | `rd` | `0110011` | $R[rd] = R[rs1] - R[rs2]$ (via CLA) |
| **SLL** | R | `0000000` | `rs2` | `rs1` | `001` | `rd` | `0110011` | $R[rd] = R[rs1] \ll R[rs2][4:0]$ |
| **SLT** | R | `0000000` | `rs2` | `rs1` | `010` | `rd` | `0110011` | $R[rd] = (R[rs1] < R[rs2]) \ ? \ 1 : 0$ |
| **SLTU** | R | `0000000` | `rs2` | `rs1` | `011` | `rd` | `0110011` | $R[rd] = (R[rs1] <_u R[rs2]) \ ? \ 1 : 0$ |
| **XOR** | R | `0000000` | `rs2` | `rs1` | `100` | `rd` | `0110011` | $R[rd] = R[rs1] \oplus R[rs2]$ |
| **SRL** | R | `0000000` | `rs2` | `rs1` | `101` | `rd` | `0110011` | $R[rd] = R[rs1] \gg R[rs2][4:0]$ |
| **SRA** | R | `0100000` | `rs2` | `rs1` | `101` | `rd` | `0110011` | $R[rd] = R[rs1] \ggg R[rs2][4:0]$ |
| **OR** | R | `0000000` | `rs2` | `rs1` | `110` | `rd` | `0110011` | $R[rd] = R[rs1] \lor R[rs2]$ |
| **AND** | R | `0000000` | `rs2` | `rs1` | `111` | `rd` | `0110011` | $R[rd] = R[rs1] \land R[rs2]$ |
| **FENCE** | I | `fm\|pred[3:1]` | `pred[0]\|succ` | `00000` | `000` | `00000` | `0001111` | Memory Order Fence (executes as NOP in this core) |
| **ECALL** | I | `000000000000` | `00000` | `00000` | `000` | `00000` | `1110011` | Environment Call Trap |
| **EBREAK**| I | `000000000001` | `00000` | `00000` | `000` | `00000` | `1110011` | Environment Breakpoint Trap |

---

## Control-Flow Target and Condition Summary

| Instruction | Target calculation | Condition |
| :--- | :--- | :--- |
| **BEQ** | `PC + imm` | `rs1 == rs2` |
| **BNE** | `PC + imm` | `rs1 != rs2` |
| **BLT** | `PC + imm` | signed `rs1 < rs2` |
| **BGE** | `PC + imm` | signed `rs1 >= rs2` |
| **JAL** | `PC + imm` | Always taken |
| **JALR** | `(forwarded_rs1 + imm) & ~1` | Always taken |

---

## 3. RV32M Standard Extension Table (Multiplication & Division)

The M-extension instructions all share the R-type format with `opcode = 7'b0110011` and `funct7 = 7'b0000001`:

| Instruction | `funct7` [31:25] | `rs2` [24:20] | `rs1` [19:15] | `funct3` [14:12] | `rd` [11:7] | `opcode` [6:0] | Operation Description | Latency |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- | :---: |
| **MUL** | `0000001` | `rs2` | `rs1` | `000` | `rd` | `0110011` | $R[rd] = (R[rs1] \times R[rs2])[31:0]$ (signed $\times$ signed) | 1 cycle |
| **MULH** | `0000001` | `rs2` | `rs1` | `001` | `rd` | `0110011` | $R[rd] = (R[rs1] \times R[rs2])[63:32]$ (signed $\times$ signed) | 1 cycle |
| **MULHSU** | `0000001` | `rs2` | `rs1` | `010` | `rd` | `0110011` | $R[rd] = (R[rs1] \times R[rs2])[63:32]$ (signed $\times$ unsigned) | 1 cycle |
| **MULHU** | `0000001` | `rs2` | `rs1` | `011` | `rd` | `0110011` | $R[rd] = (R[rs1] \times R[rs2])[63:32]$ (unsigned $\times$ unsigned) | 1 cycle |
| **DIV** | `0000001` | `rs2` | `rs1` | `100` | `rd` | `0110011` | $R[rd] = R[rs1] \ / \ R[rs2]$ (signed division) | 10 cycles in EX (9 stalls) |
| **DIVU** | `0000001` | `rs2` | `rs1` | `101` | `rd` | `0110011` | $R[rd] = R[rs1] \ / \ R[rs2]$ (unsigned division) | 10 cycles in EX (9 stalls) |
| **REM** | `0000001` | `rs2` | `rs1` | `110` | `rd` | `0110011` | $R[rd] = R[rs1] \ \% \ R[rs2]$ (signed remainder) | 10 cycles in EX (9 stalls) |
| **REMU** | `0000001` | `rs2` | `rs1` | `111` | `rd` | `0110011` | $R[rd] = R[rs1] \ \% \ R[rs2]$ (unsigned remainder) | 10 cycles in EX (9 stalls) |

Divide latency = 1 setup cycle (sign/abs) + 8 radix-16 iteration stages + 1 result cycle (sign fix-up / corner cases).

### Corner case of M extension
*Link*: [DIV_BY_ZERO and OVERFLOW](https://docs.riscv.org/reference/isa/v20260120/unpriv/m-st-ext.html#divby0)
