# PostKit — Screen Refactoring Brief (PO)

**Date:** April 13, 2026
**Context:** L'architecture produit a change significativement pendant le brainstorming final. Les ecrans HTML (v0.3) ne refletent plus le produit acte. Ce brief liste les refactorings necessaires par ecran.

---

## Ecrans a SUPPRIMER

| Ecran actuel | Raison |
|-------------|--------|
| **03-platforms-tone.html** | Tone/Platforms retires de l'onboarding. Moved to just-in-time setup au premier partage. |
| **04-bio-brainstorm.html** | Bio/Brainstorm retire de l'onboarding. Brand brainstorming declenche au premier partage sur un reseau. |
| **05-first-scan.html** | L'ecran "unlock cards" permissions n'existe plus. La permission est demandee dans le Quick Scan Preview. |

---

## Ecrans a CREER

| Nouvel ecran | Contenu | Priorite |
|-------------|---------|----------|
| **02-quick-scan-preview.html** | Permission contextuelle + Core ML 20 photos + piliers detectes avec thumbnails. Le moment wow de l'onboarding. | P0 |
| **template-nudge.html** | Ecran didactique post-onboarding : mockup widget + mockup post pre-construit + presets templates + CTA creer/plus tard. | P0 |
| **slot-machine.html** | Post-scan reveal : animation slot machine, photos shufflent dans les slots du template, haptic click, boutons garder/shuffle/editer. | P0 |
| **first-share-setup.html** | Just-in-time : choix du reseau + setup tone + trigger brainstorming 30Q optionnel. | P1 |

---

## Ecrans a MODIFIER

### 01-welcome.html
**Changement :** Mineur
- Mettre a jour les step dots : 3 etapes au lieu de 5
- Verifier que le copy correspond au final ("15 000 photos. 0 posts.")
- Retirer toute reference a "Skip" dans les edge cases (plus pertinent vu que onboarding = 3 steps ultra-rapides)

### 02-pillars.html → Renommer en 03-pillars.html
**Changement :** Moyen
- Step dots : 3/3 au lieu de 2/5
- Les piliers sont maintenant **pre-remplis** par le Quick Scan (pas une liste generique)
- Ajouter un state "pre-rempli par scan" : les piliers sugggeres sont deja en ON, l'user desactive ceux qu'il ne veut pas
- Retirer le "Back" vers un ecran Tone qui n'existe plus
- Le "Next" declenche le full scan + mene au template nudge

### home-dashboard.html
**Changement :** Moyen
- Ajouter le **nudge template** : card suggestive "Cree un template et PostKit te propose des posts chaque jour →" (visible tant que 0 template)
- Mettre a jour le scan status : le scan demarre apres l'onboarding, pas apres un ecran de permissions
- Quick actions : retirer "Review" si pas d'items a review (conditionnel)
- Ajouter un state "scan en cours post-onboarding" (premier lancement)

### explore-grid.html
**Changement :** Mineur
- Confirmer que le bouton "Select" discret est bien present (v0.2)
- Ajouter le chemin vers "Compose Post" apres multi-select
- Pas de changement structurel

### asset-detail.html
**Changement :** Mineur
- Confirmer la sheet slide-up avec tout editable
- Ajouter "Mark non-pertinent" si pas present
- Pas de changement structurel

### classification-queue.html
**Changement :** Mineur
- Confirmer le rename "Classification Queue" (fait en v0.3)
- Verifier que le tab s'appelle "Classify" (pas "Swipe")

### classification-view.html
**Changement :** Mineur
- Confirmer le micro-editeur (tags/loc/cadrage)
- Note sur le grid mode (v1.2, pas dans le mockup MVP)

### posts-list.html
**Changement :** Moyen
- Ajouter un state "premier post genere par slot machine" (le post vient d'etre cree automatiquement)
- Les 4 slots visuels doivent refleter le template
- Ajouter un badge "Auto-generated" vs "Manual"

### post-editor.html
**Changement :** Significatif
- Integrer le **slot machine** comme mode de reveal (pas juste un editeur statique)
- Ajouter le bouton "Shuffle" pour regenerer
- Ajouter "Suggest Hook" qui trigger le just-in-time tone setup si pas configure
- Les slots montrent les requirements du template

### template-builder.html
**Changement :** Moyen
- Ajouter les **presets** (Carousel 4 photos, Story, Portrait+Hook) comme point de depart
- L'ecran doit pouvoir etre atteint depuis le template nudge ET depuis les settings
- Ajouter la description du template (v0.2 deja fait)

### persona-editor.html
**Changement :** Significatif
- Retirer completement le tone global (v0.2 deja fait)
- Restructurer : Bio → Plateformes connectees (avec tones) → Piliers → Brand Voice (si brainstorming fait)
- Le brainstorming 30Q est accessible ici comme "Affiner ma brand voice"
- Chaque plateforme montre si le brainstorming a ete fait ou pas

### pillars-management.html
**Changement :** Aucun
- Reste tel quel

### scan-settings.html
**Changement :** Mineur
- Verifier coherence avec le nouveau flow (scan demarre apres onboarding)
- La permission Photos est geree dans le quick scan, pas ici (sauf re-trigger si denied)

### stats.html
**Changement :** Aucun
- Reste tel quel

---

## Nouveaux edge cases a documenter

| Ecran | Edge case |
|-------|-----------|
| Quick Scan Preview | Core ML ne detecte aucun pilier (galerie trop petite ou que des screenshots) |
| Quick Scan Preview | Permission denied au moment du scan → fallback vers explications + Settings link |
| Template Nudge | User choisit "Plus tard" → nudge persiste dans le dashboard |
| Slot Machine | Pas assez d'assets pour remplir tous les slots du template → slots partiellement remplis + "Prends plus de photos pour ce slot" |
| Slot Machine | Shuffle atteint la fin des combinaisons possibles → "Tu as vu toutes les combinaisons. Classe plus de photos pour en debloquer." |
| First Share | User refuse le brainstorming → tone par defaut (Professional), textes generiques |
| Dashboard | Scan termine + template existe + 0 match → "Tes photos ne matchent pas encore ce template. Essaie un autre ou classe plus de contenu." |

---

## Ordre de refactoring recommande

1. **Creer** 02-quick-scan-preview.html (nouvel ecran critique)
2. **Modifier** 01-welcome.html (3 step dots)
3. **Modifier** 02-pillars → 03-pillars.html (pre-rempli par scan)
4. **Creer** template-nudge.html
5. **Creer** slot-machine.html
6. **Modifier** home-dashboard.html (nudge template + state post-onboarding)
7. **Modifier** post-editor.html (slot machine + shuffle)
8. **Modifier** posts-list.html (auto-generated badge)
9. **Creer** first-share-setup.html
10. **Modifier** persona-editor.html (restructure)
11. **Supprimer** 03-platforms-tone.html, 04-bio-brainstorm.html, 05-first-scan.html
12. Mises a jour mineures sur les autres ecrans
