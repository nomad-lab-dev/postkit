# PostKit — Screen Refactoring Brief (Frontend)

**Date:** April 13, 2026
**Base sur:** 11-screen-refactoring-po-brief.md
**Pour chaque ecran:** ce qu'il faut changer dans le HTML/CSS des mockups

---

## 1. CREER — 02-quick-scan-preview.html

**Structure du mockup :**
```
Phone frame:
├── Step dots (2/3 active)
├── Titre: "Voyons ce que tu as"
├── Subtitle: "On analyse tes photos les plus recentes"
├── [STATE 1: Scanning]
│   ├── Grid 4x2 de thumbnails qui apparaissent un par un (animation fade-in)
│   ├── Progress subtle "Analyse en cours..."
│   └── Nav: Back only (pas de skip)
├── [STATE 2: Results]
│   ├── Titre: "On a trouve du contenu pour X piliers"
│   ├── Pillar cards suggerees (bento grid):
│   │   ├── Emoji + nom + "X photos" badge
│   │   └── Mini 2x2 thumbnails de SES photos
│   └── Nav: Back + "Setup mes piliers →"
├── [EDGE: Permission denied]
│   ├── Illustration lock
│   ├── "PostKit a besoin d'acceder a tes photos pour les analyser"
│   ├── "Open Settings" button
│   └── Nav: Back
├── [EDGE: 0 piliers detectes]
│   ├── "On n'a pas detecte de themes clairs"
│   ├── "Pas de souci, tu vas les choisir toi-meme"
│   └── Nav: Back + "Choisir mes piliers →"
├── [EDGE: Galerie vide]
│   ├── "Ta galerie est vide"
│   ├── "Prends des photos et reviens !"
│   └── Nav: Back
```

**CSS specifique :** Animation fade-in sequentielle sur les thumbnails (delay 0.2s entre chaque). Progress bar subtle. Pillar cards identiques au style du dashboard (bento avec thumbnails + badge count).

---

## 2. MODIFIER — 01-welcome.html

**Changements HTML :**
- Step dots: `m-dot-active` + 2 `m-dot` (3 total, pas 5)
- Retirer "Skip" des nav buttons et des edge cases
- Garder le before/after visual
- Verifier le copy: "15 000 photos. 0 posts."

**Pas de changement CSS.**

---

## 3. MODIFIER — 02-pillars.html → renommer 03-pillars.html

**Changements HTML :**
- Step dots: 2 `m-dot-done` + 1 `m-dot-active` (3/3)
- La bento grid montre les piliers **pre-coches** (ceux detectes par le scan)
- Les piliers pre-sugggeres ont un badge "Detecte par l'IA"
- L'user peut toggle off les suggestions et ajouter les siens
- Le "Next" mene au template nudge (pas a Platforms+Tone)
- Retirer le back vers un ecran Tone inexistant

**Nouveau state a ajouter :**
- "Pre-rempli par scan" : 3-4 piliers deja en ON avec badge AI, les autres en OFF

---

## 4. CREER — template-nudge.html

**Structure du mockup :**
```
Phone frame (pas de tab bar — ecran transitionnel):
├── Titre: "Debloque des posts automatiques"
├── Subtitle: "Cree un template et PostKit te propose un post chaque matin"
├── [Mockup widget iOS]
│   ├── Mini widget preview sur fond home screen
│   ├── Montre un post avec thumbnails
│   └── "Ton post du jour — Bangkok Morning"
├── [Mockup post pre-construit]
│   ├── 4 slots remplis avec vraies photos
│   ├── Badges cadrage (POV, Detail, Wide, Portrait)
│   └── Hook text preview
├── [Presets de templates]
│   ├── Bento grid selectable:
│   │   ├── "Carousel 4 photos" (4 slots)
│   │   ├── "Story unique" (1 slot)
│   │   └── "Portrait + Hook" (2 slots)
│   └── Tap sur un preset → ouvre template builder pre-rempli
├── Nav: "Plus tard" (glass) + "Creer mon template" (primary)
```

**CSS specifique :** Le mockup widget doit ressembler a un vrai widget iOS (rounded corners, shadow, fond system). Le mockup post utilise les memes images gallery-*.webp.

---

## 5. CREER — slot-machine.html

**Structure du mockup :**
```
Phone frame:
├── Titre: "Ton post est pret ✨"
├── [STATE 1: Shuffling]
│   ├── 4 slots en grille 2x2
│   ├── Chaque slot montre des photos qui defilent (blur vertical)
│   ├── Indicateur "Recherche en cours..."
│   └── Pas de boutons (animation en cours)
├── [STATE 2: Revealed]
│   ├── 4 slots avec photos finales
│   ├── Badges cadrage sur chaque slot
│   ├── Nom du template en haut
│   ├── Boutons:
│   │   ├── "Shuffle 🎰" (glass button)
│   │   ├── "Editer ✏️" (glass button)
│   │   └── "Garder ce post ✓" (primary button)
│   └── v1.1 note: "scroll vertical par slot pour changer individuellement"
├── [EDGE: Pas assez d'assets]
│   ├── Slots partiellement remplis
│   ├── Slot vide: "Prends plus de photos [cadrage] pour ce slot"
│   └── Bouton "Garder quand meme" / "Changer de template"
├── [EDGE: Toutes les combinaisons vues]
│   ├── "Tu as vu toutes les combinaisons possibles"
│   ├── "Classe plus de photos pour debloquer plus de posts"
│   └── Boutons: "Explore" / "Classifier"
```

**CSS specifique :** Animation de blur vertical sur les slots pendant le shuffle. Transition de blur → net quand le slot s'arrete. Utiliser les vraies photos gallery-*.webp. L'animation doit etre suggeree visuellement (pas de vrai JS animation dans le mockup, mais des states avant/apres clairs).

---

## 6. MODIFIER — home-dashboard.html

**Changements HTML :**
- Ajouter une card nudge template (si 0 templates) :
  ```
  m-glass avec border accent:
  "📐 Cree un template et recois un post chaque matin"
  CTA: "Creer →"
  ```
- Ajouter un state "post-onboarding, scan en cours" (le tout premier dashboard que l'user voit)
- Quick actions conditionnel : "Review" visible seulement si items a review

**Nouveau state a ajouter :**
- "Premier lancement" : scan en cours, piliers commencent a se remplir, nudge template visible

---

## 7. MODIFIER — post-editor.html

**Changements HTML :**
- Ajouter un bouton "Shuffle 🎰" a cote de "Export to Album"
- Ajouter un badge "Auto-generated" si le post vient du slot machine
- Le bouton "Suggest Hook" doit mentionner que ca peut declencher le setup tone
- Les slots vides montrent les requirements du template

---

## 8. MODIFIER — posts-list.html

**Changements HTML :**
- Ajouter un badge "🎰 Auto" sur les posts generes par le slot machine
- Distinguer visuellement les posts auto vs manuels

---

## 9. CREER — first-share-setup.html

**Structure du mockup :**
```
Sheet (modal, pas full screen):
├── Titre: "Publier sur quel reseau ?"
├── Bento grid des reseaux (Instagram, LinkedIn, X, TikTok, Pinterest)
│   └── Tap = selectionne
├── [Apres selection]
│   ├── "Quel ton sur [reseau] ?"
│   ├── 5 tone cards avec exemples (meme phrase, 5 voix)
│   ├── Multi-select 1-3
│   └── Callout didactique:
│       "Affine ta brand voice pour des textes encore meilleurs"
│       → CTA "Lancer le brainstorming (5-10 min)" / "Plus tard"
├── [Si brainstorming accepte]
│   └── Stacked cards Q&A (reutiliser le design existant)
├── [Resultat]
│   ├── Hook + caption + hashtags generes
│   ├── Tout editable
│   └── "Publier via [reseau]" → Share Sheet
```

---

## 10. MODIFIER — persona-editor.html

**Changements HTML :**
- Deja fait en v0.2 (tone per-platform, pas global)
- Ajouter section "Brand Voice" : si brainstorming fait → resume. Si non → CTA "Affiner ma brand voice"
- Restructurer : Bio → Plateformes (avec tones) → Piliers → Brand Voice

---

## 11. SUPPRIMER

Supprimer ces fichiers :
- `screens/03-platforms-tone.html`
- `screens/04-bio-brainstorm.html`
- `screens/05-first-scan.html`

Mettre a jour le holder `pillarbox-screens.html` pour retirer ces entrees du tree et ajouter les nouveaux ecrans.

---

## Holder (pillarbox-screens.html) — Mise a jour du tree

```
🚀 Onboarding (3)
  01 Welcome
  02 Quick Scan Preview [NEW]
  03 Pillars Setup [RENAMED]

📐 Template (2)
  Template Nudge [NEW]
  Template Builder

🏠 Home (1)
  Dashboard [UPDATED]

🔍 Explore (2)
  Asset Grid
  Asset Detail

🏷️ Classify (2)
  Classification Queue
  Classification View

📝 Posts (3)
  Slot Machine [NEW]
  Posts List [UPDATED]
  Post Editor [UPDATED]

📤 Share (1)
  First Share Setup [NEW]

👤 Profile (4)
  Persona Editor [UPDATED]
  Pillars CRUD
  Scan Settings
  Stats
```

Total : 18 ecrans (vs 17 avant). 4 nouveaux, 3 supprimes, 6 modifies, 5 inchanges.
