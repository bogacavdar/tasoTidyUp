extends Node3D
## Taso Kaosu — 3D birinci şahıs prototip.
## Dev bir depo, kaotik yığınlarda 5000 BENZERSİZ taso (34 set x 150 = 5100), duvarlarda 34 vitrin.
## Her taso her yuvaya konabilir; sırayı oyuncu kurar. Yanlış yerdekiler kırmızı,
## tamamen doğru dizilen vitrin yeşil olur.
## Sahne tamamen koddan kuruluyor; dışarıdan model yok.

# ---------------- Ayarlar ----------------
const NUMBERS_PER_SET := 150
const WALL_MARGIN := 1.6      # vitrinlerin önünde boş bırakılan şerit

const TASO_R := 0.08           # 16 cm: gerçeğe yakın ama yerden seçilebilir
const TASO_H := 0.01
const BASE_Y := 0.02
const REACH := 3.6
const GRAB_RADIUS := 0.4
const CELL := 1.0              # uzamsal ızgara hücre boyu

const ROOM_W := 70.0           # x
const ROOM_D := 50.0           # z
const BUILD_H := 8.6           # bina iç yüksekliği
const DOOR_W := 4.0
const DOOR_H := 2.8
const MEZZ_Y := 4.4            # asma kat zemin yüksekliği
const MEZZ_EDGE_Z := -10.0     # asma kat z=-25 ile bu değer arasında
const MEZZ_SHARE := 0.2        # tasoların asma kata saçılan oranı
const STAIR_X := 8.0           # iki kollu merdiven: x = -8 ve +8
const STAIR_W := 2.4           # merdiven genişliği
const STAIR_Z0 := -1.0         # merdivenin başladığı z (zemin kat)
const STAIR_STEPS := 24
const STAND_X := [-15.0, -5.0, 5.0, 15.0]
const STAND_Z := 8.0
const COLUMN_X := [-28.0, -20.0, -12.0, -4.0, 4.0, 12.0, 20.0, 28.0]

const SLOT_COLS := 10
const SLOT_ROWS := 15
const SLOT_GAP := 0.18
const BOARD_Y := 1.9           # vitrin panosunun orta yüksekliği (en alt sıra ~0.55 m, vitrin 2 m x 3,4 m)

const WALK_SPEED := 4.5
const SPRINT_MULT := 2.0
const JUMP_VELOCITY := 4.8
const GRAVITY := 12.0
const SAVE_PATH := "user://kayit.json"
const SETTINGS_PATH := "user://ayarlar.json"
const AUTOSAVE_SEC := 20.0

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
const RING_EMPTY := Color("d8b46a")   # boş yuva: pirinç halka (lacivert kadifede net görünür)
const RING_WRONG := Color("ff2a2a")
const RING_DONE := Color("3fe06a")
const BOARD_COLOR := Color("3a281b")  # koyu ahşap pano
const BOARD_DONE := Color("2f6b3a")

const AVUC_GRAB := [1, 3, 6, 12]
const KAPASITE := [10, 15, 25, 40, 60]
const HIZ := [1.0, 1.15, 1.3, 1.5]
const SEZGI_SURE := [0.0, 8.0, 14.0, 20.0]
const TOPLAMA_R := [0.0, 4.0, 7.0, 12.0]
const AYIKLAMA_R := [0.0, 4.0, 8.0]
const CD_SEZGI := 30.0
const CD_TOPLAMA := 40.0
const CD_AYIKLAMA := 60.0
const ABILITY_KEYS := {"sezgi": "Z", "toplama": "F", "ayiklama": "G", "cevir": "C"}
const CEVIR_R := [0.0, 5.0, 10.0]
const CD_CEVIR := 30.0

# Puan: doğru yere ilk kez oturan taso, tamamlanan tür (3 evrim) ve vitrin
const COIN_PLACE := 1
const COIN_SPECIES := 2
const COIN_SET := 25

# ---------------- Durum ----------------
var set_count := SETS.size()        # vitrin sayısı (34)
## Yerde olan setler: şimdilik yalnızca yeni çizimli Kor Vadisi. Diğer vitrinler boş bekler.
const ACTIVE_SETS := 1
var set_colors: Array[Color] = []
var tasos: Array = []                 # Dictionary: grp, num
var pile_xf: Array[Transform3D] = []  # yığındaki son konum
var in_pile: Array[bool] = []
var pile_count := 0
var grid := {}                        # Vector2i -> Array[int]
var slots: Array = []                 # slots[grp][n] = taso indeksi ya da -1
var hand: Array = []
var sel := 0                          # eldeki seçili taso
var skills := {}
var coins := 0                        # puan
var species_paid: Array[bool] = []
var cooldowns := {"sezgi": 0.0, "toplama": 0.0, "ayiklama": 0.0, "cevir": 0.0}
var sezgi_time := 0.0
var sezgi_grp := -1
var glow_mm: MultiMesh
var glow_mmi: MultiMeshInstance3D
var compass_ring: MeshInstance3D
var compass_beam: MeshInstance3D
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
var taso_mats: Array = []             # set başına malzeme (setin canlı atlası)
var pile_mms: Array = []              # set başına: yerdeki tasolar (örnek = numara - 1)
var shelf_mms: Array = []             # set başına: vitrine konmuş tasolar (örnek = numara - 1)
var hand_mms: Array = []              # set başına: eldeki tasolar
var hand_used: Array = []
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
var snd_set: AudioStreamWAV
var last_sfx_frame := -1

# Dokunmatik (telefon) kontrolleri
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
var touch_ability_btns := {}
var joy_knob: Panel

# Kayıt ve menü
static var skip_menu := false        # "Yeni Oyun" sonrası menüyü atlayıp doğrudan başla
var mouse_sens := 0.0025
var zooming := false                   # sağ tık / Zoom butonu basılıyken yakınlaştır
const ZOOM_FOV := 28.0
var touch_sens := 0.005
var volume := 0.8
var loading := false
var save_dirty := false
var save_timer := 0.0
var started := false
var menu_layer: CanvasLayer
var menu_main: Control
var menu_settings: Control
var menu_tree: Control
var tree_points: Label
var tree_buttons := {}
# Dükkân dönüşümü: düzen arttıkça ışık, renk, toz
var env: Environment
var hi_gfx := false                   # Forward+ (Windows): gerçek gölge, dolaylı ışık, sis
var adv_light := false                # dolaylı ışık + sis: ayarlardan açılır
var shelf_lights: Array = []
var sun: DirectionalLight3D
var lamps: Array = []
var order_vis := -1.0
var milestone := 0
var dust_mat: StandardMaterial3D
var dirt_mat: StandardMaterial3D
var dust_tex: NoiseTexture2D
var shelf_led_mats: Array = []
var shelf_dust_mats: Array = []
var confetti_mesh: QuadMesh
# Albüm
var menu_album: Control
var album_set := 0
var album_cells: Array = []
var album_title: Label
var album_count: Label
var album_tabs: Array = []
var idx_of_uid := PackedInt32Array()
# Ses
var music: AudioStreamPlayer
var foot: AudioStreamPlayer
var music_vol := 0.55
var sfx_vol := 1.0
var render_scale := 1.0
var snd_steps: Array = []
var snd_pick: AudioStreamWAV
var snd_drop: AudioStreamWAV
var snd_wrong: AudioStreamWAV
var snd_buy: AudioStreamWAV
var snd_magic: AudioStreamWAV
var step_accum := 1.2
var was_on_floor := true
# İlk açılış rehberi
var tut_step := -1
var tut_time := 0.0
var tut_flag := false
var tut_mark := 0
var tut_panel: PanelContainer
var tut_label: Label
var tut_skip_btn: Button
var menu_stats: Label
var btn_continue: Button
var btn_new: Button
var btn_save: Button
var new_confirm := false
var capture_grace := 0.0

var hud_stats: Label
var hud_info: Label
var hud_hand: Label
var hud_msg: Label
var hud_skills: Label
var hud_center: Label


func _ready() -> void:
	randomize()
	touch_mode = OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
	# Forward+ / Mobile motorlarında RenderingDevice var; Compatibility (web, telefon) motorunda yok
	hi_gfx = RenderingServer.get_rendering_device() != null or OS.get_environment("TASO_HI") == "1"
	_init_skills()
	_make_set_colors()
	_build_atlas()
	_make_taso_material()
	_make_env_materials()
	_load_settings()
	_build_world()
	_build_player()
	var data := _read_save()
	for k in set_count * (NUMBERS_PER_SET / 3):
		species_paid.append(false)
	_spawn_tasos(data)
	idx_of_uid.resize(set_count * NUMBERS_PER_SET)
	idx_of_uid.fill(-1)
	for i in tasos.size():
		idx_of_uid[_uid(tasos[i])] = i
	_build_pile()
	_build_hud()
	_build_sounds()
	_build_ability_visuals()
	_build_atmosphere()
	if not data.is_empty():
		_apply_save(data)
		_free_blocked_tasos()
		_say("Kaldığın yerden devam ediyorsun")
	else:
		tut_step = 0
	_tut_show()
	milestone = _milestone_for(float(correct) / maxf(tasos.size(), 1.0))
	_build_menu(not data.is_empty())
	if skip_menu:
		skip_menu = false
		_close_menu()
	else:
		_open_menu()


## Gelişim ağacı: dal 0 taşıma/hareket, 1 görüş, 2 büyüler. req: önce açılması gereken düğüm.
const TREE_ORDER := ["kapasite", "avuc", "hiz", "sezgi", "pusula", "rehber", "toplama", "oto", "ayiklama", "cevir"]


func _init_skills() -> void:
	skills = {
		"kapasite": {"name": "El Kapasitesi", "branch": 0, "req": "", "cost": [20, 60, 150, 350], "level": 0,
			"desc": "Elinde taşıyabildiğin taso: 10 → 15 / 25 / 40 / 60"},
		"avuc": {"name": "Avuç", "branch": 0, "req": "kapasite", "cost": [40, 120, 300], "level": 0,
			"desc": "Tek tıkla yakındaki 3 / 6 / 12 tasoyu al"},
		"hiz": {"name": "Hız", "branch": 0, "req": "", "cost": [30, 90, 220], "level": 0,
			"desc": "Yürüme ve koşma +%15 / +%30 / +%50"},
		"sezgi": {"name": "Sezgi [Z]", "branch": 1, "req": "", "cost": [25, 80, 200], "level": 0,
			"desc": "Seçili tasonun setini yerde parlatır: 8 / 14 / 20 sn (30 sn bekleme)"},
		"pusula": {"name": "Vitrin Pusulası", "branch": 1, "req": "sezgi", "cost": [60], "level": 0,
			"desc": "Seçili tasonun vitrinini ve doğru yuvasını gösterir"},
		"rehber": {"name": "Numara Rehberi", "branch": 1, "req": "sezgi", "cost": [70, 180], "level": 0,
			"desc": "Vitrine bakınca boş yuvalarda soluk numaralar: satır başları / bütün yuvalar"},
		"cevir": {"name": "Çevirme [C]", "branch": 2, "req": "toplama", "cost": [90, 220], "level": 0,
			"desc": "Çevrendeki 5 / 10 m içindeki ters tasoları düz çevirir (30 sn bekleme)"},
		"toplama": {"name": "Toplama [F]", "branch": 2, "req": "sezgi", "cost": [120, 250, 500], "level": 0,
			"desc": "Seçili tasonun setinden 4 / 7 / 12 m içindekileri önüne çeker (40 sn bekleme)"},
		"oto": {"name": "Otomatik Dizme", "branch": 2, "req": "pusula", "cost": [200], "level": 0,
			"desc": "Vitrine tıklayınca elindeki o setin tasoları doğru yuvalarına gider"},
		"ayiklama": {"name": "Ayıklama [G]", "branch": 2, "req": "toplama", "cost": [250, 600], "level": 0,
			"desc": "Çevrendeki 4 / 8 m içindeki tasoları setlerine göre yığınlara ayırır (60 sn)"},
	}


func _lvl(key: String) -> int:
	return int(skills[key]["level"])


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
	# her set için kendi canlı atlasıyla bir malzeme
	for g in set_count:
		var m: ShaderMaterial = taso_mat.duplicate()
		var path := "res://assets/art/set_%02d.jpg" % g
		if ResourceLoader.exists(path):
			m.set_shader_parameter("art", load(path))
			m.set_shader_parameter("has_art", true)
		taso_mats.append(m)


func _tex(id: String, kind: String) -> Texture2D:
	var path := "res://assets/tex/%s_%s.jpg" % [id, kind]
	if ResourceLoader.exists(path):
		return load(path)
	return null


## Poly Haven dokusu varsa gerçekçi PBR malzeme; yoksa düz renk (fallback)
func _pbr(id: String, fallback: Color, scale: float, tint: Color = Color.WHITE, rough: float = 0.75, use_rough_map: bool = true, specular: float = 0.5) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = fallback
	m.roughness = rough
	m.metallic_specular = specular
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
		var r := _tex(id, "rough") if use_rough_map else null
		if r != null:
			m.roughness_texture = r
			m.roughness = 1.0
	return m


func _make_env_materials() -> void:
	# parke: cilalı dokunun parlaklık haritası göz alıyordu; mat, düşük yansımalı
	mat_floor = _pbr("diagonal_parquet", Color("7a5a3c"), 0.5, Color(0.74, 0.69, 0.64), 0.88, false, 0.18)
	mat_wall = _pbr("beige_wall_001", Color("d9c9ae"), 0.3, Color(1.0, 0.97, 0.92))
	mat_ceiling = _pbr("beige_wall_001", Color("ece5d8"), 0.3, Color(1.0, 1.0, 1.0))
	mat_wood = _pbr("dark_wood", Color("5a3d28"), 0.9, Color.WHITE, 0.5)
	mat_wood_fine = _pbr("fine_grained_wood", Color("8a6240"), 1.2, Color.WHITE, 0.45)
	mat_sidewalk = _pbr("concrete_floor_02", Color("8d8d8d"), 0.4)
	mat_road = _pbr("asphalt_02", Color("3b3b3b"), 0.3)
	mat_marble = _pbr("marble_01", Color("e8e4dc"), 0.6, Color.WHITE, 0.2)
	mat_paint = _mat(Color("f1ece2"))
	var has_wood := mat_wood.albedo_texture != null
	# vitrin fonu kadife: lacivert; tamamlanınca koyu yeşil
	board_tint = Color(0.075, 0.095, 0.15)
	board_done_tint = Color(0.06, 0.17, 0.1)
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


## Her set için bir MultiMesh + kendi malzemesi; örnek indeksi = numara - 1
func _set_mms(parent: Node, count: int) -> Array:
	var out: Array = []
	for g in set_count:
		var mm := _new_mm(count)
		for k in count:
			mm.set_instance_transform(k, hidden_xf)
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = taso_mats[g]
		parent.add_child(mmi)
		out.append(mm)
	return out


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
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = _make_sky()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 0.95, 0.88)
	env.ambient_light_energy = 0.6
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05
	env.glow_enabled = not touch_mode
	env.glow_intensity = 0.3
	env.glow_bloom = 0.05
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.08
	env.adjustment_contrast = 1.05
	we.environment = env
	add_child(we)
	# alçak güneş: soldaki ve öndeki pencerelerden içeri ışık huzmeleri düşer
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-33, -62, 0)
	sun.light_energy = 0.55
	sun.light_color = Color(1.0, 0.93, 0.82)
	if hi_gfx:
		sun.shadow_enabled = true
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
		sun.directional_shadow_max_distance = 90.0
		sun.light_volumetric_fog_energy = 2.5
	add_child(sun)
	_apply_gfx()
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
		if hi_gfx:
			lamp.shadow_enabled = true
			lamp.light_volumetric_fog_energy = 0.4
			lamp.light_size = 0.15
		var bottom := _pendant_lamp(lamp.position + Vector3(0, 0.35, 0))
		lamp.position.y = bottom - 0.12
		add_child(lamp)
		lamps.append(lamp)

	# --- Zemin, dış kaldırım, tavan ---
	var floor_col := Color("7a5a3c")
	_box(self, Vector3(ROOM_W + 0.6, 0.2, ROOM_D + 0.6), Vector3(0, -0.1, 0), floor_col, "floor", mat_floor)
	_box(self, Vector3(ROOM_W + 30, 0.2, 24), Vector3(0, -0.12, hd + 12.3), Color("8d8d8d"), "floor", mat_sidewalk)
	_box(self, Vector3(ROOM_W + 30, 0.2, 14), Vector3(0, -0.13, hd + 31), Color("3b3b3b"), "floor", mat_road)
	_box(self, Vector3(ROOM_W + 0.6, 0.3, ROOM_D + 0.6), Vector3(0, BUILD_H + 0.15, 0), Color("e9e1d3"), "wall", mat_ceiling)

	# --- Duvarlar (ön duvarda kapı boşluğu) ---
	# pencere boşlukları: [merkez, genişlik, alt y, üst y]
	var front_holes := [[0.0, DOOR_W, 0.0, DOOR_H]]
	for x in [-10.0, 10.0]:
		front_holes.append([x, 6.0, 0.5, 2.7])
	for x in [-22.0, -8.0, 8.0, 22.0]:
		front_holes.append([x, 4.0, 5.6, 7.6])
	var side_holes := []
	for z in [-2.0, 8.0, 18.0]:
		side_holes.append([z, 4.0, 5.6, 7.6])
	var back_holes := []
	for x in [-26.0, -14.0, 14.0, 26.0]:
		back_holes.append([x, 5.0, 1.0, 3.0])
	_holed_wall("x", -hd - 0.15, -hw - 0.3, hw + 0.3, back_holes)
	_holed_wall("x", hd + 0.15, -hw - 0.3, hw + 0.3, front_holes)
	_holed_wall("z", -hw - 0.15, -hd, hd, side_holes)
	_holed_wall("z", hw + 0.15, -hd, hd, side_holes)
	_build_exterior()
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
	for side in [1.0]:
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
		_window(Vector3(x, 1.6, hd - 0.03), Vector2(6.0, 2.2), PI)
	for x in [-22.0, -8.0, 8.0, 22.0]:
		_window(Vector3(x, 6.6, hd - 0.03), Vector2(4.0, 2.0), PI)
	for z in [-2.0, 8.0, 18.0]:
		_window(Vector3(-hw + 0.03, 6.6, z), Vector2(4.0, 2.0), PI / 2)
		_window(Vector3(hw - 0.03, 6.6, z), Vector2(4.0, 2.0), -PI / 2)
	for x in [-26.0, -14.0, 14.0, 26.0]:
		_window(Vector3(x, 2.0, -hd + 0.03), Vector2(5.0, 2.0), 0.0)

	# --- Kasa ---
	var counter := _box(self, Vector3(3.2, 1.0, 1.0), Vector3(8.5, 0.5, hd - 5.5), Color("6b4a32"), "wall", mat_wood)
	counter.set_meta("kind", "wall")
	_mesh_box(self, Vector3(3.3, 0.06, 1.1), Vector3(8.5, 1.03, hd - 5.5), mat_marble)

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
	_build_interior_finish()
	_furnish()

	# --- Ortak çoklu çizimler: yuva halkaları, raf çıtaları, vitrindeki tasolar ---
	var total := set_count * NUMBERS_PER_SET
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = TASO_R + 0.002
	ring_mesh.outer_radius = TASO_R + 0.02
	ring_mesh.rings = 24
	ring_mesh.ring_segments = 6
	ring_mm = MultiMesh.new()
	ring_mm.transform_format = MultiMesh.TRANSFORM_3D
	ring_mm.use_colors = true
	ring_mm.mesh = ring_mesh
	ring_mm.instance_count = total
	var ring_mmi := MultiMeshInstance3D.new()
	ring_mmi.multimesh = ring_mm
	var ring_mat := StandardMaterial3D.new()
	ring_mat.vertex_color_use_as_albedo = true
	ring_mat.metallic = 0.75
	ring_mat.roughness = 0.32
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

	shelf_mms = _set_mms(self, NUMBERS_PER_SET)

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


## Delikli duvar: dikey bir duvarı pencere/kapı boşlukları dışında kutulara böler.
## along: duvarın uzandığı eksen ("x"/"z"), fixed: diğer eksendeki konumu, a0..a1: uzunluğu,
## holes: [[merkez, genişlik, alt y, üst y], ...]
func _holed_wall(along: String, fixed: float, a0: float, a1: float, holes: Array) -> void:
	var cuts := [a0, a1]
	for h in holes:
		cuts.append(float(h[0]) - float(h[1]) / 2.0)
		cuts.append(float(h[0]) + float(h[1]) / 2.0)
	cuts.sort()
	for k in cuts.size() - 1:
		var s0: float = cuts[k]
		var s1: float = cuts[k + 1]
		if s1 - s0 < 0.001:
			continue
		var mid := (s0 + s1) / 2.0
		var gaps: Array = []
		for h in holes:
			if absf(mid - float(h[0])) < float(h[1]) / 2.0:
				gaps.append([float(h[2]), float(h[3])])
		gaps.sort_custom(func(a, b): return a[0] < b[0])
		var y := 0.0
		var segs: Array = []
		for gp in gaps:
			if gp[0] > y:
				segs.append([y, gp[0]])
			y = maxf(y, gp[1])
		if y < BUILD_H:
			segs.append([y, BUILD_H])
		for sg in segs:
			var hgt: float = sg[1] - sg[0]
			var cy: float = (sg[0] + sg[1]) / 2.0
			var size := Vector3(s1 - s0, hgt, 0.3) if along == "x" else Vector3(0.3, hgt, s1 - s0)
			var pos := Vector3(mid, cy, fixed) if along == "x" else Vector3(fixed, cy, mid)
			_box(self, size, pos, Color("d9c9ae"), "wall", mat_wall)


## Dış dünya: zemin ve karşıdaki binalar (pencerelerden görünür), gökyüzü HDRI'dan
func _build_exterior() -> void:
	var hd := ROOM_D / 2.0
	var hw := ROOM_W / 2.0
	_box(self, Vector3(300, 0.2, 300), Vector3(0, -0.17, 0), Color("7d7d78"), "floor", mat_sidewalk)
	var bm: StandardMaterial3D = mat_wall.duplicate()
	bm.albedo_color = Color(0.8, 0.72, 0.64)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.12, 0.14, 0.17)
	dark.roughness = 0.15
	dark.metallic = 0.4
	var blocks := [
		[Vector3(-32, 9, hd + 52), Vector3(44, 18, 12)], [Vector3(24, 12, hd + 55), Vector3(32, 24, 12)],
		[Vector3(-hw - 26, 7, -4), Vector3(14, 14, 56)], [Vector3(hw + 28, 10, 2), Vector3(14, 20, 62)],
		[Vector3(0, 8, -hd - 30), Vector3(90, 16, 14)],
	]
	for b in blocks:
		var c: Vector3 = b[0]
		var sz: Vector3 = b[1]
		_mesh_box(self, sz, c, bm)
		# dükkâna bakan cephede pencere sıraları
		var to_shop := Vector3(-c.x, 0, -c.z).normalized()
		var along_x := absf(to_shop.z) > absf(to_shop.x)
		var face_len := sz.x if along_x else sz.z
		var cols := int(face_len / 4.0)
		var rows := int(sz.y / 3.5)
		for r in rows:
			for k in cols:
				var off := -face_len / 2.0 + (k + 0.5) * face_len / cols
				var wy := c.y - sz.y / 2.0 + 2.0 + r * 3.5
				var wpos: Vector3
				var wsize: Vector3
				if along_x:
					wpos = Vector3(c.x + off, wy, c.z + signf(to_shop.z) * (sz.z / 2.0 + 0.02))
					wsize = Vector3(1.6, 1.8, 0.05)
				else:
					wpos = Vector3(c.x + signf(to_shop.x) * (sz.x / 2.0 + 0.02), wy, c.z + off)
					wsize = Vector3(0.05, 1.8, 1.6)
				_mesh_box(self, wsize, wpos, dark)


func _make_sky() -> Sky:
	var sky := Sky.new()
	var path := "res://assets/hdri/kloofendal_48d_partly_cloudy_puresky.hdr"
	if ResourceLoader.exists(path):
		var pm := PanoramaSkyMaterial.new()
		pm.panorama = load(path)
		sky.sky_material = pm
	else:
		var ps := ProceduralSkyMaterial.new()
		ps.sky_top_color = Color("4f86c9")
		ps.sky_horizon_color = Color("cfe3f2")
		ps.ground_horizon_color = Color("b9c4c9")
		ps.ground_bottom_color = Color("6b6f6a")
		sky.sky_material = ps
	sky.radiance_size = Sky.RADIANCE_SIZE_128
	return sky


## Forward+ (Windows): dolaylı ışık (SDFGI), ortam gölgesi, ışık huzmeli sis
func _apply_gfx() -> void:
	if not hi_gfx or env == null:
		return
	env.sdfgi_enabled = adv_light
	env.sdfgi_use_occlusion = true
	env.sdfgi_min_cell_size = 0.2
	env.sdfgi_cascades = 4
	env.sdfgi_bounce_feedback = 0.45
	env.sdfgi_energy = 1.2
	env.ssao_enabled = true
	env.ssao_radius = 1.0
	env.ssao_intensity = 1.0
	env.ssil_enabled = adv_light
	env.volumetric_fog_enabled = adv_light
	env.volumetric_fog_density = 0.006
	env.volumetric_fog_albedo = Color(1.0, 0.96, 0.9)
	env.volumetric_fog_anisotropy = 0.55
	env.volumetric_fog_length = 48.0
	env.volumetric_fog_gi_inject = 0.4
	env.glow_enabled = true
	order_applied = -1.0


func _window(center: Vector3, size: Vector2, rot: float) -> void:
	var node := Node3D.new()
	node.position = center
	node.rotation.y = rot
	add_child(node)
	# cam duvarın içinde, boşluğun ortasında; dışarısı (gökyüzü, binalar) görünür
	var pane := _mesh_box(node, Vector3(size.x, size.y, 0.02), Vector3(0, 0, -0.15), glass_mat)
	pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
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
func _pendant_lamp(pos: Vector3) -> float:
	var top := BUILD_H if pos.y > MEZZ_Y + 1.0 else MEZZ_Y - 0.3
	var lp := _prop("hanging_industrial_lamp", Vector3(pos.x, top, pos.z), 0.0, "ceiling", false, 1.0 if top > MEZZ_Y else 0.55)
	if lp != null:
		_no_shadows(lp)
		return top - last_prop_size.y
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
	return pos.y - 0.25


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

	var board_m := StandardMaterial3D.new()
	board_m.albedo_color = board_tint
	board_m.roughness = 1.0
	board_m.rim_enabled = true
	board_m.rim = 0.55
	board_m.rim_tint = 0.75
	board_m.normal_enabled = true
	board_m.normal_texture = _fabric_normal()
	board_m.normal_scale = 0.6
	board_m.uv1_scale = Vector3(4, 6, 1)
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
	# başlık: koyu ahşap kuşak, ortasında pirinç isim plakası, altında setin renginde ince şerit
	var header := _box(shelf, Vector3(w + 0.16, 0.26, 0.12), Vector3(0, top_y + 0.23, 0.02), wood, "shelf", mat_wood)
	header.set_meta("grp", g)
	var hm := StandardMaterial3D.new()
	hm.albedo_color = Color("c9a25a")
	hm.metallic = 0.85
	hm.roughness = 0.3
	hm.emission = Color("ffcf70")
	hm.emission_energy_multiplier = 0.5
	_mesh_box(shelf, Vector3(w * 0.86, 0.18, 0.012), Vector3(0, top_y + 0.24, 0.085), hm)
	header_mats.append(hm)
	_mesh_box(shelf, Vector3(w + 0.16, 0.03, 0.125), Vector3(0, top_y + 0.115, 0.022), _mat(col))
	var lm: StandardMaterial3D = led_mat.duplicate()
	shelf_led_mats.append(lm)
	if hi_gfx:
		var spot := SpotLight3D.new()
		spot.position = Vector3(0, top_y - 0.08, depth - 0.1)
		spot.rotation_degrees = Vector3(-75, 0, 0)
		spot.spot_range = h + 0.8
		spot.spot_angle = 52.0
		spot.light_color = Color(1.0, 0.94, 0.82)
		spot.light_specular = 0.25
		spot.light_energy = 0.1
		shelf.add_child(spot)
		shelf_lights.append(spot)
	else:
		shelf_lights.append(null)
	_mesh_box(shelf, Vector3(w, 0.025, 0.03), Vector3(0, top_y - 0.03, depth - 0.12), lm)
	_mesh_box(shelf, Vector3(w, h, 0.012), Vector3(0, BOARD_Y, depth - 0.06), glass_mat)
	# camın üstündeki toz: vitrin doğru doldukça silinir
	var dm := StandardMaterial3D.new()
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.roughness = 1.0
	dm.albedo_texture = _dust_texture()
	dm.albedo_color = Color(0.78, 0.72, 0.62, 0.3)
	dm.uv1_offset = Vector3(randf(), randf(), 0)
	dm.uv1_scale = Vector3(1.2, 1.6, 1)
	shelf_dust_mats.append(dm)
	_mesh_box(shelf, Vector3(w, h, 0.004), Vector3(0, BOARD_Y, depth - 0.045), dm)

	var title := Label3D.new()
	title.font_size = 64
	title.pixel_size = 0.0021
	title.outline_size = 0
	title.modulate = Color(0.16, 0.1, 0.05)
	title.position = Vector3(0, top_y + 0.24, 0.093)
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
	hand_mms = _set_mms(hand_root, KAPASITE[KAPASITE.size() - 1])
	for g in set_count:
		hand_used.append(0)
	add_child(player)


# ---------------- Tasolar ----------------
func _spawn_tasos(data: Dictionary) -> void:
	if data.has("tasos"):
		var list: Array = data["tasos"]
		for i in list.size():
			var e: Array = list[i]
			tasos.append({"grp": int(e[0]), "num": int(e[1])})
			paid.append(int(e[3]) == 1)
			var ip: bool = int(e[4]) == 1
			in_pile.append(ip)
			var q := Quaternion(float(e[8]), float(e[9]), float(e[10]), float(e[11])).normalized()
			var o := Vector3(float(e[5]), float(e[6]), float(e[7]))
			if int(data.get("v", 1)) < 2:
				# 1. sürüm kaydı: asma kat 5.4 m'deydi, şimdi MEZZ_Y
				o.y = (MEZZ_Y if o.y > 2.0 else 0.0) + BASE_Y + fmod(o.y, 0.05)
			pile_xf.append(Transform3D(Basis(q), o))
			if ip:
				_grid_add(i)
				pile_count += 1
		return
	var pairs: Array = []
	for g in ACTIVE_SETS:
		for n in NUMBERS_PER_SET:
			pairs.append(Vector2i(g, n + 1))
	pairs.shuffle()
	for i in pairs.size():
		var p: Vector2i = pairs[i]
		tasos.append({"grp": p.x, "num": p.y})
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
			var mp := Vector3(randf_range(-hw, hw), MEZZ_Y + BASE_Y + jitter, randf_range(-hd, MEZZ_EDGE_Z - 0.6))
			if _props_hit(mp):
				continue
			return mp
		var p := Vector3(randf_range(-hw, hw), BASE_Y + jitter, randf_range(-hd, hd))
		if _floor_blocked(p):
			continue
		return p
	return Vector3(randf_range(-10, 10), BASE_Y, 15.0)


## Zemin katta taso saçılmayacak yerler: merdiven, standlar, kolonlar, kapı önü, kasa
func _props_hit(p: Vector3) -> bool:
	for e in props_blocked:
		var r: Rect2 = e[0]
		if absf(p.y - float(e[1])) < 1.0 and r.has_point(Vector2(p.x, p.z)):
			return true
	return false


## Eski kayıtta yeni eşyaların içine düşen tasoları boş bir yere taşı
func _free_blocked_tasos() -> void:
	for i in tasos.size():
		if in_pile[i] and _props_hit(pile_xf[i].origin):
			_move_pile(i, Transform3D(Basis(Vector3.UP, randf() * TAU), _random_floor_pos()))


func _floor_blocked(p: Vector3) -> bool:
	if _props_hit(p):
		return true
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
	pile_mms = _set_mms(self, NUMBERS_PER_SET)
	for i in tasos.size():
		var t: Dictionary = tasos[i]
		var mm: MultiMesh = pile_mms[t["grp"]]
		var k: int = t["num"] - 1
		mm.set_instance_transform(k, pile_xf[i] if in_pile[i] else hidden_xf)
		mm.set_instance_custom_data(k, _custom(i))
		mm.set_instance_color(k, _taso_color(i))
		var smm: MultiMesh = shelf_mms[t["grp"]]
		smm.set_instance_custom_data(k, _custom(i))
		smm.set_instance_color(k, _taso_color(i))



func _custom(i: int) -> Color:
	var t: Dictionary = tasos[i]
	var art: Array = SET_ART[int(t["grp"]) % SET_ART.size()]
	var theme: float = float(art[2]) + float(art[1])
	return Color(float(_uid(t)), 0.0, float(art[0]), theme)


func _taso_color(i: int) -> Color:
	return _set_color(tasos[i]["grp"])


func _pile_xf(i: int, xf: Transform3D) -> void:
	var t: Dictionary = tasos[i]
	var mm: MultiMesh = pile_mms[t["grp"]]
	mm.set_instance_transform(int(t["num"]) - 1, xf)


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
	save_dirty = true
	_grid_remove(i)
	in_pile[i] = false
	pile_count -= 1
	_pile_xf(i, hidden_xf)
	hand.append(i)


func _put_in_pile(i: int, xf: Transform3D) -> void:
	save_dirty = true
	pile_xf[i] = xf
	in_pile[i] = true
	pile_count += 1
	_pile_xf(i, xf)
	_grid_add(i)


func _throw(i: int, k: int, n: int, fwd: Vector3, cb: Basis) -> void:
	if taso_phys == null:
		taso_phys = PhysicsMaterial.new()
		taso_phys.bounce = 0.35
		taso_phys.friction = 0.75
	var body := _new_taso_body()
	# elden çıkış: tasonun yüzü kameraya dönük, birden fazlaysa hafif dağınık
	var right := cb.x
	var start := cam.global_position + fwd * 0.45 + right * 0.18 - cb.y * 0.18
	start += right * randf_range(-0.08, 0.08) * minf(n, 6) + cb.y * randf_range(-0.04, 0.04) * minf(n, 6)
	var b := cb * Basis(Vector3.RIGHT, PI / 2)
	body.global_transform = Transform3D(b, start)
	var spd := randf_range(2.6, 4.2) if n == 1 else randf_range(2.0, 4.0)
	body.linear_velocity = fwd * spd + Vector3.UP * randf_range(0.8, 1.8) + right * randf_range(-0.6, 0.6) + player.velocity * 0.5
	# takla (ters düşme şansı) + kendi ekseninde dönüş
	body.angular_velocity = right * randf_range(-16.0, 16.0) + body.global_transform.basis.y * randf_range(-8.0, 8.0) + fwd * randf_range(-4.0, 4.0)
	flying.append({"i": i, "body": body, "t": 0.0, "slow": 0.0})
	_pile_xf(i, body.global_transform)


func _update_flying(delta: float) -> void:
	wake_timer -= delta
	if wake_timer <= 0.0:
		wake_timer = 0.05
		_wake_near_flying()
	for k in range(flying.size() - 1, -1, -1):
		var e: Dictionary = flying[k]
		var body: RigidBody3D = e["body"]
		var i: int = e["i"]
		e["t"] = float(e["t"]) + delta
		var xf := body.global_transform
		_pile_xf(i, xf)
		var quiet: bool = e.get("quiet", false)
		var lv := 0.2 if quiet else 0.05
		var av := 5.0 if quiet else 0.4
		if body.linear_velocity.length() < lv and body.angular_velocity.length() < av:
			e["slow"] = float(e["slow"]) + delta
		else:
			e["slow"] = 0.0
		var limit := 2.5 if quiet else 6.0
		if body.sleeping or float(e["slow"]) > 0.35 or float(e["t"]) > limit or xf.origin.y < -3.0:
			_land(k)


## Hareket eden tasoların yakınındaki yerdeki tasolar da fizik cismi olur: çarpışır, itilir, üst üste yığılır
func _wake_near_flying() -> void:
	var movers: Array = []
	for e in flying:
		var b: RigidBody3D = e["body"]
		if b.linear_velocity.length() > (1.2 if e.get("quiet", false) else 0.4):
			movers.append(b.global_position)
	for pos in movers:
		if flying.size() >= MAX_ACTIVE:
			return
		var c0 := _cell(pos)
		for dx in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				var key := c0 + Vector2i(dx, dz)
				if not grid.has(key):
					continue
				for i in (grid[key] as Array).duplicate():
					var o := pile_xf[i].origin
					if float(rest_until.get(i, 0.0)) > anim:
						continue
					if absf(o.y - pos.y) < 0.6 and Vector2(o.x - pos.x, o.z - pos.z).length() < 0.55:
						_activate(i)
						if flying.size() >= MAX_ACTIVE:
							return


func _new_taso_body() -> RigidBody3D:
	if taso_phys == null:
		taso_phys = PhysicsMaterial.new()
		taso_phys.bounce = 0.35
		taso_phys.friction = 0.75
	var body := RigidBody3D.new()
	body.mass = 0.02
	body.collision_layer = FLY_LAYER
	body.collision_mask = 1 | FLY_LAYER
	body.continuous_cd = true
	body.physics_material_override = taso_phys
	body.angular_damp = 0.4
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = TASO_R
	sh.height = maxf(TASO_H, 0.012)
	cs.shape = sh
	body.add_child(cs)
	add_child(body)
	return body


## Yerdeki bir tasoyu duran bir fizik cismine çevir (çarpılınca hareket eder, durunca yere geri döner)
func _activate(i: int) -> void:
	if not in_pile[i]:
		return
	_grid_remove(i)
	in_pile[i] = false
	pile_count -= 1
	var body := _new_taso_body()
	var xf := pile_xf[i].orthonormalized()
	# çarpışma şekli zeminin içinde başlamasın
	var q := PhysicsRayQueryParameters3D.create(xf.origin + Vector3.UP * 0.05, xf.origin + Vector3.DOWN * 0.3)
	q.collision_mask = 1
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		xf.origin.y = maxf(xf.origin.y, hit["position"].y + 0.0065)
	xf.origin.y += 0.002
	body.global_transform = xf
	flying.append({"i": i, "body": body, "t": 0.0, "slow": 0.0, "quiet": true})


func _land(k: int) -> void:
	var e: Dictionary = flying[k]
	var body: RigidBody3D = e["body"]
	var i: int = e["i"]
	rest_until[i] = anim + 2.0
	var xf := body.global_transform.orthonormalized()
	if xf.origin.y < -3.0:
		xf = Transform3D(Basis(Vector3.UP, randf() * TAU), _random_floor_pos())
	else:
		# zemine gömülmesin: altındaki yüzeye otur
		var q := PhysicsRayQueryParameters3D.create(xf.origin + Vector3.UP * 0.4, xf.origin + Vector3.DOWN * 0.6)
		q.collision_mask = 1
		q.exclude = [body.get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		if not hit.is_empty():
			var top: float = hit["position"].y + TASO_H * 0.5 + 0.002
			if xf.origin.y < top:
				xf.origin.y = top
	flying.remove_at(k)
	body.queue_free()
	_put_in_pile(i, xf)
	if float(e["t"]) < 6.0 and not e.get("quiet", false):
		_play(snd_drop)


## Kayıt ya da büyü öncesi: havadaki bütün tasoları olduğu yerde indir
func _land_all() -> void:
	for k in range(flying.size() - 1, -1, -1):
		_land(k)


func _grab_count() -> int:
	return AVUC_GRAB[_lvl("avuc")]


func _cap() -> int:
	return KAPASITE[_lvl("kapasite")]


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
	d *= HIZ[_lvl("hiz")]
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
	_footsteps(delta)
	if not flying.is_empty():
		_update_flying(delta)
	if player.global_position.y < -5.0:
		player.global_position = Vector3(0, 1.0, ROOM_D / 2.0 - 3.0)
	var fov_target := 82.0 if (sprint and mv != Vector2.ZERO) else 75.0
	if zooming:
		fov_target = ZOOM_FOV
	cam.fov = lerpf(cam.fov, fov_target, 12.0 * delta)
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
	if save_dirty:
		save_timer += delta
		if save_timer >= AUTOSAVE_SEC:
			_write_save()
	# tarayıcıda Esc fare kilidini kendisi kaldırır: o zaman menüyü aç
	if capture_grace > 0.0:
		capture_grace -= delta
	elif started and not touch_mode and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_open_menu()
	anim += delta
	if not finished:
		elapsed += delta
	if message_time > 0.0:
		message_time -= delta
	for key in cooldowns:
		cooldowns[key] = maxf(float(cooldowns[key]) - delta, 0.0)
	if sezgi_time > 0.0:
		sezgi_time -= delta
		if sezgi_time <= 0.0 or fmod(anim, 0.5) < delta:
			_refresh_glow()
	_update_compass()
	_update_place_anims(delta)
	_update_drag()
	_update_guide(delta)
	_update_order(delta)
	for f in fans:
		(f as Node3D).rotate_y(delta * 2.2)
	_tut_update(delta)
	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		_touch_input(event)
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# yakınlaşınca bakış da o oranda yavaşlar
		var sens := mouse_sens * cam.fov / 75.0
		player.rotate_y(-event.relative.x * sens)
		cam.rotation.x = clampf(cam.rotation.x - event.relative.y * sens, -1.5, 1.5)
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		zooming = event.pressed and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_on_release()
		return
	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			return
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_on_press()
			MOUSE_BUTTON_WHEEL_UP:
				_cycle(-1)
			MOUSE_BUTTON_WHEEL_DOWN:
				_cycle(1)
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				_open_menu()
			KEY_Q:
				_drop(not event.shift_pressed)
			KEY_TAB:
				_open_tree()
			KEY_Z:
				_use_ability("sezgi")
			KEY_F:
				_use_ability("toplama")
			KEY_G:
				_use_ability("ayiklama")
			KEY_C:
				_use_ability("cevir")
			KEY_B:
				_open_album()
			KEY_H:
				if tut_step >= 0:
					_tut_skip()


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
			player.rotate_y(-e.relative.x * touch_sens)
			cam.rotation.x = clampf(cam.rotation.x - e.relative.y * touch_sens, -1.5, 1.5)


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
	var zb := _touch_button(layer, "Zoom", Vector2(1100, 620), Vector2(140, 110))
	zb.button_down.connect(func(): zooming = true)
	zb.button_up.connect(func(): zooming = false)
	_touch_button(layer, "Menü", Vector2(1440, 20), Vector2(140, 70)).pressed.connect(func(): _open_menu())
	_touch_button(layer, "<", Vector2(20, 110), Vector2(90, 80)).pressed.connect(func(): _cycle(-1))
	_touch_button(layer, ">", Vector2(120, 110), Vector2(90, 80)).pressed.connect(func(): _cycle(1))
	_touch_button(layer, "Ağaç", Vector2(1290, 20), Vector2(140, 70)).pressed.connect(func(): _open_tree())
	var keys := ["sezgi", "toplama", "ayiklama", "cevir"]
	var labels := ["Sezgi", "Topla", "Ayıkla", "Çevir"]
	for k in keys.size():
		var key: String = keys[k]
		var b := _touch_button(layer, labels[k], Vector2(1100 + k * 120, 470), Vector2(110, 75))
		b.pressed.connect(func(): _use_ability(key))
		touch_ability_btns[key] = b


func _cycle(dir: int) -> void:
	if hand.is_empty():
		return
	sel = posmod(sel + dir, hand.size())
	if tut_step == 1:
		tut_flag = true
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
	q.collision_mask = 0xFFFFFFFF & ~FLY_LAYER
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
## Sol tuşa basıldı: vitrindeki dolu bir yuvaysa bırakılana kadar bekle (tık mı, sürükleme mi?)
func _on_press() -> void:
	press_info = {}
	dragging = false
	if target.get("kind", "") == "shelf":
		var body: Node = target["body"]
		var g: int = body.get_meta("grp")
		var shelf: Node3D = shelves[g]
		var n := _nearest_slot(shelf.to_local(target["point"]))
		if n != -1 and slots[g][n] != -1:
			press_info = {"g": g, "n": n, "i": slots[g][n], "body": body, "point": target["point"]}
			return
	_on_use()


## Sürüklerken: imlecin gösterdiği yuva (yoksa -1)
func _drag_slot() -> Vector2i:
	if target.get("kind", "") != "shelf":
		return Vector2i(-1, -1)
	var body: Node = target["body"]
	var g: int = body.get_meta("grp")
	var shelf: Node3D = shelves[g]
	var n := _nearest_slot(shelf.to_local(target["point"]))
	return Vector2i(g, n) if n != -1 else Vector2i(-1, -1)


func _update_drag() -> void:
	if press_info.is_empty():
		return
	var g: int = press_info["g"]
	var n: int = press_info["n"]
	var i: int = press_info["i"]
	if slots[g][n] != i:
		press_info = {}
		dragging = false
		return
	var ds := _drag_slot()
	if not dragging and ds != Vector2i(g, n):
		dragging = true
		_cancel_anim(i)
	if dragging:
		# taso imleci izler, yuvasından hafif kalkmış
		var t: Dictionary = tasos[i]
		var smm: MultiMesh = shelf_mms[t["grp"]]
		var base := _slot_xf(g, n)
		var d := (base.origin - cam.global_position).length()
		var pos := cam.global_position - cam.global_transform.basis.z * maxf(d - 0.08, 0.3)
		smm.set_instance_transform(int(t["num"]) - 1, Transform3D(base.basis, pos))


func _on_release() -> void:
	if press_info.is_empty():
		return
	var g: int = press_info["g"]
	var n: int = press_info["n"]
	var i: int = press_info["i"]
	var was_drag := dragging
	var body: Node = press_info["body"]
	var point: Vector3 = press_info["point"]
	press_info = {}
	dragging = false
	if slots[g][n] != i:
		return
	if not was_drag:
		# sürüklemeden bırakıldı: eski davranış, taso ele gelir
		_use_shelf(body, point)
		return
	var t: Dictionary = tasos[i]
	var smm: MultiMesh = shelf_mms[t["grp"]]
	var cur: Transform3D = smm.get_instance_transform(int(t["num"]) - 1)
	var ds := _drag_slot()
	if ds.x == -1:
		# vitrin dışına bırakıldı: ele al (yer varsa)
		if hand.size() < _cap():
			_unplace(g, n)
			hand.append(i)
			sel = hand.size() - 1
			_play(snd_pick)
			_rebuild_hand()
		else:
			_say("Elin dolu (%d)" % _cap())
			_unplace(g, n)
			_place(i, g, n, cur, 0.0, false)
		return
	var g2 := ds.x
	var m := ds.y
	if g2 == g and m == n:
		_unplace(g, n)
		_place(i, g, n, cur, 0.0, false)
		return
	var other: int = slots[g2][m]
	_unplace(g, n)
	if other != -1:
		var oxf := _slot_xf(g2, m)
		_unplace(g2, m)
		_place(i, g2, m, cur)
		_place(other, g, n, oxf, 0.0, false)
	else:
		_place(i, g2, m, cur)


func _on_use() -> void:
	var kind: String = target.get("kind", "")
	match kind:
		"taso":
			if hand.size() >= _cap():
				_say("Elin dolu (%d)! Vitrine yerleştir ya da Q / Shift+Q ile fırlat" % _cap())
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
	_play(snd_pick)
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
				_place(i, g, n, null, cnt * 0.04)
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
		# Dolu yuva: bir yuvada tek taso olur; tıklayınca oradaki taso ele gelir
		if hand.size() >= _cap():
			_say("Elin dolu (%d)! Önce bir tasoyu yerleştir ya da bırak" % _cap())
			return
		var old := _unplace(g, slot)
		hand.append(old)
		sel = hand.size() - 1
		_play(snd_pick)
	sel = clampi(sel, 0, maxi(hand.size() - 1, 0))
	_rebuild_hand()


func _slot_xf(g: int, n: int) -> Transform3D:
	var shelf: Node3D = shelves[g]
	return shelf.global_transform * Transform3D(Basis(Vector3.RIGHT, PI / 2), _slot_local(n) + Vector3(0, 0, 0.009))


## Elindeki seçili tasonun dünyadaki yeri (yerleştirme animasyonunun başlangıcı)
func _hand_xf() -> Transform3D:
	return hand_root.global_transform * Transform3D(Basis().scaled(Vector3.ONE * 1.25), Vector3(0, 0.06, 0.02))


## from: animasyonun başladığı yer (yoksa elden). streak_ok: seri sayacını etkilesin mi
func _place(i: int, g: int, n: int, from: Variant = null, delay: float = 0.0, streak_ok: bool = true) -> void:
	var t: Dictionary = tasos[i]
	slots[g][n] = i
	placed += 1
	save_dirty = true
	var smm: MultiMesh = shelf_mms[t["grp"]]
	var to := _slot_xf(g, n)
	var ok := _is_correct(g, n)
	if loading:
		smm.set_instance_transform(int(t["num"]) - 1, to)
	else:
		var fx: Transform3D = from if from != null else _hand_xf()
		smm.set_instance_transform(int(t["num"]) - 1, fx)
		place_anims.append({"i": i, "from": fx, "to": to, "t": -delay, "ok": ok})
	if ok:
		correct += 1
		if not paid[i] and not loading:
			paid[i] = true
			if streak_ok:
				streak += 1
				if streak == 5 or streak == 10:
					_say("Seri %d! Puanlar artık x%d" % [streak, _streak_mult()])
			coins += COIN_PLACE * _streak_mult()
		# tür bonusu: aynı türün 3 evrimi de doğru yerdeyse
		var sp := floori((int(t["num"]) - 1) / 3.0)
		var sk_i := g * (NUMBERS_PER_SET / 3) + sp
		if not loading and not species_paid[sk_i]:
			var all3 := true
			for e in 3:
				if not _is_correct(g, sp * 3 + e):
					all3 = false
			if all3:
				species_paid[sk_i] = true
				coins += COIN_SPECIES
				_say("Tür tamam: 3 evrim yan yana! +%d puan" % COIN_SPECIES)
	elif not loading and streak_ok:
		if streak >= 5:
			_say("Seri bozuldu (%d)" % streak)
		streak = 0
	_check_shelf(g)
	_refresh_ring(g, n)


func _streak_mult() -> int:
	return 1 + mini(floori(streak / 5.0), 2)


func _update_place_anims(delta: float) -> void:
	for k in range(place_anims.size() - 1, -1, -1):
		var a: Dictionary = place_anims[k]
		a["t"] = float(a["t"]) + delta / 0.24
		var i: int = a["i"]
		var t: Dictionary = tasos[i]
		var smm: MultiMesh = shelf_mms[t["grp"]]
		var u := clampf(float(a["t"]), 0.0, 1.0)
		var e := 1.0 - pow(1.0 - u, 3.0)
		var from: Transform3D = a["from"]
		var to: Transform3D = a["to"]
		var xf := from.interpolate_with(to, e)
		xf.origin += to.basis.y * 0.12 * sin(PI * u)
		smm.set_instance_transform(int(t["num"]) - 1, xf)
		if u >= 1.0:
			smm.set_instance_transform(int(t["num"]) - 1, to)
			place_anims.remove_at(k)
			if a["ok"]:
				_play(snd_correct)
				_sparkle(to.origin + to.basis.y * 0.02, Color("ffd36b"))
			else:
				_play(snd_wrong)


func _cancel_anim(i: int) -> void:
	for k in range(place_anims.size() - 1, -1, -1):
		if int(place_anims[k]["i"]) == i:
			place_anims.remove_at(k)


func _sparkle(pos: Vector3, col: Color) -> void:
	if sparkle_mesh == null:
		sparkle_mesh = QuadMesh.new()
		sparkle_mesh.size = Vector2(0.025, 0.025)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.vertex_color_use_as_albedo = true
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		sparkle_mesh.material = m
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.amount = 26
	p.lifetime = 0.6
	p.explosiveness = 1.0
	p.mesh = sparkle_mesh
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = TASO_R * 0.9
	p.direction = Vector3(0, 1, 0)
	p.spread = 180.0
	p.initial_velocity_min = 0.3
	p.initial_velocity_max = 0.9
	p.gravity = Vector3(0, -0.6, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.3
	p.color = col
	add_child(p)
	p.global_position = pos
	p.emitting = true
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)


func _unplace(g: int, n: int) -> int:
	var i: int = slots[g][n]
	_cancel_anim(i)
	if _is_correct(g, n):
		correct -= 1
	slots[g][n] = -1
	placed -= 1
	save_dirty = true
	var t: Dictionary = tasos[i]
	var smm: MultiMesh = shelf_mms[t["grp"]]
	smm.set_instance_transform(int(t["num"]) - 1, hidden_xf)
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
	var good := 0
	for n in NUMBERS_PER_SET:
		if _is_correct(g, n):
			good += 1
	var done := good == NUMBERS_PER_SET
	_shelf_look(g, good, done)
	if done != shelf_done[g]:
		shelf_done[g] = done
		var bm: StandardMaterial3D = board_mats[g]
		bm.albedo_color = board_done_tint if done else board_tint
		var hm: StandardMaterial3D = header_mats[g]
		hm.emission_enabled = done
		for k in NUMBERS_PER_SET:
			_refresh_ring(g, k)
		if done and not loading:
			_play(snd_set, true)
			_celebrate(g)
			if not set_bonus_paid[g]:
				set_bonus_paid[g] = true
				coins += COIN_SET
				_say("%s vitrini tamam! +%d puan" % [SETS[g]["name"], COIN_SET])
			else:
				_say("%s vitrini yine tamam!" % SETS[g]["name"])
	_update_title(g)
	finished = not shelf_done.has(false)


## only_selected: Q yalnızca seçili tasoyu, Shift+Q hepsini fırlatır.
## Elden fırlat: her taso dönerek uçan bir fizik cismi olur; sekip durduğu yerde (ters ya da düz) kalır.
func _drop(only_selected: bool) -> void:
	if hand.is_empty():
		return
	var list: Array = [hand[sel]] if only_selected else hand.duplicate()
	var cb := cam.global_transform.basis
	var fwd := -cb.z
	for k in list.size():
		var i: int = list[k]
		hand.erase(i)
		_throw(i, k, list.size(), fwd, cb)
	_play(snd_pick)
	sel = clampi(sel, 0, maxi(hand.size() - 1, 0))
	_rebuild_hand()


## Seçili taso önde ve büyük, diğerleri arkasında yelpaze gibi.
func _rebuild_hand() -> void:
	# önceki el görüntüsünü gizle
	for g in set_count:
		var used: int = hand_used[g]
		var mm0: MultiMesh = hand_mms[g]
		for j in used:
			mm0.set_instance_transform(j, hidden_xf)
		hand_used[g] = 0
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
		var g: int = tasos[i]["grp"]
		var mm: MultiMesh = hand_mms[g]
		var j: int = hand_used[g]
		hand_used[g] = j + 1
		mm.set_instance_transform(j, xf)
		mm.set_instance_color(j, _taso_color(i))
		mm.set_instance_custom_data(j, _custom(i))


func _try_buy(key: String) -> bool:
	var sk: Dictionary = skills[key]
	var lvl: int = sk["level"]
	var costs: Array = sk["cost"]
	if lvl >= costs.size():
		return false
	var req: String = sk["req"]
	if req != "" and _lvl(req) == 0:
		return false
	var c: int = costs[lvl]
	if coins < c:
		return false
	coins -= c
	sk["level"] = lvl + 1
	save_dirty = true
	_play(snd_buy, true)
	_say("%s açıldı!" % sk["name"])
	return true


# ---------------- Büyüler ----------------
func _selected_grp() -> int:
	if not hand.is_empty():
		return int(tasos[hand[sel]]["grp"])
	if target.get("kind", "") == "taso" and not _face_down(target["idx"]):
		return int(tasos[target["idx"]]["grp"])
	return -1


func _use_ability(key: String) -> void:
	if _lvl(key) == 0:
		_say("Önce gelişim ağacından aç (Tab)")
		return
	if cooldowns.has(key) and float(cooldowns[key]) > 0.0:
		_say("%s hazır değil (%d sn)" % [skills[key]["name"], ceili(float(cooldowns[key]))])
		return
	match key:
		"sezgi":
			var g := _selected_grp()
			if g == -1:
				_say("Elinde ya da baktığın yerde bir taso olmalı")
				return
			sezgi_grp = g
			sezgi_time = SEZGI_SURE[_lvl("sezgi")]
			_refresh_glow()
			cooldowns["sezgi"] = CD_SEZGI
			_play(snd_magic, true)
			_say("Sezgi: %s tasoları parlıyor" % SETS[g]["name"])
		"toplama":
			var g := _selected_grp()
			if g == -1:
				_say("Elinde ya da baktığın yerde bir taso olmalı")
				return
			var n := _gather(g, TOPLAMA_R[_lvl("toplama")])
			cooldowns["toplama"] = CD_TOPLAMA
			_play(snd_magic, true)
			_say("Toplama: %d %s tasosu önüne geldi" % [n, SETS[g]["name"]])
		"cevir":
			_land_all()
			var n := _flip_around(CEVIR_R[_lvl("cevir")])
			cooldowns["cevir"] = CD_CEVIR
			_play(snd_magic, true)
			_say("Çevirme: %d ters taso düzeldi" % n)
		"ayiklama":
			var n := _sort_around(AYIKLAMA_R[_lvl("ayiklama")])
			cooldowns["ayiklama"] = CD_AYIKLAMA
			_play(snd_magic, true)
			_say("Ayıklama: %d taso setlerine göre yığıldı" % n)


func _on_floor_of_player(p: Vector3) -> bool:
	return absf(p.y - (player.global_position.y - 0.9)) < 1.5


## Seçili setin yakındaki tasolarını oyuncunun önüne düzgün bir yığın halinde çeker
func _gather(g: int, r: float) -> int:
	var pp := player.global_position
	var fwd := -player.global_transform.basis.z
	fwd.y = 0
	fwd = fwd.normalized()
	var base := pp + fwd * 1.2
	base.y = pp.y - 0.9
	var list: Array = []
	for i in tasos.size():
		if in_pile[i] and int(tasos[i]["grp"]) == g:
			var o := pile_xf[i].origin
			if _on_floor_of_player(o) and Vector2(o.x - pp.x, o.z - pp.z).length() <= r:
				list.append(i)
	for k in list.size():
		var i: int = list[k]
		var col := k % 3
		var row := floori(k / 3.0) % 3
		var h := floori(k / 9.0)
		var pos := base + Vector3((col - 1) * 0.28, BASE_Y + h * TASO_H * 1.05, (row - 1) * 0.28)
		_move_pile(i, Transform3D(Basis(Vector3.UP, randf() * 0.3), pos))
	_refresh_glow()
	return list.size()


## Çevredeki tasoları setlerine göre oyuncunun etrafında ayrı yığınlara dizer
func _sort_around(r: float) -> int:
	var pp := player.global_position
	var groups := {}
	for i in tasos.size():
		if not in_pile[i]:
			continue
		var o := pile_xf[i].origin
		if _on_floor_of_player(o) and Vector2(o.x - pp.x, o.z - pp.z).length() <= r:
			var g: int = tasos[i]["grp"]
			if not groups.has(g):
				groups[g] = []
			groups[g].append(i)
	var keys := groups.keys()
	keys.sort()
	var total := 0
	for k in keys.size():
		var ang := TAU * k / keys.size()
		var c := Vector3(pp.x + cos(ang) * 1.6, pp.y - 0.9, pp.z + sin(ang) * 1.6)
		var lst: Array = groups[keys[k]]
		lst.sort_custom(func(a, b): return int(tasos[a]["num"]) < int(tasos[b]["num"]))
		for j in lst.size():
			var i: int = lst[j]
			var off := Vector3((j % 2) * 0.26 - 0.13, 0, (floori(j / 2.0) % 2) * 0.26 - 0.13)
			var pos := c + off + Vector3(0, BASE_Y + floori(j / 4.0) * TASO_H * 1.05, 0)
			_move_pile(i, Transform3D(Basis(), pos))
			total += 1
	_refresh_glow()
	return total


## Çevredeki ters tasoları düz çevirir
func _flip_around(r: float) -> int:
	var pp := player.global_position
	var n := 0
	for i in tasos.size():
		if not in_pile[i] or not _face_down(i):
			continue
		var o := pile_xf[i].origin
		if _on_floor_of_player(o) and Vector2(o.x - pp.x, o.z - pp.z).length() <= r:
			_move_pile(i, Transform3D(Basis(Vector3.UP, randf() * TAU), o))
			n += 1
	return n


## Numara Rehberi: bakılan vitrinin boş yuvalarında soluk numaralar
func _update_guide(delta: float) -> void:
	var lv := _lvl("rehber")
	var g := -1
	if lv > 0 and target.get("kind", "") == "shelf":
		var body: Node = target["body"]
		g = body.get_meta("grp")
		guide_hide = 1.0
	elif guide_g != -1:
		guide_hide -= delta
		if guide_hide > 0.0:
			g = guide_g
	if g == -1:
		if guide_g != -1:
			for lb in guide_labels:
				(lb as Label3D).visible = false
			guide_g = -1
		return
	var ver := placed * 1000 + lv
	if g == guide_g and ver == guide_ver:
		return
	guide_g = g
	guide_ver = ver
	if guide_labels.is_empty():
		for k in NUMBERS_PER_SET:
			var lb := Label3D.new()
			lb.font_size = 36
			lb.pixel_size = 0.0014
			lb.outline_size = 8
			lb.modulate = Color(1, 0.95, 0.8, 0.55)
			lb.outline_modulate = Color(0, 0, 0, 0.5)
			lb.visible = false
			add_child(lb)
			guide_labels.append(lb)
	for n in NUMBERS_PER_SET:
		var lb: Label3D = guide_labels[n]
		var show: bool = slots[g][n] == -1 and (lv >= 2 or n % SLOT_COLS == 0)
		lb.visible = show
		if show:
			var xf := _slot_xf(g, n)
			lb.global_transform = Transform3D(xf.basis * Basis(Vector3.RIGHT, -PI / 2), xf.origin + xf.basis.y * 0.01)
			lb.text = str(n + 1)


func _move_pile(i: int, xf: Transform3D) -> void:
	_grid_remove(i)
	pile_xf[i] = xf
	_pile_xf(i, xf)
	_grid_add(i)
	save_dirty = true


## Sezgi: seçili setin yerdeki tasolarının üstünde parlayan halkalar (derinlik testi yok)
func _refresh_glow() -> void:
	var k := 0
	if sezgi_time > 0.0 and sezgi_grp != -1:
		for i in tasos.size():
			if in_pile[i] and int(tasos[i]["grp"]) == sezgi_grp and k < NUMBERS_PER_SET:
				glow_mm.set_instance_transform(k, pile_xf[i])
				k += 1
	glow_mm.visible_instance_count = k


func _build_ability_visuals() -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = TASO_R + 0.02
	torus.outer_radius = TASO_R + 0.06
	glow_mm = MultiMesh.new()
	glow_mm.transform_format = MultiMesh.TRANSFORM_3D
	glow_mm.mesh = torus
	glow_mm.instance_count = NUMBERS_PER_SET
	glow_mm.visible_instance_count = 0
	glow_mmi = MultiMeshInstance3D.new()
	glow_mmi.multimesh = glow_mm
	var gm := StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.no_depth_test = true
	gm.albedo_color = Color(0.55, 1.0, 0.9, 0.85)
	glow_mmi.material_override = gm
	add_child(glow_mmi)
	# pusula: doğru yuvada halka + vitrinin üstünde ışık sütunu
	var ct := TorusMesh.new()
	ct.inner_radius = TASO_R + 0.01
	ct.outer_radius = TASO_R + 0.05
	compass_ring = MeshInstance3D.new()
	compass_ring.mesh = ct
	var cm := StandardMaterial3D.new()
	cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cm.albedo_color = Color("5dfcff")
	compass_ring.material_override = cm
	compass_ring.visible = false
	add_child(compass_ring)
	var beam := CylinderMesh.new()
	beam.top_radius = 0.12
	beam.bottom_radius = 0.12
	beam.height = 4.0
	compass_beam = MeshInstance3D.new()
	compass_beam.mesh = beam
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.albedo_color = Color(0.36, 0.99, 1.0, 0.35)
	compass_beam.material_override = bm
	compass_beam.visible = false
	add_child(compass_beam)


func _update_compass() -> void:
	compass_ring.visible = false
	compass_beam.visible = false
	if _lvl("pusula") == 0 or hand.is_empty():
		return
	var t: Dictionary = tasos[hand[sel]]
	var g: int = t["grp"]
	var n: int = int(t["num"]) - 1
	if slots[g][n] == hand[sel]:
		return
	var shelf: Node3D = shelves[g]
	compass_ring.global_transform = shelf.global_transform * Transform3D(Basis(Vector3.RIGHT, PI / 2), _slot_local(n) + Vector3(0, 0, 0.04))
	compass_ring.visible = true
	compass_beam.global_position = shelf.global_position + shelf.global_transform.basis.z * 0.6 + Vector3(0, BOARD_Y + 3.0, 0)
	compass_beam.visible = true


func _say(s: String) -> void:
	message = s
	message_time = 2.5


# ---------------- Ses ----------------
# Ses dosyası yok: kısa çan sesleri kodda sentezleniyor.
func _build_sounds() -> void:
	snd_correct = _make_chime([[1046.5, 0.0], [1568.0, 0.05]], 0.5)
	snd_set = _make_chime([[523.3, 0.0], [659.3, 0.13], [784.0, 0.26], [1046.5, 0.39], [1318.5, 0.39], [1568.0, 0.39]], 1.6)
	for k in 3:
		snd_steps.append(_make_noise(0.13, 30.0, 0.12 + k * 0.03, 0.9, 85.0 + k * 18.0, 0.55))
	snd_pick = _make_noise(0.09, 42.0, 0.75, 0.45, 1900.0, 0.18)
	snd_drop = _make_clatter()
	snd_wrong = _make_noise(0.16, 22.0, 0.08, 0.5, 196.0, 0.7)
	snd_buy = _make_chime([[784.0, 0.0], [1046.5, 0.07], [1318.5, 0.14], [1568.0, 0.21]], 1.0)
	snd_magic = _make_noise(0.7, 4.5, 0.02, 0.6, 600.0, 0.25, 0.9)
	sfx = AudioStreamPlayer.new()
	sfx.max_polyphony = 8
	add_child(sfx)
	foot = AudioStreamPlayer.new()
	foot.max_polyphony = 2
	add_child(foot)
	music = AudioStreamPlayer.new()
	music.process_mode = Node.PROCESS_MODE_ALWAYS
	var path := "res://assets/audio/muzik.ogg"
	if ResourceLoader.exists(path):
		var ms: AudioStream = load(path)
		if ms is AudioStreamOggVorbis:
			(ms as AudioStreamOggVorbis).loop = true
		music.stream = ms
	add_child(music)
	_apply_volumes()
	if music.stream != null:
		music.play()


func _apply_volumes() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.001)))
	if sfx != null:
		sfx.volume_db = -6.0 + linear_to_db(maxf(sfx_vol, 0.001))
		foot.volume_db = -15.0 + linear_to_db(maxf(sfx_vol, 0.001))
		music.volume_db = -9.0 + linear_to_db(maxf(music_vol, 0.001))


## Filtrelenmiş gürültü + isteğe bağlı ton. lp: alçak geçiren katsayısı (0-1),
## sweep > 0: filtre zamanla açılıp kapanır ve ton yükselir (büyü "vuuş" sesi).
func _make_noise(dur: float, decay: float, lp: float, vel: float, tone_f: float = 0.0, tone_amt: float = 0.0, sweep: float = 0.0) -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * dur)
	var data := PackedByteArray()
	data.resize(count * 2)
	var y := 0.0
	var ph := 0.0
	for i in count:
		var t := float(i) / rate
		var a := clampf(lp + sweep * 0.4 * sin(PI * t / dur), 0.005, 1.0)
		y += a * (randf_range(-1.0, 1.0) - y)
		var env := exp(-t * decay) * minf(1.0, t * 600.0)
		if sweep > 0.0:
			env = sin(PI * t / dur) * exp(-t * decay * 0.3)
		var f := tone_f * (1.0 + sweep * t / dur)
		ph += TAU * f / rate
		var v := (y * (1.0 - tone_amt) * 2.2 + sin(ph) * tone_amt) * env * vel
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = data
	return w


## Yere bırakılan tasolar: birkaç küçük karton tıkırtısı
func _make_clatter() -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * 0.3)
	var data := PackedByteArray()
	data.resize(count * 2)
	var hits := [0.0, 0.05, 0.09, 0.16, 0.21]
	var y := 0.0
	for i in count:
		var t := float(i) / rate
		var v := 0.0
		y += 0.5 * (randf_range(-1.0, 1.0) - y)
		for h in hits:
			var lt: float = t - float(h)
			if lt >= 0.0:
				v += y * exp(-lt * 90.0) * (1.0 - float(h) * 2.5)
		v += sin(TAU * 140.0 * t) * exp(-t * 30.0) * 0.25
		data.encode_s16(i * 2, int(clampf(v * 0.55, -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = data
	return w


func _footsteps(delta: float) -> void:
	var on_floor := player.is_on_floor()
	var hv := Vector2(player.velocity.x, player.velocity.z).length()
	if on_floor and not was_on_floor:
		_step_sound(1.1)
		step_accum = 0.0
	elif on_floor and hv > 0.5:
		step_accum += hv * delta
		if step_accum > 1.75:
			step_accum = 0.0
			_step_sound(1.0)
	elif on_floor:
		step_accum = 1.2
	was_on_floor = on_floor


func _step_sound(gain: float) -> void:
	if snd_steps.is_empty():
		return
	foot.stream = snd_steps[randi() % snd_steps.size()]
	foot.pitch_scale = randf_range(0.88, 1.12) / gain
	foot.play()


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


# ---------------- Kayıt ----------------
func _read_save() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var d: Dictionary = parsed
	# set yapısı değiştiyse eski kaydı kullanma
	if int(d.get("sets", 0)) != set_count or int(d.get("per_set", 0)) != NUMBERS_PER_SET:
		return {}
	var list: Array = d.get("tasos", [])
	if list.size() != ACTIVE_SETS * NUMBERS_PER_SET:
		return {}
	return d


func _write_save() -> void:
	if not started and tasos.is_empty():
		return
	_land_all()
	var list: Array = []
	for i in tasos.size():
		var t: Dictionary = tasos[i]
		var xf: Transform3D = pile_xf[i]
		var q := xf.basis.get_rotation_quaternion()
		var o := xf.origin
		list.append([t["grp"], t["num"], 0, 1 if paid[i] else 0, 1 if in_pile[i] else 0,
			snappedf(o.x, 0.001), snappedf(o.y, 0.001), snappedf(o.z, 0.001),
			snappedf(q.x, 0.0001), snappedf(q.y, 0.0001), snappedf(q.z, 0.0001), snappedf(q.w, 0.0001)])
	var slot_list: Array = []
	for g in set_count:
		for n in NUMBERS_PER_SET:
			if slots[g][n] != -1:
				slot_list.append([g, n, slots[g][n]])
	var sk_levels := {}
	for key in skills:
		sk_levels[key] = skills[key]["level"]
	var pp := player.global_position
	var data := {
		"v": 2, "sets": set_count, "per_set": NUMBERS_PER_SET,
		"coins": coins, "elapsed": snappedf(elapsed, 0.1), "skills": sk_levels,
		"bonus": set_bonus_paid, "species": species_paid, "tut": tut_step, "hand": hand, "sel": sel,
		"player": [snappedf(pp.x, 0.01), snappedf(pp.y, 0.01), snappedf(pp.z, 0.01), snappedf(player.rotation.y, 0.001), snappedf(cam.rotation.x, 0.001)],
		"tasos": list, "slots": slot_list,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data))
	f.close()
	save_dirty = false
	save_timer = 0.0


func _apply_save(d: Dictionary) -> void:
	loading = true
	for e in d.get("slots", []):
		var ea: Array = e
		_place(int(ea[2]), int(ea[0]), int(ea[1]))
	loading = false
	coins = int(d.get("coins", 0))
	elapsed = float(d.get("elapsed", 0.0))
	var sk_levels: Dictionary = d.get("skills", {})
	for key in sk_levels:
		if skills.has(key):
			skills[key]["level"] = int(sk_levels[key])
	var spp: Array = d.get("species", [])
	for k in mini(spp.size(), species_paid.size()):
		species_paid[k] = bool(spp[k])
	# kaldırılan gelişimlere (Holo Dedektörü, Son Dokunuş) harcanan puanı geri ver
	var refund := {"holo": [80], "son": [100]}
	for key in refund:
		for k in mini(int(sk_levels.get(key, 0)), refund[key].size()):
			coins += int(refund[key][k])
	tut_step = int(d.get("tut", -1))
	var bonus: Array = d.get("bonus", [])
	for g in mini(bonus.size(), set_count):
		set_bonus_paid[g] = bool(bonus[g])
	hand.clear()
	for i in d.get("hand", []):
		hand.append(int(i))
	sel = clampi(int(d.get("sel", 0)), 0, maxi(hand.size() - 1, 0))
	var pl: Array = d.get("player", [])
	if pl.size() == 5:
		player.global_position = Vector3(float(pl[0]), float(pl[1]), float(pl[2]))
		if int(d.get("v", 1)) < 2:
			player.global_position.y = (MEZZ_Y if float(pl[1]) > 3.0 else 0.0) + 1.0
		player.rotation.y = float(pl[3])
		cam.rotation.x = float(pl[4])
	_rebuild_hand()
	save_dirty = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if started and save_dirty:
			_write_save()


func _load_settings() -> void:
	render_scale = 0.8 if touch_mode else 1.0
	if FileAccess.file_exists(SETTINGS_PATH):
		var f := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		f.close()
		if typeof(parsed) == TYPE_DICTIONARY:
			var d: Dictionary = parsed
			mouse_sens = float(d.get("mouse", mouse_sens))
			touch_sens = float(d.get("touch", touch_sens))
			volume = float(d.get("volume", volume))
			music_vol = float(d.get("music", music_vol))
			sfx_vol = float(d.get("sfx", sfx_vol))
			render_scale = float(d.get("scale", render_scale))
			adv_light = bool(d.get("adv2", adv_light))
	_apply_volumes()
	get_viewport().scaling_3d_scale = render_scale


func _save_settings() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"mouse": mouse_sens, "touch": touch_sens, "volume": volume, "music": music_vol, "sfx": sfx_vol, "scale": render_scale, "adv2": adv_light}))
		f.close()


# ---------------- Menü ----------------
func _menu_button(parent: Node, text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(420, 62)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 26)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.11, 0.08, 0.92)
	sb.set_corner_radius_all(14)
	sb.border_color = Color("c9a46a")
	sb.set_border_width_all(2)
	var sbh := sb.duplicate() as StyleBoxFlat
	sbh.bg_color = Color(0.32, 0.22, 0.14, 0.95)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sbh)
	b.add_theme_stylebox_override("pressed", sbh)
	b.add_theme_color_override("font_color", Color("f6e7c8"))
	parent.add_child(b)
	return b


func _menu_box(root: Control) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.position = Vector2(590, 150)
	box.size = Vector2(420, 600)
	box.add_theme_constant_override("separation", 14)
	root.add_child(box)
	return box


func _menu_label(parent: Node, text: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	parent.add_child(l)
	return l


func _build_menu(has_save: bool) -> void:
	menu_layer = CanvasLayer.new()
	menu_layer.layer = 10
	menu_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(menu_layer)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.02, 0.72)
	dim.size = Vector2(1600, 900)
	menu_layer.add_child(dim)

	menu_main = Control.new()
	menu_main.size = Vector2(1600, 900)
	menu_layer.add_child(menu_main)
	var box := _menu_box(menu_main)
	_menu_label(box, "TASO DÜKKÂNI", 56, Color("ffd36b"))
	menu_stats = _menu_label(box, "", 18, Color(1, 1, 1, 0.8))
	btn_continue = _menu_button(box, "Devam Et" if has_save else "Oyuna Başla")
	btn_continue.pressed.connect(_close_menu)
	btn_save = _menu_button(box, "Kaydet")
	btn_save.pressed.connect(_on_save_pressed)
	btn_new = _menu_button(box, "Yeni Oyun")
	btn_new.pressed.connect(_on_new_game)
	_menu_button(box, "Gelişim Ağacı").pressed.connect(_open_tree_from_menu)
	_menu_button(box, "Albüm").pressed.connect(_open_album_from_menu)
	_menu_button(box, "Ayarlar").pressed.connect(_on_settings_pressed)
	if not OS.has_feature("web"):
		_menu_button(box, "Çıkış").pressed.connect(_on_quit_pressed)

	menu_settings = Control.new()
	menu_settings.size = Vector2(1600, 900)
	menu_settings.visible = false
	menu_layer.add_child(menu_settings)
	var sbox := _menu_box(menu_settings)
	sbox.position.y = 30
	sbox.add_theme_constant_override("separation", 6)
	_menu_label(sbox, "AYARLAR", 44, Color("ffd36b"))
	_slider(sbox, "Fare hassasiyeti", 0.0005, 0.008, mouse_sens, func(v: float): mouse_sens = v)
	_slider(sbox, "Dokunmatik hassasiyet", 0.001, 0.015, touch_sens, func(v: float): touch_sens = v)
	_slider(sbox, "Genel ses", 0.0, 1.0, volume, _set_volume)
	_slider(sbox, "Müzik", 0.0, 1.0, music_vol, _set_music)
	_slider(sbox, "Efektler", 0.0, 1.0, sfx_vol, _set_sfx)
	_slider(sbox, "Görüntü çözünürlüğü (düşük = daha akıcı)", 0.5, 1.0, render_scale, _set_scale)
	if hi_gfx:
		var gb := _menu_button(sbox, "Gelişmiş ışık: " + ("Açık" if adv_light else "Kapalı"))
		gb.pressed.connect(_on_adv_toggle.bind(gb))
	_menu_button(sbox, "Rehberi baştan göster").pressed.connect(_on_tutorial_restart)
	_menu_button(sbox, "Geri").pressed.connect(_on_settings_back)
	_build_tree()
	_build_album()
	menu_layer.visible = false


## Gelişim ağacı ekranı: 3 dal, her düğüm bir buton (ad, seviye, açıklama, maliyet)
func _build_tree() -> void:
	menu_tree = Control.new()
	menu_tree.size = Vector2(1600, 900)
	menu_tree.visible = false
	menu_layer.add_child(menu_tree)
	var title := _menu_label(menu_tree, "GELİŞİM AĞACI", 46, Color("ffd36b"))
	title.position = Vector2(0, 30)
	title.size = Vector2(1600, 60)
	tree_points = _menu_label(menu_tree, "", 22, Color(1, 1, 1, 0.9))
	tree_points.position = Vector2(0, 92)
	tree_points.size = Vector2(1600, 34)
	var heads := ["TAŞIMA VE HAREKET", "GÖRÜŞ", "BÜYÜLER"]
	var cols: Array = []
	for b in 3:
		var col := VBoxContainer.new()
		col.position = Vector2(95 + b * 480, 145)
		col.size = Vector2(450, 650)
		col.add_theme_constant_override("separation", 10)
		menu_tree.add_child(col)
		_menu_label(col, heads[b], 22, Color("c9a46a"))
		cols.append(col)
	for key in TREE_ORDER:
		var sk: Dictionary = skills[key]
		var col: VBoxContainer = cols[int(sk["branch"])]
		var b := _menu_button(col, "")
		b.custom_minimum_size = Vector2(450, 120)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 16)
		b.pressed.connect(_on_tree_pressed.bind(key))
		tree_buttons[key] = b
	var back := _menu_button(menu_tree, "Oyuna dön")
	back.position = Vector2(590, 815)
	back.pressed.connect(_close_menu)
	_refresh_tree()


func _refresh_tree() -> void:
	tree_points.text = "Puan: %d     (doğru taso +%d, tür tamamlama +%d, vitrin tamamlama +%d)" % [coins, COIN_PLACE, COIN_SPECIES, COIN_SET]
	for key in TREE_ORDER:
		var sk: Dictionary = skills[key]
		var b: Button = tree_buttons[key]
		var costs: Array = sk["cost"]
		var lv: int = sk["level"]
		var req: String = sk["req"]
		var head := "%s   (Sv %d/%d)" % [sk["name"], lv, costs.size()]
		var tail := ""
		var col := Color("f6e7c8")
		if lv >= costs.size():
			tail = "TAMAMLANDI"
			col = Color("9be07a")
		elif req != "" and _lvl(req) == 0:
			tail = "Kilitli: önce %s" % String(skills[req]["name"]).split(" [")[0]
			col = Color(1, 1, 1, 0.4)
		else:
			var c: int = costs[lv]
			tail = "Maliyet: %d puan" % c
			col = Color("ffd36b") if coins >= c else Color(1, 1, 1, 0.6)
		b.text = "  %s\n  %s\n  %s" % [head, sk["desc"], tail]
		b.add_theme_color_override("font_color", col)
		b.add_theme_color_override("font_hover_color", col)


func _on_tree_pressed(key: String) -> void:
	var sk: Dictionary = skills[key]
	var costs: Array = sk["cost"]
	var lv: int = sk["level"]
	var req: String = sk["req"]
	if lv < costs.size() and coins < int(costs[lv]) and (req == "" or _lvl(req) > 0):
		tree_points.text = "Yeterli puan yok: %d gerekli, %d var" % [int(costs[lv]), coins]
		return
	if _try_buy(key):
		_refresh_tree()


func _open_tree_from_menu() -> void:
	if tut_step == 5:
		tut_flag = true
	menu_main.visible = false
	menu_tree.visible = true
	_refresh_tree()


func _open_tree() -> void:
	if menu_layer == null:
		return
	if tut_step == 5:
		tut_flag = true
	_open_menu()
	menu_main.visible = false
	menu_settings.visible = false
	menu_tree.visible = true
	_refresh_tree()


func _on_save_pressed() -> void:
	_write_save()
	btn_save.text = "Kaydedildi"


func _on_settings_pressed() -> void:
	menu_main.visible = false
	menu_settings.visible = true


func _on_settings_back() -> void:
	_save_settings()
	menu_settings.visible = false
	menu_main.visible = true


func _on_quit_pressed() -> void:
	_write_save()
	get_tree().quit()


func _set_volume(v: float) -> void:
	volume = v
	_apply_volumes()


func _set_music(v: float) -> void:
	music_vol = v
	_apply_volumes()


func _set_sfx(v: float) -> void:
	sfx_vol = v
	_apply_volumes()


func _set_scale(v: float) -> void:
	render_scale = v
	get_viewport().scaling_3d_scale = v


func _slider(parent: Node, title: String, lo: float, hi: float, value: float, on_change: Callable) -> void:
	_menu_label(parent, title, 20, Color(1, 1, 1, 0.85))
	var sl := HSlider.new()
	sl.min_value = lo
	sl.max_value = hi
	sl.step = (hi - lo) / 100.0
	sl.value = value
	sl.custom_minimum_size = Vector2(420, 36)
	sl.focus_mode = Control.FOCUS_NONE
	sl.value_changed.connect(on_change)
	parent.add_child(sl)


func _open_menu() -> void:
	if menu_layer == null or menu_layer.visible:
		return
	zooming = false
	menu_layer.visible = true
	menu_main.visible = true
	menu_settings.visible = false
	menu_tree.visible = false
	menu_album.visible = false
	new_confirm = false
	btn_new.text = "Yeni Oyun"
	btn_save.text = "Kaydet"
	btn_save.visible = started
	if started:
		btn_continue.text = "Devam Et"
	var s := int(elapsed)
	menu_stats.text = "Doğru dizilen: %d / %d     Puan: %d     Süre: %02d:%02d:%02d" % [correct, tasos.size(), coins, floori(s / 3600.0), floori(s / 60.0) % 60, s % 60]
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if started and save_dirty:
		_write_save()


func _close_menu() -> void:
	menu_layer.visible = false
	get_tree().paused = false
	started = true
	capture_grace = 0.8
	if not touch_mode:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_new_game() -> void:
	if not new_confirm:
		new_confirm = true
		btn_new.text = "Emin misin? Tüm ilerleme silinir"
		return
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	skip_menu = true
	get_tree().paused = false
	get_tree().reload_current_scene()


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
		help.text = "Sol taraf: yürü  •  Sağ taraf: sürükle bak, dokun al/koy\n< >: eldeki tasoyu seç  •  Ağaç: gelişim ağacı"
		_build_touch_ui(layer)
	_build_tutorial(layer)
	if not touch_mode:
		help.text = "WASD yürü  •  Shift koş  •  Boşluk zıpla  •  Fare bak\nSol tık: taso al / boş yuvaya koy / dolu yuvadakini eline al  •  Basılı tutup sürükle: yuvadaki tasoyu taşı\nTekerlek: eldeki tasoyu seç\nQ: seçiliyi fırlat  •  Shift+Q: hepsini fırlat  •  Sağ tık (basılı): yakınlaştır\nTab: gelişim ağacı  •  B: albüm  •  Z/F/G/C: büyüler  •  Esc: menü"


func _face_down(i: int) -> bool:
	return in_pile[i] and pile_xf[i].basis.y.y < 0.0


func _taso_name(i: int) -> String:
	var t: Dictionary = tasos[i]
	return "%s %d%s" % [SETS[t["grp"]]["code"], t["num"], ""]


func _update_hud() -> void:
	var total := tasos.size()
	var s := int(elapsed)
	var seri := ("      Seri: %d (x%d)" % [streak, _streak_mult()]) if streak > 0 else ""
	hud_stats.text = ("Puan: %d" + seri + "      Doğru: %d/%d      Vitrinde: %d      Yerde: %d      Süre: %02d:%02d") % [coins, correct, total, placed, pile_count + flying.size(), floori(s / 60.0), s % 60]

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
			if _face_down(i):
				# ters duran tasonun kimliği ancak eline alınca görünür
				hud_info.text = "Ters duran taso"
			else:
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

	var lines: Array = []
	for key in ABILITY_KEYS:
		var open := _lvl(key) > 0
		if touch_ability_btns.has(key):
			var tb: Button = touch_ability_btns[key]
			tb.visible = open
		if not open:
			continue
		var st := "hazır"
		if cooldowns.has(key) and float(cooldowns[key]) > 0.0:
			st = "%d sn" % ceili(float(cooldowns[key]))
		if key == "sezgi" and sezgi_time > 0.0:
			st = "aktif %d sn" % ceili(sezgi_time)
		lines.append("[%s] %s: %s" % [ABILITY_KEYS[key], String(skills[key]["name"]).split(" [")[0], st])
	var can_buy := false
	for key in TREE_ORDER:
		var sk: Dictionary = skills[key]
		var costs: Array = sk["cost"]
		var lv: int = sk["level"]
		var rq: String = sk["req"]
		if lv < costs.size() and coins >= int(costs[lv]) and (rq == "" or _lvl(rq) > 0):
			can_buy = true
			break
	if can_buy:
		lines.append("Gelişim ağacında açabileceğin bir şey var! (Tab)")
	hud_skills.text = "\n".join(lines)

	hud_msg.text = message if message_time > 0.0 else ""
	if finished:
		hud_center.text = "TÜM VİTRİNLER TAMAM!\nSüre %02d:%02d  •  Yeni oyun için menüyü aç" % [floori(s / 60.0), s % 60]
	elif false:
		pass
	else:
		hud_center.text = ""


# ---------------- Dükkân dönüşümü ----------------
## Dükkân düzenlendikçe aydınlanır: başta loş, soluk renkli, havada toz, yerde kir lekeleri.
const MILESTONES := [0.02, 0.1, 0.25, 0.5, 0.75, 0.9]
var order_applied := -1.0


func _noise_tex(freq: float, seed_v: int, points: Array) -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = freq
	n.fractal_octaves = 4
	n.seed = seed_v
	var t := NoiseTexture2D.new()
	t.width = 256
	t.height = 256
	t.seamless = true
	t.noise = n
	var gr := Gradient.new()
	gr.offsets = PackedFloat32Array()
	gr.colors = PackedColorArray()
	for pt in points:
		gr.add_point(float(pt[0]), pt[1])
	t.color_ramp = gr
	return t


func _dust_texture() -> NoiseTexture2D:
	if dust_tex == null:
		dust_tex = _noise_tex(0.035, 3, [[0.0, Color(1, 1, 1, 0.0)], [0.5, Color(1, 1, 1, 0.2)], [1.0, Color(1, 1, 1, 0.7)]])
	return dust_tex


func _build_atmosphere() -> void:
	# havada süzülen toz zerreleri
	var dot := GradientTexture2D.new()
	dot.width = 32
	dot.height = 32
	dot.fill = GradientTexture2D.FILL_RADIAL
	dot.fill_from = Vector2(0.5, 0.5)
	dot.fill_to = Vector2(1.0, 0.5)
	var dg := Gradient.new()
	dg.set_color(0, Color(1, 1, 1, 1))
	dg.set_color(1, Color(1, 1, 1, 0))
	dot.gradient = dg
	dust_mat = StandardMaterial3D.new()
	dust_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dust_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	dust_mat.albedo_texture = dot
	dust_mat.albedo_color = Color(1.0, 0.95, 0.82, 0.6)
	var qm := QuadMesh.new()
	qm.size = Vector2(0.05, 0.05)
	qm.material = dust_mat
	var motes := CPUParticles3D.new()
	motes.amount = 160 if touch_mode else 360
	motes.lifetime = 14.0
	motes.preprocess = 14.0
	motes.mesh = qm
	motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	motes.emission_box_extents = Vector3(ROOM_W / 2.0 - 2.0, BUILD_H / 2.0 - 0.4, ROOM_D / 2.0 - 2.0)
	motes.position = Vector3(0, BUILD_H / 2.0, 0)
	motes.direction = Vector3(0, 1, 0)
	motes.spread = 180.0
	motes.gravity = Vector3(0, -0.015, 0)
	motes.initial_velocity_min = 0.03
	motes.initial_velocity_max = 0.14
	motes.scale_amount_min = 0.5
	motes.scale_amount_max = 1.4
	add_child(motes)

	# yerde kir lekeleri
	dirt_mat = StandardMaterial3D.new()
	dirt_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dirt_mat.albedo_texture = _noise_tex(0.02, 11, [[0.0, Color(1, 1, 1, 0)], [0.5, Color(1, 1, 1, 0)], [0.75, Color(1, 1, 1, 0.6)], [1.0, Color(1, 1, 1, 1)]])
	dirt_mat.albedo_color = Color(0.2, 0.14, 0.09, 0.75)
	dirt_mat.roughness = 1.0
	var pm := PlaneMesh.new()
	pm.size = Vector2(2.2, 2.2)
	var dmm := MultiMesh.new()
	dmm.transform_format = MultiMesh.TRANSFORM_3D
	dmm.mesh = pm
	dmm.instance_count = 110
	var hw := ROOM_W / 2.0 - 1.5
	var hd := ROOM_D / 2.0 - 1.5
	for k in dmm.instance_count:
		var pos: Vector3
		if k < 85:
			pos = Vector3(randf_range(-hw, hw), 0.006, randf_range(-hd, hd - 2.0))
		else:
			pos = Vector3(randf_range(-hw, hw), MEZZ_Y + 0.006, randf_range(-hd, MEZZ_EDGE_Z - 1.0))
		var sc := randf_range(0.6, 1.8)
		dmm.set_instance_transform(k, Transform3D(Basis(Vector3.UP, randf() * TAU).scaled(Vector3(sc, 1, sc * randf_range(0.6, 1.3))), pos))
	var dmi := MultiMeshInstance3D.new()
	dmi.multimesh = dmm
	dmi.material_override = dirt_mat
	dmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(dmi)

	# kutlama konfetisi
	confetti_mesh = QuadMesh.new()
	confetti_mesh.size = Vector2(0.07, 0.045)
	var cm := StandardMaterial3D.new()
	cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cm.vertex_color_use_as_albedo = true
	cm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	cm.cull_mode = BaseMaterial3D.CULL_DISABLED
	confetti_mesh.material = cm

	for g in set_count:
		_shelf_look(g, 0, false)


func _milestone_for(p: float) -> int:
	var m := 0
	for k in MILESTONES.size():
		if p >= float(MILESTONES[k]):
			m = k + 1
	return m


func _update_order(delta: float) -> void:
	var p := float(correct) / maxf(tasos.size(), 1.0)
	if order_vis < 0.0:
		order_vis = p
	order_vis = move_toward(order_vis, p, delta * 0.03)
	if absf(order_vis - order_applied) > 0.0005:
		order_applied = order_vis
		var e := pow(order_vis, 0.6)
		if hi_gfx and adv_light:
			env.ambient_light_energy = lerpf(0.3, 0.5, e)
		else:
			env.ambient_light_energy = lerpf(0.36, 0.62, e)
		env.adjustment_saturation = lerpf(0.72, 1.04, e)
		env.adjustment_brightness = lerpf(0.88, 1.0, e)
		sun.light_energy = lerpf(0.8, 1.2, e) if hi_gfx else lerpf(0.3, 0.6, e)
		var lc := Color(1.0, 0.82, 0.62).lerp(Color(1.0, 0.94, 0.84), e)
		for lamp in lamps:
			var l: OmniLight3D = lamp
			l.light_energy = lerpf(1.4, 2.2, e) if hi_gfx else lerpf(0.95, 1.55, e)
			l.light_color = lc
		dust_mat.albedo_color.a = lerpf(0.65, 0.05, e)
		dirt_mat.albedo_color.a = lerpf(0.75, 0.0, e)
	var m := _milestone_for(p)
	if m > milestone and message_time < 0.5:
		milestone = m
		_say("Dükkân aydınlanıyor: %%%d düzenli" % roundi(float(MILESTONES[m - 1]) * 100.0))
	elif m < milestone:
		milestone = m


## Vitrinin kendi görünümü: doğru taso arttıkça LED yanar, camdaki toz silinir
func _shelf_look(g: int, good: int, done: bool) -> void:
	var fr := float(good) / NUMBERS_PER_SET
	var lm: StandardMaterial3D = shelf_led_mats[g]
	lm.albedo_color = Color(1.0, 0.98, 0.9) if done else Color(0.2, 0.18, 0.15).lerp(Color("fff3d6"), sqrt(fr))
	var dm: StandardMaterial3D = shelf_dust_mats[g]
	dm.albedo_color.a = 0.12 * pow(1.0 - fr, 1.4)
	if shelf_lights[g] != null:
		var sp: SpotLight3D = shelf_lights[g]
		sp.light_energy = 2.0 if done else lerpf(0.08, 1.3, sqrt(fr))


## Vitrin tamamlanınca konfeti
func _celebrate(g: int) -> void:
	var shelf: Node3D = shelves[g]
	var top_y := BOARD_Y + (SLOT_ROWS * SLOT_GAP + 0.3) / 2.0
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.amount = 160
	p.lifetime = 3.0
	p.explosiveness = 0.85
	p.mesh = confetti_mesh
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(1.3, 0.05, 0.1)
	p.direction = Vector3(0, 1, 0.5)
	p.spread = 35.0
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 6.0
	p.gravity = Vector3(0, -4.0, 0)
	p.damping_min = 0.8
	p.damping_max = 1.6
	p.angle_max = 360.0
	p.angular_velocity_min = -300.0
	p.angular_velocity_max = 300.0
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.3
	var gr := Gradient.new()
	gr.set_color(0, _set_color(g))
	gr.set_color(1, Color("ffd36b"))
	gr.add_point(0.5, Color.WHITE)
	p.color_initial_ramp = gr
	p.position = Vector3(0, top_y + 0.4, 0.35)
	shelf.add_child(p)
	p.emitting = true
	get_tree().create_timer(4.5).timeout.connect(p.queue_free)


# ---------------- Albüm ----------------
const ALBUM_COLS := 15
const ALBUM_SHADER := """shader_type canvas_item;
uniform vec2 cell = vec2(0.0);
uniform float locked = 0.0;
uniform vec2 grid = vec2(13.0, 12.0);
void fragment() {
	vec2 uv = clamp(UV, vec2(0.012), vec2(0.988));
	vec4 c = texture(TEXTURE, (cell + uv) / grid);
	float g = dot(c.rgb, vec3(0.3, 0.59, 0.11));
	c.rgb = mix(c.rgb, vec3(0.05 + g * 0.12), locked);
	float d = length(UV - 0.5);
	c.a = smoothstep(0.5, 0.475, d);
	float rim = smoothstep(0.455, 0.48, d);
	c.rgb = mix(c.rgb, vec3(0.85, 0.7, 0.45), rim * (1.0 - locked * 0.6));
	COLOR = c;
}
"""
var album_from_menu := false


func _build_album() -> void:
	menu_album = Control.new()
	menu_album.size = Vector2(1600, 900)
	menu_album.visible = false
	menu_layer.add_child(menu_album)
	album_title = _menu_label(menu_album, "", 40, Color("ffd36b"))
	album_title.position = Vector2(0, 18)
	album_title.size = Vector2(1600, 56)
	album_count = _menu_label(menu_album, "", 20, Color(1, 1, 1, 0.85))
	album_count.position = Vector2(0, 74)
	album_count.size = Vector2(1600, 30)
	var sh := Shader.new()
	sh.code = ALBUM_SHADER
	var pitch := 62.0
	var x0 := (1600.0 - ALBUM_COLS * pitch) / 2.0 + 2.0
	var y0 := 112.0
	for n in NUMBERS_PER_SET:
		var tr := TextureRect.new()
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.position = Vector2(x0 + (n % ALBUM_COLS) * pitch, y0 + floori(n / float(ALBUM_COLS)) * pitch)
		tr.size = Vector2(pitch - 4.0, pitch - 4.0)
		var m := ShaderMaterial.new()
		m.shader = sh
		m.set_shader_parameter("cell", Vector2(n % 13, floori(n / 13.0)))
		tr.material = m
		menu_album.add_child(tr)
		album_cells.append(tr)
	var prev := _menu_button(menu_album, "<")
	prev.custom_minimum_size = Vector2(80, 90)
	prev.size = Vector2(80, 90)
	prev.position = Vector2(x0 - 120, 380)
	prev.pressed.connect(func(): _album_show(posmod(album_set - 1, set_count)))
	var next := _menu_button(menu_album, ">")
	next.custom_minimum_size = Vector2(80, 90)
	next.size = Vector2(80, 90)
	next.position = Vector2(x0 + ALBUM_COLS * pitch + 36, 380)
	next.pressed.connect(func(): _album_show(posmod(album_set + 1, set_count)))
	var tx0 := (1600.0 - set_count * 44.0) / 2.0
	for g in set_count:
		var b := Button.new()
		b.text = SETS[g]["code"]
		b.position = Vector2(tx0 + g * 44.0, 745)
		b.size = Vector2(41, 40)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 14)
		var sb := StyleBoxFlat.new()
		sb.bg_color = _set_color(g).darkened(0.55)
		sb.border_color = _set_color(g)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(6)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("pressed", sb)
		b.pressed.connect(_album_show.bind(g))
		menu_album.add_child(b)
		album_tabs.append(b)
	var back := _menu_button(menu_album, "Geri")
	back.position = Vector2(590, 808)
	back.pressed.connect(_album_back)


func _album_show(g: int) -> void:
	album_set = g
	var path := "res://assets/art/set_%02d.jpg" % g
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	var got := 0
	for n in NUMBERS_PER_SET:
		var i: int = idx_of_uid[g * NUMBERS_PER_SET + n]
		var open: bool = i != -1 and paid[i]
		if open:
			got += 1
		var tr: TextureRect = album_cells[n]
		tr.texture = tex
		(tr.material as ShaderMaterial).set_shader_parameter("locked", 0.0 if open else 1.0)
		tr.tooltip_text = ("%s %d" % [SETS[g]["code"], n + 1]) if open else "?"
	var total := 0
	for v in paid:
		if v:
			total += 1
	album_title.text = "ALBÜM  •  %s (%s)" % [SETS[g]["name"], SETS[g]["code"]]
	album_count.text = "Bu sette açılan canlı: %d / %d        Tüm koleksiyon: %d / %d" % [got, NUMBERS_PER_SET, total, paid.size()]
	for k in album_tabs.size():
		var b: Button = album_tabs[k]
		b.modulate = Color(1.6, 1.6, 1.6) if k == g else Color(1, 1, 1, 0.75)


func _open_album() -> void:
	if menu_layer == null:
		return
	var sg := _selected_grp()
	if sg != -1:
		album_set = sg
	_open_menu()
	menu_main.visible = false
	menu_album.visible = true
	album_from_menu = false
	_album_show(album_set)


func _open_album_from_menu() -> void:
	menu_main.visible = false
	menu_album.visible = true
	album_from_menu = true
	_album_show(album_set)


func _album_back() -> void:
	if album_from_menu:
		menu_album.visible = false
		menu_main.visible = true
	else:
		_close_menu()


# ---------------- İlk açılış rehberi ----------------
## Her adım: [bilgisayar metni, dokunmatik metni]
const TUT := [
	["Yerdeki tasolar dükkânın setlerine ait. Bir tasoya bak ve sol tıkla: eline alırsın.",
		"Yerdeki tasolar dükkânın setlerine ait. Ekranın sağ tarafında bir tasoya dokun: eline alırsın."],
	["Fare tekerleğiyle eldeki tasolar arasında geç. Seçili taso en önde durur.",
		"< > butonlarıyla eldeki tasolar arasında geç. Seçili taso en önde durur."],
	["Her setin bir vitrini var; vitrin başlığının rengi tasonun rengiyle aynı. Seçili tasonun vitrinini bul ve ona bak.",
		"Her setin bir vitrini var; vitrin başlığının rengi tasonun rengiyle aynı. Seçili tasonun vitrinini bul ve ona bak."],
	["Vitrinde numara yazmaz: tasolar 1'den 150'ye soldan sağa, yukarıdan aşağı dizilir. Boş bir yuvaya tıklayıp tasoyu koy.",
		"Vitrinde numara yazmaz: tasolar 1'den 150'ye soldan sağa, yukarıdan aşağı dizilir. Boş bir yuvaya dokunup tasoyu koy."],
	["Yanlış yerdeki taso kırmızı halkayla görünür; dolu bir yuvaya tıklarsan oradaki taso eline geri gelir. Doğru taso +1, bir türün 3 evrimi yan yana +2, biten vitrin +25 puan.",
		"Yanlış yerdeki taso kırmızı halkayla görünür; dolu bir yuvaya dokunursan oradaki taso eline geri gelir. Doğru taso +1, bir türün 3 evrimi yan yana +2, biten vitrin +25 puan."],
	["Puanlarını gelişim ağacında harcarsın. Açmak için Tab tuşuna bas.",
		"Puanlarını gelişim ağacında harcarsın. Açmak için Ağaç butonuna dokun."],
	["Hazırsın! Dükkân düzenlendikçe aydınlanır, tozu kalkar. Açtığın canlılar Albüm'de birikir (B tuşu ya da menü).",
		"Hazırsın! Dükkân düzenlendikçe aydınlanır, tozu kalkar. Açtığın canlılar menüdeki Albüm'de birikir."],
]


func _build_tutorial(layer: CanvasLayer) -> void:
	tut_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.07, 0.05, 0.88)
	sb.set_corner_radius_all(14)
	sb.border_color = Color("c9a46a")
	sb.set_border_width_all(2)
	sb.set_content_margin_all(16)
	tut_panel.add_theme_stylebox_override("panel", sb)
	tut_panel.position = Vector2(360, 600)
	tut_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tut_label = Label.new()
	tut_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tut_label.custom_minimum_size = Vector2(848, 0)
	tut_label.add_theme_font_size_override("font_size", 21)
	tut_label.add_theme_color_override("font_color", Color("f6e7c8"))
	tut_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tut_panel.add_child(tut_label)
	layer.add_child(tut_panel)
	if touch_mode:
		tut_skip_btn = _touch_button(layer, "Rehberi geç", Vector2(360, 525), Vector2(200, 62))
		tut_skip_btn.pressed.connect(_tut_skip)


func _tut_show() -> void:
	if tut_panel == null:
		return
	tut_panel.visible = tut_step >= 0
	if tut_skip_btn != null:
		tut_skip_btn.visible = tut_step >= 0
	if tut_step < 0:
		return
	var row: Array = TUT[tut_step]
	var txt: String = row[1] if touch_mode else row[0]
	var hint := "" if touch_mode else "     (H: rehberi geç)"
	tut_label.text = "Rehber %d/%d%s\n%s" % [tut_step + 1, TUT.size(), hint, txt]
	tut_panel.reset_size()


func _tut_update(delta: float) -> void:
	if tut_step < 0:
		return
	tut_time += delta
	var done := false
	match tut_step:
		0:
			done = not hand.is_empty()
		1:
			done = tut_flag or tut_time > 9.0 or hand.size() < 2 and tut_time > 5.0
		2:
			if target.get("kind", "") == "shelf":
				var body: Node = target["body"]
				done = hand.is_empty() or int(body.get_meta("grp")) == int(tasos[hand[sel]]["grp"])
		3:
			done = placed > tut_mark
		4:
			done = tut_time > 10.0
		5:
			done = tut_flag
		6:
			done = tut_time > 9.0
	if done:
		tut_step += 1
		tut_time = 0.0
		tut_flag = false
		tut_mark = placed
		if tut_step >= TUT.size():
			tut_step = -1
		save_dirty = true
		_tut_show()


func _tut_skip() -> void:
	tut_step = -1
	save_dirty = true
	_tut_show()


func _on_adv_toggle(gb: Button) -> void:
	adv_light = not adv_light
	gb.text = "Gelişmiş ışık: " + ("Açık" if adv_light else "Kapalı")
	_apply_gfx()


func _on_tutorial_restart() -> void:
	tut_step = 0
	tut_time = 0.0
	tut_flag = false
	tut_mark = placed
	_tut_show()
	_save_settings()
	_close_menu()


# ---------------- Gerçekçi eşyalar (Poly Haven, CC0) ----------------
var fabric_nrm: NoiseTexture2D
var props_blocked: Array = []        # [Rect2 (x,z), kat yüksekliği]
var last_prop_size := Vector3.ZERO
var fans: Array = []
# Fırlatılan tasolar: gerçek fizik cismi olarak uçar, durunca yere (pile) geçer
const FLY_LAYER := 8
var flying: Array = []                 # [{"i": taso, "body": RigidBody3D, "t": süre}]
var wake_timer := 0.0
var rest_until := {}                    # taso -> yeniden uyandırılabileceği an
const MAX_ACTIVE := 120                 # aynı anda fizik cismi olabilecek en fazla taso
# Yerleştirme animasyonu: taso elden uçarak yuvasına oturur
var place_anims: Array = []             # [{"i","from","to","t","ok","g","n"}]
var sparkle_mesh: QuadMesh
# Vitrinde sürükle-bırak
var press_info := {}
var dragging := false
# Seri bonusu: art arda yeni ve doğru yerleştirme
var streak := 0
# Numara Rehberi etiketleri (bakılan vitrinin boş yuvaları)
var guide_labels: Array = []
var guide_g := -1
var guide_ver := -1
var guide_hide := 0.0
var taso_phys: PhysicsMaterial
const MODEL_FIX := {"steel_frame_shelves_01": [0.1, 0.0], "wooden_display_shelves_01": [1.0, PI / 2]}


func _fabric_normal() -> NoiseTexture2D:
	if fabric_nrm == null:
		var n := FastNoiseLite.new()
		n.noise_type = FastNoiseLite.TYPE_CELLULAR
		n.frequency = 0.12
		fabric_nrm = NoiseTexture2D.new()
		fabric_nrm.width = 256
		fabric_nrm.height = 256
		fabric_nrm.seamless = true
		fabric_nrm.as_normal_map = true
		fabric_nrm.bump_strength = 3.0
		fabric_nrm.noise = n
	return fabric_nrm


## Bir Poly Haven modelini yerleştirir. anchor: "floor" (alt yüzü pos.y'ye), "ceiling" (üst yüzü pos.y'ye),
## "wall" (arka yüzü pos'a; model +z'ye, yani odaya bakar). Model yoksa null döner, oyun onsuz çalışır.
func _prop(id: String, pos: Vector3, yaw: float = 0.0, anchor: String = "floor", collide: bool = true, s: float = 1.0) -> Node3D:
	var path := "res://assets/models/%s/%s.gltf" % [id, id]
	if not ResourceLoader.exists(path):
		return null
	var ps: PackedScene = load(path)
	if ps == null:
		return null
	var inst: Node3D = ps.instantiate()
	# bazı Poly Haven dosyaları farklı ölçekte ya da yönde kaydedilmiş
	if MODEL_FIX.has(id):
		var fx: Array = MODEL_FIX[id]
		inst.scale = Vector3.ONE * float(fx[0])
		inst.rotation.y = float(fx[1])
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation.y = yaw
	holder.scale = Vector3.ONE * s
	add_child(holder)
	holder.add_child(inst)
	var bb := _local_aabb(inst, holder)
	var off := Vector3(-(bb.position.x + bb.size.x / 2.0), -bb.position.y, -(bb.position.z + bb.size.z / 2.0))
	if anchor == "ceiling":
		off.y = -(bb.position.y + bb.size.y)
	elif anchor == "wall":
		off.z = -bb.position.z
	inst.position += off
	last_prop_size = bb.size * s
	if collide:
		var body := StaticBody3D.new()
		body.set_meta("kind", "wall")
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = bb.size
		cs.shape = bs
		cs.position = bb.get_center() + off
		body.add_child(cs)
		holder.add_child(body)
		# tasolar bu eşyanın içine saçılmasın
		var corners: Array = []
		for cx in [bb.position.x, bb.end.x]:
			for cz in [bb.position.z, bb.end.z]:
				corners.append(holder.global_transform * (Vector3(cx, 0, cz) + Vector3(off.x, 0, off.z)))
		var r := Rect2(Vector2(corners[0].x, corners[0].z), Vector2.ZERO)
		for c in corners:
			r = r.expand(Vector2(c.x, c.z))
		props_blocked.append([r.grow(0.25), pos.y])
	return holder


func _no_shadows(root: Node) -> void:
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for ch in n.get_children():
			stack.append(ch)
		if n is GeometryInstance3D:
			(n as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _local_aabb(root: Node, holder: Node3D) -> AABB:
	var inv := holder.global_transform.affine_inverse()
	var out := AABB()
	var first := true
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for ch in n.get_children():
			stack.append(ch)
		if n is VisualInstance3D:
			var vi := n as VisualInstance3D
			var box := (inv * vi.global_transform) * vi.get_aabb()
			if first:
				out = box
				first = false
			else:
				out = out.merge(box)
	return out


## Dükkânı dolduran eşyalar: kasa çevresi, oturma köşesi, depo rafları, koliler, bitkiler, tablolar, vantilatörler
func _furnish() -> void:
	var hw := ROOM_W / 2.0
	var hd := ROOM_D / 2.0
	var cz := hd - 5.5
	# kasa ve çevresi
	_prop("CashRegister_01", Vector3(8.1, 1.06, cz), PI, "floor", false)
	_prop("Television_01", Vector3(9.6, 1.06, cz - 0.1), 0.4, "floor", false)
	_prop("drawer_cabinet", Vector3(11.4, 0, cz - 2.4), 0.0)
	_prop("boombox", Vector3(11.4, last_prop_size.y, cz - 2.4), 0.2, "floor", false)
	_prop("gaming_console", Vector3(7.3, 1.06, cz + 0.1), PI - 0.3, "floor", false)
	_prop("metal_trash_can", Vector3(6.2, 0, cz - 1.0), 0.0, "floor", true, 0.6)
	# vitrin camı önündeki tabela ve uyarı
	_prop("standing_chalkboard_01", Vector3(3.6, 0, hd - 2.6), 0.5)
	_prop("WetFloorSign_01", Vector3(-2.6, 0, 14.0), 0.7)
	# oturma köşesi: sol ön pencerenin önü
	_prop("Sofa_01", Vector3(-10.0, 0, hd - 1.6), PI)
	_prop("CoffeeTable_01", Vector3(-10.0, 0, hd - 3.6), 0.0)
	_prop("chess_set", Vector3(-10.3, last_prop_size.y, hd - 3.6), 0.3, "floor", false)
	_prop("ArmChair_01", Vector3(-13.6, 0, hd - 3.8), PI / 2 + 0.3)
	_prop("ArmChair_01", Vector3(-6.4, 0, hd - 3.8), -PI / 2 - 0.3)
	_prop("potted_plant_01", Vector3(-14.2, 0, hd - 1.0), 0.0)
	_prop("potted_plant_01", Vector3(-5.8, 0, hd - 1.0), 1.2)
	_prop("potted_plant_02", Vector3(14.5, 0, hd - 1.0), 0.4)
	# duvar vitrinleri arası: kitaplık, çekmeceli dolap, bitki
	for z in [-16.25, -1.25, 13.75]:
		_prop("wooden_bookshelf_worn", Vector3(-hw + 0.05, 0, z), PI / 2, "wall")
	for z in [-8.75, 6.25]:
		_prop("potted_plant_02", Vector3(-hw + 0.7, 0, z), randf() * TAU)
	for z in [-8.75, 6.25]:
		_prop("wooden_display_shelves_01", Vector3(hw - 0.05, 0, z), -PI / 2, "wall")
	for z in [-16.25, -1.25, 13.75]:
		_prop("potted_plant_01", Vector3(hw - 0.8, 0, z), randf() * TAU)
	# asma katın altı: depo rafları, koliler, kasalar
	for x in [-9.5, -7.0, -4.5, 4.5, 7.0, 9.5, -20.0, 20.0, -31.0, 31.0]:
		_prop("steel_frame_shelves_01", Vector3(x, 0, -hd + 0.05), 0.0, "wall")
	var stacks := [Vector3(-2.0, 0, -22.5), Vector3(1.5, 0, -23.0), Vector3(-17.0, 0, -15.0), Vector3(17.5, 0, -14.0),
		Vector3(-27.5, 0, -14.5), Vector3(27.0, 0, -21.0), Vector3(-11.5, 0, -13.0), Vector3(11.0, 0, -18.0)]
	for st in stacks:
		var p: Vector3 = st
		var hgt := 0.0
		for k in randi_range(1, 3):
			var id: String = ["cardboard_box_01", "cardboard_box_01", "wooden_crate_01", "plastic_crate_01"][randi() % 4]
			_prop(id, p + Vector3(randf_range(-0.1, 0.1), hgt, randf_range(-0.1, 0.1)), randf_range(-0.4, 0.4), "floor", k == 0)
			hgt += last_prop_size.y
		_prop("cardboard_box_01", p + Vector3(0.75, 0, 0.3), randf() * TAU)
	_prop("wooden_ladder", Vector3(-24.0, 0, -hd + 0.6), 0.2)
	_prop("korean_fire_extinguisher_01", Vector3(-3.2, 0, hd - 0.5), PI, "floor", false)
	_prop("korean_fire_extinguisher_01", Vector3(-hw + 0.5, MEZZ_Y, -11.5), PI / 2, "floor", false)
	# asma kat
	_prop("vintage_suitcase", Vector3(-6.0, MEZZ_Y, -12.0), 0.4)
	_prop("wicker_basket_01", Vector3(6.5, MEZZ_Y, -11.8), 0.0)
	_prop("rubber_duck_toy", Vector3(6.5, MEZZ_Y + 0.12, -11.8), 0.8, "floor", false)
	_prop("drawer_cabinet", Vector3(-hw + 0.05, MEZZ_Y, -22.0), PI / 2, "wall")
	_prop("book_encyclopedia_set_01", Vector3(-hw + 0.35, MEZZ_Y + last_prop_size.y, -22.0), PI / 2, "floor", false)
	_prop("potted_plant_02", Vector3(hw - 0.8, MEZZ_Y, -12.0), 0.0)
	for x in [-24.0, 0.0, 24.0]:
		_prop("wooden_bookshelf_worn", Vector3(x, MEZZ_Y, -hd), 0.0, "wall")
	for x in [-16.0, 16.0]:
		_prop("potted_plant_01", Vector3(x, MEZZ_Y, -hd + 0.6), randf() * TAU)
	# asma katta okuma köşesi
	_prop("ArmChair_01", Vector3(-1.6, MEZZ_Y, -17.0), 0.5)
	_prop("ArmChair_01", Vector3(1.6, MEZZ_Y, -17.0), -0.5)
	_prop("CoffeeTable_01", Vector3(0, MEZZ_Y, -15.6), 0.0, "floor", true, 0.7)
	_prop("book_encyclopedia_set_01", Vector3(0.2, MEZZ_Y + last_prop_size.y, -15.6), 0.4, "floor", false)
	for st in [Vector3(-30.0, MEZZ_Y, -12.5), Vector3(29.0, MEZZ_Y, -21.0), Vector3(-9.0, MEZZ_Y, -22.5)]:
		var hgt := 0.0
		for k in randi_range(1, 3):
			_prop("cardboard_box_01", st + Vector3(randf_range(-0.08, 0.08), hgt, randf_range(-0.08, 0.08)), randf_range(-0.3, 0.3), "floor", k == 0)
			hgt += last_prop_size.y
	# duvarda tablolar ve saat
	_prop("wall_clock", Vector3(0, DOOR_H + 1.1, hd), PI, "wall", false)
	_prop("hanging_picture_frame_01", Vector3(hw, MEZZ_Y + 1.9, -13.0), -PI / 2, "wall", false)
	_prop("hanging_picture_frame_02", Vector3(-hw, MEZZ_Y + 1.9, -13.5), PI / 2, "wall", false)
	_prop("hanging_picture_frame_02", Vector3(-hw, 2.4, -20.0 + 3.75), PI / 2, "wall", false)
	# tavan: vantilatörler ve giriş avizesi
	for fp in [Vector3(-12, BUILD_H, 2), Vector3(12, BUILD_H, 2), Vector3(0, BUILD_H, 14)]:
		var f := _prop("ceiling_fan", fp, 0.0, "ceiling", false)
		if f != null:
			_no_shadows(f)
			fans.append(f)
	var chand := _prop("Chandelier_01", Vector3(0, BUILD_H, 20.5), 0.0, "ceiling", false)
	if chand != null:
		_no_shadows(chand)
		var cl := OmniLight3D.new()
		cl.position = Vector3(0, BUILD_H - last_prop_size.y - 0.1, 20.5)
		cl.omni_range = 9.0
		cl.light_energy = 1.0
		cl.light_color = Color(1.0, 0.88, 0.7)
		cl.shadow_enabled = hi_gfx
		add_child(cl)
		lamps.append(cl)


## İç mekân detayları: ahşap lambri, tavan kirişleri, halılar
func _build_interior_finish() -> void:
	var hw := ROOM_W / 2.0
	var hd := ROOM_D / 2.0
	var panel: StandardMaterial3D = mat_wood_fine.duplicate()
	panel.albedo_color = Color(0.72, 0.58, 0.45)
	var rail := mat_wood
	var ph := 0.95
	# arka ve yan duvarlar: 0.95 m lambri + küpeşte
	_mesh_box(self, Vector3(ROOM_W, ph, 0.03), Vector3(0, ph / 2.0, -hd + 0.015), panel)
	_mesh_box(self, Vector3(ROOM_W, 0.06, 0.06), Vector3(0, ph, -hd + 0.03), rail)
	for sx in [-1.0, 1.0]:
		_mesh_box(self, Vector3(0.03, ph, ROOM_D), Vector3(sx * (hw - 0.015), ph / 2.0, 0), panel)
		_mesh_box(self, Vector3(0.06, 0.06, ROOM_D), Vector3(sx * (hw - 0.03), ph, 0), rail)
		# asma katta da
		_mesh_box(self, Vector3(0.03, ph, hd + MEZZ_EDGE_Z), Vector3(sx * (hw - 0.015), MEZZ_Y + ph / 2.0, (-hd + MEZZ_EDGE_Z) / 2.0), panel)
		_mesh_box(self, Vector3(0.06, 0.06, hd + MEZZ_EDGE_Z), Vector3(sx * (hw - 0.03), MEZZ_Y + ph, (-hd + MEZZ_EDGE_Z) / 2.0), rail)
	_mesh_box(self, Vector3(ROOM_W, ph, 0.03), Vector3(0, MEZZ_Y + ph / 2.0, -hd + 0.015), panel)
	# ön duvar: pencerelerin altına kadar alçak lambri (kapı hariç)
	var seg := hw - DOOR_W / 2.0
	for sx in [-1.0, 1.0]:
		_mesh_box(self, Vector3(seg, 0.45, 0.03), Vector3(sx * (DOOR_W / 2.0 + seg / 2.0), 0.225, hd - 0.015), panel)
	# tavan kirişleri
	var beam: StandardMaterial3D = mat_wood.duplicate()
	beam.albedo_color = Color(0.55, 0.45, 0.38)
	var x := -hw + 3.5
	while x < hw:
		_mesh_box(self, Vector3(0.28, 0.4, ROOM_D), Vector3(x, BUILD_H - 0.2, 0), beam)
		x += 5.0
	_mesh_box(self, Vector3(ROOM_W, 0.32, 0.32), Vector3(0, BUILD_H - 0.16, MEZZ_EDGE_Z), beam)
	_mesh_box(self, Vector3(ROOM_W, 0.32, 0.32), Vector3(0, BUILD_H - 0.16, 10.0), beam)
	# asma katın alt yüzünde kirişler
	var z := -hd + 2.5
	while z < MEZZ_EDGE_Z:
		_mesh_box(self, Vector3(ROOM_W, 0.25, 0.2), Vector3(0, MEZZ_Y - 0.43, z), beam)
		z += 2.5
	# halılar: oturma köşesi ve giriş
	var rug := StandardMaterial3D.new()
	rug.albedo_color = Color(0.42, 0.12, 0.11)
	rug.roughness = 1.0
	rug.normal_enabled = true
	rug.normal_texture = _fabric_normal()
	rug.uv1_scale = Vector3(6, 6, 1)
	_mesh_box(self, Vector3(6.5, 0.012, 4.2), Vector3(-10.0, 0.006, hd - 3.0), rug)
	var rug2: StandardMaterial3D = rug.duplicate()
	rug2.albedo_color = Color(0.16, 0.22, 0.3)
	_mesh_box(self, Vector3(4.0, 0.012, 7.0), Vector3(0, 0.006, hd - 6.5), rug2)
