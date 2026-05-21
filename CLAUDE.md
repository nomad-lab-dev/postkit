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
TCA (The Composable Architecture) · SwiftData · PhotoKit · Core ML + Vision · Gemini Flash (Google Generative AI SDK)

## Build Strategy

**Vertical slices** — un flow complet par jour. Ne pas construire couche par couche (pas de "d'abord tous les models, puis tous les reducers"). Chaque slice = Feature (Reducer + State + Action) + View fonctionnels de bout en bout.

## Architecture

```
Views (SwiftUI)                    ← ZERO logique métier, observent @ObservableState
Reducers (@Reducer)                ← toute la logique, state mutations, effects
Dependencies (@DependencyClient)   ← implémentations swappables (live/preview/test)
  PersistenceClient                ← SwiftData (mainContext UI + background ModelContext)
  PhotoLibraryClient               ← PhotoKit (PHAsset, PHImageManager)
  ImageClassifierClient            ← Core ML on-device + Gemini Flash cloud fallback
  PostGeneratorClient              ← Gemini (caption + hashtag generation)
  GeocoderClient                   ← CLGeocoder reverse geocoding
  UserDefaultsClient               ← UserDefaults wrapper
  NotificationClient               ← UNUserNotificationCenter
Models (@Model + Snapshots)        ← SwiftData models + Equatable/Sendable snapshots
```

## Rules

**Views = zero logique.** Si une View contient un `if` ou un calcul autre que de l'affichage conditionnel simple, c'est une erreur — déplacer dans le Reducer.

**Dependency Injection via TCA.** Utiliser `@Dependency(\.xxx)` dans les Reducers. Ne jamais instancier les clients directement.

**Snapshot pattern obligatoire.** Les `@Model` SwiftData ne sont ni Equatable ni Sendable. Toujours convertir en struct Snapshot avant de stocker dans le TCA State ou de passer à travers des frontières d'isolation async.

**ImageClassifier hybride:**
- Core ML first (on-device, rapide, gratuit)
- Si confiance < 70% et signal Vision ≥ 30% → fallback Gemini Flash (cloud)
- Ne pas appeler Gemini si Core ML est confiant

**Structured concurrency:**
- TaskGroup avec throttle pour le scan (6 concurrent max par batch)
- async let pour opérations indépendantes (classify ∥ detectCadrage)
- .cancellable(id:) sur tous les effects longs
- CancellationError doit toujours se propager (jamais catch {} qui avale les erreurs)
- SwiftData heavy ops sur background ModelContext, UI reads sur mainContext

## Features

| Feature | Reducer | Notes |
|---------|---------|-------|
| Onboarding (3 étapes) | OnboardingFeature | Welcome → Quick Scan (20 photos) → Topics Setup |
| Dashboard | DashboardFeature | Pillars bento + scan status + scheduled templates |
| Classification Queue | ClassificationQueueFeature | Grid photos pending + accept all |
| Classification Card | ClassificationCardFeature | Swipe/tap pour assigner un pillar |
| Explore | ExploreFeature | Filtres: pillar, cadrage, location, status |
| Post Assembly | PostEditorFeature | Template slots + caption AI + share |
| SmartPost | SmartPostFeature | Prompt → template auto-généré via Gemini |
| Template Builder | TemplateBuilderFeature | Création/édition de templates |
| Settings | SettingsFeature | Topics, reminders, app config |

## Dépendances

```
// TCA — OBLIGATOIRE
// https://github.com/pointfreeco/swift-composable-architecture

// Google Generative AI SDK — OBLIGATOIRE avant tout build
// https://github.com/google/generative-ai-swift
```

PhotoKit, Core ML, Vision = natifs Apple, aucune installation requise.

## Env / Config

```swift
// Secrets.xcconfig (non commité) injecté via Info.plist
// GeminiAPIKey = "..."
```

Ne jamais hardcoder les clés API dans le code source.

## Quick Scan (Onboarding)

- 20 photos récentes → Core ML → ~5 sec → suggestions pillars
- S'exécute pendant l'onboarding uniquement
- Résultats = suggestions, pas définitifs
- Emoji resolution en parallèle via TaskGroup

## Full Scan (Background)

- Toute la bibliothèque, par batch de 30 (récent → ancien)
- AsyncStream avec backpressure (buffer de 3 batches)
- 6 photos traitées en parallèle par batch (TaskGroup + throttle)
- classify + detectCadrage en parallèle par photo (async let)
- Idempotent : reprend après crash grâce au Set<String> d'asset IDs déjà classifiés
- Core ML on-device en premier, Gemini Flash si < 70%
- Annulable via .cancellable(id: CancelID.fullScan)

## Phases

| Phase | Feature | Status |
|-------|---------|--------|
| 1 (MVP) | Onboarding + Classify + Dashboard + Explore + Post Assembly + SmartPost | En cours |
| 2 | PostKit Pro (StoreKit 2) + Caption AI avancée + CreateML fine-tune | À venir |
| 3 | CloudKit sync + LinkedIn post direct + Server-side Gemini proxy | À venir |

## Objectifs

**Dual objectif:** SaaS 9.99€/mo (phase 2) + portfolio iOS pour entretiens.
