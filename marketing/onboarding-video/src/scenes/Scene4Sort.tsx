import { interpolate, useCurrentFrame } from "remotion";
import { COLORS, FONTS, type SceneCopy } from "../tokens";
import { Stage, usePhoneScale } from "../Phone";

interface Props { copy: SceneCopy; }

const SORT_PILLARS = [
  { emoji: "🚗", name: "Cars",   targetCount: 47, gradient: `linear-gradient(90deg, ${COLORS.brandBlue}, #5856D6)`, color: COLORS.brandBlue },
  { emoji: "☕", name: "Food",   targetCount: 32, gradient: `linear-gradient(90deg, #FF9500, #FF3B30)`,             color: "#FF9500" },
  { emoji: "🌍", name: "Travel", targetCount: 89, gradient: `linear-gradient(90deg, ${COLORS.green}, #32ADE6)`,     color: COLORS.green },
];

/**
 * Scene 4 — Live Sort (4s · 120f) · pixel-perfect port of mockup Step 04
 * Progress bars fill, counters tick. Last second pulses CTA.
 */
export const Scene4Sort: React.FC<Props> = ({ copy }) => {
  const frame = useCurrentFrame();
  const s = usePhoneScale();

  const fillProgress = interpolate(frame, [10, 90], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const total = Math.floor(interpolate(frame, [10, 90], [0, 5847], { extrapolateLeft: "clamp", extrapolateRight: "clamp" }));
  const done = frame > 95;

  const ctaPulse = done ? 1 + Math.sin((frame - 95) * 0.4) * 0.04 : 1;
  const ctaShadow = done ? `0 0 0 ${Math.sin((frame - 95) * 0.4) * 8 + 8}px rgba(0,122,255,0.20)` : "none";

  return (
    <Stage
      screenBg="#F0F6FF"
      marketingEyebrow={copy.marketingEyebrow}
      marketingTop={copy.marketingTop}
      marketingTopEm={copy.marketingTopEm}
    >
      {/* Eyebrow chip */}
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

      {/* Headline — "Tagging photos to pillars." (mockup 20px) */}
      <div style={{
        fontFamily: FONTS.display,
        fontWeight: 700,
        fontSize: 20 * s,
        lineHeight: 1.08,
        letterSpacing: "-0.02em",
        marginBottom: 14 * s,
        color: COLORS.textDark,
      }}>
        <span style={{ whiteSpace: "pre-line" }}>{copy.prefix}</span>{" "}
        <span style={{ fontFamily: FONTS.serif, fontStyle: "italic", fontWeight: 400, color: COLORS.brandBlue }}>{copy.em}</span>
        {copy.suffix ?? ""}
      </div>

      {/* Progress bars stack */}
      <div style={{ display: "flex", flexDirection: "column", gap: 9 * s, marginBottom: 14 * s }}>
        {SORT_PILLARS.map(p => {
          const cnt = Math.floor(p.targetCount * fillProgress);
          return (
            <div key={p.name}>
              <div style={{
                display: "flex",
                justifyContent: "space-between",
                alignItems: "baseline",
                marginBottom: 5 * s,
              }}>
                <div style={{
                  fontSize: 11 * s,
                  fontWeight: 600,
                  color: COLORS.textDark,
                  fontFamily: FONTS.display,
                }}>{p.emoji} {p.name}</div>
                <div style={{
                  fontSize: 13 * s,
                  fontWeight: 700,
                  color: p.color,
                  fontFamily: FONTS.display,
                }}>{cnt}</div>
              </div>
              <div style={{
                height: 5 * s,
                background: "rgba(0,0,0,0.06)",
                borderRadius: 100,
                overflow: "hidden",
              }}>
                <div style={{
                  height: "100%",
                  width: `${fillProgress * 100}%`,
                  background: p.gradient,
                  borderRadius: 100,
                }} />
              </div>
            </div>
          );
        })}
      </div>

      {/* Status + total at bottom */}
      <div style={{ flex: 1, display: "flex", flexDirection: "column", justifyContent: "flex-end" }}>
        <div style={{
          textAlign: "center",
          fontFamily: FONTS.mono,
          fontSize: 9.5 * s,
          color: COLORS.textMuted,
          marginBottom: 4 * s,
          letterSpacing: "0.04em",
        }}>
          {done ? "✓ Your gallery is ready." : `Reading photo ${total}…`}
        </div>
        <div style={{
          textAlign: "center",
          fontFamily: FONTS.mono,
          fontSize: 9 * s,
          color: COLORS.textMuted,
          marginBottom: 14 * s,
          letterSpacing: "0.04em",
        }}>
          <strong style={{ color: COLORS.textDark, fontSize: 11 * s, fontWeight: 700 }}>{total.toLocaleString()}</strong> / 5,847 · ~45s
        </div>

        {/* CTA — single-line */}
        <div style={{
          background: done ? COLORS.brandBlue : "rgba(0,0,0,0.06)",
          color: done ? "#FFFFFF" : COLORS.textMuted,
          padding: `${10 * s}px ${8 * s}px`,
          borderRadius: 14 * s,
          textAlign: "center",
          fontFamily: FONTS.display,
          fontWeight: 600,
          fontSize: 10.5 * s,
          transform: `scale(${ctaPulse})`,
          boxShadow: ctaShadow,
          whiteSpace: "nowrap",
        }}>
          {done ? copy.cta : "Building your library…"}
        </div>
      </div>
    </Stage>
  );
};
