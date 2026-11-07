"""Original, deterministic, tileable room materials. No source photos are used.

Run from any directory: python tools/generate_pbr.py
Requires only numpy and Pillow. Generated normal maps use OpenGL (+Y) convention.
The periodic fields are sampled over [0, 1), so their next pixel wraps naturally.
Albedo is stored in sRGB; roughness and normal data are linear/non-color textures.
"""

from pathlib import Path
import json
import math
import re
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont


OUT = Path(__file__).resolve().parents[1] / "assets" / "textures" / "pbr"
RNG = np.random.default_rng(7502026)
TAU = 2.0 * math.pi
MANIFEST = {}


def grid(n: int):
    v, u = np.mgrid[0:n, 0:n].astype(np.float32) / n
    return u, v


def noise(n: int, cols: int, rows: int):
    """Periodic, smooth value noise; separate axes also give non-stretched grain."""
    lattice = RNG.random((rows, cols), dtype=np.float32)
    p = np.arange(n, dtype=np.float32) / n
    xx, yy = p * cols, p * rows
    ix, iy = np.floor(xx).astype(np.int32), np.floor(yy).astype(np.int32)
    tx, ty = xx - ix, yy - iy
    tx, ty = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)
    aa = lattice[iy[:, None] % rows, ix[None, :] % cols]
    ab = lattice[iy[:, None] % rows, (ix[None, :] + 1) % cols]
    ba = lattice[(iy[:, None] + 1) % rows, ix[None, :] % cols]
    bb = lattice[(iy[:, None] + 1) % rows, (ix[None, :] + 1) % cols]
    return (aa * (1 - tx) + ab * tx) * (1 - ty[:, None]) + (ba * (1 - tx) + bb * tx) * ty[:, None]


def fbm(n: int, start=4, octaves=5):
    image = np.zeros((n, n), np.float32)
    weight, total = 1.0, 0.0
    for octave in range(octaves):
        cells = start * 2 ** octave
        image += noise(n, cells, cells) * weight
        total += weight
        weight *= 0.48
    return image / total


def wrap_delta(p, center):
    return (p - center + 0.5) % 1.0 - 0.5


def to_u8(array):
    return np.clip(np.rint(array * 255), 0, 255).astype(np.uint8)


def normals(height, meters=1.0, amplitude=0.0001):
    # Central differences wrap, preserving normal-map continuity across repeats.
    scale = height.shape[0] * amplitude / (meters * 2.0)
    dx = (np.roll(height, -1, 1) - np.roll(height, 1, 1)) * scale
    dy = (np.roll(height, -1, 0) - np.roll(height, 1, 0)) * scale
    normal = np.stack((-dx, dy, np.ones_like(dx)), axis=2)
    normal /= np.linalg.norm(normal, axis=2, keepdims=True)
    return normal * 0.5 + 0.5


def save_material(name, color, height, roughness, meters, amplitude, note):
    OUT.mkdir(parents=True, exist_ok=True)
    Image.fromarray(to_u8(color)).save(OUT / f"{name}_albedo.png", optimize=True)
    Image.fromarray(to_u8(normals(height, meters, amplitude))).save(OUT / f"{name}_normal.png", optimize=True)
    Image.fromarray(to_u8(roughness)).save(OUT / f"{name}_roughness.png", optimize=True)
    has_ao = name in {"oak", "fabric", "chair_mesh", "granite"}
    if has_ao:
        # Very small local cavity occlusion, not a uniform baked shadow/tint.
        nearby = (np.roll(height, 1, 0) + np.roll(height, -1, 0)
                  + np.roll(height, 1, 1) + np.roll(height, -1, 1)) * 0.25
        cavity = np.maximum(nearby - height, 0) / max(float(height.std()), 0.03)
        ao = 1.0 - np.clip(cavity * 0.025, 0, 0.08)
        Image.fromarray(to_u8(ao)).save(OUT / f"{name}_ao.png", optimize=True)
    MANIFEST[name] = {
        "resolution": list(height.shape),
        "texture_width_m": meters,
        "height_amplitude_m": amplitude,
        "roughness_range": [round(float(roughness.min()), 3), round(float(roughness.max()), 3)],
        "description": note,
        "subtle_cavity_ao": has_ao,
    }


def oak():
    n = 1024
    u, v = grid(n)
    broad = noise(n, 7, 3) - 0.5
    long_grain = 0.62 * noise(n, 45, 3) + 0.25 * noise(n, 111, 5) + 0.13 * noise(n, 230, 13)
    # Curving growth lines change gently along the board, rather than giant stripes.
    warp = 0.027 * np.sin(TAU * v) + 0.019 * np.sin(TAU * (2 * v + u))
    phase = TAU * (30 * (u + warp))
    annual = np.power(0.5 + 0.5 * np.cos(phase), 12)
    broken = 0.35 + 0.65 * noise(n, 32, 45)
    pores = np.maximum(noise(n, 255, 20) - 0.68, 0) * 2.5
    flecks = np.maximum(noise(n, 18, 180) - 0.73, 0) * 1.2
    knot = np.zeros((n, n), np.float32)
    for cx, cy, strength in [(0.24, 0.33, 0.035), (0.76, 0.80, 0.021)]:
        dx = wrap_delta(u, cx) / 0.039
        dy = wrap_delta(v, cy) / 0.105
        radius = np.sqrt(dx * dx + dy * dy)
        knot += strength * np.exp(-radius * radius / 5) * (0.5 + 0.5 * np.cos(radius * 12))
    tone = broad * 0.08 + (long_grain - 0.5) * 0.12 - annual * broken * 0.020 - pores * 0.026 + flecks * 0.025 - knot
    # Neutral natural oak: no orange albedo multiplication in the runtime material.
    color = np.array([0.715, 0.657, 0.557], np.float32) + tone[:, :, None] * np.array([1.0, 0.95, 0.85])
    height = (long_grain - 0.5) * 0.50 - pores * 0.8 - annual * 0.14
    rough = np.clip(0.49 + (long_grain - 0.5) * 0.08 + pores * 0.12, 0.40, 0.66)
    save_material("oak", color, height, rough, 0.72, 0.00018, "Neutral pale oak veneer, fine longitudinal pores and sparse understated knots.")


def marble():
    n = 1024
    u, v = grid(n)
    cloud = fbm(n, 3, 5)
    fine = fbm(n, 20, 4)
    p = u + v + (cloud - 0.5) * 0.65 + (fine - 0.5) * 0.12
    main = np.exp(-np.square(np.sin(TAU * p) / 0.016))
    soft = np.exp(-np.square(np.sin(TAU * p) / 0.060))
    p2 = 2 * u - v + (cloud - 0.5) * 0.52 + (fine - 0.5) * 0.06
    branch = np.exp(-np.square(np.sin(TAU * p2) / 0.010)) * np.maximum(0, (cloud - 0.42)) * 2.8
    veil = np.exp(-np.square(np.sin(TAU * (u - 2 * v + cloud * 0.12)) / 0.13))
    strength = 0.45 + noise(n, 11, 11) * 0.55
    variation = (cloud - 0.5) * 0.026 + (fine - 0.5) * 0.008
    tone = variation - main * strength * 0.10 - soft * 0.032 - branch * 0.085 - veil * 0.010
    color = np.array([0.927, 0.931, 0.918], np.float32) + tone[:, :, None]
    height = (fine - 0.5) * 0.08 - main * 0.04
    rough = 0.40 + (fine - 0.5) * 0.05 + soft * 0.025
    save_material("marble", color, height, rough, 1.20, 0.000018, "Off-white ceramic marble print, sparse fine gray veins, no dark baked grout.")


def plaster():
    n = 1024
    mottling = fbm(n, 3, 5)
    grain = noise(n, 365, 365)
    tooth = noise(n, 190, 190)
    height = tooth * 0.6 + grain * 0.4
    variation = (mottling - 0.5) * 0.011 + (grain - 0.5) * 0.006
    color = np.array([0.893, 0.893, 0.876], np.float32) + variation[:, :, None]
    rough = 0.88 + (grain - 0.5) * 0.06
    save_material("plaster", color, height, rough, 0.80, 0.00016, "Neutral warm-white painted fine plaster; extremely subtle diffuse variation.")


def fabric():
    n = 512
    u, v = grid(n)
    threads = 80
    warp = np.power(0.5 + 0.5 * np.cos(TAU * threads * u), 2)
    weft = np.power(0.5 + 0.5 * np.cos(TAU * threads * v), 2)
    over = ((np.floor(u * threads) + np.floor(v * threads)) % 2).astype(np.float32)
    height = np.where(over > 0, warp * 0.65 + weft * 0.22, weft * 0.65 + warp * 0.22)
    lint = noise(n, 128, 128)
    shade = 0.83 + (height - 0.5) * 0.12 + (lint - 0.5) * 0.04
    color = np.stack([shade, shade, shade], axis=2)
    rough = 0.88 + (lint - 0.5) * 0.08
    save_material("fabric", color, height, rough, 0.18, 0.00031, "Neutral woven cotton twill tint base, with physically small warp and weft.")


def mesh_fabric():
    n = 512
    u, v = grid(n)
    threads = 20
    warp = np.power(0.5 + 0.5 * np.cos(TAU * threads * u), 4)
    weft = np.power(0.5 + 0.5 * np.cos(TAU * threads * v), 4)
    height = np.maximum(warp, weft)
    coverage = np.clip((height - 0.10) * 15, 0, 1)
    lint = noise(n, 130, 130)
    shade = 0.13 + height * 0.055 + (lint - 0.5) * 0.013
    color = np.stack([shade, shade * 1.03, shade * 1.035, coverage], axis=2)
    rough = np.full_like(height, 0.87)
    save_material("chair_mesh", color, height, rough, 0.10, 0.00022, "Dark polyester chair mesh with actual alpha-cut holes; 5 mm woven grid.")


def granite():
    n = 1024
    crystal = noise(n, 220, 220)
    fines = noise(n, 440, 440)
    cloud = fbm(n, 9, 4)
    fleck = np.maximum(crystal - 0.60, 0) ** 1.7
    dark_fleck = np.maximum(0.32 - crystal, 0)
    tone = (cloud - 0.5) * 0.025 + fleck * 0.80 - dark_fleck * 0.10 + (fines - 0.5) * 0.024
    color = np.array([0.165, 0.175, 0.168], np.float32) + tone[:, :, None]
    height = fines * 0.09 + crystal * 0.03
    rough = 0.31 + (crystal - 0.5) * 0.06
    save_material("granite", color, height, rough, 0.60, 0.00009, "Dark polished granite with fine pale mineral flecks; not glossy black plastic.")


def brushed_metal():
    n = 512
    grain = noise(n, 2, 384)
    wide = noise(n, 5, 70)
    tone = (grain - 0.5) * 0.020 + (wide - 0.5) * 0.014
    color = np.array([0.63, 0.65, 0.65], np.float32) + tone[:, :, None]
    rough = 0.34 + (grain - 0.5) * 0.10 + (wide - 0.5) * 0.025
    save_material("brushed_metal", color, grain, rough, 0.30, 0.000012, "Neutral stainless steel, fine directional machining marks and restrained roughness.")


def desktop():
    # Original crisp screen content, not a screenshot or a copied reference photo.
    width, height = 1024, 576
    image = Image.new("RGB", (width, height))
    pix = np.zeros((height, width, 3), np.uint8)
    yy, xx = np.mgrid[0:height, 0:width]
    radial = np.exp(-(((xx - 690) / 640) ** 2 + ((yy - 180) / 460) ** 2))
    for channel, pair in enumerate([(21, 35), (30, 57), (37, 62)]):
        pix[:, :, channel] = pair[0] + radial * (pair[1] - pair[0])
    image = Image.fromarray(pix)
    draw = ImageDraw.Draw(image)
    fonts = Path("C:/Windows/Fonts")

    def font(size, bold=False):
        path = fonts / ("segoeuib.ttf" if bold else "segoeui.ttf")
        return ImageFont.truetype(str(path), size) if path.exists() else ImageFont.load_default()

    draw.text((480, 137), "7:50", font=font(116), fill=(218, 226, 215))
    draw.text((486, 262), "VỀ NHÀ", font=font(29), fill=(164, 186, 179))
    draw.line((487, 314, 850, 314), fill=(79, 109, 106), width=1)
    draw.text((487, 331), "Một góc nhỏ. Một ngày bình thường.", font=font(17), fill=(150, 174, 169))
    for idx, title in enumerate(["Ghi chú", "Bể cá", "Thư mục"]):
        y = 55 + idx * 109
        draw.rounded_rectangle((45, y, 88, y + 39), radius=6, fill=(86 + idx * 9, 118 + idx * 5, 119))
        draw.line((55, y + 12, 78, y + 12), fill=(194, 211, 200), width=2)
        draw.line((55, y + 21, 72, y + 21), fill=(194, 211, 200), width=2)
        draw.text((38, y + 48), title, font=font(15), fill=(190, 204, 199))
    draw.rectangle((0, 536, 1024, 576), fill=(18, 24, 28))
    draw.rounded_rectangle((17, 546, 39, 566), radius=3, fill=(111, 151, 146))
    draw.rounded_rectangle((57, 544, 268, 569), radius=4, fill=(38, 49, 53))
    draw.text((68, 547), "Tìm trong máy tính", font=font(13), fill=(166, 182, 178))
    draw.text((957, 545), "07:50", font=font(14), fill=(193, 208, 201))
    image.save(OUT / "desktop_albedo.png", optimize=True)


def bathroom_tiles():
    n = 1024
    cloud = fbm(n, 6, 5)
    mineral = noise(n, 260, 260)
    delicate = fbm(n, 30, 4)
    base = np.array([0.435, 0.356, 0.301], np.float32)
    tone = (cloud - 0.5) * 0.065 + (mineral - 0.5) * 0.018
    brown = base + tone[:, :, None]
    height = delicate * 0.14 + mineral * 0.08
    rough = 0.59 + (delicate - 0.5) * 0.09
    save_material("bath_brown", brown, height, rough, 0.60, 0.00010,
                  "Muted warm-brown bathroom porcelain, fine stone grain and matte floor finish; grout is geometry.")
    ivory = np.array([0.865, 0.853, 0.805], np.float32) + ((cloud - 0.5) * 0.019 + (mineral - 0.5) * 0.004)[:, :, None]
    rough = 0.40 + (delicate - 0.5) * 0.04
    save_material("bath_ivory", ivory, height * 0.25, rough, 0.60, 0.00005,
                  "Warm ivory glazed bathroom wall tile, restrained non-flat surface; grout is geometry.")


def configure_imports():
    count = 0
    for path in OUT.glob("*.png.import"):
        content = path.read_text(encoding="utf-8")
        settings = {
            "compress/mode": "0",  # lossless source maps, no block artifacts on grain
            "mipmaps/generate": "true",
            "mipmaps/limit": "-1",
            "process/normal_map_invert_y": "false",
            "detect_3d/compress_to": "0",
        }
        if path.name.endswith("_normal.png.import"):
            settings["compress/normal_map"] = "1"
        for key, value in settings.items():
            pattern = rf"^{re.escape(key)}=.*$"
            if re.search(pattern, content, re.MULTILINE):
                content = re.sub(pattern, key + "=" + value, content, flags=re.MULTILINE)
            else:
                content += "\n" + key + "=" + value + "\n"
        path.write_text(content, encoding="utf-8")
        count += 1
    print("Configured mipmaps and OpenGL normal imports:", count)


if __name__ == "__main__":
    if "--configure-imports" in sys.argv:
        configure_imports()
        raise SystemExit(0)
    for build in [oak, marble, plaster, fabric, mesh_fabric, granite, brushed_metal, bathroom_tiles]:
        build()
        print("Generated", build.__name__)
    desktop()
    (OUT / "manifest.json").write_text(json.dumps(MANIFEST, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("Saved", len(MANIFEST), "PBR sets plus original desktop texture to", OUT)
    configure_imports()
