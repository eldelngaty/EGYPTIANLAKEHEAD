# Updated uploaded Sphinx game

**Play:** open `PLAY_SPHINX.html` in Chrome or Edge. It contains the entire game. No Node, installation, account, asset download or local server is needed for this entry file. `PLAY_GAME.bat` opens the same file on Windows.

WASD move · Shift run · mouse drag look (double-click to lock pointer) · wheel zoom · R reverse · E interact · M map · ESC pause. Follow the golden marker. Three seals → shrine C,B,A → ancient map → present-day prison anchor → ancient Nefertiti rescue.

This is the supplied Three.js project, preserved and developed in place. Original animated four-legged Sphinx, detailed Nefertiti, camera zoom/wall avoidance, clearer mission guidance, smaller HUD, improved procedural glazing and safe static mesh batching. Existing Agora architecture, enterable atrium, puzzle coordinates, reversal wave and complete mission remain.

`npm run build` regenerates the local ESM `dist/` without dependencies. `npm run dev` serves source; `npm run preview` serves dist. Optional `npm install` enables `npm run build:standalone` through esbuild. No npm dependencies are needed to play the generated HTML.

Current actual browser evidence and test results: `qa/current/`. Architectural reference supplied with the upload: `docs/references/AGORA_CIRCLE_REAL_REFERENCE.png`. Campus geometry is a stylized reference-based model; interior and Egyptian puzzle areas are fictional. No campus photograph is used to simulate walkable geometry.

Validation: actual Chromium WebGL, mouse/wheel/WASD/Shift/R/E/CBA/M/ESC and restart; QA adapter only observes. Self-contained HTML additionally tested with networking disabled. Direct `file://` navigation was blocked by the test runner's administrator policy, so direct native Windows file launch and human/audio usability remain untested. Chrome/Edge desktop recommended; mobile controls are not implemented.

---

## Original project notes

# SPHINX REVERSAL — The Curse of Lakehead

A compact third-person 3D puzzle adventure for **GIANT JAM 2.0** (Lakehead University, October 24, 2026). Theme: **REVERSAL**.

An Egyptian guardian awakens on Lakehead University's **Agora Circle**. A pharaoh's curse has split the campus into two realities: the modern campus and its ancient Egyptian echo. Reverse reality to open what the present seals, restore three seals, and free Nefertiti. Every path you restore closes another.

## Play (no npm install needed)

1. Extract the whole folder (don't run it from inside a ZIP preview).
2. With Node.js 20.19+ installed, double-click **PLAY_GAME.bat**. It builds `dist/`, starts a local server and opens the browser at **http://127.0.0.1:4173/** (or the next free port).
3. Keep the terminal open while playing.

Manual equivalent: `npm run build` then `npm run preview`. Without Node: `python -m http.server 4173 --directory dist`. Don't double-click `dist/index.html`, because ES modules require HTTP.

Use Chrome, Edge or Firefox with hardware acceleration. Everything is offline: Three.js r180 is vendored in `vendor/`, and all textures, glyphs and music are generated procedurally.

## Controls

| Key | Action |
|---|---|
| WASD / arrows | Move (camera-relative) |
| Mouse drag | Orbit the camera (double-click for pointer lock, Esc releases) |
| Shift | Run |
| Space | Jump (also skips the intro) |
| **Q** (or R) | **Reverse reality**: modern ⇄ ancient echo |
| E | Interact / collect |
| A, B, C | Offer seals at the shrine |
| M | Map |
| Esc | Pause / controls |
| V | Mute |

## How to play (spoilers, start to victory, about 5–8 minutes)

1. **Intro.** The camera flies over Agora Circle and previews one reversal. Press Space to skip.
2. **Seal A, Western Archive (west).** The archive door is sealed in the present. Press **Q**: the door sinks in the echo. Walk in and press E.
3. **Seal B, Bridge of Opposites (east).** The bridge is broken in the present. Reverse to rebuild it and cross to the round landing. The far gate is shut in the echo, so reverse again on the landing: the gate opens (and the bridge vanishes behind you). Collect B.
4. **Seal C, The Unseen (inside the Agora).** Walk through the sliding glass doors into the atrium. Seal C exists only in the echo.
5. **Shrine of Return (south).** The inscription reads A → B → C. Offer them **reversed: C, B, A**.
6. **The map.** It's blank in the present. Read it in the echo.
7. **The Queen Between Worlds (north, through the back of the atrium).** The sanctuary gate opens only in the echo. Sever the anchor in the **present**, then reverse and free Nefertiti in the **echo**.
8. **Finale.** The curse breaks and a final wave restores the campus. Your time, reversal count and rank are shown. BEGIN AGAIN resets everything.

Reversal is refused if it would trap you, for example standing in a doorway, on the bridge, or inside the ancient Sphinx. The game tells you to step clear.

## What makes the reversal special

- A **wavefront** leaves the Pharaoh and sweeps outward (custom shader patch on every major surface). Pavers bake to sandstone with glowing ritual rings, the Agora facade turns to temple stone, and the glass ribbon ignites with a gold hieroglyph frieze. The "Lakehead" plaque becomes a royal cartouche.
- Columns, obelisks and a **giant Sphinx** erupt from the ground exactly when the wave reaches them.
- The sky turns to a dusk with the Eye of Ra and stars, with a fresnel shockwave dome, FOV punch, camera shake, a screen flash and synthesized audio.
- **Gameplay differs per world:** west door, bridge, east gate, sanctuary barrier, hidden seal, map legibility, the anchor, and the Sphinx's collision all depend on the current reality.

## Architecture

| File | Responsibility |
|---|---|
| `src/main.js` | Player, camera, intro cinematic, input, progression, HUD, finale |
| `src/world.js` | Puzzle world, ancient monuments, Sphinx, collision rules, world state |
| `src/agora.js` | Reference-based Agora Circle facade, plaza, sliding doors, atrium, surroundings |
| `src/reality.js` | Reversal wavefront shader patch, sky dome, shockwave, procedural hieroglyphs |
| `src/dressing.js` | Egyptian ornaments, braziers, particles, floor wave, sanctuary |
| `src/audio.js` | Procedural Web Audio music and effects |
| `qa/agora-geometry.mjs` | Headless collision/traversal test (`npm run test:geometry`) |
| `qa/playthrough.cjs` | Real-browser full playthrough (Playwright) |

```
npm run dev            # serve source at :4173
npm run test:geometry  # headless collision tests
npm run build          # offline dist/
npm run preview        # serve dist/
QA_PORT=4173 node qa/playthrough.cjs   # needs playwright or playwright-core (PLAYWRIGHT_MODULE=path)
```

## Honesty about the Lakehead reconstruction

The exterior is an original low-poly model built from the supplied photo of Agora Circle (`docs/references/AGORA_CIRCLE_REAL_REFERENCE.png`) and the official virtual tour (a 360° panorama, not a 3D model). It includes the sky-reflecting upper glass ribbon with dark mullions, the segmented precast parapet, the ribbed tan fascia with a "Lakehead" plaque right of centre, the recessed dark storefront and glass entrance, the brick wing with columnar poplars, green benches on a lawn strip, a slatted timber planter and running-bond pavers. Proportions are estimated by eye. **The atrium interior is a playable approximation**, not a surveyed floor plan. No university logo, photos or third-party assets are included.

See `QA_REPORT.md` for exactly what was tested.
