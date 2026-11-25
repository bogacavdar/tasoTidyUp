shader_type spatial;

// Taso: kenarı set rengi, iki yüzünde beyaz daire + set kodu + numara.
// Yazılar küçük bir atlas'tan (rakamlar 0-9 ve set kodları) anında birleştiriliyor,
// böylece 5000 benzersiz taso için 5000 doku gerekmiyor.
// INSTANCE_CUSTOM.x = benzersiz taso id (set * nper + numara - 1), .y = holo (0/1)
// Atlas düzeni: 10 sütun x 4 satır, hücre 128x64. Satır 0: rakamlar, satır 1-3: set kodları.
uniform sampler2D atlas : source_color, filter_linear;
uniform float nper = 200.0;
uniform float radius = 0.12;

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
	return texture(atlas, (cell + local) / vec2(10.0, 4.0)).a;
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

void fragment() {
	vec3 base = COLOR.rgb;
	float holo = inst.y;
	if (abs(face) > 0.5) {
		vec2 uv = face_uv;
		if (face < 0.0) {
			uv.x = 1.0 - uv.x;
		}
		// beyaz iç daire
		float d = length(uv - 0.5);
		float disc = 1.0 - smoothstep(0.36, 0.375, d);
		base = mix(base, vec3(0.97, 0.96, 0.93), disc);

		int uid = int(inst.x + 0.5);
		int nper_i = int(nper + 0.5);
		int g = uid / nper_i;
		int num = uid - g * nper_i + 1;

		float ink = 0.0;
		// set kodu (üst bant)
		vec2 cq = (uv - vec2(0.33, 0.25)) / vec2(0.34, 0.17);
		ink = max(ink, sample_cell(vec2(float(g % 10), float(1 + g / 10)), cq));
		// numara (orta)
		int digits = num >= 100 ? 3 : (num >= 10 ? 2 : 1);
		float dw = 0.15;
		vec2 nq = (uv - vec2(0.5 - dw * float(digits) * 0.5, 0.43)) / vec2(dw, 0.27);
		if (nq.x >= 0.0 && nq.x < float(digits) && nq.y >= 0.0 && nq.y <= 1.0) {
			int idx = int(floor(nq.x));
			int dig = digit_at(num, digits, idx);
			ink = max(ink, sample_cell(vec2(float(dig), 0.0), vec2(0.25 + fract(nq.x) * 0.5, nq.y)));
		}
		base = mix(base, vec3(0.07, 0.07, 0.08), ink * disc);
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
