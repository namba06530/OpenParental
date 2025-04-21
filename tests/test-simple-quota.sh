#!/bin/bash
set -euo pipefail

# Variables de couleur pour l'affichage
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}[TEST] Démarrage des tests de quota internet (version simplifiée)${NC}"

# Test des répertoires
echo -e "${GREEN}[TEST] Vérification des répertoires nécessaires${NC}"
if [ ! -d "/var/lib/openparental/quota" ]; then
    echo -e "${RED}[FAIL] Répertoire de quota manquant${NC}"
    mkdir -p /var/lib/openparental/quota
    echo -e "${YELLOW}[INFO] Répertoire de quota créé${NC}"
fi

# Test de la réinitialisation du quota
echo -e "${GREEN}[TEST] Test de la réinitialisation du quota${NC}"
/usr/local/bin/internet-quota.sh reset
if [ $? -ne 0 ]; then
    echo -e "${RED}[FAIL] La réinitialisation du quota a échoué${NC}"
    exit 1
fi

# Vérification du fichier de quota
QUOTA_FILE="/var/lib/openparental/quota/child.log"
if [ ! -f "$QUOTA_FILE" ]; then
    echo -e "${RED}[FAIL] Fichier de quota non créé${NC}"
    exit 1
fi

if [ "$(cat $QUOTA_FILE)" != "0" ]; then
    echo -e "${RED}[FAIL] Le quota n'a pas été réinitialisé à 0${NC}"
    exit 1
fi

echo -e "${GREEN}[SUCCESS] Réinitialisation du quota réussie${NC}"

# Test du suivi du quota
echo -e "${GREEN}[TEST] Test du suivi du quota${NC}"
/usr/local/bin/internet-quota.sh track
if [ $? -ne 0 ]; then
    echo -e "${RED}[FAIL] Le suivi du quota a échoué${NC}"
    exit 1
fi

if [ "$(cat $QUOTA_FILE)" != "1" ]; then
    echo -e "${RED}[FAIL] Le quota n'a pas été incrémenté${NC}"
    exit 1
fi

echo -e "${GREEN}[SUCCESS] Suivi du quota réussi${NC}"

# Test multiple de suivi du quota
echo -e "${GREEN}[TEST] Test de suivi multiple du quota${NC}"
/usr/local/bin/internet-quota.sh track
/usr/local/bin/internet-quota.sh track
/usr/local/bin/internet-quota.sh track
EXPECTED_VALUE="4"  # 1 + 3 appels track
ACTUAL_VALUE=$(cat $QUOTA_FILE)
if [ "$ACTUAL_VALUE" != "$EXPECTED_VALUE" ]; then
    echo -e "${RED}[FAIL] Comptage incorrect du quota. Attendu: $EXPECTED_VALUE, Obtenu: $ACTUAL_VALUE${NC}"
    exit 1
fi

echo -e "${GREEN}[SUCCESS] Comptage multiple du quota réussi${NC}"

# Test d'erreur sur les arguments invalides
echo -e "${GREEN}[TEST] Test d'arguments invalides${NC}"
if /usr/local/bin/internet-quota.sh invalid_argument 2>/dev/null; then
    echo -e "${RED}[FAIL] L'argument invalide a été accepté${NC}"
    exit 1
fi

echo -e "${GREEN}[SUCCESS] Gestion des arguments invalides réussie${NC}"

# Test final de réinitialisation
echo -e "${GREEN}[TEST] Test final de réinitialisation${NC}"
/usr/local/bin/internet-quota.sh reset
if [ "$(cat $QUOTA_FILE)" != "0" ]; then
    echo -e "${RED}[FAIL] La réinitialisation finale a échoué${NC}"
    exit 1
fi

echo -e "${GREEN}[SUCCESS] Tous les tests ont réussi !${NC}"
exit 0 