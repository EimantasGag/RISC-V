.globl _start

.data
a: .word 5
b: .word 10
c: .word 5
d: .word 4

.text

_start:
    la a0, afterMath
    call push
    
    la t0, a
    lw a0, 0(t0)
    call push
    
    la t0, b
    lw a0, 0(t0)
    call push
    
    la t0, c
    lw a0, 0(t0)
    call push
    
    la t0, d
    lw a0, 0(t0)
    call push
    
    call math
    
afterMath:
    call pop 
    call print
    
    call end
    
# paima 4 reiksmes is stacko A,B,C,D ir grazina X, kai X=A+B-C-10+D
math:
    call pop #d reiksme
    mv t0, a0
    call pop #c reiksme
    mv t1, a0
    call pop #b reiksme
    mv t2, a0
    call pop #a reiksme
    mv t3, a0
    
    li a0, 0
    add a0, t3, t2
    sub a0, a0, t1
    addi a0, a0, -10
    add a0, a0, t0
    
    # t1 registre issaugome X
    mv t1, a0
    
    # issaugome t0 registre grizimo adresa
    call pop
    mv t0, a0
    
    # issaugo x rezultata stacke
    mv a0, t1
    call push
    
    # 
    mv ra, t0
    
    ret
    
# a0 registre value kuri pushinama i stacka
push:
    sw a0, 0(sp)
    addi sp, sp, -4
    ret

# grazina a0 registre ispopinta value
pop:
    addi sp, sp, 4
    lw a0, 0(sp)
    ret
    
# printina value a0 registre
print:
    li a7, 1
    ecall
    ret
    
end:
    li a7, 10
    ecall
    