# Pharaoh edition — current verified pass

- Full normal-input mission and restart: **31/31**. Actual WASD/Shift/mouse/wheel/Space/R/E/CBA/M/ESC/UI; QA adapter observes only. Recorded in supported LOW quality on software WebGL.
- Geometry/traversal: **24/24**. Swept camera/realm/corner math: **9/9**.
- Final corrected bundle review: **9/9**, including 360 reference, premature-rescue rejection, bridge removal safety, opposite gate, hidden C and final camera clearance. This separate regression uses existing collision-checked travel replay.
- Four original tour locations / 24 source panorama faces preserved bit-for-bit.
- Actual running-game screenshots, actual-character portrait and full recording: qa/pharaoh/.

The final visual review found and fixed a cubemap convention/orientation issue in the optional reference viewer and photographic reflections. That visual correction and glass calibration occurred after the full recording; they were rechecked on the corrected final bundle. Camera/movement/quest/hero behavior matches the full normal-input run. Full details: qa/pharaoh/summary.json.

Camera now sweeps a padded volume against real-height walls/doors and validates the smoothed result; tight corners choose an alternate orbit before entering the avatar. Movement follows the rendered camera, walls and water stop movement, and jump/landing animation and sound are improved. Main Agora geometry and three original realm-dependent puzzles remain.

Limitations: architecture is approximate, small scenery has simplified collision, jumping is not platforming. Native Windows file launch, gaming GPU performance, physical audio and independent human usability remain untested. Local file URLs are blocked in this runner; bundled HTML was exercised in an actual browser with networking disabled. No unavailable user video or Sketchfab asset was imported. Earlier qa/current reports are historical.
