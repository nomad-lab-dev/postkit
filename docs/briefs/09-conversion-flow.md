# PostKit — Conversion Flow Detail

**Version:** 1.0 · **Date:** April 13, 2026

---

## Principe : Value-First Paywall

L'onboarding EST la demo. Le paywall arrive APRES la preuve de valeur.

Levier psychologique : **Endowment Effect** — une fois que l'user a vu SES posts construits avec SES photos, il considere deja que c'est a lui. Payer c'est juste "garder ce qui est deja la".

---

## Le funnel en 5 etapes

### Etape 1 — L'IA analyse ta galerie (GRATUIT)

- 500 photos scannees gratuitement
- Core ML (on-device, rapide) + Gemini Flash (cloud, precis)
- Classification par pilier, cadrage, lieu, moment
- Duree : 10-15 minutes
- **L'user ne regarde PAS une progress bar** → il passe a l'etape 2

### Etape 2 — Setup templates et reseaux (PENDANT LE SCAN)

- Zero temps mort : le scan tourne en background
- L'user configure :
  - Ses templates de posts (nombre de slots, cadrages, piliers)
  - Ses reseaux sociaux (Instagram, LinkedIn, X...)
  - Son ton par plateforme
- Duree : 5-10 minutes (= la duree du scan)
- **Quand il finit le setup, le scan est aussi fini**

### Etape 3 — 3 posts prets a publier (MAGIE)

- L'IA a rempli les templates avec les photos classees
- Hook et caption generes
- 3 posts complets, prets a poster sur Instagram, LinkedIn, X, Pinterest, TikTok
- **C'est le moment wow** — l'user voit le resultat concret
- Endowment effect : "ces posts sont les miens"

### Etape 4 — Paywall (APRES LA PREUVE)

- "Tu viens de voir 3 posts prets en 10 minutes."
- "Tu veux ca chaque jour, sur chaque plateforme ?"
- **9.99€/mois** ou **79.99€/an** (2 mois offerts)
- CTA : "Commencer mon essai Pro"
- Alternative : "Continuer en gratuit" (limite a 500 photos + 3 posts)

### Etape 5 — Posts illimites, chaque matin (PRO)

- Scan illimite (toute la galerie)
- Templates illimites
- AI auto-fill quotidien
- Hook + caption + conseil du jour
- Chaque matin, un post frais avec du contenu jamais utilise
- **"Tu captures, PostKit poste."**

---

## Metriques du funnel

| Etape | Metrique | Target |
|-------|----------|--------|
| 1 → 2 | Scan started → setup started | 80% (auto, pas de friction) |
| 2 → 3 | Setup complete → posts generated | 70% |
| 3 → 4 | Posts seen → paywall shown | 100% (auto) |
| 4 → 5 | Paywall → Pro subscription | 5-10% |

## Objections au paywall

| Objection | Reponse integree |
|-----------|-----------------|
| "C'est trop cher" | "Moins qu'un cafe par jour pour poster chaque jour" |
| "Je vais y reflechir" | Les 3 posts restent visibles en free (mais pas les suivants) |
| "Je peux le faire moi-meme" | "Ca t'a pris 10 min avec PostKit. Combien sans ?" |
| "Et si ca me plait pas" | Annulation en 1 tap dans les Settings iOS |
