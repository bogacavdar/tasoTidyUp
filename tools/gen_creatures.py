"""Taso canlı üreticisi.

Her set için 50 tür x 3 evrim = 150 taso resmi üretir ve setin doku atlasına yazar:
    assets/art/set_XX.jpg   (13 sütun x 12 satır, hücre 128 px; hücre i = numara i+1)

Numaralandırma (Pokédex gibi): tür t (0..49), evrim e (0..2) -> numara = t*3 + e + 1

Her tür setin konseptine uygun bir vücut planından (dört ayaklı, iki ayaklı, yılan, kuş,
balık, böcek, ahtapot, hayalet, bitki, golem, yengeç, balçık) ve kafa süsü / göz / ağız /
kuyruk / desen / oran / renk seçimlerinden oluşur. (plan, kafa, göz) üçlüsü set içinde
benzersizdir; evrimler aynı türün büyüyüp süslenmiş halleridir.

Kullanım:  python3 tools/gen_creatures.py [set_no ...]     (boşsa hepsi)
"""
import colorsys
import math
import os
import random
import sys
from multiprocessing import Pool

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

CELL = 128
SS = 3                    # süper örnekleme
S = CELL * SS
COLS, ROWS = 13, 12
SPECIES = 50
STAGES = 3
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "art")

# ---------------------------------------------------------------- temalar
# plans, hue aralığı, doygunluk, parlaklık, arka plan (iç, dış), parçacık, süs
T = lambda plans, h0, h1, sat, val, bg0, bg1, part, deco: dict(
    plans=plans, h=(h0, h1), sat=sat, val=val, bg=(bg0, bg1), part=part, deco=deco)
THEMES = [
    T(["quad", "biped", "serpent", "blob", "bird"], 0.0, 0.09, 0.85, 0.96, "#ffe7cc", "#f08a4b", "ember", "flame"),      # Kor Vadisi
    T(["fish", "cephalo", "crab", "serpent", "ghost"], 0.5, 0.66, 0.7, 0.92, "#bfe6ff", "#2a5c9c", "bubble", "water"),  # Derin Su
    T(["golem", "quad", "plant", "insect"], 0.06, 0.14, 0.35, 0.72, "#eee7d6", "#9b8a6a", "dust", "rock"),             # Taş Kök
    T(["bird", "ghost", "serpent", "quad"], 0.68, 0.8, 0.55, 0.8, "#4a3a85", "#140f30", "star", "shadow"),             # Gece Rüzgârı
    T(["quad", "biped", "bird", "golem"], 0.5, 0.6, 0.3, 0.98, "#f6fcff", "#9fd6ee", "snow", "crystal"),               # Buz Tepesi
    T(["quad", "bird", "serpent", "blob", "insect"], 0.12, 0.17, 0.85, 0.98, "#fff9cf", "#7aa7ff", "spark", "bolt"),   # Şimşek Ovası
    T(["insect", "serpent", "quad", "crab"], 0.08, 0.13, 0.5, 0.9, "#fff4d8", "#e2b46c", "dust", "shell"),             # Kum Çölü
    T(["plant", "blob", "insect", "biped"], 0.95, 1.06, 0.7, 0.92, "#eef8e2", "#6f9b4f", "spore", "mushroom"),         # Mantar Ormanı
    T(["golem", "insect", "quad", "crab"], 0.55, 0.62, 0.12, 0.78, "#eceff2", "#7b838e", "dust", "metal"),             # Demir Dağ
    T(["fish", "crab", "cephalo", "plant"], 0.95, 1.05, 0.6, 0.97, "#c9f3ff", "#3aa6c9", "bubble", "coral"),           # Mercan Koyu
    T(["ghost", "blob", "cephalo", "bird", "quad"], 0.72, 0.8, 0.35, 0.5, "#342a46", "#0b0910", "wisp", "shadow"),     # Gölge Mağara
    T(["plant", "bird", "blob", "insect"], 0.12, 0.2, 0.45, 0.98, "#fffbea", "#ffd9f0", "spark", "star"),              # Yıldız Bahçe
    T(["serpent", "golem", "blob", "fish"], 0.0, 0.06, 0.9, 0.88, "#ffbe7d", "#5a1a0d", "ember", "flame"),            # Lav Gölü
    T(["quad", "biped", "insect", "serpent"], 0.25, 0.38, 0.45, 0.72, "#e6eddf", "#7d9479", "fog", "leaf"),            # Sis Bataklığı
    T(["golem", "quad", "insect", "blob"], 0.5, 0.9, 0.5, 0.97, "#f6efff", "#b9a2ff", "spark", "crystal"),             # Kristal Vadi
    T(["bird", "ghost", "quad", "serpent"], 0.6, 0.68, 0.25, 0.92, "#34437a", "#0f1530", "star", "moon"),              # Ay Tapınağı
    T(["blob", "bird", "ghost", "quad"], 0.55, 0.62, 0.25, 0.99, "#f2f9ff", "#a9d6ff", "cloud", "cloud"),              # Bulut Adası
    T(["quad", "serpent", "bird", "insect"], 0.02, 0.07, 0.65, 0.86, "#ffe0c4", "#c8553a", "dust", "rock"),            # Kızıl Kanyon
    T(["plant", "quad", "bird", "insect", "biped"], 0.3, 0.4, 0.7, 0.82, "#e6f8e1", "#3f8a4a", "leafp", "leaf"),       # Zümrüt Orman
    T(["bird", "serpent", "fish", "ghost"], 0.58, 0.66, 0.3, 0.82, "#cfd8e3", "#4a5868", "rain", "bolt"),              # Fırtına Burnu
    T(["insect", "quad", "biped", "blob"], 0.07, 0.11, 0.75, 0.96, "#fff3d6", "#d99a2b", "spark", "shell"),            # Kehribar Köy
    T(["fish", "serpent", "quad", "bird"], 0.55, 0.6, 0.12, 0.92, "#eef6fc", "#8fb5cf", "bubble", "water"),            # Gümüş Nehir
    T(["blob", "plant", "insect", "ghost"], 0.27, 0.35, 0.6, 0.62, "#26402f", "#08120c", "spore", "moss"),             # Yosun Mağara
    T(["bird", "quad", "biped", "blob"], 0.1, 0.15, 0.8, 1.0, "#fffce6", "#ffc94a", "spark", "sun"),                   # Güneş Sarayı
    T(["ghost", "bird", "serpent", "blob"], 0.58, 0.75, 0.5, 0.96, "#24306a", "#060818", "star", "comet"),             # Kuyruklu Yıldız
    T(["quad", "biped", "bird", "blob"], 0.55, 0.62, 0.12, 1.0, "#ffffff", "#cfe3f2", "snow", "snow"),                 # Kar Ovası
    T(["insect", "serpent", "crab", "quad"], 0.11, 0.14, 0.75, 0.93, "#fff6d8", "#caa04a", "spark", "shell"),          # Altın Kum
    T(["quad", "bird", "golem", "biped"], 0.75, 0.82, 0.5, 0.82, "#f2e8ff", "#7a5aa6", "dust", "crystal"),             # Mor Dağ
    T(["bird", "plant", "ghost", "insect"], 0.85, 0.95, 0.4, 0.98, "#fff3f8", "#ffc2dc", "petal", "flower"),           # Rüzgâr Gülü
    T(["bird", "ghost", "blob", "serpent"], 0.55, 0.6, 0.45, 0.98, "#eef8ff", "#5ab0f0", "cloud", "star"),             # Gök Kubbe
    T(["golem", "crab", "quad", "insect"], 0.08, 0.12, 0.2, 0.74, "#f0ebe2", "#8d8170", "dust", "rock"),               # Kaya Kalesi
    T(["crab", "fish", "cephalo", "bird"], 0.48, 0.55, 0.55, 0.93, "#eefcff", "#4fc3d9", "bubble", "water"),           # Dalga Kıyısı
    T(["golem", "serpent", "blob", "quad"], 0.0, 0.05, 0.85, 0.75, "#5a2216", "#120504", "ember", "flame"),            # Volkan Ağzı
    T(["plant", "insect", "bird", "blob"], 0.85, 1.1, 0.55, 0.98, "#fff8f0", "#a7e08f", "petal", "flower"),            # Çiçek Vadisi
]
DARK_BG = {3, 10, 12, 15, 22, 24, 32}


# ---------------------------------------------------------------- renk yardımcıları
def hexc(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float32)


def hsv(h, s, v):
    r, g, b = colorsys.hsv_to_rgb(h % 1.0, max(0, min(1, s)), max(0, min(1, v)))
    return np.array([r * 255, g * 255, b * 255], dtype=np.float32)


def mixc(a, b, t):
    return a * (1 - t) + b * t


WHITE = np.array([255, 255, 255], dtype=np.float32)
BLACK = np.array([18, 14, 16], dtype=np.float32)


ZOOM = 1.32   # canlıyı hücreyi dolduracak kadar büyüt
YC = 0.13     # dikey merkez


def P(x, y):
    """normalize koordinat (-1..1, y aşağı) -> piksel"""
    return ((x * ZOOM * 0.5 + 0.5) * S, ((y - YC) * ZOOM * 0.5 + 0.5) * S)


# ---------------------------------------------------------------- şekiller
def ellipse_pts(c, r, ang=0.0, n=48):
    ca, sa = math.cos(ang), math.sin(ang)
    out = []
    for i in range(n):
        t = 2 * math.pi * i / n
        x, y = math.cos(t) * r[0], math.sin(t) * r[1]
        out.append((c[0] + x * ca - y * sa, c[1] + x * sa + y * ca))
    return out


def catmull(pts, n=12):
    out = []
    p = [pts[0]] + list(pts) + [pts[-1]]
    for i in range(1, len(p) - 2):
        p0, p1, p2, p3 = p[i - 1], p[i], p[i + 1], p[i + 2]
        for k in range(n):
            t = k / n
            t2, t3 = t * t, t * t * t
            out.append(tuple(0.5 * ((2 * p1[j]) + (-p0[j] + p2[j]) * t + (2 * p0[j] - 5 * p1[j] + 4 * p2[j] - p3[j]) * t2
                                    + (-p0[j] + 3 * p1[j] - 3 * p2[j] + p3[j]) * t3) for j in range(2)))
    out.append(pts[-1])
    return out


def tube(ctrl, w0, w1, cap=True):
    """kontrol noktalarından geçen, genişliği w0'dan w1'e değişen boru (uzuv, kuyruk, dokunaç)"""
    pts = catmull(ctrl) if len(ctrl) > 2 else [ctrl[0], ctrl[1]]
    if len(ctrl) == 2:
        pts = [(ctrl[0][0] + (ctrl[1][0] - ctrl[0][0]) * i / 10, ctrl[0][1] + (ctrl[1][1] - ctrl[0][1]) * i / 10) for i in range(11)]
    left, right = [], []
    n = len(pts)
    for i, (x, y) in enumerate(pts):
        a = pts[max(i - 1, 0)]
        b = pts[min(i + 1, n - 1)]
        dx, dy = b[0] - a[0], b[1] - a[1]
        ln = math.hypot(dx, dy) or 1e-6
        nx, ny = -dy / ln, dx / ln
        w = (w0 + (w1 - w0) * i / max(n - 1, 1)) / 2
        left.append((x + nx * w, y + ny * w))
        right.append((x - nx * w, y - ny * w))
    poly = left + right[::-1]
    if cap:
        # yuvarlak uçlar
        e = pts[-1]
        d = (pts[-1][0] - pts[-2][0], pts[-1][1] - pts[-2][1])
        ang = math.atan2(d[1], d[0])
        cap_end = [(e[0] + math.cos(ang + math.pi / 2 - math.pi * k / 8) * w1 / 2, e[1] + math.sin(ang + math.pi / 2 - math.pi * k / 8) * w1 / 2) for k in range(9)]
        s0 = pts[0]
        d0 = (pts[1][0] - pts[0][0], pts[1][1] - pts[0][1])
        a0 = math.atan2(d0[1], d0[0]) + math.pi
        cap_start = [(s0[0] + math.cos(a0 + math.pi / 2 - math.pi * k / 8) * w0 / 2, s0[1] + math.sin(a0 + math.pi / 2 - math.pi * k / 8) * w0 / 2) for k in range(9)]
        poly = left + cap_end + right[::-1] + cap_start
    return poly


def spike_pts(base, ang, length, width):
    ca, sa = math.cos(ang), math.sin(ang)
    px_, py_ = -sa, ca
    tip = (base[0] + ca * length, base[1] + sa * length)
    return [(base[0] + px_ * width / 2, base[1] + py_ * width / 2), tip, (base[0] - px_ * width / 2, base[1] - py_ * width / 2)]


def leaf_pts(base, ang, length, width, n=16):
    ca, sa = math.cos(ang), math.sin(ang)
    out = []
    for i in range(n + 1):
        t = i / n
        w = math.sin(math.pi * t) * width / 2
        out.append((t * length, w))
    for i in range(n, -1, -1):
        t = i / n
        w = math.sin(math.pi * t) * width / 2
        out.append((t * length, -w))
    return [(base[0] + x * ca - y * sa, base[1] + x * sa + y * ca) for x, y in out]


def flame_pts(base, ang, size, rng, n=40):
    """yukarı doğru yükselen, dalgalı uçlu alev"""
    out = []
    k = rng.randint(2, 4)
    ph = rng.random() * 6
    for i in range(n):
        t = 2 * math.pi * i / n
        r = size * (0.55 + 0.45 * (1 - math.cos(t)) / 2)
        y = -math.cos(t) * size * 1.25
        x = math.sin(t) * size * 0.55 * (0.6 + 0.4 * math.cos(t))
        if y < 0:
            x += math.sin(t * k + ph) * size * 0.12
        out.append((x, y * (1.0 if y < 0 else 0.45)))
    ca, sa = math.cos(ang + math.pi / 2), math.sin(ang + math.pi / 2)
    return [(base[0] + x * ca - y * sa, base[1] + x * sa + y * ca) for x, y in out]


def star_pts(c, r1, r2, n=5, rot=-math.pi / 2):
    out = []
    for i in range(n * 2):
        r = r1 if i % 2 == 0 else r2
        a = rot + math.pi * i / n
        out.append((c[0] + math.cos(a) * r, c[1] + math.sin(a) * r))
    return out


def crystal_pts(base, ang, w, h):
    ca, sa = math.cos(ang), math.sin(ang)
    loc = [(-w / 2, 0), (-w / 2, -h * 0.65), (0, -h), (w / 2, -h * 0.65), (w / 2, 0)]
    return [(base[0] + x * ca - y * sa, base[1] + x * sa + y * ca) for x, y in loc]


def bolt_pts(c, size, ang):
    loc = [(-0.15, -0.5), (0.25, -0.5), (0.02, -0.08), (0.28, -0.08), (-0.2, 0.55), (-0.02, 0.06), (-0.28, 0.06)]
    ca, sa = math.cos(ang), math.sin(ang)
    return [(c[0] + (x * ca - y * sa) * size, c[1] + (x * sa + y * ca) * size) for x, y in loc]


def rock_pts(c, r, rng, n=7):
    out = []
    for i in range(n):
        a = 2 * math.pi * i / n + rng.random() * 0.3
        rr = r * (0.75 + 0.35 * rng.random())
        out.append((c[0] + math.cos(a) * rr, c[1] + math.sin(a) * rr * 0.8))
    return out


# ---------------------------------------------------------------- çizim
class Art:
    def __init__(self):
        self.parts = []

    def add(self, pts, col, z, outline=True, shade=True, line=True, alpha=1.0):
        self.parts.append(dict(pts=[P(*p) for p in pts], col=np.array(col, dtype=np.float32), z=z,
                               outline=outline, shade=shade, line=line, alpha=alpha))

    def ell(self, c, r, col, z, ang=0.0, **kw):
        self.add(ellipse_pts(c, r, ang), col, z, **kw)

    def render(self, img, outline_col, aura=None):
        arr = np.asarray(img, dtype=np.float32).copy()
        parts = sorted(self.parts, key=lambda p: p["z"])
        sil = Image.new("L", (S, S), 0)
        sd = ImageDraw.Draw(sil)
        for p in parts:
            if p["outline"]:
                sd.polygon(p["pts"], fill=255)
        if aura is not None:
            glow = sil.filter(ImageFilter.MaxFilter(21)).filter(ImageFilter.GaussianBlur(14))
            g = np.asarray(glow, dtype=np.float32)[..., None] / 255.0 * 0.85
            arr = arr * (1 - g) + aura[None, None, :] * g
        # dış kontur
        ol = np.asarray(sil.filter(ImageFilter.MaxFilter(9)), dtype=np.float32)[..., None] / 255.0
        arr = arr * (1 - ol) + outline_col[None, None, :] * ol
        for p in parts:
            m_img = Image.new("L", (S, S), 0)
            ImageDraw.Draw(m_img).polygon(p["pts"], fill=255)
            xs = [q[0] for q in p["pts"]]
            ys = [q[1] for q in p["pts"]]
            x0, x1 = max(int(min(xs)) - 2, 0), min(int(max(xs)) + 3, S)
            y0, y1 = max(int(min(ys)) - 2, 0), min(int(max(ys)) + 3, S)
            if x1 <= x0 or y1 <= y0:
                continue
            m = np.asarray(m_img, dtype=np.float32)[y0:y1, x0:x1, None] / 255.0 * p["alpha"]
            col = p["col"]
            if p["shade"]:
                yy, xx = np.mgrid[y0:y1, x0:x1].astype(np.float32)
                w = max(x1 - x0, 1)
                h = max(y1 - y0, 1)
                t = (xx - x0) / w * 0.4 + (yy - y0) / h * 0.6
                f = 1.16 - 0.42 * t
                cx, cy = x0 + w * 0.32, y0 + h * 0.26
                r = 0.2 * min(w, h) + 1
                spec = np.clip(1 - ((xx - cx) ** 2 + (yy - cy) ** 2) / (r * r), 0, 1) ** 1.6 * 70
                rgb = np.clip(col[None, None, :] * f[..., None] + spec[..., None], 0, 255)
            else:
                rgb = col[None, None, :]
            arr[y0:y1, x0:x1] = arr[y0:y1, x0:x1] * (1 - m) + rgb * m
            if p["line"]:
                tmp = Image.fromarray(arr.astype(np.uint8))
                ImageDraw.Draw(tmp).line(p["pts"] + [p["pts"][0]], fill=tuple(int(v) for v in (col * 0.42)), width=3, joint="curve")
                arr = np.asarray(tmp, dtype=np.float32).copy()
        return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))


# ---------------------------------------------------------------- arka plan
def background(theme, rng, gi):
    c0, c1 = hexc(theme["bg"][0]), hexc(theme["bg"][1])
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    cx, cy = S * (0.5 + (rng.random() - 0.5) * 0.2), S * (0.42 + (rng.random() - 0.5) * 0.1)
    d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) / (S * 0.62)
    t = np.clip(d, 0, 1)[..., None]
    arr = c0[None, None, :] * (1 - t) + c1[None, None, :] * t
    img = Image.fromarray(arr.astype(np.uint8))
    dr = ImageDraw.Draw(img, "RGBA")
    part = theme["part"]
    for _ in range(rng.randint(10, 22)):
        x, y = rng.random() * S, rng.random() * S * 0.8
        r = (2 + rng.random() * 5) * SS
        if part == "bubble":
            dr.ellipse([x - r, y - r, x + r, y + r], outline=(255, 255, 255, 150), width=SS)
        elif part == "ember":
            dr.ellipse([x - r / 2, y - r / 2, x + r / 2, y + r / 2], fill=(255, 210, 90, 170))
        elif part in ("star", "spark"):
            pts = star_pts((x, y), r * 1.1, r * 0.35, 4, 0)
            dr.polygon(pts, fill=(255, 250, 210, 200 if part == "star" else 150))
        elif part == "snow":
            dr.ellipse([x - r / 2, y - r / 2, x + r / 2, y + r / 2], fill=(255, 255, 255, 220))
        elif part in ("leafp", "petal"):
            col = (120, 190, 90, 150) if part == "leafp" else (255, 170, 205, 170)
            dr.polygon(leaf_pts((x, y), rng.random() * 6.3, r * 2.2, r), fill=col)
        elif part == "spore":
            dr.ellipse([x - r / 3, y - r / 3, x + r / 3, y + r / 3], fill=(235, 255, 170, 170))
        elif part == "wisp":
            dr.ellipse([x - r, y - r / 3, x + r, y + r / 3], fill=(190, 160, 255, 70))
        elif part == "cloud":
            for k in range(3):
                dr.ellipse([x - r * 3 + k * r * 1.8, y - r, x - r + k * r * 1.8, y + r], fill=(255, 255, 255, 160))
        elif part == "rain":
            dr.line([x, y, x - r, y + r * 3], fill=(220, 235, 255, 130), width=SS)
        elif part == "fog":
            dr.ellipse([x - r * 5, y - r, x + r * 5, y + r], fill=(255, 255, 255, 50))
        elif part == "dust":
            dr.ellipse([x - r / 3, y - r / 3, x + r / 3, y + r / 3], fill=(255, 255, 255, 90))
    return img


# ---------------------------------------------------------------- tür (değişmeyen özellikler)
HEADS = ["horns", "ears_pointy", "ears_round", "antennae", "crest"]
EYES = ["two", "cyclops", "three", "slit"]


def make_species(g, sp):
    th = THEMES[g]
    rng = random.Random(g * 10007 + sp * 131 + 7)
    plans = th["plans"]
    k = len(plans)
    plan = plans[sp % k]
    head = HEADS[(sp // k) % 5]
    eyes = EYES[(sp // (k * 5)) % 4]
    h0, h1 = th["h"]
    hue = (h0 + (h1 - h0) * rng.random()) % 1.0
    sat = th["sat"] * (0.8 + 0.35 * rng.random())
    val = th["val"] * (0.88 + 0.12 * rng.random())
    sp_d = dict(
        plan=plan, head=head, eyes=eyes, hue=hue, sat=sat, val=val,
        hue2=(hue + (rng.random() - 0.5) * 0.16) % 1.0,
        acc_hue=(hue + 0.45 + rng.random() * 0.15) % 1.0,
        mouth=rng.choice(["smile", "fangs", "open", "small", "tusks"]),
        tail=rng.choice(["none", "thin", "thick", "fluffy", "tipped"]),
        pattern=rng.choice(["none", "spots", "stripes", "belly", "belly", "spots"]),
        bw=0.85 + 0.35 * rng.random(), bh=0.85 + 0.3 * rng.random(),
        hr=0.85 + 0.3 * rng.random(), leg=0.8 + 0.45 * rng.random(),
        limbs=rng.choice([4, 4, 6, 8]), petals=rng.randint(3, 6),
        seed=rng.random() * 1000, mirror=rng.random() < 0.5,
        form=rng.randint(0, 3), snout=rng.random() < 0.5,
        look=rng.uniform(-1, 1), glow_eyes=g in DARK_BG,
    )
    return sp_d


# ---------------------------------------------------------------- çizim parçaları
class Ctx:
    def __init__(self, sp, stage, theme):
        self.sp, self.stage, self.theme = sp, stage, theme
        self.rng = random.Random(sp["seed"] * 7 + stage)
        st = stage
        self.k = [0.66, 0.84, 1.0][st]
        self.adorn = [0.45, 0.8, 1.15][st]
        tint = [0.18, 0.0, -0.06][st]
        body = hsv(sp["hue"], sp["sat"] * (0.85 + 0.12 * st), sp["val"])
        self.body = mixc(body, WHITE, tint) if tint > 0 else body * (1 + tint)
        self.body2 = hsv(sp["hue2"], sp["sat"] * 0.9, sp["val"] * 0.88)
        self.light = mixc(self.body, WHITE, 0.55)
        self.dark = self.body * 0.55
        self.acc = hsv(sp["acc_hue"], min(1.0, sp["sat"] + 0.25), min(1.0, sp["val"] + 0.05))
        self.art = Art()


def face(c, ctx, r, front=True, side=0.0):
    """gözler + ağız. side: -1 sola bakar (profil), 0 önden"""
    sp, a = ctx.sp, ctx.art
    st = ctx.stage
    cute = [1.3, 1.08, 0.9][st]
    er = r * 0.27 * cute
    ex = r * 0.42
    ey = c[1] - r * 0.12
    cx = c[0] + side * r * 0.35
    eye_col = WHITE
    pupil = BLACK if not sp["glow_eyes"] else hsv(sp["acc_hue"], 0.8, 1.0)
    if sp["glow_eyes"]:
        eye_col = mixc(hsv(sp["acc_hue"], 0.5, 1.0), WHITE, 0.4)
    def one(px_, py_, rr):
        a.ell((px_, py_), (rr, rr * (1.0 if sp["eyes"] != "slit" else 0.85)), eye_col, 50, outline=False, shade=False)
        if sp["eyes"] == "slit":
            a.ell((px_ + sp["look"] * rr * 0.2, py_), (rr * 0.22, rr * 0.78), pupil, 51, outline=False, shade=False, line=False)
        else:
            a.ell((px_ + sp["look"] * rr * 0.25, py_ + rr * 0.1), (rr * 0.55, rr * 0.58), pupil, 51, outline=False, shade=False, line=False)
        a.ell((px_ - rr * 0.25, py_ - rr * 0.3), (rr * 0.2, rr * 0.2), WHITE, 52, outline=False, shade=False, line=False)
        if st == 2 and sp["eyes"] != "cyclops":
            # keskin bakış: göz kapağı
            a.add([(px_ - rr * 1.1, py_ - rr * 1.15), (px_ + rr * 1.1, py_ - rr * 1.15 + (0.0 if px_ < cx else 0.0)),
                   (px_ + rr * 1.1, py_ - rr * 0.35 + (rr * 0.25 if px_ < cx else -rr * 0.25)),
                   (px_ - rr * 1.1, py_ - rr * 0.35 + (-rr * 0.25 if px_ < cx else rr * 0.25))], ctx.body, 53, outline=False, shade=False, line=False)
    if sp["eyes"] == "cyclops":
        one(cx, ey, er * 1.6)
    elif sp["eyes"] == "three":
        one(cx - ex, ey + r * 0.05, er * 0.85)
        one(cx + ex, ey + r * 0.05, er * 0.85)
        one(cx, ey - r * 0.32, er * 0.7)
    else:
        if side == 0:
            one(cx - ex, ey, er)
            one(cx + ex, ey, er)
        else:
            one(cx - ex * 0.5, ey, er)
            one(cx + ex * 0.75, ey, er * 0.85)
    # ağız
    my = c[1] + r * 0.38
    mw = r * 0.36
    mouth = sp["mouth"]
    mc = np.array([90, 20, 35], dtype=np.float32)
    if mouth == "smile":
        pts = [(cx - mw + 2 * mw * i / 12, my + math.sin(math.pi * i / 12) * r * 0.16) for i in range(13)]
        pts += [(cx + mw - 2 * mw * i / 12, my + math.sin(math.pi * (12 - i) / 12) * r * 0.1) for i in range(13)]
        a.add(pts, mc, 54, outline=False, shade=False)
    elif mouth == "open":
        a.ell((cx, my + r * 0.04), (mw * 0.6, r * 0.17), mc, 54, outline=False, shade=False)
        a.ell((cx, my + r * 0.12), (mw * 0.38, r * 0.08), np.array([235, 110, 120]), 55, outline=False, shade=False, line=False)
    elif mouth == "small":
        a.ell((cx, my), (mw * 0.35, r * 0.07), mc, 54, outline=False, shade=False)
    else:
        a.ell((cx, my), (mw * 0.7, r * 0.09), mc, 54, outline=False, shade=False)
        tl = r * (0.15 if mouth == "fangs" else 0.24) * [0.8, 1.0, 1.25][st]
        for sx in (-1, 1):
            base = (cx + sx * mw * 0.4, my - (r * 0.02 if mouth == "fangs" else -r * 0.05))
            ang = math.pi / 2 if mouth == "fangs" else -math.pi / 2 + sx * 0.4
            a.add(spike_pts(base, ang, tl, r * 0.12), WHITE, 56, outline=False, shade=False)
    # yanaklar
    if st < 2:
        for sx in (-1, 1):
            a.ell((cx + sx * r * 0.62, my - r * 0.05), (r * 0.13, r * 0.08), mixc(ctx.body, np.array([255, 120, 140]), 0.5), 49, outline=False, shade=False, line=False)


def head_adorn(c, r, ctx, facing=0.0):
    sp, a, ad = ctx.sp, ctx.art, ctx.adorn
    top = c[1] - r * 0.85
    h = sp["head"]
    if h == "horns":
        for sx in (-1, 1):
            base = (c[0] + sx * r * 0.45, top + r * 0.2)
            tip = (base[0] + sx * r * 0.55 * ad, base[1] - r * 0.9 * ad)
            mid = (base[0] + sx * r * 0.05, base[1] - r * 0.6 * ad)
            a.add(tube([base, mid, tip], r * 0.3 * ad, r * 0.02), mixc(ctx.light, WHITE, 0.4), 15)
    elif h == "ears_pointy":
        for sx in (-1, 1):
            a.add(spike_pts((c[0] + sx * r * 0.55, top + r * 0.35), -math.pi / 2 + sx * 0.45, r * 1.1 * ad, r * 0.6), ctx.body, 15)
            a.add(spike_pts((c[0] + sx * r * 0.55, top + r * 0.35), -math.pi / 2 + sx * 0.45, r * 0.75 * ad, r * 0.3), ctx.acc, 16, outline=False, line=False)
    elif h == "ears_round":
        for sx in (-1, 1):
            a.ell((c[0] + sx * r * 0.7, top + r * 0.15), (r * 0.42 * ad, r * 0.42 * ad), ctx.body, 15)
            a.ell((c[0] + sx * r * 0.7, top + r * 0.15), (r * 0.22 * ad, r * 0.22 * ad), ctx.light, 16, outline=False, line=False)
    elif h == "antennae":
        for sx in (-1, 1):
            base = (c[0] + sx * r * 0.3, top + r * 0.25)
            tip = (base[0] + sx * r * 0.5 * ad, base[1] - r * 1.0 * ad)
            a.add(tube([base, (base[0] + sx * r * 0.05, base[1] - r * 0.6 * ad), tip], r * 0.1, r * 0.06), ctx.dark, 15)
            a.ell(tip, (r * 0.2 * ad, r * 0.2 * ad), ctx.acc, 16)
    elif h == "crest":
        n = 3 + ctx.stage
        for i in range(n):
            t = (i - (n - 1) / 2) / max(n - 1, 1)
            base = (c[0] + t * r * 0.9, top + r * 0.25 + abs(t) * r * 0.2)
            a.add(spike_pts(base, -math.pi / 2 + t * 0.9, r * (0.9 - abs(t) * 0.4) * ad, r * 0.32), ctx.acc, 15)
    theme_head_deco(c, r, ctx)


def theme_head_deco(c, r, ctx):
    """setin konsept süsü (2. evrimden itibaren belirir, 3.'de büyür)"""
    if ctx.stage == 0:
        return
    a, deco, rng = ctx.art, ctx.theme["deco"], ctx.rng
    big = ctx.stage == 2
    top = (c[0], c[1] - r * 0.95)
    s = r * (0.55 if not big else 0.8)
    if deco == "flame":
        a.add(flame_pts(top, -math.pi / 2, s, rng), np.array([255, 150, 40]), 60, outline=False)
        a.add(flame_pts((top[0], top[1] + s * 0.15), -math.pi / 2, s * 0.6, rng), np.array([255, 225, 90]), 61, outline=False, line=False)
    elif deco in ("crystal", "snow"):
        n = 1 if not big else 3
        for i in range(n):
            ang = -math.pi / 2 + (i - (n - 1) / 2) * 0.5
            col = hsv(ctx.sp["acc_hue"], 0.35, 1.0) if deco == "crystal" else np.array([235, 248, 255])
            a.add(crystal_pts((top[0] + (i - (n - 1) / 2) * s * 0.45, top[1] + s * 0.25), ang, s * 0.42, s * (1.1 if i == (n - 1) / 2 else 0.8)), col, 60)
    elif deco == "mushroom":
        cap = [(top[0] - s, top[1] + s * 0.3)] + [(top[0] + math.cos(math.pi + math.pi * i / 16) * s, top[1] + s * 0.3 + math.sin(math.pi + math.pi * i / 16) * s * 0.85) for i in range(17)]
        a.add(cap, hsv(ctx.sp["acc_hue"], 0.75, 0.9), 60)
        for i in range(3 if big else 2):
            a.ell((top[0] + (i - 1) * s * 0.5, top[1] - s * 0.15 + abs(i - 1) * s * 0.2), (s * 0.13, s * 0.11), WHITE, 61, outline=False, shade=False)
    elif deco in ("leaf", "moss"):
        for i in range(2 if not big else 4):
            ang = -math.pi / 2 + (i - (1.5 if big else 0.5)) * 0.45
            a.add(leaf_pts((top[0], top[1] + s * 0.3), ang, s * 1.5, s * 0.6), hsv(0.3, 0.6, 0.75 if deco == "leaf" else 0.55), 60)
    elif deco == "flower":
        fc = (top[0] + r * 0.4, top[1] + s * 0.2)
        n = ctx.sp["petals"] + 2
        for i in range(n):
            a.add(leaf_pts(fc, 2 * math.pi * i / n, s * 0.9, s * 0.5), hsv(ctx.sp["acc_hue"], 0.45, 1.0), 60)
        a.ell(fc, (s * 0.25, s * 0.25), np.array([255, 215, 80]), 61)
    elif deco in ("star", "sun"):
        if deco == "sun":
            a.add(star_pts(top, s * 1.2, s * 0.6, 10 if big else 7), np.array([255, 205, 60]), 59)
            a.ell(top, (s * 0.5, s * 0.5), np.array([255, 235, 120]), 60)
        else:
            a.add(star_pts(top, s * 0.9, s * 0.38, 5), np.array([255, 225, 90]), 60)
    elif deco == "moon":
        moon = [(top[0] + math.cos(math.pi * 0.5 + math.pi * i / 16) * s * 0.8, top[1] + math.sin(math.pi * 0.5 + math.pi * i / 16) * s * 0.8) for i in range(17)]
        moon += [(top[0] + s * 0.25 + math.cos(math.pi * 1.5 - math.pi * i / 16) * s * 0.6, top[1] + math.sin(math.pi * 1.5 - math.pi * i / 16) * s * 0.65) for i in range(17)]
        a.add(moon, np.array([245, 240, 210]), 60)
    elif deco == "cloud":
        for i in range(3):
            a.ell((top[0] + (i - 1) * s * 0.55, top[1] + s * 0.2 - (s * 0.2 if i == 1 else 0)), (s * 0.45, s * 0.38), WHITE, 60)
    elif deco == "bolt":
        a.add(bolt_pts(top, s * 1.5, 0.2), np.array([255, 230, 60]), 60)
    elif deco in ("rock", "metal"):
        for i in range(2 if not big else 3):
            col = hsv(0.08, 0.15, 0.6 + 0.1 * i) if deco == "rock" else hsv(0.58, 0.08, 0.75 + 0.08 * i)
            a.add(rock_pts((top[0] + (i - 1) * s * 0.6, top[1] + s * 0.35 - (s * 0.25 if i == 1 else 0)), s * 0.42, rng), col, 60)
    elif deco == "shell":
        a.add(spike_pts((top[0], top[1] + s * 0.6), -math.pi / 2, s * 1.4, s * 0.55), hsv(ctx.sp["acc_hue"], 0.6, 0.95), 60)
    elif deco in ("water", "coral"):
        if deco == "coral":
            col = hsv(0.98, 0.55, 0.98)
            a.add(tube([(top[0], top[1] + s * 0.5), (top[0] - s * 0.2, top[1]), (top[0] - s * 0.5, top[1] - s * 0.6)], s * 0.28, s * 0.14), col, 60)
            a.add(tube([(top[0] - s * 0.1, top[1] + s * 0.1), (top[0] + s * 0.3, top[1] - s * 0.4)], s * 0.2, s * 0.12), col, 60)
        else:
            a.add(leaf_pts((top[0], top[1] + s * 0.5), -math.pi / 2, s * 1.4, s * 0.7), mixc(ctx.acc, WHITE, 0.2), 60)
    elif deco == "shadow":
        a.add(flame_pts(top, -math.pi / 2, s * 0.9, rng), hsv(0.75, 0.45, 0.55), 60, outline=False)
    elif deco == "comet":
        a.add(star_pts(top, s * 0.8, s * 0.35, 5), np.array([255, 245, 200]), 61)
        a.add(tube([top, (top[0] + s * 1.2, top[1] - s * 0.3), (top[0] + s * 2.2, top[1] - s * 0.2)], s * 0.7, s * 0.05, cap=False), mixc(ctx.acc, WHITE, 0.5), 59, outline=False, alpha=0.8)


def tail_tip_deco(p, ctx, size):
    if ctx.stage == 0:
        return
    deco, a = ctx.theme["deco"], ctx.art
    s = size * (1.0 if ctx.stage == 1 else 1.4)
    if deco in ("flame",):
        a.add(flame_pts(p, -math.pi / 2, s, ctx.rng), np.array([255, 160, 50]), 30, outline=False)
    elif deco in ("star", "comet", "sun"):
        a.add(star_pts(p, s, s * 0.42, 5), np.array([255, 225, 90]), 30)
    elif deco in ("crystal", "snow"):
        a.add(crystal_pts(p, -math.pi / 4, s * 0.6, s * 1.3), hsv(ctx.sp["acc_hue"], 0.35, 1.0), 30)
    elif deco in ("leaf", "moss", "flower"):
        a.add(leaf_pts(p, -math.pi / 3, s * 1.6, s * 0.7), hsv(0.3, 0.6, 0.75), 30)
    elif deco == "bolt":
        a.add(bolt_pts(p, s * 1.4, 0.4), np.array([255, 230, 60]), 30)
    elif deco in ("water", "coral"):
        a.add(leaf_pts(p, -0.3, s * 1.3, s * 0.9), mixc(ctx.acc, WHITE, 0.2), 30)
    else:
        a.ell(p, (s * 0.5, s * 0.5), ctx.acc, 30)


def back_deco(pts_line, ctx, size):
    """sırt boyunca dikenler / plakalar (evrimle artar)"""
    a, deco = ctx.art, ctx.theme["deco"]
    n = [0, 2, 4][ctx.stage]
    if n == 0:
        return
    for i in range(n):
        t = (i + 0.5) / n
        idx = int(t * (len(pts_line) - 1))
        p = pts_line[idx]
        if deco in ("rock", "metal", "shell"):
            col = hsv(0.08, 0.15, 0.65) if deco == "rock" else (hsv(0.58, 0.08, 0.8) if deco == "metal" else hsv(ctx.sp["acc_hue"], 0.55, 0.9))
            a.add(rock_pts(p, size * 0.55, ctx.rng, 6), col, 8)
        elif deco in ("crystal", "snow"):
            a.add(crystal_pts((p[0], p[1] + size * 0.3), -math.pi / 2 + (t - 0.5) * 0.6, size * 0.45, size * 1.1), hsv(ctx.sp["acc_hue"], 0.35, 1.0), 8)
        elif deco == "flame":
            a.add(flame_pts(p, -math.pi / 2, size * 0.55, ctx.rng), np.array([255, 150, 45]), 8, outline=False)
        elif deco in ("leaf", "moss", "flower"):
            a.add(leaf_pts(p, -math.pi / 2 - 0.5 + t, size * 1.2, size * 0.5), hsv(0.3, 0.6, 0.72), 8)
        else:
            a.add(spike_pts(p, -math.pi / 2 + (t - 0.5) * 0.8, size * 0.9, size * 0.5), ctx.acc, 8)


def body_pattern(c, r, ctx, z):
    sp, a = ctx.sp, ctx.art
    if sp["pattern"] == "belly":
        a.ell((c[0], c[1] + r[1] * 0.3), (r[0] * 0.62, r[1] * 0.55), ctx.light, z + 1, outline=False, shade=False, line=False)
    elif sp["pattern"] == "spots":
        rng = random.Random(sp["seed"])
        for i in range(3 + ctx.stage * 2):
            ang = rng.random() * 6.28
            rr = rng.random() * 0.6
            a.ell((c[0] + math.cos(ang) * r[0] * rr, c[1] + math.sin(ang) * r[1] * rr * 0.8), (r[0] * 0.13, r[0] * 0.11), ctx.body2 * 0.8, z + 1, outline=False, shade=False, line=False)
    elif sp["pattern"] == "stripes":
        for i in range(3):
            x = c[0] + (i - 1) * r[0] * 0.45
            a.add(leaf_pts((x, c[1] - r[1] * 0.85), math.pi / 2, r[1] * 1.0, r[0] * 0.14), ctx.body2 * 0.75, z + 1, outline=False, shade=False, line=False)


def ground_shadow(img, cx, w, gy):
    dr = ImageDraw.Draw(img, "RGBA")
    x, y = P(cx, gy + 0.015)
    dr.ellipse([x - w * S * 0.5, y - S * 0.035, x + w * S * 0.5, y + S * 0.035], fill=(0, 0, 0, 55))


# ---------------------------------------------------------------- vücut planları
def plan_quad(ctx):
    a, sp, k = ctx.art, ctx.sp, ctx.k
    f = sp["form"]
    bw, bh = 0.38 * k * sp["bw"], 0.22 * k * sp["bh"]
    leg = 0.24 * k * sp["leg"]
    neck = 1.0
    if f == 1:      # uzun gövde, kısa bacak (kertenkele / porsuk)
        bw, bh, leg = bw * 1.3, bh * 0.85, leg * 0.55
    elif f == 2:    # uzun bacak, uzun boyun (geyik)
        bw, leg, neck = bw * 0.85, leg * 1.55, 1.6
    elif f == 3:    # tıknaz (ayı)
        bw, bh, leg = bw * 1.1, bh * 1.4, leg * 0.7
    bc = (0.08, 0.42 - leg - bh * 0.6)
    gy = bc[1] + bh * 0.6 + leg
    for i, lx in enumerate([-0.7, -0.35, 0.35, 0.7]):
        back = i in (1, 3)
        x = bc[0] + lx * bw
        a.add(tube([(x, bc[1] + bh * 0.3), (x + 0.01, gy)], bw * 0.32, bw * 0.26), ctx.dark if back else ctx.body, 5 if back else 12)
        a.ell((x - 0.02, gy), (bw * 0.2, bw * 0.1), ctx.dark * 0.9, 13 if not back else 6)
    # kuyruk
    tail(ctx, (bc[0] + bw * 0.9, bc[1] - bh * 0.1), 1.0)
    a.ell(bc, (bw, bh), ctx.body, 10)
    body_pattern(bc, (bw, bh), ctx, 10)
    back_deco([(bc[0] - bw * 0.6 + bw * 1.4 * t / 10, bc[1] - bh * (0.95 - 0.3 * abs(t / 10 - 0.5))) for t in range(11)], ctx, 0.12 * k)
    # boyun ve kafa
    hr = 0.2 * k * sp["hr"] * [1.25, 1.05, 1.0][ctx.stage]
    if f == 3:
        hr *= 1.2
    hc = (bc[0] - bw * 0.85, bc[1] - bh * 1.1 * neck - hr * 0.3)
    a.add(tube([(bc[0] - bw * 0.5, bc[1] - bh * 0.2), hc], bw * 0.55 / neck, hr * 1.0), ctx.body, 18)
    head_adorn(hc, hr, ctx)
    a.ell(hc, (hr * 1.05, hr), ctx.body, 20)
    if sp["snout"] or f == 1:
        a.ell((hc[0] - hr * 0.85, hc[1] + hr * 0.3), (hr * 0.65, hr * 0.42), ctx.body, 21)
        a.ell((hc[0] - hr * 1.38, hc[1] + hr * 0.2), (hr * 0.12, hr * 0.1), BLACK, 22, outline=False, shade=False)
    else:
        a.ell((hc[0] - hr * 0.55, hc[1] + hr * 0.35), (hr * 0.45, hr * 0.32), ctx.light, 21, outline=False)
    face(hc, ctx, hr, side=-1.0)
    return gy


def plan_biped(ctx):
    a, sp, k = ctx.art, ctx.sp, ctx.k
    f = sp["form"]
    tw, th = 0.24 * k * sp["bw"], 0.3 * k * sp["bh"]
    leg = 0.2 * k * sp["leg"]
    head_mul = 1.0
    if f == 1:      # armut göbekli
        tw, th = tw * 1.35, th * 1.05
    elif f == 2:    # ince uzun
        tw, th, leg = tw * 0.75, th * 1.2, leg * 1.35
    elif f == 3:    # küçük gövde, koca kafa
        tw, th, head_mul = tw * 0.85, th * 0.75, 1.45
    tc = (0.0, 0.42 - leg - th * 0.8)
    gy = tc[1] + th * 0.8 + leg
    for sx in (-1, 1):
        x = tc[0] + sx * tw * 0.5
        a.add(tube([(x, tc[1] + th * 0.5), (x + sx * 0.02, gy)], tw * 0.5, tw * 0.42), ctx.body * 0.9, 6)
        a.ell((x + sx * 0.03, gy), (tw * 0.38, tw * 0.17), ctx.dark, 7)
    tail(ctx, (tc[0] + tw * 0.7, tc[1] + th * 0.4), 0.8)
    a.ell(tc, (tw, th), ctx.body, 10)
    body_pattern(tc, (tw, th), ctx, 10)
    for sx in (-1, 1):
        sh = (tc[0] + sx * tw * 0.85, tc[1] - th * 0.45)
        hand = (sh[0] + sx * tw * 0.75, sh[1] + th * (0.55 if ctx.stage < 2 else 0.1))
        a.add(tube([sh, (sh[0] + sx * tw * 0.5, sh[1] + th * 0.35), hand], tw * 0.38, tw * 0.3), ctx.body, 14)
        if ctx.stage == 2:
            for j in range(3):
                a.add(spike_pts(hand, (-0.6 + j * 0.6) * sx + (math.pi / 2 if sx > 0 else math.pi / 2), tw * 0.35, tw * 0.15), WHITE, 15, outline=False)
    hr = 0.21 * k * sp["hr"] * [1.3, 1.08, 1.0][ctx.stage] * head_mul
    hc = (tc[0], tc[1] - th - hr * 0.6)
    head_adorn(hc, hr, ctx)
    a.ell(hc, (hr * 1.05, hr), ctx.body, 20)
    face(hc, ctx, hr)
    return gy


def plan_serpent(ctx):
    a, sp, k = ctx.art, ctx.sp, ctx.k
    rng = random.Random(sp["seed"])
    f = sp["form"]
    amp = 0.14 + 0.08 * rng.random()
    ctrl = []
    if f == 3:      # kıvrılmış
        for i in range(7):
            t = i / 6
            ang = t * math.pi * 1.6 + 1.2
            rr = (0.42 - t * 0.28) * k
            ctrl.append((0.05 + math.cos(ang) * rr, 0.2 + math.sin(ang) * rr * 0.7))
        ctrl = ctrl[::-1]
        ctrl.append((ctrl[-1][0] - 0.05 * k, ctrl[-1][1] - 0.2 * k))
    else:
        n = 5
        for i in range(n):
            t = i / (n - 1)
            x = 0.55 * k - t * 0.95 * k
            y = 0.42 - t * 0.35 * k + math.sin(t * math.pi * 2 + rng.random()) * amp * k
            ctrl.append((x, y))
    w = 0.2 * k * sp["bw"] * (1.6 if f == 1 else 1.0)
    a.add(tube(ctrl, w * 0.25, w), ctx.body, 10)
    line = catmull(ctrl)
    back_deco([(p[0], p[1] - w * 0.45) for p in line[len(line) // 4:]], ctx, 0.1 * k)
    if sp["pattern"] != "none":
        for i in range(2, len(line) - 3, 5):
            p = line[i]
            a.ell(p, (w * 0.18 * (0.3 + i / len(line)), w * 0.16 * (0.3 + i / len(line))), ctx.body2 * 0.8, 11, outline=False, shade=False, line=False)
    tail_tip_deco(ctrl[0], ctx, 0.07 * k)
    hr = 0.17 * k * sp["hr"] * [1.25, 1.05, 1.0][ctx.stage]
    hc = (ctrl[-1][0] - hr * 0.2, ctrl[-1][1] - hr * 0.2)
    if f == 2:      # yelpaze yaka
        for i in range(7 + 2 * ctx.stage):
            ang = math.pi * 0.15 + math.pi * 1.7 * i / (6 + 2 * ctx.stage)
            a.add(spike_pts(hc, ang, hr * (1.5 + 0.3 * ctx.stage), hr * 0.55), ctx.acc if i % 2 == 0 else ctx.body2, 17)
    head_adorn(hc, hr, ctx)
    a.ell(hc, (hr * 1.15, hr * 0.95), ctx.body, 20)
    face(hc, ctx, hr, side=-1.0)
    return max(p[1] for p in ctrl) + w * 0.4


def plan_bird(ctx):
    a, sp, k = ctx.art, ctx.sp, ctx.k
    f = sp["form"]
    bw, bh = 0.26 * k * sp["bw"], 0.22 * k * sp["bh"]
    legl = 0.14 * k
    if f == 1:      # baykuş: yuvarlak, kısa
        bw, bh = bw * 1.05, bh * 1.35
    elif f == 2:    # balıkçıl: uzun bacak
        legl = 0.34 * k
    elif f == 3:    # kırlangıç: ince
        bw, bh = bw * 1.15, bh * 0.7
    gy = 0.42
    bc = (0.08, gy - legl - bh)
    for sx in (-0.3, 0.3):
        a.add(tube([(bc[0] + sx * bw, bc[1] + bh * 0.7), (bc[0] + sx * bw, gy)], 0.03, 0.025), np.array([235, 150, 50]), 4, outline=False)
    # kuyruk tüyleri
    nt = 3 + ctx.stage
    for i in range(nt):
        ang = 0.15 + (i - (nt - 1) / 2) * (0.28 if f != 3 else 0.12)
        tl = 0.32 * k * (1 + 0.2 * ctx.stage) * (1.7 if f == 3 else 1.0)
        a.add(leaf_pts((bc[0] + bw * 0.75, bc[1] + bh * 0.1), ang, tl, 0.1 * k * (0.6 if f == 3 else 1.0)), ctx.body2, 5)
    # arka kanat
    span = [0.35, 0.5, 0.7][ctx.stage] * k
    a.add(leaf_pts((bc[0] + bw * 0.1, bc[1] - bh * 0.3), -math.pi / 2 - 0.9, span, 0.22 * k), ctx.body2 * 0.8, 6)
    a.ell(bc, (bw, bh), ctx.body, 10)
    body_pattern(bc, (bw, bh), ctx, 10)
    a.add(leaf_pts((bc[0] - bw * 0.1, bc[1] - bh * 0.1), -math.pi / 2 + 0.75 + 0.3 * ctx.stage * -1, span * 1.05, 0.24 * k), ctx.body2, 14)
    hr = 0.17 * k * sp["hr"] * [1.3, 1.08, 1.0][ctx.stage]
    hc = (bc[0] - bw * 0.75, bc[1] - bh * 1.05)
    if f == 1:
        hr *= 1.3
        hc = (bc[0] - bw * 0.1, bc[1] - bh * 0.85)
    elif f == 2:
        hc = (bc[0] - bw * 1.0, bc[1] - bh * 1.9)
        a.add(tube([(bc[0] - bw * 0.6, bc[1] - bh * 0.4), (bc[0] - bw * 1.05, bc[1] - bh * 1.1), hc], hr * 0.7, hr * 0.6), ctx.body, 18)
    head_adorn(hc, hr, ctx)
    a.ell(hc, (hr, hr), ctx.body, 20)
    beak_len = hr * (0.7 + 0.25 * ctx.stage)
    a.add(spike_pts((hc[0] - hr * 0.8, hc[1] + hr * 0.15), math.pi + 0.15, beak_len, hr * 0.55), np.array([245, 165, 45]), 22)
    sp2 = dict(sp)
    face(hc, ctx, hr * 0.95, side=(0.0 if f == 1 else -1.0))
    return gy


def plan_fish(ctx):
    a, sp, k = ctx.art, ctx.sp, ctx.k
    f = sp["form"]
    bw, bh = 0.42 * k * sp["bw"], 0.25 * k * sp["bh"]
    if f == 1:      # balon balığı
        bw, bh = bw * 0.72, bh * 1.5
    elif f == 2:    # uzun
        bw, bh = bw * 1.3, bh * 0.65
    elif f == 3:    # melek balığı: yüksek yüzgeçler
        bw, bh = bw * 0.8, bh * 1.2
    bc = (0.05, 0.12)
    if f == 1 and ctx.stage > 0:
        for i in range(10 + 4 * ctx.stage):
            ang = 2 * math.pi * i / (10 + 4 * ctx.stage)
            a.add(spike_pts((bc[0] + math.cos(ang) * bw * 0.95, bc[1] + math.sin(ang) * bh * 0.95), ang, 0.06 * k * (1 + 0.3 * ctx.stage), 0.04 * k), ctx.light, 4)
    if f == 3:
        for sy in (-1, 1):
            a.add(leaf_pts((bc[0] + bw * 0.1, bc[1] + sy * bh * 0.7), sy * (math.pi / 2 + 0.6), bh * (1.4 + 0.3 * ctx.stage), bw * 0.5), ctx.body2, 5)
    # kuyruk
    tx = bc[0] + bw * 0.9
    tl = 0.26 * k * (1 + 0.15 * ctx.stage)
    for sy in (-1, 1):
        a.add(leaf_pts((tx, bc[1]), sy * 0.7, tl, 0.16 * k), ctx.body2, 5)
    # yüzgeçler
    a.add(leaf_pts((bc[0] - bw * 0.1, bc[1] - bh * 0.8), -math.pi / 2 + 0.5, 0.2 * k * (1 + 0.3 * ctx.stage), 0.14 * k), ctx.body2, 6)
    if ctx.stage == 2:
        for i in range(3):
            a.add(spike_pts((bc[0] - bw * 0.35 + i * bw * 0.3, bc[1] - bh * 0.85), -math.pi / 2 + 0.3, 0.14 * k, 0.06 * k), ctx.acc, 7)
    a.ell(bc, (bw, bh), ctx.body, 10)
    body_pattern(bc, (bw, bh), ctx, 10)
    a.add(leaf_pts((bc[0] + bw * 0.05, bc[1] + bh * 0.3), 0.5, 0.16 * k, 0.09 * k), ctx.body2, 14)
    hc = (bc[0] - bw * 0.5, bc[1] - bh * 0.1)
    face(hc, ctx, bh * 0.75, side=-1.0)
    if ctx.stage > 0:
        theme_head_deco((bc[0] - bw * 0.2, bc[1] - bh * 0.4), bh * 0.7, ctx)
    return None


def plan_insect(ctx):
    """yukarıdan görünen böcek: baş üstte, bacaklar iki yana"""
    a, sp, k = ctx.art, ctx.sp, ctx.k
    f = sp["form"]
    aw, ah = 0.2 * k * sp["bw"], 0.26 * k * sp["bh"]
    if f == 1:      # yuvarlak kabuk (uğur böceği / bok böceği)
        aw, ah = aw * 1.35, ah * 1.05
    elif f == 2:    # uzun gövde
        aw, ah = aw * 0.72, ah * 1.4
    ac = (0.0, 0.2)
    tc = (0.0, ac[1] - ah * 0.95)
    hr = 0.12 * k * sp["hr"] * [1.3, 1.08, 1.0][ctx.stage]
    hc = (0.0, tc[1] - hr * 1.3)
    dark = ctx.dark * 0.75
    for i in range(3):
        for sx in (-1, 1):
            hip = (sx * aw * 0.55, ac[1] - ah * 0.55 + i * ah * 0.45)
            knee = (sx * (aw + 0.13 * k), hip[1] - 0.06 * k + i * 0.035 * k)
            foot = (sx * (aw + 0.22 * k), hip[1] + (0.04 + i * 0.05) * k)
            a.add(tube([hip, knee, foot], 0.032 * k, 0.022 * k), dark, 4)
    if ctx.stage > 0 or f == 3:
        span = [0.3, 0.34, 0.48][ctx.stage] * k * (1.4 if f == 3 else 1.0)
        wc = mixc(ctx.acc, WHITE, 0.55) if f != 3 else ctx.acc
        for sx in (-1, 1):
            a.add(leaf_pts((sx * aw * 0.3, tc[1]), -math.pi / 2 + sx * 1.15, span, 0.16 * k * (1.8 if f == 3 else 1.0)), wc, 3, alpha=0.85)
            if f == 3:
                a.add(leaf_pts((sx * aw * 0.3, tc[1] + 0.05 * k), math.pi / 2 - sx * 1.0, span * 0.75, 0.2 * k), ctx.body2, 3)
    a.ell(ac, (aw, ah), ctx.body, 10)
    # kabuk ayrımı ve desen
    a.add([(-0.006, ac[1] - ah * 0.95), (0.006, ac[1] - ah * 0.95), (0.006, ac[1] + ah * 0.95), (-0.006, ac[1] + ah * 0.95)], ctx.body * 0.4, 11, outline=False, shade=False, line=False)
    body_pattern(ac, (aw, ah), ctx, 10)
    a.ell(tc, (aw * 0.55, ah * 0.3), ctx.body2, 12)
    head_adorn(hc, hr, ctx)
    if f == 1 and ctx.stage > 0:
        a.add(tube([(hc[0], hc[1] - hr * 0.5), (hc[0] - hr * 0.15, hc[1] - hr * 1.3), (hc[0] + hr * 0.25, hc[1] - hr * (1.8 + 0.4 * ctx.stage))], hr * 0.45, hr * 0.08), dark, 21)
    a.ell(hc, (hr, hr * 0.9), ctx.body, 20)
    face(hc, ctx, hr)
    if sp["mouth"] in ("fangs", "tusks"):
        for sx in (-1, 1):
            a.add(tube([(hc[0] + sx * hr * 0.35, hc[1] + hr * 0.75), (hc[0] + sx * hr * 0.65, hc[1] + hr * 1.2), (hc[0] + sx * hr * 0.2, hc[1] + hr * 1.45)], hr * 0.2, hr * 0.05), dark, 19)
    return foot[1] if False else ac[1] + ah * 0.9


def plan_cephalo(ctx):
    a, sp, k = ctx.art, ctx.sp, ctx.k
    f = sp["form"]
    mw, mh = 0.3 * k * sp["bw"], 0.34 * k * sp["bh"]
    mc = (0.0, -0.05)
    n = sp["limbs"] if ctx.stage > 0 else 4
    if f == 1:      # denizanası: kubbe + çok ince dokunaç
        n = 9 + 2 * ctx.stage
        mw, mh = mw * 1.2, mh * 0.75
    elif f == 2:    # kalamar: sivri baş + yan yüzgeç
        mw, mh = mw * 0.75, mh * 1.35
        for sx in (-1, 1):
            a.add(spike_pts((mc[0] + sx * mw * 0.6, mc[1] - mh * 0.6), sx * 0.3 - math.pi / 2 + sx * 1.1, mw * 0.9, mh * 0.6), ctx.body2, 9)
    elif f == 3:    # geniş
        mw, mh = mw * 1.3, mh * 0.9
    rng = random.Random(sp["seed"])
    for i in range(n):
        t = (i - (n - 1) / 2) / max((n - 1) / 2, 1)
        base = (mc[0] + t * mw * 0.7, mc[1] + mh * 0.75)
        ph = rng.random() * 3
        L = (0.38 + 0.1 * ctx.stage) * k
        ctrl = [base]
        for j in range(1, 4):
            ctrl.append((base[0] + t * 0.12 * j * k + math.sin(j * 1.4 + ph) * 0.07 * k, base[1] + L * j / 3))
        tw = mw * (0.12 if f == 1 else 0.32)
        a.add(tube(ctrl, tw, mw * 0.04), (ctx.light if f == 1 else ctx.body) if i % 2 == 0 else ctx.body * 0.85, 5 + (i % 2))
        for j in range(2):
            p = ctrl[j + 1]
            a.ell((p[0], p[1]), (mw * 0.05, mw * 0.05), ctx.light, 7, outline=False, shade=False, line=False)
    if f == 1:
        dome = [(mc[0] + math.cos(math.pi + math.pi * i / 24) * mw, mc[1] + mh * 0.6 + math.sin(math.pi + math.pi * i / 24) * mh * 1.3) for i in range(25)]
        a.add(dome, ctx.body, 10, alpha=0.92)
    elif f == 2:
        a.add([(mc[0], mc[1] - mh * 1.25)] + [(mc[0] + math.cos(t / 12 * math.pi) * mw, mc[1] + math.sin(t / 12 * math.pi) * mh * 0.8) for t in range(13)], ctx.body, 10)
    else:
        a.ell(mc, (mw, mh), ctx.body, 10)
    body_pattern(mc, (mw, mh), ctx, 10)
    if ctx.stage > 0:
        theme_head_deco((mc[0], mc[1] - mh * 0.05), mh * 0.9, ctx)
    face((mc[0], mc[1] + mh * 0.15), ctx, mw * 0.8)
    return None


def plan_ghost(ctx):
    a, sp, k = ctx.art, ctx.sp, ctx.k
    f = sp["form"]
    w, h = 0.3 * k * sp["bw"], 0.42 * k * sp["bh"]
    c = (0.0, 0.08)
    waves = 3 + ctx.stage
    pts = []
    if f == 1:      # alev biçimli ruh
        pts.append((c[0] + w * 0.15, c[1] - h * 1.25))
    for i in range(25):
        t = math.pi + math.pi * i / 24
        top_mul = 0.8 if f != 2 else 1.0
        pts.append((c[0] + math.cos(t) * w, c[1] - h * 0.2 + math.sin(t) * h * top_mul))
    for i in range(41):
        t = i / 40
        x = c[0] + w - 2 * w * t
        if f == 2:      # küre + kuyruk
            y = c[1] + h * 0.2 + math.sin(math.pi * t) * h * 0.25
            if 0.4 < t < 0.75:
                y += math.sin((t - 0.4) / 0.35 * math.pi) * h * 0.55
        elif f == 3:    # uzun cüppe
            y = c[1] + h * 0.85 + math.sin(t * math.pi * waves * 2) * h * 0.06
            x = c[0] + (w - 2 * w * t) * 1.2
        else:
            y = c[1] + h * 0.6 + math.sin(t * math.pi * waves * 2) * h * 0.1 + (1 - abs(t - 0.5) * 2) * h * 0.05
        pts.append((x, y))
    head_adorn((c[0], c[1] - h * 0.25), w * 0.85, ctx)
    a.add(pts, ctx.light if sp["pattern"] != "spots" else ctx.body, 10, alpha=0.95)
    for sx in (-1, 1):
        a.add(leaf_pts((c[0] + sx * w * 0.9, c[1] + h * 0.05), (0.4 if sx > 0 else math.pi - 0.4), 0.18 * k, 0.1 * k), ctx.light, 9)
    face((c[0], c[1] - h * 0.15), ctx, w * 0.85)
    return None


def plan_plant(ctx):
    a, sp, k = ctx.art, ctx.sp, ctx.k
    f = sp["form"]
    bw, bh = 0.27 * k * sp["bw"], 0.25 * k * sp["bh"]
    if f == 1:      # kaktus gibi uzun
        bw, bh = bw * 0.75, bh * 1.5
    elif f == 3:    # kütük
        bw, bh = bw * 1.15, bh * 1.1
    bc = (0.0, 0.42 - bh * 1.1)
    gy = 0.44
    for i in range(3 + ctx.stage):
        t = (i - (2 + ctx.stage) / 2) / max((2 + ctx.stage) / 2, 1)
        a.add(tube([(bc[0] + t * bw * 0.5, bc[1] + bh * 0.6), (bc[0] + t * bw * 0.9, gy - 0.04), (bc[0] + t * bw * 1.3, gy)], bw * 0.22, bw * 0.06), hsv(0.08, 0.45, 0.55), 5)
    nl = sp["petals"] + ctx.stage
    lc = hsv(0.3, 0.6, 0.72)
    if f == 2:      # çiçek kafalı: yüzün etrafında taç yapraklar
        npet = 7 + ctx.stage * 2
        for i in range(npet):
            ang = 2 * math.pi * i / npet
            a.add(leaf_pts(bc, ang, bw * (1.9 + 0.2 * ctx.stage), bw * 0.75), ctx.acc if i % 2 == 0 else mixc(ctx.acc, WHITE, 0.3), 6)
    elif f == 3:    # kütük: dallar
        for sx in (-1, 1):
            a.add(tube([(bc[0] + sx * bw * 0.5, bc[1] - bh * 0.6), (bc[0] + sx * bw * 1.1, bc[1] - bh * 1.3), (bc[0] + sx * bw * 1.3, bc[1] - bh * 1.9)], bw * 0.25, bw * 0.08), hsv(0.08, 0.45, 0.5), 6)
            a.add(leaf_pts((bc[0] + sx * bw * 1.3, bc[1] - bh * 1.9), -math.pi / 2 + sx * 0.5, 0.18 * k, 0.1 * k), lc, 7)
    else:
        for i in range(nl):
            ang = -math.pi / 2 + (i - (nl - 1) / 2) * (2.2 / max(nl - 1, 1))
            a.add(leaf_pts((bc[0], bc[1] - bh * 0.6), ang, (0.3 + 0.08 * ctx.stage) * k, 0.13 * k), lc if i % 2 == 0 else lc * 0.85, 6)
    a.ell(bc, (bw, bh), ctx.body, 10)
    body_pattern(bc, (bw, bh), ctx, 10)
    for sx in (-1, 1):
        a.add(leaf_pts((bc[0] + sx * bw * 0.9, bc[1]), (0.2 if sx > 0 else math.pi - 0.2), 0.22 * k, 0.1 * k), lc, 12)
    if ctx.stage > 0:
        theme_head_deco((bc[0], bc[1] - bh * 0.4), bh * 0.95, ctx)
    face((bc[0], bc[1] + bh * 0.05), ctx, bw * 0.75)
    return gy


def plan_golem(ctx):
    a, sp, k = ctx.art, ctx.sp, ctx.k
    rng = random.Random(sp["seed"])
    f = sp["form"]
    w, h = 0.3 * k * sp["bw"], 0.28 * k * sp["bh"]
    if f == 1:
        w, h = w * 0.78, h * 1.3
    elif f == 2:
        w, h = w * 1.3, h * 0.8
    c = (0.0, 0.42 - h - 0.18 * k)
    gy = c[1] + h + 0.18 * k
    stone = ctx.body
    for sx in (-1, 1):
        if f == 3:      # süzülen taşlar: bacak yerine kayalar
            a.add(rock_pts((c[0] + sx * w * 0.4, c[1] + h * 1.25), w * 0.28, rng), stone * 0.85, 5)
            continue
        a.add([(c[0] + sx * w * 0.25, c[1] + h * 0.6), (c[0] + sx * w * 0.75, c[1] + h * 0.6), (c[0] + sx * w * 0.8, gy), (c[0] + sx * w * 0.2, gy)], stone * 0.85, 5)
    body = []
    for i in range(8):
        ang = 2 * math.pi * i / 8 + math.pi / 8
        body.append((c[0] + math.cos(ang) * w * (1.0 + 0.08 * rng.random()), c[1] + math.sin(ang) * h * (1.0 + 0.08 * rng.random())))
    a.add(body, stone, 10)
    body_pattern(c, (w, h), ctx, 10)
    for sx in (-1, 1):
        sh = (c[0] + sx * w * 1.0, c[1] - h * 0.5)
        fist = (sh[0] + sx * w * 0.45, c[1] + h * 0.75)
        a.add(tube([sh, fist], w * 0.5, w * 0.45, cap=True), stone * 0.95, 12)
        a.add(rock_pts(fist, w * 0.38, rng, 6), stone * 0.8, 13)
        if ctx.stage > 0:
            a.add(rock_pts(sh, w * 0.4, rng, 6), mixc(stone, WHITE, 0.15), 14)
    # çatlak / parlayan çizgiler
    if ctx.theme["deco"] in ("flame",) or ctx.stage == 2:
        glow = np.array([255, 170, 60]) if ctx.theme["deco"] == "flame" else ctx.acc
        for i in range(2 + ctx.stage):
            x = c[0] + (rng.random() - 0.5) * w
            a.add(tube([(x, c[1] - h * 0.4), (x + 0.05 * k, c[1]), (x - 0.03 * k, c[1] + h * 0.5)], 0.025 * k, 0.012 * k, cap=False), glow, 11, outline=False, shade=False, line=False)
    hr = 0.17 * k * sp["hr"] * [1.25, 1.05, 1.0][ctx.stage]
    hc = (c[0], c[1] - h - hr * 0.55)
    head_adorn(hc, hr, ctx)
    head = [(hc[0] - hr, hc[1] - hr * 0.8), (hc[0] + hr, hc[1] - hr * 0.85), (hc[0] + hr * 1.05, hc[1] + hr * 0.8), (hc[0] - hr * 1.0, hc[1] + hr * 0.85)]
    a.add(head, stone, 20)
    face(hc, ctx, hr)
    return gy


def plan_crab(ctx):
    a, sp, k = ctx.art, ctx.sp, ctx.k
    w, h = 0.36 * k * sp["bw"], 0.2 * k * sp["bh"]
    c = (0.0, 0.3)
    gy = c[1] + h + 0.14 * k
    for i in range(3):
        for sx in (-1, 1):
            hip = (c[0] + sx * w * (0.4 + 0.15 * i), c[1] + h * 0.5)
            knee = (hip[0] + sx * 0.12 * k, hip[1] - 0.02)
            foot = (knee[0] + sx * 0.05 * k, gy)
            a.add(tube([hip, knee, foot], 0.045 * k, 0.025 * k), ctx.body * 0.8, 4)
    f = sp["form"]
    if f == 3:      # ıstakoz kuyruğu
        for i in range(4):
            a.ell((c[0] + w * (0.9 + i * 0.28), c[1] + h * 0.1 + i * 0.02), (w * 0.2, h * 0.55 - i * 0.01), ctx.body * (0.95 - i * 0.05), 6 - i * 0.1)
        a.add(leaf_pts((c[0] + w * 2.0, c[1] + h * 0.2), 0.0, w * 0.5, h * 1.0), ctx.body2, 5)
    cl0 = [0.13, 0.17, 0.22][ctx.stage] * k
    for sx in (-1, 1):
        cl = cl0 * (1.7 if (f == 1 and sx > 0) else (0.75 if f == 1 else 1.0))
        arm0 = (c[0] + sx * w * 0.75, c[1] - h * 0.2)
        cc = (c[0] + sx * (w + cl * 0.9), c[1] - h - cl * 0.6)
        a.add(tube([arm0, (arm0[0] + sx * cl * 0.6, arm0[1] - cl * 0.5), cc], 0.07 * k, 0.06 * k), ctx.body, 8)
        a.ell(cc, (cl, cl * 0.75), ctx.body, 9, ang=sx * -0.5)
        a.add(spike_pts((cc[0] - sx * cl * 0.1, cc[1] - cl * 0.2), -math.pi / 2 - sx * 0.6, cl * 0.9, cl * 0.5), ctx.body2, 9)
    for sx in (-1, 1):
        stalk = (c[0] + sx * w * 0.28, c[1] - h * 1.5)
        a.add(tube([(c[0] + sx * w * 0.22, c[1] - h * 0.6), stalk], 0.04 * k, 0.035 * k), ctx.body, 7)
    if f == 2:      # dikenli kabuk
        for i in range(7 + 2 * ctx.stage):
            ang = math.pi + math.pi * (i + 0.5) / (7 + 2 * ctx.stage)
            a.add(spike_pts((c[0] + math.cos(ang) * w * 0.9, c[1] + math.sin(ang) * h * 0.9), ang, 0.08 * k, 0.05 * k), ctx.body2, 9)
    a.ell(c, (w, h), ctx.body, 10)
    body_pattern(c, (w, h), ctx, 10)
    back_deco([(c[0] - w * 0.6 + w * 1.2 * t / 10, c[1] - h * 0.9) for t in range(11)], ctx, 0.11 * k)
    face((c[0], c[1] - h * 1.15), ctx, w * 0.6)
    return gy


def plan_blob(ctx):
    a, sp, k = ctx.art, ctx.sp, ctx.k
    w, h = 0.32 * k * sp["bw"], 0.3 * k * sp["bh"]
    c = (0.0, 0.28)
    pts = []
    f = sp["form"]
    for i in range(48):
        t = 2 * math.pi * i / 48
        r = 1.0 + (0.18 * max(0.0, -math.sin(t)) ** 3) + 0.03 * math.sin(t * 5 + sp["seed"])
        if f == 1:      # küp jöle
            r = 1.0 / max(abs(math.cos(t)), abs(math.sin(t))) ** 0.85 * 0.85
        elif f == 2:    # dikenli
            r += 0.12 * max(0.0, math.cos(t * (6 + ctx.stage * 2)))
        elif f == 3:    # iki tepeli
            r += 0.2 * max(0.0, -math.sin(t)) * abs(math.cos(t)) * 2
        y = math.sin(t) * h * r
        if y > 0:
            y *= 0.75
        pts.append((c[0] + math.cos(t) * w * r, c[1] + y))
    head_adorn((c[0], c[1] - h * 0.3), w * 0.75, ctx)
    a.add(pts, ctx.body, 10)
    body_pattern(c, (w, h), ctx, 10)
    for i in range(1 + ctx.stage):
        x = c[0] + (i - ctx.stage / 2) * w * 0.5
        a.add(tube([(x, c[1] + h * 0.55), (x, c[1] + h * 0.85)], w * 0.16, w * 0.12), ctx.body, 9)
    face((c[0], c[1] - h * 0.05), ctx, w * 0.75)
    return c[1] + h * 0.75


def tail(ctx, base, scale):
    a, sp, k = ctx.art, ctx.sp, ctx.k
    t = sp["tail"]
    if t == "none":
        return
    L = 0.34 * k * scale * (0.8 + 0.2 * ctx.stage)
    tip = (base[0] + L * 0.7, base[1] - L * 0.8)
    mid = (base[0] + L * 0.75, base[1] - L * 0.05)
    w0 = {"thin": 0.06, "thick": 0.13, "fluffy": 0.1, "tipped": 0.07}[t] * k
    w1 = {"thin": 0.02, "thick": 0.05, "fluffy": 0.12, "tipped": 0.03}[t] * k
    a.add(tube([base, mid, tip], w0, w1), ctx.body if t != "fluffy" else ctx.light, 3)
    if t == "fluffy":
        a.ell(tip, (w1 * 1.1, w1 * 1.1), ctx.light, 4)
    if t == "tipped" or ctx.stage > 0:
        tail_tip_deco(tip, ctx, 0.07 * k)


PLANS = dict(quad=plan_quad, biped=plan_biped, serpent=plan_serpent, bird=plan_bird, fish=plan_fish, insect=plan_insect,
             cephalo=plan_cephalo, ghost=plan_ghost, plant=plan_plant, golem=plan_golem, crab=plan_crab, blob=plan_blob)


def draw_creature(g, sp_idx, stage):
    theme = THEMES[g]
    sp = make_species(g, sp_idx)
    ctx = Ctx(sp, stage, theme)
    bg = background(theme, random.Random(g * 999 + sp_idx * 3 + stage), g)
    gy = PLANS[sp["plan"]](ctx)
    if gy is not None:
        ground_shadow(bg, 0.05, 0.6 * ctx.k, gy)
    aura = None
    if stage == 2:
        aura = mixc(ctx.acc, WHITE, 0.35)
    outline_col = ctx.body * 0.22 if g not in DARK_BG else mixc(ctx.body, WHITE, 0.15) * 0.35
    img = ctx.art.render(bg, outline_col, aura)
    if sp["mirror"]:
        img = img.transpose(Image.FLIP_LEFT_RIGHT)
    return img.resize((CELL, CELL), Image.LANCZOS)


def render_set(g):
    atlas = Image.new("RGB", (COLS * CELL, ROWS * CELL), (40, 40, 40))
    for sp in range(SPECIES):
        for st in range(STAGES):
            n = sp * STAGES + st
            img = draw_creature(g, sp, st)
            atlas.paste(img, ((n % COLS) * CELL, (n // COLS) * CELL))
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, f"set_{g:02d}.jpg")
    atlas.save(path, quality=88, optimize=True)
    return path


def check_unique():
    for g, th in enumerate(THEMES):
        keys = set()
        for sp in range(SPECIES):
            s = make_species(g, sp)
            key = (s["plan"], s["head"], s["eyes"])
            assert key not in keys, (g, sp, key)
            keys.add(key)


if __name__ == "__main__":
    check_unique()
    sets = [int(a) for a in sys.argv[1:]] or list(range(len(THEMES)))
    with Pool(2) as pool:
        for p in pool.imap_unordered(render_set, sets):
            print("yazıldı", p)
