// This is assembly is roughly equivalent to the following C code:
// unsigned short sum_C(long size, unsigned short * a) {
//    unsigned short sum = 0;
//    for (int i = 0; i < size; ++i) {
//        sum += a[i];
//    }
//    return sum;
//}

// This implementation follows the Linux x86-64 calling convention:
//    %rdi contains the size
//    %rsi contains the pointer a
// and
//    %ax needs to contain the result when the function returns
// in addition, this code uses
//    %rcx to store i

// the '.global' directive indicates to the assembler to make this symbol 
// available to other files.
.global sum_multiple_accum
sum_multiple_accum: // Sid- renamed the sum function here. 
    // set sum (%ax) to 0
    xor %eax, %eax
    xor %r8d, %r8d
    xor %r9d, %r9d
    xor %r10d, %r10d
    // return immediately; special case if size (%rdi) == 0
    test %rdi, %rdi
    je .L_done
    // store i = 0 in rcx
    movq $0, %rcx
// labels starting with '.L' are local to this file
.L_loop:
    // sum (%ax) += a[i]
    addw (%rsi,%rcx,2), %ax
    // i += 1
    //according to the x86 calling convention we can change rax, rcx, rdx, r8-r11
    addw 2(%rsi,%rcx,2), %r8w
    // Sid - here is where I add the second element

    addw 4(%rsi,%rcx,2), %r9w
    // Sid - here is where I add the third element

    addw 6(%rsi,%rcx,2), %r10w
    // Sid - here is where I add the fourth element
    addq $4, %rcx
	
    // i < end?
    cmpq %rdi, %rcx
    jl .L_loop
.L_done:
    addw %r8w, %ax
    addw %r9w, %r10w
    addw %r10w, %ax
    retq
