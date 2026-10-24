# Current hero and environment sources

The playable character is now an original armored **human Pharaoh**, with two animated legs, arms/hands, a staff, a linen kilt, blue-and-gold armor and a striped nemes. `src/pharaoh.js` supplies both the game model and `src/hero_preview.js` portrait. The delivered PNG is an actual rendering of that same model, not concept art or evidence of a downloaded asset.

The user-requested Sketchfab URL was checked: https://sketchfab.com/3d-models/sci-fi-pharaoh-suit-b4456e0de5fd49a28ae0062253dff349 . The page, model API, download API and oEmbed all returned HTTP 403 in this environment. Its download availability and license could not be verified. **No Sketchfab geometry, textures or animations have been copied or imported.** The user then instructed us to proceed autonomously, so an original Pharaoh was authored locally instead.

The two latest user-referenced videos were unavailable in the accessible attachments. An older recording exceeded the 32 MiB tool transfer limit. No unavailable video was watched or reconstructed, and no such claim is made.

Environment improvements therefore use the existing supplied Agora reference and the already verified official Agora panorama (page13/image19/cube8). The user previously explicitly authorized imagery redistribution in ZIP and GitHub. Six 512px JPEG faces are embedded for physically based **reflections**, not a skybox pretending to be walkable geometry. `reflection_sources.json` records face mapping and hashes. The real 3D facade, collision geometry and original mission are retained; concrete/brick relief and paving are original procedural materials. Campus layout/interior remain approximations.

Play offline with PLAY_PHARAOH.html. The source is still the uploaded Three.js project. Optional build tools regenerate the bundled game and the portrait renderer through `build:standalone` and `build:portrait`. No account, credit purchase or runtime asset download is required.
