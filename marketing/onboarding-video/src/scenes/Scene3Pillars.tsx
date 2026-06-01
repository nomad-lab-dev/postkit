import { interpolate, spring, useCurrentFrame, useVideoConfig } from "remotion";
import { COLORS, FONTS, type SceneCopy } from "../tokens";
import { Stage, usePhoneScale } from "../Phone";

interface Props { copy: SceneCopy; }

const PILLARS = [
  { emoji: "🚗", name: "Cars",            bg: "rgba(0,122,255,.07)",  border: "rgba(0,122,255,.18)",  color: COLORS.brandBlue },
  { emoji: "☕", name: "Food & Coffee",   bg: "rgba(255,149,0,.08)",  border: "rgba(255,149,0,.20)",  color: "#FF9500" },
  { emoji: "💼", name: "Build in public", bg: "rgba(175,82,222,.07)", border: "rgba(175,82,222,.20)", color: COLORS.brandPurple },
  { emoji: "🌍", name: "Travel",          bg: "rgba(52,199,89,.07)",  border: "rgba(52,199,89,.20)",  color: COLORS.green },
];

/**
 * Scene 3 — Pillars (4s · 120f) · pixel-perfect port of mockup Step 03
 * Each pillar slides in with stagger 14f.
 */
export const Scene3Pillars: React.FC<Props> = ({ copy }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = usePhoneScale();

  const pillarReveal = (i: number) => spring({
    frame: frame - (8 + i * 14),
    fps,
    config: { damping: 16, stiffness: 200 },
  });

  return (
    <Stage
      screenBg="#F0F6FF"
      marketingEyebrow={copy.marketingEyebrow}
      marketingTop={copy.marketingTop}
      marketingTopEm={copy.marketingTopEm}
    >
      {/* Eyebrow chip — dark on canvas (mockup "Your turn") */}
      <div style={{
        display: "inline-flex",
        padding: `${3 * s}px ${10 * s}px`,
        borderRadius: 100,
        background: "rgba(0,0,0,0.06)",
        color: COLORS.textDark,
        fontSize: 9 * s,
        fontWeight: 600,
        fontFamily: FONTS.mono,
        letterSpacing: "0.06em",
        textTransform: "uppercase",
        marginBottom: 8 * s,
        alignSelf: "flex-start",
      }}>
        {copy.eyebrow}
      </div>

      {/* Headline — "What do you post about?" (mockup 20px) */}
      <div style={{
        fontFamily: FONTS.display,
        fontWeight: 700,
        fontSize: 20 * s,
        lineHeight: 1.08,
        letterSpacing: "-0.02em",
        marginBottom: 4 * s,
        color: COLORS.textDark,
      }}>
        {copy.prefix}{" "}
        <span style={{ fontFamily: FONTS.serif, fontStyle: "italic", fontWeight: 400, color: COLORS.brandBlue }}>{copy.em}</span>
        {copy.suffix ?? ""}
      </div>
      <div style={{ fontSize: 10.5 * s, color: COLORS.textMuted, marginBottom: 10 * s }}>
        Pick or write 2–4. Edit anytime.
      </div>

      {/* Pillars list */}
      <div style={{ display: "flex", flexDirection: "column", gap: 5 * s, flex: 1 }}>
        {PILLARS.map((p, i) => {
          const r = pillarReveal(i);
          return (
            <div key={p.name} style={{
              display: "flex",
              alignItems: "center",
              gap: 8 * s,
              padding: `${8 * s}px ${12 * s}px`,
              background: p.bg,
              border: `1px solid ${p.border}`,
              borderRadius: 100,
              fontSize: 11 * s,
              fontWeight: 600,
              color: p.color,
              fontFamily: FONTS.display,
              opacity: r,
              transform: `translateY(${interpolate(r, [0, 1], [-6, 0])}px)`,
            }}>
              <span style={{ fontSize: 13 * s }}>{p.emoji}</span>
              <span style={{ flex: 1 }}>{p.name}</span>
              <span style={{
                width: 16 * s,
                height: 16 * s,
                borderRadius: 100,
                background: "rgba(0,0,0,0.06)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                fontSize: 11 * s,
                color: "rgba(0,0,0,0.45)",
              }}>×</span>
            </div>
          );
        })}

        {/* + Add your own */}
        {frame > 70 && (
          <div style={{
            display: "flex",
            alignItems: "center",
            gap: 7 * s,
            padding: `${8 * s}px ${12 * s}px`,
            background: "rgba(0,0,0,0.03)",
            border: "1px dashed rgba(0,0,0,0.18)",
            borderRadius: 100,
            fontSize: 11 * s,
            color: COLORS.textMuted,
            fontFamily: FONTS.display,
            fontWeight: 500,
            opacity: interpolate(frame, [70, 85], [0, 1], { extrapolateRight: "clamp" }),
          }}>
            <span style={{ flex: 1 }}>+ Add your own</span>
            <div style={{
              width: 18 * s,
              height: 18 * s,
              borderRadius: 100,
              background: COLORS.brandBlue,
              color: "#FFF",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              fontSize: 12 * s,
              fontWeight: 700,
            }}>+</div>
          </div>
        )}
      </div>

      {/* CTA — single-line */}
      <div style={{
        marginTop: 12 * s,
        background: COLORS.brandBlue,
        color: "#FFFFFF",
        padding: `${10 * s}px ${8 * s}px`,
        borderRadius: 14 * s,
        textAlign: "center",
        fontFamily: FONTS.display,
        fontWeight: 600,
        fontSize: 10.5 * s,
        whiteSpace: "nowrap",
      }}>
        {copy.cta}
      </div>
    </Stage>
  );
};
