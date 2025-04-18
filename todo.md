
# TODO - Internet Quota Rework (Phase 1: Analyse)

> Branche cible : `feature/internet-quota-rework`

## 🎯 Objectif

Avant d’effectuer la moindre modification, commence par **analyser le fonctionnement actuel** du système de gestion de quota Internet.

## 🔍 Étendue à analyser

Tu dois étudier précisément les fichiers suivants dans cette branche :

- `05-block-internet-if-needed.sh`
- `deploy/internet-quota.sh`

Ces deux scripts constituent le cœur du système actuel.

## 📌 Tâches pour cette phase

- [ ] Lire, comprendre et commenter la logique actuelle du quota Internet
- [ ] Identifier :
  - Quand et comment le quota est consommé
  - Comment est détectée la connexion
  - Comment le blocage Internet est appliqué
  - Les dépendances (outils CLI, fichiers temporaires, logs, etc.)
- [ ] Identifier les limites ou faiblesses potentielles
  - Est-ce que le système est fiable ?
  - Est-ce qu’il peut être contourné facilement ?
  - Est-ce que le redémarrage de la machine casse le suivi ?
- [ ] Proposer une ou plusieurs **améliorations concrètes**
  - Plus de fiabilité, plus de clarté, plus de contrôle
  - Ajout éventuel de logs, simplification, meilleure structure

## 📤 Format de sortie attendu

Merci de rédiger un fichier `ANALYSE.md` dans cette branche contenant :
- Un résumé du fonctionnement actuel
- Tes observations et points faibles
- Une ou plusieurs propositions d'amélioration (architecture ou refonte des scripts)

---

ℹ️ Ne fais **aucune modification du code** pour le moment.
Cette phase est purement analytique.
