# PostKit — Final Product Architecture

**Version:** 2.0 · **Date:** April 13, 2026 · **Status:** LOCKED — Ready for build

---

## Onboarding (3 etapes, < 1 min)

### Step 1 — Welcome
- "15 000 photos. 0 posts."
- Before/after visual
- CTA: "Get Started"

### Step 2 — Quick Scan Preview
- Demande permission Photos (contextuelle, pas abstraite)
- Core ML + metadonnees EXIF sur 20 photos recentes (~5 sec)
- Resultat: "On a detecte du contenu pour ces piliers"
- Piliers sugggeres avec thumbnails de SES photos
- L'user voit la valeur sur SON contenu en 10 secondes

### Step 3 — Pillars Setup
- Pre-rempli avec les suggestions du quick scan
- Bento grid on/off
- Custom pillar via partial sheet + emoji auto-suggest
- Seule etape obligatoire (min 1 pilier)

→ Full scan demarre en background
→ Dashboard apparait

---

## Template Nudge (post-onboarding)

Ecran didactique qui explique la valeur des templates :
- Mockup widget iOS sur home screen
- Mockup post pre-construit avec vraies photos
- "Chaque matin, un post pret a publier"
- Presets de templates (Carousel 4 photos, Story, Portrait+Hook)
- CTA: "Creer mon premier template" / "Plus tard"
- Si "Plus tard" → nudge card dans le dashboard tant que pas de template

---

## Full Scan (background)

- Core ML (on-device) + Gemini Flash (cloud) via hybrid pipeline
- Par batch de 30 jours, du recent vers l'ancien
- Dashboard montre les piliers se remplir en temps reel
- Auto-detect nouveaux assets a chaque ouverture d'app

---

## Post-Scan Moment Wow — Slot Machine

SI template existe :
- Animation slot machine — les photos shufflent dans les slots
- Chaque slot (POV, Detail, Wide, Portrait) tourne comme un rouleau
- S'arrete un par un de gauche a droite avec haptic "click"
- Post revele avec les photos matchees
- Boutons: "Garder ce post" / "Shuffle" / "Editer"
- v1.1: scroll vertical par slot pour changer de photo individuellement

SI pas de template :
- Dashboard avec resultats du scan
- Piliers remplis avec thumbnails
- Nudge "Cree un template pour debloquer la magie"

---

## Explore Grid

Vue libre pour browser tout le contenu classe :
- Grille de photos filtrable
- Filtres: pilier, cadrage (POV/Detail/Wide/Portrait), localisation (picker EXIF), moment (matin/aprem/soir/nuit), media (photo/video), status (active/non-pertinent)
- Bouton "Select" discret top-right pour multi-selection
- Multi-select → "Compose Post" / "Add to Existing"
- Long press alternatif pour entrer en multi-select
- Asset detail en slide-up sheet, tout editable
- Chemin B vers la creation de posts (sans template)

---

## Premier Partage (just-in-time setup)

Quand l'user tap "Share" ou "Suggest Hook" pour la premiere fois :
1. "Sur quel reseau tu publies ca ?"
2. Setup plateforme + tone (1 reseau a la fois)
3. "Tu veux des textes optimises pour ce reseau ?"
   → "Ca va permettre a PostKit de generer des descriptions et hashtags optimises automatiquement"
   → Oui → Brand brainstorming 30Q (stacked cards)
   → Non → tone par defaut (Professional)
4. Hook/caption/hashtags generes
5. Share Sheet
6. Les prochaines fois c'est deja configure

---

## Usage Quotidien

### Notification push
- "Ton post du jour est pret 📸" (si template + assets matchent)
- "Tu as 12 nouvelles photos classees" (si pas de template)

### Widget iOS
- AVEC template: preview du post suggere du jour (tap → post editor)
- SANS template: album du jour par pilier (style Apple Photos, evolue toutes les X heures)

### Flow quotidien
Ouvre app → post pret → review/edit → Share Sheet → poste → 30 secondes

---

## Classification (enrichissement continu)

- Accessible depuis le tab "Classify"
- Classification Queue: bento grid par pilier avec thumbnails + quantity
- Classification View: swipe mode (1 by 1) OU grid mode (batch)
- Chaque card est un micro-editeur (tags, loc, cadrage editables)
- Pas un passage oblige — l'IA fait le gros du travail
- Sert a affiner/corriger pour ameliorer les suggestions futures

---

## 3 niveaux de valeur

| Niveau | Template | Pro | Widget | Notif | Valeur |
|--------|----------|-----|--------|-------|--------|
| Classifieur | Non | Non | Album/pilier | "X photos classees" | Retrouver son contenu |
| Assembleur | Oui | Non | Post suggere | "Un post est pret" | Posts pre-assembles |
| Automatiseur | Oui | Oui | Post complet (hook+caption) | "Ton post du jour" | Zero effort, chaque matin |

---

## Architecture technique

- SwiftUI adaptatif, une target (iOS/iPadOS priorite, macOS adaptatif)
- MVVM + Protocols + Dependency Injection
- SwiftData (derriere PersistenceService protocol)
- Hybrid AI: Core ML + Gemini Flash (derriere ImageClassifier protocol)
- PhotoKit (derriere PhotoLibraryService protocol)
- Toutes les strings dans AppStrings enum (i18n ready)
- NavigationStack adaptatif (back contextuel natif)
- Build: vertical slices (un flow complet par jour)

---

## Ce qui est MVP vs Post-MVP

### MVP (ship semaine du 14)
- Onboarding 3 etapes (welcome, quick scan, pillars)
- Template nudge + template builder basique
- Full scan pipeline (Core ML + Gemini)
- Dashboard (piliers + scan status)
- Explore grid (filtres riches)
- Post assembly (multi-select + slots)
- Export album Photos
- Share Sheet
- Slot machine post reveal (animation basique)
- Widget (album pilier)
- Notif push basique

### v1.1 (monetisation, fin avril)
- Paywall Pro (StoreKit 2)
- AI hook + caption + hashtags
- Brand brainstorming 30Q (au premier partage)
- Tone per platform (just-in-time)
- Scroll vertical par slot (post editor)
- Widget post complet

### v1.2 (growth, mai)
- LinkedIn API integration
- iCloud sync
- Landing page + Product Hunt
- Grid mode classification

### v2.0 (WWDC, juin)
- Apple AI features
- Gemma sur Hetzner
- Multi-platform direct posting
- Apple Notes integration
