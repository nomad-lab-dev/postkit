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
TCA (The Composable Architecture) · SwiftData · PhotoKit · Core ML + Vision · Gemini Flash (Google Generative AI SDK) · StoreKit 2

## Localisation

FR + ES + EN. Les strings sont centralisées dans `Shared/AppStrings.swift` (LocalizedStringKey). Ne jamais hardcoder de strings UI en anglais sans correspondance dans les fichiers `.strings`.

## Build Strategy

**Vertical slices** — un flow complet par jour. Ne pas construire couche par couche (pas de "d'abord tous les models, puis tous les reducers"). Chaque slice = Feature (Reducer + State + Action) + View fonctionnels de bout en bout.

## Architecture

```
Views (SwiftUI)                    ← ZERO logique métier, observent @ObservableState
Reducers (@Reducer)                ← toute la logique, state mutations, effects
Dependencies (@DependencyClient)   ← implémentations swappables (live/preview/test)
  PersistenceClient                ← SwiftData (mainContext UI + background ModelContext)
  GalleryClient                    ← cache actor au-dessus de PersistenceClient (évite N+1)
  PhotoLibraryClient               ← PhotoKit (PHAsset, PHImageManager)
  ImageClassifierClient            ← Core ML on-device + Gemini Flash cloud fallback
  PostGeneratorClient              ← Gemini (caption + hashtag generation)
  GeocoderClient                   ← CLGeocoder reverse geocoding
  LocationSearchClient             ← MapKit MKLocalSearch (autocomplete slot filler)
  UserDefaultsClient               ← UserDefaults wrapper
  NotificationClient               ← UNUserNotificationCenter
  SubscriptionClient               ← StoreKit 2 (purchase / restore / isProUser)
Models (@Model + Snapshots)        ← SwiftData models + Equatable/Sendable snapshots
Navigation/AppFeature+Path.swift   ← TCA NavigationStack path extension
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

**PostEditorFeature est dans `Models/FilledSlot.swift`** (pas dans Features/) — exception historique, ne pas déplacer sans raison.

## Features

| Feature | Reducer | Notes |
|---------|---------|-------|
| Onboarding (4 étapes) | OnboardingFeature | BeforeAfter → MagicDemo → Pillars → LiveSort |
| Dashboard | DashboardFeature | Pillars bento + scan status + scheduled templates |
| Classification Queue | ClassificationQueueFeature | Grid photos pending + accept all |
| Classification Card | ClassificationCardFeature | Swipe/tap pour assigner un pillar |
| Explore | ExploreFeature | Filtres: pillar, cadrage, location, status |
| Photo Detail | PhotoDetailFeature | Détail d'une photo classifiée (sous Explore) |
| Post Assembly Entry | PostAssemblyEntryFeature | Point d'entrée (onglet Create) |
| Create Hub | CreateHubFeature | Hub : templates + slot machine + posts |
| Slot Machine | SlotMachineFeature | Roulette de sélection de slots |
| Slot Filler | SlotFillerFeature | Remplissage d'un slot (photo + location) |
| Template List | TemplateListFeature | Liste et sélection de templates |
| Template Builder | TemplateBuilderFeature | Création/édition de templates |
| Post Editor | PostEditorFeature | Template slots + caption AI + share (dans FilledSlot.swift) |
| SmartPost | SmartPostFeature | Prompt → template auto-généré via Gemini |
| Paywall | PaywallFeature | Sheet d'upgrade PostKit Pro (StoreKit 2) |
| Settings | SettingsFeature | Topics, reminders, subscription, app config |
| Reminder Setup | ReminderSetupFeature | Configuration des notifications planifiées |
| Topic Editor | TopicEditorFeature | Édition d'un pillar/topic |

## Design System

`Shared/DesignSystem/Components/` contient les composants partagés : `Badge`, `CadrageTag`, `ConfidenceBadge`, `GlassButton`, `PrimaryButton`, `TipCard`, etc. Toujours utiliser ces composants plutôt que de recréer du style inline.

## Debug / Marketing Pipeline

`Debug/` contient trois fichiers actifs en non-production :
- `DemoDataSeeder.swift` — seed SwiftData avec des données marketing réalistes. Activé via `-MarketingSeed 1` launch argument.
- `MarketingPhotoLibraryClient.swift` — `PhotoLibraryClient` alternatif qui retourne les photos bundlées (`Resources/MarketingPhotos/*.webp`).
- `MarketingAssetLoader.swift` — utilitaire de chargement des assets marketing.

**App Store screenshots** : pipeline Remotion dans `marketing/onboarding-video/`. Les scripts `scripts/extract-appstore.sh` (iPhone 6.5") et `scripts/extract-appstore-ipad.sh` (iPad 12.9"/13") génèrent les frames. Les compositions iPad (`AppStore129EN/FR/ES`) utilisent le composant `<IPad>` (`src/IPad.tsx`) à la place de `<Phone>`.

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

StoreKit config : `PostKit/PostKit.storekit` — groupe `postkit_pro`, produits `pro_weekly` ($2.99/sem, 7j trial) et `pro_yearly` ($39.99/an, 7j trial). Activer dans Run Scheme → Options → StoreKit Configuration.

## Full Scan (Background)

- Toute la bibliothèque, par batch de 30 (récent → ancien)
- AsyncStream avec backpressure (buffer de 3 batches) via `PhotoBatchSequence`
- 6 photos traitées en parallèle par batch (TaskGroup + throttle)
- classify + detectCadrage en parallèle par photo (async let)
- Idempotent : reprend après crash grâce au Set<String> d'asset IDs déjà classifiés
- Core ML on-device en premier, Gemini Flash si < 70%
- Annulable via .cancellable(id: CancelID.fullScan)

## Phases

| Phase | Feature | Status |
|-------|---------|--------|
| 1 (MVP) | Onboarding + Classify + Dashboard + Explore + Post Assembly + SmartPost | ✅ Livré |
| 2 | PostKit Pro (StoreKit 2) + Caption AI avancée + CreateML fine-tune | ✅ StoreKit livré · CreateML à venir |
| 3 | CloudKit sync + LinkedIn post direct + Server-side Gemini proxy | À venir |

## Objectifs

**Dual objectif:** SaaS ($2.99/sem ou $39.99/an) + portfolio iOS pour entretiens.
