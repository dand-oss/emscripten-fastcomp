; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=i686-unknown-unknown -mattr=cmov   | FileCheck %s --check-prefix=X86 --check-prefix=X86-NOSSE
; RUN: llc < %s -mtriple=i686-unknown-unknown -mattr=+sse   | FileCheck %s --check-prefix=X86 --check-prefix=SSE --check-prefix=X86-SSE1
; RUN: llc < %s -mtriple=i686-unknown-unknown -mattr=+sse2  | FileCheck %s --check-prefix=X86 --check-prefix=SSE --check-prefix=X86-SSE2
; RUN: llc < %s -mtriple=x86_64-unknown-unknown             | FileCheck %s --check-prefix=X64 --check-prefix=X64-SSE2
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=avx  | FileCheck %s --check-prefix=X64 --check-prefix=X64-AVX --check-prefix=X64-AVX1
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=avx2 | FileCheck %s --check-prefix=X64 --check-prefix=X64-AVX --check-prefix=X64-AVX2

; This tests codegen time inlining/optimization of memcmp
; rdar://6480398

@.str = private constant [65 x i8] c"0123456789012345678901234567890123456789012345678901234567890123\00", align 1

declare i32 @memcmp(i8*, i8*, i64)

define i32 @length0(i8* %X, i8* %Y) nounwind {
; X86-LABEL: length0:
; X86:       # %bb.0:
; X86-NEXT:    xorl %eax, %eax
; X86-NEXT:    retl
;
; X64-LABEL: length0:
; X64:       # %bb.0:
; X64-NEXT:    xorl %eax, %eax
; X64-NEXT:    retq
   %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 0) nounwind
   ret i32 %m
 }

define i1 @length0_eq(i8* %X, i8* %Y) nounwind {
; X86-LABEL: length0_eq:
; X86:       # %bb.0:
; X86-NEXT:    movb $1, %al
; X86-NEXT:    retl
;
; X64-LABEL: length0_eq:
; X64:       # %bb.0:
; X64-NEXT:    movb $1, %al
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 0) nounwind
  %c = icmp eq i32 %m, 0
  ret i1 %c
}

define i32 @length2(i8* %X, i8* %Y) nounwind {
; X86-LABEL: length2:
; X86:       # %bb.0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-NEXT:    movzwl (%ecx), %ecx
; X86-NEXT:    movzwl (%eax), %edx
; X86-NEXT:    rolw $8, %cx
; X86-NEXT:    rolw $8, %dx
; X86-NEXT:    movzwl %cx, %eax
; X86-NEXT:    movzwl %dx, %ecx
; X86-NEXT:    subl %ecx, %eax
; X86-NEXT:    retl
;
; X64-LABEL: length2:
; X64:       # %bb.0:
; X64-NEXT:    movzwl (%rdi), %eax
; X64-NEXT:    movzwl (%rsi), %ecx
; X64-NEXT:    rolw $8, %ax
; X64-NEXT:    rolw $8, %cx
; X64-NEXT:    movzwl %ax, %eax
; X64-NEXT:    movzwl %cx, %ecx
; X64-NEXT:    subl %ecx, %eax
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 2) nounwind
  ret i32 %m
}

define i1 @length2_eq(i8* %X, i8* %Y) nounwind {
; X86-LABEL: length2_eq:
; X86:       # %bb.0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-NEXT:    movzwl (%ecx), %ecx
; X86-NEXT:    cmpw (%eax), %cx
; X86-NEXT:    sete %al
; X86-NEXT:    retl
;
; X64-LABEL: length2_eq:
; X64:       # %bb.0:
; X64-NEXT:    movzwl (%rdi), %eax
; X64-NEXT:    cmpw (%rsi), %ax
; X64-NEXT:    sete %al
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 2) nounwind
  %c = icmp eq i32 %m, 0
  ret i1 %c
}

define i1 @length2_eq_const(i8* %X) nounwind {
; X86-LABEL: length2_eq_const:
; X86:       # %bb.0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movzwl (%eax), %eax
; X86-NEXT:    cmpl $12849, %eax # imm = 0x3231
; X86-NEXT:    setne %al
; X86-NEXT:    retl
;
; X64-LABEL: length2_eq_const:
; X64:       # %bb.0:
; X64-NEXT:    movzwl (%rdi), %eax
; X64-NEXT:    cmpl $12849, %eax # imm = 0x3231
; X64-NEXT:    setne %al
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* getelementptr inbounds ([65 x i8], [65 x i8]* @.str, i32 0, i32 1), i64 2) nounwind
  %c = icmp ne i32 %m, 0
  ret i1 %c
}

define i1 @length2_eq_nobuiltin_attr(i8* %X, i8* %Y) nounwind {
; X86-LABEL: length2_eq_nobuiltin_attr:
; X86:       # %bb.0:
; X86-NEXT:    pushl $0
; X86-NEXT:    pushl $2
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    calll memcmp
; X86-NEXT:    addl $16, %esp
; X86-NEXT:    testl %eax, %eax
; X86-NEXT:    sete %al
; X86-NEXT:    retl
;
; X64-LABEL: length2_eq_nobuiltin_attr:
; X64:       # %bb.0:
; X64-NEXT:    pushq %rax
; X64-NEXT:    movl $2, %edx
; X64-NEXT:    callq memcmp
; X64-NEXT:    testl %eax, %eax
; X64-NEXT:    sete %al
; X64-NEXT:    popq %rcx
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 2) nounwind nobuiltin
  %c = icmp eq i32 %m, 0
  ret i1 %c
}

define i32 @length3(i8* %X, i8* %Y) nounwind {
; X86-LABEL: length3:
; X86:       # %bb.0: # %loadbb
; X86-NEXT:    pushl %esi
; X86-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movzwl (%eax), %edx
; X86-NEXT:    movzwl (%ecx), %esi
; X86-NEXT:    rolw $8, %dx
; X86-NEXT:    rolw $8, %si
; X86-NEXT:    cmpw %si, %dx
; X86-NEXT:    jne .LBB6_1
; X86-NEXT:  # %bb.2: # %loadbb1
; X86-NEXT:    movzbl 2(%eax), %eax
; X86-NEXT:    movzbl 2(%ecx), %ecx
; X86-NEXT:    subl %ecx, %eax
; X86-NEXT:    popl %esi
; X86-NEXT:    retl
; X86-NEXT:  .LBB6_1: # %res_block
; X86-NEXT:    setae %al
; X86-NEXT:    movzbl %al, %eax
; X86-NEXT:    leal -1(%eax,%eax), %eax
; X86-NEXT:    popl %esi
; X86-NEXT:    retl
;
; X64-LABEL: length3:
; X64:       # %bb.0: # %loadbb
; X64-NEXT:    movzwl (%rdi), %eax
; X64-NEXT:    movzwl (%rsi), %ecx
; X64-NEXT:    rolw $8, %ax
; X64-NEXT:    rolw $8, %cx
; X64-NEXT:    cmpw %cx, %ax
; X64-NEXT:    jne .LBB6_1
; X64-NEXT:  # %bb.2: # %loadbb1
; X64-NEXT:    movzbl 2(%rdi), %eax
; X64-NEXT:    movzbl 2(%rsi), %ecx
; X64-NEXT:    subl %ecx, %eax
; X64-NEXT:    retq
; X64-NEXT:  .LBB6_1: # %res_block
; X64-NEXT:    setae %al
; X64-NEXT:    movzbl %al, %eax
; X64-NEXT:    leal -1(%rax,%rax), %eax
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 3) nounwind
  ret i32 %m
}

define i1 @length3_eq(i8* %X, i8* %Y) nounwind {
; X86-LABEL: length3_eq:
; X86:       # %bb.0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-NEXT:    movzwl (%ecx), %edx
; X86-NEXT:    cmpw (%eax), %dx
; X86-NEXT:    jne .LBB7_2
; X86-NEXT:  # %bb.1: # %loadbb1
; X86-NEXT:    movb 2(%ecx), %dl
; X86-NEXT:    xorl %ecx, %ecx
; X86-NEXT:    cmpb 2(%eax), %dl
; X86-NEXT:    je .LBB7_3
; X86-NEXT:  .LBB7_2: # %res_block
; X86-NEXT:    movl $1, %ecx
; X86-NEXT:  .LBB7_3: # %endblock
; X86-NEXT:    testl %ecx, %ecx
; X86-NEXT:    setne %al
; X86-NEXT:    retl
;
; X64-LABEL: length3_eq:
; X64:       # %bb.0:
; X64-NEXT:    movzwl (%rdi), %eax
; X64-NEXT:    cmpw (%rsi), %ax
; X64-NEXT:    jne .LBB7_2
; X64-NEXT:  # %bb.1: # %loadbb1
; X64-NEXT:    movb 2(%rdi), %cl
; X64-NEXT:    xorl %eax, %eax
; X64-NEXT:    cmpb 2(%rsi), %cl
; X64-NEXT:    je .LBB7_3
; X64-NEXT:  .LBB7_2: # %res_block
; X64-NEXT:    movl $1, %eax
; X64-NEXT:  .LBB7_3: # %endblock
; X64-NEXT:    testl %eax, %eax
; X64-NEXT:    setne %al
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 3) nounwind
  %c = icmp ne i32 %m, 0
  ret i1 %c
}

define i32 @length4(i8* %X, i8* %Y) nounwind {
; X86-LABEL: length4:
; X86:       # %bb.0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-NEXT:    movl (%ecx), %ecx
; X86-NEXT:    movl (%eax), %edx
; X86-NEXT:    bswapl %ecx
; X86-NEXT:    bswapl %edx
; X86-NEXT:    xorl %eax, %eax
; X86-NEXT:    cmpl %edx, %ecx
; X86-NEXT:    seta %al
; X86-NEXT:    sbbl $0, %eax
; X86-NEXT:    retl
;
; X64-LABEL: length4:
; X64:       # %bb.0:
; X64-NEXT:    movl (%rdi), %ecx
; X64-NEXT:    movl (%rsi), %edx
; X64-NEXT:    bswapl %ecx
; X64-NEXT:    bswapl %edx
; X64-NEXT:    xorl %eax, %eax
; X64-NEXT:    cmpl %edx, %ecx
; X64-NEXT:    seta %al
; X64-NEXT:    sbbl $0, %eax
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 4) nounwind
  ret i32 %m
}

define i1 @length4_eq(i8* %X, i8* %Y) nounwind {
; X86-LABEL: length4_eq:
; X86:       # %bb.0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-NEXT:    movl (%ecx), %ecx
; X86-NEXT:    cmpl (%eax), %ecx
; X86-NEXT:    setne %al
; X86-NEXT:    retl
;
; X64-LABEL: length4_eq:
; X64:       # %bb.0:
; X64-NEXT:    movl (%rdi), %eax
; X64-NEXT:    cmpl (%rsi), %eax
; X64-NEXT:    setne %al
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 4) nounwind
  %c = icmp ne i32 %m, 0
  ret i1 %c
}

define i1 @length4_eq_const(i8* %X) nounwind {
; X86-LABEL: length4_eq_const:
; X86:       # %bb.0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    cmpl $875770417, (%eax) # imm = 0x34333231
; X86-NEXT:    sete %al
; X86-NEXT:    retl
;
; X64-LABEL: length4_eq_const:
; X64:       # %bb.0:
; X64-NEXT:    cmpl $875770417, (%rdi) # imm = 0x34333231
; X64-NEXT:    sete %al
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* getelementptr inbounds ([65 x i8], [65 x i8]* @.str, i32 0, i32 1), i64 4) nounwind
  %c = icmp eq i32 %m, 0
  ret i1 %c
}

define i32 @length5(i8* %X, i8* %Y) nounwind {
; X86-LABEL: length5:
; X86:       # %bb.0: # %loadbb
; X86-NEXT:    pushl %esi
; X86-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movl (%eax), %edx
; X86-NEXT:    movl (%ecx), %esi
; X86-NEXT:    bswapl %edx
; X86-NEXT:    bswapl %esi
; X86-NEXT:    cmpl %esi, %edx
; X86-NEXT:    jne .LBB11_1
; X86-NEXT:  # %bb.2: # %loadbb1
; X86-NEXT:    movzbl 4(%eax), %eax
; X86-NEXT:    movzbl 4(%ecx), %ecx
; X86-NEXT:    subl %ecx, %eax
; X86-NEXT:    popl %esi
; X86-NEXT:    retl
; X86-NEXT:  .LBB11_1: # %res_block
; X86-NEXT:    setae %al
; X86-NEXT:    movzbl %al, %eax
; X86-NEXT:    leal -1(%eax,%eax), %eax
; X86-NEXT:    popl %esi
; X86-NEXT:    retl
;
; X64-LABEL: length5:
; X64:       # %bb.0: # %loadbb
; X64-NEXT:    movl (%rdi), %eax
; X64-NEXT:    movl (%rsi), %ecx
; X64-NEXT:    bswapl %eax
; X64-NEXT:    bswapl %ecx
; X64-NEXT:    cmpl %ecx, %eax
; X64-NEXT:    jne .LBB11_1
; X64-NEXT:  # %bb.2: # %loadbb1
; X64-NEXT:    movzbl 4(%rdi), %eax
; X64-NEXT:    movzbl 4(%rsi), %ecx
; X64-NEXT:    subl %ecx, %eax
; X64-NEXT:    retq
; X64-NEXT:  .LBB11_1: # %res_block
; X64-NEXT:    setae %al
; X64-NEXT:    movzbl %al, %eax
; X64-NEXT:    leal -1(%rax,%rax), %eax
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 5) nounwind
  ret i32 %m
}

define i1 @length5_eq(i8* %X, i8* %Y) nounwind {
; X86-LABEL: length5_eq:
; X86:       # %bb.0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-NEXT:    movl (%ecx), %edx
; X86-NEXT:    cmpl (%eax), %edx
; X86-NEXT:    jne .LBB12_2
; X86-NEXT:  # %bb.1: # %loadbb1
; X86-NEXT:    movb 4(%ecx), %dl
; X86-NEXT:    xorl %ecx, %ecx
; X86-NEXT:    cmpb 4(%eax), %dl
; X86-NEXT:    je .LBB12_3
; X86-NEXT:  .LBB12_2: # %res_block
; X86-NEXT:    movl $1, %ecx
; X86-NEXT:  .LBB12_3: # %endblock
; X86-NEXT:    testl %ecx, %ecx
; X86-NEXT:    setne %al
; X86-NEXT:    retl
;
; X64-LABEL: length5_eq:
; X64:       # %bb.0:
; X64-NEXT:    movl (%rdi), %eax
; X64-NEXT:    cmpl (%rsi), %eax
; X64-NEXT:    jne .LBB12_2
; X64-NEXT:  # %bb.1: # %loadbb1
; X64-NEXT:    movb 4(%rdi), %cl
; X64-NEXT:    xorl %eax, %eax
; X64-NEXT:    cmpb 4(%rsi), %cl
; X64-NEXT:    je .LBB12_3
; X64-NEXT:  .LBB12_2: # %res_block
; X64-NEXT:    movl $1, %eax
; X64-NEXT:  .LBB12_3: # %endblock
; X64-NEXT:    testl %eax, %eax
; X64-NEXT:    setne %al
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 5) nounwind
  %c = icmp ne i32 %m, 0
  ret i1 %c
}

define i32 @length8(i8* %X, i8* %Y) nounwind {
; X86-LABEL: length8:
; X86:       # %bb.0:
; X86-NEXT:    pushl %esi
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movl {{[0-9]+}}(%esp), %esi
; X86-NEXT:    movl (%esi), %ecx
; X86-NEXT:    movl (%eax), %edx
; X86-NEXT:    bswapl %ecx
; X86-NEXT:    bswapl %edx
; X86-NEXT:    cmpl %edx, %ecx
; X86-NEXT:    jne .LBB13_2
; X86-NEXT:  # %bb.1: # %loadbb1
; X86-NEXT:    movl 4(%esi), %ecx
; X86-NEXT:    movl 4(%eax), %edx
; X86-NEXT:    bswapl %ecx
; X86-NEXT:    bswapl %edx
; X86-NEXT:    xorl %eax, %eax
; X86-NEXT:    cmpl %edx, %ecx
; X86-NEXT:    je .LBB13_3
; X86-NEXT:  .LBB13_2: # %res_block
; X86-NEXT:    xorl %eax, %eax
; X86-NEXT:    cmpl %edx, %ecx
; X86-NEXT:    setae %al
; X86-NEXT:    leal -1(%eax,%eax), %eax
; X86-NEXT:  .LBB13_3: # %endblock
; X86-NEXT:    popl %esi
; X86-NEXT:    retl
;
; X64-LABEL: length8:
; X64:       # %bb.0:
; X64-NEXT:    movq (%rdi), %rcx
; X64-NEXT:    movq (%rsi), %rdx
; X64-NEXT:    bswapq %rcx
; X64-NEXT:    bswapq %rdx
; X64-NEXT:    xorl %eax, %eax
; X64-NEXT:    cmpq %rdx, %rcx
; X64-NEXT:    seta %al
; X64-NEXT:    sbbl $0, %eax
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 8) nounwind
  ret i32 %m
}

define i1 @length8_eq(i8* %X, i8* %Y) nounwind {
; X86-LABEL: length8_eq:
; X86:       # %bb.0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-NEXT:    movl (%ecx), %edx
; X86-NEXT:    cmpl (%eax), %edx
; X86-NEXT:    jne .LBB14_2
; X86-NEXT:  # %bb.1: # %loadbb1
; X86-NEXT:    movl 4(%ecx), %edx
; X86-NEXT:    xorl %ecx, %ecx
; X86-NEXT:    cmpl 4(%eax), %edx
; X86-NEXT:    je .LBB14_3
; X86-NEXT:  .LBB14_2: # %res_block
; X86-NEXT:    movl $1, %ecx
; X86-NEXT:  .LBB14_3: # %endblock
; X86-NEXT:    testl %ecx, %ecx
; X86-NEXT:    sete %al
; X86-NEXT:    retl
;
; X64-LABEL: length8_eq:
; X64:       # %bb.0:
; X64-NEXT:    movq (%rdi), %rax
; X64-NEXT:    cmpq (%rsi), %rax
; X64-NEXT:    sete %al
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 8) nounwind
  %c = icmp eq i32 %m, 0
  ret i1 %c
}

define i1 @length8_eq_const(i8* %X) nounwind {
; X86-LABEL: length8_eq_const:
; X86:       # %bb.0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-NEXT:    cmpl $858927408, (%ecx) # imm = 0x33323130
; X86-NEXT:    jne .LBB15_2
; X86-NEXT:  # %bb.1: # %loadbb1
; X86-NEXT:    xorl %eax, %eax
; X86-NEXT:    cmpl $926299444, 4(%ecx) # imm = 0x37363534
; X86-NEXT:    je .LBB15_3
; X86-NEXT:  .LBB15_2: # %res_block
; X86-NEXT:    movl $1, %eax
; X86-NEXT:  .LBB15_3: # %endblock
; X86-NEXT:    testl %eax, %eax
; X86-NEXT:    setne %al
; X86-NEXT:    retl
;
; X64-LABEL: length8_eq_const:
; X64:       # %bb.0:
; X64-NEXT:    movabsq $3978425819141910832, %rax # imm = 0x3736353433323130
; X64-NEXT:    cmpq %rax, (%rdi)
; X64-NEXT:    setne %al
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* getelementptr inbounds ([65 x i8], [65 x i8]* @.str, i32 0, i32 0), i64 8) nounwind
  %c = icmp ne i32 %m, 0
  ret i1 %c
}

define i1 @length12_eq(i8* %X, i8* %Y) nounwind {
; X86-LABEL: length12_eq:
; X86:       # %bb.0:
; X86-NEXT:    pushl $0
; X86-NEXT:    pushl $12
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    calll memcmp
; X86-NEXT:    addl $16, %esp
; X86-NEXT:    testl %eax, %eax
; X86-NEXT:    setne %al
; X86-NEXT:    retl
;
; X64-LABEL: length12_eq:
; X64:       # %bb.0:
; X64-NEXT:    movq (%rdi), %rax
; X64-NEXT:    cmpq (%rsi), %rax
; X64-NEXT:    jne .LBB16_2
; X64-NEXT:  # %bb.1: # %loadbb1
; X64-NEXT:    movl 8(%rdi), %ecx
; X64-NEXT:    xorl %eax, %eax
; X64-NEXT:    cmpl 8(%rsi), %ecx
; X64-NEXT:    je .LBB16_3
; X64-NEXT:  .LBB16_2: # %res_block
; X64-NEXT:    movl $1, %eax
; X64-NEXT:  .LBB16_3: # %endblock
; X64-NEXT:    testl %eax, %eax
; X64-NEXT:    setne %al
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 12) nounwind
  %c = icmp ne i32 %m, 0
  ret i1 %c
}

define i32 @length12(i8* %X, i8* %Y) nounwind {
; X86-LABEL: length12:
; X86:       # %bb.0:
; X86-NEXT:    pushl $0
; X86-NEXT:    pushl $12
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    calll memcmp
; X86-NEXT:    addl $16, %esp
; X86-NEXT:    retl
;
; X64-LABEL: length12:
; X64:       # %bb.0:
; X64-NEXT:    movq (%rdi), %rcx
; X64-NEXT:    movq (%rsi), %rdx
; X64-NEXT:    bswapq %rcx
; X64-NEXT:    bswapq %rdx
; X64-NEXT:    cmpq %rdx, %rcx
; X64-NEXT:    jne .LBB17_2
; X64-NEXT:  # %bb.1: # %loadbb1
; X64-NEXT:    movl 8(%rdi), %ecx
; X64-NEXT:    movl 8(%rsi), %edx
; X64-NEXT:    bswapl %ecx
; X64-NEXT:    bswapl %edx
; X64-NEXT:    xorl %eax, %eax
; X64-NEXT:    cmpq %rdx, %rcx
; X64-NEXT:    je .LBB17_3
; X64-NEXT:  .LBB17_2: # %res_block
; X64-NEXT:    xorl %eax, %eax
; X64-NEXT:    cmpq %rdx, %rcx
; X64-NEXT:    setae %al
; X64-NEXT:    leal -1(%rax,%rax), %eax
; X64-NEXT:  .LBB17_3: # %endblock
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 12) nounwind
  ret i32 %m
}

; PR33329 - https://bugs.llvm.org/show_bug.cgi?id=33329

define i32 @length16(i8* %X, i8* %Y) nounwind {
; X86-LABEL: length16:
; X86:       # %bb.0:
; X86-NEXT:    pushl $0
; X86-NEXT:    pushl $16
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    calll memcmp
; X86-NEXT:    addl $16, %esp
; X86-NEXT:    retl
;
; X64-LABEL: length16:
; X64:       # %bb.0:
; X64-NEXT:    movq (%rdi), %rcx
; X64-NEXT:    movq (%rsi), %rdx
; X64-NEXT:    bswapq %rcx
; X64-NEXT:    bswapq %rdx
; X64-NEXT:    cmpq %rdx, %rcx
; X64-NEXT:    jne .LBB18_2
; X64-NEXT:  # %bb.1: # %loadbb1
; X64-NEXT:    movq 8(%rdi), %rcx
; X64-NEXT:    movq 8(%rsi), %rdx
; X64-NEXT:    bswapq %rcx
; X64-NEXT:    bswapq %rdx
; X64-NEXT:    xorl %eax, %eax
; X64-NEXT:    cmpq %rdx, %rcx
; X64-NEXT:    je .LBB18_3
; X64-NEXT:  .LBB18_2: # %res_block
; X64-NEXT:    xorl %eax, %eax
; X64-NEXT:    cmpq %rdx, %rcx
; X64-NEXT:    setae %al
; X64-NEXT:    leal -1(%rax,%rax), %eax
; X64-NEXT:  .LBB18_3: # %endblock
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 16) nounwind
  ret i32 %m
}

define i1 @length16_eq(i8* %x, i8* %y) nounwind {
; X86-NOSSE-LABEL: length16_eq:
; X86-NOSSE:       # %bb.0:
; X86-NOSSE-NEXT:    pushl $0
; X86-NOSSE-NEXT:    pushl $16
; X86-NOSSE-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NOSSE-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NOSSE-NEXT:    calll memcmp
; X86-NOSSE-NEXT:    addl $16, %esp
; X86-NOSSE-NEXT:    testl %eax, %eax
; X86-NOSSE-NEXT:    setne %al
; X86-NOSSE-NEXT:    retl
;
; X86-SSE1-LABEL: length16_eq:
; X86-SSE1:       # %bb.0:
; X86-SSE1-NEXT:    pushl $0
; X86-SSE1-NEXT:    pushl $16
; X86-SSE1-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-SSE1-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-SSE1-NEXT:    calll memcmp
; X86-SSE1-NEXT:    addl $16, %esp
; X86-SSE1-NEXT:    testl %eax, %eax
; X86-SSE1-NEXT:    setne %al
; X86-SSE1-NEXT:    retl
;
; X86-SSE2-LABEL: length16_eq:
; X86-SSE2:       # %bb.0:
; X86-SSE2-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-SSE2-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-SSE2-NEXT:    movdqu (%ecx), %xmm0
; X86-SSE2-NEXT:    movdqu (%eax), %xmm1
; X86-SSE2-NEXT:    pcmpeqb %xmm0, %xmm1
; X86-SSE2-NEXT:    pmovmskb %xmm1, %eax
; X86-SSE2-NEXT:    cmpl $65535, %eax # imm = 0xFFFF
; X86-SSE2-NEXT:    setne %al
; X86-SSE2-NEXT:    retl
;
; X64-SSE2-LABEL: length16_eq:
; X64-SSE2:       # %bb.0:
; X64-SSE2-NEXT:    movdqu (%rdi), %xmm0
; X64-SSE2-NEXT:    movdqu (%rsi), %xmm1
; X64-SSE2-NEXT:    pcmpeqb %xmm0, %xmm1
; X64-SSE2-NEXT:    pmovmskb %xmm1, %eax
; X64-SSE2-NEXT:    cmpl $65535, %eax # imm = 0xFFFF
; X64-SSE2-NEXT:    setne %al
; X64-SSE2-NEXT:    retq
;
; X64-AVX-LABEL: length16_eq:
; X64-AVX:       # %bb.0:
; X64-AVX-NEXT:    vmovdqu (%rdi), %xmm0
; X64-AVX-NEXT:    vpcmpeqb (%rsi), %xmm0, %xmm0
; X64-AVX-NEXT:    vpmovmskb %xmm0, %eax
; X64-AVX-NEXT:    cmpl $65535, %eax # imm = 0xFFFF
; X64-AVX-NEXT:    setne %al
; X64-AVX-NEXT:    retq
  %call = tail call i32 @memcmp(i8* %x, i8* %y, i64 16) nounwind
  %cmp = icmp ne i32 %call, 0
  ret i1 %cmp
}

define i1 @length16_eq_const(i8* %X) nounwind {
; X86-NOSSE-LABEL: length16_eq_const:
; X86-NOSSE:       # %bb.0:
; X86-NOSSE-NEXT:    pushl $0
; X86-NOSSE-NEXT:    pushl $16
; X86-NOSSE-NEXT:    pushl $.L.str
; X86-NOSSE-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NOSSE-NEXT:    calll memcmp
; X86-NOSSE-NEXT:    addl $16, %esp
; X86-NOSSE-NEXT:    testl %eax, %eax
; X86-NOSSE-NEXT:    sete %al
; X86-NOSSE-NEXT:    retl
;
; X86-SSE1-LABEL: length16_eq_const:
; X86-SSE1:       # %bb.0:
; X86-SSE1-NEXT:    pushl $0
; X86-SSE1-NEXT:    pushl $16
; X86-SSE1-NEXT:    pushl $.L.str
; X86-SSE1-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-SSE1-NEXT:    calll memcmp
; X86-SSE1-NEXT:    addl $16, %esp
; X86-SSE1-NEXT:    testl %eax, %eax
; X86-SSE1-NEXT:    sete %al
; X86-SSE1-NEXT:    retl
;
; X86-SSE2-LABEL: length16_eq_const:
; X86-SSE2:       # %bb.0:
; X86-SSE2-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-SSE2-NEXT:    movdqu (%eax), %xmm0
; X86-SSE2-NEXT:    pcmpeqb {{\.LCPI.*}}, %xmm0
; X86-SSE2-NEXT:    pmovmskb %xmm0, %eax
; X86-SSE2-NEXT:    cmpl $65535, %eax # imm = 0xFFFF
; X86-SSE2-NEXT:    sete %al
; X86-SSE2-NEXT:    retl
;
; X64-SSE2-LABEL: length16_eq_const:
; X64-SSE2:       # %bb.0:
; X64-SSE2-NEXT:    movdqu (%rdi), %xmm0
; X64-SSE2-NEXT:    pcmpeqb {{.*}}(%rip), %xmm0
; X64-SSE2-NEXT:    pmovmskb %xmm0, %eax
; X64-SSE2-NEXT:    cmpl $65535, %eax # imm = 0xFFFF
; X64-SSE2-NEXT:    sete %al
; X64-SSE2-NEXT:    retq
;
; X64-AVX-LABEL: length16_eq_const:
; X64-AVX:       # %bb.0:
; X64-AVX-NEXT:    vmovdqu (%rdi), %xmm0
; X64-AVX-NEXT:    vpcmpeqb {{.*}}(%rip), %xmm0, %xmm0
; X64-AVX-NEXT:    vpmovmskb %xmm0, %eax
; X64-AVX-NEXT:    cmpl $65535, %eax # imm = 0xFFFF
; X64-AVX-NEXT:    sete %al
; X64-AVX-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* getelementptr inbounds ([65 x i8], [65 x i8]* @.str, i32 0, i32 0), i64 16) nounwind
  %c = icmp eq i32 %m, 0
  ret i1 %c
}

; PR33914 - https://bugs.llvm.org/show_bug.cgi?id=33914

define i32 @length24(i8* %X, i8* %Y) nounwind {
; X86-LABEL: length24:
; X86:       # %bb.0:
; X86-NEXT:    pushl $0
; X86-NEXT:    pushl $24
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    calll memcmp
; X86-NEXT:    addl $16, %esp
; X86-NEXT:    retl
;
; X64-LABEL: length24:
; X64:       # %bb.0:
; X64-NEXT:    movl $24, %edx
; X64-NEXT:    jmp memcmp # TAILCALL
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 24) nounwind
  ret i32 %m
}

define i1 @length24_eq(i8* %x, i8* %y) nounwind {
; X86-LABEL: length24_eq:
; X86:       # %bb.0:
; X86-NEXT:    pushl $0
; X86-NEXT:    pushl $24
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    calll memcmp
; X86-NEXT:    addl $16, %esp
; X86-NEXT:    testl %eax, %eax
; X86-NEXT:    sete %al
; X86-NEXT:    retl
;
; X64-SSE2-LABEL: length24_eq:
; X64-SSE2:       # %bb.0:
; X64-SSE2-NEXT:    movdqu (%rdi), %xmm0
; X64-SSE2-NEXT:    movdqu (%rsi), %xmm1
; X64-SSE2-NEXT:    pcmpeqb %xmm0, %xmm1
; X64-SSE2-NEXT:    pmovmskb %xmm1, %eax
; X64-SSE2-NEXT:    cmpl $65535, %eax # imm = 0xFFFF
; X64-SSE2-NEXT:    jne .LBB22_2
; X64-SSE2-NEXT:  # %bb.1: # %loadbb1
; X64-SSE2-NEXT:    movq 16(%rdi), %rcx
; X64-SSE2-NEXT:    xorl %eax, %eax
; X64-SSE2-NEXT:    cmpq 16(%rsi), %rcx
; X64-SSE2-NEXT:    je .LBB22_3
; X64-SSE2-NEXT:  .LBB22_2: # %res_block
; X64-SSE2-NEXT:    movl $1, %eax
; X64-SSE2-NEXT:  .LBB22_3: # %endblock
; X64-SSE2-NEXT:    testl %eax, %eax
; X64-SSE2-NEXT:    sete %al
; X64-SSE2-NEXT:    retq
;
; X64-AVX-LABEL: length24_eq:
; X64-AVX:       # %bb.0:
; X64-AVX-NEXT:    vmovdqu (%rdi), %xmm0
; X64-AVX-NEXT:    vpcmpeqb (%rsi), %xmm0, %xmm0
; X64-AVX-NEXT:    vpmovmskb %xmm0, %eax
; X64-AVX-NEXT:    cmpl $65535, %eax # imm = 0xFFFF
; X64-AVX-NEXT:    jne .LBB22_2
; X64-AVX-NEXT:  # %bb.1: # %loadbb1
; X64-AVX-NEXT:    movq 16(%rdi), %rcx
; X64-AVX-NEXT:    xorl %eax, %eax
; X64-AVX-NEXT:    cmpq 16(%rsi), %rcx
; X64-AVX-NEXT:    je .LBB22_3
; X64-AVX-NEXT:  .LBB22_2: # %res_block
; X64-AVX-NEXT:    movl $1, %eax
; X64-AVX-NEXT:  .LBB22_3: # %endblock
; X64-AVX-NEXT:    testl %eax, %eax
; X64-AVX-NEXT:    sete %al
; X64-AVX-NEXT:    retq
  %call = tail call i32 @memcmp(i8* %x, i8* %y, i64 24) nounwind
  %cmp = icmp eq i32 %call, 0
  ret i1 %cmp
}

define i1 @length24_eq_const(i8* %X) nounwind {
; X86-LABEL: length24_eq_const:
; X86:       # %bb.0:
; X86-NEXT:    pushl $0
; X86-NEXT:    pushl $24
; X86-NEXT:    pushl $.L.str
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    calll memcmp
; X86-NEXT:    addl $16, %esp
; X86-NEXT:    testl %eax, %eax
; X86-NEXT:    setne %al
; X86-NEXT:    retl
;
; X64-SSE2-LABEL: length24_eq_const:
; X64-SSE2:       # %bb.0:
; X64-SSE2-NEXT:    movdqu (%rdi), %xmm0
; X64-SSE2-NEXT:    pcmpeqb {{.*}}(%rip), %xmm0
; X64-SSE2-NEXT:    pmovmskb %xmm0, %eax
; X64-SSE2-NEXT:    cmpl $65535, %eax # imm = 0xFFFF
; X64-SSE2-NEXT:    jne .LBB23_2
; X64-SSE2-NEXT:  # %bb.1: # %loadbb1
; X64-SSE2-NEXT:    xorl %eax, %eax
; X64-SSE2-NEXT:    movabsq $3689065127958034230, %rcx # imm = 0x3332313039383736
; X64-SSE2-NEXT:    cmpq %rcx, 16(%rdi)
; X64-SSE2-NEXT:    je .LBB23_3
; X64-SSE2-NEXT:  .LBB23_2: # %res_block
; X64-SSE2-NEXT:    movl $1, %eax
; X64-SSE2-NEXT:  .LBB23_3: # %endblock
; X64-SSE2-NEXT:    testl %eax, %eax
; X64-SSE2-NEXT:    setne %al
; X64-SSE2-NEXT:    retq
;
; X64-AVX-LABEL: length24_eq_const:
; X64-AVX:       # %bb.0:
; X64-AVX-NEXT:    vmovdqu (%rdi), %xmm0
; X64-AVX-NEXT:    vpcmpeqb {{.*}}(%rip), %xmm0, %xmm0
; X64-AVX-NEXT:    vpmovmskb %xmm0, %eax
; X64-AVX-NEXT:    cmpl $65535, %eax # imm = 0xFFFF
; X64-AVX-NEXT:    jne .LBB23_2
; X64-AVX-NEXT:  # %bb.1: # %loadbb1
; X64-AVX-NEXT:    xorl %eax, %eax
; X64-AVX-NEXT:    movabsq $3689065127958034230, %rcx # imm = 0x3332313039383736
; X64-AVX-NEXT:    cmpq %rcx, 16(%rdi)
; X64-AVX-NEXT:    je .LBB23_3
; X64-AVX-NEXT:  .LBB23_2: # %res_block
; X64-AVX-NEXT:    movl $1, %eax
; X64-AVX-NEXT:  .LBB23_3: # %endblock
; X64-AVX-NEXT:    testl %eax, %eax
; X64-AVX-NEXT:    setne %al
; X64-AVX-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* getelementptr inbounds ([65 x i8], [65 x i8]* @.str, i32 0, i32 0), i64 24) nounwind
  %c = icmp ne i32 %m, 0
  ret i1 %c
}

define i32 @length32(i8* %X, i8* %Y) nounwind {
; X86-LABEL: length32:
; X86:       # %bb.0:
; X86-NEXT:    pushl $0
; X86-NEXT:    pushl $32
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    calll memcmp
; X86-NEXT:    addl $16, %esp
; X86-NEXT:    retl
;
; X64-LABEL: length32:
; X64:       # %bb.0:
; X64-NEXT:    movl $32, %edx
; X64-NEXT:    jmp memcmp # TAILCALL
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 32) nounwind
  ret i32 %m
}

; PR33325 - https://bugs.llvm.org/show_bug.cgi?id=33325

define i1 @length32_eq(i8* %x, i8* %y) nounwind {
; X86-NOSSE-LABEL: length32_eq:
; X86-NOSSE:       # %bb.0:
; X86-NOSSE-NEXT:    pushl $0
; X86-NOSSE-NEXT:    pushl $32
; X86-NOSSE-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NOSSE-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NOSSE-NEXT:    calll memcmp
; X86-NOSSE-NEXT:    addl $16, %esp
; X86-NOSSE-NEXT:    testl %eax, %eax
; X86-NOSSE-NEXT:    sete %al
; X86-NOSSE-NEXT:    retl
;
; X86-SSE1-LABEL: length32_eq:
; X86-SSE1:       # %bb.0:
; X86-SSE1-NEXT:    pushl $0
; X86-SSE1-NEXT:    pushl $32
; X86-SSE1-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-SSE1-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-SSE1-NEXT:    calll memcmp
; X86-SSE1-NEXT:    addl $16, %esp
; X86-SSE1-NEXT:    testl %eax, %eax
; X86-SSE1-NEXT:    sete %al
; X86-SSE1-NEXT:    retl
;
; X86-SSE2-LABEL: length32_eq:
; X86-SSE2:       # %bb.0:
; X86-SSE2-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-SSE2-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-SSE2-NEXT:    movdqu (%ecx), %xmm0
; X86-SSE2-NEXT:    movdqu (%eax), %xmm1
; X86-SSE2-NEXT:    pcmpeqb %xmm0, %xmm1
; X86-SSE2-NEXT:    pmovmskb %xmm1, %edx
; X86-SSE2-NEXT:    cmpl $65535, %edx # imm = 0xFFFF
; X86-SSE2-NEXT:    jne .LBB25_2
; X86-SSE2-NEXT:  # %bb.1: # %loadbb1
; X86-SSE2-NEXT:    movdqu 16(%ecx), %xmm0
; X86-SSE2-NEXT:    movdqu 16(%eax), %xmm1
; X86-SSE2-NEXT:    pcmpeqb %xmm0, %xmm1
; X86-SSE2-NEXT:    pmovmskb %xmm1, %ecx
; X86-SSE2-NEXT:    xorl %eax, %eax
; X86-SSE2-NEXT:    cmpl $65535, %ecx # imm = 0xFFFF
; X86-SSE2-NEXT:    je .LBB25_3
; X86-SSE2-NEXT:  .LBB25_2: # %res_block
; X86-SSE2-NEXT:    movl $1, %eax
; X86-SSE2-NEXT:  .LBB25_3: # %endblock
; X86-SSE2-NEXT:    testl %eax, %eax
; X86-SSE2-NEXT:    sete %al
; X86-SSE2-NEXT:    retl
;
; X64-SSE2-LABEL: length32_eq:
; X64-SSE2:       # %bb.0:
; X64-SSE2-NEXT:    movdqu (%rdi), %xmm0
; X64-SSE2-NEXT:    movdqu (%rsi), %xmm1
; X64-SSE2-NEXT:    pcmpeqb %xmm0, %xmm1
; X64-SSE2-NEXT:    pmovmskb %xmm1, %eax
; X64-SSE2-NEXT:    cmpl $65535, %eax # imm = 0xFFFF
; X64-SSE2-NEXT:    jne .LBB25_2
; X64-SSE2-NEXT:  # %bb.1: # %loadbb1
; X64-SSE2-NEXT:    movdqu 16(%rdi), %xmm0
; X64-SSE2-NEXT:    movdqu 16(%rsi), %xmm1
; X64-SSE2-NEXT:    pcmpeqb %xmm0, %xmm1
; X64-SSE2-NEXT:    pmovmskb %xmm1, %ecx
; X64-SSE2-NEXT:    xorl %eax, %eax
; X64-SSE2-NEXT:    cmpl $65535, %ecx # imm = 0xFFFF
; X64-SSE2-NEXT:    je .LBB25_3
; X64-SSE2-NEXT:  .LBB25_2: # %res_block
; X64-SSE2-NEXT:    movl $1, %eax
; X64-SSE2-NEXT:  .LBB25_3: # %endblock
; X64-SSE2-NEXT:    testl %eax, %eax
; X64-SSE2-NEXT:    sete %al
; X64-SSE2-NEXT:    retq
;
; X64-AVX1-LABEL: length32_eq:
; X64-AVX1:       # %bb.0:
; X64-AVX1-NEXT:    vmovdqu (%rdi), %xmm0
; X64-AVX1-NEXT:    vpcmpeqb (%rsi), %xmm0, %xmm0
; X64-AVX1-NEXT:    vpmovmskb %xmm0, %eax
; X64-AVX1-NEXT:    cmpl $65535, %eax # imm = 0xFFFF
; X64-AVX1-NEXT:    jne .LBB25_2
; X64-AVX1-NEXT:  # %bb.1: # %loadbb1
; X64-AVX1-NEXT:    vmovdqu 16(%rdi), %xmm0
; X64-AVX1-NEXT:    vpcmpeqb 16(%rsi), %xmm0, %xmm0
; X64-AVX1-NEXT:    vpmovmskb %xmm0, %ecx
; X64-AVX1-NEXT:    xorl %eax, %eax
; X64-AVX1-NEXT:    cmpl $65535, %ecx # imm = 0xFFFF
; X64-AVX1-NEXT:    je .LBB25_3
; X64-AVX1-NEXT:  .LBB25_2: # %res_block
; X64-AVX1-NEXT:    movl $1, %eax
; X64-AVX1-NEXT:  .LBB25_3: # %endblock
; X64-AVX1-NEXT:    testl %eax, %eax
; X64-AVX1-NEXT:    sete %al
; X64-AVX1-NEXT:    retq
;
; X64-AVX2-LABEL: length32_eq:
; X64-AVX2:       # %bb.0:
; X64-AVX2-NEXT:    vmovdqu (%rdi), %ymm0
; X64-AVX2-NEXT:    vpcmpeqb (%rsi), %ymm0, %ymm0
; X64-AVX2-NEXT:    vpmovmskb %ymm0, %eax
; X64-AVX2-NEXT:    cmpl $-1, %eax
; X64-AVX2-NEXT:    sete %al
; X64-AVX2-NEXT:    vzeroupper
; X64-AVX2-NEXT:    retq
  %call = tail call i32 @memcmp(i8* %x, i8* %y, i64 32) nounwind
  %cmp = icmp eq i32 %call, 0
  ret i1 %cmp
}

define i1 @length32_eq_const(i8* %X) nounwind {
; X86-NOSSE-LABEL: length32_eq_const:
; X86-NOSSE:       # %bb.0:
; X86-NOSSE-NEXT:    pushl $0
; X86-NOSSE-NEXT:    pushl $32
; X86-NOSSE-NEXT:    pushl $.L.str
; X86-NOSSE-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NOSSE-NEXT:    calll memcmp
; X86-NOSSE-NEXT:    addl $16, %esp
; X86-NOSSE-NEXT:    testl %eax, %eax
; X86-NOSSE-NEXT:    setne %al
; X86-NOSSE-NEXT:    retl
;
; X86-SSE1-LABEL: length32_eq_const:
; X86-SSE1:       # %bb.0:
; X86-SSE1-NEXT:    pushl $0
; X86-SSE1-NEXT:    pushl $32
; X86-SSE1-NEXT:    pushl $.L.str
; X86-SSE1-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-SSE1-NEXT:    calll memcmp
; X86-SSE1-NEXT:    addl $16, %esp
; X86-SSE1-NEXT:    testl %eax, %eax
; X86-SSE1-NEXT:    setne %al
; X86-SSE1-NEXT:    retl
;
; X86-SSE2-LABEL: length32_eq_const:
; X86-SSE2:       # %bb.0:
; X86-SSE2-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-SSE2-NEXT:    movdqu (%eax), %xmm0
; X86-SSE2-NEXT:    pcmpeqb {{\.LCPI.*}}, %xmm0
; X86-SSE2-NEXT:    pmovmskb %xmm0, %ecx
; X86-SSE2-NEXT:    cmpl $65535, %ecx # imm = 0xFFFF
; X86-SSE2-NEXT:    jne .LBB26_2
; X86-SSE2-NEXT:  # %bb.1: # %loadbb1
; X86-SSE2-NEXT:    movdqu 16(%eax), %xmm0
; X86-SSE2-NEXT:    pcmpeqb {{\.LCPI.*}}, %xmm0
; X86-SSE2-NEXT:    pmovmskb %xmm0, %ecx
; X86-SSE2-NEXT:    xorl %eax, %eax
; X86-SSE2-NEXT:    cmpl $65535, %ecx # imm = 0xFFFF
; X86-SSE2-NEXT:    je .LBB26_3
; X86-SSE2-NEXT:  .LBB26_2: # %res_block
; X86-SSE2-NEXT:    movl $1, %eax
; X86-SSE2-NEXT:  .LBB26_3: # %endblock
; X86-SSE2-NEXT:    testl %eax, %eax
; X86-SSE2-NEXT:    setne %al
; X86-SSE2-NEXT:    retl
;
; X64-SSE2-LABEL: length32_eq_const:
; X64-SSE2:       # %bb.0:
; X64-SSE2-NEXT:    movdqu (%rdi), %xmm0
; X64-SSE2-NEXT:    pcmpeqb {{.*}}(%rip), %xmm0
; X64-SSE2-NEXT:    pmovmskb %xmm0, %eax
; X64-SSE2-NEXT:    cmpl $65535, %eax # imm = 0xFFFF
; X64-SSE2-NEXT:    jne .LBB26_2
; X64-SSE2-NEXT:  # %bb.1: # %loadbb1
; X64-SSE2-NEXT:    movdqu 16(%rdi), %xmm0
; X64-SSE2-NEXT:    pcmpeqb {{.*}}(%rip), %xmm0
; X64-SSE2-NEXT:    pmovmskb %xmm0, %ecx
; X64-SSE2-NEXT:    xorl %eax, %eax
; X64-SSE2-NEXT:    cmpl $65535, %ecx # imm = 0xFFFF
; X64-SSE2-NEXT:    je .LBB26_3
; X64-SSE2-NEXT:  .LBB26_2: # %res_block
; X64-SSE2-NEXT:    movl $1, %eax
; X64-SSE2-NEXT:  .LBB26_3: # %endblock
; X64-SSE2-NEXT:    testl %eax, %eax
; X64-SSE2-NEXT:    setne %al
; X64-SSE2-NEXT:    retq
;
; X64-AVX1-LABEL: length32_eq_const:
; X64-AVX1:       # %bb.0:
; X64-AVX1-NEXT:    vmovdqu (%rdi), %xmm0
; X64-AVX1-NEXT:    vpcmpeqb {{.*}}(%rip), %xmm0, %xmm0
; X64-AVX1-NEXT:    vpmovmskb %xmm0, %eax
; X64-AVX1-NEXT:    cmpl $65535, %eax # imm = 0xFFFF
; X64-AVX1-NEXT:    jne .LBB26_2
; X64-AVX1-NEXT:  # %bb.1: # %loadbb1
; X64-AVX1-NEXT:    vmovdqu 16(%rdi), %xmm0
; X64-AVX1-NEXT:    vpcmpeqb {{.*}}(%rip), %xmm0, %xmm0
; X64-AVX1-NEXT:    vpmovmskb %xmm0, %ecx
; X64-AVX1-NEXT:    xorl %eax, %eax
; X64-AVX1-NEXT:    cmpl $65535, %ecx # imm = 0xFFFF
; X64-AVX1-NEXT:    je .LBB26_3
; X64-AVX1-NEXT:  .LBB26_2: # %res_block
; X64-AVX1-NEXT:    movl $1, %eax
; X64-AVX1-NEXT:  .LBB26_3: # %endblock
; X64-AVX1-NEXT:    testl %eax, %eax
; X64-AVX1-NEXT:    setne %al
; X64-AVX1-NEXT:    retq
;
; X64-AVX2-LABEL: length32_eq_const:
; X64-AVX2:       # %bb.0:
; X64-AVX2-NEXT:    vmovdqu (%rdi), %ymm0
; X64-AVX2-NEXT:    vpcmpeqb {{.*}}(%rip), %ymm0, %ymm0
; X64-AVX2-NEXT:    vpmovmskb %ymm0, %eax
; X64-AVX2-NEXT:    cmpl $-1, %eax
; X64-AVX2-NEXT:    setne %al
; X64-AVX2-NEXT:    vzeroupper
; X64-AVX2-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* getelementptr inbounds ([65 x i8], [65 x i8]* @.str, i32 0, i32 0), i64 32) nounwind
  %c = icmp ne i32 %m, 0
  ret i1 %c
}

define i32 @length64(i8* %X, i8* %Y) nounwind {
; X86-LABEL: length64:
; X86:       # %bb.0:
; X86-NEXT:    pushl $0
; X86-NEXT:    pushl $64
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    calll memcmp
; X86-NEXT:    addl $16, %esp
; X86-NEXT:    retl
;
; X64-LABEL: length64:
; X64:       # %bb.0:
; X64-NEXT:    movl $64, %edx
; X64-NEXT:    jmp memcmp # TAILCALL
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 64) nounwind
  ret i32 %m
}

define i1 @length64_eq(i8* %x, i8* %y) nounwind {
; X86-LABEL: length64_eq:
; X86:       # %bb.0:
; X86-NEXT:    pushl $0
; X86-NEXT:    pushl $64
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    calll memcmp
; X86-NEXT:    addl $16, %esp
; X86-NEXT:    testl %eax, %eax
; X86-NEXT:    setne %al
; X86-NEXT:    retl
;
; X64-SSE2-LABEL: length64_eq:
; X64-SSE2:       # %bb.0:
; X64-SSE2-NEXT:    pushq %rax
; X64-SSE2-NEXT:    movl $64, %edx
; X64-SSE2-NEXT:    callq memcmp
; X64-SSE2-NEXT:    testl %eax, %eax
; X64-SSE2-NEXT:    setne %al
; X64-SSE2-NEXT:    popq %rcx
; X64-SSE2-NEXT:    retq
;
; X64-AVX1-LABEL: length64_eq:
; X64-AVX1:       # %bb.0:
; X64-AVX1-NEXT:    pushq %rax
; X64-AVX1-NEXT:    movl $64, %edx
; X64-AVX1-NEXT:    callq memcmp
; X64-AVX1-NEXT:    testl %eax, %eax
; X64-AVX1-NEXT:    setne %al
; X64-AVX1-NEXT:    popq %rcx
; X64-AVX1-NEXT:    retq
;
; X64-AVX2-LABEL: length64_eq:
; X64-AVX2:       # %bb.0:
; X64-AVX2-NEXT:    vmovdqu (%rdi), %ymm0
; X64-AVX2-NEXT:    vpcmpeqb (%rsi), %ymm0, %ymm0
; X64-AVX2-NEXT:    vpmovmskb %ymm0, %eax
; X64-AVX2-NEXT:    cmpl $-1, %eax
; X64-AVX2-NEXT:    jne .LBB28_2
; X64-AVX2-NEXT:  # %bb.1: # %loadbb1
; X64-AVX2-NEXT:    vmovdqu 32(%rdi), %ymm0
; X64-AVX2-NEXT:    vpcmpeqb 32(%rsi), %ymm0, %ymm0
; X64-AVX2-NEXT:    vpmovmskb %ymm0, %ecx
; X64-AVX2-NEXT:    xorl %eax, %eax
; X64-AVX2-NEXT:    cmpl $-1, %ecx
; X64-AVX2-NEXT:    je .LBB28_3
; X64-AVX2-NEXT:  .LBB28_2: # %res_block
; X64-AVX2-NEXT:    movl $1, %eax
; X64-AVX2-NEXT:  .LBB28_3: # %endblock
; X64-AVX2-NEXT:    testl %eax, %eax
; X64-AVX2-NEXT:    setne %al
; X64-AVX2-NEXT:    vzeroupper
; X64-AVX2-NEXT:    retq
  %call = tail call i32 @memcmp(i8* %x, i8* %y, i64 64) nounwind
  %cmp = icmp ne i32 %call, 0
  ret i1 %cmp
}

define i1 @length64_eq_const(i8* %X) nounwind {
; X86-LABEL: length64_eq_const:
; X86:       # %bb.0:
; X86-NEXT:    pushl $0
; X86-NEXT:    pushl $64
; X86-NEXT:    pushl $.L.str
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    calll memcmp
; X86-NEXT:    addl $16, %esp
; X86-NEXT:    testl %eax, %eax
; X86-NEXT:    sete %al
; X86-NEXT:    retl
;
; X64-SSE2-LABEL: length64_eq_const:
; X64-SSE2:       # %bb.0:
; X64-SSE2-NEXT:    pushq %rax
; X64-SSE2-NEXT:    movl $.L.str, %esi
; X64-SSE2-NEXT:    movl $64, %edx
; X64-SSE2-NEXT:    callq memcmp
; X64-SSE2-NEXT:    testl %eax, %eax
; X64-SSE2-NEXT:    sete %al
; X64-SSE2-NEXT:    popq %rcx
; X64-SSE2-NEXT:    retq
;
; X64-AVX1-LABEL: length64_eq_const:
; X64-AVX1:       # %bb.0:
; X64-AVX1-NEXT:    pushq %rax
; X64-AVX1-NEXT:    movl $.L.str, %esi
; X64-AVX1-NEXT:    movl $64, %edx
; X64-AVX1-NEXT:    callq memcmp
; X64-AVX1-NEXT:    testl %eax, %eax
; X64-AVX1-NEXT:    sete %al
; X64-AVX1-NEXT:    popq %rcx
; X64-AVX1-NEXT:    retq
;
; X64-AVX2-LABEL: length64_eq_const:
; X64-AVX2:       # %bb.0:
; X64-AVX2-NEXT:    vmovdqu (%rdi), %ymm0
; X64-AVX2-NEXT:    vpcmpeqb {{.*}}(%rip), %ymm0, %ymm0
; X64-AVX2-NEXT:    vpmovmskb %ymm0, %eax
; X64-AVX2-NEXT:    cmpl $-1, %eax
; X64-AVX2-NEXT:    jne .LBB29_2
; X64-AVX2-NEXT:  # %bb.1: # %loadbb1
; X64-AVX2-NEXT:    vmovdqu 32(%rdi), %ymm0
; X64-AVX2-NEXT:    vpcmpeqb {{.*}}(%rip), %ymm0, %ymm0
; X64-AVX2-NEXT:    vpmovmskb %ymm0, %ecx
; X64-AVX2-NEXT:    xorl %eax, %eax
; X64-AVX2-NEXT:    cmpl $-1, %ecx
; X64-AVX2-NEXT:    je .LBB29_3
; X64-AVX2-NEXT:  .LBB29_2: # %res_block
; X64-AVX2-NEXT:    movl $1, %eax
; X64-AVX2-NEXT:  .LBB29_3: # %endblock
; X64-AVX2-NEXT:    testl %eax, %eax
; X64-AVX2-NEXT:    sete %al
; X64-AVX2-NEXT:    vzeroupper
; X64-AVX2-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* getelementptr inbounds ([65 x i8], [65 x i8]* @.str, i32 0, i32 0), i64 64) nounwind
  %c = icmp eq i32 %m, 0
  ret i1 %c
}

; This checks that we do not do stupid things with huge sizes.
define i32 @huge_length(i8* %X, i8* %Y) nounwind {
; X86-LABEL: huge_length:
; X86:       # %bb.0:
; X86-NEXT:    pushl $2147483647 # imm = 0x7FFFFFFF
; X86-NEXT:    pushl $-1
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    calll memcmp
; X86-NEXT:    addl $16, %esp
; X86-NEXT:    retl
;
; X64-LABEL: huge_length:
; X64:       # %bb.0:
; X64-NEXT:    movabsq $9223372036854775807, %rdx # imm = 0x7FFFFFFFFFFFFFFF
; X64-NEXT:    jmp memcmp # TAILCALL
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 9223372036854775807) nounwind
  ret i32 %m
}


