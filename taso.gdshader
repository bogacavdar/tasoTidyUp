shader_type spatial;

// Taso: ince bir set rengi kenar; yüzünü neredeyse tamamen kaplayan, setin temasına uygun
// prosedürel çizim ve altta küçük numara. Hiç resim dosyası yok: her şey burada çiziliyor.
//
// Benzersizlik: her motifte ayrık özellikler (kulak, göz, ağız, aksesuar...) taso numarasından
// karışık tabanlı sayı sistemiyle türetilir (pk fonksiyonu). Böylece bir setteki 150 tasonun
// her biri farklı bir kombinasyon alır; üstüne renk, ölçek, açı ve arka plan rastgele değişir.
//
// INSTANCE_CUSTOM: x = benzersiz taso id (set * nper + numara - 1)
//                  y = holo (0/1)
//                  z = motif (0 yaratık, 1 balık, 2 çiçek, 3 kristal, 4 gök cismi,
//                             5 mantar, 6 kuş, 7 manzara, 8 böcek)
//                  w = tema: tam kısmı mod (0 normal, 1 gece/koyu, 2 pastel, 3 taş/metalik),
//                            kesir kısmı ana renk tonu (hue)
// Atlas: 10 sütun x 'rows' satır, hücre 128x64. Satır 0: rakamlar 0-9.
uniform sampler2D atlas : source_color, filter_linear;
uniform float nper = 150.0;
uniform float rows = 5.0;
uniform float radius = 0.12;

const float DISC = 0.465;      // resmin kapladığı daire (uv yarıçapı, kenar 0.5)
const float ART_SCALE = 0.76;  // çizim koordinatları: diskin kenarı ~0.7

varying vec2 face_uv;
varying float face;
varying vec4 inst;

void vertex() {
	face_uv = VERTEX.xz / (2.0 * radius) + 0.5;
	face = NORMAL.y;
	inst = INSTANCE_CUSTOM;
}

// ---------------- Rakamlar ----------------
float sample_cell(vec2 cell, vec2 local) {
	if (local.x < 0.0 || local.x > 1.0 || local.y < 0.0 || local.y > 1.0) {
		return 0.0;
	}
	return texture(atlas, (cell + local) / vec2(10.0, rows)).a;
}

int digit_at(int num, int digits, int idx) {
	int k = digits - 1 - idx;
	if (k == 2) {
		return num / 100;
	}
	if (k == 1) {
		return (num / 10) % 10;
	}
	return num % 10;
}

float draw_number(vec2 uv, int num, vec2 center, float dw, float dh) {
	int digits = num >= 100 ? 3 : (num >= 10 ? 2 : 1);
	vec2 nq = (uv - vec2(center.x - dw * float(digits) * 0.5, center.y - dh * 0.5)) / vec2(dw, dh);
	if (nq.x >= 0.0 && nq.x < float(digits) && nq.y >= 0.0 && nq.y <= 1.0) {
		int idx = int(floor(nq.x));
		int dig = digit_at(num, digits, idx);
		return sample_cell(vec2(float(dig), 0.0), vec2(0.25 + fract(nq.x) * 0.5, nq.y));
	}
	return 0.0;
}

// ---------------- Yardımcılar ----------------
float hsh(float n, float k) {
	return fract(sin(n * 12.9898 + k * 78.233) * 43758.5453);
}

// Karışık taban basamağı: numaradan ayrık özellik seçer (benzersizliği garanti eder)
float pk(float n, float div, float m) {
	return mod(floor(n / div), m);
}

vec3 hsv2rgb(vec3 c) {
	vec3 q = abs(fract(c.xxx + vec3(1.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
	return c.z * mix(vec3(1.0), clamp(q - 1.0, 0.0, 1.0), c.y);
}

vec2 rot(vec2 v, float a) {
	float s = sin(a);
	float co = cos(a);
	return vec2(co * v.x - s * v.y, s * v.x + co * v.y);
}

float aa(float d) {
	return 1.0 - smoothstep(-0.006, 0.006, d);
}

float ell_d(vec2 p, vec2 c, vec2 r, float a) {
	vec2 q = rot(p - c, -a);
	return (length(q / r) - 1.0) * min(r.x, r.y);
}

// Döndürülmüş, kenar çizgili, hacimli gölgelendirilmiş elips (üst-sol ışık + parlama)
vec3 blob(vec3 col, vec2 p, vec2 c, vec2 r, float a, vec3 fc, vec3 lc, float line) {
	vec2 q = rot(p - c, -a);
	vec2 v = q / r;
	float d = (length(v) - 1.0) * min(r.x, r.y);
	col = mix(col, lc, aa(d - line));
	float shade = 1.0 + 0.16 * (-v.x * 0.6 - v.y * 0.8) - 0.12 * dot(v, v);
	float spec = smoothstep(0.34, 0.0, length(v - vec2(-0.38, -0.45))) * 0.3;
	return mix(col, fc * shade + vec3(spec), aa(d));
}

vec3 shape(vec3 col, float d, vec3 fc, vec3 lc, float line) {
	col = mix(col, lc, aa(d - line));
	return mix(col, fc, aa(d));
}

vec3 pal(float hue, float mode, float dh, float sat_mul, float val_mul) {
	float sat = 0.65;
	float val = 0.92;
	if (mode > 0.5 && mode < 1.5) { sat = 0.6; val = 0.8; }
	else if (mode > 1.5 && mode < 2.5) { sat = 0.35; val = 0.97; }
	else if (mode > 2.5) { sat = 0.14; val = 0.78; }
	return hsv2rgb(vec3(fract(hue + dh), clamp(sat * sat_mul, 0.0, 1.0), clamp(val * val_mul, 0.0, 1.0)));
}

vec3 bg_col(float hue, float mode, vec2 p) {
	float g = clamp(p.y * 0.6 + 0.5, 0.0, 1.0);
	if (mode > 0.5 && mode < 1.5) {
		return hsv2rgb(vec3(hue, 0.55, mix(0.14, 0.3, g)));
	}
	if (mode > 1.5 && mode < 2.5) {
		return hsv2rgb(vec3(hue, mix(0.05, 0.16, g), 0.99));
	}
	if (mode > 2.5) {
		return hsv2rgb(vec3(hue, 0.06, mix(0.95, 0.85, g)));
	}
	return hsv2rgb(vec3(hue, mix(0.08, 0.22, g), 0.99));
}

// Arka plan deseni: ışınlar, puantiye, çapraz çizgi, halka ya da düz
vec3 bg_pattern(vec3 bgc, vec2 p, float s, float hue, float mode) {
	float kind = floor(hsh(s, 50.0) * 5.0);
	vec3 alt = mix(bgc, pal(hue, mode, (hsh(s, 52.0) - 0.5) * 0.3, 0.6, 1.0), 0.4);
	float a = atan(p.y, p.x);
	float r = length(p);
	float m = 0.0;
	if (kind < 0.5) {
		m = step(0.5, fract(a / TAU * (10.0 + floor(hsh(s, 51.0) * 8.0))));
	} else if (kind < 1.5) {
		vec2 g = fract(rot(p, 0.6) * (5.0 + 3.0 * hsh(s, 53.0))) - 0.5;
		m = step(length(g), 0.17);
	} else if (kind < 2.5) {
		m = step(0.5, fract((p.x + p.y) * (3.0 + 3.0 * hsh(s, 54.0))));
	} else if (kind < 3.5) {
		m = step(0.5, fract(r * (4.0 + 3.0 * hsh(s, 55.0))));
	}
	return mix(bgc, alt, m * 0.5);
}

vec3 eye(vec3 col, vec2 p, vec2 c, float r, vec3 lc, float look) {
	col = blob(col, p, c, vec2(r), 0.0, vec3(1.0), lc, 0.016);
	col = blob(col, p, c + vec2(look * r * 0.25, r * 0.15), vec2(r * 0.52), 0.0, vec3(0.06), vec3(0.06), 0.0);
	col = blob(col, p, c + vec2(look * r * 0.25 - r * 0.2, -r * 0.1), vec2(r * 0.16), 0.0, vec3(1.0), vec3(1.0), 0.0);
	return col;
}

vec3 sparkle(vec3 col, vec2 p, vec2 c, float r, vec3 sc) {
	vec2 q = abs(p - c);
	float d = min(q.x * 4.0 + q.y, q.y * 4.0 + q.x) * 0.25 - r * 0.25;
	return mix(col, sc, aa(d));
}

// Yay çizgisi: below > 0 ise merkezin altındaki yarım (gülümseme), değilse üstündeki
vec3 arc_line(vec3 col, vec2 p, vec2 c, float r, float w, float below, vec3 lc) {
	float d = abs(length(p - c) - r) - w;
	return mix(col, lc, aa(max(d, below > 0.0 ? (c.y - p.y) : (p.y - c.y))));
}

// ---------------- Motif 0: yaratık ----------------
// ayrık: kulak(4) x göz(3) x ağız(4) x aksesuar(5) = 240 kombinasyon
vec3 m_creature(vec2 p, float n, float s, float hue, float mode, vec3 col) {
	float ear = pk(n, 1.0, 4.0);
	float eyes = pk(n, 4.0, 3.0) + 1.0;
	float mouth = pk(n, 12.0, 4.0);
	float acc = pk(n, 48.0, 5.0);
	vec3 body_c = pal(hue, mode, (hsh(s, 1.0) - 0.5) * 0.3, 0.75 + 0.5 * hsh(s, 2.0), 0.9 + 0.15 * hsh(s, 21.0));
	vec3 line_c = body_c * 0.32;
	vec3 light_c = mix(body_c, vec3(1.0), 0.6);
	vec3 accent = pal(hue, mode, 0.35 + 0.3 * hsh(s, 22.0), 1.15, 1.0);
	float bshape = floor(hsh(s, 15.0) * 4.0);
	vec2 br = vec2(0.3 + 0.1 * hsh(s, 3.0), 0.27 + 0.09 * hsh(s, 4.0));
	if (bshape > 1.5 && bshape < 2.5) { br = vec2(br.x * 0.82, br.y * 1.25); }
	if (bshape > 2.5) { br = vec2(br.x * 1.2, br.y * 0.85); }
	vec2 bc = vec2(0.0, 0.08);
	float top = bc.y - br.y;
	float lw = 0.024;

	if (hsh(s, 9.0) > 0.45) {
		float side = hsh(s, 10.0) > 0.5 ? 1.0 : -1.0;
		col = blob(col, p, vec2(side * (br.x + 0.05), bc.y + 0.07), vec2(0.06, 0.17), side * 0.9, body_c, line_c, lw);
		col = blob(col, p, vec2(side * (br.x + 0.16), bc.y - 0.05), vec2(0.06), 0.0, accent, line_c, lw);
	}
	for (int i = 0; i < 2; i++) {
		float sx = i == 0 ? -1.0 : 1.0;
		if (ear < 0.5) {
			col = blob(col, p, vec2(sx * 0.14, top + 0.02), vec2(0.045, 0.15), sx * 0.55, vec3(0.95, 0.92, 0.82), line_c, lw);
		} else if (ear < 1.5) {
			col = blob(col, p, vec2(sx * 0.18, top + 0.03), vec2(0.08, 0.2), sx * 0.45, body_c, line_c, lw);
			col = blob(col, p, vec2(sx * 0.18, top + 0.05), vec2(0.035, 0.11), sx * 0.45, accent, accent, 0.0);
		} else if (ear < 2.5) {
			col = blob(col, p, vec2(sx * 0.21, top + 0.07), vec2(0.11), 0.0, body_c, line_c, lw);
			col = blob(col, p, vec2(sx * 0.21, top + 0.07), vec2(0.055), 0.0, light_c, light_c, 0.0);
		} else {
			col = blob(col, p, vec2(sx * 0.1, top - 0.09), vec2(0.015, 0.13), sx * 0.35, line_c, line_c, 0.0);
			col = blob(col, p, vec2(sx * 0.155, top - 0.21), vec2(0.055), 0.0, accent, line_c, lw);
		}
	}
	for (int i = 0; i < 2; i++) {
		float sx = i == 0 ? -1.0 : 1.0;
		col = blob(col, p, vec2(sx * br.x * 0.5, bc.y + br.y * 0.93), vec2(0.1, 0.06), 0.0, body_c * 0.8, line_c, lw);
	}
	// gövde (armut biçiminde ise altta ikinci elips)
	if (bshape > 0.5 && bshape < 1.5) {
		col = blob(col, p, bc + vec2(0.0, br.y * 0.35), vec2(br.x * 1.12, br.y * 0.75), 0.0, body_c, line_c, lw);
	}
	float bodyd = ell_d(p, bc, br, 0.0);
	col = blob(col, p, bc, br, 0.0, body_c, line_c, lw);
	float pattern = floor(hsh(s, 16.0) * 4.0);
	vec3 spot = mix(body_c, line_c, 0.35);
	if (pattern < 0.5) {
		col = blob(col, p, vec2(0.0, bc.y + br.y * 0.35), vec2(br.x * 0.6, br.y * 0.5), 0.0, light_c, light_c, 0.0);
	} else if (pattern < 1.5) {
		for (int i = 0; i < 4; i++) {
			float fi = float(i);
			vec2 sp = bc + vec2((hsh(s, 30.0 + fi) - 0.5) * br.x * 1.4, (hsh(s, 40.0 + fi) - 0.5) * br.y * 1.2);
			col = mix(col, spot, aa(max(length(p - sp) - 0.03 - 0.02 * hsh(s, 60.0 + fi), bodyd + 0.03)));
		}
	} else if (pattern < 2.5) {
		float band = step(0.5, fract((p.y - bc.y) * 9.0 + hsh(s, 17.0)));
		col = mix(col, spot, aa(bodyd + 0.03) * band * 0.75);
	} else {
		col = mix(col, light_c, aa(max(bodyd + 0.03, -(p.x + br.x * 0.1))) * 0.6);
	}
	// gözler
	float er = 0.06 + 0.04 * hsh(s, 8.0);
	float ey = bc.y - br.y * 0.32;
	float look = hsh(s, 11.0) * 2.0 - 1.0;
	if (eyes < 1.5) {
		col = eye(col, p, vec2(0.0, ey), er * 1.6, line_c, look);
	} else if (eyes < 2.5) {
		col = eye(col, p, vec2(-0.11, ey), er, line_c, look);
		col = eye(col, p, vec2(0.11, ey), er, line_c, look);
	} else {
		col = eye(col, p, vec2(-0.13, ey + 0.02), er * 0.9, line_c, look);
		col = eye(col, p, vec2(0.13, ey + 0.02), er * 0.9, line_c, look);
		col = eye(col, p, vec2(0.0, ey - 0.09), er * 0.75, line_c, look);
	}
	// kaşlar
	float brow = floor(hsh(s, 18.0) * 3.0);
	if (brow > 0.5 && eyes > 1.5) {
		float tilt = brow < 1.5 ? 0.35 : -0.35;
		col = blob(col, p, vec2(-0.11, ey - er - 0.035), vec2(0.06, 0.013), tilt, line_c, line_c, 0.0);
		col = blob(col, p, vec2(0.11, ey - er - 0.035), vec2(0.06, 0.013), -tilt, line_c, line_c, 0.0);
	}
	// yanaklar ve ağız
	float my = bc.y + br.y * 0.14;
	vec3 cheek = mix(light_c, vec3(1.0, 0.5, 0.6), 0.6);
	col = blob(col, p, vec2(-br.x * 0.62, my - 0.01), vec2(0.045, 0.028), 0.0, cheek, cheek, 0.0);
	col = blob(col, p, vec2(br.x * 0.62, my - 0.01), vec2(0.045, 0.028), 0.0, cheek, cheek, 0.0);
	vec3 mouth_c = vec3(0.25, 0.05, 0.08);
	if (mouth < 0.5) {
		col = blob(col, p, vec2(0.0, my), vec2(0.06, 0.03), 0.0, mouth_c, line_c, 0.01);
	} else if (mouth < 1.5) {
		col = arc_line(col, p, vec2(0.0, my - 0.06), 0.075, 0.012, 1.0, line_c);
	} else if (mouth < 2.5) {
		col = blob(col, p, vec2(0.0, my + 0.01), vec2(0.075, 0.055), 0.0, mouth_c, line_c, 0.01);
		col = blob(col, p, vec2(0.0, my + 0.04), vec2(0.045, 0.025), 0.0, vec3(0.95, 0.45, 0.5), vec3(0.95, 0.45, 0.5), 0.0);
	} else {
		col = blob(col, p, vec2(0.0, my), vec2(0.07, 0.03), 0.0, mouth_c, line_c, 0.01);
		col = blob(col, p, vec2(-0.03, my - 0.004), vec2(0.014, 0.024), 0.0, vec3(1.0), vec3(1.0), 0.0);
		col = blob(col, p, vec2(0.03, my - 0.004), vec2(0.014, 0.024), 0.0, vec3(1.0), vec3(1.0), 0.0);
	}
	// aksesuar: yok / taç / fiyonk / alın taşı / atkı
	vec3 gold = vec3(1.0, 0.8, 0.25);
	if (acc > 0.5 && acc < 1.5) {
		float zig = abs(fract((p.x + 0.14) / 0.07) * 2.0 - 1.0);
		float crown = max(max(abs(p.x) - 0.14, p.y - (top + 0.03)), (top - 0.05 - 0.07 * zig) - p.y);
		col = shape(col, crown, gold, gold * 0.45, 0.014);
		col = blob(col, p, vec2(0.0, top - 0.02), vec2(0.022), 0.0, accent, gold * 0.4, 0.006);
	} else if (acc > 1.5 && acc < 2.5) {
		vec2 bp = vec2(br.x * 0.45, top + 0.03);
		col = blob(col, p, bp + vec2(-0.05, 0.0), vec2(0.06, 0.035), 0.5, accent, accent * 0.45, 0.012);
		col = blob(col, p, bp + vec2(0.05, 0.0), vec2(0.06, 0.035), -0.5, accent, accent * 0.45, 0.012);
		col = blob(col, p, bp, vec2(0.022), 0.0, accent * 0.8, accent * 0.45, 0.01);
	} else if (acc > 2.5 && acc < 3.5) {
		vec2 q = abs(p - vec2(0.0, ey - er - (eyes > 2.5 ? 0.15 : 0.06)));
		col = shape(col, (q.x + q.y) * 0.7 - 0.03, accent, accent * 0.4, 0.01);
	} else if (acc > 3.5) {
		float sy = bc.y + br.y * 0.45;
		col = mix(col, accent, aa(max(abs(p.y - sy) - 0.035, bodyd + 0.005)));
		col = blob(col, p, vec2(br.x * 0.55, sy + 0.08), vec2(0.035, 0.08), -0.3, accent, accent * 0.45, 0.01);
	}
	return col;
}

// ---------------- Motif 1: balık ----------------
// ayrık: yön(2) x desen(3) x kuyruk(3) x sırt yüzgeci(3) x ek(3) = 162
vec3 m_fish(vec2 p, float n, float s, float hue, float mode, vec3 col) {
	float dir = pk(n, 1.0, 2.0) < 0.5 ? 1.0 : -1.0;
	float pat = pk(n, 2.0, 3.0);
	float tail = pk(n, 6.0, 3.0);
	float dorsal = pk(n, 18.0, 3.0);
	float extra = pk(n, 54.0, 3.0);
	vec2 q = vec2(p.x * dir, p.y);
	vec3 body_c = pal(hue, mode, (hsh(s, 2.0) - 0.5) * 0.3, 0.8 + 0.4 * hsh(s, 12.0), 1.0);
	vec3 line_c = body_c * 0.32;
	vec3 fin_c = pal(hue, mode, 0.1 + 0.25 * hsh(s, 3.0), 1.1, 0.9);
	vec2 br = vec2(0.3 + 0.08 * hsh(s, 4.0), 0.17 + 0.1 * hsh(s, 5.0));
	vec2 bc = vec2(-0.06, 0.02);
	for (int i = 0; i < 3; i++) {
		float fi = float(i);
		vec2 bp = vec2(-0.42 + 0.08 * fi, -0.34 - 0.11 * fi + 0.05 * hsh(s, 20.0 + fi));
		float d = abs(length(q - bp) - (0.03 + 0.012 * fi)) - 0.006;
		col = mix(col, mix(col, vec3(1.0), 0.8), aa(d));
	}
	float tx = bc.x + br.x + 0.06;
	if (tail < 0.5) {
		col = blob(col, q, vec2(tx, -0.08), vec2(0.07, 0.17), -0.7, fin_c, line_c, 0.02);
		col = blob(col, q, vec2(tx, 0.08), vec2(0.07, 0.17), 0.7, fin_c, line_c, 0.02);
	} else if (tail < 1.5) {
		col = blob(col, q, vec2(tx + 0.04, 0.0), vec2(0.14, 0.17), 0.0, fin_c, line_c, 0.02);
	} else {
		col = blob(col, q, vec2(tx + 0.06, -0.06), vec2(0.17, 0.04), -0.35, fin_c, line_c, 0.018);
		col = blob(col, q, vec2(tx + 0.06, 0.06), vec2(0.17, 0.04), 0.35, fin_c, line_c, 0.018);
		col = blob(col, q, vec2(tx + 0.08, 0.0), vec2(0.15, 0.03), 0.0, fin_c, line_c, 0.018);
	}
	if (dorsal < 0.5) {
		col = blob(col, q, vec2(bc.x + 0.03, bc.y - br.y), vec2(0.13, 0.07), 0.25, fin_c, line_c, 0.02);
	} else if (dorsal < 1.5) {
		for (int i = 0; i < 3; i++) {
			float fi = float(i);
			col = blob(col, q, vec2(bc.x - 0.1 + fi * 0.09, bc.y - br.y - 0.02), vec2(0.03, 0.08), 0.3, fin_c, line_c, 0.016);
		}
	}
	col = blob(col, q, vec2(bc.x + 0.06, bc.y + br.y * 0.95), vec2(0.08, 0.05), -0.3, fin_c, line_c, 0.02);
	float bd = ell_d(q, bc, br, 0.0);
	col = blob(col, q, bc, br, 0.0, body_c, line_c, 0.024);
	vec3 pc = mix(body_c, line_c, 0.4);
	if (pat < 0.5) {
		float band = step(0.5, fract((q.x + 0.4) * (5.0 + 4.0 * hsh(s, 7.0))));
		col = mix(col, pc, aa(bd + 0.03) * band * 0.8);
	} else if (pat < 1.5) {
		vec2 cell = fract(q * (8.0 + 4.0 * hsh(s, 13.0))) - 0.5;
		col = mix(col, pc, aa(bd + 0.03) * aa(length(cell) - 0.18) * 0.8);
	} else {
		col = mix(col, mix(body_c, vec3(1.0), 0.5), aa(max(bd + 0.02, -(q.y - bc.y - br.y * 0.2))) * 0.8);
	}
	float gd = abs(length(q - vec2(bc.x - br.x * 0.25, bc.y)) - br.y * 0.7) - 0.008;
	col = mix(col, line_c, aa(max(gd, max(bd + 0.03, q.x - bc.x + br.x * 0.25))));
	vec2 eye_p = vec2(bc.x - br.x * 0.6, bc.y - br.y * 0.25);
	col = eye(col, q, eye_p, 0.055 + 0.025 * hsh(s, 8.0), line_c, -1.0);
	vec2 mp = vec2(bc.x - br.x * 0.95, bc.y + br.y * 0.2);
	col = blob(col, q, mp, vec2(0.035, 0.017), 0.3, vec3(0.3, 0.05, 0.08), line_c, 0.0);
	if (extra < 0.5) {
		col = blob(col, q, mp + vec2(-0.07, 0.04), vec2(0.08, 0.01), 0.5, line_c, line_c, 0.0);
		col = blob(col, q, mp + vec2(-0.06, -0.01), vec2(0.08, 0.01), -0.3, line_c, line_c, 0.0);
	} else if (extra < 1.5) {
		col = blob(col, q, vec2(eye_p.x - 0.02, bc.y - br.y - 0.08), vec2(0.012, 0.1), -0.5, line_c, line_c, 0.0);
		col = blob(col, q, vec2(eye_p.x - 0.1, bc.y - br.y - 0.15), vec2(0.04), 0.0, vec3(1.0, 1.0, 0.6), vec3(1.0, 0.9, 0.3), 0.012);
	}
	return col;
}

// ---------------- Motif 2: çiçek / mercan ----------------
// ayrık: yaprak sayısı(4) x yaprak biçimi(3) x göbek(3) x ek(5) = 180
vec3 m_flower(vec2 p, float n, float s, float hue, float mode, vec3 col) {
	float petals = 5.0 + pk(n, 1.0, 4.0);
	float pshape = pk(n, 4.0, 3.0);
	float core_t = pk(n, 12.0, 3.0);
	float extra = pk(n, 36.0, 5.0);
	vec3 stem_c = pal(0.33, mode, (hsh(s, 1.0) - 0.5) * 0.1, 1.0, 0.75);
	vec3 petal_c = pal(hue, mode, (hsh(s, 2.0) - 0.5) * 0.35, 0.8 + 0.4 * hsh(s, 14.0), 1.0);
	vec3 petal2 = pal(hue, mode, 0.1 + 0.25 * hsh(s, 3.0), 1.2, 0.85);
	vec3 line_c = petal_c * 0.38;
	vec2 fc = vec2(0.0, -0.08);
	col = mix(col, stem_c * 0.6, aa(max(abs(p.x + 0.04 * sin(p.y * 6.0)) - 0.035, -(p.y - fc.y))));
	col = mix(col, stem_c, aa(max(abs(p.x + 0.04 * sin(p.y * 6.0)) - 0.022, -(p.y - fc.y))));
	col = blob(col, p, vec2(0.13, 0.4), vec2(0.14, 0.055), -0.5, stem_c, stem_c * 0.5, 0.015);
	if (hsh(s, 4.0) > 0.4) {
		col = blob(col, p, vec2(-0.13, 0.3), vec2(0.12, 0.05), 0.5, stem_c, stem_c * 0.5, 0.015);
	}
	vec2 d = p - fc;
	float a = atan(d.y, d.x) + hsh(s, 6.0) * 3.0;
	float sec = TAU / petals;
	float a2 = mod(a + sec * 0.5, sec) - sec * 0.5;
	vec2 q = length(d) * vec2(cos(a2), sin(a2));
	float pl = 0.2 + 0.06 * hsh(s, 7.0);
	float pw = 0.08 * (pshape < 0.5 ? 0.75 : (pshape < 1.5 ? 1.05 : 1.4)) * (petals < 6.5 ? 1.15 : 0.9);
	col = blob(col, q, vec2(pl, 0.0), vec2(pl, pw), 0.0, petal_c, line_c, 0.018);
	if (pshape > 1.5) {
		col = mix(col, line_c, aa(max(abs(q.y) - 0.006, max(q.x - pl * 1.6, 0.05 - q.x))) * 0.6);
	}
	float a3 = mod(a + sec, sec) - sec * 0.5;
	vec2 q2 = length(d) * vec2(cos(a3), sin(a3));
	col = blob(col, q2, vec2(pl * 0.55, 0.0), vec2(pl * 0.55, pw * 0.7), 0.0, petal2, line_c, 0.014);
	vec3 core = mix(pal(fract(hue + 0.15), 0.0, 0.0, 1.0, 1.0), vec3(1.0, 0.85, 0.3), 0.6);
	col = blob(col, p, fc, vec2(0.08 + 0.02 * hsh(s, 9.0)), 0.0, core, line_c, 0.016);
	if (core_t < 0.5) {
		vec2 cell = fract((p - fc) * 40.0) - 0.5;
		col = mix(col, core * 0.6, aa(length(p - fc) - 0.075) * aa(length(cell) - 0.2) * 0.7);
	} else if (core_t < 1.5) {
		col = mix(col, core * 0.6, aa(abs(length(p - fc) - 0.045) - 0.01));
	} else {
		col = mix(col, core * 0.55, aa(length(p - fc) - 0.08) * step(0.5, fract(a / TAU * 12.0)) * 0.6);
	}
	vec2 ep = vec2(0.33 * (hsh(s, 70.0) > 0.5 ? 1.0 : -1.0), -0.38);
	if (extra < 0.5) {
		col = sparkle(col, p, ep, 0.09, vec3(1.0, 1.0, 0.85));
	} else if (extra < 1.5) {
		// arı
		col = blob(col, p, ep + vec2(-0.02, -0.04), vec2(0.04, 0.025), -0.4, vec3(1.0), vec3(0.6), 0.008);
		col = blob(col, p, ep, vec2(0.06, 0.04), 0.0, vec3(1.0, 0.82, 0.15), vec3(0.15), 0.012);
		col = mix(col, vec3(0.1), aa(max(ell_d(p, ep, vec2(0.06, 0.04), 0.0), abs(fract((p.x - ep.x) * 25.0) - 0.5) - 0.2)) * 0.9);
	} else if (extra < 2.5) {
		// kelebek
		vec3 wc = pal(fract(hue + 0.5), 0.0, 0.0, 1.0, 1.0);
		col = blob(col, p, ep + vec2(-0.045, -0.02), vec2(0.045, 0.06), 0.4, wc, wc * 0.4, 0.01);
		col = blob(col, p, ep + vec2(0.045, -0.02), vec2(0.045, 0.06), -0.4, wc, wc * 0.4, 0.01);
		col = blob(col, p, ep, vec2(0.012, 0.05), 0.0, vec3(0.1), vec3(0.1), 0.0);
	} else if (extra < 3.5) {
		// ikinci küçük çiçek
		vec2 fp = vec2(-ep.x * 0.9, 0.32);
		col = blob(col, p, fp, vec2(0.07), 0.0, petal2, line_c, 0.012);
		col = blob(col, p, fp, vec2(0.03), 0.0, core, line_c, 0.01);
	}
	return col;
}

// ---------------- Motif 3: kristal ----------------
// ayrık: dizilim(4) x sayı(3) x yüzey(2) x renk karışımı(3) x taban(3) = 216
float crystal_d(vec2 q, float w, float h) {
	float taper = clamp((q.y + h) / (0.4 * h), 0.0, 1.0);
	return max(abs(q.x) - w * taper, max(q.y - h * 0.5, -h - q.y));
}

vec3 one_crystal(vec3 col, vec2 p, vec2 c, float w, float h, float a, vec3 cc, float facet) {
	vec2 q = rot(p - c, -a);
	float d = crystal_d(q, w, h);
	col = mix(col, cc * 0.35, aa(d - 0.02));
	vec3 face_c = q.x < 0.0 ? mix(cc, vec3(1.0), 0.35) : cc * 0.85;
	if (facet > 0.5) {
		face_c = q.x < -w * 0.33 ? mix(cc, vec3(1.0), 0.4) : (q.x < w * 0.33 ? cc : cc * 0.75);
	}
	col = mix(col, face_c, aa(d));
	col = mix(col, mix(cc, vec3(1.0), 0.75), aa(max(abs(q.x + w * 0.45) - w * 0.12, d + 0.03)));
	return col;
}

vec3 m_crystal(vec2 p, float n, float s, float hue, float mode, vec3 col) {
	float layout_t = pk(n, 1.0, 4.0);
	float count = 3.0 + pk(n, 4.0, 3.0);
	float facet = pk(n, 12.0, 2.0);
	float cmix = pk(n, 24.0, 3.0);
	float base_t = pk(n, 72.0, 3.0);
	vec3 c1 = pal(hue, mode, (hsh(s, 1.0) - 0.5) * 0.25, 1.1, 1.0);
	vec3 rock = pal(0.08, 3.0, 0.0, 1.0, 0.7);
	if (base_t < 0.5) {
		col = blob(col, p, vec2(0.0, 0.44), vec2(0.45, 0.14), 0.0, rock, rock * 0.5, 0.02);
	} else if (base_t < 1.5) {
		col = shape(col, max(abs(p.x) - 0.2, abs(p.y - 0.46) - 0.08), rock * 1.1, rock * 0.5, 0.02);
	}
	float hl = 0.27 + 0.1 * hsh(s, 3.0);
	float spread = 0.17 + 0.05 * layout_t;
	for (int i = 0; i < 5; i++) {
		float fi = float(i);
		if (fi >= count) {
			break;
		}
		float side = mod(fi, 2.0) < 0.5 ? -1.0 : 1.0;
		float k = floor((fi + 1.0) / 2.0);
		vec2 c = vec2(side * k * spread * (layout_t > 2.5 ? 0.6 : 1.0), 0.32 + k * 0.03);
		float a = side * k * (0.32 + 0.1 * layout_t) + (hsh(s, 30.0 + fi) - 0.5) * 0.2;
		float h = hl * (1.45 - 0.3 * k) * (0.85 + 0.3 * hsh(s, 40.0 + fi));
		vec3 cc = c1;
		if (cmix > 0.5 && cmix < 1.5) {
			cc = mod(fi, 2.0) < 0.5 ? c1 : pal(hue, mode, 0.12, 1.0, 0.9);
		} else if (cmix > 1.5) {
			cc = pal(hue, mode, fi * 0.12, 1.1, 1.0);
		}
		col = one_crystal(col, p, c, 0.1 - 0.015 * k, h, a, cc, facet);
	}
	col = sparkle(col, p, vec2(-0.3 + 0.12 * hsh(s, 8.0), -0.32), 0.1, vec3(1.0));
	col = sparkle(col, p, vec2(0.32, -0.12 - 0.12 * hsh(s, 9.0)), 0.07, vec3(1.0));
	return col;
}

// ---------------- Motif 4: gök cismi ----------------
// ayrık: tür(5) x yüz(3) x ek(4) x varyant(3) = 180
vec3 m_celestial(vec2 p, float n, float s, float hue, float mode, vec3 col) {
	float kind = pk(n, 1.0, 5.0);
	float face_t = pk(n, 5.0, 3.0);
	float extra = pk(n, 15.0, 4.0);
	float variant = pk(n, 60.0, 3.0);
	vec2 g = floor((p + 1.0) * 9.0);
	vec2 f = fract((p + 1.0) * 9.0) - 0.5;
	float st = hsh(g.x + g.y * 17.0 + s, 3.0);
	col = mix(col, mix(col, vec3(1.0, 1.0, 0.85), 0.9), aa(length(f) - 0.08) * step(0.82, st));
	vec3 main_c = pal(hue, mode, (hsh(s, 2.0) - 0.5) * 0.2 + variant * 0.05, 1.0, 1.1);
	vec3 line_c = main_c * 0.4;
	float a = atan(p.y, p.x);
	float r = length(p);
	vec2 fc = vec2(0.0);
	if (kind < 0.5) {
		float nn = 8.0 + 3.0 * variant + floor(hsh(s, 3.0) * 3.0);
		float rr = 0.32 + 0.09 * pow(0.5 + 0.5 * cos(nn * a + hsh(s, 4.0) * 6.0), 4.0);
		col = shape(col, r - rr, mix(main_c, vec3(1.0, 0.8, 0.2), 0.5), line_c, 0.02);
		col = blob(col, p, vec2(0.0), vec2(0.25), 0.0, main_c, line_c, 0.02);
	} else if (kind < 1.5) {
		float off = 0.1 + 0.04 * variant;
		float d = max(r - 0.32, -(length(p - vec2(off, -0.08)) - 0.27));
		col = shape(col, d, mix(main_c, vec3(1.0, 0.97, 0.8), 0.5), line_c, 0.02);
		fc = vec2(-0.16, 0.02);
	} else if (kind < 2.5) {
		float nn = 5.0 + variant;
		float rr = 0.16 + 0.2 * pow(0.5 + 0.5 * cos(nn * a - 1.5708), 2.5);
		col = shape(col, (r - rr) * 0.7, mix(main_c, vec3(1.0, 0.9, 0.4), 0.4), line_c, 0.018);
	} else if (kind < 3.5) {
		vec2 dir = normalize(vec2(1.0, -0.6 + 0.3 * variant));
		vec2 q = vec2(dot(p, dir), dot(p, vec2(-dir.y, dir.x)));
		float tail = max(abs(q.y) - (0.02 + 0.15 * clamp(q.x / 0.6, 0.0, 1.0)), max(-q.x, q.x - 0.65));
		col = mix(col, mix(main_c, vec3(1.0), 0.5), aa(tail) * (1.0 - clamp(q.x / 0.65, 0.0, 1.0)) * 0.9);
		col = blob(col, p, vec2(-0.08) * dir, vec2(0.15), 0.0, mix(main_c, vec3(1.0), 0.6), line_c, 0.02);
		fc = vec2(-0.08) * dir;
	} else {
		vec3 ring_c = pal(hue, mode, 0.15 + 0.1 * variant, 0.8, 1.05);
		float tilt = (hsh(s, 3.0) - 0.5) * 0.9;
		vec2 q = rot(p, -tilt);
		float ring = abs(length(q / vec2(0.5, 0.13)) - 1.0) * 0.13 - 0.014;
		col = mix(col, ring_c, aa(max(ring, -q.y)));
		col = blob(col, p, vec2(0.0), vec2(0.26), 0.0, main_c, line_c, 0.02);
		col = mix(col, main_c * 0.8, aa(max(abs(p.y + 0.06) - 0.035, r - 0.25)));
		col = mix(col, ring_c, aa(max(ring, q.y)));
	}
	if (extra < 0.5) {
		col = sparkle(col, p, vec2(-0.36, -0.34), 0.09, vec3(1.0, 1.0, 0.8));
		col = sparkle(col, p, vec2(0.38, 0.3), 0.07, vec3(1.0, 1.0, 0.8));
	} else if (extra < 1.5) {
		vec3 cl = mix(vec3(1.0), col, 0.15);
		col = blob(col, p, vec2(0.22, 0.36), vec2(0.18, 0.07), 0.0, cl, vec3(0.8, 0.85, 0.95), 0.012);
		col = blob(col, p, vec2(0.12, 0.33), vec2(0.1, 0.08), 0.0, cl, vec3(0.8, 0.85, 0.95), 0.012);
	} else if (extra < 2.5) {
		col = blob(col, p, vec2(0.38, -0.3), vec2(0.07), 0.0, pal(hue, mode, 0.4, 0.6, 0.95), line_c, 0.012);
	}
	if (face_t > 0.5 && kind != 3.0) {
		vec3 ink = vec3(0.15, 0.08, 0.05);
		if (face_t < 1.5) {
			col = blob(col, p, fc + vec2(-0.08, -0.035), vec2(0.025, 0.035), 0.0, ink, ink, 0.0);
			col = blob(col, p, fc + vec2(0.08, -0.035), vec2(0.025, 0.035), 0.0, ink, ink, 0.0);
		} else {
			col = arc_line(col, p, fc + vec2(-0.08, -0.06), 0.035, 0.008, 1.0, ink);
			col = arc_line(col, p, fc + vec2(0.08, -0.06), 0.035, 0.008, 1.0, ink);
		}
		col = arc_line(col, p, fc, 0.09, 0.009, 1.0, ink);
	}
	return col;
}

// ---------------- Motif 5: mantar ----------------
// ayrık: adet(3) x şapka(3) x benek(3) x yüz(3) x ek(2) = 162
vec3 one_mushroom(vec3 col, vec2 p, vec2 base, float sc, float s, vec3 cap_c, vec3 stem_c, float face_t, float cap_t, float spot_t) {
	vec2 q = (p - base) / sc;
	vec3 line_c = cap_c * 0.35;
	col = blob(col, q, vec2(0.0, -0.17), vec2(0.09, 0.19), 0.0, stem_c, stem_c * 0.45, 0.02);
	vec2 cr = vec2(0.3, 0.2 + 0.05 * hsh(s, 2.0));
	if (cap_t > 0.5 && cap_t < 1.5) { cr = vec2(0.36, 0.13); }
	if (cap_t > 1.5) { cr = vec2(0.24, 0.3); }
	float capd = max(ell_d(q, vec2(0.0, -0.33), cr, 0.0), q.y + 0.3);
	col = shape(col, capd, cap_c, line_c, 0.022);
	col = mix(col, mix(stem_c, vec3(1.0), 0.3), aa(max(abs(q.y + 0.3) - 0.02, abs(q.x) - cr.x * 0.88)));
	if (spot_t < 1.5) {
		for (int i = 0; i < 5; i++) {
			float fi = float(i);
			vec2 sp = vec2(-0.2 + 0.1 * fi + 0.04 * hsh(s, 10.0 + fi), -0.36 - cr.y * 0.6 * hsh(s, 20.0 + fi));
			float sd = length(q - sp) - 0.03 - 0.02 * hsh(s, 30.0 + fi);
			if (spot_t > 0.5) {
				sd = abs(sd + 0.012) - 0.01;
			}
			col = mix(col, vec3(1.0, 0.98, 0.92), aa(max(sd, capd + 0.02)));
		}
	}
	if (face_t > 0.5) {
		vec3 ink = vec3(0.12);
		if (face_t < 1.5) {
			col = blob(col, q, vec2(-0.035, -0.17), vec2(0.015, 0.024), 0.0, ink, ink, 0.0);
			col = blob(col, q, vec2(0.035, -0.17), vec2(0.015, 0.024), 0.0, ink, ink, 0.0);
		} else {
			col = arc_line(col, q, vec2(-0.035, -0.19), 0.02, 0.006, 1.0, ink);
			col = arc_line(col, q, vec2(0.035, -0.19), 0.02, 0.006, 1.0, ink);
		}
		col = arc_line(col, q, vec2(0.0, -0.15), 0.025, 0.006, 1.0, ink);
	}
	return col;
}

vec3 m_mushroom(vec2 p, float n, float s, float hue, float mode, vec3 col) {
	float count = pk(n, 1.0, 3.0);
	float cap_t = pk(n, 3.0, 3.0);
	float spot_t = pk(n, 9.0, 3.0);
	float face_t = pk(n, 27.0, 3.0);
	float extra = pk(n, 81.0, 2.0);
	vec3 grass = pal(0.3, mode, 0.0, 1.0, 0.7);
	col = blob(col, p, vec2(0.0, 0.52), vec2(0.65, 0.15), 0.0, grass, grass * 0.6, 0.0);
	vec3 cap_c = pal(hue, mode, (hsh(s, 1.0) - 0.5) * 0.3, 0.9 + 0.3 * hsh(s, 5.0), 1.0);
	vec3 cap2 = pal(hue, mode, 0.12, 1.0, 0.9);
	vec3 stem_c = mix(pal(0.1, 2.0, 0.0, 1.0, 1.0), vec3(1.0), 0.3);
	if (count > 0.5) {
		col = one_mushroom(col, p, vec2(0.27, 0.45), 0.55, s + 7.0, cap2, stem_c, 0.0, 2.0 - cap_t, spot_t);
	}
	if (count > 1.5) {
		col = one_mushroom(col, p, vec2(-0.3, 0.47), 0.45, s + 13.0, cap2, stem_c, 0.0, cap_t, 2.0 - spot_t);
	}
	col = one_mushroom(col, p, vec2(-0.03, 0.47), 1.08, s, cap_c, stem_c, face_t, cap_t, spot_t);
	if (extra > 0.5 || (mode > 0.5 && mode < 1.5)) {
		for (int i = 0; i < 5; i++) {
			float fi = float(i);
			vec2 fp = vec2(-0.45 + 0.22 * fi, -0.5 + 0.25 * hsh(s, 40.0 + fi));
			col = mix(col, vec3(0.9, 1.0, 0.6), aa(length(p - fp) - 0.018));
			col = mix(col, mix(col, vec3(0.9, 1.0, 0.6), 0.4), aa(length(p - fp) - 0.04));
		}
	}
	return col;
}

// ---------------- Motif 6: kuş / yarasa ----------------
// ayrık: yön(2) x tepe tüyü(3) x kanat(3) x kuyruk(3) x ek(3) = 162
vec3 m_bird(vec2 p, float n, float s, float hue, float mode, vec3 col) {
	float dir = pk(n, 1.0, 2.0) < 0.5 ? 1.0 : -1.0;
	float crest = pk(n, 2.0, 3.0);
	float wing = pk(n, 6.0, 3.0);
	float tail = pk(n, 18.0, 3.0);
	float extra = pk(n, 54.0, 3.0);
	vec2 q = vec2(p.x * dir, p.y);
	vec3 body_c = pal(hue, mode, (hsh(s, 2.0) - 0.5) * 0.3, 0.8 + 0.4 * hsh(s, 9.0), 1.0);
	vec3 wing_c = pal(hue, mode, 0.08 + 0.2 * hsh(s, 3.0), 1.1, 0.85);
	vec3 line_c = body_c * 0.32;
	vec3 beak = vec3(1.0, 0.65, 0.15);
	bool bat = mode > 0.5 && mode < 1.5;
	if (extra < 0.5) {
		vec3 brn = vec3(0.45, 0.3, 0.18);
		col = mix(col, brn, aa(max(abs(q.y - 0.36 - q.x * 0.1) - 0.025, abs(q.x) - 0.6)));
		col = blob(col, q, vec2(0.42, 0.3), vec2(0.07, 0.035), -0.5, vec3(0.35, 0.6, 0.25), vec3(0.2, 0.35, 0.15), 0.01);
	} else if (extra < 1.5) {
		col = blob(col, q, vec2(0.28, 0.42), vec2(0.2, 0.08), 0.0, vec3(1.0), vec3(0.85, 0.9, 1.0), 0.015);
		col = blob(col, q, vec2(0.14, 0.4), vec2(0.11, 0.09), 0.0, vec3(1.0), vec3(0.85, 0.9, 1.0), 0.015);
	}
	for (int i = 0; i < 3; i++) {
		float fi = float(i) - 1.0;
		float tl = tail < 0.5 ? 0.14 : (tail < 1.5 ? 0.2 : 0.1);
		float spreadt = tail < 1.5 ? 0.3 : 0.6;
		col = blob(col, q, vec2(0.27 + tl * 0.3, 0.12 + fi * 0.05), vec2(tl, 0.035), 0.3 + fi * spreadt, wing_c, line_c, 0.016);
	}
	float flap = wing * 0.45;
	if (bat) {
		float wd = max(ell_d(q, vec2(0.16, -0.12), vec2(0.33, 0.19), -0.4 - flap), -ell_d(q, vec2(0.27, 0.08), vec2(0.2, 0.11), -0.3));
		col = shape(col, wd, wing_c * 0.7, line_c, 0.018);
	} else {
		col = blob(col, q, vec2(0.12, -0.12), vec2(0.24, 0.1), -0.6 - flap, wing_c * 0.85, line_c, 0.018);
	}
	col = blob(col, q, vec2(0.04, 0.08), vec2(0.24, 0.2), 0.15, body_c, line_c, 0.022);
	col = blob(col, q, vec2(0.0, 0.15), vec2(0.14, 0.11), 0.15, mix(body_c, vec3(1.0), 0.5), mix(body_c, vec3(1.0), 0.5), 0.0);
	col = blob(col, q, vec2(-0.16, -0.11), vec2(0.14), 0.0, body_c, line_c, 0.022);
	if (!bat) {
		if (crest > 0.5 && crest < 1.5) {
			col = blob(col, q, vec2(-0.14, -0.27), vec2(0.03, 0.09), -0.3, wing_c, line_c, 0.014);
			col = blob(col, q, vec2(-0.08, -0.26), vec2(0.026, 0.08), 0.25, wing_c, line_c, 0.014);
		} else if (crest > 1.5) {
			col = blob(col, q, vec2(-0.12, -0.27), vec2(0.06, 0.03), 0.6, pal(hue, mode, 0.5, 1.1, 1.0), line_c, 0.012);
		}
		col = blob(col, q, vec2(-0.32, -0.08), vec2(0.08, 0.032), 0.15, beak, beak * 0.5, 0.012);
	} else {
		col = blob(col, q, vec2(-0.24, -0.21), vec2(0.035, 0.085), -0.4, body_c, line_c, 0.014);
		col = blob(col, q, vec2(-0.08, -0.23), vec2(0.035, 0.085), 0.4, body_c, line_c, 0.014);
	}
	col = eye(col, q, vec2(-0.18, -0.12), 0.045 + 0.015 * hsh(s, 6.0), line_c, -1.0);
	col = blob(col, q, vec2(0.1, 0.02), vec2(0.18, 0.085), -0.3 - flap * 0.6, wing_c, line_c, 0.018);
	col = blob(col, q, vec2(-0.02, 0.31), vec2(0.012, 0.05), 0.0, beak * 0.8, beak * 0.8, 0.0);
	col = blob(col, q, vec2(0.08, 0.31), vec2(0.012, 0.05), 0.0, beak * 0.8, beak * 0.8, 0.0);
	return col;
}

// ---------------- Motif 7: manzara ----------------
// ayrık: arazi(3) x gök(3) x ek(4) x saat(2) x bulut(3) = 216
vec3 m_landscape(vec2 p, float n, float s, float hue, float mode, vec3 col) {
	float kind = pk(n, 1.0, 3.0);
	float sky_t = pk(n, 3.0, 3.0);
	float extra = pk(n, 9.0, 4.0);
	float dusk = pk(n, 36.0, 2.0);
	float clouds = pk(n, 72.0, 3.0);
	vec3 sky = mix(pal(hue, mode, 0.0, 0.5, 1.05), vec3(1.0), 0.35);
	if (dusk > 0.5) {
		sky = mix(vec3(1.0, 0.6, 0.4), pal(hue, mode, 0.0, 0.7, 0.9), clamp(-p.y + 0.2, 0.0, 1.0));
	}
	if (mode > 0.5 && mode < 1.5) {
		sky = hsv2rgb(vec3(hue, 0.5, 0.25));
	}
	col = mix(sky, mix(sky, vec3(1.0), 0.4), clamp(p.y + 0.5, 0.0, 1.0));
	vec2 sp = vec2(-0.35 + 0.7 * hsh(s, 1.0), -0.4 + 0.15 * hsh(s, 2.0));
	if (sky_t < 1.5) {
		vec3 sun = (sky_t > 0.5 || (mode > 0.5 && mode < 1.5)) ? vec3(0.95, 0.95, 0.85) : vec3(1.0, 0.85, 0.35);
		col = mix(col, mix(col, sun, 0.35), aa(length(p - sp) - 0.2));
		col = mix(col, sun, aa(length(p - sp) - 0.13));
		if (sky_t > 0.5) {
			col = mix(col, sky, aa(length(p - sp - vec2(0.05, -0.03)) - 0.11));
		}
	}
	for (int i = 0; i < 2; i++) {
		float fi = float(i);
		if (fi >= clouds) {
			break;
		}
		vec2 cp = vec2(-0.4 + 0.8 * hsh(s, 80.0 + fi), -0.25 - 0.15 * hsh(s, 90.0 + fi));
		col = blob(col, p, cp, vec2(0.15, 0.045), 0.0, vec3(1.0), vec3(1.0), 0.0);
		col = blob(col, p, cp + vec2(0.05, -0.03), vec2(0.07, 0.05), 0.0, vec3(1.0), vec3(1.0), 0.0);
	}
	for (int i = 0; i < 3; i++) {
		float fi = float(i);
		float base = -0.02 + fi * 0.16;
		float amp = (0.24 - fi * 0.05) * (0.7 + 0.6 * hsh(s, 10.0 + fi));
		float fr = 3.0 + 3.0 * hsh(s, 20.0 + fi) + fi;
		float ph = hsh(s, 30.0 + fi) * 6.28;
		float ridge;
		if (kind < 0.5) {
			ridge = base - amp * (1.0 - abs(sin(p.x * fr + ph)));
		} else {
			ridge = base - amp * (0.5 + 0.5 * sin(p.x * fr * 0.7 + ph));
		}
		vec3 lc = pal(hue, mode, 0.05 * fi - 0.05, 1.0 + 0.2 * fi, 1.0 - 0.18 * fi);
		if (dusk > 0.5) {
			lc *= vec3(1.05, 0.85, 0.8);
		}
		float d = ridge - p.y;
		col = mix(col, lc * 0.6, aa(d - 0.012));
		col = mix(col, lc, aa(d));
		if (kind < 0.5 && i == 0 && (mode > 1.5 && mode < 2.5)) {
			col = mix(col, vec3(1.0), aa(d) * aa((base - amp * 0.75) - p.y));
		}
	}
	if (kind > 1.5) {
		float w = 0.26 + 0.015 * sin(p.x * 22.0 + hsh(s, 4.0) * 6.0);
		vec3 water = pal(fract(hue + 0.05), mode, 0.0, 1.1, 0.85);
		col = mix(col, water, aa(w - p.y));
		float stripe = abs(fract((p.y - 0.26) * 14.0 + 0.5 * sin(p.x * 9.0)) - 0.5);
		col = mix(col, mix(water, vec3(1.0), 0.5), aa(w - p.y) * aa(stripe - 0.06) * 0.6);
	}
	vec2 xp = vec2(-0.25 + 0.5 * hsh(s, 60.0), 0.36);
	if (extra < 0.5) {
		// ağaçlar
		for (int i = 0; i < 3; i++) {
			float fi = float(i);
			vec2 tp = xp + vec2(fi * 0.1 - 0.1, 0.0);
			col = mix(col, vec3(0.35, 0.22, 0.12), aa(max(abs(p.x - tp.x) - 0.012, abs(p.y - tp.y - 0.02) - 0.05)));
			col = blob(col, p, tp + vec2(0.0, -0.08), vec2(0.05, 0.08), 0.0, vec3(0.2, 0.5, 0.25), vec3(0.1, 0.3, 0.15), 0.01);
		}
	} else if (extra < 1.5) {
		// ev
		col = shape(col, max(abs(p.x - xp.x) - 0.08, abs(p.y - xp.y) - 0.06), vec3(0.95, 0.9, 0.8), vec3(0.4), 0.01);
		float roof = max(abs(p.x - xp.x) * 0.8 + (p.y - xp.y + 0.12), -(p.y - xp.y + 0.12));
		col = shape(col, roof, vec3(0.75, 0.25, 0.2), vec3(0.35, 0.1, 0.08), 0.01);
		col = mix(col, vec3(0.3, 0.2, 0.15), aa(max(abs(p.x - xp.x) - 0.02, abs(p.y - xp.y - 0.025) - 0.035)));
	} else if (extra < 2.5) {
		// uzakta kuşlar
		for (int i = 0; i < 3; i++) {
			float fi = float(i);
			vec2 bp = vec2(-0.2 + 0.15 * fi + 0.1 * hsh(s, 70.0 + fi), -0.15 - 0.08 * hsh(s, 75.0 + fi));
			col = arc_line(col, p, bp + vec2(-0.025, 0.015), 0.025, 0.006, 0.0, vec3(0.15));
			col = arc_line(col, p, bp + vec2(0.025, 0.015), 0.025, 0.006, 0.0, vec3(0.15));
		}
	}
	return col;
}

// ---------------- Motif 8: böcek ----------------
// ayrık: desen(3) x kanat(2) x boynuz(3) x anten(3) x ek(3) = 162
vec3 m_bug(vec2 p, float n, float s, float hue, float mode, vec3 col) {
	float pat = pk(n, 1.0, 3.0);
	float wings = pk(n, 3.0, 2.0);
	float horn = pk(n, 6.0, 3.0);
	float ant = pk(n, 18.0, 3.0);
	float extra = pk(n, 54.0, 3.0);
	vec3 shell = pal(hue, mode, (hsh(s, 1.0) - 0.5) * 0.3, 0.9 + 0.4 * hsh(s, 6.0), 1.0);
	vec3 line_c = shell * 0.3;
	vec3 dark = vec3(0.12, 0.1, 0.1);
	if (extra < 0.5) {
		col = blob(col, p, vec2(0.05, 0.3), vec2(0.5, 0.2), -0.3, vec3(0.35, 0.65, 0.3), vec3(0.2, 0.4, 0.15), 0.015);
		col = mix(col, vec3(0.25, 0.5, 0.2), aa(max(abs(rot(p - vec2(0.05, 0.3), 0.3).y) - 0.006, ell_d(p, vec2(0.05, 0.3), vec2(0.5, 0.2), -0.3))));
	} else if (extra < 1.5) {
		col = blob(col, p, vec2(0.36, 0.36), vec2(0.08), 0.0, pal(fract(hue + 0.5), 0.0, 0.0, 1.0, 1.0), line_c, 0.01);
		col = blob(col, p, vec2(0.36, 0.36), vec2(0.03), 0.0, vec3(1.0, 0.85, 0.3), line_c, 0.008);
	}
	float ang = (hsh(s, 2.0) - 0.5) * 0.7;
	vec2 q = rot(p - vec2(0.0, 0.06), -ang);
	for (int i = 0; i < 3; i++) {
		float fi = float(i) - 1.0;
		col = blob(col, q, vec2(-0.27, 0.05 + fi * 0.13), vec2(0.11, 0.02), -0.4 * fi - 0.2, dark, dark, 0.0);
		col = blob(col, q, vec2(0.27, 0.05 + fi * 0.13), vec2(0.11, 0.02), 0.4 * fi + 0.2, dark, dark, 0.0);
	}
	if (ant < 1.5) {
		float spread = ant < 0.5 ? 0.5 : 0.25;
		col = blob(col, q, vec2(-0.09, -0.36), vec2(0.013, 0.1), -spread, dark, dark, 0.0);
		col = blob(col, q, vec2(0.09, -0.36), vec2(0.013, 0.1), spread, dark, dark, 0.0);
		col = blob(col, q, vec2(-0.09 - spread * 0.1, -0.45), vec2(0.025), 0.0, dark, dark, 0.0);
		col = blob(col, q, vec2(0.09 + spread * 0.1, -0.45), vec2(0.025), 0.0, dark, dark, 0.0);
	}
	if (horn > 0.5 && horn < 1.5) {
		col = blob(col, q, vec2(0.0, -0.33), vec2(0.03, 0.09), 0.0, dark, dark, 0.0);
	} else if (horn > 1.5) {
		col = blob(col, q, vec2(-0.05, -0.32), vec2(0.022, 0.07), 0.35, dark, dark, 0.0);
		col = blob(col, q, vec2(0.05, -0.32), vec2(0.022, 0.07), -0.35, dark, dark, 0.0);
	}
	col = blob(col, q, vec2(0.0, -0.22), vec2(0.12, 0.1), 0.0, dark, dark, 0.0);
	col = blob(col, q, vec2(-0.05, -0.25), vec2(0.024), 0.0, vec3(1.0), vec3(1.0), 0.0);
	col = blob(col, q, vec2(0.05, -0.25), vec2(0.024), 0.0, vec3(1.0), vec3(1.0), 0.0);
	vec2 sr = vec2(0.22 + 0.05 * hsh(s, 3.0), 0.28 + 0.04 * hsh(s, 4.0));
	if (wings > 0.5) {
		vec3 wc = mix(vec3(1.0), shell, 0.25);
		col = blob(col, q, vec2(-0.2, 0.08), vec2(0.12, 0.25), 0.45, wc, wc * 0.6, 0.01);
		col = blob(col, q, vec2(0.2, 0.08), vec2(0.12, 0.25), -0.45, wc, wc * 0.6, 0.01);
	}
	float sd = ell_d(q, vec2(0.0, 0.09), sr, 0.0);
	col = blob(col, q, vec2(0.0, 0.09), sr, 0.0, shell, line_c, 0.024);
	col = mix(col, line_c, aa(max(abs(q.x) - 0.008, sd + 0.01)));
	if (pat < 0.5) {
		for (int i = 0; i < 3; i++) {
			float fi = float(i);
			vec2 sp = vec2(0.1, 0.0 + fi * 0.1);
			col = mix(col, dark, aa(max(length(vec2(abs(q.x), q.y) - sp) - 0.038, sd + 0.02)));
		}
	} else if (pat < 1.5) {
		float band = step(0.5, fract(q.y * 8.0));
		col = mix(col, shell * 0.6, aa(sd + 0.02) * band * 0.7);
	}
	return col;
}

// ---------------- Taso yüzü ----------------
void fragment() {
	vec3 base = COLOR.rgb;
	float holo = inst.y;
	if (abs(face) > 0.5) {
		vec2 uv = face_uv;
		if (face < 0.0) {
			uv.x = 1.0 - uv.x;
		}
		float d = length(uv - 0.5);
		float disc = 1.0 - smoothstep(DISC - 0.006, DISC + 0.004, d);

		int uid = int(inst.x + 0.5);
		int nper_i = int(nper + 0.5);
		int g = uid / nper_i;
		int num = uid - g * nper_i + 1;
		float motif = inst.z;
		float mode = floor(inst.w);
		float hue = fract(inst.w);
		float n = float(num - 1);
		float seed = float(num) + float(g) * 0.37;

		// çizim koordinatları: disk kenarı ~0.7; tasoya göre hafif dönüş, ölçek ve ayna
		vec2 p = (uv - vec2(0.5, 0.49)) * 2.0 * ART_SCALE;
		vec3 art = bg_pattern(bg_col(hue, mode, p), p, seed, hue, mode);
		if (motif < 6.5 || motif > 7.5) {
			float ang = (hsh(seed, 90.0) - 0.5) * 0.5;
			float scl = 0.9 + 0.2 * hsh(seed, 91.0);
			p = rot(p, ang) / scl;
		}
		if (hsh(seed, 92.0) > 0.5 && motif > 1.5 && motif != 6.0) {
			p.x = -p.x;
		}
		if (motif < 0.5) { art = m_creature(p, n, seed, hue, mode, art); }
		else if (motif < 1.5) { art = m_fish(p, n, seed, hue, mode, art); }
		else if (motif < 2.5) { art = m_flower(p, n, seed, hue, mode, art); }
		else if (motif < 3.5) { art = m_crystal(p, n, seed, hue, mode, art); }
		else if (motif < 4.5) { art = m_celestial(p, n, seed, hue, mode, art); }
		else if (motif < 5.5) { art = m_mushroom(p, n, seed, hue, mode, art); }
		else if (motif < 6.5) { art = m_bird(p, n, seed, hue, mode, art); }
		else if (motif < 7.5) { art = m_landscape(p, n, seed, hue, mode, art); }
		else { art = m_bug(p, n, seed, hue, mode, art); }

		// baskı dokusu ve kenar kararması
		float grain = hsh(floor(uv.x * 380.0) + floor(uv.y * 380.0) * 397.0, 5.0);
		art *= 0.965 + 0.07 * grain;
		art *= mix(1.0, 0.85, smoothstep(DISC - 0.14, DISC, d));
		base = mix(base, art, disc);
		// ince kenar: kabartma çizgisi
		base = mix(base, base * 0.55, smoothstep(0.008, 0.0, abs(d - DISC - 0.002)) * 0.8);
		base = mix(base, min(base * 1.3 + 0.05, vec3(1.0)), smoothstep(0.008, 0.0, abs(d - 0.485)) * 0.6);

		// altta küçük numara, okunur olsun diye yarı saydam etiket üstünde
		vec2 nc = vec2(0.5, 0.885);
		float pill = max(abs(uv.x - nc.x) - 0.07, abs(uv.y - nc.y) - 0.038);
		base = mix(base, mix(base, vec3(1.0), 0.85), aa(pill) * disc);
		float ink = draw_number(uv, num, nc, 0.05, 0.075);
		base = mix(base, vec3(0.08), ink * disc);
	}
	if (holo > 0.5) {
		float h = fract(TIME * 0.3 + face_uv.x * 0.8 + face_uv.y * 0.5);
		vec3 rainbow = clamp(abs(fract(h + vec3(0.0, 0.333, 0.667)) * 6.0 - 3.0) - 1.0, 0.0, 1.0);
		base = mix(base, rainbow, 0.3);
		EMISSION = rainbow * 0.3;
	}
	ALBEDO = base;
	ROUGHNESS = holo > 0.5 ? 0.22 : 0.45;
	METALLIC = holo > 0.5 ? 0.45 : 0.0;
	SPECULAR = 0.5;
}
