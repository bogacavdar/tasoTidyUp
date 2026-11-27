extends Node
## Ana ekran: Devam Et / Yeni Oyun / Çıkış. Seçimden sonra yükleme ekranı:
## 1) modeller, dokular ve oyun sahnesi arka planda (iş parçacığında) yüklenir,
## 2) oyun sahnesi perde arkasında kurulur ve shader'lar ısıtılır,
## 3) her şey hazır olunca perde kalkar; oyun takılmadan başlar.

const MAIN := "res://main.tscn"
const SAVE_PATH := "user://kayit.json"
const ART := "res://assets/art/set_00.jpg"
const ART_COLS := 13
const ART_ROWS := 12

static var auto_new := false            # oyun içinden "Yeni Oyun" seçildi: doğrudan yeni oyunu yükle

const DISC_SHADER := """shader_type canvas_item;
uniform vec4 region;
void fragment() {
	vec2 p = UV - 0.5;
	float d = length(p);
	vec4 c = texture(TEXTURE, region.xy + UV * region.zw);
	float a = 1.0 - smoothstep(0.47, 0.5, d);
	float rim = smoothstep(0.43, 0.47, d) * a;
	COLOR = vec4(mix(c.rgb * mix(1.0, 0.75, smoothstep(0.3, 0.47, d)), vec3(0.08, 0.06, 0.05), rim), a * c.a);
}
"""

var layer: CanvasLayer
var root_ui: Control
var title_box: VBoxContainer
var load_box: VBoxContainer
var bar: ProgressBar
var step_lbl: Label
var tip_lbl: Label
var btn_cont: Button
var btn_new: Button
var new_confirm := false
var discs: Array = []
var phase := 0                         # 0 ana ekran, 1 dosyalar yükleniyor, 2 sahne kuruluyor, 3 bitti
var paths: Array = []
var keep: Array = []                   # yüklenen kaynakları önbellekte tutmak için
var main_node: Node
var shown := 0.0                       # çubuğun yumuşak ilerlemesi
var target := 0.0
var fade := -1.0

const TIPS := [
	"İpucu: Shift+Q elindeki bütün tasoları fırlatır.",
	"İpucu: Sağ tıkı basılı tutarak yakınlaşabilirsin.",
	"İpucu: Vitrinde bir tasoyu basılı tutup sürükleyerek yerini değiştirebilirsin.",
	"İpucu: Art arda doğru yerleştirmek puanını katlar.",
	"İpucu: Tab ile gelişim ağacını açabilirsin.",
]


func _ready() -> void:
	_migrate_old_save()
	layer = CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	root_ui = Control.new()
	root_ui.size = Vector2(1600, 900)
	layer.add_child(root_ui)
	var bg := ColorRect.new()
	bg.size = Vector2(1600, 900)
	var bm := ShaderMaterial.new()
	var bs := Shader.new()
	bs.code = """shader_type canvas_item;
void fragment() {
	vec2 p = UV - vec2(0.5, 0.42);
	float g = 1.0 - smoothstep(0.0, 0.9, length(p * vec2(1.6, 1.0)));
	COLOR = vec4(mix(vec3(0.05, 0.025, 0.02), vec3(0.32, 0.12, 0.05), g), 1.0);
}
"""
	bm.shader = bs
	bg.material = bm
	root_ui.add_child(bg)
	_make_discs()

	title_box = VBoxContainer.new()
	title_box.position = Vector2(500, 210)
	title_box.size = Vector2(600, 520)
	title_box.add_theme_constant_override("separation", 14)
	root_ui.add_child(title_box)
	var t := _label(title_box, "FULL SET", 96, Color("ffd36b"))
	t.add_theme_constant_override("outline_size", 14)
	_label(title_box, "COLLECTOR'S SHOP", 28, Color(1.0, 0.85, 0.7, 0.9))
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 30)
	title_box.add_child(sp)
	var has_save := FileAccess.file_exists(SAVE_PATH)
	btn_cont = _button(title_box, "Devam Et")
	btn_cont.disabled = not has_save
	btn_cont.pressed.connect(_start.bind(false))
	btn_new = _button(title_box, "Yeni Oyun")
	btn_new.pressed.connect(_on_new)
	if not OS.has_feature("web"):
		_button(title_box, "Çıkış").pressed.connect(func(): get_tree().quit())

	load_box = VBoxContainer.new()
	load_box.position = Vector2(450, 560)
	load_box.size = Vector2(700, 200)
	load_box.add_theme_constant_override("separation", 10)
	load_box.visible = false
	root_ui.add_child(load_box)
	var lt := _label(load_box, "Yükleniyor", 34, Color("ffd36b"))
	lt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(700, 14)
	bar.show_percentage = false
	bar.max_value = 1.0
	var b0 := StyleBoxFlat.new()
	b0.bg_color = Color(1, 1, 1, 0.1)
	b0.set_corner_radius_all(7)
	var b1 := StyleBoxFlat.new()
	b1.bg_color = Color("f2a640")
	b1.set_corner_radius_all(7)
	bar.add_theme_stylebox_override("background", b0)
	bar.add_theme_stylebox_override("fill", b1)
	load_box.add_child(bar)
	step_lbl = _label(load_box, "", 18, Color(1, 1, 1, 0.75))
	tip_lbl = _label(load_box, TIPS[randi() % TIPS.size()], 18, Color(1.0, 0.85, 0.6, 0.8))
	for l in [step_lbl, tip_lbl]:
		(l as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if auto_new:
		auto_new = false
		_start(true)
	elif has_save:
		btn_cont.grab_focus()
	else:
		btn_new.grab_focus()


## Oyunun adı "Taso Dükkânı"yken kayıt ve ayarlar o adla açılmış klasördeydi; yeni klasörde yoksa oradan kopyala
func _migrate_old_save() -> void:
	var new_dir := OS.get_user_data_dir()
	var old_dir := new_dir.get_base_dir().path_join("Taso Dükkânı")
	if old_dir == new_dir or not DirAccess.dir_exists_absolute(old_dir):
		return
	for f in ["kayit.json", "ayarlar.json"]:
		var src := old_dir.path_join(f)
		var dst := new_dir.path_join(f)
		if FileAccess.file_exists(src) and not FileAccess.file_exists(dst):
			DirAccess.copy_absolute(src, dst)


func _label(parent: Node, text: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 6)
	parent.add_child(l)
	return l


func _button(parent: Node, text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(380, 62)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 28)
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(12)
		sb.set_border_width_all(2)
		match st:
			"normal":
				sb.bg_color = Color(0.12, 0.07, 0.05, 0.85)
				sb.border_color = Color(0.85, 0.62, 0.3, 0.6)
			"hover", "focus":
				sb.bg_color = Color(0.3, 0.15, 0.07, 0.92)
				sb.border_color = Color("ffd36b")
			"pressed":
				sb.bg_color = Color(0.45, 0.22, 0.08, 0.95)
				sb.border_color = Color("ffd36b")
			"disabled":
				sb.bg_color = Color(0.1, 0.07, 0.06, 0.5)
				sb.border_color = Color(0.5, 0.4, 0.3, 0.3)
		b.add_theme_stylebox_override(st, sb)
	b.add_theme_color_override("font_color", Color(1.0, 0.9, 0.75))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.3))
	parent.add_child(b)
	return b


## Arka planda süzülen Kor Vadisi tasoları
func _make_discs() -> void:
	if not ResourceLoader.exists(ART):
		return
	var tex: Texture2D = load(ART)
	var sh := Shader.new()
	sh.code = DISC_SHADER
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for k in 16:
		var cell := rng.randi_range(0, ART_COLS * ART_ROWS - 1)
		if cell >= 150:
			cell = cell % 150
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		var s := rng.randf_range(110, 230)
		tr.size = Vector2(s, s)
		tr.pivot_offset = tr.size / 2.0
		var m := ShaderMaterial.new()
		m.shader = sh
		var inset := 0.02
		m.set_shader_parameter("region", Vector4((cell % ART_COLS + inset) / ART_COLS, (cell / ART_COLS + inset) / ART_ROWS,
			(1.0 - 2.0 * inset) / ART_COLS, (1.0 - 2.0 * inset) / ART_ROWS))
		tr.material = m
		tr.modulate = Color(1, 1, 1, rng.randf_range(0.22, 0.42))
		tr.position = Vector2(rng.randf_range(-100, 1600), rng.randf_range(-100, 900))
		root_ui.add_child(tr)
		discs.append([tr, Vector2(rng.randf_range(-18, 18), rng.randf_range(-30, -10)), rng.randf_range(-0.25, 0.25)])
	# ortada yazıların okunması için yumuşak karartma (tasoların üstünde, yazıların altında)
	var shade := ColorRect.new()
	shade.size = Vector2(1600, 900)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sm := ShaderMaterial.new()
	var ss := Shader.new()
	ss.code = """shader_type canvas_item;
void fragment() {
	vec2 p = (UV - vec2(0.5, 0.5)) * vec2(1.0, 1.25);
	COLOR = vec4(0.04, 0.02, 0.015, 0.85 * (1.0 - smoothstep(0.12, 0.42, length(p))));
}
"""
	sm.shader = ss
	shade.material = sm
	root_ui.add_child(shade)


func _on_new() -> void:
	if FileAccess.file_exists(SAVE_PATH) and not new_confirm:
		new_confirm = true
		btn_new.text = "Emin misin? İlerleme silinir"
		return
	_start(true)


func _start(new_game: bool) -> void:
	if phase != 0:
		return
	if new_game and FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	title_box.visible = false
	load_box.visible = true
	step_lbl.text = "Dosyalar yükleniyor"
	paths = [MAIN]
	_collect("res://assets/models", true)
	_collect("res://assets/tex", false)
	_collect("res://assets/hdri", false)
	_collect("res://assets/audio", false)
	for p in paths.duplicate():
		if ResourceLoader.load_threaded_request(p, "", true) != OK:
			paths.erase(p)
	phase = 1


## Dışa aktarılmış oyunda dosyalar ".import"/".remap" adıyla görünür; asıl yolu çıkar
func _collect(dir: String, models: bool) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	if models:
		for d in DirAccess.get_directories_at(dir):
			var p := "%s/%s/%s.gltf" % [dir, d, d]
			if ResourceLoader.exists(p):
				paths.append(p)
		return
	for f in DirAccess.get_files_at(dir):
		var n: String = f.trim_suffix(".import").trim_suffix(".remap")
		var p := dir + "/" + n
		if n.get_extension() in ["jpg", "png", "hdr", "ogg", "wav", "webp"] and not paths.has(p) and ResourceLoader.exists(p):
			paths.append(p)


func _process(delta: float) -> void:
	for d in discs:
		var tr: TextureRect = d[0]
		tr.position += (d[1] as Vector2) * delta
		tr.rotation += float(d[2]) * delta
		if tr.position.y < -260:
			tr.position.y = 920
		if tr.position.x < -260:
			tr.position.x = 1620
		elif tr.position.x > 1640:
			tr.position.x = -240
	if phase == 1:
		var done := 0.0
		var all := true
		for p in paths:
			var pr := []
			var st := ResourceLoader.load_threaded_get_status(p, pr)
			if st == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				all = false
				done += float(pr[0]) if pr.size() > 0 else 0.0
			else:
				done += 1.0
		target = 0.45 * done / maxf(paths.size(), 1)
		if all:
			for p in paths:
				var r = ResourceLoader.load_threaded_get(p)
				if r != null:
					keep.append(r)
			phase = 2
			_launch()
	shown = move_toward(shown, target, delta * 0.8)
	bar.value = shown
	if fade >= 0.0:
		fade += delta * 2.5
		root_ui.modulate.a = 1.0 - clampf(fade, 0.0, 1.0)
		if fade >= 1.0:
			queue_free()


func _launch() -> void:
	step_lbl.text = "Dükkân kuruluyor"
	var ps: PackedScene = keep[0] if keep.size() > 0 and keep[0] is PackedScene else load(MAIN)
	main_node = ps.instantiate()
	main_node.get_script().from_title = true
	main_node.boot_progress.connect(_on_boot)
	main_node.boot_done.connect(_on_done)
	# oyun sahnesi perdenin arkasında kurulur (bu ekran en üstte kalır)
	get_tree().root.add_child.call_deferred(main_node)


func _on_boot(f: float, text: String) -> void:
	target = 0.45 + 0.55 * f
	step_lbl.text = text


func _on_done() -> void:
	phase = 3
	target = 1.0
	shown = 1.0
	bar.value = 1.0
	get_tree().current_scene = main_node
	# perde birkaç kare sonra yumuşakça kalkar
	await get_tree().process_frame
	fade = 0.0
