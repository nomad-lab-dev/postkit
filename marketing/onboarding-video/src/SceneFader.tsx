import { interpolate, useCurrentFrame } from "remotion";

interface Props {
  children: React.ReactNode;
  /** Total duration of the parent sequence, in frames */
  durationFrames: number;
  /** Cross-fade duration (in/out), in frames */
  fadeFrames?: number;
}

/**
 * Wraps a scene so it cross-fades in and out with subtle scale.
 * The fade-in of scene N+1 overlaps with the fade-out of scene N
 * (because the sequences themselves overlap by `CROSSFADE_FRAMES`),
 * which produces a smooth visual hand-off.
 */
export const SceneFader: React.FC<Props> = ({
  children,
  durationFrames,
  fadeFrames = 12,
}) => {
  const frame = useCurrentFrame();

  const enterAlpha = interpolate(frame, [0, fadeFrames], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const exitAlpha = interpolate(
    frame,
    [durationFrames - fadeFrames, durationFrames],
    [1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );
  const alpha = Math.min(enterAlpha, exitAlpha);

  // Subtle scale + Y motion so transitions feel cinematic, not flat
  const scale = interpolate(alpha, [0, 1], [0.985, 1]);
  const lift = interpolate(frame, [0, fadeFrames], [10, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const sink = interpolate(
    frame,
    [durationFrames - fadeFrames, durationFrames],
    [0, -8],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );
  const y = lift + sink;

  return (
    <div
      style={{
        width: "100%",
        height: "100%",
        opacity: alpha,
        transform: `translateY(${y}px) scale(${scale})`,
        transformOrigin: "center",
      }}
    >
      {children}
    </div>
  );
};
