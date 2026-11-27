shader_type spatial;

// Taso: kenarsız; canlı resmi (setin atlasından) yüzü tamamen kaplar, kenarda yalnızca ince koyu
// bir kabartma çizgisi var. Numara üstte, koyu yarı saydam etiket üstünde beyaz ve okunaklı.
//
// Her setin kendi malzemesi ve atlası var: assets/art/set_XX.jpg (13 x 12 hücre, hücre i = numara i+1).
// INSTANCE_CUSTOM: x = benzersiz taso id (set * nper + numara - 1), y = holo (0/1)
// Rakam atlası: 10 sütun x 'rows' satır, hücre 128x64. Satır 0: rakamlar 0-9.
uniform sampler2D atlas : source_color, filter_linear;
uniform sampler2D art : source_color, filter_linear_mipmap_anisotropic;
uniform bool has_art = false;
uniform float art_cols = 13.0;
uniform float art_rows = 12.0;
uniform float nper = 150.0;
uniform float rows = 5.0;
uniform float radius = 0.12;

const float DISC = 0.488;      // resmin kapladığı daire (uv yarıçapı, kenar 0.5)

varying vec2 face_uv;
varying float face;
varying vec4 inst;
varying vec3 wpos;

void vertex() {
	face_uv = VERTEX.xz / (2.0 * radius) + 0.5;
	face = NORMAL.y;
	inst = INSTANCE_CUSTOM;
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
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

float aa(float d) {
	return 1.0 - smoothstep(-0.006, 0.006, d);
}

// ---------------- Taso yüzü ----------------
void fragment() {
	// kenar ve yan yüz: koyu, set rengi yok
	vec3 base = vec3(0.1, 0.092, 0.085);
	float gloss = 0.0;
	float holo = inst.y;
	if (face < -0.5) {
		// arka yüz: bütün tasolarda aynı. Koyu kırmızı zemin, ışınlar, altın halkalar ve yıldız.
		vec2 p = vec2(1.0 - face_uv.x, face_uv.y) - 0.5;
		float d = length(p);
		float a = atan(p.y, p.x);
		vec3 col = mix(vec3(0.5, 0.07, 0.06), vec3(0.16, 0.025, 0.03), smoothstep(0.0, 0.5, d));
		float ray = step(0.5, fract(a * 16.0 / 6.2831853));
		col = mix(col, col * 1.35, ray * 0.4 * (1.0 - smoothstep(0.12, 0.42, d)));
		vec3 gold = vec3(0.93, 0.72, 0.32);
		col = mix(col, gold, aa(abs(d - 0.455) - 0.014));
		col = mix(col, gold, aa(abs(d - 0.41) - 0.004));
		float dots = aa(length(vec2(fract(a * 24.0 / 6.2831853) - 0.5, (d - 0.36) * 24.0 / 6.2831853 * 6.0)) * 0.02 - 0.004);
		col = mix(col, gold, dots * aa(abs(d - 0.36) - 0.02));
		float star_r = 0.075 + 0.075 * pow(0.5 + 0.5 * cos(5.0 * (a + 1.5708)), 2.0);
		col = mix(col, gold * 0.75, aa(d - star_r - 0.012));
		col = mix(col, gold * 1.08, aa(d - star_r));
		col = mix(col, gold, aa(abs(d - 0.2) - 0.005));
		base = mix(base, col, 1.0 - smoothstep(0.492, 0.5, d));
	} else if (face > 0.5) {
		vec2 uv = face_uv;
		float d = length(uv - 0.5);
		float disc = 1.0 - smoothstep(DISC - 0.006, DISC + 0.004, d);

		int uid = int(inst.x + 0.5);
		int nper_i = int(nper + 0.5);
		int g = uid / nper_i;
		int num = uid - g * nper_i + 1;

		vec3 pic = vec3(0.95, 0.93, 0.88);
		if (has_art) {
			float cell = float(num - 1);
			vec2 cxy = vec2(mod(cell, art_cols), floor(cell / art_cols));
			vec2 cuv = clamp((uv - 0.5) / (2.0 * DISC) + 0.5, 0.012, 0.988);
			pic = texture(art, (cxy + cuv) / vec2(art_cols, art_rows)).rgb;
		}
		// kenara doğru hafif kararma ve ince kabartma çizgisi
		pic *= mix(1.0, 0.8, smoothstep(DISC - 0.06, DISC, d));
		base = mix(base, pic, disc);
		base = mix(base, min(base * 1.25 + 0.04, vec3(1.0)), smoothstep(0.006, 0.0, abs(d - (DISC - 0.008))) * 0.35);

		// üstte numara: koyu yarı saydam etiket, beyaz rakamlar
		vec2 nc = vec2(0.5, 0.13);
		float pill = max(abs(uv.x - nc.x) - 0.085, abs(uv.y - nc.y) - 0.05);
		float pr = length(max(vec2(abs(uv.x - nc.x) - 0.06, abs(uv.y - nc.y) - 0.025), 0.0)) - 0.025;
		base = mix(base, base * 0.25, aa(pr) * 0.78 * disc);
		float ink = draw_number(uv, num, nc, 0.058, 0.085);
		base = mix(base, vec3(1.0), ink * disc);

		// cilalı baskı: bakış açısıyla yüzeyde kayan ince bir parıltı ve kenarlara doğru yansıma
		vec3 r = reflect(-VIEW, NORMAL);
		float band = sin(r.x * 7.0 + r.y * 5.0 + (wpos.x + wpos.z) * 9.0 + (uv.x + uv.y) * 2.5);
		float glint = smoothstep(0.86, 1.0, band) * 0.22 + smoothstep(0.6, 1.0, band) * 0.05;
		float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
		gloss = (glint + fres * 0.18) * disc;

		// kenar kabartması: resmin hemen dışında incecik bir hat; sol üst ışık alır, sağ alt gölgede kalır
		vec2 dir2 = (uv - 0.5) / max(d, 0.001);
		float lit = 0.5 + 0.5 * dot(dir2, normalize(vec2(-0.6, -0.8)));
		float lip = smoothstep(DISC + 0.001, DISC + 0.005, d) * (1.0 - smoothstep(0.494, 0.499, d));
		base = mix(base, mix(vec3(0.05, 0.045, 0.04), vec3(0.62, 0.58, 0.52), lit), lip * 0.85);
	}
	if (holo > 0.5) {
		float h = fract(TIME * 0.3 + face_uv.x * 0.8 + face_uv.y * 0.5);
		vec3 rainbow = clamp(abs(fract(h + vec3(0.0, 0.333, 0.667)) * 6.0 - 3.0) - 1.0, 0.0, 1.0);
		base = mix(base, rainbow, 0.3);
		EMISSION = rainbow * 0.3;
	}
	ALBEDO = base;
	EMISSION += vec3(1.0, 0.98, 0.94) * gloss;
	// ön yüz cilalı (parlak), kenar ve arka yüz daha mat
	ROUGHNESS = face > 0.5 ? 0.24 : (face < -0.5 ? 0.45 : 0.32);
	METALLIC = 0.0;
	SPECULAR = face > 0.5 ? 0.7 : 0.5;
}
