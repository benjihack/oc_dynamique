#!/bin/bash

# Chemin du script à vérifier et télécharger
SCRIPT_PATH="/home/user/oc_dynamique.sh"
SCRIPT_URL="https://raw.githubusercontent.com/benjihack/oc_dynamique/refs/heads/main/oc_dynamique.sh"

# Vérifier si le script existe déjà et le supprimer si c'est le cas
if [ -f "$SCRIPT_PATH" ]; then
    echo "Le script existe déjà. Suppression..."
    rm "$SCRIPT_PATH"
fi

# Télécharger le script depuis GitHub
echo "Téléchargement du script depuis GitHub..."
wget -O "$SCRIPT_PATH" "$SCRIPT_URL"

# Rendre le script exécutable
echo "Rendre le script exécutable..."
chmod +x "$SCRIPT_PATH"

# Lancer le script dans une session screen nommée 'oc_auto'
echo "Lancer le script dans une session screen..."
screen -S oc_auto "$SCRIPT_PATH"

# Ajouter la commande au crontab.root pour exécution au démarrage
echo "Ajouter la commande au crontab.root..."
echo "/usr/bin/screen -dmS oc_auto $SCRIPT_PATH" | sudo tee -a /hive/etc/crontab.root > /dev/null

echo "Installation et configuration du script terminées."
