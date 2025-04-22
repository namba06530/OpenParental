# OpenParental – Stack de Contrôle Parental HandMade pour Ubuntu

![Licence MIT](https://img.shields.io/badge/license-MIT-green.svg)

Une solution complète de **contrôle parental open source** pour Ubuntu, conçue pour être simple, robuste et accessible à tous. Ce projet vise à fournir aux familles un contrôle efficace du temps d'écran et de l'accès Internet, tout en respectant la vie privée et la philosophie du logiciel libre.

## 🚀 Pourquoi ce projet ?
- **Liberté** : 100% open source, modifiable et partageable.
- **Simplicité** : Installation guidée via scripts, sans dépendance aux solutions propriétaires.
- **Sécurité** : Séparation stricte des comptes, filtrage multicouche, configuration SSH sécurisée.
- **Communauté** : Ouvert aux contributions, pour améliorer ensemble la protection numérique des familles.

## 📁 Structure du Projet

```
OpenParental/
├── src/                                # Code source
│   ├── internet-quota.sh              # Script principal de gestion des quotas
│   └── lib/
│       └── logging.sh                 # Bibliothèque de logging
├── tests/                             # Suite de tests
│   ├── test-logging.sh               # Tests de logging
│   └── test-iptables.sh              # Tests iptables
├── docs/                              # Documentation
│   ├── README.md                     # Documentation en anglais
│   └── README.fr.md                  # Documentation en français
└── ...
```

## 🎯 Objectifs du Projet

- Fournir un contrôle parental robuste et personnalisable
- Simplifier le déploiement et la configuration
- Permettre un suivi et une gestion efficaces du temps d'écran et d'Internet
- Protéger les enfants des contenus inappropriés en ligne

## 🛠 Composants de la Solution

### 1. Gestion des Comptes
- Création d'un compte administrateur caché
- Séparation des privilèges entre admin et utilisateurs
- Protection de l'accès aux paramètres système

### 2. Accès à Distance Sécurisé
- Configuration SSH pour l'administration à distance
- Sécurisation des accès
- Surveillance à distance

### 3. Filtrage DNS
- Configuration automatique des DNS Cloudflare Family (1.1.1.3 et 1.0.0.3)
- Blocage des contenus malveillants et adultes
- Protection contre la modification des paramètres DNS

### 4. Filtrage Web avec hBlock
- Blocage avancé des publicités, trackers et contenus malveillants
- Mise à jour automatique des listes de blocage
- Protection supplémentaire via le fichier hosts du système

### 5. Contrôle du Temps d'Écran (Timekpr-nExT)
- Limitation du temps d'utilisation de l'ordinateur
- Définition des créneaux horaires autorisés
- Suivi détaillé de l'utilisation

### 6. Gestion de la Connexion Internet (Quota)
- Limitation du temps de connexion Internet
- Système de quota personnalisable
- Suivi de l'utilisation
- Script dédié à déployer sur chaque machine enfant

### 7. Système de Logging
- Logging complet avec plusieurs niveaux (DEBUG, INFO, WARN, ERROR, SECURITY)
- Rotation et nettoyage automatiques des logs
- Suivi détaillé des événements système et des actions utilisateur
- Stockage sécurisé des logs avec les permissions appropriées

## 📋 Prérequis

- Ubuntu (version recommandée : 22.04 LTS ou supérieure)
- Un compte utilisateur avec des droits sudo pour l'installation initiale
- NetworkManager
- Connexion Internet pour installer les composants
- iptables pour le filtrage réseau

## 🚀 Installation Standard (famille, école, association...)

1. **Cloner le dépôt**
   ```bash
   git clone https://github.com/namba06530/OpenParental.git
   cd OpenParental
   ```
2. **Personnaliser le fichier** `.env` (un exemple prêt à l'emploi est fourni sous `.env.example`)
3. **Lancer l'installation complète**
   ```bash
   sudo ./00-install.sh
   ```

C'est tout ! Le script 00-install.sh s'occupe de tout : création des comptes, configuration réseau, filtrage, quotas, antivirus, durcissement final, etc.

> **Astuce** : Cette méthode fonctionne à la fois pour un ordinateur familial et pour une flotte d'ordinateurs dans une école ou un lieu public.

## 🚚 Déploiement sur les Machines Enfants

> **Note** : Pour la plupart des cas d'usage, il suffit de suivre la procédure d'installation standard ci-dessus sur chaque machine à protéger. Le script 00-install.sh configure automatiquement la gestion des quotas Internet, le filtrage, la sécurité, etc.

Si vous souhaitez déployer **uniquement la gestion des quotas Internet** sur une machine existante (cas d'usage avancé) :

1. Cloner le dépôt et adapter le .env
2. Exécuter uniquement :
   ```bash
   sudo ./06-set-internet-quota.sh
   ```

## 📝 Feuille de Route

- [x] Scripts d'installation (création de comptes, filtrage, quotas, etc.)
- [x] Script d'installation unifié (00-install.sh, point d'entrée unique)
- [x] Fonctionnalité Quota Internet (gestion des quotas Internet)
- [x] Implémentation du système de logging
- [x] Framework de tests automatisés
- [ ] Séparation du temps Internet et du temps d'écran (priorité)
- [ ] Amélioration de la gestion multi-utilisateurs pour les quotas Internet et le temps d'écran
- [ ] Interface d'administration graphique
- [ ] Système de rapports et statistiques
- [ ] Sauvegarde et restauration des configurations
- [ ] Interface d'administration web à distance
- [ ] Mises à jour automatiques des composants
- [ ] Système de notifications pour les parents
- [ ] Support amélioré multi-utilisateurs
- [ ] Documentation détaillée de la configuration
- [ ] Assistant de configuration première utilisation

> 💡 La séparation du temps Internet et du temps d'écran est maintenant la priorité du projet. N'hésitez pas à suggérer de nouvelles idées ou à contribuer à la feuille de route !

## 🔒 Sécurité & Confidentialité
- Aucune donnée envoyée hors de la machine par défaut.
- Les logs et quotas restent locaux.
- Les parents restent responsables de la supervision.
- Stockage chiffré des données sensibles.
- Audits et mises à jour de sécurité réguliers.

## 📚 Documentation Détaillée

### Compte Administrateur
- Création d'un compte administrateur caché
- Configuration des droits sudo
- Protection de l'interface de connexion

### Configuration SSH
- Installation sécurisée
- Configuration des clés et accès
- Paramètres de sécurité recommandés

### Configuration DNS
Le script `03-force-custom-dns.sh` :
- Configure NetworkManager pour ignorer les DNS DHCP
- Utilise les DNS Cloudflare Family pour le filtrage
- Protège la configuration contre les modifications

### Gestion du Temps
Timekpr-nExT permet de :
- Définir des limites quotidiennes
- Configurer les créneaux horaires autorisés
- Gérer plusieurs comptes utilisateurs

### Quota Internet
Le script `src/internet-quota.sh` gère :
- La limitation du temps de connexion
- Le suivi de l'utilisation
- Les règles de quota personnalisées
- La gestion des notifications et de la liste blanche
- Un enregistrement simple et efficace des données d'utilisation

### Système de Logging
La bibliothèque `src/lib/logging.sh` fournit :
- Plusieurs niveaux de log (DEBUG, INFO, WARN, ERROR, SECURITY)
- Rotation automatique des logs
- Stockage sécurisé des logs
- Suivi détaillé des événements
- Surveillance des performances

### Filtrage avec hBlock
hBlock permet de :
- Bloquer les publicités et trackers
- Protéger contre les domaines malveillants
- Mettre à jour régulièrement les listes de blocage
- Personnaliser les listes blanches/noires

## 🔒 Durcissement Final : Suppression Automatique des Scripts et du Fichier .env

À la toute fin de l'installation, lors de l'exécution du script `99-final-script.sh`, une phase de durcissement est proposée :

- **Suppression automatique de tous les scripts d'installation** (`00-*.sh` à `99-*.sh`)
- **Suppression du fichier `.env`** (contenant les paramètres sensibles)

Cette étape renforce la sécurité en supprimant tout ce qui pourrait permettre une reconfiguration ou un contournement de la protection après l'installation.

> Vous pouvez choisir d'accepter ou de refuser cette suppression lors de l'exécution du script. Si vous refusez, n'oubliez pas de supprimer manuellement ces fichiers pour une sécurité optimale.

## 🤝 Contribution

Les contributions sont **les bienvenues** !

- Fork le projet
- Créer une branche (`git checkout -b feature/ma-fonctionnalite`)
- Commit vos changements (`git commit -am 'Ajout de ma fonctionnalité'`)
- Push la branche (`git push origin feature/ma-fonctionnalite`)
- Ouvrir une Pull Request

Pour toute question, suggestion ou bug, ouvrez une [issue](https://github.com/your-username/OpenParental/issues) ou rejoignez les discussions.

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE).

## ⚠️ Avertissement & Éthique

Ce projet est fourni "tel quel", sans garantie. Il vise à aider les familles à mieux gérer l'usage numérique, en respectant la vie privée et l'éthique. **N'utilisez jamais ce projet pour surveiller ou restreindre d'autres personnes sans leur consentement.**

---

> _Fait avec ❤️ par la communauté open source. Rejoignez-nous pour améliorer la sécurité numérique des familles !_

## Tests

Le projet inclut plusieurs suites de tests pour assurer la qualité et la fiabilité du système :

### Tests de Journalisation

Les tests de journalisation sont organisés en trois catégories distinctes :

1. **Tests d'Infrastructure de Journalisation** (`test-logging.sh`)
   - Vérifie le fonctionnement de base du système de journalisation
   - Teste la création, la rotation et le nettoyage des fichiers de logs
   - Assure que l'infrastructure de journalisation fonctionne correctement

2. **Tests de Gestion des Erreurs** (`test-error-handling-module.sh`)
   - Vérifie le formatage et la gestion des erreurs
   - Teste l'intégration entre le système de journalisation et la gestion des erreurs
   - Assure que les messages d'erreur sont correctement formatés et enregistrés

3. **Tests d'Utilisation des Logs**
   - Vérifie l'utilisation des logs dans des contextes spécifiques
   - Teste l'intégration des logs avec d'autres fonctionnalités
   - Assure que les logs sont correctement utilisés dans les différents modules

Tous les tests sont exécutés dans des conteneurs Docker isolés pour garantir la sécurité et la reproductibilité.

## 🔧 Module de Quota Internet

Un système modulaire de gestion des quotas Internet a été intégré au projet pour permettre un contrôle précis du temps de connexion des utilisateurs. Ce système est conçu pour être :
- **Modulaire** : Divisé en composants indépendants et réutilisables
- **Sécurisé** : Construit avec une approche sécurité avant tout
- **Fiable** : Gestion robuste des erreurs et journalisation
- **Maintenable** : Séparation claire des responsabilités

### Architecture Modulaire

```
src/modules/
├── quota-core.sh      # Gestion des quotas
├── quota-security.sh  # Sécurité et opérations fichiers
├── quota-network.sh   # Règles réseau et pare-feu
├── quota-config.sh    # Gestion de la configuration
└── quota-logging.sh   # Système de journalisation
```

### Fonctionnalités Principales

#### Module Core (quota-core.sh)
- Suivi et gestion des quotas
- Fonctions d'incrémentation et de réinitialisation
- Rapports d'état
- Gestion de la concurrence avec verrous

#### Module Security (quota-security.sh)
- Opérations sécurisées sur les fichiers
- Gestion des permissions
- Contrôle d'accès
- Vérifications d'intégrité

#### Module Network (quota-network.sh)
- Gestion des règles iptables
- Système de liste blanche
- Contrôle réseau par utilisateur
- Utilitaires de nettoyage

#### Module Config (quota-config.sh)
- Configuration centralisée
- Validation des paramètres
- Gestion des fichiers de configuration
- Paramètres par défaut

#### Module Logging (quota-logging.sh)
- Journalisation multi-niveaux (DEBUG, INFO, WARN, ERROR)
- Rotation et nettoyage des logs
- Formatage standardisé des messages
- Surveillance des performances

### Exemples d'Utilisation

1. **Vérifier le Quota Actuel**
   ```bash
   internet-quota status
   ```

2. **Augmenter le Temps d'Utilisation**
   ```bash
   internet-quota increment 30  # Ajouter 30 minutes
   ```

3. **Réinitialiser le Quota Journalier**
   ```bash
   internet-quota reset
   ```

4. **Configurer les Paramètres**
   ```bash
   internet-quota config quota=120  # Définir le quota journalier à 120 minutes
   ```

### Intégration

Le système de quota s'intègre avec :
- La journalisation système pour la surveillance
- iptables pour le contrôle réseau
- systemd pour l'automatisation
- Le système de notification utilisateur

### Fonctionnalités de Sécurité

- Contrôle des permissions des fichiers
- Isolation des processus
- Stockage sécurisé de la configuration
- Journalisation des activités
- Protection des règles réseau

### Améliorations Futures

- Chiffrement des données
- Détection avancée des contournements
- Quotas par application
- Interface web
- Statistiques détaillées

Pour plus de détails, consultez le fichier [TODO.md](docs/TODO.md).