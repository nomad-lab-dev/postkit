# PostKit — Design Decisions Log

**Decisions cles prises pendant le product design (April 12-13, 2026)**

---

## Architecture

| Decision | Choix | Pourquoi | Date |
|----------|-------|----------|------|
| Pattern | MVVM + Protocols + DI | Portfolio piece pour entretiens iOS. Testable, swappable. | Apr 12 |
| Persistence | SwiftData (derriere protocol) | Natif Apple, iCloud-ready, moderne. Protocol pour Core Data swap. | Apr 12 |
| Classification AI | Hybrid Core ML + Gemini Flash | Local = rapide/gratuit, Cloud = precis. Protocol ImageClassifier switchable. | Apr 12 |
| Plateforme | SwiftUI multiplateforme (iOS + macOS) | Un codebase. Plus ambitieux mais meilleur portfolio. | Apr 12 |
| Strings | Toutes dans des enums (AppStrings) | i18n ready. Zero hardcoded values dans les Views. | Apr 13 |
| Navigation | NavigationStack natif SwiftUI | Back contextuel automatique. | Apr 13 |

## Onboarding

| Decision | Choix | Alternative rejetee | Pourquoi | Date |
|----------|-------|-------------------|----------|------|
| Nombre d'etapes | 5 | 7 (v0.0) | Summary supprime, Tone+Platforms fusionnes. Moins de friction. | Apr 12 |
| Seule etape obligatoire | Pillars | Tout obligatoire | L'app fonctionne avec juste des piliers. Le reste est bonus. | Apr 12 |
| Bio/Persona | Dual path (Quick Bio ou 30 questions) | Bio texte uniquement | Le brainstorming 30Q ajoute une valeur massive pour le persona. | Apr 12 |
| Brainstorming UI | Stacked cards (variant A) | Chat bubbles, Typeform | Coherent avec le swipe mode. Focus 1 question. Portfolio piece. | Apr 12 |
| Tone | Per-platform (pas global) | Tone unique global | Personne ne parle pareil sur LinkedIn et TikTok. | Apr 12 |
| "Mix" option | Supprime | Garder comme option | "Mix" ne dit rien. Multi-select 2-3 max est plus precis. | Apr 12 |
| Pillar cards | Bento grid avec description | Flat chip tags | Regle des 3 secondes. Plus comprehensible. | Apr 12 |
| Custom pillar | Partial sheet (pas inline) | Inline textfield | iOS-native pattern, plus focus. | Apr 13 |
| Emoji pillar | Auto-suggest via AI + native picker | SF Symbols | Micro-interaction qui delighte. Portfolio piece. | Apr 12 |
| First Scan | Unlock Cards + Rocket header | Checklist, progress ring | Gamifie, satisfaisant, clair. | Apr 13 |
| Permissions | Obligatoires (pas de skip) | Maybe Later | L'app ne fonctionne pas sans Photos. Pas de fausse option. | Apr 13 |
| Location permission | Supprime | Demander | EXIF GPS est dans les metadonnees photo, pas besoin de CLLocationManager. | Apr 13 |

## Classification

| Decision | Choix | Pourquoi | Date |
|----------|-------|----------|------|
| Scan order | Recent → ancien, par 30 jours | Contenu utilisable immediatement. | Apr 12 |
| Auto-classification | Full auto, user corrige si faux | Moins de friction que semi-auto. | Apr 12 |
| Swipe → Review | Renomme en "Classification" | Le nom doit refleter l'usage, pas le geste. | Apr 13 |
| Grid mode | Toggle swipe/grid | 10K+ photos = grid plus rapide pour batch elimination. | Apr 13 |
| Swipe card | Micro-editeur (tags/loc/cadrage editables) | Chaque validation est aussi une session d'enrichissement. | Apr 12 |
| 3 asset states | Active / Non-pertinent / Used | "Non-pertinent" permet de nettoyer sans supprimer. | Apr 12 |

## Posts

| Decision | Choix | Pourquoi | Date |
|----------|-------|----------|------|
| Post structure | Slot-based avec template requirements | Chaque slot est un brief de recherche pre-rempli. | Apr 12 |
| Explorer contextuel | Pre-filtre par slot requirements | Montre les assets qui matchent, mais reste ouvert a l'exploration. | Apr 12 |
| Status change | Tap detail + context menu (pas swipe) | Swipe status = dangereux (accident). | Apr 12 |
| Export | Album Photos natif | L'user retrouve ses posts dans sa galerie pour Instagram. | Apr 12 |
| MVP posting | Share Sheet | Integration API reseaux en v1.2. | Apr 12 |

## Naming

| Decision | Choix | Alternative | Pourquoi | Date |
|----------|-------|------------|----------|------|
| App name | PostKit | PillarBox, BrandAI, Sortd | ASO optimise + memorable + brand durable. | Apr 13 |
| Tab "Swipe" | Rename "Classify" | Review Queue | Usage-based naming. Pas le geste. | Apr 13 |
| SwipeView | ClassificationQueueView | ReviewQueueView | C'est une file de classification. | Apr 13 |
| SwipeCardView | ClassificationView | ReviewCardView | La ou la classification a lieu. | Apr 13 |
