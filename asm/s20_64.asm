section .data
indeces: dw 0C840h, 01D95h, 062EAh, 0B73Fh, 03210h, 04765h, 098BAh, 0EDCFh

section .text
struc s20_ctx
  state    resb 64
  .size:
endstruc

global _s20_setkey
global s20_setkey

global _s20_permute
global s20_permute

global _s20_stream
global s20_stream

;global s20_encrypt
;global _s20_encrypt





; void s20_setkey(s20_ctx *ctx, void *key, void *iv)
_s20_setkey:
s20_setkey:
    ;rdi [state] 64 bytes
    ;rsi [key]
    ;rdx [iv]
        
    mov r10, rdi
    mov r11, rsi

    xor r9, r9 ;Needed to clear some bytes

    mov    eax, 061707865h
    stosd   ;Saves the constant in ctx
    
    ; copy 16 bytes of 256-bit key
    movsq  
    movsq

    mov    eax, 03320646Eh
    stosd   ;Saves the next constant in ctx
    
    ;copy iv to 6,7
    xchg rsi, rdx
    movsq
    
    ; zero 64-bit counter at 8,9
    xchg rax, r9
    stosq
    
    ; store 32-bits at 10
    mov    eax, 079622D32h
    stosd
    
    ; store remainder of key at 11-14
    xchg rsi, rdx
    movsq  
    movsq
    
    ; store last 32-bits constant
    mov    eax, 06B206574h
    stosd
    
    ;restore saved registers
    mov rdi, r10
    mov rsi, r11
    
    ret

%define a rbx
%define b r8
%define c rdx
%define d r10

%define t r9d

;Internal Only, not exported
;NOT WORKING WITH C
; void s20_permute(s20_blk *blk, uint16_t index)
_s20_permute: ;index in rax
s20_permute:
    mov    a, rax
    mov    b, rax    
    mov    c, rax    
    mov    d, rax    
    
    mov    r11, rcx ;save rcx

    ;ror    a, 0 ;äh richtig? TODO
    shr    b, 4
    shr    c, 8
    shr    d, 12

    ;SUper Ugly TODO
    and    a, 0xf
    and    b, 0xf
    and    c, 0xf
    and    d, 0xf

    lea    a, [rdi+a*4]
    lea    b, [rdi+b*4]
    lea    c, [rdi+c*4]
    lea    d, [rdi+d*4]

    ; load ecx with rotate values
    ; 16, 12, 8, 7
    mov    rcx, 0120D0907h
s20_permute_rotl32:
    mov    t, [a]           ;r9d=x[a]
    add    t, [d]
    rol    t, CL
    xor    [b], t

    xchg   CL, CH
            
    mov    t, [b]           ;r9d=x[b]
    add    t, [a]
    rol    t, CL
    xor    [c], t
    
    xchg   a, c
    xchg   b, d
    
    shr    rcx, 16
    jnz    s20_permute_rotl32
    
    mov    rcx, r11
    ret

; void s20_stream (s20_ctx *ctx, void *in)
_s20_stream:
s20_stream: 
    ;rdi [state] 64 bytes
    ;rsi [in]
    
    ;TODO recover rdi, rsi 
    mov    r13, rdi  ;Save ctx
    mov    r14, rsi  ;Save in

    ;cpy state to in
    xchg   rdi, rsi
    mov    rcx, 8
    rep    movsq ;64bytes
    
    mov    r15, 10   ;Rounds: Counter
    mov    rdi, r14

s20_stream_c0:   
    mov    rsi, indeces
    
s20_stream_c1:
    ;rdi hold  *in
    mov    cl, 8
s20_stream_c2:
    lodsw   ;rax = indeces[cl]
    call   s20_permute
    loop   s20_stream_c2
    dec    r15
    jnz    s20_stream_c0

    ; add state to x
    mov    cl, 8
s20_stream_c3:
    mov    rax, [r13 + rcx*8 - 8]           ;r13 = ctx
    add    [r14 + rcx*8 - 8], rax           ;r14 = in
    loop   s20_stream_c3
    
    stc
    adc    [r13 + 8*4], rcx
    
    mov rdi, r13
    mov rsi, r14
    ret

;_s20_encrypt:
;s20_encrypt:
;    call s20_permute
;    ret