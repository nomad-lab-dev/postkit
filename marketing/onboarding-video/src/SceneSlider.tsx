import { Easing, interpolate, useCurrentFrame } from "remotion";

interface Props {
  children: React.ReactNode;
  /** Total duration of the parent sequence, in frames */
  durationFrames: number;
  /** Slide duration (in / out), in frames. Match CROSSFADE_FRAMES from tokens. */
  slideFrames?: number;
}

/**
 * Slides scene content horizontally:
 *   - Enters from leading edge (translateX -100% → 0) with ease-out
 *   - Exits to trailing edge (0 → 100%) with ease-in
 *
 * The background gradient stays fixed in the parent — only the scene
 * content (headline + phone) moves. When two scenes overlap (because
 * their sequences overlap by `slideFrames`), you see one card leaving
 * to the right while the next card arrives from the left → conveyor.
 */
export const SceneSlider: React.FC<Props> = ({
  children,
  durationFrames,
  slideFrames = 16,
}) => {
  const frame = useCurrentFrame();

  // Enter: -100% → 0% (ease-out)
  const enterX = interpolate(frame, [0, slideFrames], [-100, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.out(Easing.cubic),
  });

  // Exit: 0% → 100% (ease-in)
  const exitX = interpolate(
    frame,
    [durationFrames - slideFrames, durationFrames],
    [0, 100],
    {
      extrapolateLeft: "clamp",
      extrapolateRight: "clamp",
      easing: Easing.in(Easing.cubic),
    }
  );

  // Sum works because during the middle phase both are clamped to 0.
  const x = enterX + exitX;

  return (
    <div
      style={{
        width: "100%",
        height: "100%",
        transform: `translateX(${x}%)`,
        willChange: "transform",
      }}
    >
      {children}
    </div>
  );
};
