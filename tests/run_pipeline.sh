#!/bin/bash

# Configuration initiale
echo "🔧 Configuration de l'environnement de test..."
mkdir -p /run/dbus
touch /run/dbus/system_bus_socket

# Création des services systemd
echo "📝 Création des services systemd..."
mkdir -p /etc/systemd/system
cat > /etc/systemd/system/internet-quota-track.service << EOL
[Unit]
Description=Internet Quota Tracking Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/internet-quota.sh track
User=nolan
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOL

cat > /etc/systemd/system/internet-quota-reset.service << EOL
[Unit]
Description=Internet Quota Reset Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/internet-quota.sh reset
User=nolan
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOL

# Exécution du pipeline d'installation
echo "🚀 Lancement du pipeline d'installation..."
cd /app
./scripts/install/00-install.sh

# Test des fonctionnalités
echo "🧪 Test des fonctionnalités du script de quota..."
echo "➡️ Test de la commande track..."
sudo -u nolan /usr/local/bin/internet-quota.sh track
echo "➡️ Vérification du statut..."
sudo -u nolan /usr/local/bin/internet-quota.sh status
echo "➡️ Test de la commande reset..."
sudo -u nolan /usr/local/bin/internet-quota.sh reset
echo "➡️ Vérification finale du statut..."
sudo -u nolan /usr/local/bin/internet-quota.sh status

# Maintien du conteneur actif pour inspection
echo "✅ Tests terminés. Conteneur maintenu actif pour inspection..."
tail -f /dev/null 