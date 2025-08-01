.section .text.trampoline
.globl run_user
.globl user_trap
.globl machine_handler

# a0 is a pointer to the trap context of type TRAP_STATE
.align 4
run_user:
  # calling convention
  addi sp, sp, -15*4
  sw gp, 0 * 4(sp)
  sw tp, 1 * 4(sp)
  sw ra, 2 * 4(sp)
  sw s0, 3 * 4(sp)
  sw s1, 4 * 4(sp)
  sw s2, 5 * 4(sp)
  sw s3, 6 * 4(sp)
  sw s4, 7 * 4(sp)
  sw s5, 8 * 4(sp)
  sw s6, 9 * 4(sp)
  sw s7, 10 * 4(sp)
  sw s8, 11 * 4(sp)
  sw s9, 12 * 4(sp)
  sw s10, 13 * 4(sp)
  sw s11, 14 * 4(sp)

  # save the trap state for the next trap
  csrw sscratch, a0

  # save the kernel stack in TRAP_STATE.kernel_sp
  sw sp, 32 * 4(a0)

  # write TRAP_STATE.mepc in sepc: address of the next instruction after sret
  lw t0, 31 * 4(a0)
  csrw sepc, t0

  lw t0, 33 * 4(a0)
  csrrw t0, satp, t0
  sfence.vma zero, zero
  sw t0, 33 * 4(a0)

  # load the user general purpose registers from TRAP_STATE
  lw ra, 0 * 4(a0)
  lw sp, 1 * 4(a0)
  lw gp, 2 * 4(a0)
  lw tp, 3 * 4(a0)
  lw t0, 4 * 4(a0)
  lw t1, 5 * 4(a0)
  lw t2, 6 * 4(a0)
  lw s0, 7 * 4(a0)
  lw s1, 8 * 4(a0)
  # don't `lw a0, 9 * 4(a0)`, a0 is still used
  lw a1, 10 * 4(a0)
  lw a2, 11 * 4(a0)
  lw a3, 12 * 4(a0)
  lw a4, 13 * 4(a0)
  lw a5, 14 * 4(a0)
  lw a6, 15 * 4(a0)
  lw a7, 16 * 4(a0)
  lw s2, 17 * 4(a0)
  lw s3, 18 * 4(a0)
  lw s4, 19 * 4(a0)
  lw s5, 20 * 4(a0)
  lw s6, 21 * 4(a0)
  lw s7, 22 * 4(a0)
  lw s8, 23 * 4(a0)
  lw s9, 24 * 4(a0)
  lw s10, 25 * 4(a0)
  lw s11, 26 * 4(a0)
  lw t3, 27 * 4(a0)
  lw t4, 28 * 4(a0)
  lw t5, 29 * 4(a0)
  lw t6, 30 * 4(a0)

  lw a0, 9 * 4(a0)
  sret

.align 4
user_trap:
  csrrw a0, sscratch, a0

  # save the user general purpose registers to TRAP_STATE
  sw ra, 0 * 4(a0)
  sw sp, 1 * 4(a0)
  sw gp, 2 * 4(a0)
  sw tp, 3 * 4(a0)
  sw t0, 4 * 4(a0)
  sw t1, 5 * 4(a0)
  sw t2, 6 * 4(a0)
  sw s0, 7 * 4(a0)
  sw s1, 8 * 4(a0)
  # don't `sw a0, 9 * 4(a0)`, a0 is in sscratch
  sw a1, 10 * 4(a0)
  sw a2, 11 * 4(a0)
  sw a3, 12 * 4(a0)
  sw a4, 13 * 4(a0)
  sw a5, 14 * 4(a0)
  sw a6, 15 * 4(a0)
  sw a7, 16 * 4(a0)
  sw s2, 17 * 4(a0)
  sw s3, 18 * 4(a0)
  sw s4, 19 * 4(a0)
  sw s5, 20 * 4(a0)
  sw s6, 21 * 4(a0)
  sw s7, 22 * 4(a0)
  sw s8, 23 * 4(a0)
  sw s9, 24 * 4(a0)
  sw s10, 25 * 4(a0)
  sw s11, 26 * 4(a0)
  sw t3, 27 * 4(a0)
  sw t4, 28 * 4(a0)
  sw t5, 29 * 4(a0)
  sw t6, 30 * 4(a0)

  #save user-a0 in 9 * 4(a0)
  csrr t0, sscratch
  sw t0, 9 * 4(a0)

  # load the kernel stack pointer from TRAP_STATE.kernel_sp
  lw sp, 32 * 4(a0)

  lw t0, 33 * 4(a0)
  csrrw t0, satp, t0
  sfence.vma zero, zero
  sw t0, 33 * 4(a0)

  # save mepc into the stack
  csrr t0, sepc
  sw t0, 31 * 4(a0)

  lw gp, 0 * 4(sp)
  lw tp, 1 * 4(sp)
  lw ra, 2 * 4(sp)
  lw s0, 3 * 4(sp)
  lw s1, 4 * 4(sp)
  lw s2, 5 * 4(sp)
  lw s3, 6 * 4(sp)
  lw s4, 7 * 4(sp)
  lw s5, 8 * 4(sp)
  lw s6, 9 * 4(sp)
  lw s7, 10 * 4(sp)
  lw s8, 11 * 4(sp)
  lw s9, 12 * 4(sp)
  lw s10, 13 * 4(sp)
  lw s11, 14 * 4(sp)
  addi sp, sp, 15*4
  ret

#define PRINT_HEX(code...)\
  PRINT_BYTE(code; li a1, 0xFF000000; and a0, a0, a1; srli a0, a0, 24); \
  PRINT_BYTE(code; li a1, 0x00FF0000; and a0, a0, a1; srli a0, a0, 16); \
  PRINT_BYTE(code; li a1, 0x0000FF00; and a0, a0, a1; srli a0, a0, 8); \
  PRINT_BYTE(code; li a1, 0x000000FF; and a0, a0, a1;);

#define PRINT_ENDLINE \
  la a0, 0x10000000;  \
  la a1, 10;          \
  sw a1, 0(a0)

/*
  Take the argument in a0, only use a1, a2 and a3
*/
#define PRINT_BYTE(code...) \
  code;                     \
  andi a1, a0, 0xF0;        \
  srli a1, a1, 4;           \
  li a3, 0x10000000;        \
  li a2, 10;                \
  blt a1, a2, 1f;           \
  addi a1, a1, 0x41 - 10;   \
  sb a1, 0(a3);             \
  j 2f;                     \
1:;                         \
  addi a1, a1, 0x30;        \
  sb a1, 0(a3);             \
2:;                         \
  code;                     \
  andi a1, a0, 0x0F;        \
  li a3, 0x10000000;        \
  li a2, 10;                \
  blt a1, a2, 1f;           \
  addi a1, a1, 0x41 - 10;   \
  sb a1, 0(a3);             \
  j 2f;                     \
1:;                         \
  addi a1, a1, 0x30;        \
  sb a1, 0(a3);             \
2:;


.align 4
machine_handler:
  csrrw a0,mscratch,a0
  sw a1, 0 * 4(a0)
  sw a2, 1 * 4(a0)
  sw a3, 2 * 4(a0)
  sw a4, 3 * 4(a0)

  lw a1, 4 * 4(a0) // interval
  lw a2, 5 * 4(a0) // *mtimecmp

  lw a3, 0(a2)     // mtimecmp
  add a3, a3, a1
  sw a3, 0(a2)     // mtimecmp <- old(mtimecmp) + interval

  li a1,2
  csrs sip, a1 // Set bit 2 of sip

  lw a1, 0 * 4(a0)
  lw a2, 1 * 4(a0)
  lw a3, 2 * 4(a0)
  lw a4, 3 * 4(a0)
  csrrw a0,mscratch,a0
  mret

