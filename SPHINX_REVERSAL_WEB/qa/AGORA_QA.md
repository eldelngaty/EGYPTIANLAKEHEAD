# Agora reconstruction QA — NEW revision

**Source inspected:** `AGENTS.md`, original release source, original PDF concept, `docs/references/AGORA_CIRCLE_REAL_REFERENCE.png`, and official 360° virtual-tour page. The tour is panorama photography, **not** a 3D mesh.

**Build:** `npm run build` passed using a self-contained, offline Three.js ESM build. No iframe, network texture, or live university connection is used.

**Automated collision route:** `npm run test:geometry` passed 24 assertions, including actual `world.blocked` coordinate movement: spawn outside → approach and open glass entrance → cross entrance → explore lobby left/right → reverse to plaza. Also checked wall collisions, rear lobby opening, door closing, west/east barriers and original A/B/C seal coordinates.

**Update (Oct 24, ~16:00):** real-browser QA now runs on the team laptop with Playwright's cached Chromium (`qa/browser.cjs` auto-detects it; set `PLAYWRIGHT_MODULE` to a `playwright-core` path if `playwright` isn't installed, and `QA_PORT` for the server port). See `QA_REPORT.md` for current results. A human should still play once with a real mouse/keyboard.

## Required manual acceptance (on your Windows gaming/development PC)

1. `node serve.mjs` after `npm run build`; open `http://127.0.0.1:4173/?qa` in Chrome or Edge.
2. Begin rescue. The Pharaoh spawns in a broad tiled courtyard facing the real-reference-inspired beige facade with Lakehead sign and upper blue window ribbon.
3. Hold W. The transparent sliding glass entrance should automatically slide apart as you approach.
4. Continue W and verify the camera follows the character into the tiled Agora atrium. Move left/right without crossing the side walls.
5. Drag the mouse to rotate the camera. W should now use the rotated direction. Double-click the view to use pointer-lock rotation if desired (Escape releases).
6. Face back toward the doors. Use S or rotate 180° and W to return outdoors. This **must** be continuous, not a scene cut/teleport.
7. Press Q (or R). Confirm Egyptian echo appears and original western/eastern world-dependent gates still work.
8. Run `node qa/agora-browser.cjs` if Playwright and its Chromium browser are installed. Complete the full A→B→C rescue once before submission, as the newer building introduces additional navigation constraints.

The atrium is a simplified playable approximation because a verified Agora interior floor plan and photogrammetry were not supplied. Its exact arrangement should not be presented as surveyed architecture.
