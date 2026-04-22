/* Main landing page sections (hero, problem, how, pillars, templates, platforms, persona, download, waitlist, faq) */

const { useState: useS, useEffect: useE, useRef: useR, useMemo: useM } = React;

/* ================== HERO ================== */
function Hero({ lang, copy, density, heroLayout, onCTA }) {
  const h = copy.hero;
  const [afterVisible, setAfterVisible] = useS(false);
  useE(() => { const t = setTimeout(() => setAfterVisible(true), 600); return () => clearTimeout(t); }, []);

  return (
    <section style={{
      position: "relative", padding: density === "airy" ? "140px 48px 80px" : "100px 40px 60px",
      overflow: "hidden",
    }}>
      {/* ambient glow */}
      <div style={{
        position: "absolute", top: -200, left: "50%", transform: "translateX(-50%)",
        width: 900, height: 900, borderRadius: "50%",
        background: "radial-gradient(circle, rgba(0,122,255,.08) 0%, transparent 60%)",
        pointerEvents: "none",
      }}/>

      <div style={{ maxWidth: 1200, margin: "0 auto", position: "relative" }}>
        <div style={{ textAlign: "center", marginBottom: 56 }}>
          <div style={{
            display: "inline-flex", alignItems: "center", gap: 8,
            padding: "6px 14px", borderRadius: 100,
            background: "rgba(0,122,255,.08)", color: "#007aff",
            fontSize: 12, fontWeight: 600, letterSpacing: "-0.01em",
            marginBottom: 24,
          }}>
            <span style={{ width: 6, height: 6, borderRadius: "50%", background: "#34c759", display: "inline-block",
              boxShadow: "0 0 0 3px rgba(52,199,89,.2)" }}/>
            {h.eyebrow}
          </div>
          <h1 style={{
            fontSize: "clamp(40px, 6vw, 76px)", fontWeight: 700,
            letterSpacing: "-0.045em", lineHeight: 1.02,
            margin: 0,
          }}>
            {h.title1}<br/>
            <span style={{
              background: "linear-gradient(135deg,#007aff 0%,#af52de 100%)",
              WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent",
            }}>{h.title2}</span>
          </h1>
          <p style={{
            fontSize: "clamp(16px, 1.4vw, 20px)", color: "#52525b",
            maxWidth: 640, margin: "20px auto 0", lineHeight: 1.5,
          }}>{h.sub}</p>
          <div style={{ display: "flex", gap: 12, justifyContent: "center", marginTop: 32, flexWrap: "wrap" }}>
            <button onClick={onCTA} style={{
              padding: "14px 28px", background: "#0a0a0c", color: "#fff",
              border: 0, borderRadius: 100, fontSize: 15, fontWeight: 600,
              cursor: "pointer", boxShadow: "0 10px 30px -10px rgba(0,0,0,.35)",
              transition: "transform .15s",
            }} onMouseEnter={e => e.currentTarget.style.transform="translateY(-1px)"}
               onMouseLeave={e => e.currentTarget.style.transform="translateY(0)"}>
              {h.cta} →
            </button>
          </div>
          <div style={{ fontSize: 12, color: "#86868b", marginTop: 14 }}>{h.ctaSub}</div>
        </div>

        {/* Split before/after */}
        <div style={{
          display: "grid", gridTemplateColumns: "1fr auto 1fr",
          gap: 20, alignItems: "center",
          maxWidth: 1040, margin: "0 auto",
        }}>
          {/* Before */}
          <div>
            <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", marginBottom: 10 }}>
              <div style={{ fontSize: 11, fontWeight: 700, textTransform: "uppercase", letterSpacing: "0.08em", color: "#ff3b30" }}>
                {h.beforeLabel}
              </div>
              <div style={{ fontSize: 12, color: "#86868b" }}>{h.beforeCaption}</div>
            </div>
            <div style={{
              background: "#fafafa", border: "1px solid rgba(0,0,0,.06)",
              borderRadius: 20, padding: 12,
              boxShadow: "0 20px 40px -20px rgba(0,0,0,.1)",
            }}>
              <ChaosGallery photos={window.POSTKIT.CHAOS_PHOTOS} animate={true}/>
            </div>
          </div>

          <div style={{
            width: 44, height: 44, borderRadius: "50%",
            background: "linear-gradient(135deg,#007aff,#af52de)",
            display: "grid", placeItems: "center", color: "#fff",
            fontSize: 20, fontWeight: 700,
            boxShadow: "0 10px 24px -4px rgba(88,86,214,.4)",
          }}>→</div>

          {/* After */}
          <div>
            <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", marginBottom: 10 }}>
              <div style={{ fontSize: 11, fontWeight: 700, textTransform: "uppercase", letterSpacing: "0.08em", color: "#34c759" }}>
                {h.afterLabel}
              </div>
              <div style={{ fontSize: 12, color: "#86868b" }}>{h.afterCaption}</div>
            </div>
            <div style={{
              background: "linear-gradient(145deg,#f5f5f7,#ffffff)",
              border: "1px solid rgba(0,0,0,.06)",
              borderRadius: 20, padding: 12,
              boxShadow: "0 20px 40px -20px rgba(0,122,255,.15)",
              opacity: afterVisible ? 1 : 0,
              transform: afterVisible ? "translateY(0)" : "translateY(20px)",
              transition: "opacity .6s, transform .6s",
            }}>
              <SortedPillars pillars={window.POSTKIT.PILLARS} lang={lang} dense={true}/>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

/* ================== PROBLEM ================== */
function ProblemSection({ lang, copy, density }) {
  const p = copy.problem;
  return (
    <section style={{ padding: density === "airy" ? "100px 48px" : "72px 40px", background: "#fafafa" }}>
      <div style={{ maxWidth: 1100, margin: "0 auto" }}>
        <div style={{ textAlign: "center", marginBottom: 48 }}>
          <Eyebrow>{p.eyebrow}</Eyebrow>
          <SectionTitle>{p.title}</SectionTitle>
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(4,1fr)", gap: 16 }}>
          {p.points.map((pt, i) => (
            <div key={i} style={{
              background: "#fff", border: "1px solid rgba(0,0,0,.06)",
              borderRadius: 20, padding: "28px 24px", textAlign: "center",
              boxShadow: "0 1px 3px rgba(0,0,0,.03)",
            }}>
              <div style={{
                fontSize: 44, fontWeight: 700, letterSpacing: "-0.04em",
                background: "linear-gradient(135deg,#007aff,#af52de)",
                WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent",
                lineHeight: 1,
              }}>{pt.k}</div>
              <div style={{ fontSize: 13, color: "#52525b", marginTop: 10, lineHeight: 1.4 }}>{pt.v}</div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ================== HOW IT WORKS — 3 steps with live pillar reveal ================== */
function HowSection({ lang, copy, density }) {
  const h = copy.how;
  const [revealedPillars, setRevealedPillars] = useS(0);
  const ref = useR(null);

  useE(() => {
    const el = ref.current; if (!el) return;
    const io = new IntersectionObserver(([e]) => {
      if (e.isIntersecting) {
        // reveal pillars one by one
        window.POSTKIT.PILLARS.forEach((_, i) => {
          setTimeout(() => setRevealedPillars(v => Math.max(v, i+1)), 400 + i*350);
        });
        io.disconnect();
      }
    }, { threshold: 0.3 });
    io.observe(el); return () => io.disconnect();
  }, []);

  return (
    <section ref={ref} style={{ padding: density === "airy" ? "120px 48px" : "84px 40px" }}>
      <div style={{ maxWidth: 1200, margin: "0 auto" }}>
        <div style={{ textAlign: "center", marginBottom: 64 }}>
          <Eyebrow>{h.eyebrow}</Eyebrow>
          <SectionTitle>{h.title}</SectionTitle>
        </div>

        {/* Live reveal visualization */}
        <div style={{
          maxWidth: 820, margin: "0 auto 80px",
          background: "linear-gradient(145deg,#f5f5f7,#ffffff)",
          border: "1px solid rgba(0,0,0,.06)",
          borderRadius: 28, padding: 32,
          boxShadow: "0 30px 60px -20px rgba(0,0,0,.08)",
        }}>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1.2fr", gap: 32, alignItems: "center" }}>
            <div>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(4,1fr)", gap: 3, borderRadius: 12, overflow: "hidden" }}>
                {window.POSTKIT.CHAOS_PHOTOS.slice(0, 16).map((src, i) => {
                  const pillarIdx = Math.floor(i / 4) % window.POSTKIT.PILLARS.length;
                  const highlighted = revealedPillars > pillarIdx;
                  return (
                    <img key={i} src={src} style={{
                      width: "100%", aspectRatio: "1", objectFit: "cover",
                      opacity: highlighted ? 1 : 0.45,
                      filter: highlighted ? "none" : "grayscale(0.6)",
                      transition: `opacity .5s ${i*0.03}s, filter .5s ${i*0.03}s`,
                    }}/>
                  );
                })}
              </div>
              <div style={{ fontSize: 11, color: "#86868b", textAlign: "center", marginTop: 10, fontFamily: "ui-monospace, SF Mono, monospace" }}>
                {lang === "fr" ? "Ta galerie brute" : "Your raw gallery"}
              </div>
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
              {window.POSTKIT.PILLARS.map((p, i) => (
                <div key={p.id} style={{
                  display: "grid", gridTemplateColumns: "auto 1fr auto", gap: 10, alignItems: "center",
                  padding: "10px 14px", borderRadius: 12,
                  background: "#fff",
                  border: `1px solid ${i < revealedPillars ? p.color + "40" : "rgba(0,0,0,.04)"}`,
                  boxShadow: i < revealedPillars ? `0 6px 16px -6px ${p.color}30` : "none",
                  opacity: i < revealedPillars ? 1 : 0.4,
                  transform: i < revealedPillars ? "translateX(0)" : "translateX(10px)",
                  transition: "all .4s",
                }}>
                  <div style={{ width: 28, height: 28, borderRadius: 8, background: `${p.color}15`, display: "grid", placeItems: "center", fontSize: 14 }}>{p.emoji}</div>
                  <div>
                    <div style={{ fontSize: 13, fontWeight: 600 }}>{lang === "fr" ? p.labelFr : p.labelEn}</div>
                    <div style={{ fontSize: 10.5, color: "#86868b" }}>
                      {i < revealedPillars
                        ? (lang === "fr" ? `${p.count} photos détectées` : `${p.count} photos detected`)
                        : (lang === "fr" ? "Analyse..." : "Analyzing...")
                      }
                    </div>
                  </div>
                  <div style={{ fontSize: 11, fontWeight: 700, color: p.color,
                    fontFamily: "ui-monospace, SF Mono, monospace" }}>
                    {i < revealedPillars ? "✓" : "···"}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* 3 step cards */}
        <div style={{ display: "grid", gridTemplateColumns: "repeat(3,1fr)", gap: 20 }}>
          {h.steps.map((s, i) => (
            <div key={i} style={{
              background: "#fff", border: "1px solid rgba(0,0,0,.06)",
              borderRadius: 20, padding: 28,
              boxShadow: "0 1px 2px rgba(0,0,0,.03)",
            }}>
              <div style={{
                fontSize: 11, fontWeight: 700, color: "#007aff",
                fontFamily: "ui-monospace, SF Mono, monospace", marginBottom: 12,
              }}>{s.n}</div>
              <div style={{ fontSize: 22, fontWeight: 700, letterSpacing: "-0.02em", marginBottom: 8 }}>{s.t}</div>
              <div style={{ fontSize: 14, color: "#52525b", lineHeight: 1.55 }}>{s.d}</div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ================== PILLARS SHOWCASE ================== */
function PillarsSection({ lang, copy, density }) {
  const p = copy.pillars;
  const [active, setActive] = useS("dev");
  const activePillar = window.POSTKIT.PILLARS.find(x => x.id === active);

  return (
    <section style={{ padding: density === "airy" ? "120px 48px" : "84px 40px", background: "#0a0a0c", color: "#fff" }}>
      <div style={{ maxWidth: 1200, margin: "0 auto" }}>
        <div style={{ textAlign: "center", marginBottom: 56 }}>
          <Eyebrow dark>{p.eyebrow}</Eyebrow>
          <SectionTitle dark>{p.title}</SectionTitle>
          <p style={{ fontSize: 16, color: "rgba(255,255,255,.6)", marginTop: 14 }}>{p.sub}</p>
        </div>

        <div style={{ display: "grid", gridTemplateColumns: "repeat(5,1fr)", gap: 8, marginBottom: 40 }}>
          {window.POSTKIT.PILLARS.map((pl) => (
            <button key={pl.id} onClick={() => setActive(pl.id)} style={{
              background: active === pl.id ? `${pl.color}20` : "rgba(255,255,255,.04)",
              border: `1px solid ${active === pl.id ? pl.color + "60" : "rgba(255,255,255,.08)"}`,
              borderRadius: 14, padding: "14px 10px", cursor: "pointer",
              color: "#fff", textAlign: "left",
              transition: "all .2s",
            }}>
              <div style={{ fontSize: 22, marginBottom: 6 }}>{pl.emoji}</div>
              <div style={{ fontSize: 13, fontWeight: 600 }}>{lang === "fr" ? pl.labelFr : pl.labelEn}</div>
              <div style={{ fontSize: 11, color: "rgba(255,255,255,.5)", marginTop: 2 }}>{pl.count} photos</div>
            </button>
          ))}
        </div>

        <div style={{ display: "grid", gridTemplateColumns: "repeat(4,1fr)", gap: 4, borderRadius: 20, overflow: "hidden" }}>
          {activePillar.photos.concat(activePillar.photos).slice(0, 8).map((src, i) => (
            <img key={i} src={src} style={{
              width: "100%", aspectRatio: "1", objectFit: "cover", display: "block",
              animation: `fadeScale .4s ${i*0.04}s both`,
            }}/>
          ))}
        </div>
      </div>
    </section>
  );
}

Object.assign(window, { Hero, ProblemSection, HowSection, PillarsSection });

/* helper: eyebrow + section title */
function Eyebrow({ children, dark }) {
  return (
    <div style={{
      fontSize: 11, fontWeight: 700, letterSpacing: "0.12em", textTransform: "uppercase",
      color: dark ? "rgba(255,255,255,.6)" : "#007aff", marginBottom: 14,
    }}>{children}</div>
  );
}
function SectionTitle({ children, dark }) {
  return (
    <h2 style={{
      fontSize: "clamp(28px, 3.4vw, 44px)", fontWeight: 700,
      letterSpacing: "-0.035em", lineHeight: 1.1, margin: 0,
      whiteSpace: "pre-line", color: dark ? "#fff" : "#0a0a0c",
    }}>{children}</h2>
  );
}
Object.assign(window, { Eyebrow, SectionTitle });
