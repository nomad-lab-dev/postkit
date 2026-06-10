import { AbsoluteFill, useVideoConfig } from "remotion";
import { COLORS, FONTS } from "./tokens";
import { IPad, IPAD_BASE_H } from "./IPad";

/**
 * Frame-height fraction the phone occupies, depending on layout.
 * - Single marketing headline (Scenes 2–5): phone takes 65%
 * - Split marketing headline (Scene 1):     phone takes 52% to leave room
 *   for the second headline below.
 */
export const phoneHeightFraction = (hasBottomHeadline: boolean) =>
  hasBottomHeadline ? 0.52 : 0.65;

/**
 * Returns the multiplier from mockup-px to actual render px. Pass
 * `hasBottomHeadline: true` from Scene 1 so the in-phone sizes stay
 * proportional to the smaller split-layout phone.
 */
export const usePhoneScale = (hasBottomHeadline = false) => {
  const { height, width } = useVideoConfig();
  const isWide = width / height > 0.6;
  const frac = hasBottomHeadline
    ? (isWide ? 0.72 : 0.52)
    : (isWide ? 0.76 : 0.65);
  return ((height * frac) / 844) * 2;
};

interface PhoneProps {
  children: React.ReactNode;
  /** Scale factor relative to base phone (390×844). Used to fit different aspect ratios. */
  scale?: number;
  /** Screen background — defaults to canvas */
  screenBg?: string;
  /** Status bar tint — light text for dark/gradient bgs */
  statusBarDark?: boolean;
}

/**
 * iPhone mockup container — base size 390×844 (logical points).
 * Body padding tuned to match the static HTML mockup: 18 top / 14 sides / 14 bottom.
 */
export const Phone: React.FC<PhoneProps> = ({
  children,
  scale = 1,
  screenBg = "#F0F6FF",
  statusBarDark = false,
}) => {
  const W = 390 * scale;
  const H = 844 * scale;
  const radius = 60 * scale;
  const padding = 10 * scale;
  const innerRadius = radius - padding;
  const statusColor = statusBarDark ? "#FFFFFF" : COLORS.textDark;

  return (
    <div
      style={{
        position: "relative",
        width: W,
        height: H,
        borderRadius: radius,
        background: "#0A0A0A",
        padding,
        boxShadow: `0 ${40 * scale}px ${120 * scale}px rgba(0,0,0,0.55), 0 0 0 ${4 * scale}px rgba(255,255,255,0.06)`,
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
        {/* Notch */}
        <div
          style={{
            position: "absolute",
            top: 14 * scale,
            left: "50%",
            transform: "translateX(-50%)",
            width: 130 * scale,
            height: 36 * scale,
            background: "#0A0A0A",
            borderRadius: 22 * scale,
            zIndex: 10,
          }}
        />
        {/* Status bar */}
        <div
          style={{
            position: "relative",
            height: 60 * scale,
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            padding: `0 ${36 * scale}px`,
            fontSize: 18 * scale,
            fontWeight: 600,
            color: statusColor,
            fontFamily: "system-ui, sans-serif",
            zIndex: 5,
          }}
        >
          <span>9:41</span>
          <span style={{ letterSpacing: 2 }}>● ●●●</span>
        </div>
        {/* Body — padding tuned so children look proportionally identical
            to the static mockup at scale (mockup uses 18/14 on a ~195px-wide
            phone display ≈ 9%/7% ratios → 36/28 on our 390-wide logical phone). */}
        <div
          style={{
            position: "absolute",
            top: 60 * scale,
            left: 0,
            right: 0,
            bottom: 0,
            padding: `${36 * scale}px ${28 * scale}px ${28 * scale}px`,
            display: "flex",
            flexDirection: "column",
          }}
        >
          {children}
        </div>
      </div>
    </div>
  );
};

/**
 * Stage — wraps the phone with external marketing headlines (top + optional bottom).
 *
 * Layout:
 *  - Top zone: marketing eyebrow chip + headline (Space Grotesk Bold + Instrument
 *    Serif italic em). Always white on the brand gradient.
 *  - Phone: centered (if split-headline) or anchored to bottom (if single headline).
 *    Sized to leave headline zones breathing room.
 *  - Bottom zone (Scene 1 only): second marketing headline mirroring the top.
 *
 * In-phone content (eyebrow chip + headline + scene UI + CTA) is rendered by each
 * scene component inside `children`.
 */
interface StageProps {
  children: React.ReactNode;
  /** External marketing eyebrow (e.g., "STEP 01 · UNCOVER") */
  marketingEyebrow?: string;
  /** External marketing top headline prefix */
  marketingTop?: string;
  /** External marketing top headline italic em */
  marketingTopEm?: string;
  /** Optional bottom marketing headline (Scene 1 split layout) */
  marketingBottom?: string;
  marketingBottomEm?: string;
  /** Phone screen background (defaults to canvas #F0F6FF) */
  screenBg?: string;
  /** Light status bar (use on gradient/dark screens) */
  statusBarDark?: boolean;
  /** Override phone height in pixels */
  phoneHeight?: number;
}

export const Stage: React.FC<StageProps> = ({
  children,
  marketingEyebrow,
  marketingTop,
  marketingTopEm,
  marketingBottom,
  marketingBottomEm,
  screenBg,
  statusBarDark,
  phoneHeight: phoneHeightProp,
}) => {
  const { height: frameH, width: frameW } = useVideoConfig();
  const hasBottomHeadline = !!(marketingBottom && marketingBottomEm);

  // On wide canvases (iPad, aspect > 0.6) scale the phone to fill ~58% of the width
  // so it doesn't float as a tiny element in the center. On narrow iPhone canvases
  // keep the original height-fraction logic unchanged.
  const isWide = frameW / frameH > 0.6;
  const heightFrac = hasBottomHeadline
    ? (isWide ? 0.72 : 0.52)
    : (isWide ? 0.76 : 0.65);

  const phoneHeight =
    phoneHeightProp ?? frameH * heightFrac;
  const scale = phoneHeight / 844;

  const topPos = frameH * (isWide ? 0.05 : 0.06);
  const bottomPos = frameH * (isWide ? 0.04 : 0.06);
  const phonePadBottom = frameH * 0.05;
  const headlineFs = frameH * 0.044;
  const eyebrowFs = frameH * 0.013;
  const eyebrowMb = frameH * 0.008;

  return (
    <AbsoluteFill style={{ fontFamily: FONTS.display }}>

      {/* Top marketing headline */}
      {marketingTop && marketingTopEm && (
        <div
          style={{
            position: "absolute",
            top: topPos,
            left: 0,
            right: 0,
            textAlign: "center",
            color: "#FFFFFF",
            zIndex: 20,
            padding: `0 ${frameH * 0.04}px`,
          }}
        >
          {marketingEyebrow && (
            <div
              style={{
                fontFamily: FONTS.mono,
                fontSize: eyebrowFs,
                fontWeight: 600,
                letterSpacing: "0.2em",
                opacity: 0.7,
                marginBottom: eyebrowMb,
              }}
            >
              {marketingEyebrow}
            </div>
          )}
          <div
            style={{
              fontSize: headlineFs,
              fontWeight: 700,
              letterSpacing: "-0.02em",
              lineHeight: 1.05,
            }}
          >
            {marketingTop}{" "}
            <span style={{ fontFamily: FONTS.serif, fontStyle: "italic", color: "#FFD68A", fontWeight: 400 }}>
              {marketingTopEm}
            </span>
          </div>
        </div>
      )}

      {/* Phone — centered for split, bottom-anchored for single headline */}
      <AbsoluteFill
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: hasBottomHeadline ? "center" : "flex-end",
          paddingBottom: hasBottomHeadline ? 0 : phonePadBottom,
        }}
      >
        {isWide ? (
          <IPad scale={phoneHeight / IPAD_BASE_H} screenBg={screenBg} statusBarDark={statusBarDark}>
            {children}
          </IPad>
        ) : (
          <Phone scale={scale} screenBg={screenBg} statusBarDark={statusBarDark}>
            {children}
          </Phone>
        )}
      </AbsoluteFill>

      {/* Bottom marketing headline (Scene 1 split layout) */}
      {hasBottomHeadline && (
        <div
          style={{
            position: "absolute",
            bottom: bottomPos,
            left: 0,
            right: 0,
            textAlign: "center",
            color: "#FFFFFF",
            zIndex: 20,
            fontSize: headlineFs,
            fontWeight: 700,
            letterSpacing: "-0.02em",
            lineHeight: 1.05,
            padding: `0 ${frameH * 0.04}px`,
          }}
        >
          {marketingBottom}{" "}
          <span style={{ fontFamily: FONTS.serif, fontStyle: "italic", color: "#FFD68A", fontWeight: 400 }}>
            {marketingBottomEm}
          </span>
        </div>
      )}
    </AbsoluteFill>
  );
};
