module Alu where

import Blarney
import Blarney.Option
import Blarney.Utils
import Blarney.ADT
import Blarney.Ehr

import Instr
import CSR

alu :: ExecInput -> ExecOutput
alu query =
  ExecOutput {rd, exception, cause, pc= newPc, tval= newPc, flush= false}
  where
    rs1 = query.rs1
    rs2 = query.rs2
    op2 = query.instr.rs2.valid ? (rs2,imm)
    opcode = query.instr.opcode
    imm = query.instr.imm.val
    off = query.instr.off
    pc = query.pc

    cause = instruction_address_misaligned

    exception = slice @1 @0 newPc =!= 0

    taken = select [
        opcode `is` [BEQ] --> rs1 === rs2,
        opcode `is` [BNE] --> rs1 =!= rs2,
        opcode `is` [BLTU] --> rs1 .<. rs2,
        opcode `is` [BGEU] --> rs1 .>=. rs2,
        opcode `is` [BLT] --> toSigned rs1 .<. toSigned rs2,
        opcode `is` [BGE] --> toSigned rs1 .>=. toSigned rs2
      ]

    newPc = selectDefault (pc + 4) [
        opcode `is` [BEQ,BNE,BLTU,BGEU,BLT,BGE] --> taken ? (pc+signExtend off,pc+4),
        opcode `is` [JALR] --> (rs1 + imm) .&. inv 1,
        opcode `is` [JAL]  --> pc + imm
      ]

    rd = select [
        opcode `is` [JALR, JAL] --> pc + 4,
        opcode `is` [LUI] --> imm,
        opcode `is` [AUIPC] --> pc + imm,
        opcode `is` [ADD] --> rs1 + op2,
        opcode `is` [SUB] --> rs1 - op2,
        opcode `is` [XOR] --> rs1 .^. op2,
        opcode `is` [OR] --> rs1 .|. op2,
        opcode `is` [AND] --> rs1 .&. op2,
        opcode `is` [SLT] --> toSigned rs1 .<. toSigned op2 ? (1,0),
        opcode `is` [SLTU] --> rs1 .<. op2 ? (1,0),
        opcode `is` [SLL] --> rs1 .<<. slice @4 @0 op2,
        opcode `is` [SRL] --> rs1 .>>. slice @4 @0 op2,
        opcode `is` [SRA] --> rs1 .>>>. slice @4 @0 op2
      ]

execCSR :: Priv -> CSRUnit -> ExecInput -> Action ExecOutput
execCSR currentPriv unit ExecInput{instr, pc, rs1} = do
  let doRead = instr.opcode `is` [CSRRW] ? (instr.rd.val =!= 0, true)
  let doWrite = instr.opcode `is` [CSRRC,CSRRS] ? (instr.rs1.val =!= 0, true)
  let readOnly = isReadOnlyCSR instr.csr

  let legal =
        inv (doWrite .&&. readOnly)
        .&&. currentPriv .>=. minPrivCSR instr.csr

  x <- whenAction (doRead .&&. legal) (unit.csrUnitRead instr.csr)

  let operand = instr.csrI ? (zeroExtend instr.rs1.val, rs1)

  let value =
        select
          [ instr.opcode `is` [CSRRW] --> operand
          , instr.opcode `is` [CSRRS] --> x .|. operand
          , instr.opcode `is` [CSRRC] --> x .&. inv operand ]

  when (legal .&&. doWrite) do
    unit.csrUnitWrite instr.csr value

  return
    ExecOutput
      { rd= x
      , exception= inv legal
      , cause= illegal_instruction
      , tval= instr.raw
      , flush= unit.csrUnitFlush
      , pc= pc + 4 }

execAMO :: (MnemonicVec, Bit 32) -> Bit 32 -> Bit 32
execAMO (opcode, x) y =
  select
    [ opcode `is` [AMOOR] --> x .|. y
    , opcode `is` [AMOAND] --> x .&. y
    , opcode `is` [AMOXOR] --> x .^. y
    , opcode `is` [AMOSWAP] --> x
    , opcode `is` [AMOADD] --> x + y
    , opcode `is` [AMOMIN] --> toSigned x .>. toSigned y ? (y,x)
    , opcode `is` [AMOMAX] --> toSigned x .>. toSigned y ? (x,y)
    , opcode `is` [AMOMINU] --> x .>. y ? (y,x)
    , opcode `is` [AMOMAXU] --> x .>. y ? (x,y) ]
