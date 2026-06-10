import { useVideoConfig } from "remotion";
import { COLORS, FONTS } from "./tokens";

/**
 * iPad Pro 13" mockup — base logical size 820×1180 (portrait).
 * Aspect ratio 0.695, close to real iPad Pro 13" (1032×1376 points).
 * - Thin bezel (12px padding)
 * - Camera pill top-center (no notch)
 * - Home indicator bar bottom-center
 */

export const IPAD_BASE_W = 820;
export const IPAD_BASE_H = 1180;

interface IPadProps {
  children: React.ReactNode;
  scale?: number;
  screenBg?: string;
  statusBarDark?: boolean;
}

export const IPad: React.FC<IPadProps> = ({
  children,
  scale = 1,
  screenBg = "#F0F6FF",
  statusBarDark = false,
}) => {
  const W = IPAD_BASE_W * scale;
  const H = IPAD_BASE_H * scale;
  const bezel = 12 * scale;
  const radius = 42 * scale;
  const innerRadius = radius - 4;
  const statusColor = statusBarDark ? "#FFFFFF" : COLORS.textDark;

  return (
    <div
      style={{
        position: "relative",
        width: W,
        height: H,
        borderRadius: radius,
        background: "#0A0A0A",
        padding: bezel,
        boxShadow: [
          `0 ${28 * scale}px ${80 * scale}px rgba(0,0,0,0.55)`,
          `0 0 0 ${2.5 * scale}px rgba(255,255,255,0.07)`,
        ].join(", "),
      }}
    >
      <div
        style={{
          width: "100%",
          height: "100%",
          borderRadius: innerRadius,
          background: screenBg,
          overflow: "hidden",
          position: "relative",
        }}
      >
        {/* Camera pill — top center (Face ID for iPad Pro) */}
        <div
          style={{
            position: "absolute",
            top: 10 * scale,
            left: "50%",
            transform: "translateX(-50%)",
            width: 70 * scale,
            height: 12 * scale,
            background: "#0A0A0A",
            borderRadius: 8 * scale,
            zIndex: 10,
          }}
        />

        {/* Status bar */}
        <div
          style={{
            position: "relative",
            height: 40 * scale,
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            padding: `0 ${26 * scale}px`,
            fontSize: 13 * scale,
            fontWeight: 600,
            color: statusColor,
            fontFamily: "system-ui, sans-serif",
            zIndex: 5,
          }}
        >
          <span>9:41</span>
          <span style={{ letterSpacing: 2 }}>● ●●●</span>
        </div>

        {/* Body */}
        <div
          style={{
            position: "absolute",
            top: 40 * scale,
            left: 0,
            right: 0,
            bottom: 22 * scale,
            padding: `${20 * scale}px ${22 * scale}px ${18 * scale}px`,
            display: "flex",
            flexDirection: "column",
          }}
        >
          {children}
        </div>

        {/* Home indicator bar */}
        <div
          style={{
            position: "absolute",
            bottom: 6 * scale,
            left: "50%",
            transform: "translateX(-50%)",
            width: 120 * scale,
            height: 4 * scale,
            background: statusBarDark
              ? "rgba(255,255,255,0.38)"
              : "rgba(0,0,0,0.22)",
            borderRadius: 4 * scale,
          }}
        />
      </div>
    </div>
  );
};

/**
 * Returns the content scale multiplier for iPad compositions.
 * Same principle as usePhoneScale but based on iPad base dimensions.
 */
export const useIPadScale = (hasBottomHeadline = false) => {
  const { height, width } = useVideoConfig();
  const frac = hasBottomHeadline ? 0.72 : 0.76;
  const iPadH = height * frac;
  // IPAD_BASE_W/IPAD_BASE_H = 820/1180. Content elements were designed for
  // ~410px display width (half of 820). Multiply by iPadH/IPAD_BASE_H to get
  // render-px, then × 2 to compensate the 410→820 logical doubling.
  return (iPadH / IPAD_BASE_H) * 2;
};
