# Current uploaded-project development pass

- Geometry/traversal: 24/24.
- Actual WASD/mouse/wheel/Shift/R/E/CBA/M/ESC full quest and restart: 20/20 against source; 20/20 against self-contained HTML with network disabled.
- Final packed HTML regression after visual fixes: 30/30. This additional regression uses the existing collision-checked movement replay between real keyboard/UI actions, unlike the full keyboard runs.
- Final normal intro, solid four-legged hero profile and 1024px HUD rendered offline and inspected.
- Actual screenshots, short gameplay recording, methods and logs: qa/current/.

The final visual pass corrected body triangle winding, foot height on plaza/atrium/bridge and the ending camera that crossed the Agora wall. Core quest state and original puzzle positions are retained.

Native Windows file launching is untested: local file URLs are blocked by administrator policy on this test runner. Standalone HTML was tested in actual Chromium with network disabled and its document supplied through a test response. Human usability, physical audio and gaming-GPU performance remain untested. See qa/current/summary.json for exact scope. Earlier reports are historical.
