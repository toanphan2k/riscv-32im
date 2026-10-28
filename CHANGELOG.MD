# Changelog

## [0.4.1] - 2026-10-28

### Added
- added fpga demo top, seven segment led test
- added test binary and mem
- added constraints for testing on FPGA

## [0.4.0] - 2026-10-28

### Added
- added cpu_rv32im_top.sv connect to ram and rom
- added dmem structure image (gen by AI)

### Fixed
- After running with counter test, we see that we need to init register file at reset.
- x2 = sp = 0x4000

## [0.3.5] - 2026-10-24

### Added
- Added instruction memory for testing rv32im_core and top

### Fixed
- Fixed missing ctrl.wb_src_sel = WB_SRC_PC_4 in Decoder Control, OP_JAL and OP_JALR

### Changed
- Update tb_rv32im_core.sv to use mem

## [0.3.4] - 2026-10-24

### Added
- Added testbench for rv32im_core.sv

### Fixed
- BUG: funct7[5] == 1, then opcode is SUB, not ADD

### Changed
- Modify testbench contributors to Copilot and Chat GPT
- Add encode_r to stage_id testbench

## [0.3.3] - 2026-10-22

### Added
- Added system verilog file description

## [0.3.2] - 2026-10-22

### Changed
- Update radix4_divider_comb with div_by_zero and overflow

## [0.3.1] - 2026-10-22

### Added
- Test onchange.yaml

## [0.3.0] - 2026-10-22

### Added
- Added constraint file.
- Connect all modules to RISCV Core
- Added testbench for ID, EX, and MEM

### Fixed
- Fixed register files
- Fixed stage_id id_decoder_ctrl wrong input and incorect wb_rd_addr
- Fixed stage_if: branch_target as input, add missing logic advance

## [0.2.18] - 2026-10-18

### Fixed
- Fixed missing is_mul and is_div in m unit.
- Fixed wrong signal selection in stage_ex.
- Fixed wrong input range values in M UNIT.

## [0.2.17] - 2026-10-16

### Changed
- Improve all current testbenches and synchronize format

## [0.2.16] - 2026-10-16

### Changed
- Redesinged and improve hazzard unit
- Add conditions to reduce CPU from stall more often, more strict conditon
- Condition internal cpu reg location for stall and flush

### Added
- Add signal control for better ctrl.uses_rs1 harzard dectection control

## [0.2.15] - 2026-10-16

### Added
- Introduce Ripple Carry Adder Unit for comparison

### Changed
- Change cla testbench to a more general testbench, for all adder

## [0.2.14] - 2026-10-15

### Added
- Add a simple adder using DSP/synthesis tech resource (For comparison purpose)

## [0.2.13] - 2026-10-15

### Fixed
- Align ALU source selection and branch compare logic
- Update control signal ports from `control_signal_t` to `ctrl_signal_t`
- Add missing commas/semicolons that were preventing synthesis or compile checks.

## [0.2.12] - 2026-10-15

### Changed
- Changed 31 = XLEN -1 for flexibility
- Changed indentation for beauty in cla_32bit, cla_32bit_lau, alu_rv32
- Update testbench for SLT, SLTU ALU edge case

### Added
- Initiate cla_32bit inside alu unit
- ALU results depend most on cla_32bit

## [0.2.11] - 2026-10-15

### Added
- Complete M-Unit with sample simple mul and div unit for test
- Replace with other algorithms in code block

## [0.2.10] - 2026-10-15

### Fixed
- Wrong forwarding Selection in Forward Unit

### Changed
- Put logic into always_comb for easy to see
- Rename file to forward_unit.sv
- Rename file to hazard_unit.sv
- Change indent of stage_wb

## [0.2.9] - 2026-10-15

### Added
- Add a simple multiplier unit using only arithmetic symbols
- Add testbench for this multiplier module

## [0.2.8] - 2026-10-15

### Added
- Add a simple divider unit using only arithmetic symbols
- Add testbench for this module

## [0.2.7] - 2026-10-14

### Added
- Add radix 4 restoring div using combinational logi
- Add testbench to test div module of radix 4 restoring
- Author: Anh Tran

## [0.2.6] - 2026-10-13

### Added
- Add hazard units and testbench
- Author: Anh Tran

## [0.2.5] - 2026-10-13

### Fixed
- MEM addr width should be 12 bit
- ROM only read when there is en_read
- Data of DMEM only accessible when there is request
- Only init HEX file it is not none
- Fixed testbench accordingly

### Added
- Add DMEM write stobe for correct load instructions

## [0.2.4] - 2026-10-13

### Added
- Add Instruction ROM
- Add Data Memory RAM
- Add sample memory testbench

## [0.2.3] - 2026-10-12

### Added
- Added writeback stage

## [0.2.2] - 2026-10-12

### Added
- init M-Extension Unit input/output

## [0.2.1] - 2026-10-12

### Added
- Added local params RST_32BIT_VECTOR, TRAP_VECTOR, NOP_INSTR in RV32IM package
- Added dmem_write_strobe enum
- Added pc_src_sel enum
- Added README.MD
- Added stage MEM
- Added stage IF

### Changed
- Apply RST_32BIT_VECTOR for all reset/flush signals
- Remove NOP_INSTR from local riscv stage reg

## [0.1.6] - 2026-10-12

### Changed
- Rename id_register_file.sv -> register_file.sv

## [0.1.5] - 2026-10-08

## Fixed
- fix syntax error in rv32im_pkg.sv
- fix syntax error in stage_id.sv

## [0.1.4] - 2026-10-07

### Added
- add REG_NUM constant
- add id_register_file.sv
- add stage_id.sv
- add id_decoder_ctrl.sv

### Changed
- imm_funct3_e renamed to funct3_e to distinguish with system_funct3_e

## [0.1.3] - 2026-10-05

### Added
- add Funct 7 enum to navigate between ALU block and M-Ext block
- add imm_funct3_e enum to switch case

### Changed
- imm_gen.sv rename to id_imm_gen.sv

### Fixed
- alu_src_b_sel_e ALU_SRC_B_RS2 to 1 bit
- Fix OP_IMM to correct 32 bit input

## [0.1.2] - 2026-10-03

### Added
- add IMMEDIATE_GENERATOR module to gen IMM depend on OPCODE

### Changed
- instruction -> instr in input and output for consitency

## [0.1.1] - 2026-10-03

### Added
- add RISCV_ISA_Architect.md to show the structure of instruction and RISCV microarchitect
- add ISA instruction type images and RISCV microarchitect images

### Changed
- migrate images to docs/images

## [0.1.0] - 2026-10-03

### Fixed
- Fixed missing import package in cla_32bit.sv
- Fixed missing ; in stage_ex.sv

### Added
- reg between each stage: reg_if_id, reg_id_ex, reg_ex_mem, reg_mem_wb
- Add REG_ADDR_WIDTH in constant

### Changed
- Change 5 bit of register address [4:0] to [REG_ADDR_WIDTH-1:0]
- Format indent for beauty

## [0.0.12] - 2026-10-02

### Added
- Select signal for execution stage in package
- Add pack control signal in package
- Add stage_ex.sv
- Add local parameter XLEN = 32
### Changed
- Replace MSB 32 with XLEN in all files

## [0.0.11] - 2026-09-30

### Added
- Initialize changelog.md and version.txt

## [0.0.10] - 2026-09-29

### Fixed
- Correct carry-block indexing and overflow handling in the 32-bit CLA.

## [0.0.9] - 2026-09-29

### Added
- Implement the 32-bit carry-lookahead adder.

## [0.0.8] - 2026-09-28

### Added
- Initialize the five RV32IM pipeline stages.

## [0.0.7] - 2026-09-28

### Added
- Add a diagram of the 4-bit carry-lookahead adder.

## [0.0.6] - 2026-09-28

### Changed
- Adapt the 4-bit adder for the 32-bit carry-lookahead design.

## [0.0.5] - 2026-09-28

### Added
- Add the 4-bit carry-lookahead adder and testbench.

## [0.0.4] - 2026-09-27

### Fixed
- Fix GitHub Markdown rendering in the instruction-set documentation.

## [0.0.3] - 2026-09-27

### Changed
- Update the instruction-set documentation and RV32IM package.

## [0.0.2] - 2026-09-25

### Added
- Initialize the ALU and package, with an ALU testbench.

## [0.0.1] - 2026-09-25

### Added
- Add initial Git attributes.

