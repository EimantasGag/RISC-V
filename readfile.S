.globl _start

.equ STDOUT, 1
.equ SYS_WRITE, 64

.equ SYS_MUNMAP, 215

.equ SYS_MMAP, 222 
.equ PROT_READ, 0x1 
.equ PROT_WRITE, 0x2 
.equ MAP_ANONYMOUS, 0x20
.equ MAP_PRIVATE, 0x02
.equ PAGESIZE, 104 # LATIN_LETTER_COUNT * 4

.equ LATIN_LETTER_COUNT, 26

.macro printText textAdress, textLength
    li a0, STDOUT
    la t3, \textAdress
    mv a1, t3
    li a2, \textLength
    li a7, SYS_WRITE
    ecall
.endm

.macro printNumber numberAdress
    la a1, \numberAdress
    lw a0, 0(a1)
    call print_number
.endm

.section .rodata
filename: .asciz "failas.txt"
filename2: .asciz "rez.txt"
error_msg: .asciz "Error: Read failed.\n"
sentence_txt: .asciz "\nSentence count: "
word_txt: .asciz "\nWord count: "
uppercase_txt: .asciz "\nUppercase count: "
lowercase_txt: .asciz "\nLowercase count: "
latin_txt: .asciz "\nLatin letter count: "
latin_letters_txt: .asciz "\nA: \nB: \nC: \nD: \nE: \nF: \nG: \nH: \nI: \nJ: \nK: \nL: \nM: \nN: \nO: \nP: \nQ: \nR: \nS: \nT: \nU: \nV: \nW: \nX: \nY: \nZ: "
upper_letter_g: .asciz "G"
lower_letter_g: .asciz "g"

.section .data
.align 6
sentence_count: .word 0
word_count: .word 0
uppercase_count: .word 0
lowercase_count: .word 0
latin_letter_count_adress: .word 0

.section .text

_start:
    addi sp, sp, -1024         # Allocate 1024 bytes on the stack
    mv t1, sp                  # Use stack as buffer

    # Open file
    li a0, -100                # AT_FDCWD
    la a1, filename            # File name
    li a2, 0                   # O_RDONLY
    li a3, 0                   # Mode (unused for O_RDONLY)
    li a7, 56                  # Syscall number for openat
    ecall

    bltz a0, exit_error        # Exit if open failed
    mv t0, a0                  # Save file descriptor in t0

    # Open file to write
    li a0, -100                # AT_FDCWD
    la a1, filename2           # File name
    li a2, 1                   # O_RDONLY
    li a3, 666              # Mode (unused for O_RDONLY)
    li a7, 56                  # Syscall number for openat
    ecall

    bltz a0, exit_error        # Exit if open failed
    mv a6, a0                  # t6 registre rasomo failo descriptor

    li a0, 0                        # NULL, because we want anonymous mapping
    li a1, PAGESIZE                 # Linux standard page is 4096
    li a2, PROT_READ|PROT_WRITE     # Read and write to page
    li a3, MAP_ANONYMOUS|MAP_PRIVATE  
    li a4, -1                       # File descriptor for anonymous
    li a5, 0                        # Offset
    li a7, SYS_MMAP
    ecall

    bltz a0, exit_error

    la t2, latin_letter_count_adress
    sw a0, 0(t2)

read_loop:
    # Read from file
    mv a0, t0                  # File descriptor
    mv a1, t1                  # Buffer address
    li a2, 1024                # Buffer size
    li a7, 63                  # Syscall number for read
    ecall

    bltz a0, read_error        # Exit if read failed
    beqz a0, close_file        # End of file (read 0 bytes)
    mv a2, a0                   # Bytes to print

    # Write to stdout
    li a0, STDOUT              # Stdout file descriptor
    mv a1, t1                  # Buffer address
    li a7, SYS_WRITE           # Syscall number for write
    ecall
    bltz a0, write_error       # Exit if write failed

    # issaugo buffer adresa sicia
    mv a5, t1

    mv a0, a5
    mv a1, a2
    mv a2, a6
    call write_file

    # Taskus skaiciuoja
    mv a0, a5
    li a2, 46
    la a3, sentence_count
    call count_char

    # Sauktukus skaiciuoja
    mv a0, a5
    li a2, 33
    la a3, sentence_count
    call count_char

    # Klaustukus skaiciuoja
    mv a0, a5
    li a2, 63
    la a3, sentence_count
    call count_char

    # New line skaiciuoja
    mv a0, a5
    li a2, 10
    la a3, sentence_count
    call count_char

    mv a0, a5
    li a2, 32
    la a3, word_count
    call count_char

    mv a0, a5
    li a2, 10
    la a3, word_count
    call count_char

    mv a0, a5
    call count_uppercase_lowercase

    mv a0, a5
    call count_latin_letters

    j read_loop                # Continue reading

close_file:

    # Padidinti word count += 1
    la t1, word_count
    lw t2, 0(t1)
    addi t2, t2, 1
    sw t2, 0(t1)

    # Close the file
    mv a0, t0                  # File descriptor
    li a7, 57                  # Syscall number for close
    ecall

    # Close the file
    mv a0, a6                  # File descriptor
    li a7, 57                  # Syscall number for close
    ecall

    # Free stack
    addi sp, sp, 1024          # Restore stack

    printText sentence_txt, 17
    printNumber sentence_count

    printText word_txt, 13
    printNumber word_count

    printText uppercase_txt, 18
    printNumber uppercase_count

    printText lowercase_txt, 18
    printNumber lowercase_count

    printText latin_txt, 21
    call print_latin_letter_count

    # Freeina heapa
    la a0, latin_letter_count_adress
    li a1, PAGESIZE
    li a7, SYS_MUNMAP
    ecall

    # Exit successfully
    li a0, 0
    li a7, 93
    ecall

read_error:
write_error:
exit_error:

    # Freeina heapa
    la a0, latin_letter_count_adress
    li a1, PAGESIZE
    li a7, SYS_MUNMAP
    ecall

    # Free stack and exit with error
    addi sp, sp, 1024          # Restore stack
    li a0, 1
    li a7, 93
    ecall

# a0 registre teksto adresas, a1 bytes to read skaicius, a2 registre rasomo failo descriptor
write_file:
    #byte countas, neskaityti daugiau nei a1 bytu
    li t4, 0

write_file_loop:
    lb t3, 0(a0)

    beq zero, t3, write_file_end

    beq t4, a1, write_file_end

    li t5, 69
    beq t3, t5, write_file_g

    li t5, 101
    beq t3, t5, write_file_g

    # israso dabartine raide
    mv t5, a0
    mv t3, a1
    mv t2, a2

    mv a0, t2
    mv a1, t5
    li a2, 1
    li a7, SYS_WRITE
    ecall

    mv a0, t5
    mv a1, t3
    mv a2, t2

write_file_next_byte:
    addi a0, a0, 1
    addi t4, t4, 1
    
    j write_file_loop

write_file_g:
    # cia pakeisti i g raide
    li t5, 101
    beq t3, t5, lowercase_g 

uppercase_g:
    mv t5, a0
    mv t3, a1
    mv t2, a2

    mv a0, t2
    la a1, upper_letter_g
    li a2, 1
    li a7, SYS_WRITE
    ecall

    j write_file_g_end

lowercase_g:
    mv t5, a0
    mv t3, a1
    mv t2, a2
    
    mv a0, t2
    la a1, lower_letter_g
    li a2, 1
    li a7, SYS_WRITE
    ecall

write_file_g_end:
    mv a0, t5
    mv a1, t3
    mv a2, t2

    j write_file_next_byte

write_file_end:
    ret

# a0 registre teksto adresas, a1 bytes to read skaicius
count_latin_letters:

    #byte countas, neskaityti daugiau nei a1 bytu
    li t4, 0

count_latin_letters_loop:
    lb t3, 0(a0)

    beq zero, t3, count_latin_letters_end

    beq t4, a1, count_latin_letters_end

    # jeigu raide mazoji, paversime ja i didziaja
    li t5, 96
    bgt t3, t5, latin_to_uppercase
    j latin_maybe_uppercase_letter

latin_next_byte:
    addi a0, a0, 1
    addi t4, t4, 1
    
    j count_latin_letters_loop

latin_maybe_uppercase_letter:
    addi t3, t3, -65

    # jeigu t3 reiksme nera tarp [0:25], tai cia ne latin raide
    bltz t3, latin_next_byte

    li t5, 25  
    bgt t3, t5, latin_next_byte

    j increment_latin_count

latin_to_uppercase:
    #ascii skirtumas tarp mazuju ir didziuju yra 32
    addi t3, t3, -32 
    j latin_maybe_uppercase_letter

increment_latin_count:
    la t6, latin_letter_count_adress
    
    # heapo adresas t6 registre
    lw t6, 0(t6)

    li t2, 4
    mul t3, t3, t2 #t3 *= 4
    add t6, t6, t3

    lw t5, 0(t6)
    addi t5, t5, 1

    sw t5, 0(t6)

    j latin_next_byte

count_latin_letters_end:
    ret

# a0 registre teksto adresas, a1 bytes to read skaicius, a2 char kuri skaiciuoti, a3 adresas kuriame saugomas kintamasis
count_char:
    lw t2, 0(a3)

    # byte countas, neskaityti daugiau nei a1 bytu
    li t4, 0

    # cia boolean; true jeigu praeitas char buvo a2 char
    li t6, 0

count_char_loop:
    lb t3, 0(a0)

    beq zero, t3, count_char_end

    beq t4, a1, count_char_end

    mv t5, a2
    beq t3, t5, increment_sentence_count

    li t6, 0

next_byte:
    addi a0, a0, 1
    addi t4, t4, 1

    j count_char_loop

increment_sentence_count:
    # jeigu praeitas char buvo toks pats, neskaiciuoti
    bnez t6, next_byte

    # nustatyti i true
    li t6, 1

    addi t2, t2, 1
    j next_byte

count_char_end:
    li t5, 1024
    beq a1, t5, count_char_end_exit
    
    li t5, 46
    bne t5, a2, count_char_end_exit
    beqz t6, count_add_sentence

    # Jeigu skaiciuoja taskus ir sakinio gale nepadejo
    # tasko tai vistiek += 1

    j count_char_end_exit

count_add_sentence:
    addi t2, t2, 1

count_char_end_exit:
    sw t2, 0(a3)
    ret

# a0 registre teksto adresas, a1 bytes to read skaicius
count_uppercase_lowercase:
    #byte countas, neskaityti daugiau nei a1 bytu
    li t4, 0

    #uppercase countas
    li t2, 0

    #lowercase countas
    li t6, 0

count_up_low_loop:
    lb t3, 0(a0)

    beq zero, t3, count_up_low_end

    beq t4, a1, count_up_low_end

    li t5, 91
    blt t3, t5, maybe_uppercase

    li t5, 123
    blt t3, t5, maybe_lowercase

count_up_low_next_byte:
    addi a0, a0, 1
    addi t4, t4, 1
    
    j count_up_low_loop

maybe_uppercase:
    li t5, 64
    bgt t3, t5, increment_uppercase
    j count_up_low_next_byte

maybe_lowercase:
    li t5, 96
    bgt t3, t5, increment_lowercase
    j count_up_low_next_byte

increment_uppercase:
    addi t2, t2, 1
    j count_up_low_next_byte

increment_lowercase:
    addi t6, t6, 1
    j count_up_low_next_byte

count_up_low_end:
    la t5, uppercase_count
    lw t3, 0(t5)
    add t2, t3, t2
    sw t2, 0(t5)

    la t5, lowercase_count
    lw t3, 0(t5)
    add t6, t3, t6
    sw t6, 0(t5)

    ret 

# printina masyva latin_letter_count_adress adrese
print_latin_letter_count:
    addi sp, sp, -1
    sw ra, 0(sp)

    # array index
    li t1, 0

    la t6, latin_letter_count_adress
    lw t6, 0(t6)

print_latin_letter_loop:
    li a0, STDOUT

    # raides adreso gavimas
    la t4, latin_letters_txt
    li t5, 4
    mul t5, t5, t1 #t5 = t1 * 4
    add t5, t4, t5
    mv a1, t5 

    li a2, 4 # text length
    li a7, SYS_WRITE
    ecall

    lw t5, 0(t6)
    mv a0, t5
    call print_number

    addi t1, t1, 1

    # 25 raides masyve
    li t5, 25
    bgt t1, t5, print_latin_letter_end

    addi t6, t6, 4

    j print_latin_letter_loop

print_latin_letter_end:
    lw ra, 0(sp)
    addi sp, sp, 1
    ret


# a0 registre skaicius kuri printinti
print_number:
    # 1 byta paimam is stacko, saugosim printinima digit'a
    addi sp, sp, -1

    #const
    li t4, 10
    li t2, 1
    blt a0, t4, print_loop_start #jeigu skaicius vienazenklis, nereik ieskot

    li t2, 10

print_number_findh:
    div t3, a0, t2
    blt t3, t4, print_loop_start

    li t3, 10
    mul t2, t2, t3 #t2 *= 10
    j print_number_findh

print_loop_start:
    mv t4, a0
    
print_loop:
    li t3, 10

    li a0, STDOUT

    div a1, t4, t2 
    li t3, 10
    remu a1, a1, t3
    addi a1, a1, 48

    # issaugome apskaiciuota reiksme stacke
    sb a1, 0(sp)

    mv a1, sp

    li a2, 1
    li a7, SYS_WRITE
    ecall

    li t3, 10
    div t2, t2, t3 #t2 /= 10

    bne t2, zero, print_loop

    # grazinam stacka
    addi sp, sp, 1

    ret


