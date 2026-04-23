/* Sections 2: Templates (slot filling), Platforms switcher, Persona, Download, Waitlist, FAQ, Footer */

const { useState: uS, useEffect: uE, useRef: uR } = React;

/* ================== TEMPLATES — Slot filling triggered by CTA ================== */
function TemplatesSection({ lang, copy, density }) {
  const t = copy.templates;
  const [started, setStarted] = uS(false);
  const [filled, setFilled] = uS([false, false, false, false]);

  // Each slot declares its pillars[] — supports multi-pillar tagging.
  // "Wide" is intentionally multi (travel + life) to demonstrate overlap.
  const SLOTS = [
    { label: "POV",      pillars: ["dev"],           photo: "assets/gallery-dev-1.webp" },
    { label: "Detail",   pillars: ["auto"],          photo: "assets/gallery-auto-1.webp" },
    { label: "Wide",     pillars: ["travel","life"], photo: "assets/gallery-nomad-2.webp" },
    { label: "Portrait", pillars: ["life"],          photo: "assets/gallery-life-1.webp" },
  ];

  const pillarById = (id) => window.POSTKIT.PILLARS.find(p => p.id === id);

  const runFill = () => {
    setStarted(true);
    setFilled([false, false, false, false]);
    SLOTS.forEach((_, i) => setTimeout(() => {
      setFilled(f => { const n = [...f]; n[i] = true; return n; });
    }, 300 + i * 450));
  };

  const replay = () => {
    setFilled([false, false, false, false]);
    SLOTS.forEach((_, i) => setTimeout(() => {
      setFilled(f => { const n = [...f]; n[i] = true; return n; });
    }, 300 + i * 450));
  };

  return (
    <section className="pk-section" style={{ padding: density === "airy" ? "120px 48px" : "84px 40px" }}>
      <div className="pk-grid-templates" style={{ maxWidth: 1200, margin: "0 auto", display: "grid", gridTemplateColumns: "1fr 1.1fr", gap: 64, alignItems: "center" }}>
        <div>
          <Eyebrow>{t.eyebrow}</Eyebrow>
          <SectionTitle>{t.title}</SectionTitle>
          <p style={{ fontSize: 17, color: "#52525b", marginTop: 18, lineHeight: 1.5 }}>{t.sub}</p>
        </div>

        <div style={{
          background: "linear-gradient(145deg,#f5f5f7,#ffffff)",
          border: "1px solid rgba(0,0,0,.06)",
          borderRadius: 24, padding: 28,
          boxShadow: "0 30px 60px -20px rgba(0,0,0,.1)",
          position: "relative",
        }}>
          {/* Card header: title · replay icon button (only after first fill) */}
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 14, gap: 12, minHeight: 28 }}>
            <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: "0.08em", textTransform: "uppercase", color: "#86868b" }}>
              Template · Carousel 4 photos
            </div>
            {started && (
              <button
                onClick={e => {
                  replay();
                  const el = e.currentTarget;
                  el.style.transform = "rotate(-360deg)";
                  setTimeout(() => { el.style.transform = ""; }, 650);
                }}
                title={lang === "fr" ? "Rejouer l'animation" : "Replay animation"}
                aria-label={lang === "fr" ? "Rejouer l'animation" : "Replay animation"}
                className="pk-replay-btn"
                style={{
                  width: 28, height: 28, borderRadius: "50%",
                  background: "rgba(0,122,255,.08)",
                  border: "1px solid rgba(0,122,255,.18)",
                  color: "#007aff",
                  cursor: "pointer",
                  display: "grid", placeItems: "center",
                  padding: 0, lineHeight: 1,
                  fontFamily: "inherit", fontSize: 14,
                  transition: "transform .6s cubic-bezier(.34,1.56,.64,1), background .2s",
                  flex: "0 0 auto",
                  animation: "fadeIn .3s",
                }}
                onMouseEnter={e => {
                  if (!e.currentTarget.style.transform) e.currentTarget.style.background = "rgba(0,122,255,.16)";
                }}
                onMouseLeave={e => { e.currentTarget.style.background = "rgba(0,122,255,.08)"; }}
              >↻</button>
            )}
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 8, position: "relative" }}>
            {SLOTS.map((s, i) => (
              <div key={i} style={{
                aspectRatio: "4/5", borderRadius: 14,
                border: filled[i] ? "1px solid transparent" : "2px dashed rgba(0,0,0,.12)",
                background: filled[i] ? "#000" : "rgba(0,0,0,.02)",
                position: "relative", overflow: "hidden",
                transition: "all .3s",
              }}>
                {filled[i] && (
                  <img src={s.photo} style={{
                    width: "100%", height: "100%", objectFit: "cover",
                    animation: "slotIn .4s both",
                  }}/>
                )}
                {/* Top-left: framing label (POV / Detail / Wide / Portrait) */}
                <div style={{
                  position: "absolute", top: 8, left: 8,
                  padding: "3px 9px", borderRadius: 100,
                  background: filled[i] ? "rgba(255,255,255,.92)" : "rgba(0,0,0,.05)",
                  fontSize: 9.5, fontWeight: 700,
                  color: filled[i] ? "#000" : "#86868b",
                  backdropFilter: "blur(10px)",
                  letterSpacing: "0.04em",
                }}>{s.label}</div>

                {/* Bottom-left: pillar tags (classification result, appears after slot fills) */}
                {filled[i] && (
                  <div style={{
                    position: "absolute", left: 8, bottom: 8, right: 8,
                    display: "flex", gap: 4, flexWrap: "wrap",
                  }}>
                    {s.pillars.map((pid, pi) => {
                      const pl = pillarById(pid);
                      if (!pl) return null;
                      return (
                        <div key={pid} className="pk-slot-pillar-tag" style={{
                          display: "inline-flex", alignItems: "center", gap: 5,
                          padding: "3px 7px 3px 6px",
                          background: "rgba(10,10,12,.62)",
                          backdropFilter: "blur(10px) saturate(160%)",
                          border: "1px solid " + pl.color + "55",
                          borderRadius: 6,
                          fontSize: 9, fontWeight: 700,
                          color: "#fff",
                          letterSpacing: "0.04em",
                          fontFamily: "ui-monospace, 'Geist Mono', SF Mono, monospace",
                          textTransform: "uppercase",
                          animation: `fadeIn .3s ${0.4 + pi * 0.08}s both`,
                        }}>
                          <span style={{
                            width: 6, height: 6, borderRadius: "50%",
                            background: pl.color,
                            boxShadow: "0 0 6px " + pl.color,
                          }}/>
                          {lang === "fr" ? pl.labelFr : pl.labelEn}
                        </div>
                      );
                    })}
                  </div>
                )}

                {!filled[i] && (
                  <div style={{
                    position: "absolute", inset: 0, display: "grid", placeItems: "center",
                    fontSize: 11, color: "#86868b", fontFamily: "ui-monospace, SF Mono, monospace",
                  }}>
                    <div style={{ textAlign: "center", opacity: started ? 1 : 0.5 }}>
                      <div style={{ opacity: .5, fontSize: 18 }}>{started ? "⌕" : "▢"}</div>
                      {started && (
                        <div style={{ marginTop: 4 }}>{lang === "fr" ? "Recherche..." : "Searching..."}</div>
                      )}
                    </div>
                  </div>
                )}
              </div>
            ))}

            {/* CTA button — centered on the grid so the slot transition stays visible behind */}
            {!started && (
              <button
                className="pk-fill-cta"
                onClick={runFill}
                style={{
                  position: "absolute",
                  top: "50%", left: "50%",
                  transform: "translate(-50%, -50%)",
                  display: "inline-flex", alignItems: "center", gap: 10,
                  background: "linear-gradient(135deg, #007aff 0%, #af52de 100%)",
                  color: "#fff",
                  border: "1px solid rgba(255,255,255,.25)",
                  borderRadius: 100,
                  fontSize: 14, fontWeight: 700,
                  cursor: "pointer",
                  boxShadow: "0 14px 36px -6px rgba(0,122,255,.55), 0 0 0 8px rgba(0,122,255,.1)",
                  fontFamily: "inherit",
                  letterSpacing: "-0.01em",
                  padding: "13px 20px",
                  overflow: "hidden",
                  animation: "pkFillPulse 2.4s ease-in-out infinite",
                  zIndex: 5,
                  whiteSpace: "nowrap",
                }}
              >
                <span className="pk-fill-cta-shimmer" aria-hidden="true"/>
                <span style={{ position: "relative", display: "inline-flex", alignItems: "center", gap: 8 }}>
                  <span style={{ fontSize: 16 }}>✨</span>
                  <span>{lang === "fr" ? "Remplir avec ma galerie" : "Fill from my gallery"}</span>
                  <span style={{ fontSize: 16, marginLeft: 2 }}>→</span>
                </span>
              </button>
            )}
          </div>
          <div style={{
            marginTop: 16, padding: "12px 14px",
            background: "rgba(52,199,89,.06)",
            border: "1px solid rgba(52,199,89,.15)",
            borderRadius: 12,
            display: "flex", alignItems: "center", gap: 10,
            opacity: filled.every(Boolean) ? 1 : 0.35,
            transition: "opacity .4s",
          }}>
            <div style={{
              width: 22, height: 22, borderRadius: "50%", background: "#34c759",
              display: "grid", placeItems: "center", color: "#fff", fontSize: 12, fontWeight: 700,
            }}>✓</div>
            <div>
              <div style={{ fontSize: 12.5, fontWeight: 600 }}>
                {lang === "fr" ? "Post prêt à publier" : "Post ready to publish"}
              </div>
              <div style={{ fontSize: 10.5, color: "#52525b", fontFamily: "ui-monospace, SF Mono, monospace" }}>
                Bangkok Morning Hustle · Hook + caption
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

/* ================== PLATFORMS SWITCHER ================== */
function PlatformsSection({ lang, copy, density }) {
  const p = copy.platforms;
  const [activeId, setActiveId] = uS("ig");
  const active = window.POSTKIT.PLATFORMS.find(x => x.id === activeId);
  const photos = ["assets/cinematic-1.webp", "assets/lifestyle-1.webp", "assets/gallery-dev-1.webp"];

  return (
    <section className="pk-section" style={{
      padding: density === "airy" ? "120px 48px" : "84px 40px",
      background: "linear-gradient(180deg,#fafafa 0%,#f0f0f2 100%)",
    }}>
      <div style={{ maxWidth: 1200, margin: "0 auto" }}>
        <div style={{ textAlign: "center", marginBottom: 48 }}>
          <Eyebrow>{p.eyebrow}</Eyebrow>
          <SectionTitle>{p.title}</SectionTitle>
          <p style={{ fontSize: 16, color: "#52525b", marginTop: 14 }}>{p.sub}</p>
        </div>

        <div style={{ display: "flex", gap: 8, justifyContent: "center", marginBottom: 40, flexWrap: "wrap" }}>
          {window.POSTKIT.PLATFORMS.map((pl) => (
            <button key={pl.id} onClick={() => setActiveId(pl.id)} style={{
              padding: "10px 18px", borderRadius: 100,
              background: activeId === pl.id ? "#0a0a0c" : "#fff",
              color: activeId === pl.id ? "#fff" : "#0a0a0c",
              border: "1px solid " + (activeId === pl.id ? "#0a0a0c" : "rgba(0,0,0,.08)"),
              fontSize: 13, fontWeight: 600, cursor: "pointer",
              fontFamily: "inherit",
              transition: "all .15s",
            }}>{pl.name}</button>
          ))}
        </div>

        <div className="pk-platform-shell" style={{
          maxWidth: 520, margin: "0 auto",
          display: "flex", justifyContent: "center",
        }}>
          <div key={activeId} style={{
            width: "100%", maxWidth: 420,
            animation: "fadeScale .35s",
          }}>
            <PlatformPost platform={active} lang={lang} photos={photos} authorAvatar="assets/nico-avatar.webp"/>
          </div>
        </div>
        <div style={{ textAlign: "center", marginTop: 24, fontSize: 12, color: "#86868b", fontFamily: "ui-monospace, SF Mono, monospace" }}>
          {lang === "fr"
            ? "Même contenu source. Ratio, ton et hook adaptés à " + active.name + "."
            : "Same source content. Ratio, tone and hook adapted to " + active.name + "."}
        </div>
      </div>
    </section>
  );
}

/* ================== PERSONA ================== */
function PersonaSection({ lang, copy, density }) {
  const p = copy.persona;
  return (
    <section className="pk-section" style={{ padding: density === "airy" ? "120px 48px" : "84px 40px" }}>
      <div style={{ maxWidth: 900, margin: "0 auto" }}>
        <div style={{ textAlign: "center", marginBottom: 48 }}>
          <Eyebrow>{p.eyebrow}</Eyebrow>
          <SectionTitle>{p.title}</SectionTitle>
        </div>
        <div className="pk-grid-persona" style={{
          display: "grid", gridTemplateColumns: "auto 1fr", gap: 32,
          background: "linear-gradient(145deg,#f5f5f7,#ffffff)",
          border: "1px solid rgba(0,0,0,.06)", borderRadius: 28,
          padding: 40,
          boxShadow: "0 30px 60px -20px rgba(0,0,0,.08)",
        }}>
          <img src="assets/nico-avatar.webp" style={{
            width: 96, height: 96, borderRadius: "50%",
            objectFit: "cover",
            boxShadow: "0 10px 30px -10px rgba(0,0,0,.2)",
          }}/>
          <div>
            <div style={{ fontSize: 20, fontWeight: 700, letterSpacing: "-0.02em" }}>{p.name}</div>
            <div style={{ fontSize: 13, color: "#007aff", fontWeight: 500, marginTop: 2 }}>{p.role}</div>
            <div className="pk-persona-quote" style={{
              marginTop: 16, fontSize: 17, lineHeight: 1.55, color: "#1a1a1c",
              fontStyle: "italic", borderLeft: "3px solid #007aff", paddingLeft: 16,
            }}>"{p.quote}"</div>
          </div>
        </div>
      </div>
    </section>
  );
}

/* ================== DOWNLOAD / PRIVACY ================== */
function DownloadSection({ lang, copy, density }) {
  const d = copy.download;
  return (
    <section className="pk-section pk-download" style={{
      padding: density === "airy" ? "140px 48px" : "100px 40px",
      background: "#0a0a0c", color: "#fff",
      position: "relative", overflow: "hidden",
    }}>
      <div style={{
        position: "absolute", top: "50%", left: "50%", transform: "translate(-50%,-50%)",
        width: 800, height: 800, borderRadius: "50%",
        background: "radial-gradient(circle, rgba(0,122,255,.12) 0%, transparent 60%)",
      }}/>
      <div style={{ maxWidth: 900, margin: "0 auto", textAlign: "center", position: "relative" }}>
        <Eyebrow dark>{d.eyebrow}</Eyebrow>
        <SectionTitle dark>{d.title}</SectionTitle>
        <p style={{ fontSize: 17, color: "rgba(255,255,255,.6)", marginTop: 18, maxWidth: 600, marginLeft: "auto", marginRight: "auto", lineHeight: 1.5 }}>{d.sub}</p>
        <div style={{ display: "flex", gap: 14, justifyContent: "center", marginTop: 36, flexWrap: "wrap" }}>
          <AppStoreBadge/>
          <AppStoreBadge mac/>
        </div>
      </div>
    </section>
  );
}

/* ================== WAITLIST ================== */
function WaitlistSection({ lang, copy, density, onSubmit }) {
  const w = copy.waitlist;
  const [email, setEmail] = uS("");
  const [submitted, setSubmitted] = uS(false);
  const [loading, setLoading] = uS(false);
  const [error, setError] = uS("");
  const [count, setCount] = uS(482);

  const submit = async (e) => {
    e.preventDefault();
    setError("");
    if (!email || !email.includes("@") || !email.includes(".")) {
      setError(lang === "fr" ? "Email invalide." : "Invalid email.");
      return;
    }
    setLoading(true);
    try {
      const res = await fetch("/api/waitlist", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, lang }),
      });
      // If endpoint doesn't exist (local dev / preview), still treat as success for UX
      if (res.status === 404) {
        setSubmitted(true);
        setCount(c => c + 1);
        if (onSubmit) onSubmit(email);
        return;
      }
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        setError(data.error || (lang === "fr" ? "Erreur, réessaye." : "Error, try again."));
        return;
      }
      setSubmitted(true);
      setCount(c => c + 1);
      if (onSubmit) onSubmit(email);
    } catch (err) {
      // Network error in static preview — still show success so UX isn't broken
      setSubmitted(true);
      setCount(c => c + 1);
      if (onSubmit) onSubmit(email);
    } finally {
      setLoading(false);
    }
  };

  return (
    <section id="waitlist" className="pk-section" style={{ padding: density === "airy" ? "120px 48px" : "84px 40px", background: "#fafafa" }}>
      <div style={{ maxWidth: 640, margin: "0 auto", textAlign: "center" }}>
        <Eyebrow>{w.eyebrow}</Eyebrow>
        <SectionTitle>{w.title}</SectionTitle>
        <p style={{ fontSize: 16, color: "#52525b", marginTop: 14 }}>{w.sub}</p>
        {submitted ? (
          <div style={{
            marginTop: 36, padding: "24px 28px",
            background: "linear-gradient(135deg,rgba(52,199,89,.1),rgba(0,122,255,.05))",
            border: "1px solid rgba(52,199,89,.2)", borderRadius: 16,
            fontSize: 15, color: "#0a0a0c", fontWeight: 500,
          }}>
            <div style={{ fontSize: 28, marginBottom: 6 }}>✓</div>
            {w.success}
          </div>
        ) : (
          <>
            <form onSubmit={submit} className="pk-waitlist-form" style={{ display: "flex", gap: 8, marginTop: 28, maxWidth: 480, margin: "28px auto 0" }}>
              <input type="email" value={email} onChange={e => { setEmail(e.target.value); setError(""); }}
                placeholder={w.placeholder} disabled={loading} required style={{
                  flex: 1, padding: "14px 18px", fontSize: 15,
                  border: "1px solid " + (error ? "#ff3b30" : "rgba(0,0,0,.1)"), borderRadius: 100,
                  background: "#fff", outline: "none",
                  fontFamily: "inherit", opacity: loading ? .6 : 1,
                }}/>
              <button type="submit" disabled={loading} style={{
                padding: "14px 24px", background: "#0a0a0c", color: "#fff",
                border: 0, borderRadius: 100, fontSize: 14, fontWeight: 600,
                cursor: loading ? "default" : "pointer", whiteSpace: "nowrap",
                fontFamily: "inherit", opacity: loading ? .7 : 1,
              }}>{loading ? (lang === "fr" ? "…" : "…") : w.button}</button>
            </form>
            {error && (
              <div style={{ fontSize: 12.5, color: "#ff3b30", marginTop: 10 }}>{error}</div>
            )}
          </>
        )}
        <div style={{ fontSize: 12, color: "#86868b", marginTop: 18, fontFamily: "ui-monospace, SF Mono, monospace" }}>
          <span style={{ display: "inline-block", width: 6, height: 6, borderRadius: "50%", background: "#34c759", marginRight: 6, verticalAlign: "middle" }}/>
          {w.counter(count)}
        </div>
      </div>
    </section>
  );
}

/* ================== FAQ ================== */
function FAQSection({ lang, copy, density }) {
  const f = copy.faq;
  const [open, setOpen] = uS(0);
  return (
    <section className="pk-section pk-faq" style={{ padding: density === "airy" ? "120px 48px" : "84px 40px" }}>
      <div style={{ maxWidth: 760, margin: "0 auto" }}>
        <div style={{ textAlign: "center", marginBottom: 48 }}>
          <Eyebrow>{f.eyebrow}</Eyebrow>
          <SectionTitle>{f.title}</SectionTitle>
        </div>
        <div>
          {f.items.map((item, i) => (
            <div key={i} style={{ borderTop: "1px solid rgba(0,0,0,.08)" }}>
              <button onClick={() => setOpen(open === i ? -1 : i)} style={{
                width: "100%", padding: "22px 0", display: "flex",
                justifyContent: "space-between", alignItems: "center",
                background: "none", border: 0, cursor: "pointer",
                fontSize: 16, fontWeight: 600, textAlign: "left",
                color: "#0a0a0c", fontFamily: "inherit",
              }}>
                <span>{item.q}</span>
                <span style={{
                  fontSize: 20, fontWeight: 400,
                  transform: open === i ? "rotate(45deg)" : "rotate(0)",
                  transition: "transform .2s", color: "#86868b",
                }}>+</span>
              </button>
              {open === i && (
                <div style={{ paddingBottom: 22, fontSize: 15, color: "#52525b", lineHeight: 1.55, animation: "fadeIn .25s" }}>
                  {item.a}
                </div>
              )}
            </div>
          ))}
          <div style={{ borderTop: "1px solid rgba(0,0,0,.08)" }}/>
        </div>
      </div>
    </section>
  );
}

/* ================== FOOTER ================== */
function Footer({ copy }) {
  return (
    <footer className="pk-footer" style={{
      padding: "40px 48px",
      borderTop: "1px solid rgba(0,0,0,.06)",
      display: "flex", justifyContent: "space-between", alignItems: "center",
      flexWrap: "wrap", gap: 16,
    }}>
      <Logo size={22}/>
      <div style={{ fontSize: 12, color: "#86868b" }}>{copy.footer.tag}</div>
      <div style={{ display: "flex", gap: 20, fontSize: 12 }}>
        {copy.footer.links.map((l, i) => (
          <a key={i} href="#" onClick={e => e.preventDefault()} style={{ color: "#52525b", textDecoration: "none" }}>{l}</a>
        ))}
      </div>
    </footer>
  );
}

Object.assign(window, { TemplatesSection, PlatformsSection, PersonaSection, DownloadSection, WaitlistSection, FAQSection, Footer });
