.text
.globl main

main:
    mv      a0, zero               # start state a0 at 0
    mv      a2, zero               # clear cmd_delay
    mv      a3, zero               # clear cmd_seq
    li      t1, 0xFF               # max state value (was 0b11111111)
    li      t4, 0x5A               # lfsr seed (was 0b1011010)

shift_loop:
    # fixed delay section
    li      t2, 10                 # load delay counter
delay_loop:
    addi    t2, t2, -1             # count down
    bnez    t2, delay_loop         # keep looping if not 0

    slli    a0, a0, 1              # shift state left
    ori     a0, a0, 1              # add the 1 bit at the end
    bne     a0, t1, state_output   # if not full, go to output

state_S8:
    li      a2, 1                  # cmd_delay on

    # calculate random delay (7-bit lfsr)
    andi    t5, t4, 1              # get lsb
    srli    t4, t4, 1              # shift right
    beqz    t5, calc_rem           # skip xor if lsb was 0
    xori    t4, t4, 0xA0           # xor feedback (0b10100000)

calc_rem:
    li      t6, 10                 # max delay limit
    rem     t5, t4, t6             # get remainder
    addi    t5, t5, 1              # make range 1-10

random_delay:
    addi    t5, t5, -1             # count down random delay
    bnez    t5, random_delay

    mv      a0, zero               # reset state
    j       shift_loop             # start over

state_output:
    beq     a0, zero, output_reset # check if we reset
    li      a3, 1                  # cmd_seq on
    j       shift_loop

output_reset:
    mv      a2, zero               # turn off delay cmd
    mv      a3, zero               # turn off seq cmd
    j       shift_loop