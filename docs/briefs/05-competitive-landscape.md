# PostKit — Competitive Landscape

**Version:** 1.0 · **Date:** April 13, 2026

---

## Positionnement

**"Pas un scheduler. Pas un editeur. Un assembleur."**

PostKit occupe un espace que personne n'occupe : entre la galerie photo et les reseaux sociaux. Le chainon manquant.

---

## Matrice concurrentielle

| App | Ce qu'elle fait | Ce qu'elle NE fait PAS | Pricing | Menace |
|-----|----------------|----------------------|---------|--------|
| **Buffer** | Schedule des posts pre-crees | Pas de classification, pas d'assembly | 6-120$/mo | Faible — complementaire |
| **Later** | Visual planner + scheduling Instagram | Pas de scan galerie, pas d'AI classification | 25-80$/mo | Faible — different segment |
| **Planoly** | Grid planner Instagram | Meme limites que Later | 13-43$/mo | Faible |
| **Canva** | Creation graphique, templates visuels | Ne touche pas ta galerie existante | 0-13$/mo | Faible — different job |
| **Apple Photos** | Organisation basique, albums, recherche | Pas de "pilier de marque", pas de post assembly | Gratuit | Moyen — base native |
| **Google Photos** | AI search, albums auto | Meilleure recherche mais pas de posting workflow | Gratuit | Moyen — pourrait evoluer |
| **TagCam** | AI photo tagging | Pas de post assembly, pas de templates | Freemium | Low |
| **PicSeek** | AI photo search | Recherche only, pas de classification par pilier | Freemium | Low |

---

## Ou PostKit gagne

### vs Schedulers (Buffer, Later, Planoly)

> "Tu as deja ton contenu, ils le programment. PostKit resout le probleme d'AVANT : trouver et assembler le contenu."

Les schedulers partent du principe que tu as un post pret. PostKit cree le post.

### vs Creation (Canva)

> "Canva cree du nouveau contenu graphique. PostKit utilise le contenu que tu as DEJA dans ta galerie."

Pas de templates graphiques, pas d'editeur photo. PostKit assemble tes vraies photos.

### vs Photos apps (Apple/Google Photos)

> "Apple Photos organise par date et lieu. PostKit organise par INTENTION — tes piliers de marque."

La difference : Apple Photos ne sait pas que ta photo de Porsche = pilier "automotive" = post Instagram potentiel.

---

## Notre avantage defensif

1. **Classification par pilier** — concept unique, pas juste du tagging
2. **Templates de posts** — assemblage automatise avec regles (cadrage, pilier, tags)
3. **Persona-driven AI** — le ton s'adapte par plateforme (pas generique)
4. **Native iOS** — PhotoKit, Core ML, SwiftData. Pas une web app wrappee.
5. **Data moat** — plus l'user classe, plus l'app est utile (switching cost)

## Risques

| Risque | Probabilite | Impact | Mitigation |
|--------|------------|--------|-----------|
| Apple ajoute des "piliers" dans Photos | Low | High | On sera plus avance en UX + posting workflow |
| Buffer/Later ajoutent du AI photo scanning | Medium | Medium | Notre classification par pilier est plus profonde |
| Un clone copie le concept | Medium | Low | Execution + native quality + data moat |
| Gemini API change de pricing | Low | Medium | Protocol abstrait, switch vers Gemma/Claude |
