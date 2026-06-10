import { Img, interpolate, useCurrentFrame, useVideoConfig } from "remotion";
import { COLORS, FONTS, type SceneCopy } from "../tokens";
import { Stage, usePhoneScale } from "../Phone";

interface Props { copy: SceneCopy; }

/**
 * Scene 1 — Hook: Before/After toggle (5s · 150f)
 *
 * Pixel-perfect port of `index-final-v2.html` Step 01:
 *   - Eyebrow chip "Step 01 · Hook" (blue tint)
 *   - Headline "Your gallery, two ways." with orange italic em
 *   - Segmented control "Without / With PostKit"
 *   - Stage: chaos cloud (9 scattered photos) → mini-bento 2×2 cross-fade
 *   - Dark CTA "Show me the change →"
 *
 * Sizes are expressed in mockup-px and multiplied by `usePhoneScale` so the
 * rendered output matches the static HTML mockup proportionally at any frame
 * resolution (1080×1920, 1242×2688, etc).
 */

const CHAOS = [
  { src: "https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=300&h=300&fit=crop&auto=format&q=70", top: 0,   left: 0,   rotate: -8 },
  { src: "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=300&h=300&fit=crop&auto=format&q=70", top: 5,   left: 48,  rotate: 4 },
  { src: "https://images.unsplash.com/photo-1531572753322-ad063cecc140?w=300&h=300&fit=crop&auto=format&q=70", top: 0,   left: 104, rotate: -3 },
  { src: "https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=300&h=300&fit=crop&auto=format&q=70", top: 50,  left: 18,  rotate: 7 },
  { src: "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=300&h=300&fit=crop&auto=format&q=70", top: 50,  left: 74,  rotate: -6 },
  { src: "https://images.unsplash.com/photo-1499678329028-101435549a4e?w=300&h=300&fit=crop&auto=format&q=70", top: 55,  left: 124, rotate: 9 },
  { src: "https://images.unsplash.com/photo-1494976388531-d1058494cdd8?w=300&h=300&fit=crop&auto=format&q=70", top: 100, left: 6,   rotate: -5 },
  { src: "https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=300&h=300&fit=crop&auto=format&q=70", top: 108, left: 62,  rotate: 8 },
  { src: "https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?w=300&h=300&fit=crop&auto=format&q=70", top: 104, left: 118, rotate: -9 },
];

const BENTO_CELLS = [
  { label: "🚗 Cars",   count: 47, src: "https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=400&h=300&fit=crop&auto=format&q=70" },
  { label: "☕ Coffee", count: 32, src: "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=400&h=300&fit=crop&auto=format&q=70" },
  { label: "🌍 Travel", count: 89, src: "https://images.unsplash.com/photo-1499678329028-101435549a4e?w=400&h=300&fit=crop&auto=format&q=70" },
  { label: "💼 Build",  count: 23, src: "https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=400&h=300&fit=crop&auto=format&q=70" },
];

export const Scene1Hook: React.FC<Props> = ({ copy }) => {
  const frame = useCurrentFrame();
  const s = usePhoneScale(true);  // split-headline layout
  const { width, height } = useVideoConfig();
  // On iPad canvas (wide aspect), spread chaos photos to fill the taller content area.
  const pm = width / height > 0.6 ? 1.4 : 1;

  const chaosOpacity = interpolate(frame, [60, 100], [1, 0], { extrapolateRight: "clamp" });
  const chaosScale = interpolate(frame, [60, 100], [1, 1.05], { extrapolateRight: "clamp" });
  const bentoOpacity = interpolate(frame, [72, 110], [0, 1], { extrapolateRight: "clamp" });
  const bentoScale = interpolate(frame, [72, 110], [0.94, 1], { extrapolateRight: "clamp" });
  const togglePos = interpolate(frame, [55, 80], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });

  return (
    <Stage
      screenBg="#F0F6FF"
      marketingEyebrow={copy.marketingEyebrow}
      marketingTop={copy.marketingTop}
      marketingTopEm={copy.marketingTopEm}
      marketingBottom={copy.marketingBottom}
      marketingBottomEm={copy.marketingBottomEm}
    >
      {/* Eyebrow chip — blue tint (mockup 9px font / 3 8 padding) */}
      <div style={{
        display: "inline-flex",
        alignItems: "center",
        padding: `${3 * s}px ${10 * s}px`,
        borderRadius: 100,
        background: "rgba(0,122,255,0.10)",
        color: COLORS.brandBlue,
        fontSize: 10 * s,
        fontWeight: 600,
        fontFamily: FONTS.mono,
        letterSpacing: "0.06em",
        textTransform: "uppercase",
        marginBottom: 8 * s,
        alignSelf: "flex-start",
      }}>
        {copy.eyebrow}
      </div>

      {/* Headline — Space Grotesk Bold + Instrument Serif italic em (mockup 19px) */}
      <div style={{
        fontFamily: FONTS.display,
        fontWeight: 700,
        fontSize: 20 * s,
        lineHeight: 1.08,
        letterSpacing: "-0.02em",
        marginBottom: 12 * s,
        color: COLORS.textDark,
      }}>
        {copy.prefix}{" "}
        <span style={{ fontFamily: FONTS.serif, fontStyle: "italic", fontWeight: 400, color: "#FF9500" }}>
          {copy.em}
        </span>
        {copy.suffix ?? ""}
      </div>

      {/* Segmented control (mockup 9px font / 3px padding container) */}
      <div style={{
        display: "grid",
        gridTemplateColumns: "1fr 1fr",
        background: "rgba(0,0,0,0.06)",
        borderRadius: 100,
        padding: 3 * s,
        marginBottom: 12 * s,
        position: "relative",
      }}>
        <div style={{
          position: "absolute",
          top: 3 * s,
          bottom: 3 * s,
          left: `calc(${togglePos * 50}% + ${3 * s}px)`,
          width: `calc(50% - ${6 * s}px)`,
          background: "#FFFFFF",
          borderRadius: 100,
          boxShadow: "0 1px 3px rgba(0,0,0,0.10)",
          transition: "left 0.3s",
        }} />
        <div style={{
          padding: `${6 * s}px ${4 * s}px`,
          textAlign: "center",
          fontSize: 8 * s,
          fontWeight: 700,
          whiteSpace: "nowrap",
          minWidth: 0,
          color: togglePos < 0.5 ? COLORS.textDark : "rgba(0,0,0,0.55)",
          fontFamily: FONTS.mono,
          letterSpacing: "0.04em",
          zIndex: 2,
          position: "relative",
        }}>Without</div>
        <div style={{
          padding: `${6 * s}px ${4 * s}px`,
          textAlign: "center",
          fontSize: 8 * s,
          fontWeight: 700,
          whiteSpace: "nowrap",
          minWidth: 0,
          color: togglePos >= 0.5 ? COLORS.textDark : "rgba(0,0,0,0.55)",
          fontFamily: FONTS.mono,
          letterSpacing: "0.04em",
          zIndex: 2,
          position: "relative",
        }}>With PostKit</div>
      </div>

      {/* Stage that fills remaining space (chaos OR mini-bento) */}
      <div style={{ position: "relative", flex: 1, marginTop: 4 * s, marginBottom: 8 * s, overflow: "hidden" }}>
        {/* CHAOS pane — 9 scattered photos */}
        <div style={{
          position: "absolute",
          inset: 0,
          opacity: chaosOpacity,
          transform: `scale(${chaosScale})`,
          transformOrigin: "center",
        }}>
          <div style={{ position: "relative", width: "100%", height: "100%" }}>
            {CHAOS.map((p, i) => {
              const wobble = Math.sin((frame + i * 9) * 0.05) * 1.2;
              const sp = s * pm;
              return (
                <div
                  key={i}
                  style={{
                    position: "absolute",
                    top: `${p.top * sp}px`,
                    left: `${p.left * sp}px`,
                    width: `${46 * sp}px`,
                    height: `${46 * sp}px`,
                    borderRadius: 6 * sp,
                    overflow: "hidden",
                    transform: `rotate(${p.rotate + wobble}deg)`,
                    boxShadow: `0 ${4 * sp}px ${10 * sp}px rgba(0,0,0,0.25)`,
                    zIndex: i,
                  }}
                >
                  <Img src={p.src} style={{ width: "100%", height: "100%", objectFit: "cover", display: "block" }} />
                </div>
              );
            })}
          </div>
        </div>

        {/* BENTO pane — 2×2 grid */}
        <div style={{
          position: "absolute",
          inset: 0,
          opacity: bentoOpacity,
          transform: `scale(${bentoScale})`,
          display: "grid",
          gridTemplateColumns: "1fr 1fr",
          gridTemplateRows: "1fr 1fr",
          gap: 5 * s,
        }}>
          {BENTO_CELLS.map((c, i) => (
            <div key={i} style={{
              background: "#FFFFFF",
              border: "1px solid rgba(0,0,0,0.06)",
              borderRadius: 8 * s,
              padding: 5 * s,
              boxShadow: `0 ${2 * s}px ${6 * s}px rgba(0,0,0,0.05)`,
              display: "flex",
              flexDirection: "column",
              minHeight: 0,
            }}>
              <div style={{
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
                marginBottom: 3 * s,
                fontSize: 9 * s,
                fontWeight: 700,
                fontFamily: FONTS.display,
                color: COLORS.textDark,
              }}>
                <span>{c.label}</span>
                <span style={{ fontFamily: FONTS.mono, fontSize: 7.5 * s, color: COLORS.textMuted, fontWeight: 500 }}>{c.count}</span>
              </div>
              <div style={{ flex: 1, borderRadius: 4 * s, overflow: "hidden", minHeight: 0 }}>
                <Img src={c.src} style={{ width: "100%", height: "100%", objectFit: "cover", display: "block" }} />
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* CTA — single-line, dark "Show me the change →" */}
      <div style={{
        background: COLORS.textDark,
        color: "#FFFFFF",
        padding: `${10 * s}px ${8 * s}px`,
        borderRadius: 14 * s,
        textAlign: "center",
        fontFamily: FONTS.display,
        fontWeight: 600,
        fontSize: 10.5 * s,
        letterSpacing: "-0.005em",
        whiteSpace: "nowrap",
      }}>
        {copy.cta}
      </div>
    </Stage>
  );
};
