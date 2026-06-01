import { Img, interpolate, spring, useCurrentFrame, useVideoConfig } from "remotion";
import { COLORS, FONTS, type SceneCopy } from "../tokens";
import { Stage, usePhoneScale } from "../Phone";

interface Props { copy: SceneCopy; }

const PROMPT = "My weekend in Italy";
const CAPTION = "Three days, two cities, one road. Naples → Capri.";
const PHOTOS = [
  "https://images.unsplash.com/photo-1531572753322-ad063cecc140?w=300&h=300&fit=crop&auto=format&q=70",
  "https://images.unsplash.com/photo-1499678329028-101435549a4e?w=300&h=300&fit=crop&auto=format&q=70",
  "https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?w=300&h=300&fit=crop&auto=format&q=70",
  "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=300&h=300&fit=crop&auto=format&q=70",
];

/**
 * Scene 2 — Magic Demo (5.5s · 165f) · pixel-perfect port of mockup Step 02
 *
 * Phone has gradient bg (radial orange + linear blue→purple→pink).
 * Magic card animates: prompt types → loading dots → photo grid reveals
 * (stagger 6f) → caption fades → share button slides up.
 */
export const Scene2Demo: React.FC<Props> = ({ copy }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = usePhoneScale();

  const charsToShow = Math.min(
    Math.floor(interpolate(frame, [0, 45], [0, PROMPT.length], { extrapolateRight: "clamp" })),
    PROMPT.length
  );
  const typed = PROMPT.slice(0, charsToShow);
  const isTyping = frame < 45;

  const loadingOpacity = interpolate(frame, [45, 50, 75, 80], [0, 1, 1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const loadingHeight = interpolate(frame, [45, 50, 75, 80], [0, 36, 36, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });

  const photoReveal = (i: number) => {
    const start = 80 + i * 6;
    return spring({ frame: frame - start, fps, config: { damping: 14, stiffness: 220 } });
  };

  const captionOpacity = interpolate(frame, [105, 120], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const shareReveal = spring({ frame: frame - 120, fps, config: { damping: 18, stiffness: 180 } });

  return (
    <Stage
      screenBg={`radial-gradient(ellipse at 80% 0%, rgba(255,159,0,0.20) 0%, transparent 50%), linear-gradient(160deg, ${COLORS.brandBlue} 0%, #5856D6 50%, ${COLORS.brandPurple} 100%)`}
      statusBarDark
      marketingEyebrow={copy.marketingEyebrow}
      marketingTop={copy.marketingTop}
      marketingTopEm={copy.marketingTopEm}
    >
      {/* Eyebrow chip — glass on gradient (mockup 9px font) */}
      <div style={{
        display: "inline-flex",
        padding: `${3 * s}px ${10 * s}px`,
        borderRadius: 100,
        background: "rgba(255,255,255,0.18)",
        color: "#FFFFFF",
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

      {/* Headline — em + suffix (mockup 19px) */}
      <div style={{
        fontFamily: FONTS.display,
        fontWeight: 700,
        fontSize: 20 * s,
        lineHeight: 1.08,
        letterSpacing: "-0.02em",
        marginBottom: 8 * s,
        color: "#FFFFFF",
        whiteSpace: "pre-line",
      }}>
        {copy.prefix}<span style={{ fontFamily: FONTS.serif, fontStyle: "italic", fontWeight: 400, color: "#FFAE42" }}>{copy.em}</span>{copy.suffix ?? ""}
      </div>

      {/* Magic card */}
      <div style={{
        background: "rgba(255,255,255,0.97)",
        borderRadius: 13 * s,
        padding: 8 * s,
        boxShadow: `0 ${10 * s}px ${28 * s}px rgba(0,0,0,0.22)`,
        color: COLORS.textDark,
        display: "flex",
        flexDirection: "column",
        marginBottom: 6 * s,
      }}>
        {/* Prompt bubble */}
        <div style={{ display: "flex", justifyContent: "flex-end", marginBottom: 6 * s }}>
          <div style={{
            background: COLORS.brandBlue,
            color: "#FFFFFF",
            padding: `${7 * s}px ${11 * s}px ${9 * s}px`,
            borderRadius: 13 * s,
            borderBottomRightRadius: 4 * s,
            fontSize: 10.5 * s,
            fontWeight: 600,
            lineHeight: 1.4,
            maxWidth: "92%",
          }}>
            {typed}{isTyping && Math.floor(frame / 4) % 2 === 0 ? "|" : ""}
          </div>
        </div>

        {/* Loading dots */}
        <div style={{
          display: "flex",
          gap: 4 * s,
          justifyContent: "center",
          alignItems: "center",
          maxHeight: loadingHeight * (s / 2),
          padding: loadingHeight > 0 ? `${5 * s}px 0` : 0,
          opacity: loadingOpacity,
          overflow: "hidden",
        }}>
          {[0, 1, 2].map(i => {
            const bounce = Math.sin((frame + i * 6) * 0.4) * 0.5 + 0.5;
            return (
              <div key={i} style={{
                width: 6 * s, height: 6 * s, borderRadius: 3 * s,
                background: COLORS.brandBlue,
                transform: `scale(${0.6 + bounce * 0.4})`,
                opacity: 0.4 + bounce * 0.6,
              }} />
            );
          })}
        </div>

        {/* Photo grid 2x2 — aspect 1.7/1 (compressed for App Store frame height) */}
        {frame > 75 && (
          <div style={{
            display: "grid",
            gridTemplateColumns: "1fr 1fr",
            gridTemplateRows: "1fr 1fr",
            gap: 2 * s,
            aspectRatio: "1.7/1",
            borderRadius: 6 * s,
            overflow: "hidden",
            background: "#000",
            marginBottom: 4 * s,
          }}>
            {PHOTOS.map((src, i) => {
              const reveal = photoReveal(i);
              return (
                <div key={i} style={{
                  opacity: reveal,
                  transform: `scale(${interpolate(reveal, [0, 1], [1.08, 1])})`,
                  overflow: "hidden",
                }}>
                  <Img src={src} style={{ width: "100%", height: "100%", objectFit: "cover", display: "block" }} />
                </div>
              );
            })}
          </div>
        )}

        {/* Caption */}
        {frame > 105 && (
          <div style={{ opacity: captionOpacity }}>
            <div style={{
              fontFamily: FONTS.mono,
              fontSize: 7.5 * s,
              color: COLORS.green,
              fontWeight: 700,
              letterSpacing: "0.08em",
              textTransform: "uppercase",
              marginBottom: 3 * s,
              display: "flex",
              alignItems: "center",
              gap: 4 * s,
            }}>
              <div style={{ width: 5 * s, height: 5 * s, borderRadius: 100, background: COLORS.green }} />
              Generated · 2.1 s
            </div>
            <div style={{ fontSize: 9.5 * s, lineHeight: 1.45, color: COLORS.textDark }}>{CAPTION}</div>
          </div>
        )}

        {/* Share button INSIDE the card */}
        {frame > 118 && (
          <div style={{
            background: "linear-gradient(45deg, #FEDA75 0%, #FA7E1E 25%, #D62976 50%, #962FBF 75%, #4F5BD5 100%)",
            color: "#FFFFFF",
            padding: `${8 * s}px ${11 * s}px`,
            borderRadius: 10 * s,
            textAlign: "center",
            fontSize: 10.5 * s,
            fontWeight: 700,
            fontFamily: FONTS.display,
            opacity: shareReveal,
            transform: `translateY(${interpolate(shareReveal, [0, 1], [16, 0])}px)`,
            marginTop: 8 * s,
            boxShadow: `0 ${6 * s}px ${14 * s}px rgba(214,41,118,0.28)`,
          }}>
            📷  Share on Instagram
          </div>
        )}
      </div>

      {/* Continue CTA — single-line */}
      <div style={{
        marginTop: "auto",
        background: "#FFFFFF",
        color: COLORS.textDark,
        padding: `${10 * s}px ${8 * s}px`,
        borderRadius: 14 * s,
        textAlign: "center",
        fontFamily: FONTS.display,
        fontWeight: 700,
        fontSize: 10.5 * s,
        boxShadow: `0 ${8 * s}px ${22 * s}px rgba(0,0,0,0.18)`,
        whiteSpace: "nowrap",
      }}>
        {copy.cta}
      </div>
    </Stage>
  );
};
