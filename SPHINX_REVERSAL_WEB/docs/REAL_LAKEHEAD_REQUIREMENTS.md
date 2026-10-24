# CRITICAL REVISED ART DIRECTION — REAL LAKEHEAD AGORA

GIANT JAM 2.0 / SPHINX REVERSAL — 24 October 2026, working deadline 7:00 PM America/Toronto.

## This document supersedes the inaccurate-campus assumptions in earlier instructions.

The current game's generic imagined campus is NOT approved as the final result. The core brief is a **faithful and recognisable 3D reconstruction of the actual Agora Circle at Lakehead University (Thunder Bay)**, used as the main interactive playable area, with a magical Ancient Egyptian alternate reality occupying the SAME spatial layout. The player must be able to freely move around the reconstructed **3D geometry**, not merely appear as a sprite superimposed on a photo.

### Authoritative visual references

- Lakehead official virtual tour, Agora Circle: https://virtualtour.lakeheadu.ca/lakehead/lakehead-thunder-bay/agora-circle
- `docs/references/AGORA_CIRCLE_REAL_REFERENCE.png` — screenshot of REAL site supplied by the user.
- `docs/references/CURRENT_GAME_BEFORE.png` — screenshot of existing build, illustrating the inaccurate generic campus that must be improved.

Be technically honest: the linked campus tour explicitly describes itself as **360-degree panoramas**. This is photographic panorama content, not evidence of an editable 3D mesh or model export. Do NOT claim the tour can directly be downloaded or imported as a freely walkable mesh. A photo/panorama wrapped around the player is not equivalent to a real collision-enabled 3D reconstruction. Respect asset permissions: user-supplied source screenshots can guide modeling, but do not redistribute/reuse third-party photographs as in-game assets unless permission/license allows it. The goal is an original 3D model based on authentic visual references.

### Geometry recognizability checklist (prioritize in this order)

1. Building across the plaza must have **continuous modernist rectangular façade**: long beige concrete/cladding horizontal canopy at first-floor height, with the **Lakehead** lettering in roughly the same focal position as photographed.
2. A **long, upper-level strip of blue reflective windows** across the top portion above the entrance canopy.
3. Ground level with **recessed large dark glass entrance doors/windows** below canopy.
4. Correct **wide, open rectangular plaza** paved with rows of square/rectangular grey/beige slabs, NOT a blue waterworld or painted circle decal.
5. The **side connecting wings**, trees, benches, planters, and main front doors placed according to reference composition. Avoid simplistic duplicate unrelated houses.
6. Present-day sky and outdoor lighting should look like a university courtyard; Egyptian monuments appear mostly in ANCIENT reality.

### Rendering and camera

Prefer third-person perspective or low oblique perspective with player roughly in foreground, entrance in view; a high overhead orthographic shot hides the most recognisable portion of the façade. Preserve responsive movement and collisions. Set at least one default camera viewpoint that makes the recognisable frontage an obvious hero shot. Add a temporary debug-free camera angle selector only if quickly useful for QA.

### Game integration and regression rules

- Keep the EXISTING Three.js + Vite project and working progress; DO NOT start again or migrate engines.
- Inspect `AGENTS.md`, `README.md`, `src/world.js`, and `src/main.js` before making changes. Prior `AGENTS.md` phrase "fictionalized Lakehead" is superseded by this directive.
- Keep gameplay loop: R toggles modern/ancient, three seals A/B/C, world-dependent west door/bridge+east gate, hidden coin, shrine C→B→A, map, rescue Nefertiti.
- Do not move gameplay coordinates, triggers, or collision boxes without updating & testing related logic. Prefer refactoring static decoration into an `AgoraCampus` group, leaving puzzle objects intact.
- Maintain smooth animation, navigation, restart, and real browser tests.
- Create a safety commit/branch before major changes, or back up relevant files.

### Production gates

GATE 1: the modern 3D agora seen from third-person is recognisably based on REAL photo. Capture a screenshot at street-level and compare against reference. Do not fake a validation.
GATE 2: the same navigable 3D space transforms to Egyptian echo when R is pressed, with meaningful geometry/gameplay differences and no broken traversal/collision.
GATE 3: finish gameplay path (A, B, C; shrine reverse order; map; rescue) + npm run build.

Cut optional polish before jeopardizing deadline. Do not spend time trying to scrape/reverse-engineer proprietary tour panoramas or set up photogrammetry without legitimate image rights, multiple views, and a demonstrated quick pipeline.
