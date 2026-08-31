#!/usr/bin/env python3
"""Генератор иконки приложения «Копилка».

Рисует монету с прорезью внутри золотого кольца прогресса на тёмном фоне.
Запуск: python3 Tools/generate_app_icon.py
Результат: Kopilka/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png (1024×1024)
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

SUPERSAMPLE = 4
SIZE = 1024
S = SIZE * SUPERSAMPLE

OUTPUT = Path(__file__).resolve().parent.parent / (
    "Kopilka/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
)


def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def vertical_gradient(size, top, bottom):
    image = Image.new("RGB", (size, size), top)
    draw = ImageDraw.Draw(image)
    for y in range(size):
        draw.line([(0, y), (size, y)], fill=lerp(top, bottom, y / max(size - 1, 1)))
    return image


def diagonal_gradient(size, start, end):
    image = Image.new("RGB", (size, size), start)
    draw = ImageDraw.Draw(image)
    for i in range(2 * size):
        draw.line([(i, 0), (0, i)], fill=lerp(start, end, i / max(2 * size - 1, 1)))
    return image


def radial_glow(size, color, radius, center, strength=120):
    layer = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(layer)
    cx, cy = center
    draw.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=strength)
    layer = layer.filter(ImageFilter.GaussianBlur(radius * 0.45))
    glow = Image.new("RGB", (size, size), color)
    return glow, layer


def build():
    canvas = vertical_gradient(S, (0x25, 0x23, 0x2E), (0x0A, 0x0B, 0x10))

    # Тёплое свечение за монетой.
    glow, mask = radial_glow(S, (0xE0, 0xA6, 0x4C), int(S * 0.36), (S // 2, int(S * 0.47)), 110)
    canvas = Image.composite(Image.blend(canvas, glow, 0.55), canvas, mask)

    # Кольцо прогресса: дуга 280°, золотой градиент по сегментам.
    ring = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ring_draw = ImageDraw.Draw(ring)
    inset = int(S * 0.135)
    box = [inset, inset, S - inset, S - inset]
    width = int(S * 0.062)
    start_angle, sweep, steps = -220, 280, 280
    gold_start, gold_end = (0xFF, 0xE3, 0xA8), (0xC0, 0x76, 0x33)
    for step in range(steps):
        t = step / (steps - 1)
        a0 = start_angle + sweep * step / steps
        a1 = start_angle + sweep * (step + 1) / steps + 0.6
        ring_draw.arc(box, a0, a1, fill=lerp(gold_start, gold_end, t) + (255,), width=width)

    # Незакрытая часть кольца — приглушённая, как «осталось накопить».
    ring_draw.arc(box, start_angle + sweep, start_angle + 360, fill=(0xFF, 0xFF, 0xFF, 38), width=width)

    canvas = Image.alpha_composite(canvas.convert("RGBA"), ring)

    # Монета.
    coin_radius = int(S * 0.255)
    center = (S // 2, S // 2)
    coin_box = [
        center[0] - coin_radius,
        center[1] - coin_radius,
        center[0] + coin_radius,
        center[1] + coin_radius,
    ]

    shadow = Image.new("L", (S, S), 0)
    ImageDraw.Draw(shadow).ellipse(
        [coin_box[0], coin_box[1] + int(S * 0.02), coin_box[2], coin_box[3] + int(S * 0.03)],
        fill=140,
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(S * 0.035)).point(lambda v: int(v * 0.55))
    canvas = Image.composite(Image.new("RGBA", (S, S), (0x05, 0x05, 0x08, 255)), canvas, shadow)

    coin_gradient = diagonal_gradient(S, (0xFF, 0xEB, 0xBE), (0xC6, 0x83, 0x33)).convert("RGBA")
    coin_mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(coin_mask).ellipse(coin_box, fill=255)
    canvas = Image.composite(coin_gradient, canvas, coin_mask)

    # Тонкий светлый кант монеты.
    edge = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(edge).ellipse(coin_box, outline=(0xFF, 0xF7, 0xE2, 200), width=int(S * 0.006))
    canvas = Image.alpha_composite(canvas, edge)

    # Прорезь для монет.
    slot_width = int(coin_radius * 1.05)
    slot_height = int(S * 0.032)
    slot_box = [
        center[0] - slot_width // 2,
        center[1] - slot_height // 2 - int(S * 0.005),
        center[0] + slot_width // 2,
        center[1] + slot_height // 2 - int(S * 0.005),
    ]
    slot = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(slot).rounded_rectangle(slot_box, radius=slot_height // 2, fill=(0x3A, 0x24, 0x0B, 255))
    # Небольшой наклон: прорезь читается как щель копилки, а не как знак «минус».
    slot = slot.rotate(-11, resample=Image.BICUBIC, center=center)
    slot = slot.filter(ImageFilter.GaussianBlur(S * 0.0012))
    canvas = Image.alpha_composite(canvas, slot)

    # Блик сверху — монета перестаёт быть плоским кругом.
    highlight = Image.new("L", (S, S), 0)
    ImageDraw.Draw(highlight).ellipse(
        [
            center[0] - int(coin_radius * 0.8),
            center[1] - int(coin_radius * 1.05),
            center[0] + int(coin_radius * 0.55),
            center[1] - int(coin_radius * 0.25),
        ],
        fill=90,
    )
    highlight = highlight.filter(ImageFilter.GaussianBlur(S * 0.03))
    highlight = Image.composite(highlight, Image.new("L", (S, S), 0), coin_mask)
    canvas = Image.composite(Image.new("RGBA", (S, S), (0xFF, 0xFF, 0xFF, 255)), canvas, highlight)

    icon = canvas.convert("RGB").resize((SIZE, SIZE), Image.LANCZOS)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    icon.save(OUTPUT, format="PNG")
    print(f"saved {OUTPUT} ({icon.size[0]}×{icon.size[1]})")


if __name__ == "__main__":
    build()
