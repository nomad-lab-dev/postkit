# PostKit — Sprint Plan (Jeudi 17 → Mercredi 23 avril)

**Format:** Daily check-in (matin) + check-out (soir) filmables pour du build-in-public
**Duree:** 7 jours
**Objectif:** MVP fonctionnel sur TestFlight

---

## Jeudi 17 — FONDATIONS

### Check-in (matin, 2 min video)
> "Day 1. On pose les fondations de PostKit. Aujourd'hui : projet Xcode, architecture MVVM + Protocols, et les models SwiftData. A ce soir."

### Travail
- [ ] Creer le projet Xcode (iOS, SwiftUI, target unique adaptive)
- [ ] Structure folders : Views / ViewModels / Models / Services / Protocols / Utils
- [ ] SwiftData models : Pillar, Tag, Asset, Post, PostTemplate, Persona
- [ ] PersistenceService protocol + SwiftData implementation
- [ ] AppStrings enum (structure pour i18n)
- [ ] Design tokens : Colors, Spacing, Typography dans des enums
- [ ] Premier build qui compile sur simulateur

### Check-out (soir, 3 min video)
> Montrer : le projet dans Xcode, la structure, les models, un preview SwiftUI vide qui compile. "L'archi est posee. Demain on branche PhotoKit et Core ML."

### Livrable video
Screenshot Xcode + structure + build success

---

## Vendredi 18 — SCAN PIPELINE

### Check-in (matin)
> "Day 2. Aujourd'hui je branche l'IA sur la galerie. Core ML pour classifier les photos, PhotoKit pour les lire. Le coeur technique de l'app."

### Travail
- [ ] PhotoLibraryService protocol + PhotoKit implementation
- [ ] Permission flow (request, handle granted/denied/limited)
- [ ] EXIF metadata extraction (date, location, time of day)
- [ ] ImageClassifier protocol
- [ ] Core ML implementation (VNClassifyImageRequest)
- [ ] Quick Scan (20 photos, ~5 sec) pour l'onboarding
- [ ] Batch scan pipeline (30-day windows, incremental)
- [ ] Tester sur device reel (pas simulateur — PhotoKit)

### Check-out (soir)
> Montrer : l'app qui scanne de vraies photos, les tags detectes par Core ML, la classification en action. "L'IA voit mes photos. Demain on construit l'onboarding."

### Livrable video
Screen recording : scan 20 photos → piliers detectes en console/UI

---

## Samedi 19 — ONBOARDING + PILIERS

### Check-in (matin)
> "Day 3. L'onboarding. 2 etapes : Welcome avec Quick Scan, puis Pillars. Le premier contact de l'user avec PostKit."

### Travail
- [ ] WelcomeView (3 states : hero, scanning, results)
- [ ] OnboardingViewModel (state machine)
- [ ] Permission trigger depuis le CTA "Decouvrir mon contenu"
- [ ] Quick scan animation (photos fade-in une par une)
- [ ] Pilier detection → bento cards avec thumbnails
- [ ] PillarsSetupView (pre-rempli par scan, toggle on/off)
- [ ] Custom pillar : partial sheet + emoji auto-suggest
- [ ] Pillar CRUD (create, edit, delete, reorder)
- [ ] Navigation : Welcome → Pillars → Dashboard

### Check-out (soir)
> Montrer : le flow complet onboarding. "Decouvrir mon contenu" → permission → scan → piliers → setup. Le tout en moins d'1 minute.

### Livrable video
Screen recording du flow onboarding bout-en-bout sur device

---

## Dimanche 20 — DASHBOARD + CLASSIFICATION

### Check-in (matin)
> "Day 4. Le dashboard et la classification. Apres l'onboarding, l'user arrive sur son command center et peut commencer a trier ses photos."

### Travail
- [ ] HomeView (dashboard)
- [ ] Scan status card (4 states)
- [ ] Pillar bento cards avec mini thumbnail grids
- [ ] Quick actions (Review, Compose, Template)
- [ ] Template nudge card (si 0 templates)
- [ ] ClassificationQueueView (bento selector)
- [ ] ClassificationView (swipe mode)
- [ ] Swipe gestures + haptic feedback
- [ ] Tags/loc/cadrage editable pendant le swipe
- [ ] Batch save (every 10 swipes)
- [ ] Full scan running en background pendant l'usage

### Check-out (soir)
> Montrer : dashboard avec piliers remplis + swipe classification en action. "Je trie 50 photos en 2 minutes."

### Livrable video
Screen recording : dashboard → tap pilier → swipe 10 photos → retour dashboard (counts updated)

---

## Lundi 21 — EXPLORE + POSTS

### Check-in (matin)
> "Day 5. L'explorateur de contenu et le systeme de posts. Chercher, filtrer, selectionner, assembler."

### Travail
- [ ] ExploreView (asset grid, LazyVGrid)
- [ ] Filtres : pilier, cadrage, localisation, moment, media
- [ ] Location picker (populated from EXIF data)
- [ ] Multi-select (long press + "Selectionner" button)
- [ ] AssetDetailSheet (slide-up, tout editable)
- [ ] Mark non-pertinent
- [ ] PostsListView (cards avec visual slots)
- [ ] PostEditorView (slot-based)
- [ ] Hook/Description/Hashtags fields
- [ ] Export to Photos album (PHAssetCollection)

### Check-out (soir)
> Montrer : explorer filtrer par pilier → selectionner 4 photos → creer un post → voir le post avec les slots remplis → export album. "De la galerie au post en 30 secondes."

### Livrable video
Screen recording : explore → filter → select → post → export

---

## Mardi 22 — TEMPLATES + SLOT MACHINE

### Check-in (matin)
> "Day 6. La killer feature. Les templates et la slot machine. L'IA assemble les posts pour toi."

### Travail
- [ ] TemplateBuilderView (slot config : cadrage, pilier, tags)
- [ ] Presets (Carousel 4, Story, Portrait+Hook)
- [ ] Template nudge view (post-onboarding didactique)
- [ ] Slot Machine engine (match assets → template requirements)
- [ ] SlotMachineView (animation shuffle → reveal)
- [ ] Haptic feedback sur chaque slot qui s'arrete
- [ ] Boutons Remixer / Ajuster / Parfait je garde
- [ ] Widget iOS (post preview ou album pilier) — basique
- [ ] Notification push locale ("Ton post du jour")
- [ ] Gemini Flash API integration (behind protocol) pour classification cloud

### Check-out (soir)
> Montrer : creer un template → scan fini → SLOT MACHINE animation → post revele → "Parfait, je garde". "L'app me propose des posts. Je n'ai rien fait."

### Livrable video
Screen recording : template → slot machine shuffle → post reveal. LE moment wow.

---

## Mercredi 23 — POLISH + TESTFLIGHT

### Check-in (matin)
> "Day 7. Dernier jour. Polish, edge cases, et TestFlight. On ship."

### Travail
- [ ] Polish UI (animations, transitions, Liquid Glass touches)
- [ ] Edge cases : permissions denied, empty library, scan errors
- [ ] Error handling Gemini API (rate limits, fallback Core ML)
- [ ] Freemium limits (500 photos, 5 piliers, 3 posts)
- [ ] Settings screen (scan settings, persona editor basique)
- [ ] App icon (generer depuis les 10 prompts)
- [ ] Screenshots App Store (5 avec keyword captions)
- [ ] TestFlight build + upload
- [ ] App Store Connect metadata (titre, subtitle, keywords, description)
- [ ] Soumission App Store Review

### Check-out (soir)
> Montrer : l'app complete sur iPhone. Onboarding → scan → classify → post → export. "PostKit est sur TestFlight. 7 jours de build-in-public. Demain, le monde teste."

### Livrable video
Full walkthrough de l'app sur device reel. The big reveal.

---

## Format Video Daily

### Check-in (matin, 1-2 min)
```
[Face camera, bureau visible]
"Day X of building PostKit.
Hier : [1 phrase recap].
Aujourd'hui : [objectif du jour en 1 phrase].
Let's build."
```

### Check-out (soir, 2-4 min)
```
[Screen recording + voiceover]
"Day X done. Voila ce que j'ai construit aujourd'hui."
[Demo de la feature du jour]
"Demain : [teaser du jour suivant]."
[Face camera]
"See you tomorrow."
```

### Plateformes
- **LinkedIn** : check-out avec texte detaille (le persona est la)
- **X/Twitter** : check-in short + screen recording en thread
- **Instagram Stories** : behind the scenes pendant le dev
- **TikTok** : le check-out en format vertical (screen recording accelere)

---

## Metriques du sprint

| Jour | Feature principale | Wow moment video |
|------|-------------------|-----------------|
| J1 Jeu | Archi + Models | Xcode build success |
| J2 Ven | Scan pipeline | Core ML classifie des vraies photos |
| J3 Sam | Onboarding | Flow complet en < 1 min |
| J4 Dim | Dashboard + Classify | Swipe 50 photos en 2 min |
| J5 Lun | Explore + Posts | Galerie → post en 30 sec |
| J6 Mar | Templates + Slot Machine | Animation shuffle → post revele |
| J7 Mer | Polish + TestFlight | Full walkthrough sur device |

---

## Risques et fallbacks

| Risque | Impact | Fallback |
|--------|--------|----------|
| Core ML pas assez precis | Moyen | Gemini Flash pour tout (plus cher mais plus precis) |
| PhotoKit complexe sur simulateur | Bloquant | Tester sur device des J2 |
| Slot machine animation complexe | Moyen | Version simplifiee sans animation (juste le resultat) |
| Gemini API rate limit | Faible | Core ML only pour le MVP, Gemini en v1.1 |
| Pas le temps pour le widget | Faible | Widget en v1.1, notif push suffit |
| App Store review lente | Faible | TestFlight disponible immediatement |
