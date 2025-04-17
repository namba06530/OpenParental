# HandMade Parental Control Stack pour Ubuntu

![MIT License](https://img.shields.io/badge/license-MIT-green.svg)

Une solution **open source** complète de contrôle parental pour Ubuntu, pensée pour être simple, robuste, et accessible à tous. Ce projet vise à offrir aux familles un contrôle efficace du temps d'écran et d'Internet, tout en respectant la vie privée et la philosophie du logiciel libre.

## 🚀 Pourquoi ce projet ?
- **Liberté** : 100% open source, modifiable et partageable.
- **Simplicité** : Installation guidée par scripts, pas de dépendance à des solutions propriétaires.
- **Sécurité** : Séparation stricte des comptes, filtrage multicouche, configuration SSH sécurisée.
- **Communauté** : Ouvert à la contribution, pour améliorer ensemble la protection numérique des familles.

## 📁 Structure du projet

```
ct_parent/
├── 00-install.sh                         # Orchestration de l'installation complète
├── 01-create-hidden-admin-user.sh        # Création du compte administrateur
├── 02-install-and-configure-ssh.sh       # Configuration de l'accès SSH
├── 03-force-custom-dns.sh                # Configuration DNS sécurisé
├── 04-install-and-configure-hblock.sh    # Installation du filtrage web
├── 05-install-and-configure-Timekpr.sh   # Contrôle du temps d'écran
├── 06-set-internet-quota.sh              # Gestion des quotas Internet (installation/configuration)
├── deploy/
│   └── internet-quota.sh                 # Script à déployer sur les machines enfants pour le quota Internet
└── README.md                             # Documentation
```

## 🎯 Objectifs du projet

- Fournir un contrôle parental robuste et personnalisable
- Faciliter le déploiement et la configuration
- Permettre un suivi et une gestion efficace du temps d'écran et d'Internet
- Protéger les enfants des contenus inappropriés sur Internet

## 🛠 Composants de la solution

### 1. Gestion des comptes
- Création d'un compte administrateur caché
- Séparation des privilèges entre admin et utilisateurs
- Protection de l'accès aux paramètres système

### 2. Accès distant sécurisé
- Configuration SSH pour administration à distance
- Sécurisation des accès
- Monitoring à distance

### 3. Filtrage DNS
- Configuration automatique des DNS Cloudflare Family (1.1.1.3 et 1.0.0.3)
- Blocage des contenus malveillants et pour adultes
- Protection contre la modification des paramètres DNS

### 4. Filtrage Web avec hBlock
- Blocage avancé des publicités, trackers et contenus malveillants
- Mise à jour automatique des listes de blocage
- Protection supplémentaire via le fichier hosts système

### 5. Contrôle du temps d'écran (Timekpr-nExT)
- Limitation du temps d'utilisation de l'ordinateur
- Définition de plages horaires autorisées
- Suivi détaillé du temps d'utilisation

### 6. Gestion de la connexion Internet (Quota)
- Limitation du temps de connexion Internet
- Système de quota personnalisable
- Monitoring de l'utilisation
- Script dédié à déployer sur chaque machine enfant

## 📋 Prérequis

- Ubuntu (version recommandée : 22.04 LTS ou supérieure)
- Un compte utilisateur avec droits sudo pour l'installation initiale
- NetworkManager
- Connexion Internet pour l'installation des composants

## 🚀 Installation standard (famille, école, association...)

1. **Cloner le dépôt**
   ```bash
   git clone https://github.com/votre-utilisateur/ct_parent.git
   cd ct_parent
   ```
2. **Personnaliser le fichier** `.env` (un exemple prêt à l'emploi est fourni sous le nom `.env.example`)
3. **Lancer l'installation complète**
   ```bash
   sudo ./00-install.sh
   ```

C'est tout ! Le script 00-install.sh s'occupe de tout : création des comptes, configuration réseau, filtrage, quotas, antivirus, sécurisation finale, etc.

> **Astuce** : Cette méthode fonctionne aussi bien pour un poste familial que pour un parc d'ordinateurs en école ou lieu public.

## 🚚 Déploiement sur les machines enfants

> **Remarque** : Pour la plupart des usages, il suffit de suivre la procédure d'installation standard ci-dessus sur chaque machine à protéger. Le script 00-install.sh configure automatiquement la gestion du quota Internet, le filtrage, la sécurité, etc.

Si vous souhaitez déployer **uniquement la gestion du quota Internet** sur une machine déjà existante (cas avancé) :

1. Clonez le dépôt et adaptez le .env
2. Lancez uniquement :
   ```bash
   sudo ./06-set-internet-quota.sh
   ```

## 📝 Roadmap

- [ ] Script d'installation unifié (regroupant tous les scripts)
- [ ] Interface graphique d'administration
- [ ] Système de rapports et statistiques
- [ ] Sauvegarde et restauration des configurations
- [ ] Interface web d'administration à distance
- [ ] Mise à jour automatique des composants
- [ ] Système de notifications pour les parents
- [ ] Support multi-utilisateurs amélioré
- [ ] Documentation détaillée des options de configuration
- [ ] Assistant de première configuration

## 🔒 Sécurité & Vie privée
- Aucun envoi de données hors de la machine par défaut.
- Les logs et quotas restent locaux.
- Les parents restent responsables de la supervision.

## 📚 Documentation détaillée

### Compte Administrateur
- Création d'un compte admin caché
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

### Gestion du temps
Timekpr-nExT permet :
- Définir des limites quotidiennes
- Configurer des plages horaires
- Gérer plusieurs comptes utilisateurs

### Quota Internet
Le script `deploy/internet-quota.sh` gère :
- La limitation du temps de connexion
- Le suivi de la consommation
- Les règles de quota personnalisées
- Les notifications et la gestion de la whitelist

### Filtrage avec hBlock
hBlock permet :
- Blocage des publicités et trackers
- Protection contre les domaines malveillants
- Mise à jour régulière des listes de blocage
- Personnalisation des listes blanches/noires

## 🤝 Contribution

Les contributions sont **bienvenues** !

- Forkez le projet
- Créez une branche (`git checkout -b feature/ma-feature`)
- Commitez vos modifications (`git commit -am 'Ajout de ma feature'`)
- Poussez la branche (`git push origin feature/ma-feature`)
- Ouvrez une Pull Request

Pour toute question, suggestion ou bug, ouvrez une [issue](https://github.com/votre-utilisateur/ct_parent/issues) ou participez aux discussions.

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE).

## ⚠️ Avertissement & Éthique

Ce projet est fourni "en l'état", sans garantie. Il vise à aider les familles à mieux gérer le numérique, dans le respect de la vie privée et de l'éthique. **N'utilisez jamais ce projet pour surveiller ou restreindre autrui sans consentement.**

---

> _Fait avec ❤️ par la communauté open source. Rejoignez-nous pour améliorer la sécurité numérique des familles !_