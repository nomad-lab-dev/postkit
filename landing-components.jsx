/* Shared presentational components for PostKit landings */

const { useState, useEffect, useRef, useMemo } = React;

/* ---------- Wordmark ---------- */
function Logo({ dark = false, size = 28 }) {
  const fg = dark ? "#fff" : "#0a0a0c";
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
      <div style={{
        width: size, height: size, borderRadius: size * 0.28,
        background: "linear-gradient(135deg,#007aff 0%,#af52de 100%)",
        display: "grid", placeItems: "center", color: "#fff",
        fontWeight: 800, fontSize: size * 0.5, letterSpacing: "-0.04em",
        boxShadow: "inset 0 1px 0 rgba(255,255,255,.3), 0 1px 2px rgba(0,0,0,.08)",
      }}>
        <svg width={size*0.55} height={size*0.55} viewBox="0 0 24 24" fill="none">
          <rect x="3" y="3" width="8" height="8" rx="1.5" fill="#fff" opacity=".95"/>
          <rect x="13" y="3" width="8" height="8" rx="1.5" fill="#fff" opacity=".65"/>
          <rect x="3" y="13" width="8" height="8" rx="1.5" fill="#fff" opacity=".75"/>
          <rect x="13" y="13" width="8" height="8" rx="1.5" fill="#fff" opacity=".95"/>
        </svg>
      </div>
      <span style={{ fontWeight: 700, fontSize: size * 0.58, letterSpacing: "-0.02em", color: fg }}>
        PostKit
      </span>
    </div>
  );
}

/* ---------- iPhone frame ---------- */
function IPhone({ children, width = 280, dark = false, scale = 1 }) {
  const h = width * 2.17;
  return (
    <div style={{
      width, height: h, borderRadius: width * 0.14,
      background: dark ? "#1c1c1e" : "#0a0a0c",
      padding: 4, position: "relative",
      boxShadow: "0 40px 80px -20px rgba(0,0,0,.25), 0 20px 40px -15px rgba(0,0,0,.18), inset 0 0 0 1px rgba(255,255,255,.08)",
      transform: scale !== 1 ? `scale(${scale})` : undefined,
      transformOrigin: "top center",
    }}>
      <div style={{
        width: "100%", height: "100%", borderRadius: width * 0.125,
        background: dark ? "#000" : "#f2f2f7",
        overflow: "hidden", position: "relative",
      }}>
        {/* Dynamic island */}
        <div style={{
          position: "absolute", top: 8, left: "50%", transform: "translateX(-50%)",
          width: width * 0.3, height: 22, borderRadius: 14, background: "#000", zIndex: 10,
        }}/>
        {/* Status bar */}
        <div style={{
          position: "absolute", top: 0, left: 0, right: 0, height: 38,
          display: "flex", justifyContent: "space-between", alignItems: "flex-end",
          padding: "0 20px 6px", fontSize: 11, fontWeight: 600,
          color: dark ? "#fff" : "#000", zIndex: 5,
        }}>
          <span>9:41</span>
          <span style={{ display: "flex", gap: 4, alignItems: "center" }}>
            <span style={{ fontSize: 10 }}>􀙇</span>
            <span style={{ fontSize: 10 }}>􀛨</span>
            <span style={{ fontSize: 10 }}>􀛪</span>
          </span>
        </div>
        <div style={{ paddingTop: 44, height: "100%", position: "relative" }}>
          {children}
        </div>
      </div>
    </div>
  );
}

/* ---------- Chaos gallery (before) ---------- */
function ChaosGallery({ photos, animate = false }) {
  return (
    <div style={{
      display: "grid", gridTemplateColumns: "repeat(6,1fr)", gap: 2,
      borderRadius: 16, overflow: "hidden",
      filter: "saturate(0.85)",
    }}>
      {photos.map((src, i) => (
        <img key={i} src={src} style={{
          width: "100%", aspectRatio: "1",
          objectFit: "cover", display: "block",
          opacity: animate ? 0 : 1,
          animation: animate ? `chaosIn .4s ${i*0.04}s both` : undefined,
          filter: i % 5 === 0 ? "brightness(0.85)" : i % 7 === 0 ? "saturate(0.6)" : undefined,
        }}/>
      ))}
    </div>
  );
}

/* ---------- Sorted pillars (after) ---------- */
function SortedPillars({ pillars, lang, showBadges = true, dense = false, activeId = null }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: dense ? 6 : 10 }}>
      {pillars.map((p, i) => (
        <div key={p.id} style={{
          background: "#fff",
          border: "1px solid rgba(0,0,0,.06)",
          borderRadius: 14,
          padding: dense ? "8px 10px" : "10px 12px",
          display: "grid",
          gridTemplateColumns: "auto 1fr auto",
          gap: 10,
          alignItems: "center",
          boxShadow: activeId === p.id
            ? `0 8px 24px -6px ${p.color}40, 0 0 0 2px ${p.color}`
            : "0 1px 2px rgba(0,0,0,.03)",
          transition: "box-shadow .3s, transform .3s",
          transform: activeId === p.id ? "translateY(-1px)" : "none",
        }}>
          <div style={{
            width: 32, height: 32, borderRadius: 10,
            background: `${p.color}12`,
            display: "grid", placeItems: "center", fontSize: 16,
          }}>{p.emoji}</div>
          <div>
            <div style={{ fontSize: 13, fontWeight: 600, letterSpacing: "-0.01em" }}>
              {lang === "fr" ? p.labelFr : p.labelEn}
            </div>
            <div style={{ fontSize: 10.5, color: "#86868b" }}>
              {p.count} {lang === "fr" ? "photos" : "photos"}
            </div>
          </div>
          <div style={{ display: "flex", gap: 3 }}>
            {p.photos.slice(0, 3).map((src, j) => (
              <img key={j} src={src} style={{
                width: 26, height: 26, borderRadius: 6,
                objectFit: "cover", boxShadow: "0 1px 2px rgba(0,0,0,.08)",
              }}/>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}

/* ---------- Platform render ---------- */
function PlatformPost({ platform, lang, photos, authorAvatar, authorName = "nico.build" }) {
  const p = platform;
  const [w, h] = p.ratio.split("/").map(Number);
  const aspect = `${w}/${h}`;

  const common = (
    <>
      <img src={photos[0]} style={{
        position: "absolute", inset: 0, width: "100%", height: "100%",
        objectFit: "cover",
      }}/>
    </>
  );

  if (p.id === "ig") {
    return (
      <div style={{ background: "#fff", borderRadius: 14, overflow: "hidden", boxShadow: "0 10px 40px -10px rgba(0,0,0,.2)" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 8, padding: "10px 12px" }}>
          <div style={{ width: 28, height: 28, borderRadius: "50%", background: p.bg, padding: 1.5 }}>
            <img src={authorAvatar} style={{ width: "100%", height: "100%", borderRadius: "50%", border: "2px solid #fff" }}/>
          </div>
          <div style={{ fontSize: 12, fontWeight: 600 }}>{authorName}</div>
          <div style={{ fontSize: 10, color: "#8e8e93", marginLeft: "auto" }}>Bangkok, TH</div>
        </div>
        <div style={{ position: "relative", aspectRatio: aspect, background: "#000" }}>{common}</div>
        <div style={{ padding: "8px 12px 12px" }}>
          <div style={{ display: "flex", gap: 14, fontSize: 18, marginBottom: 6 }}>
            <span>♡</span><span>💬</span><span>↗</span>
          </div>
          <div style={{ fontSize: 11.5, lineHeight: 1.4 }}>
            <strong>{authorName}</strong> {p.caption[lang]}
          </div>
        </div>
      </div>
    );
  }
  if (p.id === "tt") {
    return (
      <div style={{ background: "#000", borderRadius: 14, overflow: "hidden", position: "relative", aspectRatio: aspect, boxShadow: "0 10px 40px -10px rgba(0,0,0,.3)" }}>
        {common}
        <div style={{ position: "absolute", inset: 0, background: "linear-gradient(to top, rgba(0,0,0,.7) 0%, transparent 40%)" }}/>
        <div style={{ position: "absolute", right: 10, bottom: 60, display: "flex", flexDirection: "column", gap: 14, color: "#fff", alignItems: "center", fontSize: 10 }}>
          <div>♡<div style={{ fontSize: 9 }}>12.4k</div></div>
          <div>💬<div style={{ fontSize: 9 }}>284</div></div>
          <div>↗<div style={{ fontSize: 9 }}>Share</div></div>
        </div>
        <div style={{ position: "absolute", left: 12, right: 60, bottom: 12, color: "#fff" }}>
          <div style={{ fontSize: 12, fontWeight: 700 }}>@{authorName}</div>
          <div style={{ fontSize: 11, marginTop: 4, lineHeight: 1.35 }}>{p.caption[lang]}</div>
        </div>
      </div>
    );
  }
  if (p.id === "li") {
    return (
      <div style={{ background: "#fff", borderRadius: 14, overflow: "hidden", boxShadow: "0 10px 40px -10px rgba(0,0,0,.18)" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10, padding: "12px 14px 8px" }}>
          <img src={authorAvatar} style={{ width: 36, height: 36, borderRadius: "50%" }}/>
          <div>
            <div style={{ fontSize: 13, fontWeight: 700 }}>Nicolas L.</div>
            <div style={{ fontSize: 10.5, color: "#666" }}>Indie dev · SaaS founder</div>
            <div style={{ fontSize: 10, color: "#888" }}>2h · 🌐</div>
          </div>
        </div>
        <div style={{ padding: "0 14px 10px", fontSize: 12, lineHeight: 1.5 }}>
          <strong>{p.hook[lang]}</strong>
          <div style={{ marginTop: 6, color: "#444" }}>{p.caption[lang]}</div>
        </div>
        <div style={{ position: "relative", aspectRatio: aspect, background: "#000" }}>{common}</div>
        <div style={{ display: "flex", gap: 18, padding: "10px 14px", fontSize: 11, color: "#666", borderTop: "1px solid #eee" }}>
          <span>👍 Like</span><span>💬 Comment</span><span>↗ Share</span>
        </div>
      </div>
    );
  }
  if (p.id === "x") {
    return (
      <div style={{ background: "#000", color: "#fff", borderRadius: 14, overflow: "hidden", padding: 14, boxShadow: "0 10px 40px -10px rgba(0,0,0,.4)" }}>
        <div style={{ display: "flex", gap: 10, marginBottom: 8 }}>
          <img src={authorAvatar} style={{ width: 36, height: 36, borderRadius: "50%" }}/>
          <div>
            <div style={{ fontSize: 13, fontWeight: 700 }}>nico.build</div>
            <div style={{ fontSize: 11, color: "#71767b" }}>@nicobuild · 2h</div>
          </div>
        </div>
        <div style={{ fontSize: 13, lineHeight: 1.5, marginBottom: 10 }}>
          {p.hook[lang]} {p.caption[lang]}
        </div>
        <div style={{ position: "relative", aspectRatio: aspect, borderRadius: 10, overflow: "hidden", background: "#111" }}>{common}</div>
        <div style={{ display: "flex", justifyContent: "space-between", marginTop: 10, fontSize: 11, color: "#71767b" }}>
          <span>💬 128</span><span>🔁 402</span><span>♡ 2.1k</span><span>📊 18k</span>
        </div>
      </div>
    );
  }
  // pinterest
  return (
    <div style={{ background: "#fff", borderRadius: 14, overflow: "hidden", boxShadow: "0 10px 40px -10px rgba(0,0,0,.18)" }}>
      <div style={{ position: "relative", aspectRatio: aspect, background: "#000" }}>
        {common}
        <div style={{ position: "absolute", top: 10, right: 10, background: "#E60023", color: "#fff", fontSize: 11, fontWeight: 700, padding: "6px 12px", borderRadius: 100 }}>Save</div>
      </div>
      <div style={{ padding: "10px 12px 14px" }}>
        <div style={{ fontSize: 13, fontWeight: 700, lineHeight: 1.3 }}>{p.hook[lang]}</div>
        <div style={{ fontSize: 11, color: "#666", marginTop: 4, lineHeight: 1.4 }}>{p.caption[lang]}</div>
        <div style={{ display: "flex", alignItems: "center", gap: 6, marginTop: 10 }}>
          <img src={authorAvatar} style={{ width: 20, height: 20, borderRadius: "50%" }}/>
          <div style={{ fontSize: 10.5, color: "#666" }}>{authorName}</div>
        </div>
      </div>
    </div>
  );
}

/* ---------- App Store badge ---------- */
function AppStoreBadge({ mac = false }) {
  return (
    <a href="#" onClick={e => e.preventDefault()} style={{
      display: "inline-flex", alignItems: "center", gap: 10,
      padding: "10px 18px", background: "#000", color: "#fff",
      borderRadius: 12, textDecoration: "none",
      transition: "transform .15s", cursor: "pointer",
    }}
    onMouseEnter={e => e.currentTarget.style.transform = "scale(1.03)"}
    onMouseLeave={e => e.currentTarget.style.transform = "scale(1)"}>
      <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
        <path d="M17.05 20.28c-.98.95-2.05.88-3.08.43-1.09-.47-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.43C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09l.01-.01zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z"/>
      </svg>
      <div>
        <div style={{ fontSize: 9, opacity: .8, letterSpacing: "0.02em" }}>
          {mac ? "Download on the" : "Download on the"}
        </div>
        <div style={{ fontSize: 16, fontWeight: 600, marginTop: -2 }}>
          {mac ? "Mac App Store" : "App Store"}
        </div>
      </div>
    </a>
  );
}

Object.assign(window, { Logo, IPhone, ChaosGallery, SortedPillars, PlatformPost, AppStoreBadge });
