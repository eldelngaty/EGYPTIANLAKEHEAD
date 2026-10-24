# Sphinx Reversal — Lakehead Rescue / playable repair

[Windows x64 game](https://github.com/eldelngaty/EGYPTIANLAKEHEAD/raw/refs/heads/repair/360-adventure-ux/downloads/Sphinx_Reversal_Playable_Repair_Windows_x64.zip) · [Complete Godot project](https://github.com/eldelngaty/EGYPTIANLAKEHEAD/raw/refs/heads/repair/360-adventure-ux/downloads/Sphinx_Reversal_Playable_Repair_Project.zip)

Windows: extract the ZIP and run `SphinxReversal.exe`; Godot is not required. Source: open `GAME_GODOT_V5_RUNNING_BASE/project.godot` in **Godot 4.7.2** and press F5.

This continues the same four authentic Lakehead panoramas. Exploration is now a location-based, first-person 360° adventure: right-drag to look, click large hotspots, press E on a highlighted target, and use R to reverse time. Named campus destinations remain visible; the next destination is highlighted. There is no fake small-radius walking or extra reach requirement.

The guardian has a newly authored blue-and-gold nemes, carved face, collar, kilt, hands, sandals, staff and limb pivots. An opening shot, live 3D HUD portrait and rescue/victory presentation keep the hero visible without placing a walking miniature over every photo. Nefertiti has a distinct tall blue crown.

Three short reversal encounters reveal the Agora scarab, restore the Library echo passage, and open ATAC's time lock. The same three-scarab → 3–2–1 altar → golden key → map → Lake Tamblyn → prison reversal → rescue quest remains. A graphical map and restart button complete the flow.

Navigation selects named peers verified in official Thunder Bay tour 52 / parent group 51. It does not invent adjacency from scene numbers or claim direct walking paths. Photo provenance and user-confirmed redistribution permission remain in `assets/tour/manifest.json` and `tour_evidence/`.

Validation uses Godot 4.7.2: 51 public-input completion checks, 51 asset/navigation/layout checks, and 15 legacy logic checks. The final Windows EXE's embedded game data also passes the public-input flow using the Linux Godot runner. Graphical execution captures the actual interface and characters; this is automation plus screenshot review, **not a real-user usability study**. Windows PE export is supplied, but native Windows execution and physical audio/GPU performance remain untested here.

![Actual Godot opening / guardian](screenshots/repair/00_guardian_intro.png)
![Actual Godot map](screenshots/repair/04_ancient_map.png)

Tests from the repository root:
```
godot --headless --path GAME_GODOT_V5_RUNNING_BASE --editor --import --quit
godot --headless --path GAME_GODOT_V5_RUNNING_BASE --script ../validation/tour_gameplay_smoke.gd
godot --headless --path GAME_GODOT_V5_RUNNING_BASE --script ../validation/human_input_smoke.gd
```
