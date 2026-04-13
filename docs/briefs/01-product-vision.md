# PostKit — Product Vision

**Version:** 1.0 · **Date:** April 13, 2026 · **Author:** Nicolas Lucchetta

---

## One-liner

**"Capture une fois. Poste partout. Chaque jour."**

## Problem Statement

1 seconde pour capturer une photo. 1 heure pour la transformer en post. Ce ratio est casse.

Les solopreneurs ont des milliers de photos dans leur galerie — voitures, code, food, voyages, moments — mais tout est melange. Retrouver le bon contenu, l'organiser par theme, ecrire un hook, adapter le ton par plateforme... ca prend plus de temps que de creer le contenu lui-meme.

Resultat : ils postent 1x par semaine au lieu de chaque jour. Leur personal brand stagne.

## Solution

PostKit est une app iOS/macOS native qui :

1. **Scanne** ta galerie photo avec l'IA (Core ML + Gemini Flash)
2. **Classe** chaque photo par pilier de marque (auto, dev, nomad, food...)
3. **Assemble** des posts prets a publier via des templates configurables
4. **Genere** hooks et captions adaptes a chaque plateforme

## Vision fondatrice

"Rendre le posting aussi simple que la capture."

Le contenu existe deja dans la galerie de l'utilisateur. PostKit le trouve, le trie, et le met en forme. Personne d'autre ne fait ca.

## Positionnement

**Pas un scheduler. Pas un editeur. Un assembleur.**

- Buffer, Later, Planoly = tu as deja ton contenu, ils le programment
- Canva = tu crees du contenu graphique
- PostKit = tu as deja le contenu dans ta galerie, PostKit le trouve, le trie, et le transforme en posts

## Product Principles

1. **Show, don't tell** — la valeur est visible avant le paywall
2. **Zero temps mort** — le setup se fait pendant le scan
3. **Native first** — SwiftUI, PhotoKit, Core ML. Pas de web view.
4. **Portfolio-quality** — MVVM + Protocols + DI. Code defensible en entretien iOS.
5. **3-second rule** — chaque ecran compris en 3 secondes

## Dual Objective

1. **Business** — app monetisable, 9.99€/mois, MRR target 250€ mois 1
2. **Portfolio** — piece technique pour entretiens iOS senior (WWDC juin 2026 ready)

## Horizons

| Horizon | Date | Contenu |
|---------|------|---------|
| MVP | Avr 18 | Classification, swipe, posts, onboarding, export album |
| v1.1 | Avr 30 | Templates + AI auto-fill, paywall Pro, premieres conversions |
| v1.2 | Mai | Integration reseaux, iCloud sync, landing page, Product Hunt |
| v2.0 | Juin | Apple AI features (WWDC), Gemma sur Hetzner, multi-platform posting |
