# PostKit — Session Handoff Brief

**Date:** April 13, 2026
**Objectif:** Ne rien perdre entre les sessions. Ce fichier est le point de reprise.

---

## Ce qui est FAIT

### Product Design (2 jours)
- 17 ecrans designes (HTML mockups, Liquid Glass light mode)
- 38 user stories versionnees (v0.0 → v0.3)
- Screen navigator (holder + iframe, 1 HTML par ecran)
- Product cockpit (hub central)
- Brainstorm variants (bio Q&A, first scan unlock cards)
- 3 rounds de challenge PO/designer completes

### Product Vision
- Vision page live : **https://postkit-vision.vercel.app/docs/postkit-vision.html**
- Avec vraies photos du fondateur (17 webp)
- 4 ecrans mockup integres (classification, dashboard, post editor, template builder)
- Copy auditee avec marketing psychology (13 titres recrits)
- Conversion funnel 5 etapes en timeline verticale
- Logos reseaux sociaux SVG

### Strategy (brainstorming 30 questions)
- App Name : **PostKit: AI Photos to Posts**
- Subtitle : **Camera Roll to Daily Content**
- ICP : Solo entrepreneur (pas content creator)
- Pricing : Free (500 photos) / Pro (9.99€/mois)
- Positioning : "Pas un scheduler. Pas un editeur. Un assembleur."
- Tagline : "Capture une fois. Poste partout. Chaque jour."

### Documentation (9 briefs MD)
- 01 Product Vision
- 02 ICP & Personas
- 03 Business Model & Pricing
- 04 ASO Strategy
- 05 Competitive Landscape
- 06 Go-to-Market Plan
- 07 Design Decisions Log (40+ decisions)
- 08 Product Roadmap (4 phases)
- 09 Conversion Flow (5-step funnel)

### Infra
- Git repo : **github.com/nomad-lab-dev/postkit**
- Vercel : **postkit-vision.vercel.app**
- Notion MCP : configure dans .mcp.json (actif prochaine session)
- Skills installees : ASO, marketing-ideas, app-store-optimization, app-store-opportunity-research, ui-ux-pro-max, karpathy-guidelines, framer-motion-animator

---

## Ce qui reste a FAIRE

### Priorite 1 — Avant de coder (prochaine session)

1. **Notion setup** — Pousser les 9 briefs dans Notion structure
   - User doit : creer page "PostKit" + connecter integration
   - Claude fait : creer toutes les sous-pages et databases

2. **Scope check** — Valider le scope MVP realiste pour ship vendredi 18
   - 38 stories est ambitieux pour 5 jours
   - Identifier les must-have vs nice-to-have
   - Definir la "definition of done" pour le MVP

3. **Landing page** — One-page publique pour le lancement
   - Peut etre generee depuis la vision page
   - Besoin d'un domaine (postkit.app ?)

### Priorite 2 — Dev sprint (lun-ven 14-18)

4. **Installer les skills Swift** avant de coder :
   ```bash
   npx skills add https://github.com/avdlee/swiftui-agent-skill --skill swiftui-expert-skill
   npx skills add https://github.com/twostraws/swiftui-agent-skill --skill swiftui-pro
   ```

5. **Creer le projet Xcode** — Setup multiplateforme, MVVM, protocols

6. **Scope check mercredi 16** — Point milieu, couper si necessaire

### Priorite 3 — Post-MVP (avr 21-30)

7. **Paywall Pro** — StoreKit 2, subscription
8. **Template builder + AI auto-fill**
9. **Product Hunt launch**
10. **ASO iteration #1**

---

## Decisions en suspens

| Decision | Options | A trancher quand |
|----------|---------|-----------------|
| Domaine | postkit.app / postkit.io / getpostkit.com | Avant landing page |
| App Store screenshots | Generer des vrais screenshots vs mockups HTML | Quand le MVP est pret |
| Beta testers | Recruter sur X/LinkedIn ou cercle proche | Avant TestFlight |
| 2eme bouton multi-select (Explore) | "Add to Existing" vs autre | Pendant le dev |

---

## Rappels automatiques

- **Mercredi 16 avril** : scope check dev ("qu'est-ce qu'on coupe pour vendredi ?")
- **Vendredi 18 avril** : TestFlight build + soumission App Store
- **Lundi 21 avril** : launch week commence

---

## Fichiers cles

```
PillarBox/
├── docs/
│   ├── briefs/              ← 9 MD files (vision, personas, pricing, ASO, etc.)
│   ├── postkit-vision.html  ← Vision page (live sur Vercel)
│   ├── postkit-product-cockpit.html
│   ├── postkit-backlog.html ← 38 stories versionnees
│   ├── pillarbox-screens.html ← Screen navigator (holder + iframes)
│   ├── screens/             ← 17 HTML individuels par ecran
│   ├── specs/               ← Design spec technique
│   └── assets/              ← 17 webp + photos fondateur
├── .mcp.json                ← Notion MCP config (local, gitignored)
└── .gitignore
```
