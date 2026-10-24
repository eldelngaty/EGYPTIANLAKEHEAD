# Sphinx Reversal — Lakehead Campus Edition

Open project.godot in Godot 4.x and press F5. Tested with Godot 4.6.3; Godot 4.7 was not available for validation.

This continues the existing game. Agora now has a modular masonry facade, recessed entrance and landscaped forecourt. Paterson has horizontal window bands and a curved jade canopy; ATAC has a bowed glazed facade, inclined fins and glazed return elevations. The guardian has a striped nemes, linen kilt, gold collar, staff and walking limbs. Reversal transitions the sky and sunlight, animates runes and particles, and restores the bridge in staggered sections.

Existing quest: collect three ancient scarabs, complete the 3–2–1 altar sequence, obtain the key and map, and rescue Nefertiti. Movement and interaction controls are unchanged. H opens the existing guide. V cycles architecture-facing views; F1 hides the HUD.

Validation: headless import, 15 gameplay checks on both source and packaged PCK, and actual OpenGL screenshots. Graphical rendering used Mesa software rendering; target-device performance and audible output were not measured.

The campus is an approximate stylized reconstruction. Supplied virtual-tour and cubemap URLs returned HTTP 403 in this environment. No imagery was downloaded from them and no survey-level accuracy is claimed. New modular geometry and brick/concrete/paving/grass textures are procedural. Original project assets remain included.

The PCK is a packaged game resource, not a standalone executable. Run with a matching Godot 4.6.3 binary using: godot --main-pack SphinxReversal.pck
Windows export preset is included; Windows export templates were not installed, so no .exe is supplied.
