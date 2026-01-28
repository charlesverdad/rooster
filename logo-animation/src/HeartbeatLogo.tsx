import React from "react";
import {
  AbsoluteFill,
  useCurrentFrame,
  interpolate,
  Easing,
  spring,
  useVideoConfig,
} from "remotion";

// Cubic bezier easing for smooth motion
const easeOutBack = (t: number): number => {
  const c1 = 1.70158;
  const c3 = c1 + 1;
  return 1 + c3 * Math.pow(t - 1, 3) + c1 * Math.pow(t - 1, 2);
};

/**
 * Isometric block that renders a flat 3D-looking shape with top and right faces.
 */
const IsometricBlock: React.FC<{
  x: number;
  y: number;
  width: number;
  height: number;
  depth: number;
  color: string;
  topColor: string;
  rightColor: string;
  animDelay: number;
}> = ({ x, y, width, height, depth, color, topColor, rightColor, animDelay }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const progress = spring({
    frame: frame - animDelay,
    fps,
    config: {
      damping: 14,
      stiffness: 80,
      mass: 0.8,
    },
  });

  // Slide in from above and fade
  const translateY = interpolate(progress, [0, 1], [-120, 0]);
  const opacity = interpolate(progress, [0, 1], [0, 1]);
  const scale = interpolate(progress, [0, 1], [0.7, 1]);

  // Isometric angle offsets
  const isoX = depth * 0.7;
  const isoY = depth * 0.4;

  return (
    <div
      style={{
        position: "absolute",
        left: x,
        top: y,
        opacity,
        transform: `translateY(${translateY}px) scale(${scale})`,
        transformOrigin: "center center",
      }}
    >
      {/* Front face */}
      <div
        style={{
          position: "absolute",
          width,
          height,
          backgroundColor: color,
          left: 0,
          top: isoY,
        }}
      />
      {/* Top face - parallelogram */}
      <svg
        style={{ position: "absolute", left: 0, top: 0 }}
        width={width + isoX}
        height={isoY + 1}
        viewBox={`0 0 ${width + isoX} ${isoY + 1}`}
      >
        <polygon
          points={`${isoX},0 ${width + isoX},0 ${width},${isoY} 0,${isoY}`}
          fill={topColor}
        />
      </svg>
      {/* Right face - parallelogram */}
      <svg
        style={{ position: "absolute", left: width, top: 0 }}
        width={isoX + 1}
        height={height + isoY + 1}
        viewBox={`0 0 ${isoX + 1} ${height + isoY + 1}`}
      >
        <polygon
          points={`${isoX},0 ${isoX},${height} 0,${height + isoY} 0,${isoY}`}
          fill={rightColor}
        />
      </svg>
    </div>
  );
};

/**
 * The "H" letter made of isometric blocks.
 * Composed of: left vertical, right vertical, horizontal crossbar.
 */
const LetterH: React.FC<{ baseX: number; baseY: number; baseDelay: number }> = ({
  baseX,
  baseY,
  baseDelay,
}) => {
  const blockSize = 52;
  const depth = 18;
  const mainColor = "#1a1a1a";
  const topColor = "#444444";
  const rightColor = "#2a2a2a";

  return (
    <>
      {/* Left vertical bar */}
      <IsometricBlock
        x={baseX}
        y={baseY}
        width={blockSize}
        height={blockSize * 3}
        depth={depth}
        color={mainColor}
        topColor={topColor}
        rightColor={rightColor}
        animDelay={baseDelay}
      />
      {/* Right vertical bar */}
      <IsometricBlock
        x={baseX + blockSize * 2}
        y={baseY}
        width={blockSize}
        height={blockSize * 3}
        depth={depth}
        color={mainColor}
        topColor={topColor}
        rightColor={rightColor}
        animDelay={baseDelay + 4}
      />
      {/* Crossbar */}
      <IsometricBlock
        x={baseX + blockSize}
        y={baseY + blockSize}
        width={blockSize}
        height={blockSize}
        depth={depth}
        color={mainColor}
        topColor={topColor}
        rightColor={rightColor}
        animDelay={baseDelay + 8}
      />
    </>
  );
};

/**
 * The "C" (or rounded B-like shape) from the logo.
 * Composed of: left vertical, top horizontal, bottom curve piece.
 */
const LetterC: React.FC<{ baseX: number; baseY: number; baseDelay: number }> = ({
  baseX,
  baseY,
  baseDelay,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const blockSize = 52;
  const depth = 18;
  const mainColor = "#1a1a1a";
  const topColor = "#444444";
  const rightColor = "#2a2a2a";

  const curveProgress = spring({
    frame: frame - (baseDelay + 12),
    fps,
    config: { damping: 14, stiffness: 80, mass: 0.8 },
  });

  const curveTranslateY = interpolate(curveProgress, [0, 1], [-120, 0]);
  const curveOpacity = interpolate(curveProgress, [0, 1], [0, 1]);
  const curveScale = interpolate(curveProgress, [0, 1], [0.7, 1]);

  return (
    <>
      {/* Left vertical bar */}
      <IsometricBlock
        x={baseX}
        y={baseY}
        width={blockSize}
        height={blockSize * 3}
        depth={depth}
        color={mainColor}
        topColor={topColor}
        rightColor={rightColor}
        animDelay={baseDelay}
      />
      {/* Top horizontal bar */}
      <IsometricBlock
        x={baseX + blockSize}
        y={baseY}
        width={blockSize * 2}
        height={blockSize}
        depth={depth}
        color={mainColor}
        topColor={topColor}
        rightColor={rightColor}
        animDelay={baseDelay + 6}
      />
      {/* Bottom curved section - rendered as SVG for the rounded shape */}
      <div
        style={{
          position: "absolute",
          left: baseX + blockSize,
          top: baseY + blockSize * 1.2,
          opacity: curveOpacity,
          transform: `translateY(${curveTranslateY}px) scale(${curveScale})`,
          transformOrigin: "center center",
        }}
      >
        {/* Front face of curved bottom */}
        <svg width={blockSize * 2.2} height={blockSize * 2} viewBox="0 0 115 104">
          <path
            d="M0,0 L80,0 C108,0 115,20 115,45 C115,75 95,104 55,104 L0,104 Z"
            fill={mainColor}
          />
        </svg>
        {/* Isometric top edge for the curve */}
        <svg
          style={{ position: "absolute", left: 0, top: -depth * 0.4 }}
          width={blockSize * 2.2 + depth * 0.7}
          height={depth * 0.4 + 2}
          viewBox={`0 0 ${blockSize * 2.2 + depth * 0.7} ${depth * 0.4 + 2}`}
        >
          <polygon
            points={`${depth * 0.7},0 ${blockSize * 2.2 + depth * 0.7},0 ${blockSize * 2.2},${depth * 0.4} 0,${depth * 0.4}`}
            fill={topColor}
          />
        </svg>
      </div>
    </>
  );
};

/**
 * Animated text "Heartbeat Church" that fades and slides in.
 */
const LogoText: React.FC<{ baseDelay: number }> = ({ baseDelay }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const word1Progress = spring({
    frame: frame - baseDelay,
    fps,
    config: { damping: 16, stiffness: 60, mass: 1 },
  });

  const word2Progress = spring({
    frame: frame - (baseDelay + 8),
    fps,
    config: { damping: 16, stiffness: 60, mass: 1 },
  });

  const word1X = interpolate(word1Progress, [0, 1], [80, 0]);
  const word1Opacity = interpolate(word1Progress, [0, 1], [0, 1]);

  const word2X = interpolate(word2Progress, [0, 1], [80, 0]);
  const word2Opacity = interpolate(word2Progress, [0, 1], [0, 1]);

  return (
    <>
      <div
        style={{
          position: "absolute",
          left: 580,
          top: 370,
          fontFamily: "'Arial Black', 'Helvetica Neue', sans-serif",
          fontWeight: 900,
          fontSize: 88,
          color: "#1a1a1a",
          letterSpacing: "-1px",
          opacity: word1Opacity,
          transform: `translateX(${word1X}px)`,
        }}
      >
        Heartbeat
      </div>
      <div
        style={{
          position: "absolute",
          left: 580,
          top: 468,
          fontFamily: "'Arial Black', 'Helvetica Neue', sans-serif",
          fontWeight: 900,
          fontSize: 88,
          color: "#1a1a1a",
          letterSpacing: "-1px",
          opacity: word2Opacity,
          transform: `translateX(${word2X}px)`,
        }}
      >
        Church
      </div>
    </>
  );
};

/**
 * Subtle ground shadow that appears under the logo blocks.
 */
const GroundShadow: React.FC<{ baseDelay: number }> = ({ baseDelay }) => {
  const frame = useCurrentFrame();

  const opacity = interpolate(frame, [baseDelay, baseDelay + 20], [0, 0.08], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <div
      style={{
        position: "absolute",
        left: 170,
        top: 720,
        width: 340,
        height: 30,
        borderRadius: "50%",
        background: "radial-gradient(ellipse, #000 0%, transparent 70%)",
        opacity,
      }}
    />
  );
};

/**
 * Main composition: Heartbeat Church logo animation.
 * Letters H and C assemble from isometric blocks with spring easing,
 * then the text slides in from the right.
 */
export const HeartbeatLogoAnimation: React.FC = () => {
  const frame = useCurrentFrame();

  // Background subtle gradient animation
  const bgShift = interpolate(frame, [0, 150], [0, 5]);

  return (
    <AbsoluteFill
      style={{
        backgroundColor: `hsl(0, 0%, ${97 + bgShift * 0.2}%)`,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      {/* Ground shadow */}
      <GroundShadow baseDelay={15} />

      {/* Letter H - top left area */}
      <LetterH baseX={200} baseY={310} baseDelay={5} />

      {/* Letter C - bottom left, offset below H */}
      <LetterC baseX={200} baseY={490} baseDelay={15} />

      {/* Text */}
      <LogoText baseDelay={25} />
    </AbsoluteFill>
  );
};
