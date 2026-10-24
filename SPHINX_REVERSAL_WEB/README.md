# SPHINX REVERSAL — Pharaoh edition

**Play:** extract the play ZIP and open `PLAY_PHARAOH.html` in Chrome or Edge. All runtime assets are inside the HTML; no Node, server, account or paid service is required. `PLAY_GAME.bat` opens the same file on Windows. Native Windows file launching is not yet verified on this Linux runner.

WASD/arrows move relative to the camera · Shift run · mouse drag look/double-click lock · wheel zoom · Space jump · R reverse · E interact · M map · ESC pause. ESC → Official Agora 360 opens a clearly labeled, fixed photographic reference; free walking always uses modeled 3D geometry.

Quest: west archive A (ancient opens) → ancient bridge / present gate B → hidden ancient Agora C → shrine C,B,A → ancient map → northern sanctuary → present prison anchor → ancient Nefertiti rescue and victory. Seals can be collected nonlinearly; all three, the shrine/map and the anchor are required for rescue.

The player is an original armored human Pharaoh with animated legs/arms, a blue-and-gold nemes, royal staff and cape. `PHARAOH_PORTRAIT.html` renders the same model in studio lighting; the delivered PNG is an actual rendering. Official Agora photographs supply mapped reflections and the optional observation scene; four original panorama sets are retained. The specific Sketchfab model and missing videos were unavailable and are not represented as imported. See docs/HERO_AND_REFERENCE_SOURCES.md.

Current evidence: `qa/pharaoh/` and QA_REPORT.md. Full normal-input mission **31/31**, geometry **24/24**, camera math **9/9**, final corrected-bundle review **9/9**. The full recording precedes a final panorama orientation/glass calibration fix, which was separately checked. Architecture remains an approximate compact Agora, not a surveyed full campus. Hardware GPU, human/audio usability, native Windows and other browsers remain unverified.

For editing: `npm run dev` serves source; `npm run build` regenerates dependency-free ESM dist; `npm run preview` serves dist. Optional npm dependencies enable `build:standalone` and `build:portrait`. Node geometry and camera checks use `test:geometry` and `test:camera`; browser QA requires Playwright/Chromium. No paid generation service is used.
