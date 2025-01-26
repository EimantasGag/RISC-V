.data 

dataStart: .word 0x10000000

.text

_start:
    li a0, 82 #R
    call alloc_node
    
    #t3 saugos head node
    mv t3, a1
    
    li a0, 86 #V
    call alloc_node
    mv t5, a1
    
    mv a0, t3
    mv a1, t5
    call add_tail
    
    li a0, 73 #I
    call alloc_node
    mv t4, a1
    
    mv a0, t3
    mv a1, t4
    call add_tail
    
    li a0, 83 #S
    call alloc_node
    mv t4, a1
    
    mv a0, t3
    mv a1, t4
    call add_tail
    
    li a0, 67 #C
    call alloc_node
    mv t4, a1
    
    mv a0, t3
    mv a1, t4
    call add_tail
    
    mv a0, t3
    call print_list
    li t1, -1
    beq a0, t1, endError
    
    mv a0, t3
    mv a1, t5
    call del_node
    li t1, -1
    beq a0, t1, endError
    
end:
    li a0, 0
    li a7, 93
    ecall
    
endError:
    li a0, -1
    li a7, 93
    ecall

# a0 head node adresas, a1 del node adresas
# grazina -1 jei nerado tokio node, kitu atveju head node adresa grazina
del_node:
    # jeigu bando galva deletinti erroras bus
    beq a0, a1, noNode
    mv t2, a0
    
findNode:
    lw t2, 1(t2)
    
    beq t2, a1, nodeExists
    
    beq t2, a0, noNode
    
    j findNode

nodeExists:
    # del next node adresas
    lw t0, 1(a1)
    
    # del prev node adresas
    lw t1, 5(a1)
    
    # value nustato i nuli
    sb x0, 0(a1)
    
    beq t0, a0, delLastNode
    
    beq t1, a1, delHeadNode
    
    # pakeicia nextnode->prev
    sw t1, 5(t0)
    
    # pakeicia prevnode->next
    sw t0, 1(t1)
    
    ret
    
noNode:
    li a0, -1
    ret
    
delLastNode:
    sw a0, 1(t1)
    ret
    
delHeadNode:
    sw t0, 5(t0)
    mv t1, a0
    
getLastNode:
    lw t1, 1(t1)
    
    bne t1, a0, getLastNode
    
    # nustato kad last node rodytu i nauja head
    sw t0, 1(t1)
    
    # a0 registre naujas head adresas
    mv a0, t0
    
    ret
    
# a0 head node
# a0 grazina paskutini isprintinta byte arba -1
print_list:    
    #t1 head saugo
    mv t1, a0
    
    mv t0, a0
printNext:
    li a7, 11
    lb a0, 0(t0)
    
    # jeigu value nulis, print error
    beq a0, x0, printError
    
    ecall 
    
    lw t0, 1(t0)
    
    # jeigu cur->next ne head, tai ieskot toliau
    bne t0, t1, printNext
    
    ret
printError:
    li a0, -1
    ret
    
#a0 registre head, a1 registre newnode
add_tail:
    #newnode->next nustato i head
    sw a0, 1(a1)
    
    #t0 saugomas cur adresas
    mv t0, a0
    
getNext:
    lw t0, 1(t0)
    lw t1, 1(t0)
    
    # jeigu cur->next ne head, tai ieskot toliau
    bne t1, a0, getNext
    
    # pakeiciamas cur->next i newnode
    sw a1, 1(t0)
    
    # pakeicia newnode->prev i cur
    sw t0, 5(a1)
    
    ret
    
# a0 registre new node value
# a1 registre grazina new node adresa arba -1 jei nepavyko alokuoti
alloc_node:
    la t0, dataStart
    lw t1, 0(t0)
    addi t1, t1, 4

getVal:   
    lb t2, 0(t1)
    
    # prideda 9 baitus jeigu reikes jumpinti
    addi t1, t1, 9
    
    # jeigu ne nulis tai ieskot kitos vietos
    bne t2, x0, getVal
    
    # rado tuscia vieta, atminusuoti jumpinimo pasiruosima
    addi t1, t1, -9 
    
    # issaugo val, prev ir next nustato i save
    sb a0, 0(t1)
    sw t1, 1(t1)
    sw t1, 5(t1)
    
    mv a1, t1
    
    ret
    