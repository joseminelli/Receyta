import { useEffect, useState } from "react";
import { continueRender, delayRender, staticFile } from "remotion";

export const useFont = () => {
  const [handle] = useState(() => delayRender("fonte"));
  useEffect(() => {
    const face = new FontFace("Bricolage", `url(${staticFile("fonts/BricolageGrotesque-Variable.ttf")})`, { weight: "200 800" });
    face.load().then((loaded) => {
      document.fonts.add(loaded);
      continueRender(handle);
    });
  }, [handle]);
};
