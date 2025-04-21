#!/bin/bash
set -euo pipefail

# Variables de couleur pour l'affichage
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Démarrage des tests de quota internet dans Docker ===${NC}"

# Construire l'image Docker
echo -e "${YELLOW}[INFO] Construction de l'image Docker...${NC}"
docker build -t openparental-simple-test -f tests/Dockerfile.test .

# Exécuter les tests
echo -e "${YELLOW}[INFO] Exécution des tests dans un conteneur Docker...${NC}"
docker run --privileged openparental-simple-test

# Vérifier le résultat
STATUS=$?
if [ $STATUS -eq 0 ]; then
    echo -e "${GREEN}[SUCCESS] Les tests Docker ont réussi !${NC}"
else
    echo -e "${RED}[FAIL] Les tests Docker ont échoué avec le code: $STATUS${NC}"
    exit 1
fi

echo -e "${GREEN}=== Tests terminés avec succès ===${NC}"
exit 0 