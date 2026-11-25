extends Node3D
## Taso Kaosu — 3D birinci şahıs prototip.
## Dev bir depo, kaotik yığınlarda 5000 BENZERSİZ taso (34 set x 150 = 5100), duvarlarda 34 vitrin.
## Her taso her yuvaya konabilir; sırayı oyuncu kurar. Yanlış yerdekiler kırmızı,
## tamamen doğru dizilen vitrin yeşil olur.
## Sahne tamamen koddan kuruluyor; dışarıdan model yok.

# ---------------- Ayarlar ----------------
const NUMBERS_PER_SET := 150
const HOLO_CHANCE := 0.04
const WALL_MARGIN := 1.6      # vitrinlerin önünde boş bırakılan şerit

const TASO_R := 0.12
const TASO_H := 0.014
const BASE_Y := 0.02
const REACH := 3.6
const GRAB_RADIUS := 0.4
const CELL := 1.0              # uzamsal ızgara hücre boyu

const ROOM_W := 70.0           # x
const ROOM_D := 50.0           # z
const BUILD_H := 11.0          # bina iç yüksekliği
const DOOR_W := 4.0
const DOOR_H := 3.6
const MEZZ_Y := 5.4            # asma kat zemin yüksekliği
const MEZZ_EDGE_Z := -10.0     # asma kat z=-25 ile bu değer arasında
const MEZZ_SHARE := 0.2        # tasoların asma kata saçılan oranı
const STAIR_X := 8.0           # iki kollu merdiven: x = -8 ve +8
const STAIR_W := 2.4           # merdiven genişliği
const STAIR_Z0 := -1.0         # merdivenin başladığı z (zemin kat)
const STAIR_STEPS := 30
const STAND_X := [-15.0, -5.0, 5.0, 15.0]
const STAND_Z := 8.0
const COLUMN_X := [-28.0, -20.0, -12.0, -4.0, 4.0, 12.0, 20.0, 28.0]

const SLOT_COLS := 10
const SLOT_ROWS := 15
const SLOT_GAP := 0.25
const BOARD_Y := 2.45          # vitrin panosunun orta yüksekliği (en alt sıra 0.7 m)

const WALK_SPEED := 4.5
const SPRINT_MULT := 2.0
const JUMP_VELOCITY := 4.8
const GRAVITY := 12.0
const MOUSE_SENS := 0.0025

const SETS := [
	{"name": "Kor Vadisi", "code": "KV"}, {"name": "Derin Su", "code": "DS"},
	{"name": "Taş Kök", "code": "TK"}, {"name": "Gece Rüzgârı", "code": "GR"},
	{"name": "Buz Tepesi", "code": "BT"}, {"name": "Şimşek Ovası", "code": "ŞO"},
	{"name": "Kum Çölü", "code": "KÇ"}, {"name": "Mantar Ormanı", "code": "MO"},
	{"name": "Demir Dağ", "code": "DD"}, {"name": "Mercan Koyu", "code": "MK"},
	{"name": "Gölge Mağara", "code": "GM"}, {"name": "Yıldız Bahçe", "code": "YB"},
	{"name": "Lav Gölü", "code": "LG"}, {"name": "Sis Bataklığı", "code": "SB"},
	{"name": "Kristal Vadi", "code": "KR"}, {"name": "Ay Tapınağı", "code": "AT"},
	{"name": "Bulut Adası", "code": "BA"}, {"name": "Kızıl Kanyon", "code": "KK"},
	{"name": "Zümrüt Orman", "code": "ZO"}, {"name": "Fırtına Burnu", "code": "FB"},
	{"name": "Kehribar Köy", "code": "KH"}, {"name": "Gümüş Nehir", "code": "GN"},
	{"name": "Yosun Mağara", "code": "YM"}, {"name": "Güneş Sarayı", "code": "GS"},
	{"name": "Kuyruklu Yıldız", "code": "KY"}, {"name": "Kar Ovası", "code": "KO"},
	{"name": "Altın Kum", "code": "AK"}, {"name": "Mor Dağ", "code": "MD"},
	{"name": "Rüzgâr Gülü", "code": "RG"}, {"name": "Gök Kubbe", "code": "GK"},
	{"name": "Kaya Kalesi", "code": "KA"}, {"name": "Dalga Kıyısı", "code": "DK"},
	{"name": "Volkan Ağzı", "code": "VA"}, {"name": "Çiçek Vadisi", "code": "ÇV"},
]
# Her setin çizim teması: [motif, ana renk tonu (0-1), mod]
# motif: 0 yaratık, 1 balık, 2 çiçek/mercan, 3 kristal, 4 gök cismi, 5 mantar, 6 kuş/yarasa, 7 manzara, 8 böcek
# mod: 0 normal, 1 gece/koyu, 2 pastel, 3 taş/metalik
const SET_ART := [
	[0, 0.03, 0], [1, 0.60, 0], [0, 0.08, 3], [6, 0.72, 1], [7, 0.55, 2], [4, 0.14, 0],
	[8, 0.10, 2], [5, 0.00, 0], [3, 0.60, 3], [2, 0.95, 0], [0, 0.75, 1], [2, 0.15, 2],
	[7, 0.02, 0], [0, 0.30, 3], [3, 0.50, 0], [4, 0.62, 1], [6, 0.55, 2], [7, 0.04, 0],
	[2, 0.38, 0], [6, 0.60, 3], [8, 0.09, 0], [1, 0.55, 3], [5, 0.30, 1], [4, 0.10, 0],
	[4, 0.70, 1], [0, 0.58, 2], [8, 0.13, 0], [7, 0.78, 0], [2, 0.85, 2], [4, 0.58, 2],
	[3, 0.08, 3], [7, 0.52, 0], [0, 0.02, 1], [2, 0.90, 0],
]

const PALETTE := [
	"e6194b", "3cb44b", "ffe119", "4363d8", "f58231", "911eb4", "42d4f4", "f032e6",
	"bfef45", "fabed4", "469990", "dcbeff", "9a6324", "fffac8", "800000", "aaffc3",
	"808000", "ffd8b1", "000075", "a9a9a9", "ffffff", "222222", "ff6f61", "6b5b95",
	"88b04b", "92a8d1", "955251", "b565a7", "009b77", "dd4124", "45b8ac", "efc050",
	"5b3a29", "1e5945",
]  # 34 set için birbirinden belirgin ayrışan renkler
const RING_EMPTY := Color("efe3c8")   # boş yuva: krem
const RING_WRONG := Color("ff2a2a")
const RING_DONE := Color("3fe06a")
const BOARD_COLOR := Color("3a281b")  # koyu ahşap pano
const BOARD_DONE := Color("2f6b3a")

const SKILL_ORDER := ["oto", "avuc", "holo"]
const AVUC_GRAB := [1, 3, 6, 12]
const AVUC_CAP := [10, 15, 25, 40]

const COIN_PLACE := 2
const COIN_HOLO := 10
const COIN_SET := 200

# ---------------- Durum ----------------
var set_count := SETS.size()
var set_colors: Array[Color] = []
var tasos: Array = []                 # Dictionary: grp, num, holo
var pile_xf: Array[Transform3D] = []  # yığındaki son konum
var in_pile: Array[bool] = []
var pile_count := 0
var grid := {}                        # Vector2i -> Array[int]
var slots: Array = []                 # slots[grp][n] = taso indeksi ya da -1
var hand: Array = []
var sel := 0                          # eldeki seçili taso
var holo_list: Array[int] = []
var skills := {}
var coins := 0
var placed := 0                       # vitrinlerdeki taso sayısı
var correct := 0                      # doğru yerdeki taso sayısı
var elapsed := 0.0
var anim := 0.0
var finished := false
var message := ""
var message_time := 0.0
var target := {}

# ---------------- Düğümler ----------------
var player: CharacterBody3D
var cam: Camera3D
var hand_root: Node3D
var taso_mesh: CylinderMesh
var taso_mat: ShaderMaterial
var pile_mm: MultiMesh
var shelf_mm: MultiMesh
var hand_mm: MultiMesh
var holo_mm: MultiMesh
var holo_mmi: MultiMeshInstance3D
var holo_ring_mat: StandardMaterial3D
var atlas_vp: SubViewport
var atlas_rows := 5
var shelves: Array = []
var shelf_titles: Array = []
var ring_mm: MultiMesh
var lip_mm: MultiMesh
var hover_ring: MeshInstance3D
var glass_mat: StandardMaterial3D
var mat_floor: StandardMaterial3D
var mat_wall: StandardMaterial3D
var mat_ceiling: StandardMaterial3D
var mat_wood: StandardMaterial3D
var mat_wood_fine: StandardMaterial3D
var mat_paint: StandardMaterial3D
var mat_sidewalk: StandardMaterial3D
var mat_road: StandardMaterial3D
var mat_marble: StandardMaterial3D
var board_tint := Color.WHITE
var board_done_tint := Color.WHITE
var led_mat: StandardMaterial3D
var sky_mat: StandardMaterial3D
var board_mats: Array = []
var header_mats: Array = []
var shelf_done: Array[bool] = []
var set_bonus_paid: Array[bool] = []
var paid: Array[bool] = []            # bu taso doğru yere ilk kez oturunca jeton verildi mi
var hidden_xf := Transform3D(Basis().scaled(Vector3.ONE * 0.0001), Vector3(0, -50, 0))

var sfx: AudioStreamPlayer
var snd_correct: AudioStreamWAV
var snd_holo: AudioStreamWAV
var snd_set: AudioStreamWAV
var last_sfx_frame := -1

# Dokunmatik (telefon) kontrolleri
const TOUCH_LOOK_SENS := 0.005
const JOY_RADIUS := 110.0
var touch_mode := false
var move_id := -1
var move_origin := Vector2.ZERO
var touch_move := Vector2.ZERO
var look_id := -1
var look_start := Vector2.ZERO
var look_start_ms := 0
var look_travel := 0.0
var touch_jump := false
var touch_sprint := false
var joy_base: Panel
var joy_knob: Panel

var hud_stats: Label
var hud_info: Label
var hud_hand: Label
var hud_msg: Label
var hud_skills: Label
var hud_center: Label


func _ready() -> void:
	randomize()
	touch_mode = OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
	_init_skills()
	_make_set_colors()
	_build_atlas()
	_make_taso_material()
	_make_env_materials()
	_build_world()
	_build_player()
	_spawn_tasos()
	_build_pile()
	_build_hud()
	_build_sounds()
	_say("Bir yığına yürü, tasoya bak ve sol tıkla!")


func _init_skills() -> void:
	skills = {
		"oto": {"name": "Otomatik Dizme", "desc": "vitrine tıklayınca elindeki o setin tasoları doğru boş yuvalarına gider", "cost": [60], "level": 0},
		"avuc": {"name": "Avuç", "desc": "tek tıkla 3/6/12 taso al, el kapasitesi 15/25/40", "cost": [40, 150, 400], "level": 0},
		"holo": {"name": "Holo Dedektörü", "desc": "gömülü holo tasolar yığının içinden parlar", "cost": [120], "level": 0},
	}


func _uid(t: Dictionary) -> int:
	return int(t["grp"]) * NUMBERS_PER_SET + int(t["num"]) - 1


func _set_color(g: int) -> Color:
	return set_colors[g]


func _make_set_colors() -> void:
	for g in set_count:
		set_colors.append(Color.html(PALETTE[g % PALETTE.size()]))


# ---------------- Taso yüzü atlası ----------------
# Küçük bir doku: 1. satırda 0-9 rakamları, sonraki satırlarda set kodları (hücre 128x64).
# Shader her tasonun numarasını ve set kodunu bu parçalardan anında birleştirir.
func _build_atlas() -> void:
	var cw := 128
	var ch := 64
	atlas_vp = SubViewport.new()
	atlas_rows = 1 + ceili(set_count / 10.0)
	atlas_vp.size = Vector2i(10 * cw, atlas_rows * ch)
	atlas_vp.transparent_bg = true
	atlas_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(atlas_vp)
	var root := Control.new()
	root.size = Vector2(atlas_vp.size)
	atlas_vp.add_child(root)
	var texts: Array = []
	for dgt in 10:
		texts.append([str(dgt), Vector2(dgt * cw, 0), 58])
	for g in set_count:
		texts.append([SETS[g]["code"], Vector2((g % 10) * cw, (1 + floori(g / 10.0)) * ch), 50])
	for e in texts:
		var l := Label.new()
		l.text = e[0]
		l.position = e[1]
		l.size = Vector2(cw, ch)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", e[2])
		l.add_theme_color_override("font_color", Color.WHITE)
		root.add_child(l)
	_freeze_atlas.call_deferred()


func _freeze_atlas() -> void:
	for i in 4:
		await get_tree().process_frame
	atlas_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED


func _make_taso_material() -> void:
	taso_mesh = CylinderMesh.new()
	taso_mesh.top_radius = TASO_R
	taso_mesh.bottom_radius = TASO_R
	taso_mesh.height = TASO_H
	taso_mesh.radial_segments = 24
	taso_mesh.rings = 1
	taso_mat = ShaderMaterial.new()
	taso_mat.shader = load("res://taso.gdshader")
	taso_mat.set_shader_parameter("atlas", atlas_vp.get_texture())
	taso_mat.set_shader_parameter("nper", float(NUMBERS_PER_SET))
	taso_mat.set_shader_parameter("rows", float(atlas_rows))
	taso_mat.set_shader_parameter("radius", TASO_R)


func _tex(id: String, kind: String) -> Texture2D:
	var path := "res://assets/tex/%s_%s.jpg" % [id, kind]
	if ResourceLoader.exists(path):
		return load(path)
	return null


## Poly Haven dokusu varsa gerçekçi PBR malzeme; yoksa düz renk (fallback)
func _pbr(id: String, fallback: Color, scale: float, tint: Color = Color.WHITE, rough: float = 0.75) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = fallback
	m.roughness = rough
	var d := _tex(id, "diff")
	if d != null:
		m.albedo_color = tint
		m.albedo_texture = d
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3.ONE * scale
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		var n := _tex(id, "nor")
		if n != null:
			m.normal_enabled = true
			m.normal_texture = n
		var r := _tex(id, "rough")
		if r != null:
			m.roughness_texture = r
			m.roughness = 1.0
	return m


func _make_env_materials() -> void:
	mat_floor = _pbr("diagonal_parquet", Color("7a5a3c"), 0.5)
	mat_wall = _pbr("beige_wall_001", Color("d9c9ae"), 0.3, Color(1.0, 0.97, 0.92))
	mat_ceiling = _pbr("beige_wall_001", Color("ece5d8"), 0.3, Color(1.0, 1.0, 1.0))
	mat_wood = _pbr("dark_wood", Color("5a3d28"), 0.9, Color.WHITE, 0.5)
	mat_wood_fine = _pbr("fine_grained_wood", Color("8a6240"), 1.2, Color.WHITE, 0.45)
	mat_sidewalk = _pbr("concrete_floor_02", Color("8d8d8d"), 0.4)
	mat_road = _pbr("asphalt_02", Color("3b3b3b"), 0.3)
	mat_marble = _pbr("marble_01", Color("e8e4dc"), 0.6, Color.WHITE, 0.2)
	mat_paint = _mat(Color("f1ece2"))
	var has_wood := mat_wood.albedo_texture != null
	board_tint = Color(0.62, 0.58, 0.55) if has_wood else BOARD_COLOR
	board_done_tint = Color(0.45, 0.95, 0.5) if has_wood else BOARD_DONE
	glass_mat = StandardMaterial3D.new()
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.albedo_color = Color(0.85, 0.95, 1.0, 0.1)
	glass_mat.roughness = 0.05
	glass_mat.metallic = 0.3
	led_mat = StandardMaterial3D.new()
	led_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	led_mat.albedo_color = Color("fff3d6")
	sky_mat = StandardMaterial3D.new()
	sky_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sky_mat.albedo_color = Color("cfe9ff")


func _new_mm(count: int) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = taso_mesh
	mm.instance_count = count
	return mm


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.8
	return m


# ---------------- Dünya ----------------
func _box(parent: Node, size: Vector3, pos: Vector3, col: Color, kind: String, m: Material = null) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.set_meta("kind", kind)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = m if m != null else _mat(col)
	body.add_child(mi)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	body.add_child(cs)
	parent.add_child(body)
	return body


func _mesh_box(parent: Node, size: Vector3, pos: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = m
	mi.position = pos
	parent.add_child(mi)
	return mi


func _cyl(parent: Node, r: float, h: float, pos: Vector3, col: Color, collide: bool) -> Node3D:
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = 16
	var mi := MeshInstance3D.new()
	mi.mesh = cm
	mi.material_override = _mat(col)
	if not collide:
		mi.position = pos
		parent.add_child(mi)
		return mi
	var body := StaticBody3D.new()
	body.position = pos
	body.set_meta("kind", "wall")
	body.add_child(mi)
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = r
	sh.height = h
	cs.shape = sh
	body.add_child(cs)
	parent.add_child(body)
	return body


func _build_world() -> void:
	var hw := ROOM_W / 2.0
	var hd := ROOM_D / 2.0

	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("a9cfee")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 0.95, 0.88)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.15
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_bloom = 0.05
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.08
	env.adjustment_contrast = 1.05
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 25, 0)
	sun.light_energy = 0.55
	add_child(sun)
	var lamp_spots := [
		[Vector3(-20, BUILD_H - 0.8, 8), 24.0], [Vector3(0, BUILD_H - 0.8, 8), 24.0], [Vector3(20, BUILD_H - 0.8, 8), 24.0],
		[Vector3(-20, MEZZ_Y - 0.6, -17), 13.0], [Vector3(20, MEZZ_Y - 0.6, -17), 13.0],
		[Vector3(-18, BUILD_H - 0.6, -17), 14.0], [Vector3(18, BUILD_H - 0.6, -17), 14.0],
	]
	for ls in lamp_spots:
		var lamp := OmniLight3D.new()
		lamp.position = ls[0]
		lamp.omni_range = ls[1]
		lamp.light_energy = 1.3
		lamp.light_color = Color(1, 0.93, 0.82)
		lamp.light_energy = 1.6
		add_child(lamp)
		_pendant_lamp(lamp.position + Vector3(0, 0.35, 0))

	# --- Zemin, dış kaldırım, tavan ---
	var floor_col := Color("7a5a3c")
	_box(self, Vector3(ROOM_W + 0.6, 0.2, ROOM_D + 0.6), Vector3(0, -0.1, 0), floor_col, "floor", mat_floor)
	_box(self, Vector3(ROOM_W + 30, 0.2, 24), Vector3(0, -0.12, hd + 12.3), Color("8d8d8d"), "floor", mat_sidewalk)
	_box(self, Vector3(ROOM_W + 30, 0.2, 14), Vector3(0, -0.13, hd + 31), Color("3b3b3b"), "floor", mat_road)
	_box(self, Vector3(ROOM_W + 0.6, 0.3, ROOM_D + 0.6), Vector3(0, BUILD_H + 0.15, 0), Color("e9e1d3"), "wall", mat_ceiling)

	# --- Duvarlar (ön duvarda kapı boşluğu) ---
	var wall := Color("d9c9ae")
	_box(self, Vector3(ROOM_W + 0.6, BUILD_H, 0.3), Vector3(0, BUILD_H / 2, -hd - 0.15), wall, "wall", mat_wall)
	_box(self, Vector3(0.3, BUILD_H, ROOM_D + 0.6), Vector3(-hw - 0.15, BUILD_H / 2, 0), wall, "wall", mat_wall)
	_box(self, Vector3(0.3, BUILD_H, ROOM_D + 0.6), Vector3(hw + 0.15, BUILD_H / 2, 0), wall, "wall", mat_wall)
	var seg_w := hw - DOOR_W / 2.0
	for sx in [-1.0, 1.0]:
		_box(self, Vector3(seg_w, BUILD_H, 0.3), Vector3(sx * (DOOR_W / 2.0 + seg_w / 2.0), BUILD_H / 2, hd + 0.15), wall, "wall", mat_wall)
	_box(self, Vector3(DOOR_W, BUILD_H - DOOR_H, 0.3), Vector3(0, DOOR_H + (BUILD_H - DOOR_H) / 2, hd + 0.15), wall, "wall", mat_wall)
	# süpürgelik
	var trim: Material = mat_wood
	_mesh_box(self, Vector3(ROOM_W, 0.15, 0.04), Vector3(0, 0.075, -hd + 0.02), trim)
	_mesh_box(self, Vector3(0.04, 0.15, ROOM_D), Vector3(-hw + 0.02, 0.075, 0), trim)
	_mesh_box(self, Vector3(0.04, 0.15, ROOM_D), Vector3(hw - 0.02, 0.075, 0), trim)

	# --- Kapı: çerçeve, açık cam kanatlar, tabela ---
	var frame_col := Color("3b2a1d")
	for sx in [-1.0, 1.0]:
		_box(self, Vector3(0.2, DOOR_H, 0.45), Vector3(sx * (DOOR_W / 2.0 + 0.1), DOOR_H / 2, hd + 0.15), frame_col, "wall", mat_wood)
		var leaf := Node3D.new()
		leaf.position = Vector3(sx * DOOR_W / 2.0, 0, hd + 0.2)
		leaf.rotation.y = sx * 1.3
		add_child(leaf)
		_mesh_box(leaf, Vector3(DOOR_W / 2.0 - 0.1, DOOR_H - 0.15, 0.05), Vector3(-sx * (DOOR_W / 4.0), DOOR_H / 2, 0), glass_mat)
		_mesh_box(leaf, Vector3(0.06, DOOR_H - 0.15, 0.07), Vector3(-sx * (DOOR_W / 2.0 - 0.1), DOOR_H / 2, 0), mat_wood)
	_mesh_box(self, Vector3(DOOR_W + 0.6, 0.2, 0.45), Vector3(0, DOOR_H + 0.1, hd + 0.15), mat_wood)
	for side in [1.0, -1.0]:
		var sign_z: float = hd + 0.15 + side * 0.25
		var board := _mesh_box(self, Vector3(9.0, 1.4, 0.12), Vector3(0, DOOR_H + 1.3, sign_z), _mat(Color("8a1f2b")))
		board.position.z = sign_z
		var sl := Label3D.new()
		sl.text = "TASO DÜKKÂNI"
		sl.font_size = 96
		sl.pixel_size = 0.01
		sl.outline_size = 16
		sl.modulate = Color("ffe08a")
		sl.position = Vector3(0, DOOR_H + 1.3, sign_z + side * 0.08)
		sl.rotation.y = 0.0 if side > 0 else PI
		add_child(sl)
	# paspas
	_mesh_box(self, Vector3(DOOR_W, 0.02, 2.0), Vector3(0, 0.01, hd - 1.2), _mat(Color("4b2b2b")))

	# --- Pencereler (dışarıdan gün ışığı giren camlar) ---
	for x in [-10.0, 10.0]:
		_window(Vector3(x, 2.1, hd - 0.03), Vector2(6.0, 3.0), PI)
	for x in [-22.0, -8.0, 8.0, 22.0]:
		_window(Vector3(x, 7.8, hd - 0.03), Vector2(4.0, 2.4), PI)
	for z in [-2.0, 8.0, 18.0]:
		_window(Vector3(-hw + 0.03, 7.8, z), Vector2(4.0, 2.4), PI / 2)
		_window(Vector3(hw - 0.03, 7.8, z), Vector2(4.0, 2.4), -PI / 2)
	for x in [-26.0, -14.0, 14.0, 26.0]:
		_window(Vector3(x, 2.4, -hd + 0.03), Vector2(5.0, 2.6), 0.0)

	# --- Kasa ---
	var counter := _box(self, Vector3(3.2, 1.0, 1.0), Vector3(8.5, 0.5, hd - 5.5), Color("6b4a32"), "wall", mat_wood)
	counter.set_meta("kind", "wall")
	_mesh_box(self, Vector3(3.3, 0.06, 1.1), Vector3(8.5, 1.03, hd - 5.5), mat_marble)
	_mesh_box(self, Vector3(0.5, 0.3, 0.4), Vector3(8.0, 1.21, hd - 5.5), _mat(Color("2a2a2a")))
	var kl := Label3D.new()
	kl.text = "KASA"
	kl.font_size = 64
	kl.pixel_size = 0.006
	kl.outline_size = 10
	kl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	kl.position = Vector3(8.5, 2.0, hd - 5.5)
	add_child(kl)

	# --- Asma kat: döşeme, kolonlar, cam korkuluk, sahanlık ---
	var mezz_d := MEZZ_EDGE_Z + hd
	_box(self, Vector3(ROOM_W, 0.3, mezz_d), Vector3(0, MEZZ_Y - 0.15, (-hd + MEZZ_EDGE_Z) / 2.0), floor_col, "floor", mat_floor)
	_mesh_box(self, Vector3(ROOM_W, 0.32, 0.06), Vector3(0, MEZZ_Y - 0.15, MEZZ_EDGE_Z + 0.03), trim)
	for x in COLUMN_X:
		_box(self, Vector3(0.45, MEZZ_Y - 0.3, 0.45), Vector3(x, (MEZZ_Y - 0.3) / 2.0, MEZZ_EDGE_Z - 0.3), Color("cbb89a"), "wall", mat_marble)
	# Cam korkuluk: iki merdivenin geldiği yerlerde boşluk var
	var gap := STAIR_W / 2.0 + 0.05
	var rail_spans := [
		[-hw, -STAIR_X - gap], [-STAIR_X + gap, STAIR_X - gap], [STAIR_X + gap, hw],
	]
	for span in rail_spans:
		var x0: float = span[0]
		var x1: float = span[1]
		var seg_len := x1 - x0
		var cx := (x0 + x1) / 2.0
		var rail := _box(self, Vector3(seg_len, 1.0, 0.05), Vector3(cx, MEZZ_Y + 0.5, MEZZ_EDGE_Z - 0.08), Color("cfe8f0"), "wall")
		(rail.get_child(0) as MeshInstance3D).material_override = glass_mat
		_mesh_box(self, Vector3(seg_len, 0.07, 0.1), Vector3(cx, MEZZ_Y + 1.03, MEZZ_EDGE_Z - 0.08), mat_wood_fine)
		_mesh_box(self, Vector3(seg_len, 0.05, 0.08), Vector3(cx, MEZZ_Y + 0.03, MEZZ_EDGE_Z - 0.08), mat_wood_fine)

	_build_stairs(-STAIR_X)
	_build_stairs(STAIR_X)

	# --- Ortak çoklu çizimler: yuva halkaları, raf çıtaları, vitrindeki tasolar ---
	var total := set_count * NUMBERS_PER_SET
	var ring_mesh := CylinderMesh.new()
	ring_mesh.top_radius = TASO_R + 0.014
	ring_mesh.bottom_radius = TASO_R + 0.014
	ring_mesh.height = 0.004
	ring_mesh.radial_segments = 24
	ring_mm = MultiMesh.new()
	ring_mm.transform_format = MultiMesh.TRANSFORM_3D
	ring_mm.use_colors = true
	ring_mm.mesh = ring_mesh
	ring_mm.instance_count = total
	var ring_mmi := MultiMeshInstance3D.new()
	ring_mmi.multimesh = ring_mm
	var ring_mat := StandardMaterial3D.new()
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.vertex_color_use_as_albedo = true
	ring_mmi.material_override = ring_mat
	add_child(ring_mmi)

	var lip_mesh := BoxMesh.new()
	lip_mesh.size = Vector3(SLOT_COLS * SLOT_GAP + 0.2, 0.018, 0.08)
	lip_mm = MultiMesh.new()
	lip_mm.transform_format = MultiMesh.TRANSFORM_3D
	lip_mm.mesh = lip_mesh
	lip_mm.instance_count = set_count * SLOT_ROWS
	var lip_mmi := MultiMeshInstance3D.new()
	lip_mmi.multimesh = lip_mm
	lip_mmi.material_override = mat_wood_fine
	add_child(lip_mmi)

	shelf_mm = _new_mm(total)
	var shelf_mmi := MultiMeshInstance3D.new()
	shelf_mmi.multimesh = shelf_mm
	shelf_mmi.material_override = taso_mat
	add_child(shelf_mmi)

	# --- Vitrin yerleşimi ---
	var placements := _vitrine_placements()
	for g in set_count:
		var pl: Array = placements[g]
		_build_vitrine(g, pl[0], pl[1])

	# Baktığın yuvayı gösteren sarı halka
	var torus := TorusMesh.new()
	torus.inner_radius = TASO_R + 0.012
	torus.outer_radius = TASO_R + 0.04
	hover_ring = MeshInstance3D.new()
	hover_ring.mesh = torus
	var hmat := StandardMaterial3D.new()
	hmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hmat.albedo_color = Color("ffe14d")
	hover_ring.material_override = hmat
	hover_ring.visible = false
	add_child(hover_ring)


func _window(center: Vector3, size: Vector2, rot: float) -> void:
	var node := Node3D.new()
	node.position = center
	node.rotation.y = rot
	add_child(node)
	_mesh_box(node, Vector3(size.x, size.y, 0.02), Vector3.ZERO, sky_mat)
	var fm := _mat(Color("f2ede4"))
	var t := 0.1
	_mesh_box(node, Vector3(size.x + t * 2, t, 0.08), Vector3(0, size.y / 2 + t / 2, 0.03), fm)
	_mesh_box(node, Vector3(size.x + t * 2, t * 1.5, 0.14), Vector3(0, -size.y / 2 - t * 0.75, 0.05), fm)
	_mesh_box(node, Vector3(t, size.y, 0.08), Vector3(-size.x / 2 - t / 2, 0, 0.03), fm)
	_mesh_box(node, Vector3(t, size.y, 0.08), Vector3(size.x / 2 + t / 2, 0, 0.03), fm)
	_mesh_box(node, Vector3(0.05, size.y, 0.05), Vector3(0, 0, 0.02), fm)
	_mesh_box(node, Vector3(size.x, 0.05, 0.05), Vector3(0, 0, 0.02), fm)


## Bir merdiven kolu: verilen x'te, zemin kattan (z = STAIR_Z0) asma kat kenarına (z = MEZZ_EDGE_Z) çıkar.
## İki kol (x = -8 ve +8) asma katın balkonuyla birlikte U şekli oluşturur.
## Görünen basamakların altında, karakterin takılmadan yürüdüğü görünmez düz bir rampa var.
func _build_stairs(x: float) -> void:
	var run := STAIR_Z0 - MEZZ_EDGE_Z
	var rise := MEZZ_Y / STAIR_STEPS
	var tread := run / STAIR_STEPS
	var w := STAIR_W
	# basamaklar ve rıhtlar
	for k in STAIR_STEPS:
		var z_front := STAIR_Z0 - k * tread
		var y_top := (k + 1) * rise
		_mesh_box(self, Vector3(w, 0.045, tread + 0.035), Vector3(x, y_top - 0.0225, z_front - tread / 2.0 + 0.0175), mat_wood)
		_mesh_box(self, Vector3(w - 0.02, rise, 0.02), Vector3(x, y_top - rise / 2.0, z_front - 0.01), mat_paint)
	# basamakların altını kapatan eğimli gövde ve yan kirişler (görsel)
	var p0 := Vector3(x, 0.0, STAIR_Z0)
	var p1 := Vector3(x, MEZZ_Y, MEZZ_EDGE_Z)
	_slope_box(self, Vector3(w, 0.25, 0.0), p0, p1, -0.2, mat_paint, false)
	for sx in [-1.0, 1.0]:
		var side := Vector3(sx * (w / 2.0 + 0.05), 0, 0)
		_slope_box(self, Vector3(0.1, 0.45, 0.0), p0 + side, p1 + side, 0.05, mat_wood, false)
	# görünmez yürüme rampası: basamak burunlarının biraz altından geçer
	var ext := (p1 - p0).normalized()
	_slope_box(self, Vector3(w, 0.1, 0.0), p0 + Vector3(0, rise * 0.5, 0) - ext * 0.6, p1 + Vector3(0, rise * 0.5, 0), -0.05, null, true)
	# korkuluklar: görünmez duvar + babalar + küpeşte
	for sx in [-1.0, 1.0]:
		var side := Vector3(sx * (w / 2.0 + 0.04), 0, 0)
		_slope_box(self, Vector3(0.06, 1.0, 0.0), p0 + side, p1 + side, 0.55, null, true)
		_slope_box(self, Vector3(0.09, 0.07, 0.0), p0 + side + Vector3(0, 0.95, 0), p1 + side + Vector3(0, 0.95, 0), 0.0, mat_wood_fine, false)
		for k in range(0, STAIR_STEPS, 2):
			var z := STAIR_Z0 - (k + 0.5) * tread
			var y := (k + 1) * rise
			_cyl(self, 0.022, 0.92, Vector3(x + side.x, y + 0.46, z), Color("f1ece2"), false)
		# başlangıç direği
		_box(self, Vector3(0.16, 1.15, 0.16), Vector3(x + side.x, 0.575, STAIR_Z0 + 0.05), Color("5a3d28"), "wall", mat_wood)
		_mesh_box(self, Vector3(0.22, 0.08, 0.22), Vector3(x + side.x, 1.19, STAIR_Z0 + 0.05), mat_wood_fine)
	# merdiven önünde halı
	_mesh_box(self, Vector3(w + 0.4, 0.015, 1.6), Vector3(x, 0.008, STAIR_Z0 + 1.0), _mat(Color("7a1f27")))


## a'dan b'ye uzanan eğimli kutu. size.x = genişlik, size.y = kalınlık (uzunluk otomatik).
## up_off: kutunun yüzeye dik yönde kaydırılması. m = null ise görünmez.
func _slope_box(parent: Node, size: Vector3, a: Vector3, b: Vector3, up_off: float, m: Material, collide: bool) -> void:
	var zf := (b - a).normalized()
	var yu := (Vector3.UP - zf * Vector3.UP.dot(zf)).normalized()
	var xr := yu.cross(zf)
	var length := a.distance_to(b)
	var sz := Vector3(size.x, size.y, length)
	var xf := Transform3D(Basis(xr, yu, zf), (a + b) / 2.0 + yu * up_off)
	if collide:
		var body := StaticBody3D.new()
		body.transform = xf
		body.set_meta("kind", "floor")
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = sz
		cs.shape = sh
		body.add_child(cs)
		if m != null:
			var mi := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = sz
			mi.mesh = bm
			mi.material_override = m
			body.add_child(mi)
		parent.add_child(body)
	elif m != null:
		var mi2 := MeshInstance3D.new()
		var bm2 := BoxMesh.new()
		bm2.size = sz
		mi2.mesh = bm2
		mi2.material_override = m
		mi2.transform = xf
		parent.add_child(mi2)


## Tavandan sarkan sarkıt lamba (kablo, abajur, parlayan ampul)
func _pendant_lamp(pos: Vector3) -> void:
	var top := BUILD_H if pos.y > MEZZ_Y + 1.0 else MEZZ_Y - 0.3
	var cord_len := maxf(top - pos.y, 0.1)
	_cyl(self, 0.01, cord_len, pos + Vector3(0, cord_len / 2.0, 0), Color("202020"), false)
	var shade := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.12
	cm.bottom_radius = 0.42
	cm.height = 0.35
	cm.radial_segments = 24
	shade.mesh = cm
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color("2f4f3f")
	sm.metallic = 0.6
	sm.roughness = 0.35
	sm.cull_mode = BaseMaterial3D.CULL_DISABLED
	shade.material_override = sm
	shade.position = pos
	add_child(shade)
	var bulb := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 0.09
	sp.height = 0.18
	bulb.mesh = sp
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.albedo_color = Color(1.0, 0.92, 0.75)
	bulb.material_override = bm
	bulb.position = pos + Vector3(0, -0.15, 0)
	add_child(bulb)


## 34 vitrin: [konum, y-dönüşü]. Vitrin yerelde +z'ye bakar.
func _vitrine_placements() -> Array:
	var hw := ROOM_W / 2.0 - 0.05
	var hd := ROOM_D / 2.0 - 0.05
	var out: Array = []
	# Zemin kat sol ve sağ duvar: 6'şar
	for z in [-20.0, -12.5, -5.0, 2.5, 10.0, 17.5]:
		out.append([Vector3(-hw, 0, z), PI / 2])
	for z in [-20.0, -12.5, -5.0, 2.5, 10.0, 17.5]:
		out.append([Vector3(hw, 0, z), -PI / 2])
	# Orta standlar: çift taraflı, 4 stand x 2 yüz
	for x in STAND_X:
		out.append([Vector3(x, 0, STAND_Z + 0.06), 0.0])
		out.append([Vector3(x, 0, STAND_Z - 0.06), PI])
	# Ön duvar, kapının iki yanı: 4
	for x in [-26.0, -18.0, 18.0, 26.0]:
		out.append([Vector3(x, 0, hd), PI])
	# Asma kat: arka duvar 8, yan duvarlar 1'er
	for x in [-28.0, -20.0, -12.0, -4.0, 4.0, 12.0, 20.0, 28.0]:
		out.append([Vector3(x, MEZZ_Y, -hd), 0.0])
	out.append([Vector3(-hw, MEZZ_Y, -17.5), PI / 2])
	out.append([Vector3(hw, MEZZ_Y, -17.5), -PI / 2])
	return out


func _build_vitrine(g: int, pos: Vector3, rot: float) -> void:
	var shelf := Node3D.new()
	shelf.position = pos
	shelf.rotation.y = rot
	add_child(shelf)
	shelves.append(shelf)
	var col := _set_color(g)
	var w := SLOT_COLS * SLOT_GAP + 0.2
	var h := SLOT_ROWS * SLOT_GAP + 0.3
	var depth := 0.42
	var wood := Color("5a3d28")
	var top_y := BOARD_Y + h / 2.0
	var base_top := BOARD_Y - h / 2.0

	var board_m: StandardMaterial3D = mat_wood.duplicate()
	board_m.albedo_color = board_tint
	var back := _box(shelf, Vector3(w, h, 0.1), Vector3(0, BOARD_Y, 0), BOARD_COLOR, "shelf", board_m)
	back.set_meta("grp", g)
	board_mats.append(board_m)
	for sx in [-1.0, 1.0]:
		var side := _box(shelf, Vector3(0.08, h + 0.12, depth), Vector3(sx * (w / 2.0 + 0.04), BOARD_Y, depth / 2.0 - 0.05), wood, "shelf", mat_wood)
		side.set_meta("grp", g)
	var cap := _box(shelf, Vector3(w + 0.16, 0.1, depth + 0.04), Vector3(0, top_y + 0.05, depth / 2.0 - 0.04), wood, "shelf", mat_wood)
	cap.set_meta("grp", g)
	var base := _box(shelf, Vector3(w + 0.16, base_top, depth + 0.08), Vector3(0, base_top / 2.0, depth / 2.0 - 0.02), wood.darkened(0.25), "shelf", mat_wood)
	base.set_meta("grp", g)
	var header := _box(shelf, Vector3(w + 0.16, 0.26, 0.12), Vector3(0, top_y + 0.23, 0.02), col, "shelf")
	header.set_meta("grp", g)
	var hm: StandardMaterial3D = (header.get_child(0) as MeshInstance3D).material_override
	hm.emission = Color("3fae5a")
	header_mats.append(hm)
	_mesh_box(shelf, Vector3(w, 0.025, 0.03), Vector3(0, top_y - 0.03, depth - 0.12), led_mat)
	_mesh_box(shelf, Vector3(w, h, 0.012), Vector3(0, BOARD_Y, depth - 0.06), glass_mat)

	var title := Label3D.new()
	title.font_size = 64
	title.pixel_size = 0.0026
	title.outline_size = 12
	title.position = Vector3(0, top_y + 0.23, 0.09)
	shelf.add_child(title)
	shelf_titles.append(title)

	for r in SLOT_ROWS:
		var ry := BOARD_Y + ((SLOT_ROWS - 1) / 2.0 - r) * SLOT_GAP
		lip_mm.set_instance_transform(g * SLOT_ROWS + r, shelf.global_transform * Transform3D(Basis(), Vector3(0, ry - TASO_R - 0.012, 0.09)))

	var row_slots: Array = []
	for n in NUMBERS_PER_SET:
		var sp := _slot_local(n)
		ring_mm.set_instance_transform(g * NUMBERS_PER_SET + n, shelf.global_transform * Transform3D(Basis(Vector3.RIGHT, PI / 2), sp + Vector3(0, 0, 0.002)))
		ring_mm.set_instance_color(g * NUMBERS_PER_SET + n, RING_EMPTY)
		row_slots.append(-1)
		shelf_mm.set_instance_transform(g * NUMBERS_PER_SET + n, hidden_xf)
	slots.append(row_slots)
	shelf_done.append(false)
	set_bonus_paid.append(false)
	_update_title(g)


func _slot_local(n: int) -> Vector3:
	var c := n % SLOT_COLS
	var r := floori(float(n) / SLOT_COLS)
	return Vector3((c - (SLOT_COLS - 1) / 2.0) * SLOT_GAP, BOARD_Y + ((SLOT_ROWS - 1) / 2.0 - r) * SLOT_GAP, 0.05)


func _nearest_slot(local: Vector3) -> int:
	var c := roundi(local.x / SLOT_GAP + (SLOT_COLS - 1) / 2.0)
	var r := roundi((BOARD_Y - local.y) / SLOT_GAP + (SLOT_ROWS - 1) / 2.0)
	if c < 0 or c >= SLOT_COLS or r < 0 or r >= SLOT_ROWS:
		return -1
	return r * SLOT_COLS + c


func _update_title(g: int) -> void:
	var filled := 0
	for v in slots[g]:
		if v != -1:
			filled += 1
	var lb: Label3D = shelf_titles[g]
	if shelf_done[g]:
		lb.text = "%s (%s)   TAMAM!" % [SETS[g]["name"], SETS[g]["code"]]
	else:
		lb.text = "%s (%s)   %d/%d" % [SETS[g]["name"], SETS[g]["code"], filled, NUMBERS_PER_SET]


func _build_player() -> void:
	player = CharacterBody3D.new()
	player.position = Vector3(0, 0.95, ROOM_D / 2.0 - 3.0)
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.7
	cs.shape = cap
	player.add_child(cs)
	cam = Camera3D.new()
	cam.position = Vector3(0, 0.7, 0)
	cam.fov = 75
	cam.near = 0.03
	cam.far = 120
	player.add_child(cam)
	hand_root = Node3D.new()
	hand_root.position = Vector3(0.3, -0.28, -0.55)
	hand_root.rotation = Vector3(1.15, -0.25, 0)
	cam.add_child(hand_root)
	hand_mm = _new_mm(AVUC_CAP[AVUC_CAP.size() - 1])
	hand_mm.visible_instance_count = 0
	var hmi := MultiMeshInstance3D.new()
	hmi.multimesh = hand_mm
	hmi.material_override = taso_mat
	hand_root.add_child(hmi)
	add_child(player)


# ---------------- Tasolar ----------------
func _spawn_tasos() -> void:
	var pairs: Array = []
	for g in set_count:
		for n in NUMBERS_PER_SET:
			pairs.append(Vector2i(g, n + 1))
	pairs.shuffle()
	for i in pairs.size():
		var p: Vector2i = pairs[i]
		var holo := randf() < HOLO_CHANCE
		tasos.append({"grp": p.x, "num": p.y, "holo": holo})
		if holo:
			holo_list.append(i)
		# İki katın zeminine tamamen rastgele saçılır; çakışmasın diye hafif yükseklik farkı
		var pos := _random_floor_pos()
		var b := Basis(Vector3.UP, randf() * TAU) * Basis(Vector3.RIGHT, randf_range(-0.12, 0.12))
		pile_xf.append(Transform3D(b, pos))
		in_pile.append(true)
		paid.append(false)
		_grid_add(i)
	pile_count = tasos.size()


func _random_floor_pos() -> Vector3:
	var hw := ROOM_W / 2.0 - WALL_MARGIN
	var hd := ROOM_D / 2.0 - WALL_MARGIN
	for attempt in 40:
		var jitter := randf() * 0.04
		if randf() < MEZZ_SHARE:
			return Vector3(randf_range(-hw, hw), MEZZ_Y + BASE_Y + jitter, randf_range(-hd, MEZZ_EDGE_Z - 0.6))
		var p := Vector3(randf_range(-hw, hw), BASE_Y + jitter, randf_range(-hd, hd))
		if _floor_blocked(p):
			continue
		return p
	return Vector3(randf_range(-10, 10), BASE_Y, 15.0)


## Zemin katta taso saçılmayacak yerler: merdiven, standlar, kolonlar, kapı önü, kasa
func _floor_blocked(p: Vector3) -> bool:
	if absf(absf(p.x) - STAIR_X) < STAIR_W / 2.0 + 0.6 and p.z > MEZZ_EDGE_Z - 0.5 and p.z < STAIR_Z0 + 2.0:
		return true
	for sx in STAND_X:
		if absf(p.x - sx) < 2.2 and absf(p.z - STAND_Z) < 1.3:
			return true
	for cx in COLUMN_X:
		if absf(p.x - cx) < 0.6 and absf(p.z - (MEZZ_EDGE_Z - 0.3)) < 0.6:
			return true
	if absf(p.x) < 3.0 and p.z > ROOM_D / 2.0 - 4.0:
		return true
	if absf(p.x - 8.5) < 2.2 and absf(p.z - (ROOM_D / 2.0 - 5.5)) < 1.2:
		return true
	return false


func _build_pile() -> void:
	pile_mm = _new_mm(tasos.size())
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = pile_mm
	mmi.material_override = taso_mat
	add_child(mmi)
	for i in tasos.size():
		pile_mm.set_instance_transform(i, pile_xf[i])
		pile_mm.set_instance_custom_data(i, _custom(i))
	_recolor_pile()

	# Holo dedektörü halkaları: derinlik testi yok, yığının içinden görünür
	var torus := TorusMesh.new()
	torus.inner_radius = TASO_R + 0.01
	torus.outer_radius = TASO_R + 0.045
	holo_mm = MultiMesh.new()
	holo_mm.transform_format = MultiMesh.TRANSFORM_3D
	holo_mm.mesh = torus
	holo_mm.instance_count = holo_list.size()
	holo_mmi = MultiMeshInstance3D.new()
	holo_mmi.multimesh = holo_mm
	holo_ring_mat = StandardMaterial3D.new()
	holo_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	holo_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	holo_ring_mat.no_depth_test = true
	holo_ring_mat.albedo_color = Color(1, 0.95, 0.4, 0.8)
	holo_mmi.material_override = holo_ring_mat
	holo_mmi.visible = false
	add_child(holo_mmi)
	_refresh_holo()


func _custom(i: int) -> Color:
	var t: Dictionary = tasos[i]
	var art: Array = SET_ART[int(t["grp"]) % SET_ART.size()]
	var theme: float = float(art[2]) + float(art[1])
	return Color(float(_uid(t)), 1.0 if t["holo"] else 0.0, float(art[0]), theme)


func _taso_color(i: int) -> Color:
	return _set_color(tasos[i]["grp"])


func _recolor_pile() -> void:
	for i in tasos.size():
		pile_mm.set_instance_color(i, _taso_color(i))


func _refresh_holo() -> void:
	for k in holo_list.size():
		var i := holo_list[k]
		holo_mm.set_instance_transform(k, pile_xf[i] if in_pile[i] else hidden_xf)


# Uzamsal ızgara: 5000 taso arasında bakılanı ve yakındakileri hızlı bulmak için
func _cell(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x / CELL), floori(p.z / CELL))


func _grid_add(i: int) -> void:
	var k := _cell(pile_xf[i].origin)
	if not grid.has(k):
		grid[k] = []
	grid[k].append(i)


func _grid_remove(i: int) -> void:
	var k := _cell(pile_xf[i].origin)
	if grid.has(k):
		grid[k].erase(i)


func _take(i: int) -> void:
	_grid_remove(i)
	in_pile[i] = false
	pile_count -= 1
	pile_mm.set_instance_transform(i, hidden_xf)
	hand.append(i)


func _put_in_pile(i: int, xf: Transform3D) -> void:
	pile_xf[i] = xf
	in_pile[i] = true
	pile_count += 1
	pile_mm.set_instance_transform(i, xf)
	_grid_add(i)


func _grab_count() -> int:
	return AVUC_GRAB[skills["avuc"]["level"]]


func _cap() -> int:
	return AVUC_CAP[skills["avuc"]["level"]]


# ---------------- Döngü ----------------
func _physics_process(delta: float) -> void:
	var mv := Vector2.ZERO
	if Input.is_key_pressed(KEY_W):
		mv.y += 1
	if Input.is_key_pressed(KEY_S):
		mv.y -= 1
	if Input.is_key_pressed(KEY_D):
		mv.x += 1
	if Input.is_key_pressed(KEY_A):
		mv.x -= 1
	if touch_move != Vector2.ZERO:
		mv += Vector2(touch_move.x, -touch_move.y)
	var fwd := -player.global_transform.basis.z
	var right := player.global_transform.basis.x
	var d := fwd * mv.y + right * mv.x
	d.y = 0
	d = d.normalized() * minf(mv.length(), 1.0)
	var sprint := Input.is_key_pressed(KEY_SHIFT) or touch_sprint
	var speed := WALK_SPEED * (SPRINT_MULT if sprint else 1.0)
	player.velocity.x = d.x * speed
	player.velocity.z = d.z * speed
	if player.is_on_floor():
		if Input.is_key_pressed(KEY_SPACE) or touch_jump:
			player.velocity.y = JUMP_VELOCITY
	else:
		player.velocity.y -= GRAVITY * delta
	player.move_and_slide()
	if player.global_position.y < -5.0:
		player.global_position = Vector3(0, 1.0, ROOM_D / 2.0 - 3.0)
	cam.fov = lerpf(cam.fov, 82.0 if (sprint and mv != Vector2.ZERO) else 75.0, 8.0 * delta)
	target = _find_target()
	_update_hover()


func _update_hover() -> void:
	hover_ring.visible = false
	if target.get("kind", "") != "shelf":
		return
	var body: Node = target["body"]
	var g: int = body.get_meta("grp")
	var shelf: Node3D = shelves[g]
	var n := _nearest_slot(shelf.to_local(target["point"]))
	if n == -1:
		return
	hover_ring.global_transform = shelf.global_transform * Transform3D(Basis(Vector3.RIGHT, PI / 2), _slot_local(n) + Vector3(0, 0, 0.03))
	hover_ring.visible = true


func _process(delta: float) -> void:
	anim += delta
	if not finished:
		elapsed += delta
	if message_time > 0.0:
		message_time -= delta
	holo_mmi.visible = skills["holo"]["level"] > 0
	holo_ring_mat.albedo_color.a = 0.45 + 0.45 * sin(anim * 5.0)
	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		_touch_input(event)
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		player.rotate_y(-event.relative.x * MOUSE_SENS)
		cam.rotation.x = clampf(cam.rotation.x - event.relative.y * MOUSE_SENS, -1.5, 1.5)
		return
	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			return
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_on_use()
			MOUSE_BUTTON_RIGHT:
				_drop(false)
			MOUSE_BUTTON_WHEEL_UP:
				_cycle(-1)
			MOUSE_BUTTON_WHEEL_DOWN:
				_cycle(1)
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			KEY_Q:
				_drop(true)
			KEY_R:
				get_tree().reload_current_scene()
			KEY_1:
				_try_buy("oto")
			KEY_2:
				_try_buy("avuc")
			KEY_3:
				_try_buy("holo")


## Sol yarı: sanal joystick. Sağ yarı: sürükleyerek bak, kısa dokunuşla kullan.
func _touch_input(event: InputEvent) -> void:
	var vw := get_viewport().get_visible_rect().size.x
	if event is InputEventScreenTouch:
		var e: InputEventScreenTouch = event
		if e.pressed:
			if e.position.x < vw * 0.45 and move_id == -1:
				move_id = e.index
				move_origin = e.position
				touch_move = Vector2.ZERO
				joy_base.position = e.position - joy_base.size / 2.0
				joy_knob.position = e.position - joy_knob.size / 2.0
				joy_base.visible = true
				joy_knob.visible = true
			elif look_id == -1:
				look_id = e.index
				look_start = e.position
				look_start_ms = Time.get_ticks_msec()
				look_travel = 0.0
		else:
			if e.index == move_id:
				move_id = -1
				touch_move = Vector2.ZERO
				joy_base.visible = false
				joy_knob.visible = false
			elif e.index == look_id:
				look_id = -1
				if look_travel < 25.0 and Time.get_ticks_msec() - look_start_ms < 350:
					_on_use()
	elif event is InputEventScreenDrag:
		var e: InputEventScreenDrag = event
		if e.index == move_id:
			var off := e.position - move_origin
			if off.length() > JOY_RADIUS:
				off = off.normalized() * JOY_RADIUS
			touch_move = off / JOY_RADIUS
			joy_knob.position = move_origin + off - joy_knob.size / 2.0
		elif e.index == look_id:
			look_travel += e.relative.length()
			player.rotate_y(-e.relative.x * TOUCH_LOOK_SENS)
			cam.rotation.x = clampf(cam.rotation.x - e.relative.y * TOUCH_LOOK_SENS, -1.5, 1.5)


func _round_panel(col: Color, size: float) -> Panel:
	var pn := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(int(size / 2.0))
	pn.add_theme_stylebox_override("panel", sb)
	pn.size = Vector2(size, size)
	pn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pn.visible = false
	return pn


func _touch_button(parent: Node, text: String, pos: Vector2, size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 24)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.35)
	sb.set_corner_radius_all(18)
	sb.border_color = Color(1, 1, 1, 0.5)
	sb.set_border_width_all(2)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	var sbp := sb.duplicate() as StyleBoxFlat
	sbp.bg_color = Color(1, 1, 1, 0.3)
	b.add_theme_stylebox_override("pressed", sbp)
	parent.add_child(b)
	return b


func _build_touch_ui(layer: CanvasLayer) -> void:
	joy_base = _round_panel(Color(1, 1, 1, 0.15), JOY_RADIUS * 2.0)
	joy_knob = _round_panel(Color(1, 1, 1, 0.45), 90.0)
	layer.add_child(joy_base)
	layer.add_child(joy_knob)
	var jump := _touch_button(layer, "Zıpla", Vector2(1420, 700), Vector2(150, 150))
	jump.button_down.connect(func(): touch_jump = true)
	jump.button_up.connect(func(): touch_jump = false)
	var run := _touch_button(layer, "Koş", Vector2(1260, 760), Vector2(140, 100))
	run.toggle_mode = true
	run.toggled.connect(func(on: bool): touch_sprint = on)
	_touch_button(layer, "Bırak", Vector2(1420, 560), Vector2(150, 110)).pressed.connect(func(): _drop(true))
	_touch_button(layer, "Hepsini\nbırak", Vector2(1260, 620), Vector2(140, 110)).pressed.connect(func(): _drop(false))
	_touch_button(layer, "<", Vector2(20, 110), Vector2(90, 80)).pressed.connect(func(): _cycle(-1))
	_touch_button(layer, ">", Vector2(120, 110), Vector2(90, 80)).pressed.connect(func(): _cycle(1))
	for k in SKILL_ORDER.size():
		var key: String = SKILL_ORDER[k]
		_touch_button(layer, str(k + 1), Vector2(1280 + k * 100, 120), Vector2(85, 75)).pressed.connect(func(): _try_buy(key))


func _cycle(dir: int) -> void:
	if hand.is_empty():
		return
	sel = posmod(sel + dir, hand.size())
	_rebuild_hand()


func _find_target() -> Dictionary:
	var o := cam.global_position
	var d := -cam.global_transform.basis.z
	var best_t := REACH
	var res := {"kind": ""}
	var cells := {}
	var step := 0.25
	for s in int(REACH / step) + 1:
		var p := o + d * (s * step)
		for dx in [-TASO_R, TASO_R]:
			for dz in [-TASO_R, TASO_R]:
				cells[_cell(p + Vector3(dx, 0, dz))] = true
	for k in cells:
		if not grid.has(k):
			continue
		for i in grid[k]:
			var v := pile_xf[i].origin - o
			var t := v.dot(d)
			if t < 0.0 or t > best_t:
				continue
			if v.length_squared() - t * t < TASO_R * TASO_R:
				best_t = t
				res = {"kind": "taso", "idx": i, "point": o + d * t}
	var q := PhysicsRayQueryParameters3D.create(o, o + d * REACH)
	q.exclude = [player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		var hp: Vector3 = hit["position"]
		if (hp - o).length() < best_t:
			var col: Object = hit["collider"]
			var kind: String = col.get_meta("kind", "")
			res = {"kind": kind, "point": hp, "body": col}
	return res


# ---------------- Etkileşim ----------------
func _on_use() -> void:
	var kind: String = target.get("kind", "")
	match kind:
		"taso":
			if hand.size() >= _cap():
				_say("Elin dolu (%d)! Vitrine yerleştir ya da Q / sağ tık ile bırak" % _cap())
				return
			_grab(target["idx"])
		"shelf":
			_use_shelf(target["body"], target["point"])


func _grab(first: int) -> void:
	var center := pile_xf[first].origin
	var limit := mini(_cap(), hand.size() + _grab_count())
	_take(first)
	if hand.size() < limit:
		var near: Array = []
		var r := ceili(GRAB_RADIUS / CELL)
		var c0 := _cell(center)
		for cx in range(c0.x - r, c0.x + r + 1):
			for cz in range(c0.y - r, c0.y + r + 1):
				var k := Vector2i(cx, cz)
				if not grid.has(k):
					continue
				for i in grid[k]:
					if pile_xf[i].origin.distance_to(center) <= GRAB_RADIUS:
						near.append(i)
		near.sort_custom(func(a, b): return pile_xf[a].origin.distance_to(center) < pile_xf[b].origin.distance_to(center))
		for i in near:
			if hand.size() >= limit:
				break
			_take(i)
	sel = hand.size() - 1
	_refresh_holo()
	_rebuild_hand()


func _is_correct(g: int, n: int) -> bool:
	var i: int = slots[g][n]
	return i != -1 and tasos[i]["grp"] == g and tasos[i]["num"] - 1 == n


func _use_shelf(body: Node, hp: Vector3) -> void:
	var g: int = body.get_meta("grp")
	var shelf: Node3D = shelves[g]
	var slot := _nearest_slot(shelf.to_local(hp))

	# Otomatik Dizme: vitrinin boş bir yerine (ya da çerçevesine) tıklayınca o setin tasoları doğru yerine gider
	if skills["oto"]["level"] > 0 and (slot == -1 or slots[g][slot] == -1):
		var keep: Array = []
		var cnt := 0
		for i in hand:
			var t: Dictionary = tasos[i]
			var n: int = t["num"] - 1
			if t["grp"] == g and slots[g][n] == -1:
				_place(i, g, n)
				cnt += 1
			else:
				keep.append(i)
		hand = keep
		if cnt > 0:
			sel = clampi(sel, 0, maxi(hand.size() - 1, 0))
			_rebuild_hand()
			return

	if slot == -1:
		return

	if slots[g][slot] == -1:
		# Boş yuva: seçili tasoyu koy (her taso her yuvaya konabilir)
		if hand.is_empty():
			_say("Elin boş")
			return
		var i: int = hand[sel]
		hand.remove_at(sel)
		_place(i, g, slot)
	else:
		# Dolu yuva: el boşsa geri al, doluysa seçiliyle yer değiştir
		if hand.is_empty():
			var old := _unplace(g, slot)
			hand.append(old)
			sel = 0
		else:
			var i: int = hand[sel]
			var old := _unplace(g, slot)
			hand[sel] = old
			_place(i, g, slot)
	sel = clampi(sel, 0, maxi(hand.size() - 1, 0))
	_rebuild_hand()


func _place(i: int, g: int, n: int) -> void:
	var t: Dictionary = tasos[i]
	slots[g][n] = i
	placed += 1
	var shelf: Node3D = shelves[g]
	var mi := g * NUMBERS_PER_SET + n
	shelf_mm.set_instance_transform(mi, shelf.global_transform * Transform3D(Basis(Vector3.RIGHT, PI / 2), _slot_local(n) + Vector3(0, 0, 0.009)))
	shelf_mm.set_instance_color(mi, _set_color(t["grp"]))
	shelf_mm.set_instance_custom_data(mi, _custom(i))
	if _is_correct(g, n):
		correct += 1
		_play(snd_holo if t["holo"] else snd_correct)
		if not paid[i]:
			paid[i] = true
			coins += COIN_HOLO if t["holo"] else COIN_PLACE
			if t["holo"]:
				_say("HOLO! +%d jeton" % COIN_HOLO)
	_check_shelf(g)
	_refresh_ring(g, n)


func _unplace(g: int, n: int) -> int:
	var i: int = slots[g][n]
	if _is_correct(g, n):
		correct -= 1
	slots[g][n] = -1
	placed -= 1
	shelf_mm.set_instance_transform(g * NUMBERS_PER_SET + n, hidden_xf)
	_check_shelf(g)
	_refresh_ring(g, n)
	return i


func _refresh_ring(g: int, n: int) -> void:
	var c := RING_EMPTY
	if shelf_done[g]:
		c = RING_DONE
	elif slots[g][n] != -1 and not _is_correct(g, n):
		c = RING_WRONG
	ring_mm.set_instance_color(g * NUMBERS_PER_SET + n, c)


## Vitrin tamamen doğru mu? Değiştiyse rengini ve halkalarını güncelle.
func _check_shelf(g: int) -> void:
	var done := true
	for n in NUMBERS_PER_SET:
		if not _is_correct(g, n):
			done = false
			break
	if done != shelf_done[g]:
		shelf_done[g] = done
		var bm: StandardMaterial3D = board_mats[g]
		bm.albedo_color = board_done_tint if done else board_tint
		var hm: StandardMaterial3D = header_mats[g]
		hm.emission_enabled = done
		for k in NUMBERS_PER_SET:
			_refresh_ring(g, k)
		if done:
			_play(snd_set, true)
			if not set_bonus_paid[g]:
				set_bonus_paid[g] = true
				coins += COIN_SET
				_say("%s vitrini tamam! +%d" % [SETS[g]["name"], COIN_SET])
			else:
				_say("%s vitrini yine tamam!" % SETS[g]["name"])
	_update_title(g)
	finished = not shelf_done.has(false)


## only_selected: Q yalnızca seçili tasoyu, sağ tık hepsini bırakır.
func _drop(only_selected: bool) -> void:
	if hand.is_empty():
		return
	var list: Array = [hand[sel]] if only_selected else hand.duplicate()
	var pt := player.global_position - player.global_transform.basis.z * 1.0
	pt.y = player.global_position.y - 0.95
	var kind: String = target.get("kind", "")
	if kind == "taso" or kind == "floor":
		pt = target["point"]
	var spread := 0.12 * sqrt(float(list.size()))
	for k in list.size():
		var i: int = list[k]
		var off := Vector3.ZERO if k == 0 else Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * spread
		var pos := pt + off
		pos.y = maxf(pt.y, 0.0) + BASE_Y + k * TASO_H * 0.5
		var b := Basis(Vector3.UP, randf() * TAU) * Basis(Vector3.RIGHT, randf_range(-0.25, 0.25))
		_put_in_pile(i, Transform3D(b, pos))
		hand.erase(i)
	sel = clampi(sel, 0, maxi(hand.size() - 1, 0))
	_refresh_holo()
	_rebuild_hand()


## Seçili taso önde ve büyük, diğerleri arkasında yelpaze gibi.
func _rebuild_hand() -> void:
	hand_mm.visible_instance_count = hand.size()
	var cnt := hand.size()
	for k in cnt:
		var i: int = hand[k]
		var rel := k - sel
		var xf: Transform3D
		if rel == 0:
			xf = Transform3D(Basis().scaled(Vector3.ONE * 1.25), Vector3(0, 0.06, 0.02))
		else:
			var a := absi(rel)
			var side := 1.0 if rel > 0 else -1.0
			var pos := Vector3(side * (0.05 + a * 0.022), -0.004 * a, -0.01 * a)
			if a > 8:
				pos = Vector3(side * 0.24, -0.04, -0.09)
			xf = Transform3D(Basis(Vector3.FORWARD, -side * 0.08 * a).scaled(Vector3.ONE * 0.85), pos)
		hand_mm.set_instance_transform(k, xf)
		hand_mm.set_instance_color(k, _taso_color(i))
		hand_mm.set_instance_custom_data(k, _custom(i))


func _try_buy(key: String) -> void:
	var sk: Dictionary = skills[key]
	var lvl: int = sk["level"]
	var costs: Array = sk["cost"]
	if lvl >= costs.size():
		_say("%s zaten en üst seviyede" % sk["name"])
		return
	var c: int = costs[lvl]
	if coins < c:
		_say("Yeterli jeton yok (%d gerekli)" % c)
		return
	coins -= c
	sk["level"] = lvl + 1
	_say("%s açıldı!" % sk["name"])


func _say(s: String) -> void:
	message = s
	message_time = 2.5


# ---------------- Ses ----------------
# Ses dosyası yok: kısa çan sesleri kodda sentezleniyor.
func _build_sounds() -> void:
	snd_correct = _make_chime([[1046.5, 0.0], [1568.0, 0.05]], 0.5)
	snd_holo = _make_chime([[1046.5, 0.0], [1318.5, 0.07], [1568.0, 0.14], [2093.0, 0.21]], 0.9)
	snd_set = _make_chime([[523.3, 0.0], [659.3, 0.13], [784.0, 0.26], [1046.5, 0.39], [1318.5, 0.39], [1568.0, 0.39]], 1.6)
	sfx = AudioStreamPlayer.new()
	sfx.max_polyphony = 8
	sfx.volume_db = -6.0
	add_child(sfx)


## notes: [[frekans, başlangıç sn], ...]; her nota hafif harmonikli, üstel sönümlü sinüs
func _make_chime(notes: Array, dur: float) -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * dur)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / rate
		var v := 0.0
		for nt in notes:
			var f: float = nt[0]
			var st: float = nt[1]
			if t < st:
				continue
			var lt := t - st
			var env := exp(-lt * 7.0) * minf(1.0, lt * 300.0)
			v += (sin(TAU * f * lt) + 0.3 * sin(TAU * f * 2.0 * lt)) * env
		v = clampf(v * 0.35, -1.0, 1.0)
		data.encode_s16(i * 2, int(v * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	return w


## Aynı karede birden fazla taso oturursa (Otomatik Dizme) tek ses çal
func _play(stream: AudioStreamWAV, force: bool = false) -> void:
	var f := Engine.get_process_frames()
	if f == last_sfx_frame and not force:
		return
	last_sfx_frame = f
	sfx.stream = stream
	sfx.pitch_scale = randf_range(0.97, 1.03)
	sfx.play()


# ---------------- HUD ----------------
func _mk_label(parent: Node, pos: Vector2, size: int, col: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	parent.add_child(l)
	return l


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var dot := ColorRect.new()
	dot.color = Color(1, 1, 1, 0.85)
	dot.size = Vector2(6, 6)
	dot.position = Vector2(797, 447)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(dot)
	hud_stats = _mk_label(layer, Vector2(20, 14), 22, Color("ffd36b"))
	hud_info = _mk_label(layer, Vector2(500, 470), 22, Color.WHITE)
	hud_info.size = Vector2(600, 30)
	hud_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_msg = _mk_label(layer, Vector2(300, 380), 24, Color(1, 0.95, 0.7))
	hud_msg.size = Vector2(1000, 34)
	hud_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_center = _mk_label(layer, Vector2(300, 250), 40, Color("ffd36b"))
	hud_center.size = Vector2(1000, 120)
	hud_center.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_hand = _mk_label(layer, Vector2(20, 50), 18, Color(1, 1, 1, 0.9))
	hud_skills = _mk_label(layer, Vector2(20, 760), 17, Color(1, 1, 1, 0.9))
	var help := _mk_label(layer, Vector2(1040, 14), 14, Color(1, 1, 1, 0.6))
	if touch_mode:
		hud_hand.position = Vector2(20, 200)
		help.text = "Sol taraf: yürü  •  Sağ taraf: sürükle bak, dokun al/koy\n< >: eldeki tasoyu seç  •  1-3: yetenek satın al"
		_build_touch_ui(layer)
	else:
		help.text = "WASD yürü  •  Shift koş  •  Boşluk zıpla  •  Fare bak\nSol tık: taso al / yuvaya koy / dolu yuvadan geri al veya değiştir\nTekerlek: eldeki tasoyu seç\nQ: seçiliyi bırak  •  Sağ tık: hepsini bırak\n1-3: yetenek satın al  •  R: yeniden  •  Esc: fareyi bırak"


func _taso_name(i: int) -> String:
	var t: Dictionary = tasos[i]
	return "%s %d%s" % [SETS[t["grp"]]["code"], t["num"], " HOLO" if t["holo"] else ""]


func _update_hud() -> void:
	var total := set_count * NUMBERS_PER_SET
	var s := int(elapsed)
	hud_stats.text = "Jeton: %d      Doğru: %d/%d      Vitrinde: %d      Yerde: %d      Süre: %02d:%02d" % [coins, correct, total, placed, pile_count, floori(s / 60.0), s % 60]

	if hand.is_empty():
		hud_hand.text = "Elde (0/%d)" % _cap()
	else:
		var parts: Array = []
		var from := maxi(0, sel - 5)
		var to := mini(hand.size(), from + 11)
		for k in range(from, to):
			var nm := _taso_name(hand[k])
			parts.append("[%s]" % nm if k == sel else nm)
		var more := "" if hand.size() <= to - from else "  …"
		hud_hand.text = "Elde (%d/%d)   Seçili: %s\n%s%s" % [hand.size(), _cap(), _taso_name(hand[sel]), "  ".join(parts), more]

	var kind: String = target.get("kind", "")
	match kind:
		"taso":
			var i: int = target["idx"]
			var g: int = tasos[i]["grp"]
			var set_txt: String = SETS[g]["name"]
			hud_info.text = "%s   (%s)" % [_taso_name(i), set_txt]
		"shelf":
			var body: Node = target["body"]
			var g: int = body.get_meta("grp")
			var shelf: Node3D = shelves[g]
			var n := _nearest_slot(shelf.to_local(target["point"]))
			var slot_txt := ""
			if n != -1:
				slot_txt = "   boş yuva" if slots[g][n] == -1 else "   " + _taso_name(slots[g][n])
			hud_info.text = "%s vitrini%s" % [SETS[g]["name"], slot_txt]
		_:
			hud_info.text = ""

	var lines: Array = ["YETENEKLER"]
	for k in SKILL_ORDER.size():
		var sk: Dictionary = skills[SKILL_ORDER[k]]
		var costs: Array = sk["cost"]
		var lvl: int = sk["level"]
		var lv_txt := "" if costs.size() == 1 else " Sv %d/%d" % [lvl, costs.size()]
		var price := "AÇIK" if lvl >= costs.size() else "%d jeton" % costs[lvl]
		lines.append("[%d] %s%s  –  %s  (%s)" % [k + 1, sk["name"], lv_txt, price, sk["desc"]])
	hud_skills.text = "\n".join(lines)

	hud_msg.text = message if message_time > 0.0 else ""
	if finished:
		hud_center.text = "TÜM VİTRİNLER TAMAM!\nSüre %02d:%02d  •  R ile yeniden başla" % [floori(s / 60.0), s % 60]
	elif not touch_mode and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		hud_center.text = "Oynamak için tıkla"
	else:
		hud_center.text = ""
