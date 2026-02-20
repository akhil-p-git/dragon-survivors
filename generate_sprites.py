#!/usr/bin/env python3
"""
Dragon Survivors - Enhanced Pixel Art Sprite Generator
Generates all game sprites as high-quality pixel art PNGs with transparency.
Features: richer palettes, dark outlines, dithering, consistent top-left lighting.
"""

from PIL import Image, ImageDraw
import os
import math

OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "assets", "sprites")
os.makedirs(OUTPUT_DIR, exist_ok=True)


def save(img, name):
    path = os.path.join(OUTPUT_DIR, name)
    img.save(path)
    print(f"  Created: {name} ({img.width}x{img.height})")


def px(img, x, y, color):
    """Set a single pixel with bounds checking."""
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), color)


def get_px(img, x, y):
    """Get pixel color with bounds checking."""
    if 0 <= x < img.width and 0 <= y < img.height:
        return img.getpixel((x, y))
    return (0, 0, 0, 0)


def fill_rect(img, x1, y1, x2, y2, color):
    """Fill a rectangle of pixels."""
    for yy in range(max(0, y1), min(img.height, y2 + 1)):
        for xx in range(max(0, x1), min(img.width, x2 + 1)):
            img.putpixel((xx, yy), color)


def draw_ellipse_filled(img, x1, y1, x2, y2, color):
    """Draw a filled ellipse pixel by pixel."""
    cx = (x1 + x2) / 2.0
    cy = (y1 + y2) / 2.0
    rx = (x2 - x1) / 2.0
    ry = (y2 - y1) / 2.0
    for yy in range(y1, y2 + 1):
        for xx in range(x1, x2 + 1):
            if rx > 0 and ry > 0:
                if ((xx - cx) ** 2) / (rx ** 2) + ((yy - cy) ** 2) / (ry ** 2) <= 1.0:
                    px(img, xx, yy, color)


def add_outline(img, outline_color=(10, 10, 15, 255)):
    """Add a 1px dark outline around all non-transparent pixels."""
    w, h = img.size
    outline_pixels = []
    for y in range(h):
        for x in range(w):
            r, g, b, a = img.getpixel((x, y))
            if a == 0:
                # Check if any neighbor is opaque
                for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h:
                        _, _, _, na = img.getpixel((nx, ny))
                        if na > 128:
                            outline_pixels.append((x, y))
                            break
    for x, y in outline_pixels:
        img.putpixel((x, y), outline_color)


def dither_rect(img, x1, y1, x2, y2, color1, color2, pattern="checker"):
    """Fill a rect with a dithering pattern between two colors."""
    for yy in range(max(0, y1), min(img.height, y2 + 1)):
        for xx in range(max(0, x1), min(img.width, x2 + 1)):
            if pattern == "checker":
                c = color1 if (xx + yy) % 2 == 0 else color2
            elif pattern == "horizontal":
                c = color1 if yy % 2 == 0 else color2
            elif pattern == "vertical":
                c = color1 if xx % 2 == 0 else color2
            img.putpixel((xx, yy), c)


def blend_color(c1, c2, t):
    """Blend two RGBA colors. t=0 gives c1, t=1 gives c2."""
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(4))


# ============================================================
# 1. KNIGHT (32x48) - Blue armored knight hero
# ============================================================
def generate_knight():
    img = Image.new("RGBA", (32, 48), (0, 0, 0, 0))

    # Extended palette with 6 shading steps
    steel_hi = (160, 200, 235, 255)    # Brightest highlight
    steel_lt = (120, 170, 210, 255)    # Light
    steel = (70, 130, 180, 255)        # Base
    steel_md = (50, 100, 155, 255)     # Mid shadow
    steel_dk = (35, 70, 120, 255)      # Dark
    steel_vdk = (20, 45, 85, 255)      # Deepest shadow
    visor_dark = (15, 15, 30, 255)
    skin = (225, 185, 145, 255)
    skin_shadow = (195, 155, 115, 255)
    eye_dark = (30, 30, 45, 255)
    sword_hi = (220, 225, 235, 255)
    sword_mid = (180, 190, 200, 255)
    sword_dk = (140, 150, 165, 255)
    hilt_brown = (139, 90, 43, 255)
    hilt_dk = (100, 60, 25, 255)
    gold = (200, 170, 40, 255)
    gold_hi = (240, 215, 80, 255)

    # === HELMET ===
    # Top plume/crest
    fill_rect(img, 13, 1, 18, 2, steel_lt)
    fill_rect(img, 14, 0, 17, 0, steel_hi)
    # Main helmet dome
    fill_rect(img, 10, 3, 21, 5, steel_lt)
    fill_rect(img, 9, 6, 22, 14, steel)
    # Top-left highlight
    fill_rect(img, 10, 3, 14, 5, steel_hi)
    fill_rect(img, 9, 6, 12, 8, steel_hi)
    dither_rect(img, 13, 6, 15, 8, steel_hi, steel_lt)
    # Right side shadow
    fill_rect(img, 19, 6, 22, 14, steel_md)
    fill_rect(img, 21, 9, 22, 14, steel_dk)
    # Bottom helm shadow
    fill_rect(img, 9, 13, 22, 14, steel_md)
    # Visor slit with depth
    fill_rect(img, 11, 10, 21, 11, visor_dark)
    # Face visible through visor
    fill_rect(img, 12, 10, 19, 11, skin)
    fill_rect(img, 17, 10, 19, 11, skin_shadow)
    # Eyes in visor
    px(img, 13, 10, eye_dark)
    px(img, 17, 10, eye_dark)
    # Visor rim highlight
    fill_rect(img, 11, 9, 20, 9, steel_lt)
    fill_rect(img, 11, 12, 20, 12, steel_dk)
    # Nose guard
    fill_rect(img, 15, 9, 16, 12, steel_md)
    px(img, 15, 9, steel_lt)

    # Neck
    fill_rect(img, 13, 15, 18, 16, skin)
    px(img, 13, 16, skin_shadow)
    px(img, 18, 16, skin_shadow)

    # === TORSO / ARMOR ===
    fill_rect(img, 8, 17, 23, 30, steel)
    # Chest highlight (top-left light)
    fill_rect(img, 8, 17, 14, 22, steel_lt)
    fill_rect(img, 8, 17, 11, 19, steel_hi)
    dither_rect(img, 12, 17, 14, 19, steel_hi, steel_lt)
    # Chest plate center ridge
    fill_rect(img, 15, 17, 16, 28, steel_md)
    # Shadow on right and bottom
    fill_rect(img, 20, 24, 23, 30, steel_dk)
    fill_rect(img, 22, 20, 23, 30, steel_vdk)
    dither_rect(img, 19, 26, 21, 30, steel, steel_dk)
    # Armor plate line
    fill_rect(img, 8, 23, 23, 23, steel_dk)
    # Belt
    fill_rect(img, 8, 29, 23, 30, hilt_brown)
    fill_rect(img, 8, 29, 23, 29, hilt_dk)
    # Belt buckle
    fill_rect(img, 14, 29, 17, 30, gold)
    px(img, 14, 29, gold_hi)

    # === SHOULDER PAULDRONS ===
    # Left pauldron
    fill_rect(img, 5, 16, 8, 19, steel_lt)
    fill_rect(img, 5, 16, 6, 17, steel_hi)
    fill_rect(img, 7, 18, 8, 19, steel_md)
    # Right pauldron
    fill_rect(img, 23, 16, 26, 19, steel)
    fill_rect(img, 25, 18, 26, 19, steel_dk)

    # === ARMS ===
    # Left arm
    fill_rect(img, 4, 20, 7, 28, steel)
    fill_rect(img, 4, 20, 5, 24, steel_lt)
    fill_rect(img, 6, 25, 7, 28, steel_dk)
    # Right arm
    fill_rect(img, 24, 20, 27, 28, steel_md)
    fill_rect(img, 26, 24, 27, 28, steel_dk)
    # Elbow joints
    dither_rect(img, 4, 24, 7, 25, steel, steel_dk)
    dither_rect(img, 24, 24, 27, 25, steel_dk, steel_vdk)
    # Gauntlets
    fill_rect(img, 4, 27, 7, 28, steel_dk)
    fill_rect(img, 24, 27, 27, 28, steel_vdk)
    # Hands
    fill_rect(img, 4, 29, 7, 30, skin)
    fill_rect(img, 6, 30, 7, 30, skin_shadow)
    fill_rect(img, 24, 29, 27, 30, skin_shadow)

    # === LEGS ===
    fill_rect(img, 10, 31, 15, 42, steel_dk)
    fill_rect(img, 17, 31, 22, 42, steel_dk)
    # Left leg highlight
    fill_rect(img, 10, 31, 12, 36, steel)
    dither_rect(img, 10, 37, 12, 40, steel, steel_dk)
    # Right leg shadow
    fill_rect(img, 20, 36, 22, 42, steel_vdk)
    # Knee plates
    fill_rect(img, 10, 36, 15, 37, steel)
    fill_rect(img, 17, 36, 22, 37, steel_md)

    # === BOOTS ===
    fill_rect(img, 9, 43, 16, 46, steel_dk)
    fill_rect(img, 16, 43, 23, 46, steel_dk)
    fill_rect(img, 9, 43, 12, 44, steel)
    fill_rect(img, 21, 45, 23, 46, steel_vdk)
    # Soles
    fill_rect(img, 9, 46, 16, 47, (25, 25, 35, 255))
    fill_rect(img, 16, 46, 23, 47, (25, 25, 35, 255))

    # === SWORD ===
    # Pommel
    px(img, 27, 29, gold)
    px(img, 28, 29, gold_hi)
    # Hilt grip
    fill_rect(img, 27, 25, 28, 28, hilt_brown)
    dither_rect(img, 27, 25, 28, 28, hilt_brown, hilt_dk, "horizontal")
    # Crossguard
    fill_rect(img, 25, 24, 30, 25, gold)
    px(img, 25, 24, gold_hi)
    px(img, 30, 25, hilt_dk)
    # Blade
    fill_rect(img, 27, 12, 28, 23, sword_mid)
    # Blade highlight (left edge)
    for y in range(12, 24):
        px(img, 27, y, sword_hi)
    # Blade shadow (right edge)
    for y in range(16, 24):
        px(img, 28, y, sword_dk)
    # Blade tip
    px(img, 27, 11, sword_hi)
    px(img, 28, 11, sword_mid)
    px(img, 27, 10, sword_mid)

    add_outline(img)
    save(img, "knight.png")


# ============================================================
# 2. ARCHER (32x48) - Green hooded archer
# ============================================================
def generate_archer():
    img = Image.new("RGBA", (32, 48), (0, 0, 0, 0))

    # Rich green palette
    green_hi = (90, 190, 95, 255)
    green_lt = (60, 160, 70, 255)
    green = (34, 120, 50, 255)
    green_md = (25, 95, 38, 255)
    green_dk = (18, 70, 25, 255)
    green_vdk = (10, 48, 15, 255)
    brown = (120, 70, 30, 255)
    brown_lt = (150, 95, 45, 255)
    brown_dk = (80, 45, 15, 255)
    skin = (225, 185, 145, 255)
    skin_shadow = (195, 155, 115, 255)
    eye_color = (40, 40, 45, 255)
    bow_lt = (170, 110, 45, 255)
    bow = (140, 85, 30, 255)
    bow_dk = (100, 60, 18, 255)
    string = (210, 210, 190, 255)
    gold = (200, 170, 40, 255)

    # === HOOD ===
    # Hood peak
    fill_rect(img, 14, 0, 17, 1, green_lt)
    px(img, 15, 0, green_hi)
    # Hood top
    fill_rect(img, 11, 1, 20, 3, green_lt)
    fill_rect(img, 10, 4, 21, 6, green)
    fill_rect(img, 9, 7, 22, 12, green)
    # Hood highlight (top-left light)
    fill_rect(img, 11, 1, 15, 3, green_hi)
    fill_rect(img, 10, 4, 13, 6, green_hi)
    dither_rect(img, 14, 4, 16, 6, green_hi, green_lt)
    fill_rect(img, 9, 7, 12, 9, green_lt)
    # Hood shadow (right)
    fill_rect(img, 19, 8, 22, 12, green_dk)
    fill_rect(img, 21, 10, 22, 12, green_vdk)
    # Hood drape sides
    fill_rect(img, 9, 13, 10, 16, green_md)
    fill_rect(img, 21, 13, 22, 16, green_dk)

    # Face
    fill_rect(img, 12, 9, 19, 13, skin)
    fill_rect(img, 17, 11, 19, 13, skin_shadow)
    # Eyes
    px(img, 14, 10, eye_color)
    px(img, 18, 10, eye_color)
    # Eye whites
    px(img, 13, 10, (240, 240, 240, 255))
    px(img, 17, 10, (240, 240, 240, 255))
    # Mouth
    px(img, 15, 12, skin_shadow)
    px(img, 16, 12, skin_shadow)

    # Neck
    fill_rect(img, 13, 14, 18, 15, skin)
    px(img, 17, 15, skin_shadow)

    # === CLOAK / TORSO ===
    fill_rect(img, 8, 16, 23, 30, green)
    # Highlight
    fill_rect(img, 8, 16, 14, 22, green_lt)
    fill_rect(img, 8, 16, 11, 18, green_hi)
    dither_rect(img, 12, 16, 14, 20, green_hi, green_lt)
    # Shadow
    fill_rect(img, 20, 24, 23, 30, green_dk)
    fill_rect(img, 22, 22, 23, 30, green_vdk)
    dither_rect(img, 19, 26, 21, 30, green, green_dk)
    # Cloak folds
    fill_rect(img, 15, 17, 16, 28, green_md)

    # Belt
    fill_rect(img, 8, 29, 23, 30, brown)
    fill_rect(img, 8, 29, 23, 29, brown_dk)
    # Belt buckle
    fill_rect(img, 14, 29, 17, 30, gold)

    # === ARMS ===
    fill_rect(img, 4, 17, 7, 28, green)
    fill_rect(img, 4, 17, 5, 22, green_lt)
    fill_rect(img, 6, 24, 7, 28, green_dk)
    fill_rect(img, 24, 17, 27, 28, green_md)
    fill_rect(img, 26, 22, 27, 28, green_dk)
    # Bracers
    fill_rect(img, 4, 26, 7, 28, brown)
    fill_rect(img, 24, 26, 27, 28, brown_dk)
    # Hands
    fill_rect(img, 4, 29, 7, 30, skin)
    fill_rect(img, 24, 29, 27, 30, skin_shadow)

    # === BOW ===
    # Bow stave (curved)
    for i in range(14):
        by = 17 + i
        # Curve the bow outward
        offset = int(2.5 * math.sin(math.pi * i / 13))
        bx = 2 - offset
        px(img, bx, by, bow)
        px(img, bx + 1, by, bow_lt)
        if i in (0, 13):
            px(img, bx, by, bow_dk)  # Tips darker
    # Bow tips (nocks)
    px(img, 2, 16, bow_dk)
    px(img, 2, 31, bow_dk)
    # Bowstring
    for i in range(13):
        px(img, 3, 17 + i, string)
    # Arrow nocked
    px(img, 3, 23, (160, 165, 170, 255))
    px(img, 2, 23, (160, 165, 170, 255))
    px(img, 1, 23, (200, 200, 210, 255))

    # === QUIVER ===
    fill_rect(img, 24, 13, 26, 26, brown)
    fill_rect(img, 24, 13, 25, 18, brown_lt)
    fill_rect(img, 26, 20, 26, 26, brown_dk)
    # Arrow tips
    px(img, 24, 12, (180, 180, 185, 255))
    px(img, 25, 11, (180, 180, 185, 255))
    px(img, 26, 12, (180, 180, 185, 255))
    px(img, 25, 12, (200, 200, 210, 255))
    # Fletching
    px(img, 24, 13, (200, 50, 50, 255))
    px(img, 26, 13, (200, 50, 50, 255))

    # === LEGS ===
    fill_rect(img, 10, 31, 15, 42, green_dk)
    fill_rect(img, 17, 31, 22, 42, green_dk)
    fill_rect(img, 10, 31, 12, 36, green_md)
    fill_rect(img, 20, 37, 22, 42, green_vdk)

    # Boots
    fill_rect(img, 9, 43, 16, 46, brown)
    fill_rect(img, 16, 43, 23, 46, brown)
    fill_rect(img, 9, 43, 12, 44, brown_lt)
    fill_rect(img, 21, 45, 23, 46, brown_dk)
    fill_rect(img, 9, 46, 16, 47, brown_dk)
    fill_rect(img, 16, 46, 23, 47, brown_dk)

    add_outline(img)
    save(img, "archer.png")


# ============================================================
# 3. SLIME (24x24) - Glossy gel slime with drip detail
# ============================================================
def generate_slime():
    img = Image.new("RGBA", (24, 24), (0, 0, 0, 0))

    # Glossy green palette
    spec = (200, 255, 210, 255)        # Specular highlight
    green_hi = (130, 245, 130, 255)
    green_lt = (80, 220, 80, 255)
    green = (50, 180, 50, 255)
    green_md = (30, 140, 30, 255)
    green_dk = (15, 100, 15, 255)
    green_vdk = (8, 65, 8, 255)
    white = (255, 255, 255, 255)
    pupil = (15, 15, 20, 255)
    mouth = (10, 70, 10, 255)

    # Main body blob shape (bottom-heavy)
    fill_rect(img, 5, 20, 18, 23, green_vdk)     # Base/shadow
    fill_rect(img, 3, 16, 20, 19, green_dk)       # Lower body
    fill_rect(img, 2, 10, 21, 15, green)          # Mid body
    fill_rect(img, 4, 6, 19, 9, green)            # Upper body
    fill_rect(img, 6, 4, 17, 5, green_lt)         # Top
    fill_rect(img, 8, 3, 15, 3, green_lt)         # Very top

    # Light gradient: top-left is brightest
    fill_rect(img, 4, 6, 10, 8, green_lt)
    fill_rect(img, 3, 9, 9, 11, green_lt)
    fill_rect(img, 6, 4, 12, 5, green_hi)
    dither_rect(img, 11, 6, 14, 9, green_lt, green)
    dither_rect(img, 10, 10, 14, 13, green, green_md)

    # Shadow gradient: bottom-right darker
    fill_rect(img, 16, 14, 20, 19, green_dk)
    dither_rect(img, 14, 16, 18, 19, green_md, green_dk)
    fill_rect(img, 18, 16, 20, 19, green_vdk)

    # Specular highlights (glossy gel)
    fill_rect(img, 6, 4, 8, 5, spec)
    px(img, 7, 3, spec)
    px(img, 5, 6, spec)
    fill_rect(img, 6, 5, 7, 6, green_hi)

    # Drip details on bottom
    px(img, 6, 22, green_dk)
    px(img, 6, 23, green_md)
    px(img, 17, 22, green_dk)
    px(img, 17, 23, green_vdk)
    px(img, 12, 22, green_dk)

    # Eyes (larger, cuter)
    # Left eye white
    fill_rect(img, 6, 9, 9, 12, white)
    px(img, 6, 9, green_lt)
    px(img, 9, 9, green_lt)
    # Left pupil
    fill_rect(img, 7, 10, 8, 11, pupil)
    # Eye shine
    px(img, 7, 10, (80, 80, 100, 255))
    px(img, 7, 9, white)
    # Right eye white
    fill_rect(img, 14, 9, 17, 12, white)
    px(img, 14, 9, green_lt)
    px(img, 17, 9, green_lt)
    # Right pupil
    fill_rect(img, 15, 10, 16, 11, pupil)
    # Eye shine
    px(img, 15, 10, (80, 80, 100, 255))
    px(img, 15, 9, white)

    # Cute smile
    px(img, 9, 14, mouth)
    px(img, 10, 15, mouth)
    px(img, 11, 15, mouth)
    px(img, 12, 15, mouth)
    px(img, 13, 15, mouth)
    px(img, 14, 14, mouth)
    # Cheek blush
    px(img, 5, 13, (100, 200, 100, 128))
    px(img, 18, 13, (80, 170, 80, 128))

    add_outline(img)
    save(img, "slime.png")


# ============================================================
# 4. SKELETON (24x36) - Sharper bones, glowing eyes, weapon
# ============================================================
def generate_skeleton():
    img = Image.new("RGBA", (24, 36), (0, 0, 0, 0))

    bone_hi = (250, 248, 240, 255)
    bone_lt = (240, 235, 225, 255)
    bone = (225, 215, 195, 255)
    bone_md = (200, 190, 170, 255)
    bone_dk = (170, 160, 140, 255)
    bone_vdk = (130, 120, 100, 255)
    eye_glow = (200, 50, 50, 255)
    eye_bright = (255, 100, 80, 255)
    teeth = (210, 200, 185, 255)
    socket = (25, 10, 10, 255)
    weapon_gray = (150, 155, 165, 255)
    weapon_dk = (100, 105, 115, 255)

    # === SKULL ===
    fill_rect(img, 7, 0, 16, 1, bone_lt)
    fill_rect(img, 6, 2, 17, 9, bone)
    # Skull highlight
    fill_rect(img, 7, 0, 12, 3, bone_hi)
    fill_rect(img, 6, 2, 10, 5, bone_lt)
    dither_rect(img, 11, 2, 14, 4, bone_lt, bone)
    # Skull shadow
    fill_rect(img, 14, 6, 17, 9, bone_md)
    fill_rect(img, 16, 7, 17, 9, bone_dk)
    # Brow ridge
    fill_rect(img, 7, 3, 16, 3, bone_md)

    # Glowing eye sockets
    fill_rect(img, 8, 4, 10, 6, socket)
    fill_rect(img, 13, 4, 15, 6, socket)
    # Red glow in sockets
    px(img, 9, 5, eye_glow)
    px(img, 14, 5, eye_glow)
    px(img, 8, 5, eye_bright)
    px(img, 13, 5, eye_bright)
    # Glow bleed
    px(img, 8, 4, (120, 30, 30, 255))
    px(img, 13, 4, (120, 30, 30, 255))

    # Nose cavity
    px(img, 11, 7, socket)
    px(img, 12, 7, socket)
    px(img, 11, 8, (40, 20, 20, 255))

    # Jaw / teeth
    fill_rect(img, 7, 9, 16, 10, bone_dk)
    for x in range(8, 16):
        if x % 2 == 0:
            px(img, x, 9, teeth)
            px(img, x, 10, bone_vdk)

    # Neck (spine vertebrae)
    fill_rect(img, 10, 11, 13, 12, bone_md)
    px(img, 11, 11, bone_lt)
    px(img, 12, 12, bone_dk)

    # === RIBCAGE ===
    # Spine
    fill_rect(img, 11, 13, 12, 21, bone_md)
    px(img, 11, 13, bone_lt)
    # Ribs with shading
    for i in range(4):
        y = 14 + i * 2
        # Left ribs
        fill_rect(img, 6, y, 10, y, bone)
        px(img, 5, y, bone_dk)
        px(img, 6, y, bone_lt)
        # Right ribs
        fill_rect(img, 13, y, 17, y, bone_md)
        px(img, 18, y, bone_dk)

    # Shoulders
    fill_rect(img, 4, 13, 8, 13, bone)
    fill_rect(img, 15, 13, 19, 13, bone_md)

    # === ARMS ===
    # Left arm (with highlights)
    fill_rect(img, 3, 14, 4, 22, bone)
    px(img, 3, 14, bone_lt)
    px(img, 3, 15, bone_lt)
    fill_rect(img, 4, 18, 4, 22, bone_md)
    # Left hand
    fill_rect(img, 2, 23, 5, 24, bone_dk)
    px(img, 2, 23, bone)

    # Right arm
    fill_rect(img, 19, 14, 20, 22, bone_md)
    fill_rect(img, 20, 18, 20, 22, bone_dk)
    # Right hand
    fill_rect(img, 18, 23, 21, 24, bone_dk)

    # === WEAPON (bone club in right hand) ===
    fill_rect(img, 21, 16, 22, 24, weapon_gray)
    fill_rect(img, 21, 16, 21, 18, weapon_dk)
    px(img, 21, 15, weapon_gray)
    px(img, 22, 15, weapon_dk)

    # Pelvis
    fill_rect(img, 8, 22, 15, 23, bone)
    fill_rect(img, 8, 22, 10, 23, bone_lt)
    fill_rect(img, 14, 22, 15, 23, bone_dk)

    # === LEGS ===
    fill_rect(img, 8, 24, 10, 32, bone)
    fill_rect(img, 8, 24, 9, 28, bone_lt)
    fill_rect(img, 10, 28, 10, 32, bone_dk)
    fill_rect(img, 13, 24, 15, 32, bone_md)
    fill_rect(img, 14, 28, 15, 32, bone_dk)

    # Feet
    fill_rect(img, 6, 33, 11, 35, bone_dk)
    fill_rect(img, 6, 33, 8, 34, bone)
    fill_rect(img, 12, 33, 17, 35, bone_dk)

    add_outline(img)
    save(img, "skeleton.png")


# ============================================================
# 5. ARMORED KNIGHT (32x48) - Menacing dark knight enemy
# ============================================================
def generate_armored_knight():
    img = Image.new("RGBA", (32, 48), (0, 0, 0, 0))

    # Dark metal palette
    metal_hi = (140, 140, 155, 255)
    metal_lt = (110, 110, 125, 255)
    metal = (80, 80, 95, 255)
    metal_md = (55, 55, 68, 255)
    metal_dk = (35, 35, 48, 255)
    metal_vdk = (18, 18, 28, 255)
    red_glow = (220, 30, 30, 255)
    red_bright = (255, 60, 50, 255)
    red_dk = (140, 10, 10, 255)
    scar_color = (100, 95, 88, 255)

    # === HELMET ===
    fill_rect(img, 10, 4, 21, 5, metal_lt)
    fill_rect(img, 9, 6, 22, 14, metal)
    fill_rect(img, 10, 4, 21, 6, metal)
    # Highlight
    fill_rect(img, 10, 4, 14, 6, metal_hi)
    fill_rect(img, 9, 6, 12, 8, metal_hi)
    dither_rect(img, 13, 6, 16, 8, metal_hi, metal_lt)
    # Shadow
    fill_rect(img, 19, 9, 22, 14, metal_dk)
    fill_rect(img, 21, 10, 22, 14, metal_vdk)
    # Bottom helm
    fill_rect(img, 9, 13, 22, 14, metal_dk)

    # Horns/spikes
    fill_rect(img, 8, 3, 9, 6, metal_dk)
    fill_rect(img, 7, 1, 8, 3, metal_md)
    px(img, 7, 0, metal_lt)
    fill_rect(img, 22, 3, 23, 6, metal_dk)
    fill_rect(img, 23, 1, 24, 3, metal_md)
    px(img, 24, 0, metal_lt)

    # Glowing red visor
    fill_rect(img, 12, 10, 20, 11, red_glow)
    px(img, 11, 10, red_dk)
    px(img, 21, 10, red_dk)
    px(img, 14, 10, red_bright)
    px(img, 18, 10, red_bright)
    # Visor rim
    fill_rect(img, 11, 9, 21, 9, metal_lt)
    fill_rect(img, 11, 12, 21, 12, metal_dk)

    # Battle damage scratches
    px(img, 14, 7, scar_color)
    px(img, 15, 8, scar_color)
    px(img, 19, 6, scar_color)

    # Neck guard
    fill_rect(img, 11, 15, 20, 16, metal_dk)
    fill_rect(img, 11, 15, 14, 15, metal)

    # === TORSO ===
    fill_rect(img, 7, 17, 24, 30, metal)
    # Highlight
    fill_rect(img, 7, 17, 13, 22, metal_lt)
    fill_rect(img, 7, 17, 10, 19, metal_hi)
    dither_rect(img, 11, 17, 13, 20, metal_hi, metal_lt)
    # Center plate line
    fill_rect(img, 15, 17, 16, 28, metal_dk)
    # Shadow
    fill_rect(img, 20, 24, 24, 30, metal_dk)
    fill_rect(img, 23, 20, 24, 30, metal_vdk)
    dither_rect(img, 19, 26, 22, 30, metal, metal_dk)
    # Armor plate lines
    fill_rect(img, 7, 23, 24, 23, metal_vdk)
    fill_rect(img, 7, 27, 24, 27, metal_vdk)
    # Battle damage on chest
    px(img, 12, 20, scar_color)
    px(img, 13, 21, scar_color)

    # Belt
    fill_rect(img, 7, 29, 24, 30, metal_vdk)
    fill_rect(img, 14, 29, 17, 30, red_dk)
    px(img, 15, 29, red_glow)

    # === SHOULDER PAULDRONS ===
    fill_rect(img, 2, 16, 7, 20, metal_lt)
    fill_rect(img, 2, 16, 4, 17, metal_hi)
    fill_rect(img, 6, 19, 7, 20, metal_dk)
    fill_rect(img, 24, 16, 29, 20, metal)
    fill_rect(img, 27, 18, 29, 20, metal_dk)
    # Spikes
    px(img, 1, 15, metal_lt)
    px(img, 2, 14, metal_hi)
    px(img, 29, 15, metal)
    px(img, 30, 14, metal_lt)

    # === ARMS ===
    fill_rect(img, 3, 21, 6, 28, metal)
    fill_rect(img, 3, 21, 4, 24, metal_lt)
    fill_rect(img, 25, 21, 28, 28, metal_md)
    fill_rect(img, 27, 24, 28, 28, metal_dk)
    # Gauntlets
    fill_rect(img, 3, 29, 6, 31, metal_dk)
    fill_rect(img, 3, 29, 4, 30, metal)
    fill_rect(img, 25, 29, 28, 31, metal_vdk)

    # === LEGS ===
    fill_rect(img, 9, 31, 14, 42, metal_dk)
    fill_rect(img, 17, 31, 22, 42, metal_dk)
    fill_rect(img, 9, 31, 11, 36, metal)
    dither_rect(img, 9, 37, 11, 40, metal, metal_dk)
    fill_rect(img, 20, 36, 22, 42, metal_vdk)
    # Knee guards
    fill_rect(img, 9, 36, 14, 37, metal)
    fill_rect(img, 17, 36, 22, 37, metal_md)

    # Boots
    fill_rect(img, 8, 43, 15, 46, metal_dk)
    fill_rect(img, 16, 43, 23, 46, metal_dk)
    fill_rect(img, 8, 43, 11, 44, metal)
    fill_rect(img, 8, 46, 15, 47, metal_vdk)
    fill_rect(img, 16, 46, 23, 47, metal_vdk)

    # === DARK SWORD ===
    fill_rect(img, 28, 23, 29, 27, (80, 15, 15, 255))
    dither_rect(img, 28, 23, 29, 27, (80, 15, 15, 255), (60, 10, 10, 255), "horizontal")
    fill_rect(img, 28, 12, 29, 22, (110, 110, 120, 255))
    for y in range(12, 23):
        px(img, 28, y, (130, 130, 145, 255))
    for y in range(16, 23):
        px(img, 29, y, (85, 85, 95, 255))
    px(img, 28, 11, (130, 130, 145, 255))
    px(img, 28, 10, (110, 110, 120, 255))
    fill_rect(img, 27, 27, 30, 28, red_dk)
    px(img, 27, 27, red_glow)

    add_outline(img)
    save(img, "armored_knight.png")


# ============================================================
# 6. DRAGON (64x48) - Red dragon boss with more detail
# ============================================================
def generate_dragon():
    img = Image.new("RGBA", (64, 48), (0, 0, 0, 0))

    # Rich red palette
    red_hi = (240, 90, 65, 255)
    red_lt = (220, 65, 45, 255)
    red = (195, 35, 25, 255)
    red_md = (160, 25, 20, 255)
    red_dk = (120, 15, 12, 255)
    red_vdk = (80, 8, 5, 255)
    belly_hi = (250, 215, 100, 255)
    belly_lt = (240, 190, 70, 255)
    belly = (220, 150, 50, 255)
    belly_dk = (190, 120, 35, 255)
    eye_yellow = (255, 240, 30, 255)
    eye_bright = (255, 255, 160, 255)
    pupil = (15, 8, 0, 255)
    wing_bone = (140, 18, 15, 255)
    wing_mem = (170, 35, 30, 180)
    wing_mem_lt = (190, 55, 45, 160)
    claw = (50, 50, 55, 255)
    claw_hi = (90, 90, 100, 255)
    tooth = (245, 245, 230, 255)
    fire_orange = (255, 160, 20, 255)
    fire_yellow = (255, 230, 60, 255)

    # === BODY ===
    fill_rect(img, 20, 22, 48, 38, red)
    fill_rect(img, 18, 25, 50, 35, red)
    # Body highlight (top-left light)
    fill_rect(img, 20, 22, 33, 26, red_lt)
    fill_rect(img, 20, 22, 27, 24, red_hi)
    dither_rect(img, 28, 22, 35, 26, red_lt, red)
    # Body shadow
    fill_rect(img, 38, 33, 50, 38, red_dk)
    fill_rect(img, 45, 30, 50, 38, red_vdk)
    dither_rect(img, 36, 34, 42, 38, red, red_dk)
    # Scale texture (dithered bands)
    dither_rect(img, 22, 28, 46, 30, red, red_md, "checker")

    # Belly (warm gradient)
    fill_rect(img, 24, 33, 44, 38, belly)
    fill_rect(img, 26, 36, 42, 38, belly_lt)
    fill_rect(img, 28, 37, 38, 38, belly_hi)
    fill_rect(img, 38, 33, 44, 36, belly_dk)
    dither_rect(img, 24, 33, 30, 35, belly, belly_lt)

    # === HEAD ===
    fill_rect(img, 8, 16, 22, 28, red)
    fill_rect(img, 6, 18, 20, 26, red)
    # Snout
    fill_rect(img, 4, 20, 8, 25, red)
    fill_rect(img, 2, 21, 5, 24, red_md)
    # Head highlight
    fill_rect(img, 8, 16, 14, 19, red_lt)
    fill_rect(img, 8, 16, 11, 17, red_hi)
    dither_rect(img, 12, 16, 15, 19, red_lt, red)
    # Head shadow
    fill_rect(img, 18, 24, 22, 28, red_dk)

    # Nostrils with fire glow
    px(img, 3, 22, (50, 12, 10, 255))
    px(img, 3, 23, (50, 12, 10, 255))
    # Fire wisps from nostrils
    px(img, 2, 22, fire_orange)
    px(img, 1, 21, fire_yellow)
    px(img, 1, 23, fire_orange)
    px(img, 0, 22, (255, 200, 60, 200))

    # Mouth line
    fill_rect(img, 4, 25, 18, 25, red_dk)
    # Lower jaw
    fill_rect(img, 5, 26, 18, 28, red_dk)
    fill_rect(img, 5, 26, 10, 27, red_md)
    # Teeth
    for x in range(5, 17, 2):
        px(img, x, 25, tooth)
        px(img, x + 1, 26, tooth)
    # Fire glow in mouth
    px(img, 7, 26, fire_orange)
    px(img, 9, 26, fire_yellow)
    px(img, 11, 26, fire_orange)

    # Eyes
    fill_rect(img, 10, 18, 14, 20, eye_yellow)
    px(img, 12, 19, pupil)
    px(img, 11, 19, pupil)
    px(img, 13, 19, pupil)
    # Eye highlight
    px(img, 10, 18, eye_bright)
    px(img, 11, 18, eye_bright)

    # Horns (with gradient)
    fill_rect(img, 12, 13, 14, 16, red_md)
    fill_rect(img, 13, 11, 14, 13, red_dk)
    px(img, 13, 10, red_vdk)
    px(img, 12, 13, red_lt)
    fill_rect(img, 17, 14, 19, 17, red_md)
    fill_rect(img, 18, 12, 19, 14, red_dk)
    px(img, 18, 11, red_vdk)
    px(img, 17, 14, red_lt)

    # === WINGS ===
    # Left wing bones
    fill_rect(img, 22, 10, 25, 22, wing_bone)
    fill_rect(img, 22, 10, 23, 14, red_md)
    # Left wing membrane
    fill_rect(img, 14, 4, 22, 10, wing_mem)
    fill_rect(img, 10, 6, 14, 12, wing_mem)
    fill_rect(img, 22, 4, 30, 12, wing_mem)
    fill_rect(img, 25, 6, 32, 14, wing_mem)
    # Membrane light gradient
    fill_rect(img, 14, 4, 18, 7, wing_mem_lt)
    fill_rect(img, 22, 4, 26, 7, wing_mem_lt)
    dither_rect(img, 12, 8, 20, 10, wing_mem_lt, wing_mem)
    # Wing finger bones
    fill_rect(img, 14, 4, 15, 10, wing_bone)
    fill_rect(img, 22, 3, 23, 8, wing_bone)
    fill_rect(img, 30, 5, 31, 12, wing_bone)
    # Wing tip claws
    px(img, 14, 3, claw)
    px(img, 22, 2, claw)
    px(img, 30, 4, claw)
    px(img, 14, 3, claw_hi)

    # Right wing bones
    fill_rect(img, 40, 10, 43, 22, wing_bone)
    fill_rect(img, 42, 10, 43, 14, red_dk)
    # Right wing membrane
    fill_rect(img, 36, 4, 44, 12, wing_mem)
    fill_rect(img, 44, 4, 52, 10, wing_mem)
    fill_rect(img, 52, 6, 56, 12, wing_mem)
    fill_rect(img, 34, 6, 38, 14, wing_mem)
    # Right wing membrane is darker (shadow side)
    dither_rect(img, 44, 6, 52, 10, wing_mem, (150, 25, 20, 160))
    # Wing finger bones
    fill_rect(img, 36, 3, 37, 8, wing_bone)
    fill_rect(img, 44, 3, 45, 8, wing_bone)
    fill_rect(img, 52, 5, 53, 10, wing_bone)
    # Wing tip claws
    px(img, 36, 2, claw)
    px(img, 44, 2, claw)
    px(img, 53, 4, claw)

    # === TAIL ===
    fill_rect(img, 48, 28, 54, 32, red)
    fill_rect(img, 48, 28, 51, 30, red_lt)
    fill_rect(img, 54, 30, 58, 34, red_md)
    fill_rect(img, 58, 32, 61, 35, red_dk)
    fill_rect(img, 60, 33, 63, 36, red_vdk)
    dither_rect(img, 52, 30, 56, 33, red, red_md)
    # Tail spade
    fill_rect(img, 61, 31, 63, 32, red_dk)
    fill_rect(img, 61, 37, 63, 38, red_dk)
    px(img, 63, 34, red_vdk)

    # === LEGS ===
    # Front legs
    fill_rect(img, 22, 36, 26, 44, red_md)
    fill_rect(img, 22, 36, 24, 40, red)
    fill_rect(img, 20, 44, 27, 46, red_dk)
    # Front claws
    for cx_pos in [20, 22, 24, 26]:
        px(img, cx_pos, 46, claw)
        px(img, cx_pos, 47, claw_hi)

    # Back legs (thicker)
    fill_rect(img, 38, 36, 44, 44, red_md)
    fill_rect(img, 38, 36, 41, 40, red)
    fill_rect(img, 42, 40, 44, 44, red_dk)
    fill_rect(img, 36, 44, 45, 46, red_dk)
    # Back claws
    for cx_pos in [36, 39, 42, 45]:
        px(img, cx_pos, 46, claw)
        px(img, cx_pos, 47, claw_hi)

    add_outline(img)
    save(img, "dragon.png")


# ============================================================
# 7. SWORD ARC (48x24) - Keep existing (already updated)
# ============================================================
def generate_sword_arc():
    img = Image.new("RGBA", (48, 24), (0, 0, 0, 0))

    white = (255, 255, 255, 255)
    bright = (255, 255, 220, 255)
    yellow = (255, 230, 100, 255)
    light_yellow = (255, 240, 160, 200)

    cx, cy = 24, 24
    r_outer = 22
    r_inner = 16

    for y in range(24):
        for x in range(48):
            dx = x - cx
            dy = y - cy
            dist = (dx * dx + dy * dy) ** 0.5
            if r_inner <= dist <= r_outer and y < 20:
                mid_r = (r_outer + r_inner) / 2.0
                band_dist = abs(dist - mid_r) / ((r_outer - r_inner) / 2.0)
                if band_dist < 0.3:
                    px(img, x, y, white)
                elif band_dist < 0.6:
                    px(img, x, y, bright)
                elif band_dist < 0.8:
                    px(img, x, y, yellow)
                else:
                    px(img, x, y, light_yellow)

    for sx, sy in [(8, 6), (15, 2), (33, 2), (40, 6), (24, 1)]:
        px(img, sx, sy, white)
        px(img, sx + 1, sy, bright)
        px(img, sx, sy + 1, bright)

    save(img, "sword_arc.png")


# ============================================================
# 8. ARROW (16x6) - Sharper tip, better fletching
# ============================================================
def generate_arrow():
    img = Image.new("RGBA", (16, 6), (0, 0, 0, 0))

    shaft_lt = (160, 110, 55, 255)
    shaft = (135, 88, 38, 255)
    shaft_dk = (100, 62, 22, 255)
    tip_hi = (210, 215, 225, 255)
    tip = (170, 175, 185, 255)
    tip_dk = (130, 135, 145, 255)
    fletch_red = (210, 50, 50, 255)
    fletch_dk = (160, 30, 30, 255)

    # Shaft
    fill_rect(img, 3, 2, 12, 3, shaft)
    fill_rect(img, 3, 2, 12, 2, shaft_lt)
    fill_rect(img, 3, 3, 12, 3, shaft_dk)

    # Arrowhead (triangular, sharper)
    px(img, 0, 2, tip_hi)
    px(img, 0, 3, tip)
    px(img, 1, 1, tip)
    px(img, 1, 2, tip_hi)
    px(img, 1, 3, tip)
    px(img, 1, 4, tip_dk)
    px(img, 2, 2, tip)
    px(img, 2, 3, tip_dk)
    # Arrowhead edges
    px(img, 2, 1, tip_dk)
    px(img, 2, 4, tip_dk)

    # Fletching (feathered)
    px(img, 13, 1, fletch_red)
    px(img, 13, 2, fletch_red)
    px(img, 13, 3, fletch_red)
    px(img, 13, 4, fletch_dk)
    px(img, 14, 0, fletch_red)
    px(img, 14, 1, fletch_dk)
    px(img, 14, 4, fletch_dk)
    px(img, 14, 5, fletch_red)
    px(img, 15, 0, fletch_dk)
    px(img, 15, 5, fletch_dk)
    # Nock
    px(img, 12, 2, shaft_dk)
    px(img, 12, 3, shaft_dk)

    add_outline(img)
    save(img, "arrow.png")


# ============================================================
# 9. FIREBALL (20x20) - More flame layers, heat distortion
# ============================================================
def generate_fireball():
    img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))

    white_hot = (255, 255, 240, 255)
    yellow = (255, 245, 120, 255)
    bright_orange = (255, 190, 40, 255)
    orange = (255, 130, 25, 255)
    red_orange = (240, 80, 20, 255)
    red = (210, 40, 15, 255)
    dark_red = (150, 20, 8, 255)
    smoke = (80, 30, 10, 140)

    # Outer smoke/heat wisps
    smoke_positions = [
        (3, 1), (16, 1), (1, 5), (18, 5),
        (0, 10), (19, 10), (1, 14), (18, 14),
        (3, 18), (16, 18), (7, 0), (12, 0),
        (7, 19), (12, 19),
    ]
    for sx, sy in smoke_positions:
        px(img, sx, sy, smoke)

    # Outer dark red flame
    draw_ellipse_filled(img, 2, 2, 17, 17, dark_red)

    # Red flame ring
    draw_ellipse_filled(img, 3, 3, 16, 16, red)

    # Red-orange ring
    draw_ellipse_filled(img, 4, 4, 15, 15, red_orange)

    # Orange middle
    draw_ellipse_filled(img, 5, 5, 14, 14, orange)

    # Bright orange inner
    draw_ellipse_filled(img, 6, 6, 13, 13, bright_orange)

    # Yellow inner core
    draw_ellipse_filled(img, 7, 7, 12, 12, yellow)

    # White-hot center
    draw_ellipse_filled(img, 8, 8, 11, 11, white_hot)

    # Flame tendrils (asymmetric for motion feel)
    tendrils = [
        # Top tendrils
        (8, 1, red), (9, 0, dark_red), (10, 1, red_orange),
        (5, 2, red), (14, 2, red_orange),
        # Side tendrils
        (1, 8, red), (0, 9, dark_red),
        (18, 8, red), (19, 9, dark_red),
        (1, 12, red_orange), (18, 12, red),
        # Bottom tendrils
        (6, 17, red), (7, 18, dark_red),
        (13, 17, red), (12, 18, dark_red),
        # Diagonal wisps
        (3, 3, red_orange), (16, 3, red),
        (3, 16, red), (16, 16, red_orange),
    ]
    for tx, ty, tc in tendrils:
        px(img, tx, ty, tc)

    # Heat shimmer effect (semi-transparent outer glow)
    glow_positions = [
        (4, 0), (15, 0), (0, 4), (19, 4),
        (0, 15), (19, 15), (4, 19), (15, 19),
    ]
    for gx, gy in glow_positions:
        px(img, gx, gy, (255, 150, 30, 60))

    save(img, "fireball.png")


# ============================================================
# 10. BONE (16x8) - Cracked texture, sharper knobs
# ============================================================
def generate_bone():
    img = Image.new("RGBA", (16, 8), (0, 0, 0, 0))

    bone_hi = (250, 245, 240, 255)
    bone_lt = (240, 235, 225, 255)
    bone = (220, 210, 190, 255)
    bone_md = (195, 185, 165, 255)
    bone_dk = (165, 155, 135, 255)
    bone_vdk = (130, 120, 100, 255)
    crack = (140, 130, 110, 255)

    # Left knob (rounder, more detailed)
    fill_rect(img, 1, 1, 3, 2, bone_lt)
    fill_rect(img, 1, 3, 3, 4, bone)
    fill_rect(img, 0, 2, 0, 3, bone_md)
    fill_rect(img, 1, 5, 3, 6, bone_md)
    fill_rect(img, 0, 4, 0, 5, bone_dk)
    px(img, 1, 0, bone_hi)
    px(img, 2, 0, bone_lt)
    px(img, 1, 7, bone_dk)
    px(img, 2, 7, bone_vdk)
    # Left knob highlight
    px(img, 1, 1, bone_hi)
    px(img, 3, 5, bone_dk)
    px(img, 3, 6, bone_vdk)

    # Shaft (with crack)
    fill_rect(img, 4, 3, 11, 4, bone)
    fill_rect(img, 4, 3, 11, 3, bone_lt)
    fill_rect(img, 4, 4, 11, 4, bone_dk)
    # Crack detail
    px(img, 7, 3, crack)
    px(img, 8, 4, crack)
    px(img, 6, 4, bone_vdk)

    # Right knob
    fill_rect(img, 12, 1, 14, 2, bone_lt)
    fill_rect(img, 12, 3, 14, 4, bone)
    fill_rect(img, 15, 2, 15, 3, bone_md)
    fill_rect(img, 12, 5, 14, 6, bone_md)
    fill_rect(img, 15, 4, 15, 5, bone_dk)
    px(img, 12, 0, bone_lt)
    px(img, 13, 0, bone_hi)
    px(img, 12, 7, bone_dk)
    px(img, 13, 7, bone_vdk)
    # Right knob shadow
    px(img, 14, 2, bone_md)
    px(img, 14, 5, bone_dk)
    px(img, 14, 6, bone_vdk)

    add_outline(img)
    save(img, "bone.png")


# ============================================================
# 11. SHIELD (16x16) - Better metallic sheen, rivets
# ============================================================
def generate_shield():
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))

    border_hi = (140, 145, 155, 255)
    border = (100, 100, 115, 255)
    border_dk = (65, 65, 80, 255)
    silver_hi = (230, 235, 245, 255)
    silver_lt = (210, 215, 225, 255)
    silver = (180, 185, 195, 255)
    silver_dk = (140, 145, 155, 255)
    silver_vdk = (105, 110, 120, 255)
    blue_hi = (100, 150, 255, 255)
    blue = (40, 80, 200, 255)
    blue_dk = (20, 50, 150, 255)
    rivet = (220, 215, 200, 255)
    rivet_dk = (160, 155, 140, 255)

    # Shield border
    draw_ellipse_filled(img, 1, 1, 14, 14, border)
    draw_ellipse_filled(img, 1, 1, 13, 13, border_hi)
    # Shield body
    draw_ellipse_filled(img, 2, 2, 13, 13, silver)
    # Highlight (top-left)
    draw_ellipse_filled(img, 2, 2, 9, 9, silver_lt)
    fill_rect(img, 3, 3, 6, 5, silver_hi)
    px(img, 4, 3, (245, 248, 255, 255))
    # Shadow (bottom-right)
    for y in range(9, 14):
        for x in range(9, 14):
            cx, cy = 7.5, 7.5
            if ((x - cx) ** 2 + (y - cy) ** 2) <= 36:
                px(img, x, y, silver_dk)
    for y in range(11, 14):
        for x in range(11, 14):
            cx, cy = 7.5, 7.5
            if ((x - cx) ** 2 + (y - cy) ** 2) <= 36:
                px(img, x, y, silver_vdk)

    # Center gem
    fill_rect(img, 6, 6, 9, 9, blue)
    px(img, 6, 6, blue_hi)
    px(img, 7, 6, blue_hi)
    px(img, 6, 7, blue_hi)
    px(img, 9, 9, blue_dk)
    px(img, 8, 9, blue_dk)
    px(img, 9, 8, blue_dk)
    # Gem sparkle
    px(img, 7, 7, (160, 200, 255, 255))

    # Rivets around the rim
    rivet_positions = [(4, 1), (11, 1), (1, 5), (14, 5),
                       (1, 10), (14, 10), (4, 14), (11, 14)]
    for rx, ry in rivet_positions:
        cx, cy = 7.5, 7.5
        if ((rx - cx) ** 2 + (ry - cy) ** 2) <= 49:
            px(img, rx, ry, rivet)
            # Rivet shadow (bottom-right)
            if rx < 8 and ry < 8:
                pass  # highlight side
            else:
                px(img, rx, ry, rivet_dk)

    # Cross embossing
    fill_rect(img, 7, 3, 8, 5, silver_lt)
    fill_rect(img, 7, 10, 8, 12, silver_dk)
    fill_rect(img, 3, 7, 5, 8, silver_lt)
    fill_rect(img, 10, 7, 12, 8, silver_dk)

    add_outline(img)
    save(img, "shield.png")


# ============================================================
# 12. LIGHTNING (16x48) - Impactful vertical bolt with glow
# ============================================================
def generate_lightning():
    img = Image.new("RGBA", (16, 48), (0, 0, 0, 0))

    white = (255, 255, 255, 255)
    core = (230, 245, 255, 255)
    bright_yellow = (255, 255, 140, 255)
    yellow = (255, 235, 60, 255)
    dark_yellow = (220, 190, 30, 255)
    glow = (255, 255, 200, 100)
    glow_outer = (180, 200, 255, 45)
    spark = (210, 230, 255, 255)
    impact_white = (255, 255, 230, 255)
    impact_yellow = (255, 245, 120, 200)

    # Main jagged bolt path - zigzags down from top to bottom center
    bolt_path = [
        (8, 0), (8, 1), (9, 2), (9, 3),
        (7, 4), (6, 5), (5, 6), (5, 7),
        (6, 8), (7, 9), (8, 10), (9, 11), (10, 12),
        (9, 13), (8, 14), (7, 15), (6, 16), (5, 17),
        (5, 18), (6, 19), (7, 20), (8, 21), (9, 22),
        (10, 23), (10, 24),
        (9, 25), (8, 26), (7, 27), (6, 28), (5, 29),
        (5, 30), (6, 31), (7, 32), (8, 33), (9, 34),
        (9, 35), (8, 36), (7, 37), (7, 38), (8, 39),
        (8, 40), (8, 41), (8, 42),
    ]

    # Outer glow (widest, blue-tinted, faint)
    for bx, by in bolt_path:
        for dx in range(-4, 5):
            for dy in [-1, 0, 1]:
                if abs(dx) >= 2:
                    px(img, bx + dx, by + dy, glow_outer)

    # Inner glow (warm)
    for bx, by in bolt_path:
        for dx in [-2, -1, 0, 1, 2]:
            for dy in [-1, 0, 1]:
                if abs(dx) == 2 or abs(dy) == 1:
                    px(img, bx + dx, by + dy, glow)

    # Yellow body (3px wide)
    for bx, by in bolt_path:
        px(img, bx - 1, by, yellow)
        px(img, bx, by, bright_yellow)
        px(img, bx + 1, by, yellow)

    # Bright core
    for bx, by in bolt_path:
        px(img, bx, by, core)

    # White-hot center (every other pixel for shimmer)
    for i, (bx, by) in enumerate(bolt_path):
        if i % 2 == 0:
            px(img, bx, by, white)

    # Branch sparks (small jagged offshoots)
    branches = [
        # (start_x, start_y, dx, dy, length)
        (5, 7, -1, 1, 4),
        (10, 12, 1, 0, 3),
        (5, 17, -1, -1, 3),
        (10, 24, 1, 1, 3),
        (5, 30, -1, 0, 3),
        (9, 35, 1, -1, 2),
    ]
    for sx, sy, dx, dy, length in branches:
        for i in range(length):
            bx = sx + dx * i
            by = sy + dy * i
            if i == 0:
                px(img, bx, by, spark)
            else:
                px(img, bx, by, yellow)
                # Add a glow pixel beside each branch segment
                px(img, bx + (1 if dx <= 0 else -1), by, glow)

    # Extra isolated spark dots
    spark_positions = [
        (2, 6), (13, 11), (2, 17), (13, 23), (2, 29), (12, 35),
        (4, 3), (11, 8), (3, 22), (12, 28),
    ]
    for sx, sy in spark_positions:
        px(img, sx, sy, spark)

    # Impact glow at bottom (bright radial burst)
    impact_cx, impact_cy = 8, 44
    for dy in range(-4, 5):
        for dx in range(-5, 6):
            dist = (dx * dx + dy * dy) ** 0.5
            if dist <= 5.0:
                ix, iy = impact_cx + dx, impact_cy + dy
                if dist < 1.5:
                    px(img, ix, iy, impact_white)
                elif dist < 3.0:
                    px(img, ix, iy, bright_yellow)
                elif dist < 4.0:
                    px(img, ix, iy, impact_yellow)
                else:
                    px(img, ix, iy, glow)

    # Ground sparks radiating from impact
    ground_sparks = [
        (4, 45), (5, 46), (3, 47), (12, 45), (11, 46), (13, 47),
        (6, 47), (10, 47), (8, 47),
    ]
    for gx, gy in ground_sparks:
        px(img, gx, gy, yellow)

    save(img, "lightning.png")


# ============================================================
# 13. XP ORB (12x12) - More facets, brighter glow
# ============================================================
def generate_xp_orb():
    img = Image.new("RGBA", (12, 12), (0, 0, 0, 0))

    white = (240, 255, 255, 255)
    cyan_hi = (140, 250, 255, 255)
    cyan_lt = (80, 230, 245, 255)
    cyan = (20, 200, 220, 255)
    cyan_md = (10, 160, 180, 255)
    cyan_dk = (0, 120, 150, 255)
    cyan_vdk = (0, 80, 110, 255)
    glow = (0, 200, 255, 60)
    glow_bright = (80, 230, 255, 100)

    diamond_rows = {
        0: (5, 6),
        1: (4, 7),
        2: (3, 8),
        3: (2, 9),
        4: (1, 10),
        5: (1, 10),
        6: (1, 10),
        7: (2, 9),
        8: (3, 8),
        9: (4, 7),
        10: (5, 6),
        11: (5, 6),
    }

    # Outer glow aura
    for y, (x_start, x_end) in diamond_rows.items():
        for x in range(max(0, x_start - 2), min(12, x_end + 3)):
            if not (x_start <= x <= x_end):
                px(img, x, y, glow)
    # Brighter inner glow
    for y, (x_start, x_end) in diamond_rows.items():
        for x in range(max(0, x_start - 1), min(12, x_end + 2)):
            if not (x_start <= x <= x_end):
                px(img, x, y, glow_bright)

    # Fill diamond with gradient
    for y, (x_start, x_end) in diamond_rows.items():
        for x in range(x_start, x_end + 1):
            # Distance-based gradient from top-left
            d = ((x - 4) ** 2 + (y - 3) ** 2) ** 0.5
            if d < 2:
                px(img, x, y, cyan_hi)
            elif d < 3.5:
                px(img, x, y, cyan_lt)
            elif d < 5:
                px(img, x, y, cyan)
            elif d < 7:
                px(img, x, y, cyan_md)
            else:
                px(img, x, y, cyan_dk)

    # Facet lines (crystal-like)
    # Horizontal facet
    for y_row in [5, 6]:
        xs, xe = diamond_rows[y_row]
        for x in range(xs, xe + 1):
            c = get_px(img, x, y_row)
            if c[3] > 0:
                darker = tuple(max(0, c[i] - 25) for i in range(3)) + (255,)
                px(img, x, y_row, darker)
    # Vertical facet
    for y in range(12):
        xs, xe = diamond_rows[y]
        mid = (xs + xe) // 2
        if xs <= mid <= xe:
            c = get_px(img, mid, y)
            if c[3] > 0:
                darker = tuple(max(0, c[i] - 20) for i in range(3)) + (255,)
                px(img, mid, y, darker)

    # White specular
    px(img, 5, 1, white)
    px(img, 5, 2, white)
    px(img, 4, 2, white)
    px(img, 4, 3, cyan_hi)

    # Deep shadow corner
    for y in range(8, 11):
        xs, xe = diamond_rows[y]
        px(img, xe, y, cyan_vdk)

    save(img, "xp_orb.png")


# ============================================================
# 14. CHEST (24x20) - Wood grain, better lock, gems
# ============================================================
def generate_chest():
    img = Image.new("RGBA", (24, 20), (0, 0, 0, 0))

    wood_hi = (175, 115, 60, 255)
    wood_lt = (155, 95, 45, 255)
    wood = (125, 75, 32, 255)
    wood_md = (100, 58, 22, 255)
    wood_dk = (75, 42, 14, 255)
    wood_vdk = (50, 28, 8, 255)
    gold_hi = (255, 225, 90, 255)
    gold_lt = (240, 200, 60, 255)
    gold = (210, 170, 35, 255)
    gold_dk = (170, 130, 20, 255)
    gold_vdk = (130, 95, 10, 255)
    lock_dark = (25, 18, 8, 255)
    gem_red = (220, 40, 40, 255)
    gem_red_hi = (255, 100, 90, 255)
    gem_green = (40, 200, 60, 255)
    gem_green_hi = (100, 255, 120, 255)

    # === Chest body (lower half, rows 10-19) ===
    fill_rect(img, 1, 10, 22, 18, wood)
    # Front face with wood grain
    fill_rect(img, 1, 11, 5, 18, wood_lt)
    dither_rect(img, 6, 11, 10, 18, wood_lt, wood, "horizontal")
    fill_rect(img, 18, 11, 22, 18, wood_dk)
    dither_rect(img, 14, 14, 22, 18, wood, wood_dk, "horizontal")
    # Wood grain lines
    for y in [12, 15, 17]:
        fill_rect(img, 2, y, 21, y, wood_md)
    # Bottom edge
    fill_rect(img, 0, 19, 23, 19, wood_vdk)
    fill_rect(img, 0, 18, 0, 19, wood_vdk)
    fill_rect(img, 23, 18, 23, 19, wood_vdk)

    # Gold trim on body top
    fill_rect(img, 1, 10, 22, 10, gold)
    fill_rect(img, 1, 10, 8, 10, gold_lt)
    fill_rect(img, 18, 10, 22, 10, gold_dk)
    px(img, 0, 10, gold_dk)
    px(img, 23, 10, gold_vdk)

    # === Lid (top half, rows 1-9) ===
    fill_rect(img, 2, 3, 21, 4, wood)
    fill_rect(img, 1, 5, 22, 9, wood)
    fill_rect(img, 3, 2, 20, 2, wood)
    fill_rect(img, 5, 1, 18, 1, wood_lt)
    # Lid highlight
    fill_rect(img, 2, 3, 10, 5, wood_lt)
    fill_rect(img, 5, 1, 12, 2, wood_hi)
    fill_rect(img, 3, 2, 8, 3, wood_hi)
    dither_rect(img, 11, 3, 15, 5, wood_lt, wood)
    # Lid shadow
    fill_rect(img, 17, 6, 22, 9, wood_dk)
    fill_rect(img, 20, 5, 22, 9, wood_vdk)
    dither_rect(img, 15, 7, 19, 9, wood, wood_dk)

    # Gold trim on lid bottom
    fill_rect(img, 1, 9, 22, 9, gold)
    fill_rect(img, 1, 9, 8, 9, gold_lt)
    fill_rect(img, 18, 9, 22, 9, gold_dk)
    # Gold trim on lid arch
    fill_rect(img, 5, 1, 18, 1, gold)
    fill_rect(img, 3, 2, 20, 2, gold)
    fill_rect(img, 3, 2, 10, 2, gold_lt)
    fill_rect(img, 16, 2, 20, 2, gold_dk)

    # === Lock/Clasp ===
    fill_rect(img, 9, 8, 14, 13, gold)
    fill_rect(img, 10, 9, 13, 12, gold_lt)
    fill_rect(img, 10, 9, 11, 10, gold_hi)
    fill_rect(img, 12, 11, 13, 12, gold_dk)
    # Keyhole
    px(img, 11, 10, lock_dark)
    px(img, 12, 10, lock_dark)
    px(img, 11, 11, lock_dark)
    px(img, 12, 11, lock_dark)
    px(img, 11, 12, lock_dark)

    # Metal bands
    fill_rect(img, 1, 14, 22, 14, gold_dk)
    fill_rect(img, 1, 14, 8, 14, gold)
    fill_rect(img, 1, 6, 22, 6, gold_dk)
    fill_rect(img, 1, 6, 8, 6, gold)

    # Corner studs
    for cx, cy in [(2, 11), (21, 11), (2, 17), (21, 17)]:
        px(img, cx, cy, gold_hi)

    # Gems on front
    px(img, 5, 16, gem_red)
    px(img, 5, 15, gem_red_hi)
    px(img, 18, 16, gem_green)
    px(img, 18, 15, gem_green_hi)

    add_outline(img)
    save(img, "chest.png")


# ============================================================
# 15. ROCK (32x32) - Dark cavern boulder
# ============================================================
def generate_rock():
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))

    stone_hi = (110, 105, 95, 255)
    stone_lt = (90, 85, 78, 255)
    stone = (70, 65, 60, 255)
    stone_md = (55, 50, 48, 255)
    stone_dk = (40, 36, 34, 255)
    stone_vdk = (25, 22, 20, 255)
    moss = (45, 75, 35, 255)
    moss_lt = (60, 95, 45, 255)
    crack_color = (30, 27, 25, 255)

    # Build irregular boulder shape using overlapping ellipses
    # Main body
    draw_ellipse_filled(img, 3, 5, 28, 28, stone)
    draw_ellipse_filled(img, 5, 3, 26, 26, stone)
    draw_ellipse_filled(img, 2, 8, 29, 30, stone_md)

    # Top highlight region
    draw_ellipse_filled(img, 5, 4, 20, 16, stone_lt)
    fill_rect(img, 7, 5, 16, 10, stone_hi)
    dither_rect(img, 8, 6, 14, 8, stone_hi, stone_lt)
    # Specular
    fill_rect(img, 9, 6, 12, 7, (130, 125, 115, 255))

    # Shadow regions (bottom-right)
    draw_ellipse_filled(img, 14, 18, 29, 30, stone_dk)
    fill_rect(img, 20, 22, 28, 29, stone_vdk)
    dither_rect(img, 16, 20, 24, 26, stone_md, stone_dk)

    # Cracks
    crack_paths = [
        [(12, 12), (13, 13), (14, 14), (13, 15), (12, 16)],
        [(18, 10), (19, 11), (20, 12), (21, 13)],
        [(8, 18), (9, 19), (10, 20), (10, 21)],
    ]
    for path in crack_paths:
        for cx, cy in path:
            px(img, cx, cy, crack_color)

    # Moss highlights (top-left)
    moss_positions = [
        (5, 10), (6, 10), (6, 11), (4, 12),
        (5, 22), (6, 22), (7, 23), (5, 23),
        (3, 15), (3, 16),
    ]
    for mx, my in moss_positions:
        if get_px(img, mx, my)[3] > 0:
            px(img, mx, my, moss)
    # Lighter moss spots
    for mx, my in [(5, 10), (6, 22)]:
        if get_px(img, mx, my)[3] > 0:
            px(img, mx, my, moss_lt)

    # Texture dithering for rocky feel
    for y in range(32):
        for x in range(32):
            r, g, b, a = get_px(img, x, y)
            if a > 0 and (x + y) % 5 == 0:
                # Subtle noise
                px(img, x, y, (max(0, r - 8), max(0, g - 8), max(0, b - 8), a))

    add_outline(img)
    save(img, "rock.png")


# ============================================================
# 16. CAVERN FLOOR TILE (64x64) - Dark stone tiling texture
# ============================================================
def generate_cavern_floor():
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))

    # Base dark stone colors
    floor_hi = (55, 48, 58, 255)
    floor_lt = (48, 42, 52, 255)
    floor = (40, 35, 45, 255)
    floor_md = (34, 30, 38, 255)
    floor_dk = (28, 24, 32, 255)
    grout = (22, 18, 25, 255)
    highlight = (62, 55, 65, 255)

    # Fill base
    fill_rect(img, 0, 0, 63, 63, floor)

    # Subtle variation across the tile
    import random
    random.seed(42)  # Deterministic
    for y in range(64):
        for x in range(64):
            r = random.random()
            if r < 0.15:
                px(img, x, y, floor_lt)
            elif r < 0.25:
                px(img, x, y, floor_md)
            elif r < 0.30:
                px(img, x, y, floor_dk)

    # Stone tile grid lines (grout) - every 16px
    for gx in range(0, 64, 16):
        for y in range(64):
            px(img, gx, y, grout)
            if gx + 1 < 64:
                px(img, gx + 1, y, floor_dk)
    for gy in range(0, 64, 16):
        for x in range(64):
            px(img, x, gy, grout)
            if gy + 1 < 64:
                px(img, x, gy + 1, floor_dk)

    # Offset every other row of tiles (brick pattern)
    for gy in [16, 48]:
        for x in range(0, 64):
            px(img, x, gy, grout)

    # Add subtle highlight along top-left edges of each tile
    for gx in range(0, 64, 16):
        for gy in range(0, 64, 16):
            # Top edge highlight
            for x in range(gx + 2, min(gx + 15, 64)):
                if gy + 1 < 64:
                    px(img, x, gy + 1, floor_lt)
            # Left edge highlight
            for y in range(gy + 2, min(gy + 15, 64)):
                if gx + 1 < 64:
                    px(img, gx + 1, y, floor_lt)

    # Scattered darker patches (depth variations)
    patches = [(8, 8, 5), (35, 12, 4), (50, 40, 6), (15, 45, 4), (42, 25, 3)]
    for px_c, py_c, radius in patches:
        for dy in range(-radius, radius + 1):
            for dx in range(-radius, radius + 1):
                if dx * dx + dy * dy <= radius * radius:
                    x, y = px_c + dx, py_c + dy
                    if 0 <= x < 64 and 0 <= y < 64:
                        c = get_px(img, x, y)
                        if c[3] > 0:
                            px(img, x, y, (max(0, c[0] - 6), max(0, c[1] - 6), max(0, c[2] - 6), 255))

    # Lighter stone highlights (occasional bright spots)
    light_spots = [(20, 20), (45, 10), (10, 50), (55, 55), (30, 35)]
    for lx, ly in light_spots:
        px(img, lx, ly, highlight)
        px(img, lx + 1, ly, floor_lt)
        px(img, lx, ly + 1, floor_lt)

    save(img, "cavern_floor.png")


# ============================================================
# 17. ORBIT PROJECTILE (16x16) - Small blue/white glowing orb
# ============================================================
def generate_orbit_projectile():
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))

    # Blue/white glowing orb palette
    white_core = (255, 255, 255, 255)
    white_hot = (240, 248, 255, 255)
    ice_hi = (180, 220, 255, 255)
    ice_lt = (130, 190, 255, 255)
    ice = (80, 150, 255, 255)
    ice_md = (50, 110, 230, 255)
    ice_dk = (30, 70, 200, 255)
    ice_vdk = (15, 40, 160, 255)
    glow_bright = (100, 180, 255, 120)
    glow = (60, 130, 255, 70)
    glow_faint = (40, 100, 220, 35)

    # Outermost glow halo (very faint)
    draw_ellipse_filled(img, 0, 0, 15, 15, glow_faint)

    # Outer glow ring
    draw_ellipse_filled(img, 1, 1, 14, 14, glow)

    # Brighter inner glow
    draw_ellipse_filled(img, 2, 2, 13, 13, glow_bright)

    # Darkest visible ring
    draw_ellipse_filled(img, 3, 3, 12, 12, ice_vdk)

    # Dark blue ring
    draw_ellipse_filled(img, 4, 4, 11, 11, ice_dk)

    # Mid blue body
    draw_ellipse_filled(img, 4, 4, 11, 11, ice_md)

    # Blue body
    draw_ellipse_filled(img, 5, 5, 10, 10, ice)

    # Light blue inner
    draw_ellipse_filled(img, 5, 5, 9, 9, ice_lt)

    # Highlight region (top-left light source)
    draw_ellipse_filled(img, 5, 5, 8, 8, ice_hi)

    # White-hot core
    fill_rect(img, 6, 6, 8, 8, white_hot)
    fill_rect(img, 6, 6, 7, 7, white_core)

    # Specular highlight (bright white dot, top-left)
    px(img, 5, 4, white_core)
    px(img, 6, 4, white_hot)
    px(img, 4, 5, white_hot)
    px(img, 5, 5, white_core)

    # Shadow on bottom-right of the orb body
    px(img, 10, 10, ice_dk)
    px(img, 11, 10, ice_vdk)
    px(img, 10, 11, ice_vdk)
    px(img, 9, 10, ice_md)
    px(img, 10, 9, ice_md)

    # Sparkle points around the glow
    sparkle_positions = [(2, 3), (12, 2), (3, 12), (13, 11), (7, 1), (1, 7), (14, 8), (8, 14)]
    for sx, sy in sparkle_positions:
        px(img, sx, sy, ice_hi)

    # Energy wisps (small bright dots in the glow field)
    wisp_positions = [(1, 5), (5, 1), (10, 1), (14, 6), (14, 10), (10, 14), (1, 10)]
    for wx, wy in wisp_positions:
        px(img, wx, wy, (160, 210, 255, 160))

    save(img, "orbit_projectile.png")


# ============================================================
# 18. AURA (64x64) - Translucent green/white radial circle
# ============================================================
def generate_aura():
    size = 64
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    cx, cy = size // 2, size // 2
    outer_r = 30.0
    inner_r = 22.0

    # Palette: soft green-white glow, subtle and translucent
    for y in range(size):
        for x in range(size):
            dx = x - cx
            dy = y - cy
            dist = (dx * dx + dy * dy) ** 0.5

            if dist > outer_r + 2:
                continue

            # Outermost faint glow fringe (soft edge)
            if dist > outer_r:
                t = (dist - outer_r) / 2.0
                alpha = int(20 * (1.0 - t))
                if alpha > 0:
                    px(img, x, y, (180, 255, 200, alpha))
                continue

            # Main ring region (between inner_r and outer_r)
            if dist >= inner_r:
                # Band position: 0 at inner_r, 1 at outer_r
                band_t = (dist - inner_r) / (outer_r - inner_r)

                # Ring is brightest in the middle of the band
                mid_dist = abs(band_t - 0.5) * 2.0  # 0 at center, 1 at edges

                if mid_dist < 0.3:
                    # Bright core of the ring
                    alpha = 90
                    r, g, b = 220, 255, 230
                elif mid_dist < 0.6:
                    alpha = 65
                    r, g, b = 180, 240, 200
                elif mid_dist < 0.85:
                    alpha = 40
                    r, g, b = 140, 220, 170
                else:
                    alpha = 22
                    r, g, b = 120, 200, 150

                # Dither pattern for subtle texture
                if (x + y) % 3 == 0:
                    alpha = max(0, alpha - 10)

                px(img, x, y, (r, g, b, alpha))

            # Interior fill (very subtle inner glow)
            elif dist >= inner_r - 6:
                fade_t = (inner_r - dist) / 6.0  # 0 at inner_r, 1 deeper inside
                alpha = int(18 * (1.0 - fade_t))
                if alpha > 0 and (x + y) % 2 == 0:
                    px(img, x, y, (160, 230, 180, alpha))

    # Add a few sparkle points along the ring for visual interest
    sparkle_angles = [0.0, 0.7, 1.4, 2.1, 2.8, 3.5, 4.2, 4.9, 5.6]
    sparkle_r = (inner_r + outer_r) / 2.0
    for angle in sparkle_angles:
        sx = int(cx + math.cos(angle) * sparkle_r)
        sy = int(cy + math.sin(angle) * sparkle_r)
        px(img, sx, sy, (255, 255, 255, 110))
        # Adjacent glow
        for ddx, ddy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            px(img, sx + ddx, sy + ddy, (220, 255, 230, 70))

    save(img, "aura.png")


# ============================================================
# 19. PASSIVE ITEM: SPINACH (20x20) - Green leafy vegetable
# ============================================================
def generate_passive_spinach():
    img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))

    green_hi = (100, 210, 80, 255)
    green_lt = (70, 180, 55, 255)
    green = (34, 140, 34, 255)
    green_md = (25, 110, 25, 255)
    green_dk = (15, 80, 15, 255)
    green_vdk = (8, 55, 8, 255)
    stem = (80, 60, 20, 255)
    stem_lt = (110, 85, 35, 255)
    vein = (50, 160, 50, 255)

    # Stem (bottom center going up)
    fill_rect(img, 9, 14, 10, 19, stem)
    px(img, 9, 14, stem_lt)
    px(img, 10, 19, stem)

    # Main leaf (large teardrop shape)
    # Bottom of leaf
    fill_rect(img, 7, 11, 12, 13, green)
    fill_rect(img, 5, 8, 14, 10, green)
    fill_rect(img, 4, 5, 15, 7, green)
    fill_rect(img, 5, 3, 14, 4, green_lt)
    fill_rect(img, 7, 1, 12, 2, green_lt)
    fill_rect(img, 8, 0, 11, 0, green_hi)

    # Highlight (top-left light)
    fill_rect(img, 5, 3, 9, 5, green_hi)
    fill_rect(img, 4, 5, 8, 7, green_lt)
    dither_rect(img, 9, 3, 12, 6, green_hi, green_lt)

    # Shadow (bottom-right)
    fill_rect(img, 12, 8, 14, 10, green_dk)
    fill_rect(img, 13, 6, 15, 8, green_dk)
    fill_rect(img, 10, 11, 12, 13, green_md)
    px(img, 14, 9, green_vdk)

    # Central vein
    for y in range(2, 13):
        px(img, 9, y, vein)
    # Side veins
    px(img, 7, 5, vein)
    px(img, 8, 4, vein)
    px(img, 11, 5, vein)
    px(img, 12, 4, vein)
    px(img, 6, 8, vein)
    px(img, 7, 7, vein)
    px(img, 12, 8, vein)
    px(img, 13, 7, vein)

    # Specular highlight
    px(img, 6, 3, (180, 255, 170, 255))
    px(img, 7, 2, (180, 255, 170, 255))

    add_outline(img)
    save(img, "passive_spinach.png")


# ============================================================
# 20. PASSIVE ITEM: ARMOR (20x20) - Metal chest plate
# ============================================================
def generate_passive_armor():
    img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))

    metal_hi = (200, 210, 220, 255)
    metal_lt = (170, 180, 195, 255)
    metal = (130, 140, 155, 255)
    metal_md = (100, 110, 125, 255)
    metal_dk = (70, 75, 90, 255)
    metal_vdk = (45, 48, 60, 255)
    rivet = (220, 215, 200, 255)

    # Main chest plate shape
    fill_rect(img, 4, 3, 15, 16, metal)

    # Shoulder sections
    fill_rect(img, 2, 2, 5, 5, metal_lt)
    fill_rect(img, 14, 2, 17, 5, metal_md)

    # Highlight (top-left)
    fill_rect(img, 4, 3, 9, 7, metal_lt)
    fill_rect(img, 4, 3, 7, 5, metal_hi)
    dither_rect(img, 8, 3, 11, 6, metal_hi, metal_lt)
    px(img, 2, 2, metal_hi)
    px(img, 3, 2, metal_hi)

    # Shadow (bottom-right)
    fill_rect(img, 12, 12, 15, 16, metal_dk)
    fill_rect(img, 14, 10, 15, 16, metal_vdk)
    dither_rect(img, 10, 13, 13, 16, metal, metal_dk)

    # Center ridge
    fill_rect(img, 9, 3, 10, 16, metal_md)

    # Neck opening (top center)
    fill_rect(img, 7, 1, 12, 2, metal_dk)
    fill_rect(img, 8, 0, 11, 1, metal_vdk)

    # Bottom edge
    fill_rect(img, 4, 16, 15, 17, metal_dk)
    fill_rect(img, 5, 17, 14, 18, metal_vdk)

    # Waist taper
    fill_rect(img, 3, 14, 3, 16, metal_md)
    fill_rect(img, 16, 14, 16, 16, metal_dk)

    # Rivets
    for rx, ry in [(5, 4), (14, 4), (5, 15), (14, 15)]:
        px(img, rx, ry, rivet)

    # Plate line detail
    fill_rect(img, 4, 10, 15, 10, metal_dk)

    add_outline(img)
    save(img, "passive_armor.png")


# ============================================================
# 21. PASSIVE ITEM: WINGS (20x20) - Feathered wings
# ============================================================
def generate_passive_wings():
    img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))

    white = (255, 255, 255, 255)
    feather_hi = (220, 235, 250, 255)
    feather_lt = (180, 210, 240, 255)
    feather = (135, 185, 235, 255)
    feather_md = (100, 155, 210, 255)
    feather_dk = (70, 120, 180, 255)
    feather_vdk = (45, 85, 145, 255)

    # Left wing
    # Primary feathers (bottom, longest)
    fill_rect(img, 0, 10, 3, 16, feather_md)
    fill_rect(img, 1, 8, 5, 14, feather)
    fill_rect(img, 3, 6, 7, 12, feather_lt)
    fill_rect(img, 5, 5, 8, 10, feather_lt)

    # Left wing highlight
    fill_rect(img, 3, 6, 6, 8, feather_hi)
    px(img, 4, 5, feather_hi)
    px(img, 5, 4, white)
    px(img, 6, 5, white)

    # Left wing shadow
    fill_rect(img, 0, 14, 2, 16, feather_vdk)
    fill_rect(img, 1, 12, 3, 14, feather_dk)

    # Feather lines (left)
    for i in range(4):
        y = 7 + i * 2
        px(img, 2 + i, y, feather_dk)
        px(img, 3 + i, y, feather_md)

    # Right wing (mirror)
    fill_rect(img, 16, 10, 19, 16, feather_md)
    fill_rect(img, 14, 8, 18, 14, feather)
    fill_rect(img, 12, 6, 16, 12, feather_lt)
    fill_rect(img, 11, 5, 14, 10, feather_lt)

    # Right wing highlight
    fill_rect(img, 12, 6, 14, 8, feather_hi)
    px(img, 13, 5, feather_hi)

    # Right wing shadow
    fill_rect(img, 17, 14, 19, 16, feather_vdk)
    fill_rect(img, 16, 12, 18, 14, feather_dk)

    # Feather lines (right)
    for i in range(4):
        y = 7 + i * 2
        px(img, 16 - i, y, feather_dk)
        px(img, 15 - i, y, feather_md)

    # Center body connector
    fill_rect(img, 8, 7, 11, 12, feather_md)
    fill_rect(img, 8, 7, 10, 9, feather)
    fill_rect(img, 9, 11, 10, 12, feather_dk)

    add_outline(img)
    save(img, "passive_wings.png")


# ============================================================
# 22. PASSIVE ITEM: HOLLOW HEART (20x20) - Glowing red heart
# ============================================================
def generate_passive_hollow_heart():
    img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))

    red_hi = (255, 130, 140, 255)
    red_lt = (240, 80, 90, 255)
    red = (220, 40, 60, 255)
    red_md = (180, 25, 45, 255)
    red_dk = (140, 15, 30, 255)
    red_vdk = (100, 8, 20, 255)
    glow = (255, 100, 120, 100)
    highlight = (255, 180, 190, 255)

    # Heart shape using pixel art
    # Top lobes
    fill_rect(img, 2, 4, 5, 6, red)
    fill_rect(img, 6, 3, 9, 6, red)
    fill_rect(img, 10, 3, 13, 6, red)
    fill_rect(img, 14, 4, 17, 6, red)

    # Upper middle
    fill_rect(img, 1, 5, 18, 8, red)
    fill_rect(img, 2, 3, 4, 4, red_lt)
    fill_rect(img, 15, 3, 17, 4, red_md)

    # Middle
    fill_rect(img, 2, 9, 17, 11, red)

    # Lower taper
    fill_rect(img, 3, 12, 16, 13, red)
    fill_rect(img, 4, 14, 15, 14, red_md)
    fill_rect(img, 5, 15, 14, 15, red_md)
    fill_rect(img, 6, 16, 13, 16, red_dk)
    fill_rect(img, 7, 17, 12, 17, red_dk)
    fill_rect(img, 8, 18, 11, 18, red_vdk)
    fill_rect(img, 9, 19, 10, 19, red_vdk)

    # Highlight (top-left lobe)
    fill_rect(img, 3, 4, 5, 5, red_hi)
    fill_rect(img, 4, 3, 7, 4, red_lt)
    px(img, 3, 3, red_hi)
    px(img, 4, 3, highlight)
    px(img, 5, 3, red_hi)

    # Shadow (bottom-right)
    fill_rect(img, 14, 8, 17, 10, red_dk)
    fill_rect(img, 16, 6, 17, 8, red_dk)
    fill_rect(img, 15, 10, 17, 11, red_vdk)

    # Hollow center (darker inner area for "hollow" look)
    fill_rect(img, 7, 7, 12, 11, red_dk)
    fill_rect(img, 8, 8, 11, 10, red_vdk)
    # Inner glow
    px(img, 8, 8, red_md)
    px(img, 9, 9, (80, 5, 15, 255))
    px(img, 10, 9, (80, 5, 15, 255))

    # Specular
    px(img, 4, 4, highlight)
    px(img, 5, 4, (255, 200, 210, 255))

    add_outline(img)
    save(img, "passive_hollow_heart.png")


# ============================================================
# 23. PASSIVE ITEM: DUPLICATOR (20x20) - Double diamond / mirror
# ============================================================
def generate_passive_duplicator():
    img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))

    gold_hi = (255, 230, 100, 255)
    gold_lt = (240, 210, 70, 255)
    gold = (220, 180, 40, 255)
    gold_md = (190, 150, 30, 255)
    gold_dk = (150, 110, 20, 255)
    gold_vdk = (110, 80, 10, 255)
    gem_cyan = (100, 220, 255, 255)
    gem_cyan_hi = (180, 240, 255, 255)
    gem_cyan_dk = (40, 150, 200, 255)

    # Left diamond shape
    # Top point
    px(img, 5, 2, gold_lt)
    fill_rect(img, 4, 3, 6, 4, gold)
    fill_rect(img, 3, 5, 7, 7, gold)
    fill_rect(img, 2, 8, 8, 10, gold)
    fill_rect(img, 3, 11, 7, 13, gold)
    fill_rect(img, 4, 14, 6, 15, gold_md)
    px(img, 5, 16, gold_dk)

    # Left diamond highlight
    fill_rect(img, 3, 5, 5, 7, gold_lt)
    fill_rect(img, 2, 8, 4, 9, gold_hi)
    px(img, 4, 3, gold_hi)

    # Left diamond shadow
    fill_rect(img, 6, 11, 7, 13, gold_dk)
    fill_rect(img, 7, 9, 8, 10, gold_dk)
    px(img, 6, 15, gold_vdk)

    # Left gem center
    fill_rect(img, 4, 8, 6, 10, gem_cyan)
    px(img, 4, 8, gem_cyan_hi)
    px(img, 6, 10, gem_cyan_dk)

    # Right diamond shape (offset)
    px(img, 14, 4, gold_lt)
    fill_rect(img, 13, 5, 15, 6, gold)
    fill_rect(img, 12, 7, 16, 9, gold)
    fill_rect(img, 11, 10, 17, 12, gold)
    fill_rect(img, 12, 13, 16, 15, gold)
    fill_rect(img, 13, 16, 15, 17, gold_md)
    px(img, 14, 18, gold_dk)

    # Right diamond highlight
    fill_rect(img, 12, 7, 14, 9, gold_lt)
    fill_rect(img, 11, 10, 13, 11, gold_hi)
    px(img, 13, 5, gold_hi)

    # Right diamond shadow
    fill_rect(img, 15, 13, 16, 15, gold_dk)
    fill_rect(img, 16, 11, 17, 12, gold_dk)
    px(img, 15, 17, gold_vdk)

    # Right gem center
    fill_rect(img, 13, 10, 15, 12, gem_cyan)
    px(img, 13, 10, gem_cyan_hi)
    px(img, 15, 12, gem_cyan_dk)

    # Connection sparkle between the two
    px(img, 9, 9, gold_hi)
    px(img, 10, 10, gold_lt)
    px(img, 8, 8, (255, 255, 200, 180))
    px(img, 10, 8, (255, 255, 200, 120))
    px(img, 8, 10, (255, 255, 200, 120))

    add_outline(img)
    save(img, "passive_duplicator.png")


# ============================================================
# 24. PASSIVE ITEM: TOME (20x20) - Magic spell book
# ============================================================
def generate_passive_tome():
    img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))

    cover_hi = (140, 70, 30, 255)
    cover_lt = (120, 55, 20, 255)
    cover = (95, 42, 12, 255)
    cover_md = (75, 32, 8, 255)
    cover_dk = (55, 22, 5, 255)
    cover_vdk = (35, 14, 2, 255)
    page_hi = (255, 250, 240, 255)
    page = (240, 235, 220, 255)
    page_dk = (215, 210, 195, 255)
    page_vdk = (190, 185, 170, 255)
    gold = (210, 175, 40, 255)
    gold_hi = (245, 215, 80, 255)
    magic_blue = (80, 140, 255, 255)
    magic_lt = (140, 180, 255, 255)

    # Book spine (left side)
    fill_rect(img, 2, 2, 4, 17, cover)
    fill_rect(img, 2, 2, 3, 8, cover_lt)
    fill_rect(img, 2, 2, 2, 5, cover_hi)
    fill_rect(img, 4, 12, 4, 17, cover_dk)

    # Front cover
    fill_rect(img, 5, 1, 16, 16, cover)
    # Cover highlight
    fill_rect(img, 5, 1, 10, 5, cover_lt)
    fill_rect(img, 5, 1, 8, 3, cover_hi)
    dither_rect(img, 9, 1, 12, 4, cover_hi, cover_lt)
    # Cover shadow
    fill_rect(img, 13, 11, 16, 16, cover_dk)
    fill_rect(img, 15, 8, 16, 16, cover_vdk)
    dither_rect(img, 12, 13, 15, 16, cover, cover_dk)

    # Page edges (visible from side, between covers)
    fill_rect(img, 5, 17, 16, 18, page)
    fill_rect(img, 5, 17, 10, 17, page_hi)
    fill_rect(img, 13, 18, 16, 18, page_dk)

    # Back cover edge (bottom)
    fill_rect(img, 5, 19, 16, 19, cover_dk)

    # Gold corner decorations on cover
    fill_rect(img, 5, 1, 7, 2, gold)
    fill_rect(img, 14, 1, 16, 2, gold)
    fill_rect(img, 5, 15, 7, 16, gold)
    fill_rect(img, 14, 15, 16, 16, gold)
    px(img, 5, 1, gold_hi)
    px(img, 14, 1, gold_hi)

    # Gold clasp
    fill_rect(img, 16, 7, 17, 11, gold)
    fill_rect(img, 17, 8, 17, 10, gold_hi)

    # Magic symbol on cover (simple star/glyph)
    px(img, 10, 5, magic_blue)
    px(img, 9, 6, magic_blue)
    px(img, 10, 6, magic_lt)
    px(img, 11, 6, magic_blue)
    px(img, 8, 7, magic_blue)
    px(img, 10, 7, magic_blue)
    px(img, 12, 7, magic_blue)
    px(img, 9, 8, magic_blue)
    px(img, 10, 8, magic_lt)
    px(img, 11, 8, magic_blue)
    px(img, 10, 9, magic_blue)
    px(img, 8, 10, magic_blue)
    px(img, 12, 10, magic_blue)
    px(img, 9, 11, magic_blue)
    px(img, 11, 11, magic_blue)
    px(img, 10, 12, magic_blue)

    # Magic glow
    px(img, 10, 6, (200, 220, 255, 255))
    px(img, 10, 8, (200, 220, 255, 255))

    add_outline(img)
    save(img, "passive_tome.png")


# ============================================================
# MAIN - Generate all sprites
# ============================================================
def main():
    print("=== Dragon Survivors Enhanced Sprite Generator ===\n")
    print("Output directory:", OUTPUT_DIR)
    print()

    print("[Characters]")
    generate_knight()
    generate_archer()

    print("\n[Enemies]")
    generate_slime()
    generate_skeleton()
    generate_armored_knight()
    generate_dragon()

    print("\n[Weapon Effects]")
    generate_sword_arc()
    generate_arrow()
    generate_fireball()
    generate_bone()
    generate_shield()
    generate_lightning()
    generate_orbit_projectile()
    generate_aura()

    print("\n[Pickups]")
    generate_xp_orb()
    generate_chest()

    print("\n[Passive Items]")
    generate_passive_spinach()
    generate_passive_armor()
    generate_passive_wings()
    generate_passive_hollow_heart()
    generate_passive_duplicator()
    generate_passive_tome()

    print("\n[Environment]")
    generate_rock()
    generate_cavern_floor()

    print(f"\nDone! Generated 24 sprites in {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
