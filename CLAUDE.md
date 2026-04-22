# PostKit — Agent Instructions

## ⚠️ Naming — CRITIQUE

Le projet s'appelle **PostKit** depuis le 13 avril 2026. PillarBox = nom de repo uniquement.

| Ancien nom (repo/git) | Nom correct dans le code |
|-----------------------|--------------------------|
| PillarBox | PostKit |
| SwipeView | ClassificationQueueView |
| SwipeCardView | ClassificationView |

Ne jamais utiliser les anciens noms dans le code, les commentaires, ou les strings UI.

## Stack

SwiftUI · iOS 18+ / macOS 15+ · Xcode 16+
MVVM + Protocols + DI · SwiftData · PhotoKit · Core ML + Vision · Gemini Flash (Google Generative AI SDK)

## Build Strategy

**Vertical slices** — un flow complet par jour. Ne pas construire couche par couche (pas de "d'abord tous les models, puis tous les ViewModels"). Chaque slice = View + ViewModel + Service impl fonctionnels de bout en bout.

## Architecture

```
Views (SwiftUI)          ← ZERO logique métier, uniquement état UI
ViewModels (@Observable) ← toute la logique, injectés via @Environment
Services (protocols)     ← implémentations swappables
  PersistenceService     ← SwiftData (swappable CoreData)
  PhotoLibraryService    ← PhotoKit
  ImageClassifierService ← Core ML on-device + Gemini Flash cloud
AppStrings (enum)        ← toutes les strings, i18n ready
```

## Rules

**Views = zero logique.** Si une View contient un `if` ou un calcul autre que de l'affichage conditionnel simple, c'est une erreur — déplacer dans le ViewModel.

**DI via @Environment SwiftUI.** Ne pas instancier les services directement dans les Views ou ViewModels. Injecter via le container DI.

**Services derrière protocol.** Ne jamais appeler `SwiftData` directement depuis un ViewModel — toujours passer par `PersistenceService`. Idem pour `PhotoKit` → `PhotoLibraryService`.

**ImageClassifier hybride:**
- Core ML first (on-device, rapide, gratuit)
- Si confiance < 70% → fallback Gemini Flash (cloud)
- Ne pas appeler Gemini si Core ML est confiant

## Screens

| Screen | ViewModel | Notes |
|--------|-----------|-------|
| Onboarding (3 étapes) | OnboardingViewModel | Welcome → Quick Scan → Pillars Setup |
| Dashboard | DashboardViewModel | Piliers + scan status + slot machine reveal |
| ClassificationQueueView | ClassificationViewModel | Bento grid photos en attente |
| ClassificationView | ClassificationViewModel | Swipe ou tap pilier |
| Explore Grid | ExploreViewModel | Filtres: pilier, cadrage, loc, moment, status |
| Post Assembly | PostAssemblyViewModel | Multi-select → nom → save → export |

## Dépendances

```
// Google Generative AI SDK — OBLIGATOIRE avant tout build
// Ajouter via Swift Package Manager:
// https://github.com/google/generative-ai-swift
```

PhotoKit, Core ML, Vision = natifs Apple, aucune installation requise.

## Env / Config

```swift
// Dans un fichier Config.swift ou via Secrets.xcconfig (jamais commité)
let GEMINI_API_KEY = "..."
```

Ne jamais hardcoder les clés API dans le code source.

## Quick Scan (Onboarding)

- 20 photos récentes → Core ML → ~5 sec → suggestions piliers
- S'exécute pendant l'onboarding uniquement
- Résultats = suggestions, pas définitifs

## Full Scan (Background)

- Toute la bibliothèque, par batch de 30 jours (récent → ancien)
- Background task, dashboard se remplit en temps réel
- Auto-detect nouveaux assets à chaque ouverture de l'app
- Core ML on-device en premier, Gemini Flash si < 70%

## Phases

| Phase | Feature | Status |
|-------|---------|--------|
| 1 (MVP) | Onboarding + Classify + Dashboard + Explore + Post Assembly | En cours |
| 2 | PostKit Pro (StoreKit 2) + Caption AI + Fine-tune | À venir |
| 3 | CloudKit sync + LinkedIn post direct | À venir |

## Objectifs

**Dual objectif:** SaaS 9.99€/mo (phase 2) + portfolio iOS pour entretiens.
MVP April 18 — focus phase 1 uniquement.
