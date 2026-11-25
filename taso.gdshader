shader_type spatial;

// Taso: kenarı set rengi, iki yüzünde beyaz daire + set kodu + numara.
// Yazılar küçük bir atlas'tan (rakamlar 0-9 ve set kodları) anında birleştiriliyor,
// böylece 5000+ benzersiz taso için ayrı doku gerekmiyor.
// "art_set" setindeki tasolarda ise numaradan türetilen özgün bir yaratık çiziliyor.
// INSTANCE_CUSTOM.x = benzersiz taso id (set * nper + numara - 1), .y = holo (0/1)
// Atlas düzeni: 10 sütun x 'rows' satır, hücre 128x64. Satır 0: rakamlar, sonraki satırlar: set kodları.
uniform sampler2D atlas : source_color, filter_linear;
uniform float nper = 150.0;
uniform float rows = 5.0;
uniform float radius = 0.12;
uniform int art_set = 0;

varying vec2 face_uv;
varying float face;
varying vec4 inst;

void vertex() {
	face_uv = VERTEX.xz / (2.0 * radius) + 0.5;
	face = NORMAL.y;
	inst = INSTANCE_CUSTOM;
}

float sample_cell(vec2 cell, vec2 local) {
	if (local.x < 0.0 || local.x > 1.0 || local.y < 0.0 || local.y > 1.0) {
		return 0.0;
	}
	return texture(atlas, (cell + local) / vec2(10.0, rows)).a;
}

int digit_at(int num, int digits, int idx) {
	int p = digits - 1 - idx;
	if (p == 2) {
		return num / 100;
	}
	if (p == 1) {
		return (num / 10) % 10;
	}
	return num % 10;
}

// Numarayı verilen merkeze (dw: rakam genişliği, dh: yükseklik) çizer; mürekkep yoğunluğu döner
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

// ---------------- Prosedürel yaratık ----------------
float hsh(float n, float k) {
	return fract(sin(n * 12.9898 + k * 78.233) * 43758.5453);
}

vec3 hsv2rgb(vec3 c) {
	vec3 p = abs(fract(c.xxx + vec3(1.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
	return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

vec2 rot(vec2 v, float a) {
	float s = sin(a);
	float co = cos(a);
	return vec2(co * v.x - s * v.y, s * v.x + co * v.y);
}

float aa(float d) {
	return 1.0 - smoothstep(-0.006, 0.006, d);
}

// Döndürülmüş, kenar çizgili elips
vec3 blob(vec3 col, vec2 p, vec2 c, vec2 r, float a, vec3 fc, vec3 lc, float line) {
	vec2 q = rot(p - c, -a);
	float d = (length(q / r) - 1.0) * min(r.x, r.y);
	col = mix(col, lc, aa(d - line));
	return mix(col, fc, aa(d));
}

vec3 eye(vec3 col, vec2 p, vec2 c, float r, vec3 lc, float look) {
	col = blob(col, p, c, vec2(r), 0.0, vec3(1.0), lc, 0.018);
	col = blob(col, p, c + vec2(look * r * 0.25, r * 0.15), vec2(r * 0.52), 0.0, vec3(0.06), vec3(0.06), 0.0);
	col = blob(col, p, c + vec2(look * r * 0.25 - r * 0.2, -r * 0.1), vec2(r * 0.16), 0.0, vec3(1.0), vec3(1.0), 0.0);
	return col;
}

vec3 creature(vec2 p, float s, vec3 bg) {
	vec3 col = bg;
	float hue = hsh(s, 1.0);
	vec3 body_c = hsv2rgb(vec3(hue, 0.5 + 0.35 * hsh(s, 2.0), 0.92));
	vec3 line_c = body_c * 0.35;
	vec3 light_c = mix(body_c, vec3(1.0), 0.6);
	vec3 accent = hsv2rgb(vec3(fract(hue + 0.5), 0.7, 0.95));
	vec2 br = vec2(0.27 + 0.13 * hsh(s, 3.0), 0.23 + 0.12 * hsh(s, 4.0));
	vec2 bc = vec2(0.0, 0.06);
	float top = bc.y - br.y;
	float lw = 0.022;

	// kuyruk
	if (hsh(s, 9.0) > 0.45) {
		float side = hsh(s, 10.0) > 0.5 ? 1.0 : -1.0;
		col = blob(col, p, vec2(side * (br.x + 0.04), bc.y + 0.06), vec2(0.05, 0.15), side * 0.9, body_c, line_c, lw);
		col = blob(col, p, vec2(side * (br.x + 0.14), bc.y - 0.04), vec2(0.05), 0.0, accent, line_c, lw);
	}
	// kulak / boynuz / anten
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
	// ayaklar
	for (int i = 0; i < 2; i++) {
		float sx = i == 0 ? -1.0 : 1.0;
		col = blob(col, p, vec2(sx * br.x * 0.5, bc.y + br.y * 0.92), vec2(0.09, 0.055), 0.0, body_c * 0.8, line_c, lw);
	}
	// gövde ve karın
	col = blob(col, p, bc, br, 0.0, body_c, line_c, lw);
	col = blob(col, p, vec2(0.0, bc.y + br.y * 0.35), vec2(br.x * 0.6, br.y * 0.5), 0.0, light_c, light_c, 0.0);
	// benekler
	if (hsh(s, 6.0) > 0.5) {
		vec3 spot = mix(body_c, line_c, 0.35);
		col = blob(col, p, bc + vec2(-br.x * 0.62, -br.y * 0.2), vec2(0.045), 0.0, spot, spot, 0.0);
		col = blob(col, p, bc + vec2(br.x * 0.6, -br.y * 0.05), vec2(0.035), 0.0, spot, spot, 0.0);
		col = blob(col, p, bc + vec2(br.x * 0.45, -br.y * 0.55), vec2(0.03), 0.0, spot, spot, 0.0);
	}
	// gözler
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
	// yanaklar, ağız, dişler
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

		if (g == art_set) {
			// Yaratıklı taso: arka plan, yaratık, altta küçük numara
			vec3 bg = mix(vec3(0.98, 0.96, 0.9), base, 0.22);
			vec2 p = (uv - vec2(0.5, 0.45)) * 2.0;
			vec3 cr = creature(p, float(num), bg);
			base = mix(base, cr, disc);
			float ink = draw_number(uv, num, vec2(0.5, 0.815), 0.06, 0.1);
			base = mix(base, vec3(0.08), ink * disc);
		} else {
			base = mix(base, vec3(0.97, 0.96, 0.93), disc);
			float ink = 0.0;
			vec2 cq = (uv - vec2(0.33, 0.25)) / vec2(0.34, 0.17);
			ink = max(ink, sample_cell(vec2(float(g % 10), float(1 + g / 10)), cq));
			ink = max(ink, draw_number(uv, num, vec2(0.5, 0.565), 0.15, 0.27));
			base = mix(base, vec3(0.07, 0.07, 0.08), ink * disc);
		}
	}
	if (holo > 0.5) {
		float h = fract(TIME * 0.3 + face_uv.x * 0.8 + face_uv.y * 0.5);
		vec3 rainbow = clamp(abs(fract(h + vec3(0.0, 0.333, 0.667)) * 6.0 - 3.0) - 1.0, 0.0, 1.0);
		base = mix(base, rainbow, 0.3);
		EMISSION = rainbow * 0.3;
	}
	ALBEDO = base;
	ROUGHNESS = holo > 0.5 ? 0.25 : 0.65;
	METALLIC = holo > 0.5 ? 0.4 : 0.0;
}
