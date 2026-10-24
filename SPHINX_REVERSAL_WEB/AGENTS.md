# Codex / OpenCode briefing (read before editing)

This is an updated **Agora reconstruction implementation** for **SPHINX REVERSAL**, a 3D puzzle game for GIANT JAM 2.0, theme REVERSAL, with deadline **October 24, 2026 at 7:00 PM Toronto time**.

## Design is LOCKED
- Egyptian guardian explores a photo-referenced, simplified 3D Lakehead Agora Circle and enterable Agora atrium.
- Press R to switch between modern campus and an ancient Egyptian echo. Both worlds must be mechanically meaningful.
- Exactly three ancient seals: west door (ancient opens), east bridge (ancient rebuilt) plus east gate (modern opens), hidden seal (ancient only).
- Reverse-order shrine: C → B → A, then reveal magical map and rescue Nefertiti in ancient state.
- Visual wow moment: cinematic reverse-world transformation. Optimize visual polish, do not create an open world.
- No enemies/combat/multiplayer/complex physics.
- Preserve existing functioning code; verify with browser after every vertical slice.

## Tech
- Vanilla JS + Three.js. **Current default is a dependency-free local ESM build**: `npm run dev`, `npm run test:geometry`, `npm run build`, `npm run preview`. `npm install` is optional; `npm run build:vite` is a legacy optional alternative. `vendor/three.mjs` supplies the local MIT Three.js runtime.
- `src/world.js`: all geometry, scene dressing, world state and collision rules.
- `src/main.js`: player, camera, controls, progression, interactions, UI events.
- `src/style.css`: interface. `index.html`: UI templates.
- No Godot migration without a concrete, tested reason; avoid Blender/MCP setup unless fast and high-value.

## Your immediate job
1. Run the locally bundled build and perform actual browser testing (no dependency installation required).
2. Fix any runtime/collision/world-state issues; test player can complete A+B+C → shrine CBA → map → rescue.
3. Improve the reversal VFX substantially (coherent animation, shader/particles, camera feedback, meaningful transform).
4. Improve visual fidelity **without** sacrificing performance (e.g., inspired-but-not-real campus landmark, Egyptian ornaments, lighting/atmosphere, character readability).
5. Check existing UI hints, audio, state-reset tests, README instructions, and produce a build in `dist/`.
6. Do NOT claim testing unless performed. Report exact verified capabilities and remaining blockers.

Potential issue to check first: the `main.js` movement update uses world-space WASD in an isometric camera. Evaluate usability and optionally change to camera-relative input.

**Keep BACKFIRE (separate project) untouched.**

## 2026-10-24 Agora-specific precedence

The latest requirements in `docs/REAL_LAKEHEAD_REQUIREMENTS.md` supersede the
fictionalized-campus art direction. Exterior should match
`docs/references/AGORA_CIRCLE_REAL_REFERENCE.png`; interior is a playable
approximation. Keep `src/agora.js` connected to `src/world.js`; do not move
original puzzle A/B/C/queen/shrine coordinates without updating test routes.
The release builds locally via `npm run build` (vendored Three.js ESM, no CDN).
`npm run test:geometry` covers geometry traversal, but real browser rendering and
WASD/mouse still REQUIRE manual browser QA. See `qa/AGORA_QA.md`.
