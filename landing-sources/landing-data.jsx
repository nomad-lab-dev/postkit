/* Shared copy (FR/EN) + data for PostKit landings */

const COPY = {
  fr: {
    nav: { features: "Fonctions", pillars: "Piliers", pricing: "Pricing", faq: "FAQ", cta: "Get early access" },
    hero: {
      eyebrow: "iOS · macOS · Shipping mai 2026",
      title1: "Ton prochain post",
      title2: "est déjà dans ta galerie.",
      sub: "PostKit scanne tes photos, les classe par pilier de marque, et te livre un post prêt à publier — chaque matin, sur chaque plateforme.",
      cta: "Get early access",
      ctaSub: "Rejoins la waitlist · 482 devs déjà inscrits",
      beforeLabel: "Aujourd'hui",
      beforeCaption: "15 000 photos. Zéro post.",
      afterLabel: "Avec PostKit",
      afterCaption: "5 piliers. 3 posts prêts. Chaque jour.",
    },
    problem: {
      eyebrow: "Le problème",
      title: "Capturer prend 1 seconde.\nPoster devrait aussi.",
      points: [
        { k: "15k", v: "photos dans ta galerie" },
        { k: "30min", v: "à chercher LA bonne photo" },
        { k: "1x/sem", v: "tu postes au lieu de chaque jour" },
        { k: "😤", v: "screenshots, doublons, chaos" },
      ],
    },
    how: {
      eyebrow: "Comment ça marche",
      title: "Du chaos au post en 3 étapes.",
      steps: [
        { n: "01", t: "Scan", d: "Core ML + Gemini analysent ta galerie. 15k photos en 15 min, sans sortir de l'iPhone pour les sensibles." },
        { n: "02", t: "Classify", d: "L'IA détecte tes piliers. Tu valides en swipant. 89 photos triées en 2 minutes." },
        { n: "03", t: "Post", d: "Tes templates se remplissent tout seuls. Hook et caption générés. Prêt pour IG, TikTok, LinkedIn, X, Pinterest." },
      ],
    },
    pillars: {
      eyebrow: "Classification automatique",
      title: "L'IA découvre tes piliers de marque.",
      sub: "Même galerie. Classée en 2 minutes.",
    },
    templates: {
      eyebrow: "Templates intelligents",
      title: "Définis un format.\nL'IA remplit les slots.",
      sub: "Carrousel 4 photos : POV + détail + wide + portrait. PostKit pioche dans tes assets triés et assemble le post. Tu valides. C'est publié.",
    },
    platforms: {
      eyebrow: "Multi-plateformes",
      title: "Un post.\nCinq formats natifs.",
      sub: "Le même contenu reformaté pour chaque plateforme, avec le ton qui va bien.",
    },
    sync: {
      eyebrow: "Cross-platform · iCloud Sync",
      title: "Ta galerie iPhone.\nTon bureau Mac.",
      sub: "Capture au téléphone. Classe au calme sur Mac. Publie depuis là où tu es. PostKit synchronise tes piliers, tes templates et tes posts via iCloud — sans jamais dupliquer tes photos.",
      bullets: [
        { t: "Capture sur iPhone", d: "Shoot, PostKit analyse en arrière-plan dès que t'es en Wi-Fi + chargeur." },
        { t: "Classe sur Mac", d: "Écran large, clavier, trackpad. Swipe 500 photos en 5 minutes sur macOS." },
        { t: "Publie partout", d: "Piliers, templates et drafts sync via iCloud. Reprends exactement où t'en étais." },
        { t: "Zéro duplication", d: "PostKit lit ta Photothèque iCloud via PhotoKit. Aucune copie, aucun stockage en plus." },
      ],
      chip: "Handoff · iCloud Drive · PhotoKit",
    },
    persona: {
      eyebrow: "Pour qui",
      title: "Entrepreneur. Pas content creator.\nEt pourtant tu postes chaque jour.",
      name: "Alex, 32 ans",
      role: "Dev freelance & fondateur d'un micro-SaaS",
      quote: "Je sais que je dois poster pour mon business. J'ai des milliers de photos cool — voyages, code, events. Mais organiser tout ça me prend tellement de temps que je finis par ne rien poster.",
    },
    download: {
      eyebrow: "Shipping mai 2026",
      title: "Natif. Privé. Fait pour durer.",
      sub: "SwiftUI sur iPhone, iPad et Mac. Photos jamais uploadées sans ton consentement. Classification on-device par défaut.",
    },
    waitlist: {
      eyebrow: "Early access",
      title: "Rejoins la waitlist.",
      sub: "Les 1000 premiers inscrits ont 3 mois offerts au lancement.",
      placeholder: "ton@email.com",
      button: "Get early access",
      success: "T'es dedans. On te ping avant tout le monde.",
      counter: (n) => `${n} devs déjà inscrits`,
    },
    faq: {
      eyebrow: "FAQ",
      title: "Les questions qu'on nous pose.",
      items: [
        { q: "Mes photos sont-elles uploadées quelque part ?", a: "Non. La classification tourne on-device avec Core ML. Seules les photos que tu choisis de passer en HD (optionnel) utilisent Gemini Flash, chiffrées en transit." },
        { q: "Ça marche avec iCloud Photos ?", a: "Oui. PostKit lit ta photothèque via PhotoKit — même mécanisme que Photos.app. Pas de copie, pas de duplication." },
        { q: "Quels formats d'export ?", a: "Instagram feed/reels/stories, TikTok, LinkedIn, X, Pinterest. Chaque export est natif au ratio et aux conventions de la plateforme." },
        { q: "Combien ça coûte ?", a: "9,99€/mois après la période d'essai. Pas de tier gratuit avec limitations — juste un essai honnête de 7 jours." },
        { q: "Android ?", a: "Pas prévu. PostKit tire parti de Core ML, PhotoKit et Metal. Un portage Android serait un autre produit." },
      ],
    },
    footer: { tag: "PostKit · Made in Bangkok · 2026", links: ["Privacy", "Terms", "Contact"] },
  },
  en: {
    nav: { features: "Features", pillars: "Pillars", pricing: "Pricing", faq: "FAQ", cta: "Get early access" },
    hero: {
      eyebrow: "iOS · macOS · Shipping May 2026",
      title1: "Your next post",
      title2: "is already in your camera roll.",
      sub: "PostKit scans your photos, sorts them by brand pillar, and ships a ready-to-publish post every morning — on every platform.",
      cta: "Get early access",
      ctaSub: "Join the waitlist · 482 devs signed up",
      beforeLabel: "Today",
      beforeCaption: "15,000 photos. Zero posts.",
      afterLabel: "With PostKit",
      afterCaption: "5 pillars. 3 posts ready. Daily.",
    },
    problem: {
      eyebrow: "The problem",
      title: "Capturing takes 1 second.\nPosting should too.",
      points: [
        { k: "15k", v: "photos in your gallery" },
        { k: "30min", v: "hunting for THE shot" },
        { k: "1×/week", v: "you post instead of daily" },
        { k: "😤", v: "screenshots, dupes, chaos" },
      ],
    },
    how: {
      eyebrow: "How it works",
      title: "From chaos to post in 3 steps.",
      steps: [
        { n: "01", t: "Scan", d: "Core ML + Gemini analyze your gallery. 15k photos in 15 min, on-device for anything sensitive." },
        { n: "02", t: "Classify", d: "AI detects your pillars. You confirm by swiping. 89 photos sorted in 2 minutes." },
        { n: "03", t: "Post", d: "Your templates auto-fill. Hook and caption generated. Ready for IG, TikTok, LinkedIn, X, Pinterest." },
      ],
    },
    pillars: {
      eyebrow: "Automatic classification",
      title: "AI discovers your brand pillars.",
      sub: "Same gallery. Sorted in 2 minutes.",
    },
    templates: {
      eyebrow: "Smart templates",
      title: "Define a format.\nAI fills the slots.",
      sub: "4-photo carousel: POV + detail + wide + portrait. PostKit picks from your sorted assets and assembles the post. You approve. It ships.",
    },
    platforms: {
      eyebrow: "Multi-platform",
      title: "One post.\nFive native formats.",
      sub: "Same content, reformatted for each platform, with the tone that fits.",
    },
    sync: {
      eyebrow: "Cross-platform · iCloud Sync",
      title: "Your iPhone gallery.\nYour Mac desk.",
      sub: "Shoot on phone. Sort in peace on Mac. Post from wherever you are. PostKit syncs your pillars, templates and posts via iCloud — without ever duplicating your photos.",
      bullets: [
        { t: "Shoot on iPhone", d: "Capture, PostKit analyzes in the background whenever you're on Wi-Fi + charger." },
        { t: "Sort on Mac", d: "Big screen, keyboard, trackpad. Swipe 500 photos in 5 minutes on macOS." },
        { t: "Post anywhere", d: "Pillars, templates and drafts sync via iCloud. Pick up exactly where you left off." },
        { t: "Zero duplication", d: "PostKit reads your iCloud library through PhotoKit. No copies, no extra storage." },
      ],
      chip: "Handoff · iCloud Drive · PhotoKit",
    },
    persona: {
      eyebrow: "Who it's for",
      title: "Entrepreneur. Not a content creator.\nAnd yet you post every day.",
      name: "Alex, 32",
      role: "Freelance dev & indie SaaS founder",
      quote: "I know I should post for my business. I've got thousands of cool photos — trips, code, events. But organizing it all takes so long I end up not posting at all.",
    },
    download: {
      eyebrow: "Shipping May 2026",
      title: "Native. Private. Built to last.",
      sub: "SwiftUI on iPhone, iPad and Mac. Photos never uploaded without consent. On-device classification by default.",
    },
    waitlist: {
      eyebrow: "Early access",
      title: "Join the waitlist.",
      sub: "First 1000 signups get 3 months free at launch.",
      placeholder: "your@email.com",
      button: "Get early access",
      success: "You're in. We'll ping you first.",
      counter: (n) => `${n} devs already signed up`,
    },
    faq: {
      eyebrow: "FAQ",
      title: "Questions we get asked.",
      items: [
        { q: "Are my photos uploaded anywhere?", a: "No. Classification runs on-device with Core ML. Only photos you opt into HD use Gemini Flash, encrypted in transit." },
        { q: "Does it work with iCloud Photos?", a: "Yes. PostKit reads your library via PhotoKit — same mechanism as Photos.app. No copy, no duplication." },
        { q: "Which export formats?", a: "Instagram feed/reels/stories, TikTok, LinkedIn, X, Pinterest. Each export is native to the platform's ratio and conventions." },
        { q: "How much does it cost?", a: "€9.99/month after the trial. No crippled free tier — just an honest 7-day trial." },
        { q: "Android?", a: "Not planned. PostKit leans on Core ML, PhotoKit and Metal. An Android port would be a different product." },
      ],
    },
    footer: { tag: "PostKit · Made in Bangkok · 2026", links: ["Privacy", "Terms", "Contact"] },
  },
};

const PILLARS = [
  { id: "auto", emoji: "🚗", labelFr: "Automotive", labelEn: "Automotive", count: 89, color: "#007aff",
    photos: ["assets/gallery-auto-1.webp","assets/gallery-auto-2.webp","assets/gallery-auto-3.webp","assets/gallery-auto-4.webp"] },
  { id: "dev", emoji: "💻", labelFr: "Dev & Nomad", labelEn: "Dev & Nomad", count: 342, color: "#5856d6",
    photos: ["assets/gallery-dev-1.webp","assets/gallery-dev-2.webp","assets/gallery-dev-3.webp","assets/gallery-nomad-3.webp"] },
  { id: "travel", emoji: "✈️", labelFr: "Travel", labelEn: "Travel", count: 215, color: "#34c759",
    photos: ["assets/gallery-nomad-1.webp","assets/gallery-nomad-2.webp","assets/gallery-nomad-4.webp","assets/gallery-food-1.webp"] },
  { id: "food", emoji: "🍜", labelFr: "Food & Bangkok", labelEn: "Food & Bangkok", count: 128, color: "#ff9500",
    photos: ["assets/gallery-food-2.webp","assets/gallery-food-3.webp","assets/gallery-food-1.webp","assets/gallery-nomad-4.webp"] },
  { id: "life", emoji: "🎭", labelFr: "Lifestyle", labelEn: "Lifestyle", count: 67, color: "#af52de",
    photos: ["assets/gallery-life-1.webp","assets/gallery-life-2.webp","assets/gallery-life-3.webp","assets/gallery-auto-1.webp"] },
];

const CHAOS_PHOTOS = [
  "assets/gallery-auto-1.webp","assets/gallery-food-1.webp","assets/gallery-dev-1.webp",
  "assets/gallery-life-1.webp","assets/gallery-nomad-2.webp","assets/gallery-auto-3.webp",
  "assets/gallery-nomad-1.webp","assets/gallery-life-2.webp","assets/gallery-auto-2.webp",
  "assets/gallery-food-2.webp","assets/gallery-nomad-3.webp","assets/gallery-dev-2.webp",
  "assets/gallery-food-3.webp","assets/gallery-auto-4.webp","assets/gallery-life-3.webp",
  "assets/gallery-dev-3.webp","assets/gallery-nomad-4.webp","assets/gallery-auto-1.webp",
];

const PLATFORMS = [
  { id: "ig",  name: "Instagram", ratio: "4/5",  bg: "linear-gradient(135deg,#FEDA75 0%,#FA7E1E 25%,#D62976 50%,#962FBF 75%,#4F5BD5 100%)",
    hook: { fr: "Bangkok au lever du jour. Dev life.", en: "Bangkok at sunrise. Dev life." },
    caption: { fr: "5h30. Le code tourne. Le café refroidit. La ville s'allume. Pourquoi je fais ça ici ? Parce qu'ici, le temps m'appartient.", en: "5:30am. Code running. Coffee cooling. City waking up. Why here? Because here, time is mine." } },
  { id: "tt",  name: "TikTok",    ratio: "9/16", bg: "#000",
    hook: { fr: "POV : tu codes depuis Bangkok", en: "POV: you code from Bangkok" },
    caption: { fr: "Jour 47 du nomad life. Le setup, le café, la vue. #devlife #bangkok #nomad", en: "Day 47 of nomad life. The setup, the coffee, the view. #devlife #bangkok #nomad" } },
  { id: "li",  name: "LinkedIn",  ratio: "1/1",  bg: "#0A66C2",
    hook: { fr: "Pourquoi j'ai déplacé mon bureau à 9 500 km de chez moi", en: "Why I moved my office 6,000 miles from home" },
    caption: { fr: "3 leçons de 6 mois de remote depuis l'Asie : 1) La discipline remplace le manager. 2) Le fuseau horaire est un asset, pas un problème. 3) Le coût de la vie divisé par 3 ne compense jamais la solitude. Mais le build shipping à 5h du mat' le vaut.", en: "3 lessons from 6 months remote in Asia: 1) Discipline replaces your manager. 2) Timezone is an asset, not a problem. 3) Cost of living divided by 3 never offsets loneliness. But shipping at 5am is worth it." } },
  { id: "x",   name: "X",         ratio: "16/9", bg: "#000",
    hook: { fr: "Bangkok, 5h30. Le build est vert.", en: "Bangkok, 5:30am. Build's green." },
    caption: { fr: "Ship quand la ville dort. C'est ça, le remote.", en: "Ship while the city sleeps. That's remote." } },
  { id: "pin", name: "Pinterest", ratio: "2/3",  bg: "#E60023",
    hook: { fr: "Dev nomad setup — Bangkok", en: "Dev nomad setup — Bangkok" },
    caption: { fr: "Morning routine pour créateurs en remote. Save this.", en: "Morning routine for remote creators. Save this." } },
];

window.POSTKIT = { COPY, PILLARS, CHAOS_PHOTOS, PLATFORMS };
