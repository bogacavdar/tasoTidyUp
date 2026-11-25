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

const ROOM_W := 60.0           # x
const ROOM_D := 50.0           # z
const WALL_H := 7.0

const SLOT_COLS := 10
const SLOT_ROWS := 15
const SLOT_GAP := 0.28
const BOARD_Y := 2.46          # vitrin panosunun orta yüksekliği (en alt sıra ~0.5 m)

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
const PALETTE := [
	"e6194b", "3cb44b", "ffe119", "4363d8", "f58231", "911eb4", "42d4f4", "f032e6",
	"bfef45", "fabed4", "469990", "dcbeff", "9a6324", "fffac8", "800000", "aaffc3",
	"808000", "ffd8b1", "000075", "a9a9a9", "ffffff", "222222", "ff6f61", "6b5b95",
	"88b04b", "92a8d1", "955251", "b565a7", "009b77", "dd4124", "45b8ac", "efc050",
	"5b3a29", "1e5945",
]  # 34 set için birbirinden belirgin ayrışan renkler
const RING_EMPTY := Color("1c1917")
const RING_WRONG := Color("ff2a2a")
const RING_DONE := Color("3fe06a")
const BOARD_COLOR := Color("2b2623")
const BOARD_DONE := Color("27502f")

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
var board_mats: Array = []
var header_mats: Array = []
var shelf_done: Array[bool] = []
var set_bonus_paid: Array[bool] = []
var paid: Array[bool] = []            # bu taso doğru yere ilk kez oturunca jeton verildi mi
var hidden_xf := Transform3D(Basis().scaled(Vector3.ONE * 0.0001), Vector3(0, -50, 0))

var hud_stats: Label
var hud_info: Label
var hud_hand: Label
var hud_msg: Label
var hud_skills: Label
var hud_center: Label


func _ready() -> void:
	randomize()
	_init_skills()
	_make_set_colors()
	_build_atlas()
	_make_taso_material()
	_build_world()
	_build_player()
	_spawn_tasos()
	_build_pile()
	_build_hud()
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
func _box(parent: Node, size: Vector3, pos: Vector3, col: Color, kind: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.set_meta("kind", kind)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(col)
	body.add_child(mi)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	body.add_child(cs)
	parent.add_child(body)
	return body


func _build_world() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("1d1a18")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.9, 0.85, 0.8)
	env.ambient_light_energy = 0.75
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-60, 30, 0)
	sun.light_energy = 0.8
	add_child(sun)
	for x in [-18.0, 0.0, 18.0]:
		for z in [-11.0, 11.0]:
			var lamp := OmniLight3D.new()
			lamp.position = Vector3(x, WALL_H - 0.6, z)
			lamp.omni_range = 24.0
			lamp.light_energy = 1.4
			lamp.light_color = Color(1, 0.92, 0.8)
			add_child(lamp)

	var hw := ROOM_W / 2.0
	var hd := ROOM_D / 2.0
	_box(self, Vector3(ROOM_W + 0.6, 0.2, ROOM_D + 0.6), Vector3(0, -0.1, 0), Color("4a3a2e"), "floor")
	var wall := Color("5d5249")
	_box(self, Vector3(ROOM_W + 0.6, WALL_H, 0.3), Vector3(0, WALL_H / 2, -hd - 0.15), wall, "wall")
	_box(self, Vector3(ROOM_W + 0.6, WALL_H, 0.3), Vector3(0, WALL_H / 2, hd + 0.15), wall, "wall")
	_box(self, Vector3(0.3, WALL_H, ROOM_D + 0.6), Vector3(-hw - 0.15, WALL_H / 2, 0), wall, "wall")
	_box(self, Vector3(0.3, WALL_H, ROOM_D + 0.6), Vector3(hw + 0.15, WALL_H / 2, 0), wall, "wall")

	# 34 vitrin: kuzey 10, güney 10, doğu 8, batı 8 yer var; ilk set_count kadarı kullanılır
	var placements: Array = []
	for k in 10:
		placements.append([Vector3(-24.75 + 5.5 * k, 0, -hd + 0.05), 0.0])
	for k in 10:
		placements.append([Vector3(-24.75 + 5.5 * k, 0, hd - 0.05), PI])
	for k in 8:
		placements.append([Vector3(hw - 0.05, 0, -19.25 + 5.5 * k), -PI / 2])
	for k in 8:
		placements.append([Vector3(-hw + 0.05, 0, -19.25 + 5.5 * k), PI / 2])

	var board_w := SLOT_COLS * SLOT_GAP + 0.3
	var board_h := SLOT_ROWS * SLOT_GAP + 0.4
	var ring_mesh := CylinderMesh.new()
	ring_mesh.top_radius = TASO_R + 0.028
	ring_mesh.bottom_radius = TASO_R + 0.028
	ring_mesh.height = 0.004
	ring_mesh.radial_segments = 24
	ring_mm = MultiMesh.new()
	ring_mm.transform_format = MultiMesh.TRANSFORM_3D
	ring_mm.use_colors = true
	ring_mm.mesh = ring_mesh
	ring_mm.instance_count = set_count * NUMBERS_PER_SET
	var ring_mmi := MultiMeshInstance3D.new()
	ring_mmi.multimesh = ring_mm
	var ring_mat := StandardMaterial3D.new()
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.vertex_color_use_as_albedo = true
	ring_mmi.material_override = ring_mat
	add_child(ring_mmi)

	shelf_mm = _new_mm(set_count * NUMBERS_PER_SET)
	var shelf_mmi := MultiMeshInstance3D.new()
	shelf_mmi.multimesh = shelf_mm
	shelf_mmi.material_override = taso_mat
	add_child(shelf_mmi)

	for g in set_count:
		var shelf := Node3D.new()
		shelf.position = placements[g][0]
		shelf.rotation.y = placements[g][1]
		add_child(shelf)
		shelves.append(shelf)
		var col := _set_color(g)
		var board := _box(shelf, Vector3(board_w, board_h, 0.1), Vector3(0, BOARD_Y, 0), Color("2b2623"), "shelf")
		board.set_meta("grp", g)
		board_mats.append((board.get_child(0) as MeshInstance3D).material_override)
		var header := _box(shelf, Vector3(board_w, 0.32, 0.14), Vector3(0, BOARD_Y + board_h / 2 + 0.16, 0.02), col.darkened(0.15), "shelf")
		header.set_meta("grp", g)
		var hm: StandardMaterial3D = (header.get_child(0) as MeshInstance3D).material_override
		hm.emission = Color("3fae5a")
		header_mats.append(hm)
		var counter := _box(shelf, Vector3(board_w, 0.3, 0.45), Vector3(0, 0.15, 0.2), Color("3a302a"), "shelf")
		counter.set_meta("grp", g)

		var title := Label3D.new()
		title.font_size = 64
		title.pixel_size = 0.003
		title.outline_size = 12
		title.position = Vector3(0, BOARD_Y + board_h / 2 + 0.16, 0.1)
		shelf.add_child(title)
		shelf_titles.append(title)

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
	player.position = Vector3(0, 0.95, 19)
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
		# Tüm zemine tamamen rastgele saçılır; üst üste binenler çakışmasın diye hafif yükseklik farkı
		var hw := ROOM_W / 2.0 - WALL_MARGIN
		var hd := ROOM_D / 2.0 - WALL_MARGIN
		var pos := Vector3(randf_range(-hw, hw), BASE_Y + randf() * 0.04, randf_range(-hd, hd))
		var b := Basis(Vector3.UP, randf() * TAU) * Basis(Vector3.RIGHT, randf_range(-0.12, 0.12))
		pile_xf.append(Transform3D(b, pos))
		in_pile.append(true)
		paid.append(false)
		_grid_add(i)
	pile_count = tasos.size()


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
	return Color(float(_uid(t)), 1.0 if t["holo"] else 0.0, 0.0, 0.0)


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
	var fwd := -player.global_transform.basis.z
	var right := player.global_transform.basis.x
	var d := fwd * mv.y + right * mv.x
	d.y = 0
	d = d.normalized()
	var sprint := Input.is_key_pressed(KEY_SHIFT)
	var speed := WALK_SPEED * (SPRINT_MULT if sprint else 1.0)
	player.velocity.x = d.x * speed
	player.velocity.z = d.z * speed
	if player.is_on_floor():
		if Input.is_key_pressed(KEY_SPACE):
			player.velocity.y = JUMP_VELOCITY
	else:
		player.velocity.y -= GRAVITY * delta
	player.move_and_slide()
	cam.fov = lerpf(cam.fov, 82.0 if (sprint and mv != Vector2.ZERO) else 75.0, 8.0 * delta)
	target = _find_target()


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
		bm.albedo_color = BOARD_DONE if done else BOARD_COLOR
		var hm: StandardMaterial3D = header_mats[g]
		hm.emission_enabled = done
		for k in NUMBERS_PER_SET:
			_refresh_ring(g, k)
		if done:
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
	pt.y = 0.0
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
	elif Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		hud_center.text = "Oynamak için tıkla"
	else:
		hud_center.text = ""
