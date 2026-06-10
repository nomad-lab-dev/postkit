import { useCurrentFrame } from "remotion";
import { COLORS, FONTS, type SceneCopy } from "../tokens";
import { Stage, usePhoneScale } from "../Phone";

interface Props { copy: SceneCopy; }

const PROMPTS = [
  { label: "🌍 Italy roadtrip",              text: "my Italy roadtrip" },
  { label: "☕ Coffee shops I love",         text: "my coffee shops" },
  { label: "🚗 Porsche meetup last weekend", text: "my Porsche meetup" },
];

/**
 * Scene 5 — Your Turn (4s · 120f) · pixel-perfect port of mockup Step 05
 * Active pill cycles through 3 prompts. Prompt text swaps in the input.
 */
export const Scene5Turn: React.FC<Props> = ({ copy }) => {
  const frame = useCurrentFrame();
  const s = usePhoneScale();

  let activeIdx = 0;
  if (frame >= 35 && frame < 70) activeIdx = 1;
  else if (frame >= 70) activeIdx = 2;

  const active = PROMPTS[activeIdx];
  const showCaret = Math.floor(frame / 6) % 2 === 0;

  return (
    <Stage
      screenBg="#F0F6FF"
      marketingEyebrow={copy.marketingEyebrow}
      marketingTop={copy.marketingTop}
      marketingTopEm={copy.marketingTopEm}
    >
      {/* Eyebrow chip — dark */}
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

      {/* Headline — "Now your first prompt." (mockup 20px) */}
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
        <span style={{ fontFamily: FONTS.serif, fontStyle: "italic", fontWeight: 400, color: COLORS.brandBlue }}>{copy.em}</span>
        {copy.suffix ?? ""}
      </div>

      {/* TYPE OR PICK card */}
      <div style={{
        background: "#FFFFFF",
        borderRadius: 14 * s,
        padding: `${12 * s}px ${14 * s}px`,
        boxShadow: `0 ${6 * s}px ${18 * s}px rgba(0,0,0,0.10)`,
        marginBottom: 12 * s,
      }}>
        <div style={{
          fontFamily: FONTS.mono,
          fontSize: 8 * s,
          color: COLORS.textMuted,
          letterSpacing: "0.16em",
          textTransform: "uppercase",
          fontWeight: 600,
          marginBottom: 6 * s,
        }}>
          Type or pick
        </div>
        <div style={{
          fontSize: 14 * s,
          fontWeight: 500,
          lineHeight: 1.4,
          color: COLORS.textDark,
          fontFamily: FONTS.display,
        }}>
          A post about <span>{active.text}</span>
          <span style={{
            display: "inline-block",
            width: 2 * s,
            height: 14 * s,
            background: COLORS.brandBlue,
            verticalAlign: "middle",
            marginLeft: 1 * s,
            opacity: showCaret ? 1 : 0,
          }} />
        </div>
      </div>

      {/* Pick pills */}
      <div style={{ display: "flex", flexDirection: "column", gap: 6 * s, flex: 1 }}>
        {PROMPTS.map((p, i) => {
          const isActive = i === activeIdx;
          return (
            <div key={p.label} style={{
              padding: `${8 * s}px ${12 * s}px`,
              borderRadius: 100,
              background: isActive ? "rgba(0,122,255,0.10)" : "rgba(0,0,0,0.04)",
              color: isActive ? COLORS.brandBlue : COLORS.textDark,
              fontSize: 10.5 * s,
              fontWeight: 600,
              fontFamily: FONTS.display,
              transition: "all 0.3s",
            }}>
              {p.label}
            </div>
          );
        })}
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
