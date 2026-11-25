"""34 set x 50 tür x 3 evrim = 5100 taso için ComfyUI istemleri üretir.

Çıktı: tools/comfy/prompts.json
  [{"set": 0, "num": 1, "species": 0, "stage": 0, "seed": ..., "prompt": "..."}, ...]
Numara düzeni oyundakiyle aynı: num = tür * 3 + evrim + 1 (1-2-3 ilk türün evrimleri).
Aynı sette her türün canlı tipi (arketipi) farklıdır; özellikler ve desenler de rastgele ama tekrarsız seçilir.
Kullanım: python tools/comfy/prompts.py
"""
import json
import os
import random

HERE = os.path.dirname(os.path.abspath(__file__))
SPECIES = 50

# Canlı arketipleri: kategori -> liste
POOL = {
    "land": ["fox", "wolf", "bear cub", "deer", "lizard", "rabbit", "boar", "wildcat", "lion", "ram", "rhinoceros",
             "hedgehog", "armadillo", "mole", "monkey", "badger", "otter", "elephant", "tortoise", "gecko", "hound",
             "horse", "bull", "raccoon", "squirrel", "hamster", "pangolin", "crocodile", "kangaroo", "sloth",
             "chameleon", "lynx", "hyena", "tapir", "anteater", "porcupine", "weasel", "yak", "goat", "panther"],
    "air": ["owl", "hawk", "bat", "moth", "butterfly", "hummingbird", "raven", "heron", "dragonfly", "flying squirrel",
            "parrot", "swallow", "vulture", "peacock", "eagle", "crane", "toucan", "kingfisher", "magpie", "sugar glider"],
    "sea": ["fish", "shark", "manta ray", "octopus", "squid", "jellyfish", "seahorse", "crab", "lobster", "eel",
            "whale", "dolphin", "seal", "sea turtle", "nautilus", "anglerfish", "starfish", "shrimp", "pufferfish",
            "axolotl", "newt", "frog", "sea slug", "hermit crab", "walrus", "penguin", "narwhal", "piranha"],
    "bug": ["beetle", "mantis", "ant", "spider", "scorpion", "centipede", "snail", "caterpillar", "bee", "wasp",
            "firefly", "ladybug", "cicada", "stag beetle", "grasshopper", "pill bug", "water strider", "rhino beetle"],
    "spirit": ["mushroom creature", "flower sprite", "tree spirit", "cactus creature", "rock golem", "will-o-wisp",
               "ghost", "slime", "crystal elemental", "cloud spirit", "lantern spirit", "puppet doll", "moss golem",
               "living teapot", "seed sprite", "ember spirit", "snowman spirit", "clockwork critter"],
    "myth": ["dragon", "wyvern", "sea serpent", "hydra", "qilin", "unicorn", "basilisk", "chimera", "sphinx",
             "griffin", "phoenix", "kitsune", "tanuki", "salamander", "thunderbird", "kraken", "golem knight",
             "cerberus pup", "pegasus", "manticore", "naga", "baku", "tengu", "yeti"],
}

FEATURES = ["a long curling tail", "small horns", "tiny wings", "a spiky back", "big round eyes", "a striped pattern",
            "a spotted pattern", "armored plates", "a fluffy mane", "long ears", "a glowing gem on its forehead",
            "crystal spikes", "leafy fur", "fins along its back", "a bushy tail", "antennae", "tusks", "a shell",
            "flame-tipped ears", "frost-covered fur", "rune markings", "a crest on its head", "webbed feet",
            "feathered tail", "patterned scales", "a bell collar", "moss patches", "a split tail", "glowing freckles",
            "a scarf of vines", "tiny claws", "a curled horn", "translucent skin", "a star-shaped mark",
            "ribbon-like whiskers", "a hood of feathers", "pearl-like spots", "a lantern-shaped tail tip"]

# Set temaları (oyundaki sıra): ad, ortam/arka plan, malzeme ve öğe, renkler, tercih edilen kategoriler
THEMES = [
    ("Kor Vadisi", "a valley of glowing embers and smoldering rocks", "fire and ember", "red, orange and charcoal", ["land", "myth"]),
    ("Derin Su", "the dark deep ocean with light rays from above", "deep water and bioluminescence", "deep blue, teal and cyan glow", ["sea"]),
    ("Taş Kök", "an ancient forest of stone roots and boulders", "stone and old roots", "grey, moss green and brown", ["land", "spirit"]),
    ("Gece Rüzgârı", "a windy night sky over hills with a big moon", "night wind and shadow", "indigo, violet and silver", ["air", "myth"]),
    ("Buz Tepesi", "snowy icy mountain peaks", "ice and frost", "white, ice blue and pale cyan", ["land", "sea"]),
    ("Şimşek Ovası", "a stormy plain with lightning bolts", "electricity and lightning", "yellow, electric blue and dark grey", ["land", "air"]),
    ("Kum Çölü", "sand dunes under a hot sun", "sand and desert", "sand beige, ochre and terracotta", ["land", "bug"]),
    ("Mantar Ormanı", "a forest of giant glowing mushrooms", "mushroom and spores", "purple, pink and moss green", ["spirit", "bug"]),
    ("Demir Dağ", "an iron mountain with forges and gears", "iron and rusty metal", "steel grey, rust orange and black", ["land", "spirit"]),
    ("Mercan Koyu", "a colorful coral reef in shallow water", "coral and pearls", "coral pink, turquoise and sand", ["sea"]),
    ("Gölge Mağara", "a dark cave with faint purple light", "shadow and darkness", "black, deep purple and pale violet", ["myth", "bug"]),
    ("Yıldız Bahçe", "a starlit garden with glowing flowers", "stars and constellations", "navy, gold and soft white", ["spirit", "air"]),
    ("Lav Gölü", "a lake of molten lava with dark volcanic rock", "lava and magma", "crimson, molten orange and black", ["myth", "land"]),
    ("Sis Bataklığı", "a misty swamp with twisted trees", "swamp mist and murky water", "olive, grey green and muted teal", ["sea", "bug"]),
    ("Kristal Vadi", "a valley of huge shining crystals", "crystal and gemstone", "amethyst, aqua and white sparkle", ["spirit", "land"]),
    ("Ay Tapınağı", "a moonlit ancient temple", "moonlight and silver", "silver, pale blue and lilac", ["myth", "air"]),
    ("Bulut Adası", "floating islands above the clouds", "clouds and sky", "sky blue, white and soft gold", ["air", "spirit"]),
    ("Kızıl Kanyon", "a deep red rock canyon", "red rock and dust", "rust red, sandstone and brown", ["land", "bug"]),
    ("Zümrüt Orman", "a lush emerald jungle", "leaves and jungle", "emerald green, lime and gold", ["land", "air", "bug"]),
    ("Fırtına Burnu", "a stormy sea cape with crashing waves", "storm and sea spray", "slate blue, white foam and dark grey", ["sea", "air"]),
    ("Kehribar Köy", "a cozy village in warm amber autumn light", "amber and autumn leaves", "amber, honey and warm brown", ["land", "spirit"]),
    ("Gümüş Nehir", "a clear silver river in a calm valley", "flowing water and silver scales", "silver, light blue and green", ["sea", "land"]),
    ("Yosun Mağara", "a damp cave full of glowing moss", "moss and dripping water", "dark green, glowing lime and stone grey", ["bug", "spirit"]),
    ("Güneş Sarayı", "a golden sun palace with bright light", "sunlight and gold", "gold, white and warm yellow", ["myth", "air"]),
    ("Kuyruklu Yıldız", "outer space with comets and nebulae", "cosmic dust and comets", "deep space blue, magenta and starlight", ["myth", "spirit"]),
    ("Kar Ovası", "a quiet snowy plain with pine trees", "snow and winter", "white, pale grey and pine green", ["land", "air"]),
    ("Altın Kum", "a golden beach with gentle waves", "golden sand and shells", "gold, sea blue and cream", ["sea", "bug"]),
    ("Mor Dağ", "purple mountains at dusk", "dusk and lavender stone", "lavender, plum and peach", ["land", "myth"]),
    ("Rüzgâr Gülü", "windy flower fields with pinwheels", "wind and petals", "mint, rose and sky blue", ["air", "spirit"]),
    ("Gök Kubbe", "a vast dome of sky with auroras", "aurora and sky", "aurora green, violet and night blue", ["air", "myth"]),
    ("Kaya Kalesi", "a rocky fortress on a cliff", "rock and fortress stone", "granite grey, moss and bronze", ["land", "spirit"]),
    ("Dalga Kıyısı", "a sunny seashore with big waves", "waves and foam", "turquoise, white and sand", ["sea"]),
    ("Volkan Ağzı", "the crater of an erupting volcano", "volcanic fire and ash", "black, fiery red and ash grey", ["myth", "land", "bug"]),
    ("Çiçek Vadisi", "a valley full of colorful flowers", "flowers and petals", "pink, yellow and fresh green", ["bug", "spirit", "air"]),
]

STAGE = [
    "a small cute baby {a} creature, chubby round proportions, curious expression",
    "a young {a} creature, bigger and more confident, sharper features, first signs of {elem} power",
    "a fully evolved majestic {a} creature, large and powerful, ornate {elem} armor and features, heroic pose",
]

STYLE = ("fantasy creature trading card art, single creature, full body, centered, three-quarter view, "
         "highly detailed digital painting, realistic textures, soft cinematic lighting, depth of field background")


def build():
    out = []
    for g, (name, place, elem, colors, cats) in enumerate(THEMES):
        rng = random.Random(1000 + g)
        pref = [a for c in cats for a in POOL[c]]
        rng.shuffle(pref)
        rest = [a for c in POOL if c not in cats for a in POOL[c]]
        rng.shuffle(rest)
        chosen = []
        for a in pref + rest:
            if a not in chosen:
                chosen.append(a)
            if len(chosen) == SPECIES:
                break
        feats = FEATURES[:]
        for sp, arch in enumerate(chosen):
            f = rng.sample(feats, 2)
            base_seed = rng.randrange(1, 2 ** 31)
            for st in range(3):
                body = STAGE[st].format(a=arch, elem=elem)
                prompt = (f"{body}, with {f[0]} and {f[1]}, made of {elem} themed details, color palette of {colors}, "
                          f"background: {place}, {STYLE}")
                out.append({"set": g, "set_name": name, "num": sp * 3 + st + 1, "species": sp, "stage": st,
                            "archetype": arch, "seed": base_seed, "prompt": prompt})
    return out


if __name__ == "__main__":
    data = build()
    with open(os.path.join(HERE, "prompts.json"), "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=1)
    print(len(data), "istem yazıldı")
