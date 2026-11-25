shader_type spatial;

// Taso: kenarı set rengi; yüzünde setin temasına uygun, numaradan türetilen prosedürel çizim
// ve altta küçük numara. Hiç resim dosyası yok: her şey burada, ekran kartında çiziliyor.
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

// Döndürülmüş, kenar çizgili elips
// Döndürülmüş, kenar çizgili, hacimli gölgelendirilmiş elips (üst-sol ışık + parlama)
vec3 blob(vec3 col, vec2 p, vec2 c, vec2 r, float a, vec3 fc, vec3 lc, float line) {
	vec2 q = rot(p - c, -a);
	vec2 v = q / r;
	float d = (length(v) - 1.0) * min(r.x, r.y);
	col = mix(col, lc, aa(d - line));
	float shade = 1.0 + 0.16 * (-v.x * 0.6 - v.y * 0.8) - 0.12 * dot(v, v);
	float spec = smoothstep(0.34, 0.0, length(v - vec2(-0.38, -0.45))) * 0.3;
	vec3 f = fc * shade + vec3(spec);
	return mix(col, f, aa(d));
}

// Kenar çizgili şekil: verilen mesafe değeriyle
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

// ---------------- Motif 0: yaratık ----------------
vec3 m_creature(vec2 p, float s, float hue, float mode, vec3 col) {
	vec3 body_c = pal(hue, mode, (hsh(s, 1.0) - 0.5) * 0.14, 0.8 + 0.4 * hsh(s, 2.0), 1.0);
	vec3 line_c = body_c * 0.35;
	vec3 light_c = mix(body_c, vec3(1.0), 0.6);
	vec3 accent = pal(hue, mode, 0.5, 1.1, 1.0);
	vec2 br = vec2(0.27 + 0.13 * hsh(s, 3.0), 0.23 + 0.12 * hsh(s, 4.0));
	vec2 bc = vec2(0.0, 0.06);
	float top = bc.y - br.y;
	float lw = 0.022;
	if (hsh(s, 9.0) > 0.45) {
		float side = hsh(s, 10.0) > 0.5 ? 1.0 : -1.0;
		col = blob(col, p, vec2(side * (br.x + 0.04), bc.y + 0.06), vec2(0.05, 0.15), side * 0.9, body_c, line_c, lw);
		col = blob(col, p, vec2(side * (br.x + 0.14), bc.y - 0.04), vec2(0.05), 0.0, accent, line_c, lw);
	}
	float ear = floor(hsh(s, 5.0) * 4.0);
	for (int i = 0; i < 2; i++) {
		float sx = i == 0 ? -1.0 : 1.0;
		if (ear < 0.5) {
			col = blob(col, p, vec2(sx * 0.13, top + 0.02), vec2(0.04, 0.13), sx * 0.55, vec3(0.95, 0.92, 0.82), line_c, lw);
		} else if (ear < 1.5) {
			col = blob(col, p, vec2(sx * 0.16, top + 0.03), vec2(0.07, 0.18), sx * 0.45, body_c, line_c, lw);
			col = blob(col, p, vec2(sx * 0.16, top + 0.05), vec2(0.03, 0.1), sx * 0.45, accent, accent, 0.0);
		} else if (ear < 2.5) {
			col = blob(col, p, vec2(sx * 0.19, top + 0.06), vec2(0.1), 0.0, body_c, line_c, lw);
			col = blob(col, p, vec2(sx * 0.19, top + 0.06), vec2(0.05), 0.0, light_c, light_c, 0.0);
		} else {
			col = blob(col, p, vec2(sx * 0.09, top - 0.08), vec2(0.014, 0.12), sx * 0.35, line_c, line_c, 0.0);
			col = blob(col, p, vec2(sx * 0.14, top - 0.19), vec2(0.05), 0.0, accent, line_c, lw);
		}
	}
	for (int i = 0; i < 2; i++) {
		float sx = i == 0 ? -1.0 : 1.0;
		col = blob(col, p, vec2(sx * br.x * 0.5, bc.y + br.y * 0.92), vec2(0.09, 0.055), 0.0, body_c * 0.8, line_c, lw);
	}
	col = blob(col, p, bc, br, 0.0, body_c, line_c, lw);
	col = blob(col, p, vec2(0.0, bc.y + br.y * 0.35), vec2(br.x * 0.6, br.y * 0.5), 0.0, light_c, light_c, 0.0);
	if (hsh(s, 6.0) > 0.5) {
		vec3 spot = mix(body_c, line_c, 0.35);
		col = blob(col, p, bc + vec2(-br.x * 0.62, -br.y * 0.2), vec2(0.045), 0.0, spot, spot, 0.0);
		col = blob(col, p, bc + vec2(br.x * 0.6, -br.y * 0.05), vec2(0.035), 0.0, spot, spot, 0.0);
		col = blob(col, p, bc + vec2(br.x * 0.45, -br.y * 0.55), vec2(0.03), 0.0, spot, spot, 0.0);
	}
	float eyes = floor(hsh(s, 7.0) * 3.0) + 1.0;
	float er = 0.055 + 0.04 * hsh(s, 8.0);
	float ey = bc.y - br.y * 0.3;
	float look = hsh(s, 11.0) * 2.0 - 1.0;
	if (eyes < 1.5) {
		col = eye(col, p, vec2(0.0, ey), er * 1.6, line_c, look);
	} else if (eyes < 2.5) {
		col = eye(col, p, vec2(-0.1, ey), er, line_c, look);
		col = eye(col, p, vec2(0.1, ey), er, line_c, look);
	} else {
		col = eye(col, p, vec2(-0.12, ey + 0.02), er * 0.9, line_c, look);
		col = eye(col, p, vec2(0.12, ey + 0.02), er * 0.9, line_c, look);
		col = eye(col, p, vec2(0.0, ey - 0.08), er * 0.75, line_c, look);
	}
	float my = bc.y + br.y * 0.12;
	vec3 cheek = mix(light_c, vec3(1.0, 0.5, 0.6), 0.6);
	col = blob(col, p, vec2(-br.x * 0.62, my - 0.01), vec2(0.04, 0.025), 0.0, cheek, cheek, 0.0);
	col = blob(col, p, vec2(br.x * 0.62, my - 0.01), vec2(0.04, 0.025), 0.0, cheek, cheek, 0.0);
	col = blob(col, p, vec2(0.0, my), vec2(0.055 + 0.03 * hsh(s, 12.0), 0.022 + 0.02 * hsh(s, 13.0)), 0.0, vec3(0.25, 0.05, 0.08), line_c, 0.01);
	if (hsh(s, 14.0) > 0.55) {
		col = blob(col, p, vec2(-0.025, my - 0.005), vec2(0.012, 0.02), 0.0, vec3(1.0), vec3(1.0), 0.0);
		col = blob(col, p, vec2(0.025, my - 0.005), vec2(0.012, 0.02), 0.0, vec3(1.0), vec3(1.0), 0.0);
	}
	return col;
}

// ---------------- Motif 1: balık ----------------
vec3 m_fish(vec2 p, float s, float hue, float mode, vec3 col) {
	float dir = hsh(s, 1.0) > 0.5 ? 1.0 : -1.0;
	vec2 q = vec2(p.x * dir, p.y);
	vec3 body_c = pal(hue, mode, (hsh(s, 2.0) - 0.5) * 0.2, 1.0, 1.0);
	vec3 line_c = body_c * 0.35;
	vec3 fin_c = pal(hue, mode, 0.08 + 0.1 * hsh(s, 3.0), 1.1, 0.9);
	vec2 br = vec2(0.26 + 0.08 * hsh(s, 4.0), 0.15 + 0.1 * hsh(s, 5.0));
	vec2 bc = vec2(-0.05, 0.0);
	// baloncuklar
	for (int i = 0; i < 3; i++) {
		float fi = float(i);
		vec2 bp = vec2(-0.38 + 0.07 * fi, -0.32 - 0.1 * fi + 0.05 * hsh(s, 20.0 + fi));
		float d = abs(length(q - bp) - (0.03 + 0.012 * fi)) - 0.006;
		col = mix(col, mix(col, vec3(1.0), 0.8), aa(d));
	}
	// kuyruk
	col = blob(col, q, vec2(bc.x + br.x + 0.06, -0.08), vec2(0.06, 0.15), -0.7, fin_c, line_c, 0.02);
	col = blob(col, q, vec2(bc.x + br.x + 0.06, 0.08), vec2(0.06, 0.15), 0.7, fin_c, line_c, 0.02);
	// yüzgeçler
	col = blob(col, q, vec2(bc.x + 0.03, bc.y - br.y), vec2(0.12, 0.06), 0.25, fin_c, line_c, 0.02);
	col = blob(col, q, vec2(bc.x + 0.06, bc.y + br.y * 0.95), vec2(0.07, 0.045), -0.3, fin_c, line_c, 0.02);
	// gövde
	float bd = ell_d(q, bc, br, 0.0);
	col = shape(col, bd, body_c, line_c, 0.022);
	// çizgiler ya da benekler
	float pat = floor(hsh(s, 6.0) * 3.0);
	vec3 pc = mix(body_c, line_c, 0.4);
	if (pat < 0.5) {
		float band = step(0.5, fract((q.x + 0.4) * (5.0 + 4.0 * hsh(s, 7.0))));
		col = mix(col, pc, aa(bd + 0.03) * band * 0.8);
	} else if (pat < 1.5) {
		vec2 cell = fract(q * 9.0) - 0.5;
		col = mix(col, pc, aa(bd + 0.03) * aa(length(cell) - 0.18) * 0.8);
	}
	// karın, solungaç, göz, ağız
	col = mix(col, mix(body_c, vec3(1.0), 0.5), aa(max(bd + 0.02, -(q.y - bc.y - br.y * 0.25))) * 0.7);
	float gd = abs(length(q - vec2(bc.x - br.x * 0.25, bc.y)) - br.y * 0.7) - 0.008;
	col = mix(col, line_c, aa(max(gd, max(bd + 0.03, q.x - bc.x + br.x * 0.25))));
	col = eye(col, q, vec2(bc.x - br.x * 0.6, bc.y - br.y * 0.25), 0.05 + 0.02 * hsh(s, 8.0), line_c, -1.0);
	col = blob(col, q, vec2(bc.x - br.x * 0.95, bc.y + br.y * 0.2), vec2(0.03, 0.015), 0.3, vec3(0.3, 0.05, 0.08), line_c, 0.0);
	return col;
}

// ---------------- Motif 2: çiçek / mercan ----------------
vec3 m_flower(vec2 p, float s, float hue, float mode, vec3 col) {
	vec3 stem_c = pal(0.33, mode, (hsh(s, 1.0) - 0.5) * 0.1, 1.0, 0.75);
	vec3 petal_c = pal(hue, mode, (hsh(s, 2.0) - 0.5) * 0.2, 1.0, 1.0);
	vec3 petal2 = pal(hue, mode, 0.06 + 0.1 * hsh(s, 3.0), 1.2, 0.85);
	vec3 line_c = petal_c * 0.4;
	vec2 fc = vec2(0.0, -0.08);
	// sap ve yapraklar
	col = mix(col, stem_c * 0.6, aa(max(abs(p.x + 0.04 * sin(p.y * 6.0)) - 0.035, -(p.y - fc.y))));
	col = mix(col, stem_c, aa(max(abs(p.x + 0.04 * sin(p.y * 6.0)) - 0.022, -(p.y - fc.y))));
	col = blob(col, p, vec2(0.12, 0.38), vec2(0.13, 0.05), -0.5, stem_c, stem_c * 0.5, 0.015);
	if (hsh(s, 4.0) > 0.4) {
		col = blob(col, p, vec2(-0.12, 0.28), vec2(0.11, 0.045), 0.5, stem_c, stem_c * 0.5, 0.015);
	}
	// taç yaprakları (kutupsal katlama)
	float n = 5.0 + floor(hsh(s, 5.0) * 4.0);
	vec2 d = p - fc;
	float a = atan(d.y, d.x) + hsh(s, 6.0) * 3.0;
	float sec = TAU / n;
	float a2 = mod(a + sec * 0.5, sec) - sec * 0.5;
	vec2 q = length(d) * vec2(cos(a2), sin(a2));
	float pl = 0.16 + 0.06 * hsh(s, 7.0);
	float pw = (0.06 + 0.04 * hsh(s, 8.0)) * (n < 6.5 ? 1.2 : 0.9);
	col = blob(col, q, vec2(pl, 0.0), vec2(pl, pw), 0.0, petal_c, line_c, 0.018);
	// iç halka yapraklar
	float a3 = mod(a + sec, sec) - sec * 0.5;
	vec2 q2 = length(d) * vec2(cos(a3), sin(a3));
	col = blob(col, q2, vec2(pl * 0.55, 0.0), vec2(pl * 0.55, pw * 0.7), 0.0, petal2, line_c, 0.014);
	// göbek
	vec3 core = pal(fract(hue + 0.15), 0.0, 0.0, 1.0, 1.0);
	core = mix(core, vec3(1.0, 0.85, 0.3), 0.6);
	col = blob(col, p, fc, vec2(0.07 + 0.02 * hsh(s, 9.0)), 0.0, core, line_c, 0.016);
	vec2 cell = fract((p - fc) * 40.0) - 0.5;
	col = mix(col, core * 0.6, aa(length(p - fc) - 0.065) * aa(length(cell) - 0.2) * 0.7);
	if (hsh(s, 10.0) > 0.6) {
		col = sparkle(col, p, vec2(0.3, -0.35), 0.08, vec3(1.0, 1.0, 0.85));
	}
	return col;
}

// ---------------- Motif 3: kristal ----------------
float crystal_d(vec2 q, float w, float h) {
	float taper = clamp((q.y + h) / (0.4 * h), 0.0, 1.0);
	return max(abs(q.x) - w * taper, max(q.y - h * 0.5, -h - q.y));
}

vec3 one_crystal(vec3 col, vec2 p, vec2 c, float w, float h, float a, vec3 cc) {
	vec2 q = rot(p - c, -a);
	float d = crystal_d(q, w, h);
	col = mix(col, cc * 0.35, aa(d - 0.02));
	vec3 face_c = q.x < 0.0 ? mix(cc, vec3(1.0), 0.35) : cc * 0.85;
	col = mix(col, face_c, aa(d));
	col = mix(col, mix(cc, vec3(1.0), 0.75), aa(max(abs(q.x + w * 0.45) - w * 0.12, d + 0.03)));
	return col;
}

vec3 m_crystal(vec2 p, float s, float hue, float mode, vec3 col) {
	vec3 c1 = pal(hue, mode, (hsh(s, 1.0) - 0.5) * 0.15, 1.1, 1.0);
	vec3 c2 = pal(hue, mode, 0.08 * (hsh(s, 2.0) - 0.5) + 0.05, 1.0, 0.9);
	vec3 rock = pal(0.08, 3.0, 0.0, 1.0, 0.7);
	col = blob(col, p, vec2(0.0, 0.42), vec2(0.42, 0.13), 0.0, rock, rock * 0.5, 0.02);
	float hl = 0.25 + 0.1 * hsh(s, 3.0);
	col = one_crystal(col, p, vec2(-0.2, 0.3), 0.07, hl * 0.9, -0.45 - 0.2 * hsh(s, 4.0), c2);
	col = one_crystal(col, p, vec2(0.21, 0.32), 0.065, hl * 0.8, 0.4 + 0.2 * hsh(s, 5.0), c2);
	col = one_crystal(col, p, vec2(0.0, 0.3), 0.1, hl * 1.45, (hsh(s, 6.0) - 0.5) * 0.2, c1);
	if (hsh(s, 7.0) > 0.4) {
		col = one_crystal(col, p, vec2(0.1, 0.36), 0.045, hl * 0.6, 0.25, mix(c1, vec3(1.0), 0.3));
	}
	col = sparkle(col, p, vec2(-0.28 + 0.1 * hsh(s, 8.0), -0.3), 0.09, vec3(1.0));
	col = sparkle(col, p, vec2(0.3, -0.12 - 0.1 * hsh(s, 9.0)), 0.06, vec3(1.0));
	return col;
}

// ---------------- Motif 4: gök cismi ----------------
vec3 m_celestial(vec2 p, float s, float hue, float mode, vec3 col) {
	// arka plan yıldızları
	vec2 g = floor((p + 1.0) * 9.0);
	vec2 f = fract((p + 1.0) * 9.0) - 0.5;
	float st = hsh(g.x + g.y * 17.0 + s, 3.0);
	col = mix(col, mix(col, vec3(1.0, 1.0, 0.85), 0.9), aa(length(f) - 0.08) * step(0.82, st));
	float kind = floor(hsh(s, 1.0) * 5.0);
	vec3 main_c = pal(hue, mode, (hsh(s, 2.0) - 0.5) * 0.12, 1.0, 1.1);
	vec3 line_c = main_c * 0.4;
	float a = atan(p.y, p.x);
	float r = length(p);
	bool face_on = hsh(s, 6.0) > 0.35;
	vec2 fc = vec2(0.0);
	if (kind < 0.5) {
		// güneş
		float n = 8.0 + floor(hsh(s, 3.0) * 6.0);
		float rr = 0.27 + 0.08 * pow(0.5 + 0.5 * cos(n * a + hsh(s, 4.0) * 6.0), 4.0);
		col = shape(col, r - rr, mix(main_c, vec3(1.0, 0.8, 0.2), 0.5), line_c, 0.02);
		col = blob(col, p, vec2(0.0), vec2(0.21), 0.0, main_c, line_c, 0.02);
	} else if (kind < 1.5) {
		// hilal
		float d = max(r - 0.28, -(length(p - vec2(0.12, -0.08)) - 0.24));
		col = shape(col, d, mix(main_c, vec3(1.0, 0.97, 0.8), 0.5), line_c, 0.02);
		fc = vec2(-0.14, 0.02);
	} else if (kind < 2.5) {
		// yıldız
		float n = 5.0 + floor(hsh(s, 3.0) * 3.0);
		float rr = 0.14 + 0.18 * pow(0.5 + 0.5 * cos(n * a - 1.5708), 2.5);
		col = shape(col, (r - rr) * 0.7, mix(main_c, vec3(1.0, 0.9, 0.4), 0.4), line_c, 0.018);
	} else if (kind < 3.5) {
		// kuyruklu yıldız
		vec2 dir = normalize(vec2(1.0, -0.6 + 0.4 * hsh(s, 3.0)));
		vec2 q = vec2(dot(p, dir), dot(p, vec2(-dir.y, dir.x)));
		float tail = max(abs(q.y) - (0.02 + 0.13 * clamp(q.x / 0.55, 0.0, 1.0)), max(-q.x, q.x - 0.6));
		col = mix(col, mix(main_c, vec3(1.0), 0.5), aa(tail) * (1.0 - clamp(q.x / 0.6, 0.0, 1.0)) * 0.9);
		col = blob(col, p, vec2(-0.08) * dir, vec2(0.13), 0.0, mix(main_c, vec3(1.0), 0.6), line_c, 0.02);
		fc = vec2(-0.08) * dir;
	} else {
		// halkalı gezegen
		vec3 ring_c = pal(hue, mode, 0.12, 0.8, 1.05);
		float tilt = (hsh(s, 3.0) - 0.5) * 0.8;
		vec2 q = rot(p, -tilt);
		float ring = abs(length(q / vec2(0.42, 0.11)) - 1.0) * 0.11 - 0.012;
		col = mix(col, ring_c, aa(max(ring, -q.y)));
		col = blob(col, p, vec2(0.0), vec2(0.22), 0.0, main_c, line_c, 0.02);
		col = mix(col, main_c * 0.8, aa(max(abs(p.y + 0.05) - 0.03, r - 0.21)));
		col = mix(col, ring_c, aa(max(ring, q.y)));
	}
	if (face_on && kind != 3.0) {
		vec3 ink = vec3(0.15, 0.08, 0.05);
		col = blob(col, p, fc + vec2(-0.07, -0.03), vec2(0.022, 0.03), 0.0, ink, ink, 0.0);
		col = blob(col, p, fc + vec2(0.07, -0.03), vec2(0.022, 0.03), 0.0, ink, ink, 0.0);
		float sm = abs(length(p - fc - vec2(0.0, 0.0)) - 0.08) - 0.008;
		col = mix(col, ink, aa(max(sm, -(p.y - fc.y - 0.03))));
	}
	return col;
}

// ---------------- Motif 5: mantar ----------------
vec3 one_mushroom(vec3 col, vec2 p, vec2 base, float sc, float s, vec3 cap_c, vec3 stem_c, bool face_on) {
	vec2 q = (p - base) / sc;
	vec3 line_c = cap_c * 0.35;
	col = blob(col, q, vec2(0.0, -0.17), vec2(0.09, 0.19), 0.0, stem_c, stem_c * 0.45, 0.02);
	float capd = max(ell_d(q, vec2(0.0, -0.33), vec2(0.3, 0.2 + 0.06 * hsh(s, 2.0)), 0.0), q.y + 0.3);
	col = shape(col, capd, cap_c, line_c, 0.022);
	col = mix(col, mix(stem_c, vec3(1.0), 0.3), aa(max(abs(q.y + 0.3) - 0.02, abs(q.x) - 0.26)));
	for (int i = 0; i < 4; i++) {
		float fi = float(i);
		vec2 sp = vec2(-0.17 + 0.12 * fi + 0.04 * hsh(s, 10.0 + fi), -0.43 + 0.08 * hsh(s, 20.0 + fi));
		col = mix(col, vec3(1.0, 0.98, 0.92), aa(max(length(q - sp) - 0.035 - 0.02 * hsh(s, 30.0 + fi), capd + 0.02)));
	}
	if (face_on) {
		vec3 ink = vec3(0.12);
		col = blob(col, q, vec2(-0.035, -0.17), vec2(0.014, 0.022), 0.0, ink, ink, 0.0);
		col = blob(col, q, vec2(0.035, -0.17), vec2(0.014, 0.022), 0.0, ink, ink, 0.0);
	}
	return col;
}

vec3 m_mushroom(vec2 p, float s, float hue, float mode, vec3 col) {
	vec3 grass = pal(0.3, mode, 0.0, 1.0, 0.7);
	col = blob(col, p, vec2(0.0, 0.5), vec2(0.6, 0.14), 0.0, grass, grass * 0.6, 0.0);
	vec3 cap_c = pal(hue, mode, (hsh(s, 1.0) - 0.5) * 0.15, 1.1, 1.0);
	vec3 cap2 = pal(hue, mode, 0.07, 1.0, 0.9);
	vec3 stem_c = mix(pal(0.1, 2.0, 0.0, 1.0, 1.0), vec3(1.0), 0.3);
	if (hsh(s, 3.0) > 0.4) {
		col = one_mushroom(col, p, vec2(0.25, 0.42), 0.55, s + 7.0, cap2, stem_c, false);
	}
	col = one_mushroom(col, p, vec2(-0.05, 0.44), 1.0, s, cap_c, stem_c, hsh(s, 4.0) > 0.3);
	if (mode > 0.5 && mode < 1.5) {
		for (int i = 0; i < 4; i++) {
			float fi = float(i);
			vec2 fp = vec2(-0.4 + 0.25 * fi, -0.45 + 0.2 * hsh(s, 40.0 + fi));
			col = mix(col, vec3(0.9, 1.0, 0.6), aa(length(p - fp) - 0.018));
		}
	}
	return col;
}

// ---------------- Motif 6: kuş / yarasa ----------------
vec3 m_bird(vec2 p, float s, float hue, float mode, vec3 col) {
	float dir = hsh(s, 1.0) > 0.5 ? 1.0 : -1.0;
	vec2 q = vec2(p.x * dir, p.y);
	vec3 body_c = pal(hue, mode, (hsh(s, 2.0) - 0.5) * 0.15, 1.0, 1.0);
	vec3 wing_c = pal(hue, mode, 0.05 + 0.08 * hsh(s, 3.0), 1.1, 0.85);
	vec3 line_c = body_c * 0.35;
	vec3 beak = vec3(1.0, 0.65, 0.15);
	bool bat = mode > 0.5 && mode < 1.5;
	// bulut
	if (mode > 1.5 && mode < 2.5) {
		col = blob(col, p, vec2(0.25, 0.4), vec2(0.18, 0.07), 0.0, vec3(1.0), vec3(0.85, 0.9, 1.0), 0.015);
		col = blob(col, p, vec2(0.12, 0.38), vec2(0.1, 0.08), 0.0, vec3(1.0), vec3(0.85, 0.9, 1.0), 0.015);
	}
	// kuyruk tüyleri
	for (int i = 0; i < 3; i++) {
		float fi = float(i) - 1.0;
		col = blob(col, q, vec2(0.26, 0.12 + fi * 0.05), vec2(0.13, 0.035), 0.3 + fi * 0.3, wing_c, line_c, 0.016);
	}
	// arka kanat
	float flap = hsh(s, 4.0) * 0.8;
	if (bat) {
		float wd = max(ell_d(q, vec2(0.15, -0.12), vec2(0.3, 0.17), -0.4 - flap), -ell_d(q, vec2(0.25, 0.08), vec2(0.18, 0.1), -0.3));
		col = shape(col, wd, wing_c * 0.7, line_c, 0.018);
	} else {
		col = blob(col, q, vec2(0.12, -0.12), vec2(0.22, 0.09), -0.6 - flap, wing_c * 0.85, line_c, 0.018);
	}
	// gövde ve kafa
	col = blob(col, q, vec2(0.04, 0.08), vec2(0.22, 0.18), 0.15, body_c, line_c, 0.02);
	col = blob(col, q, vec2(0.0, 0.14), vec2(0.13, 0.1), 0.15, mix(body_c, vec3(1.0), 0.5), mix(body_c, vec3(1.0), 0.5), 0.0);
	col = blob(col, q, vec2(-0.15, -0.1), vec2(0.13), 0.0, body_c, line_c, 0.02);
	if (hsh(s, 5.0) > 0.5 && !bat) {
		col = blob(col, q, vec2(-0.13, -0.25), vec2(0.03, 0.08), -0.3, wing_c, line_c, 0.014);
		col = blob(col, q, vec2(-0.08, -0.24), vec2(0.025, 0.07), 0.2, wing_c, line_c, 0.014);
	}
	if (bat) {
		col = blob(col, q, vec2(-0.23, -0.2), vec2(0.035, 0.08), -0.4, body_c, line_c, 0.014);
		col = blob(col, q, vec2(-0.08, -0.22), vec2(0.035, 0.08), 0.4, body_c, line_c, 0.014);
	} else {
		col = blob(col, q, vec2(-0.3, -0.08), vec2(0.07, 0.03), 0.15, beak, beak * 0.5, 0.012);
	}
	col = eye(col, q, vec2(-0.17, -0.12), 0.04 + 0.015 * hsh(s, 6.0), line_c, -1.0);
	// ön kanat
	col = blob(col, q, vec2(0.1, 0.02), vec2(0.17, 0.08), -0.3 - flap * 0.5, wing_c, line_c, 0.018);
	// ayaklar
	col = blob(col, q, vec2(-0.02, 0.3), vec2(0.012, 0.05), 0.0, beak * 0.8, beak * 0.8, 0.0);
	col = blob(col, q, vec2(0.08, 0.3), vec2(0.012, 0.05), 0.0, beak * 0.8, beak * 0.8, 0.0);
	return col;
}

// ---------------- Motif 7: manzara ----------------
vec3 m_landscape(vec2 p, float s, float hue, float mode, vec3 col) {
	vec3 sky = mix(pal(hue, mode, 0.0, 0.5, 1.05), vec3(1.0), 0.35);
	if (mode > 0.5 && mode < 1.5) {
		sky = hsv2rgb(vec3(hue, 0.5, 0.25));
	}
	col = mix(sky, mix(sky, vec3(1.0), 0.4), clamp(p.y + 0.5, 0.0, 1.0));
	// güneş ya da ay
	vec2 sp = vec2(-0.3 + 0.6 * hsh(s, 1.0), -0.38 + 0.12 * hsh(s, 2.0));
	vec3 sun = mode > 0.5 && mode < 1.5 ? vec3(0.95, 0.95, 0.85) : vec3(1.0, 0.85, 0.35);
	col = mix(col, mix(col, sun, 0.35), aa(length(p - sp) - 0.17));
	col = mix(col, sun, aa(length(p - sp) - 0.11));
	float kind = floor(hsh(s, 3.0) * 3.0);   // 0 sivri dağ, 1 yumuşak tepe, 2 deniz/göl
	for (int i = 0; i < 3; i++) {
		float fi = float(i);
		float base = -0.05 + fi * 0.15;
		float amp = (0.22 - fi * 0.05) * (0.7 + 0.6 * hsh(s, 10.0 + fi));
		float fr = 3.0 + 3.0 * hsh(s, 20.0 + fi) + fi;
		float ph = hsh(s, 30.0 + fi) * 6.28;
		float ridge;
		if (kind < 0.5) {
			ridge = base - amp * (1.0 - abs(sin(p.x * fr + ph)));
		} else {
			ridge = base - amp * (0.5 + 0.5 * sin(p.x * fr * 0.7 + ph));
		}
		vec3 lc = pal(hue, mode, 0.04 * fi - 0.04, 1.0 + 0.2 * fi, 1.0 - 0.18 * fi);
		float d = ridge - p.y;
		col = mix(col, lc * 0.6, aa(d - 0.012));
		col = mix(col, lc, aa(d));
		// karlı tepeler
		if (kind < 0.5 && i == 0 && (mode > 1.5 && mode < 2.5)) {
			col = mix(col, vec3(1.0), aa(d) * aa((base - amp * 0.75) - p.y));
		}
	}
	if (kind > 1.5) {
		float w = 0.24 + 0.015 * sin(p.x * 22.0 + hsh(s, 4.0) * 6.0);
		vec3 water = pal(fract(hue + 0.05), mode, 0.0, 1.1, 0.85);
		col = mix(col, water, aa(w - p.y));
		float stripe = abs(fract((p.y - 0.24) * 14.0 + 0.5 * sin(p.x * 9.0)) - 0.5);
		col = mix(col, mix(water, vec3(1.0), 0.5), aa(w - p.y) * aa(stripe - 0.06) * 0.6);
	}
	return col;
}

// ---------------- Motif 8: böcek ----------------
vec3 m_bug(vec2 p, float s, float hue, float mode, vec3 col) {
	vec3 shell = pal(hue, mode, (hsh(s, 1.0) - 0.5) * 0.12, 1.1, 1.0);
	vec3 line_c = shell * 0.3;
	vec3 dark = vec3(0.12, 0.1, 0.1);
	float ang = (hsh(s, 2.0) - 0.5) * 0.6;
	vec2 q = rot(p - vec2(0.0, 0.05), -ang);
	// bacaklar
	for (int i = 0; i < 3; i++) {
		float fi = float(i) - 1.0;
		col = blob(col, q, vec2(-0.24, 0.05 + fi * 0.12), vec2(0.1, 0.018), -0.4 * fi - 0.2, dark, dark, 0.0);
		col = blob(col, q, vec2(0.24, 0.05 + fi * 0.12), vec2(0.1, 0.018), 0.4 * fi + 0.2, dark, dark, 0.0);
	}
	// antenler
	col = blob(col, q, vec2(-0.08, -0.33), vec2(0.012, 0.09), -0.5, dark, dark, 0.0);
	col = blob(col, q, vec2(0.08, -0.33), vec2(0.012, 0.09), 0.5, dark, dark, 0.0);
	col = blob(col, q, vec2(-0.13, -0.41), vec2(0.022), 0.0, dark, dark, 0.0);
	col = blob(col, q, vec2(0.13, -0.41), vec2(0.022), 0.0, dark, dark, 0.0);
	// kafa
	col = blob(col, q, vec2(0.0, -0.2), vec2(0.11, 0.09), 0.0, dark, dark, 0.0);
	col = blob(col, q, vec2(-0.045, -0.23), vec2(0.022), 0.0, vec3(1.0), vec3(1.0), 0.0);
	col = blob(col, q, vec2(0.045, -0.23), vec2(0.022), 0.0, vec3(1.0), vec3(1.0), 0.0);
	// kabuk
	vec2 sr = vec2(0.2 + 0.05 * hsh(s, 3.0), 0.25 + 0.04 * hsh(s, 4.0));
	float sd = ell_d(q, vec2(0.0, 0.08), sr, 0.0);
	col = shape(col, sd, shell, line_c, 0.022);
	col = mix(col, line_c, aa(max(abs(q.x) - 0.008, sd + 0.01)));
	col = mix(col, mix(shell, vec3(1.0), 0.5), aa(max(ell_d(q, vec2(-0.08, -0.03), vec2(0.04, 0.08), 0.3), sd + 0.02)) * 0.8);
	float pat = floor(hsh(s, 5.0) * 3.0);
	if (pat < 0.5) {
		for (int i = 0; i < 3; i++) {
			float fi = float(i);
			vec2 sp = vec2(0.09, 0.0 + fi * 0.09);
			col = mix(col, dark, aa(max(length(vec2(abs(q.x), q.y) - sp) - 0.035, sd + 0.02)));
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
		float disc = 1.0 - smoothstep(0.36, 0.375, d);

		int uid = int(inst.x + 0.5);
		int nper_i = int(nper + 0.5);
		int g = uid / nper_i;
		int num = uid - g * nper_i + 1;
		float motif = inst.z;
		float mode = floor(inst.w);
		float hue = fract(inst.w);
		float seed = float(num) + float(g) * 0.37;

		vec2 p = (uv - vec2(0.5, 0.45)) * 2.0;
		vec3 art = bg_col(hue, mode, p);
		if (motif < 0.5) { art = m_creature(p, seed, hue, mode, art); }
		else if (motif < 1.5) { art = m_fish(p, seed, hue, mode, art); }
		else if (motif < 2.5) { art = m_flower(p, seed, hue, mode, art); }
		else if (motif < 3.5) { art = m_crystal(p, seed, hue, mode, art); }
		else if (motif < 4.5) { art = m_celestial(p, seed, hue, mode, art); }
		else if (motif < 5.5) { art = m_mushroom(p, seed, hue, mode, art); }
		else if (motif < 6.5) { art = m_bird(p, seed, hue, mode, art); }
		else if (motif < 7.5) { art = m_landscape(p, seed, hue, mode, art); }
		else { art = m_bug(p, seed, hue, mode, art); }
		// zemin gölgesi (ayakta duran motiflerde)
		if (motif < 0.5 || (motif > 4.5 && motif < 6.5) || motif > 7.5) {
			float sh = smoothstep(1.0, 0.0, length((p - vec2(0.0, 0.47)) / vec2(0.42, 0.07)));
			art = mix(art, art * 0.68, sh * 0.55);
		}
		// baskı dokusu ve kenar kararması
		float grain = hsh(floor(uv.x * 380.0) + floor(uv.y * 380.0) * 397.0, 5.0);
		art *= 0.965 + 0.07 * grain;
		art *= mix(1.0, 0.82, smoothstep(0.22, 0.37, d));
		base = mix(base, art, disc);
		// taso kenarı: hafif kabartma halkası ve dışa doğru koyulaşma
		float rim = 1.0 - disc;
		base *= mix(1.0, 0.86 + 0.18 * (1.0 - smoothstep(0.375, 0.5, d)), rim);
		base = mix(base, min(base * 1.35 + 0.05, vec3(1.0)), smoothstep(0.012, 0.0, abs(d - 0.388)) * 0.7);
		base = mix(base, base * 0.6, smoothstep(0.01, 0.0, abs(d - 0.373)) * 0.8);

		// altta küçük numara, okunur olsun diye yarı saydam etiket üstünde
		float pill = max(abs(uv.x - 0.5) - 0.075, abs(uv.y - 0.815) - 0.045);
		base = mix(base, mix(base, vec3(1.0), 0.8), aa(pill) * disc);
		float ink = draw_number(uv, num, vec2(0.5, 0.815), 0.055, 0.09);
		base = mix(base, vec3(0.08), ink * disc);
	}
	if (holo > 0.5) {
		float h = fract(TIME * 0.3 + face_uv.x * 0.8 + face_uv.y * 0.5);
		vec3 rainbow = clamp(abs(fract(h + vec3(0.0, 0.333, 0.667)) * 6.0 - 3.0) - 1.0, 0.0, 1.0);
		base = mix(base, rainbow, 0.3);
		EMISSION = rainbow * 0.3;
	}
	ALBEDO = base;
	ROUGHNESS = holo > 0.5 ? 0.22 : 0.42;
	METALLIC = holo > 0.5 ? 0.45 : 0.0;
	SPECULAR = 0.6;
}
