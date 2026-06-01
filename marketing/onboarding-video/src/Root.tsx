import { Composition } from "remotion";
import { FPS, HEADLINES_EN, HEADLINES_FR, HEADLINES_ES, TOTAL_SEC } from "./tokens";
import { OnboardingShowcase } from "./OnboardingShowcase";

/** iPhone 6.5" — App Store screenshot spec */
const APPSTORE_W = 1242;
const APPSTORE_H = 2688;

export const Root: React.FC = () => {
  return (
    <>
      {/* 9:16 vertical — for App Store preview / IG Stories / TikTok / landing */}
      <Composition
        id="OnboardingShowcase"
        component={OnboardingShowcase}
        durationInFrames={Math.round(TOTAL_SEC * FPS)}
        fps={FPS}
        width={1080}
        height={1920}
        defaultProps={{ headlines: HEADLINES_EN }}
      />

      {/* 1:1 square */}
      <Composition
        id="OnboardingShowcaseSquare"
        component={OnboardingShowcase}
        durationInFrames={Math.round(TOTAL_SEC * FPS)}
        fps={FPS}
        width={1080}
        height={1080}
        defaultProps={{ headlines: HEADLINES_EN }}
      />

      {/* 16:9 landscape */}
      <Composition
        id="OnboardingShowcaseLandscape"
        component={OnboardingShowcase}
        durationInFrames={Math.round(TOTAL_SEC * FPS)}
        fps={FPS}
        width={1920}
        height={1080}
        defaultProps={{ headlines: HEADLINES_EN }}
      />

      {/* ─── APP STORE iPhone 6.5" — per locale ─── */}
      <Composition
        id="AppStore65EN"
        component={OnboardingShowcase}
        durationInFrames={Math.round(TOTAL_SEC * FPS)}
        fps={FPS}
        width={APPSTORE_W}
        height={APPSTORE_H}
        defaultProps={{ headlines: HEADLINES_EN }}
      />
      <Composition
        id="AppStore65FR"
        component={OnboardingShowcase}
        durationInFrames={Math.round(TOTAL_SEC * FPS)}
        fps={FPS}
        width={APPSTORE_W}
        height={APPSTORE_H}
        defaultProps={{ headlines: HEADLINES_FR }}
      />
      <Composition
        id="AppStore65ES"
        component={OnboardingShowcase}
        durationInFrames={Math.round(TOTAL_SEC * FPS)}
        fps={FPS}
        width={APPSTORE_W}
        height={APPSTORE_H}
        defaultProps={{ headlines: HEADLINES_ES }}
      />
    </>
  );
};
