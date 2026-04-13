# PostKit — Business Model & Pricing

**Version:** 1.0 · **Date:** April 13, 2026

---

## Model : Freemium + Subscription

### Free Tier (acquisition)

Le hook. L'utilisateur decouvre la valeur sans payer.

| Feature | Limite |
|---------|--------|
| Classification IA | 500 photos max |
| Piliers | 5 max |
| Swipe / Grid classification | Illimite |
| Posts manuels | 3 max |
| Export album Photos | Oui |
| Templates | Non |
| AI auto-fill | Non |
| AI hook/caption | Non |

**Cout pour nous :** ~1.50-3€ par user (500 photos × Gemini Flash). Acceptable comme CAC si conversion > 5%.

### Pro Tier (conversion) — 9.99€/mois ou 79.99€/an

"Gratuit pour trier. Pro pour automatiser."

| Feature | Inclus |
|---------|--------|
| Scan illimite | Oui |
| Piliers illimites | Oui |
| Templates de posts | Oui |
| AI auto-fill des templates | Oui |
| AI hook + caption + conseil | Oui |
| Posts illimites | Oui |
| Ton adapte par plateforme | Oui |
| Brand brainstorming (30 questions) | Oui |

### Pourquoi 9.99€/mois

- Prix standard des outils de productivite creator (Later, Planoly, Buffer solo)
- Le solo entrepreneur reflechit 30 sec mais pas 5 min — c'est le prix de Spotify
- ROI clair : 10€/mois pour gagner 5h/mois = 2€/heure
- Apple prend 30% (7€ net) — viable avec 25 abonnes pour 175€ MRR net

### Conversion Flow (value-first)

```
1. Scan gratuit (500 photos) — l'IA analyse
2. Pendant le scan → setup templates + reseaux
3. Scan termine → 3 posts prets a publier ✨
4. Paywall → "Tu veux ca chaque jour ? 9.99€/mois"
5. Pro → posts illimites, chaque matin, sans effort
```

L'user voit le resultat AVANT de payer. Endowment effect : les posts sont deja "a lui".

### Mur strategique

Le mur est a **500 photos** — assez pour voir la magie du tri (2-3 piliers bien remplis), pas assez pour un usage reel (un createur actif a 2-5K photos pertinentes).

### Evolution future (post-Gemma)

Quand Gemma tourne sur Hetzner (cout zero par scan) :
- Free tier genereux (2000+ photos)
- Volume d'acquisition x4
- Marge sur Pro augmente (plus de cout Gemini)

---

## Objectifs financiers

| Metrique | Mois 1 | Mois 3 | Mois 6 |
|----------|--------|--------|--------|
| Downloads | 500 | 2,000 | 5,000 |
| Free → Pro conversion | 5% | 7% | 10% |
| Abonnes Pro | 25 | 140 | 500 |
| MRR brut | 250€ | 1,400€ | 5,000€ |
| MRR net (post-Apple 30%) | 175€ | 980€ | 3,500€ |

## Cout infrastructure

| Poste | Cout/mois |
|-------|-----------|
| Gemini Flash API (classification) | ~50-200€ selon volume |
| Hetzner (serveur existant) | 0€ (deja paye) |
| Apple Developer | 8€ (99€/an) |
| Vercel (landing) | 0€ (free tier) |
| **Total** | ~60-210€/mois |

Breakeven a ~30 abonnes Pro.
