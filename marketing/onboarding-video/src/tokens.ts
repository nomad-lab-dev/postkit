/** Shared design tokens — match the iOS app / landing brand */

export const FPS = 30;

/** Per-scene durations (seconds). No pauses — scenes cross-fade into each other. */
export const SCENE_DURATIONS = {
  scene1Hook: 5,
  scene2Demo: 5.5,
  scene3Pillars: 4,
  scene4Sort: 4,
  scene5Turn: 4,
} as const;

/** Overlap between consecutive scenes (in frames). 16f @ 30fps ≈ 0.53s.
 *  During this window the outgoing scene slides right (off-screen) while
 *  the incoming scene slides in from left — conveyor-belt transition. */
export const CROSSFADE_FRAMES = 16;

/** Cumulative frame starts with cross-fade overlap math */
export const SCENE_STARTS = (() => {
  const keys = Object.keys(SCENE_DURATIONS) as (keyof typeof SCENE_DURATIONS)[];
  const out = {} as Record<keyof typeof SCENE_DURATIONS, number>;
  let cursor = 0;
  for (const k of keys) {
    out[k] = cursor;
    cursor += SCENE_DURATIONS[k] * FPS - CROSSFADE_FRAMES;
  }
  return out;
})();

const lastKey = Object.keys(SCENE_DURATIONS).pop() as keyof typeof SCENE_DURATIONS;
export const TOTAL_FRAMES = SCENE_STARTS[lastKey] + SCENE_DURATIONS[lastKey] * FPS;
export const TOTAL_SEC = TOTAL_FRAMES / FPS;

export const COLORS = {
  brandBlue: "#007AFF",
  brandPurple: "#AF52DE",
  brandPink: "#FF2D55",
  accent: "#FF9500",
  green: "#34C759",
  white: "#FFFFFF",
  bgDark: "#0E0E12",
  textDark: "#1C1C1E",
  textMuted: "#8E8E93",
  surface: "#FFFFFF",
  bg: "#F0F6FF",
} as const;

export const FONTS = {
  display: '"Space Grotesk", system-ui, sans-serif',
  serif: '"Instrument Serif", Georgia, serif',
  mono: '"Geist Mono", "SF Mono", ui-monospace, monospace',
} as const;

/**
 * Translations — headlines per locale.
 * Each scene complements the in-phone content with a benefit framing.
 * Marketing-psychology levers:
 *   1 — endowment ("your gallery is full of assets")
 *   2 — time savings
 *   3 — brand-clarity commitment
 *   4 — division-of-labor relief
 *   5 — habit anchoring
 */
export type SceneCopy = {
  // ── EXTERNAL (above/below phone on gradient bg) ────────────────
  /** Eyebrow above the marketing headline ("STEP 01 · UNCOVER") */
  marketingEyebrow: string;
  /** First word(s) of the top marketing headline */
  marketingTop: string;
  /** Italic em of the top marketing headline */
  marketingTopEm: string;
  /** Optional split-headline: bottom prefix (Scene 1 only) */
  marketingBottom?: string;
  /** Optional split-headline: bottom em (Scene 1 only) */
  marketingBottomEm?: string;

  // ── IN-PHONE (inside the phone screen) ─────────────────────────
  /** Mono uppercase chip inside the phone */
  eyebrow: string;
  /** Text BEFORE the italic em — may include "\n" for line breaks */
  prefix: string;
  /** The italic Instrument Serif emphasis word */
  em: string;
  /** Text AFTER the em (include leading space if needed) */
  suffix?: string;
  /** Primary CTA at bottom of the phone */
  cta: string;
};
export type Translation = {
  scene1: SceneCopy;
  scene2: SceneCopy;
  scene3: SceneCopy;
  scene4: SceneCopy;
  scene5: SceneCopy;
};

export const HEADLINES_EN: Translation = {
  scene1: {
    marketingEyebrow: "STEP 01 · UNCOVER",
    marketingTop: "Your gallery's",
    marketingTopEm: "already full.",
    marketingBottom: "PostKit pulls",
    marketingBottomEm: "the posts out.",
    eyebrow: "Step 01 · Hook",
    prefix: "Your gallery,",
    em: "two ways.",
    cta: "Show me the change →",
  },
  scene2: {
    marketingEyebrow: "STEP 02 · GENERATE",
    marketingTop: "From idea to post",
    marketingTopEm: "in 2 seconds.",
    eyebrow: "Step 02 · Smart Post",
    prefix: "Type a sentence.\n",
    em: "Get",
    suffix: " a post.",
    cta: "Continue · I'm sold →",
  },
  scene3: {
    marketingEyebrow: "STEP 03 · DEFINE",
    marketingTop: "Your brand,",
    marketingTopEm: "defined once.",
    eyebrow: "Your turn",
    prefix: "What do",
    em: "you",
    suffix: " post about?",
    cta: "Continue with 4 pillars →",
  },
  scene4: {
    marketingEyebrow: "STEP 04 · AUTOMATE",
    marketingTop: "We sort.",
    marketingTopEm: "You curate.",
    eyebrow: "Sorting your gallery",
    prefix: "Tagging photos\nto",
    em: "pillars.",
    cta: "Continue · gallery ready →",
  },
  scene5: {
    marketingEyebrow: "STEP 05 · RITUAL",
    marketingTop: "30 seconds.",
    marketingTopEm: "Every morning.",
    eyebrow: "Done. 191 photos sorted.",
    prefix: "Now",
    em: "your",
    suffix: " first prompt.",
    cta: "Generate my first post →",
  },
};

export const HEADLINES_FR: Translation = {
  scene1: {
    marketingEyebrow: "ÉTAPE 01 · RÉVÉLER",
    marketingTop: "Ta galerie déborde",
    marketingTopEm: "de contenu.",
    marketingBottom: "PostKit en fait",
    marketingBottomEm: "des posts.",
    eyebrow: "Étape 01 · Hook",
    prefix: "Ta galerie,",
    em: "deux versions.",
    cta: "Montre-moi la différence →",
  },
  scene2: {
    marketingEyebrow: "ÉTAPE 02 · GÉNÉRER",
    marketingTop: "De l'idée au post",
    marketingTopEm: "en 2 secondes.",
    eyebrow: "Étape 02 · Smart Post",
    prefix: "Écris une phrase.\n",
    em: "Reçois",
    suffix: " un post.",
    cta: "Continuer · vendu →",
  },
  scene3: {
    marketingEyebrow: "ÉTAPE 03 · DÉFINIR",
    marketingTop: "Définis ton personal branding",
    marketingTopEm: "une fois pour toutes.",
    eyebrow: "À toi de jouer",
    prefix: "De quoi tu",
    em: "parles",
    suffix: " ?",
    cta: "Continuer avec 4 piliers →",
  },
  scene4: {
    marketingEyebrow: "ÉTAPE 04 · AUTOMATISER",
    marketingTop: "On trie.",
    marketingTopEm: "Tu choisis.",
    eyebrow: "Tri de ta galerie",
    prefix: "Photos classées\npar",
    em: "piliers.",
    cta: "Continuer · galerie prête →",
  },
  scene5: {
    marketingEyebrow: "ÉTAPE 05 · RITUEL",
    marketingTop: "1 post en 30 sec.",
    marketingTopEm: "Chaque jour.",
    eyebrow: "Prêt. 191 photos triées.",
    prefix: "À",
    em: "toi",
    suffix: " le premier prompt.",
    cta: "Générer mon premier post →",
  },
};

export const HEADLINES_ES: Translation = {
  scene1: {
    marketingEyebrow: "PASO 01 · DESCUBRIR",
    marketingTop: "Tu galería",
    marketingTopEm: "ya está llena.",
    marketingBottom: "PostKit saca",
    marketingBottomEm: "los posts.",
    eyebrow: "Paso 01 · Hook",
    prefix: "Tu galería,",
    em: "dos versiones.",
    cta: "Muéstrame el cambio →",
  },
  scene2: {
    marketingEyebrow: "PASO 02 · GENERAR",
    marketingTop: "De idea a post",
    marketingTopEm: "en 2 segundos.",
    eyebrow: "Paso 02 · Smart Post",
    prefix: "Escribe una frase.\n",
    em: "Obtén",
    suffix: " un post.",
    cta: "Continuar · me convence →",
  },
  scene3: {
    marketingEyebrow: "PASO 03 · DEFINIR",
    marketingTop: "Tu marca,",
    marketingTopEm: "definida una vez.",
    eyebrow: "Tu turno",
    prefix: "¿De qué hablas",
    em: "tú",
    suffix: "?",
    cta: "Continuar con 4 pilares →",
  },
  scene4: {
    marketingEyebrow: "PASO 04 · AUTOMATIZAR",
    marketingTop: "Nosotros ordenamos.",
    marketingTopEm: "Tú curas.",
    eyebrow: "Ordenando tu galería",
    prefix: "Etiquetando fotos\na",
    em: "pilares.",
    cta: "Continuar · galería lista →",
  },
  scene5: {
    marketingEyebrow: "PASO 05 · RITUAL",
    marketingTop: "30 segundos.",
    marketingTopEm: "Cada mañana.",
    eyebrow: "Hecho. 191 fotos ordenadas.",
    prefix: "Ahora",
    em: "tu",
    suffix: " primer prompt.",
    cta: "Generar mi primer post →",
  },
};

/** Backwards-compat alias — most internal code still imports `HEADLINES` directly */
export const HEADLINES = HEADLINES_EN;
