import { useVideoConfig } from "remotion";

export const useLayout = () => {
  const { width, height } = useVideoConfig();
  const vertical = height > width;
  const u = vertical ? width / 1080 : height / 1080;
  return { width, height, vertical, u };
};
