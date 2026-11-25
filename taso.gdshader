shader_type spatial;

// Taso: kenarı set rengi, iki yüzünde atlas'tan gelen numara ve set kodu.
// INSTANCE_CUSTOM.x = atlas hücresi (benzersiz taso id), .y = holo (0/1)
uniform sampler2D atlas : source_color, filter_linear;
uniform float cols = 27.0;
uniform float radius = 0.12;
uniform float time_scale = 1.0;

varying vec2 face_uv;
varying float face;
varying vec4 inst;

void vertex() {
	face_uv = VERTEX.xz / (2.0 * radius) + 0.5;
	face = NORMAL.y;
	inst = INSTANCE_CUSTOM;
}

void fragment() {
	vec3 base = COLOR.rgb;
	float holo = inst.y;
	if (abs(face) > 0.5) {
		vec2 uv = face_uv;
		if (face < 0.0) {
			uv.x = 1.0 - uv.x;
		}
		vec2 cell = vec2(mod(inst.x, cols), floor(inst.x / cols));
		vec4 t = texture(atlas, (cell + clamp(uv, 0.02, 0.98)) / cols);
		base = mix(base, t.rgb, t.a);
	}
	if (holo > 0.5) {
		float h = fract(TIME * 0.3 * time_scale + face_uv.x * 0.8 + face_uv.y * 0.5);
		vec3 rainbow = clamp(abs(fract(h + vec3(0.0, 0.333, 0.667)) * 6.0 - 3.0) - 1.0, 0.0, 1.0);
		base = mix(base, rainbow, 0.35);
		EMISSION = rainbow * 0.35;
	}
	ALBEDO = base;
	ROUGHNESS = holo > 0.5 ? 0.25 : 0.65;
	METALLIC = holo > 0.5 ? 0.4 : 0.0;
}
