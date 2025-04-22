# Guide de Contribution à OpenParental

Merci de votre intérêt pour contribuer à OpenParental ! Ce guide vous aidera à comprendre comment participer au projet de manière efficace.

## 🌟 Comment Contribuer

### 1. Trouver une Tâche

1. Consultez le fichier [TODO.md](TODO.md) pour voir les tâches disponibles
2. Les tâches sont organisées par phase et priorité
3. Choisissez une tâche qui correspond à vos compétences
4. Vérifiez que personne ne travaille déjà dessus dans les issues GitHub

### 2. Environnement de Développement

1. Fork le projet
2. Clonez votre fork :
   ```bash
   git clone https://github.com/votre-username/OpenParental.git
   cd OpenParental
   ```
3. Créez une branche pour votre fonctionnalité :
   ```bash
   git checkout -b feature/ma-fonctionnalite
   ```

### 3. Standards de Code

- Utilisez shellcheck pour valider vos scripts
- Suivez les conventions de nommage existantes
- Commentez votre code en anglais
- Ajoutez des tests pour les nouvelles fonctionnalités

### 4. Tests

- Tous les tests doivent être exécutés dans Docker
- Utilisez le framework de test fourni
- Ajoutez des tests unitaires pour les nouvelles fonctionnalités
- Vérifiez que tous les tests passent avant de soumettre

### 5. Documentation

- Mettez à jour la documentation en anglais ET en français
- Suivez le format Markdown existant
- Documentez les nouvelles fonctionnalités
- Mettez à jour les exemples si nécessaire

## 📝 Process de Contribution

1. **Créer une Issue**
   - Décrivez clairement le problème ou la fonctionnalité
   - Référencez le TODO.md si applicable
   - Attendez la validation avant de commencer

2. **Développement**
   - Créez une branche depuis main
   - Faites des commits atomiques
   - Suivez les standards de code
   - Testez votre code

3. **Pull Request**
   - Créez une PR vers la branche main
   - Décrivez les changements
   - Référencez l'issue correspondante
   - Attendez la review

4. **Review**
   - Répondez aux commentaires
   - Faites les modifications demandées
   - Maintenez la PR à jour avec main

## 🔒 Sécurité

- Ne commitez jamais de données sensibles
- Signalez les problèmes de sécurité en privé
- Utilisez des variables d'environnement pour les secrets
- Vérifiez les permissions des fichiers

## 📚 Ressources

- [Documentation du Projet](docs/README.md)
- [Guide de Sécurité](docs/SECURITY.md)
- [TODO List](docs/TODO.md)
- [Analyse du Système](docs/ANALYSE.md)

## 🤝 Code de Conduite

- Soyez respectueux et constructif
- Aidez les autres contributeurs
- Suivez les bonnes pratiques
- Communiquez clairement

## 📋 Checklist de Contribution

- [ ] J'ai lu le guide de contribution
- [ ] J'ai créé une issue
- [ ] J'ai fait les tests nécessaires
- [ ] J'ai mis à jour la documentation
- [ ] J'ai suivi les standards de code
- [ ] J'ai ajouté les tests appropriés

## ❓ Questions

Pour toute question :
1. Vérifiez la documentation existante
2. Cherchez dans les issues
3. Créez une nouvelle issue avec le label "question"

---

Merci de contribuer à OpenParental ! 🎉 