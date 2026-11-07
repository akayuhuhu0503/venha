# Original room materials

All PNG textures in `pbr/` were created specifically for this project by
`tools/generate_pbr.py`, using deterministic mathematical fields and original
graphics. No room photographs, downloaded textures, or reference pixels are
used. These generated textures and the generator are provided under CC0 1.0:
https://creativecommons.org/publicdomain/zero/1.0/

`pbr/manifest.json` records resolution and physical repeat width for each PBR
set. Albedo maps are sRGB; normal maps use OpenGL +Y; normal and roughness maps
are non-color data. RoomGeo builds per-face UVs in meters, with repeat width
configured in `scripts/materials.gd`. Shared textures use ordinary UV sampling
instead of the costlier triplanar shader. Wood/tile meshes have eight bounded,
deterministic offsets to vary grain without creating a separate texture set.
Oak, woven fabric, chair mesh and granite include very subtle local cavity AO
(0.92–1.0), affecting ambient light only. It is not a baked room shadow.

After the first Godot import, run
`python -X utf8 tools/generate_pbr.py --configure-imports`
to preserve mipmaps and the OpenGL normal-map settings when regenerating
textures. The supplied import metadata already includes these settings.

The desktop screen graphic is original. Its lettering is rasterized using the
Windows Segoe UI font when available; no font file is bundled or redistributed.
