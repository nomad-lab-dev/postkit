import { AbsoluteFill, Sequence } from "remotion";
import { COLORS, FPS, HEADLINES_EN, SCENE_DURATIONS, SCENE_STARTS, type Translation } from "./tokens";
import { Scene1Hook } from "./scenes/Scene1Hook";
import { Scene2Demo } from "./scenes/Scene2Demo";
import { Scene3Pillars } from "./scenes/Scene3Pillars";
import { Scene4Sort } from "./scenes/Scene4Sort";
import { Scene5Turn } from "./scenes/Scene5Turn";
import { SceneSlider } from "./SceneSlider";

interface Props {
  /** Translation for headlines. Default = English. */
  headlines?: Translation;
}

/**
 * Persistent global background — the brand gradient + ambient glow stay fixed
 * across all scenes. Only the scene content (headline + phone) slides
 * horizontally via `SceneSlider`. Conveyor effect emerges from overlapping
 * sequences (CROSSFADE_FRAMES overlap).
 *
 * Translation copy is passed via the `headlines` prop — each composition in
 * Root.tsx wires a specific locale's HEADLINES_xx as `defaultProps.headlines`.
 */
export const OnboardingShowcase: React.FC<Props> = ({ headlines = HEADLINES_EN }) => {
  const frames = {
    hook: SCENE_DURATIONS.scene1Hook * FPS,
    demo: SCENE_DURATIONS.scene2Demo * FPS,
    pillars: SCENE_DURATIONS.scene3Pillars * FPS,
    sort: SCENE_DURATIONS.scene4Sort * FPS,
    turn: SCENE_DURATIONS.scene5Turn * FPS,
  };

  return (
    <AbsoluteFill>
      {/* ─── PERSISTENT BACKGROUND ─── */}
      <AbsoluteFill
        style={{
          background: `linear-gradient(155deg, ${COLORS.brandBlue} 0%, ${COLORS.brandPurple} 60%, ${COLORS.brandPink} 100%)`,
        }}
      />
      <AbsoluteFill
        style={{
          background: `radial-gradient(ellipse at 70% 15%, rgba(255, 159, 0, 0.25) 0%, transparent 55%)`,
          pointerEvents: "none",
        }}
      />

      {/* ─── SLIDING SCENES ─── */}
      <Sequence from={SCENE_STARTS.scene1Hook} durationInFrames={frames.hook}>
        <SceneSlider durationFrames={frames.hook}>
          <Scene1Hook copy={headlines.scene1} />
        </SceneSlider>
      </Sequence>

      <Sequence from={SCENE_STARTS.scene2Demo} durationInFrames={frames.demo}>
        <SceneSlider durationFrames={frames.demo}>
          <Scene2Demo copy={headlines.scene2} />
        </SceneSlider>
      </Sequence>

      <Sequence from={SCENE_STARTS.scene3Pillars} durationInFrames={frames.pillars}>
        <SceneSlider durationFrames={frames.pillars}>
          <Scene3Pillars copy={headlines.scene3} />
        </SceneSlider>
      </Sequence>

      <Sequence from={SCENE_STARTS.scene4Sort} durationInFrames={frames.sort}>
        <SceneSlider durationFrames={frames.sort}>
          <Scene4Sort copy={headlines.scene4} />
        </SceneSlider>
      </Sequence>

      <Sequence from={SCENE_STARTS.scene5Turn} durationInFrames={frames.turn}>
        <SceneSlider durationFrames={frames.turn}>
          <Scene5Turn copy={headlines.scene5} />
        </SceneSlider>
      </Sequence>
    </AbsoluteFill>
  );
};
