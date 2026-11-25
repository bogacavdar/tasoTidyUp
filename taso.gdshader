shader_type spatial;

// Taso: ince bir set rengi kenar; yüzünü neredeyse tamamen kaplayan canlı resmi (setin
// atlasından, tools/gen_creatures.py ile üretilmiş) ve altta küçük numara.
//
// Her setin kendi malzemesi ve atlası var: assets/art/set_XX.jpg (13 x 12 hücre, hücre i = numara i+1).
// INSTANCE_CUSTOM: x = benzersiz taso id (set * nper + numara - 1), y = holo (0/1)
// Rakam atlası: 10 sütun x 'rows' satır, hücre 128x64. Satır 0: rakamlar 0-9.
uniform sampler2D atlas : source_color, filter_linear;
uniform sampler2D art : source_color, filter_linear_mipmap;
uniform bool has_art = false;
uniform float art_cols = 13.0;
uniform float art_rows = 12.0;
uniform float nper = 150.0;
uniform float rows = 5.0;
uniform float radius = 0.12;

const float DISC = 0.465;      // resmin kapladığı daire (uv yarıçapı, kenar 0.5)

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

float aa(float d) {
	return 1.0 - smoothstep(-0.006, 0.006, d);
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

		vec3 pic = vec3(0.95, 0.93, 0.88);
		if (has_art) {
			float cell = float(num - 1);
			vec2 cxy = vec2(mod(cell, art_cols), floor(cell / art_cols));
			vec2 cuv = clamp((uv - 0.5) / (2.0 * DISC) + 0.5, 0.012, 0.988);
			pic = texture(art, (cxy + cuv) / vec2(art_cols, art_rows)).rgb;
		}
		// kenar kararması
		pic *= mix(1.0, 0.86, smoothstep(DISC - 0.12, DISC, d));
		base = mix(base, pic, disc);
		// ince kenar: kabartma çizgisi
		base = mix(base, base * 0.55, smoothstep(0.008, 0.0, abs(d - DISC - 0.002)) * 0.8);
		base = mix(base, min(base * 1.3 + 0.05, vec3(1.0)), smoothstep(0.008, 0.0, abs(d - 0.485)) * 0.6);

		// altta küçük numara, yarı saydam etiket üstünde
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
