# -*- coding: utf-8 -*-
"""把角色立绘合成到场景图里，作为 H3 的首帧。

用法：python compose_frame.py bg.png char.png out.png [角色占比 0.68] [底部偏移 20]
"""
import sys

from PIL import Image, ImageDraw, ImageFilter

bg_path, char_path, out_path = sys.argv[1], sys.argv[2], sys.argv[3]
scale = float(sys.argv[4]) if len(sys.argv) > 4 else 0.68
bottom_pad = int(sys.argv[5]) if len(sys.argv) > 5 else 20

bg = Image.open(bg_path).convert("RGBA")
W, H = bg.size
ch = Image.open(char_path).convert("RGBA")

w = int(ch.width * scale)
h = int(ch.height * scale)
ch = ch.resize((w, h), Image.LANCZOS)

x = (W - w) // 2
y = H - h + bottom_pad

shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(shadow)
d.ellipse([x + w * 0.2, y + h * 0.93, x + w * 0.8, y + h * 0.99], fill=(10, 40, 70, 90))
shadow = shadow.filter(ImageFilter.GaussianBlur(12))

bg = Image.alpha_composite(bg, shadow)
bg.paste(ch, (x, y), ch)

tint = Image.new("RGBA", (W, H), (90, 170, 220, 26))
bg = Image.alpha_composite(bg, tint)

bg.convert("RGB").save(out_path)
print("SAVED", out_path, bg.size)
