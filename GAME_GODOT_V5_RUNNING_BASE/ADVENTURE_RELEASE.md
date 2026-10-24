# Sphinx Reversal — Third-person adventure

Open project.godot in Godot 4.7.2, or run the supplied Windows executable. No account, paid service or runtime asset download is required.

WASD move, Shift run, mouse look, wheel zoom, E interact, R reverse, M mission map, ESC pause/settings. Follow one yellow objective. The opening lasts 3.5 seconds. Collect the Agora scarab, restore the Library passage, activate the ATAC mechanism, return to the altar (3 → 2 → 1), unlock the ATAC map chamber and restore the lake bridge to rescue Nefertiti. Enter restarts after victory.

The Sphinx is an original authored quadruped, with a pharaonic head, tapered lion body, separate hips/knees/paws, analytic two-bone articulation, stance/swing gait, breathing, tail and turning lean. It is not an imported GLB or a static statue. Original Nefertiti character is retained and scaled for the rescue shot.

The compact campus is a stylized adaptation, not a surveyed digital twin. Official Agora image33, Library image49 and ATAC image42 informed modeled concrete ribs, horizontal glazing, curved green canopy and sandstone/glass atrium. Building relationships are compressed for gameplay; official map retrieval was blocked. See tour_evidence/adventure_reference_review.json in the full source delivery. The four verified photographic tour locations remain local and accessible through ESC → Official Tour / Reference View; these photographs do not provide walking geometry.

Validation uses actual keyboard/mouse events and continuous walking, never assigning player transforms, camera angles or quest flags. It checks hidden pickups, physical building collision, three scarabs, Library/ATAC reversal mechanisms, wrong and correct altar inputs, key, map, water blocking, restored bridge crossing, rescue, victory and engine restart. This is automated input testing plus manual screenshot inspection, not human usability testing.

Limitations: native Windows execution is not available on this Linux runner. Windows EXE resources are additionally exercised with the same Godot 4.7.2 Linux engine. Rendering is tested on software OpenGL, not a gaming GPU. Physical audio playback is untested. Visual fidelity is stylized and architectural topology is approximate. The executable is unsigned; Windows SmartScreen may warn.
