#!/bin/bash
set -euo pipefail

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
log_info() {
    echo -e "${YELLOW}ℹ️ $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Vérification que Docker est installé
if ! command -v docker &> /dev/null; then
    log_error "Docker n'est pas installé. Veuillez l'installer avant d'exécuter ce script."
    exit 1
fi

# Nettoyage des conteneurs existants
log_info "Nettoyage des conteneurs de test existants..."
docker ps -a --filter "name=quota-test" --format "{{.ID}}" | xargs -r docker rm -f

# Construction de l'image de test
log_info "Construction de l'image de test..."
docker build -t quota-test -f tests/Dockerfile.test .

# Exécution des tests
log_info "Exécution des tests dans un conteneur Docker..."
docker run --rm --name quota-test quota-test bash ./tests/test-error-handling-module.sh

# Vérification du résultat
if [ $? -eq 0 ]; then
    log_success "Tous les tests ont réussi !"
    exit 0
else
    log_error "Certains tests ont échoué. Consultez les logs ci-dessus pour plus de détails."
    exit 1
fi 