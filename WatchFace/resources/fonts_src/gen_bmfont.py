import sys
from PIL import Image, ImageDraw, ImageFont

def generate(ttf_path, size, chars, out_fnt, out_png, png_filename_in_fnt):
    font = ImageFont.truetype(ttf_path, size)
    ascent, descent = font.getmetrics()
    pad = 4

    glyphs = {}
    max_h = 1
    total_w = 0

    for ch in chars:
        canvas_w = size * 2 + 40
        canvas_h = ascent + descent + pad * 4
        img = Image.new("L", (canvas_w, canvas_h), 0)
        draw = ImageDraw.Draw(img)
        origin_x = pad * 2
        origin_y = pad
        draw.text((origin_x, origin_y), ch, font=font, fill=255)
        bbox = img.getbbox()
        xadvance = round(font.getlength(ch))
        if bbox is None:
            glyphs[ch] = {"img": None, "w": 0, "h": 0, "xoff": 0, "yoff": 0, "xadv": xadvance}
            continue
        x0, y0, x1, y1 = bbox
        glyph_img = img.crop((x0, y0, x1, y1))
        w, h = glyph_img.size
        xoff = x0 - origin_x
        yoff = y0 - origin_y
        glyphs[ch] = {"img": glyph_img, "w": w, "h": h, "xoff": xoff, "yoff": yoff, "xadv": xadvance}
        max_h = max(max_h, h)
        total_w += w + 2

    atlas_w = max(total_w, 1)
    atlas_h = max_h
    atlas = Image.new("L", (atlas_w, atlas_h), 0)
    cursor_x = 0
    positions = {}
    for ch in chars:
        g = glyphs[ch]
        if g["img"] is None:
            positions[ch] = (0, 0)
            continue
        atlas.paste(g["img"], (cursor_x, 0))
        positions[ch] = (cursor_x, 0)
        cursor_x += g["w"] + 2

    atlas.save(out_png)

    lines = []
    lines.append('info face="OpenDyslexic" size=-{0} bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=1 aa=1 padding=0,0,0,0 spacing=1,1 outline=0'.format(size))
    lines.append('common lineHeight={0} base={1} scaleW={2} scaleH={3} pages=1 packed=0 alphaChnl=1 redChnl=0 greenChnl=0 blueChnl=0'.format(ascent + descent, ascent, atlas_w, atlas_h))
    lines.append('page id=0 file="{0}"'.format(png_filename_in_fnt))
    lines.append('chars count={0}'.format(len(chars)))
    for ch in chars:
        g = glyphs[ch]
        x, y = positions[ch]
        code = ord(ch)
        lines.append('char id={0}   x={1}   y={2}     width={3}    height={4}     xoffset={5}     yoffset={6}    xadvance={7}    page=0  chnl=15'.format(
            code, x, y, g["w"], g["h"], g["xoff"], g["yoff"], g["xadv"]))

    with open(out_fnt, "w", encoding="ascii", newline="\n") as f:
        f.write("\n".join(lines) + "\n")

    print("wrote", out_fnt, out_png, "atlas", atlas_w, "x", atlas_h, "lineHeight", ascent + descent, "base", ascent)


if __name__ == "__main__":
    ttf = sys.argv[1]
    chars = list("0123456789:/°- ")
    generate(ttf, int(sys.argv[2]), chars, sys.argv[3], sys.argv[4], sys.argv[4].split("/")[-1])
