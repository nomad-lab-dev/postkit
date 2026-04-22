/* Cross-platform / iCloud sync section */

function SyncSection({ lang, copy, density, dark = false }) {
  const s = copy.sync;
  const bg = dark ? "transparent" : "#fff";
  const textMuted = dark ? "rgba(255,255,255,.7)" : "#52525b";
  const borderCol = dark ? "rgba(255,255,255,.08)" : "rgba(0,0,0,.06)";
  const cardBg = dark ? "rgba(255,255,255,.04)" : "#fff";
  const PILLARS = window.POSTKIT.PILLARS;

  return (
    <section style={{
      padding: density === "airy" ? "120px 48px" : "84px 40px",
      background: bg, color: dark ? "#fff" : "#0a0a0c",
    }}>
      <div style={{ maxWidth: 1200, margin: "0 auto" }}>
        <div style={{ textAlign: "center", marginBottom: 56 }}>
          <Eyebrow dark={dark}>{s.eyebrow}</Eyebrow>
          <SectionTitle dark={dark}>{s.title}</SectionTitle>
          <p style={{ fontSize: 17, color: textMuted, marginTop: 18, maxWidth: 640, margin: "18px auto 0", lineHeight: 1.5 }}>{s.sub}</p>
        </div>

        {/* Visual stage */}
        <div style={{
          position: "relative",
          background: dark
            ? "linear-gradient(145deg,rgba(255,255,255,.03),rgba(255,255,255,.01))"
            : "linear-gradient(145deg,#f5f5f7,#ffffff)",
          border: "1px solid " + borderCol,
          borderRadius: 28,
          padding: "56px 48px 72px",
          marginBottom: 40,
          boxShadow: dark ? "none" : "0 30px 60px -20px rgba(0,0,0,.08)",
          overflow: "hidden",
        }}>
          {/* Soft blue orb behind iCloud */}
          <div style={{
            position: "absolute", top: "50%", left: "50%",
            transform: "translate(-50%,-50%)",
            width: 360, height: 360, borderRadius: "50%",
            background: "radial-gradient(circle, rgba(0,122,255,.12) 0%, transparent 70%)",
            pointerEvents: "none",
          }}/>

          <div style={{
            display: "grid",
            gridTemplateColumns: "minmax(200px, 240px) minmax(140px, 1fr) minmax(360px, 520px)",
            gap: 24, alignItems: "center",
            position: "relative",
          }}>
            {/* iPhone mockup — PostKit home screen */}
            <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 18 }}>
              <div style={{
                width: 220, aspectRatio: "1/2.05",
                background: "#0a0a0c", borderRadius: 36, padding: 6,
                position: "relative",
                boxShadow: "0 30px 50px -15px rgba(0,0,0,.3), inset 0 0 0 1px rgba(255,255,255,.06)",
              }}>
                <div style={{
                  width: "100%", height: "100%", borderRadius: 30,
                  background: "#f2f2f7", overflow: "hidden", position: "relative",
                }}>
                  {/* Dynamic island */}
                  <div style={{
                    position: "absolute", top: 8, left: "50%", transform: "translateX(-50%)",
                    width: 72, height: 20, borderRadius: 12, background: "#000", zIndex: 3,
                  }}/>
                  {/* Status bar */}
                  <div style={{
                    position: "absolute", top: 0, left: 0, right: 0, height: 34,
                    display: "flex", justifyContent: "space-between", alignItems: "flex-end",
                    padding: "0 16px 5px", fontSize: 10, fontWeight: 600, zIndex: 2,
                  }}>
                    <span>9:41</span>
                    <span style={{ display: "inline-flex", gap: 3, fontSize: 9 }}>
                      <span>􀛨</span><span>􀙇</span><span>􀛪</span>
                    </span>
                  </div>
                  {/* App content */}
                  <div style={{ paddingTop: 40, paddingLeft: 12, paddingRight: 12 }}>
                    <div style={{ fontSize: 8.5, color: "#8e8e93", fontWeight: 500 }}>
                      {lang === "fr" ? "Bonjour" : "Good morning"}
                    </div>
                    <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: "-0.01em", marginTop: 1 }}>Nico</div>
                    {/* scan card */}
                    <div style={{
                      marginTop: 8, padding: "8px 10px",
                      background: "#fff", borderRadius: 10,
                      border: "1px solid rgba(0,122,255,.12)",
                      boxShadow: "0 2px 6px rgba(0,0,0,.03)",
                    }}>
                      <div style={{ fontSize: 9.5, fontWeight: 600 }}>
                        {lang === "fr" ? "12 items à valider" : "12 items to review"}
                      </div>
                      <div style={{ fontSize: 7.5, color: "#8e8e93", marginTop: 1 }}>
                        {lang === "fr" ? "Dernier scan 14:32" : "Last scan 14:32"} · <span style={{ color: "#007aff" }}>Review</span>
                      </div>
                    </div>
                    {/* pillars grid */}
                    <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 4, marginTop: 8 }}>
                      {PILLARS.slice(0, 4).map((p, i) => (
                        <div key={p.id} style={{
                          background: "#fff", borderRadius: 8,
                          border: "1px solid rgba(0,0,0,.04)",
                          padding: 5,
                        }}>
                          <div style={{ display: "flex", alignItems: "center", gap: 3, marginBottom: 3 }}>
                            <span style={{ fontSize: 9 }}>{p.emoji}</span>
                            <span style={{ fontSize: 7, fontWeight: 600, flex: 1, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                              {(lang === "fr" ? p.labelFr : p.labelEn).split(" ")[0]}
                            </span>
                            <span style={{ fontSize: 6, color: p.color, fontWeight: 700 }}>{p.count}</span>
                          </div>
                          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 1 }}>
                            {p.photos.slice(0, 3).map((src, j) => (
                              <img key={j} src={src} style={{ width: "100%", aspectRatio: "1", objectFit: "cover", borderRadius: 1.5 }}/>
                            ))}
                          </div>
                        </div>
                      ))}
                    </div>
                    {/* quick actions */}
                    <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 3, marginTop: 6 }}>
                      {[{ i: "👆", l: lang === "fr" ? "Review" : "Review", on: true }, { i: "📝", l: "Compose" }, { i: "📐", l: lang === "fr" ? "Tpl" : "Tpl" }].map((a, i) => (
                        <div key={i} style={{
                          background: a.on ? "rgba(0,122,255,.08)" : "#fff",
                          border: "1px solid " + (a.on ? "rgba(0,122,255,.12)" : "rgba(0,0,0,.04)"),
                          borderRadius: 7, padding: "3px 2px", textAlign: "center",
                        }}>
                          <div style={{ fontSize: 9 }}>{a.i}</div>
                          <div style={{ fontSize: 6, fontWeight: 600, color: a.on ? "#007aff" : "#333" }}>{a.l}</div>
                        </div>
                      ))}
                    </div>
                  </div>
                  {/* tab bar */}
                  <div style={{
                    position: "absolute", bottom: 0, left: 0, right: 0,
                    background: "rgba(255,255,255,.9)", backdropFilter: "blur(10px)",
                    borderTop: "1px solid rgba(0,0,0,.06)",
                    display: "flex", justifyContent: "space-around",
                    padding: "5px 0 10px",
                  }}>
                    {[{ i: "🏠", l: "Home", on: true }, { i: "🔍", l: "Explore" }, { i: "🏷️", l: "Classify" }, { i: "📝", l: "Posts" }, { i: "👤", l: "Me" }].map((t, i) => (
                      <div key={i} style={{ textAlign: "center", fontSize: 6, color: t.on ? "#007aff" : "#8e8e93", fontWeight: 500 }}>
                        <div style={{ fontSize: 10 }}>{t.i}</div>
                        <div style={{ marginTop: 1 }}>{t.l}</div>
                      </div>
                    ))}
                  </div>
                  {/* home indicator */}
                  <div style={{
                    position: "absolute", bottom: 4, left: "50%", transform: "translateX(-50%)",
                    width: 70, height: 3, borderRadius: 2, background: "rgba(0,0,0,.3)",
                  }}/>
                </div>
              </div>
              <div style={{
                fontSize: 11, fontWeight: 700, letterSpacing: "0.1em", textTransform: "uppercase",
                color: textMuted, fontFamily: "ui-monospace, SF Mono, monospace",
              }}>iPhone · {lang === "fr" ? "Capture" : "Capture"}</div>
            </div>

            {/* Sync column */}
            <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 10, padding: "0 8px" }}>
              <div style={{
                width: 56, height: 56, borderRadius: "50%",
                background: "rgba(0,122,255,.1)",
                border: "1px solid rgba(0,122,255,.2)",
                display: "grid", placeItems: "center",
                boxShadow: "0 0 0 6px rgba(0,122,255,.04)",
              }}>
                <svg width="26" height="26" viewBox="0 0 24 24" fill="none" style={{ color: "#007aff" }}>
                  <path d="M7.5 13.5a4.5 4.5 0 0 1 .4-8.98 5.5 5.5 0 0 1 10.7.98A4 4 0 0 1 18 13.5H7.5z" stroke="currentColor" strokeWidth="1.6" strokeLinejoin="round"/>
                  <path d="M12 11v8m0 0l-3-3m3 3l3-3" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
              </div>
              <div style={{
                position: "relative", height: 2, width: 100,
                background: dark ? "rgba(255,255,255,.1)" : "rgba(0,0,0,.08)", borderRadius: 2,
                overflow: "hidden",
              }}>
                <div style={{
                  position: "absolute", top: 0, height: "100%", width: "40%",
                  background: "linear-gradient(90deg, transparent, #007aff, transparent)",
                  animation: "syncPulse 2.2s ease-in-out infinite",
                }}/>
              </div>
              <div style={{
                fontSize: 11, fontWeight: 700, color: "#007aff",
                fontFamily: "ui-monospace, SF Mono, monospace",
              }}>iCloud</div>
              <div style={{
                fontSize: 9.5, color: textMuted,
                fontFamily: "ui-monospace, SF Mono, monospace",
                textAlign: "center", lineHeight: 1.5,
              }}>{s.chip}</div>
            </div>

            {/* Mac */}
            <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 18, minWidth: 0 }}>
              <div style={{ width: "100%", position: "relative" }}>
                {/* MacBook screen */}
                <div style={{
                  background: "#0a0a0c", borderRadius: "10px 10px 3px 3px",
                  padding: "10px 10px 6px",
                  boxShadow: "0 30px 50px -15px rgba(0,0,0,.25)",
                }}>
                  <div style={{
                    background: "#fafafa", borderRadius: 3, overflow: "hidden",
                    aspectRatio: "16/10",
                  }}>
                    {/* Window chrome */}
                    <div style={{
                      height: 22, background: "rgba(0,0,0,.04)",
                      display: "flex", alignItems: "center", gap: 5, padding: "0 9px",
                      borderBottom: "1px solid rgba(0,0,0,.05)",
                    }}>
                      <div style={{ width: 9, height: 9, borderRadius: "50%", background: "#ff5f57" }}/>
                      <div style={{ width: 9, height: 9, borderRadius: "50%", background: "#febc2e" }}/>
                      <div style={{ width: 9, height: 9, borderRadius: "50%", background: "#28c840" }}/>
                      <div style={{ flex: 1, textAlign: "center", fontSize: 9, color: "#666", fontWeight: 500, letterSpacing: "-0.01em" }}>
                        PostKit — Classify · Dev & Nomad
                      </div>
                    </div>
                    {/* Content: sidebar + grid */}
                    <div style={{ display: "grid", gridTemplateColumns: "96px 1fr", height: "calc(100% - 22px)" }}>
                      <div style={{ background: "rgba(0,0,0,.02)", padding: "8px 6px", borderRight: "1px solid rgba(0,0,0,.04)" }}>
                        <div style={{ fontSize: 7.5, fontWeight: 700, color: "#8e8e93", letterSpacing: "0.06em", textTransform: "uppercase", padding: "0 4px 6px" }}>
                          {lang === "fr" ? "Piliers" : "Pillars"}
                        </div>
                        {PILLARS.map((p, i) => (
                          <div key={p.id} style={{
                            display: "flex", alignItems: "center", gap: 5,
                            padding: "5px 6px", borderRadius: 5, marginBottom: 2,
                            background: i === 1 ? "rgba(0,122,255,.1)" : "transparent",
                            fontSize: 9.5, fontWeight: i === 1 ? 600 : 500,
                            color: i === 1 ? "#007aff" : "#333",
                          }}>
                            <span style={{ fontSize: 10 }}>{p.emoji}</span>
                            <span style={{ flex: 1, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                              {(lang === "fr" ? p.labelFr : p.labelEn).split(" ")[0]}
                            </span>
                            <span style={{ fontSize: 8, color: i === 1 ? "#007aff" : "#999", fontFamily: "ui-monospace, SF Mono, monospace" }}>{p.count}</span>
                          </div>
                        ))}
                      </div>
                      <div style={{ padding: 6, display: "grid", gridTemplateColumns: "repeat(5,1fr)", gap: 3, alignContent: "start", overflow: "hidden" }}>
                        {PILLARS[1].photos.concat(window.POSTKIT.CHAOS_PHOTOS).slice(0, 20).map((src, i) => (
                          <div key={i} style={{ position: "relative" }}>
                            <img src={src} style={{
                              width: "100%", aspectRatio: "1", objectFit: "cover", borderRadius: 3,
                              outline: i === 0 ? "2px solid #007aff" : "none",
                              outlineOffset: i === 0 ? "1px" : "0",
                              display: "block",
                            }}/>
                            {i === 0 && (
                              <div style={{
                                position: "absolute", top: 3, right: 3,
                                width: 10, height: 10, borderRadius: "50%",
                                background: "#34c759", border: "1.5px solid #fff",
                              }}/>
                            )}
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>
                </div>
                {/* base / keyboard bezel */}
                <div style={{
                  height: 9, width: "108%", marginLeft: "-4%",
                  background: "linear-gradient(180deg, #1a1a1c 0%, #3a3a3c 100%)",
                  borderRadius: "0 0 10px 10px",
                }}/>
                {/* notch under */}
                <div style={{
                  height: 3, width: 60, margin: "0 auto",
                  background: "rgba(0,0,0,.3)", borderRadius: "0 0 6px 6px",
                }}/>
              </div>
              <div style={{
                fontSize: 11, fontWeight: 700, letterSpacing: "0.1em", textTransform: "uppercase",
                color: textMuted, fontFamily: "ui-monospace, SF Mono, monospace",
              }}>Mac · {lang === "fr" ? "Classification" : "Classify"}</div>
            </div>
          </div>
        </div>

        {/* 4 bullets */}
        <div style={{ display: "grid", gridTemplateColumns: "repeat(4,1fr)", gap: 16 }}>
          {s.bullets.map((b, i) => {
            const icons = ["📱","🖥️","🔄","🔒"];
            return (
              <div key={i} style={{
                background: cardBg,
                border: "1px solid " + borderCol,
                borderRadius: 18, padding: 24,
              }}>
                <div style={{ fontSize: 22, marginBottom: 10 }}>{icons[i]}</div>
                <div style={{ fontSize: 15, fontWeight: 700, letterSpacing: "-0.01em", marginBottom: 6 }}>{b.t}</div>
                <div style={{ fontSize: 13, color: textMuted, lineHeight: 1.5 }}>{b.d}</div>
              </div>
            );
          })}
        </div>
      </div>

      <style>{`
        @keyframes syncPulse {
          0% { left: -40%; }
          100% { left: 100%; }
        }
      `}</style>
    </section>
  );
}

window.SyncSection = SyncSection;
