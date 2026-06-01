import { AbsoluteFill } from "remotion";
import { COLORS } from "../tokens";

/**
 * 1-second pause between scenes — pure gradient + subtle PostKit logo dot.
 * Gives the eye a beat between transitions.
 */
export const PauseScene: React.FC = () => {
  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(155deg, ${COLORS.brandBlue} 0%, ${COLORS.brandPurple} 60%, ${COLORS.brandPink} 100%)`,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      <AbsoluteFill
        style={{
          background: `radial-gradient(ellipse at 50% 50%, rgba(255,255,255,0.10) 0%, transparent 60%)`,
        }}
      />
      <div style={{ position: "relative", width: 80, height: 80, borderRadius: 18, background: "linear-gradient(135deg, #FFFFFF, rgba(255,255,255,0.7))", display: "grid", gridTemplateColumns: "1fr 1fr", gridTemplateRows: "1fr 1fr", gap: 4, padding: 8 }}>
        <div style={{ background: COLORS.brandBlue, borderRadius: 5, opacity: 0.95 }} />
        <div style={{ background: COLORS.brandBlue, borderRadius: 5, opacity: 0.62 }} />
        <div style={{ background: COLORS.brandBlue, borderRadius: 5, opacity: 0.72 }} />
        <div style={{ background: COLORS.brandBlue, borderRadius: 5, opacity: 0.95 }} />
      </div>
    </AbsoluteFill>
  );
};
