import { Composition } from "remotion";
import { Banner } from "./Banner";
import { Video } from "./Video";
import { FPS, TOTAL_FRAMES } from "./timeline";

export const Root = () => (
  <>
    <Composition id="Vertical" component={Video} durationInFrames={TOTAL_FRAMES} fps={FPS} width={1080} height={1920} />
    <Composition id="Horizontal" component={Video} durationInFrames={TOTAL_FRAMES} fps={FPS} width={1920} height={1080} />
    <Composition id="BannerVertical" component={Banner} durationInFrames={1} fps={FPS} width={1080} height={1920} />
    <Composition id="BannerHorizontal" component={Banner} durationInFrames={1} fps={FPS} width={1920} height={1080} />
  </>
);
