"""Store graphics from docs/brand: icon-512.png (Google Play icon, full square; Play rounds it itself) and
feature-graphic.png (1024x500). Run: uvx --with cairosvg python store/make_graphics.py"""
import re
from pathlib import Path
import cairosvg

HERE = Path(__file__).resolve().parent
BRAND = HERE.parent / "docs" / "brand"
OUT = HERE / "graphics"
GREEN, WHITE = "#0D6B5E", "#FFFFFF"

OUT.mkdir(exist_ok=True)
icon = (BRAND / "icon-squircle.svg").read_text().replace('rx="34"', 'rx="0"')
cairosvg.svg2png(bytestring=icon.encode(), write_to=str(OUT / "icon-512.png"), output_width=512, output_height=512)

for lang in ("en", "ar"):
    lockup = (BRAND / f"lockup-{lang}.svg").read_text()
    lockup = lockup.replace(f'color="{GREEN}"', f'color="{WHITE}"').replace('fill="#053D35"', f'fill="{WHITE}"')
    vb = [float(v) for v in re.search(r'viewBox="([^"]+)"', lockup).group(1).split()]
    inner = re.sub(r"^<svg[^>]*>|</svg>\s*$", "", lockup.strip())
    w = 640.0                                   # lockup width on the 1024x500 canvas
    s = w / vb[2]
    h = vb[3] * s
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="500" viewBox="0 0 1024 500">'
           f'<rect width="1024" height="500" fill="{GREEN}"/>'
           f'<g transform="translate({(1024 - w) / 2} {(500 - h) / 2}) scale({s}) translate({-vb[0]} {-vb[1]})">{inner}</g></svg>')
    cairosvg.svg2png(bytestring=svg.encode(), write_to=str(OUT / f"feature-graphic-{lang}.png"), output_width=1024, output_height=500)
print("wrote", sorted(p.name for p in OUT.iterdir()))
