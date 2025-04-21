# Plan d'Action - Internet Quota Rework

## ✅ Phase 1 : Analyse
- [x] Analyse du système actuel
- [x] Création du rapport d'analyse (ANALYSE.md)
- [x] Identification des points d'amélioration
- [x] Création de la liste des tâches (TODO.md)

## ✅ Phase 2 : Simplification et Stabilisation
- [x] Création d'une version simplifiée et fonctionnelle du script
- [x] Implémentation des commandes de base (track, reset)
- [x] Ajout de la commande status pour vérifier l'utilisation
- [x] Tests dans un environnement Docker
- [x] Déploiement sur VM de test

## ✅ Phase 3 : Fondations Solides
- [x] Développement d'un système de logging avancé
- [x] Implémentation d'un système de gestion d'erreurs robuste
- [x] Tests unitaires de base sur les fonctionnalités principales
- [x] Intégration avec systemd pour l'automatisation

## 🔄 Phase 4 : Modularisation (EN COURS DE REALISATION)
- [ ] Refactorisation du code en modules indépendants :
  - [ ] quota-core.sh : Fonctions de base de gestion des quotas
  - [ ] quota-security.sh : Protection des données et vérification
  - [ ] quota-network.sh : Gestion des règles de pare-feu
  - [ ] quota-config.sh : Gestion de la configuration
- [ ] Restructuration du système de fichiers
- [ ] Création d'une API interne cohérente
- [ ] Tests unitaires pour chaque module

## 🔄 Phase 5 : Sécurité (PROCHAINE)
- [ ] Implémentation du chiffrement des données de quota
- [ ] Système de détection des tentatives de contournement
- [ ] Vérification d'intégrité via checksums
- [ ] Journalisation des événements de sécurité
- [ ] Tests de résistance aux manipulations

## 🔄 Phase 6 : Détection Précise et Backup
- [ ] Système de détection précise d'activité internet
  - [ ] Distinction entre navigation active et trafic passif
  - [ ] Détection d'inactivité
  - [ ] Comptage précis du temps réel d'utilisation
- [ ] Système de backup automatique des données
  - [ ] Sauvegarde périodique chiffrée
  - [ ] Rotation automatique des sauvegardes
  - [ ] Vérification de l'intégrité des backups

## 🔄 Phase 7 : Architecture de Base de Données
- [ ] Migration vers SQLite pour le stockage des données
- [ ] Schéma de base de données optimisé
- [ ] Gestion des transactions et de la concurrence
- [ ] Importation des données existantes

## 🔄 Phase 8 : Interface Utilisateur
- [ ] Amélioration des notifications
  - [ ] Alertes paramétrables pour différents seuils
  - [ ] Messages personnalisés selon l'âge
  - [ ] Notifications visuelles améliorées
- [ ] Interface web simple
  - [ ] Dashboard pour les parents
  - [ ] Visualisation du temps restant pour les enfants

## 🔄 Phase 9 : Fonctionnalités Avancées
- [ ] Quotas par application
- [ ] Système de gestion des exceptions (temps bonus, sites éducatifs)
- [ ] Centralisation des logs dans SQLite
- [ ] Mécanisme de récupération automatique
- [ ] API REST pour intégration externe
- [ ] Tableau de bord avancé avec statistiques et graphiques

## 📋 Plan d'Exécution Détaillé

### Prochain Sprint (Mai 2025)
1. **Modularisation du code**
   - Définir l'architecture des modules
   - Refactoriser le script internet-quota.sh
   - Créer les modules de base
   - Migrer les fonctionnalités existantes
   - Tests d'intégration

### Sprint Suivant (Juin 2025)
1. **Implémentation de la sécurité**
   - Chiffrement des données de quota
   - Système de vérification d'intégrité
   - Tests de sécurité dans Docker

## 📝 Notes et Directives
- Tous les tests doivent être exécutés dans des conteneurs Docker pour la sécurité
- Chaque module doit avoir sa propre suite de tests unitaires
- La documentation doit être mise à jour en parallèle du développement
- Maintenir la compatibilité avec les installations existantes
- Respecter les règles de style et de codage du projet
- Privilégier la simplicité et la robustesse

## 📈 Progression Actuelle
- [x] Phase 1 : Analyse (100%)
- [x] Phase 2 : Simplification et Stabilisation (100%)
- [x] Phase 3 : Fondations Solides (100%)
- [ ] Phase 4 : Modularisation (0% - EN COURS)
- [ ] Phase 5 : Sécurité (0%)
- [ ] Phase 6 : Détection Précise et Backup (0%)
- [ ] Phase 7 : Architecture de Base de Données (0%)
- [ ] Phase 8 : Interface Utilisateur (0%)
- [ ] Phase 9 : Fonctionnalités Avancées (0%) 