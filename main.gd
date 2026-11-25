extends Node3D
## Taso Kaosu — 3D birinci şahıs prototip.
## Odanın ortasında dev bir taso yığını; duvarlarda her set için bir vitrin.
## Oyuncu yürür, yığından taso alır, vitrindeki doğru numaralı yuvaya yerleştirir.
## Sahne tamamen koddan kuruluyor; dışarıdan model yok.

# ---------------- Ayarlar ----------------
const SET_COUNT := 4
const NUMBERS_PER_SET := 40
const TASO_COUNT := 500
const HOLO_CHANCE := 0.05

const TASO_R := 0.12
const TASO_H := 0.014
const BASE_Y := 0.02
const PILE_R := 1.7
const PILE_HEIGHT := 0.4
const REACH := 3.2
const GRAB_RADIUS := 0.35

const SLOT_COLS := 8
const SLOT_ROWS := 5
const SLOT_GAP := 0.3
const BOARD_Y := 1.35

const MOVE_SPEED := 4.0
const MOUSE_SENS := 0.0025
const GRAVITY := 9.8

const SET_NAMES := ["Kor Vadisi", "Derin Su", "Taş Kök", "Gece Rüzgârı"]
const SET_LETTERS := ["K", "D", "T", "G"]
const SET_COLORS := [Color("e0603a"), Color("3a8fe0"), Color("7bb04a"), Color("9a6ae6")]
const PLAIN := Color("d9cfb8")

const SKILL_ORDER := ["renk", "oto", "avuc", "holo"]
const AVUC_CAP := [1, 3, 6, 12]

const COIN_PLACE := 2
const COIN_HOLO := 10
const COIN_COPY := 1
const COIN_ALBUM := 50

# ---------------- Durum ----------------
var tasos: Array = []                 # Dictionary: grp, num, holo
var pile_xf: Array[Transform3D] = []  # yığındaki son konum
var in_pile: Array[bool] = []
var slots: Array = []                 # slots[grp][n] = taso indeksi ya da -1
var hand: Array = []
var holo_list: Array[int] = []
var skills := {}
var coins := 0
var placed := 0
var copies := 0
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
var pile_mm: MultiMesh
var holo_mm: MultiMesh
var holo_mmi: MultiMeshInstance3D
var holo_ring_mat: StandardMaterial3D
var set_mats: Array = []
var holo_mats: Array = []
var plain_mat: StandardMaterial3D
var plain_holo_mat: StandardMaterial3D
var shelves: Array = []
var shelf_titles: Array = []
var slot_labels: Array = []
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
	_make_materials()
	_build_world()
	_build_player()
	_spawn_tasos()
	_build_pile()
	_build_hud()
	_say("Yığına yürü, bir tasoya bak ve sol tıkla!")


func _init_skills() -> void:
	skills = {
		"renk": {"name": "Renk Gözü", "desc": "yığındaki tasolar set rengini gösterir", "cost": [20], "level": 0},
		"oto": {"name": "Otomatik Numara", "desc": "vitrine tıklayınca tasolar kendi yuvasına gider", "cost": [40], "level": 0},
		"avuc": {"name": "Avuç", "desc": "tek tıkla 3 / 6 / 12 taso al", "cost": [60, 150, 400], "level": 0},
		"holo": {"name": "Holo Dedektörü", "desc": "gömülü holo tasolar yığının içinden parlar", "cost": [80], "level": 0},
	}


func _make_materials() -> void:
	taso_mesh = CylinderMesh.new()
	taso_mesh.top_radius = TASO_R
	taso_mesh.bottom_radius = TASO_R
	taso_mesh.height = TASO_H
	taso_mesh.radial_segments = 24
	taso_mesh.rings = 1
	for g in SET_COUNT:
		var c: Color = SET_COLORS[g]
		set_mats.append(_mat(c))
		var hm := _mat(c)
		hm.emission_enabled = true
		hm.emission = c.lightened(0.4)
		hm.emission_energy_multiplier = 0.9
		holo_mats.append(hm)
	plain_mat = _mat(PLAIN)
	plain_holo_mat = _mat(PLAIN)
	plain_holo_mat.emission_enabled = true
	plain_holo_mat.emission = Color(1, 0.95, 0.7)
	plain_holo_mat.emission_energy_multiplier = 0.6


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.75
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
	env.ambient_light_energy = 0.55
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-60, 30, 0)
	sun.light_energy = 0.7
	add_child(sun)
	for p in [Vector3(0, 2.8, 0), Vector3(0, 2.6, -5), Vector3(0, 2.6, 5)]:
		var lamp := OmniLight3D.new()
		lamp.position = p
		lamp.omni_range = 9.0
		lamp.light_energy = 1.3
		lamp.light_color = Color(1, 0.92, 0.8)
		add_child(lamp)

	# Zemin, halı, duvarlar
	_box(self, Vector3(14.6, 0.2, 14.6), Vector3(0, -0.1, 0), Color("4a3a2e"), "floor")
	_box(self, Vector3(4.4, 0.01, 4.4), Vector3(0, 0.005, 0), Color("6b2e2e"), "floor")
	var wall := Color("5d5249")
	_box(self, Vector3(14.6, 3.2, 0.3), Vector3(0, 1.6, -7.15), wall, "wall")
	_box(self, Vector3(14.6, 3.2, 0.3), Vector3(0, 1.6, 7.15), wall, "wall")
	_box(self, Vector3(0.3, 3.2, 14.6), Vector3(-7.15, 1.6, 0), wall, "wall")
	_box(self, Vector3(0.3, 3.2, 14.6), Vector3(7.15, 1.6, 0), wall, "wall")

	# Vitrinler: kuzey duvarında 2, güney duvarında 2
	var placements := [
		[Vector3(-3.2, 0, -6.95), 0.0],
		[Vector3(3.2, 0, -6.95), 0.0],
		[Vector3(-3.2, 0, 6.95), PI],
		[Vector3(3.2, 0, 6.95), PI],
	]
	for g in SET_COUNT:
		var shelf := Node3D.new()
		shelf.position = placements[g][0]
		shelf.rotation.y = placements[g][1]
		add_child(shelf)
		shelves.append(shelf)
		var col: Color = SET_COLORS[g]
		var board := _box(shelf, Vector3(2.7, 1.9, 0.1), Vector3(0, BOARD_Y, 0), Color("2b2623"), "shelf")
		board.set_meta("grp", g)
		var header := _box(shelf, Vector3(2.7, 0.3, 0.14), Vector3(0, 2.45, 0.02), col.darkened(0.15), "shelf")
		header.set_meta("grp", g)
		var counter := _box(shelf, Vector3(2.7, 0.35, 0.45), Vector3(0, 0.175, 0.2), Color("3a302a"), "shelf")
		counter.set_meta("grp", g)

		var title := Label3D.new()
		title.font_size = 64
		title.pixel_size = 0.003
		title.outline_size = 12
		title.position = Vector3(0, 2.45, 0.1)
		shelf.add_child(title)
		shelf_titles.append(title)

		var ring_mat := _mat(Color("1c1917"))
		var ring_mesh := CylinderMesh.new()
		ring_mesh.top_radius = TASO_R + 0.01
		ring_mesh.bottom_radius = TASO_R + 0.01
		ring_mesh.height = 0.004
		ring_mesh.radial_segments = 24
		var row_labels: Array = []
		var row_slots: Array = []
		for n in NUMBERS_PER_SET:
			var sp := _slot_local(n)
			var ring := MeshInstance3D.new()
			ring.mesh = ring_mesh
			ring.material_override = ring_mat
			ring.position = sp + Vector3(0, 0, 0.002)
			ring.rotation.x = PI / 2
			shelf.add_child(ring)

			var lb := Label3D.new()
			lb.text = str(n + 1)
			lb.font_size = 48
			lb.pixel_size = 0.0022
			lb.modulate = Color(1, 1, 1, 0.45)
			lb.outline_size = 0
			lb.position = sp + Vector3(0, 0, 0.006)
			shelf.add_child(lb)
			row_labels.append(lb)
			row_slots.append(-1)
		slot_labels.append(row_labels)
		slots.append(row_slots)
		_update_title(g)

	# Kopya kutusu
	_box(self, Vector3(0.9, 0.6, 0.9), Vector3(2.8, 0.3, 2.6), Color("6a4c86"), "copy")
	var cl := Label3D.new()
	cl.text = "KOPYA KUTUSU"
	cl.font_size = 48
	cl.pixel_size = 0.004
	cl.outline_size = 10
	cl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	cl.position = Vector3(2.8, 0.95, 2.6)
	add_child(cl)


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
	var cnt := 0
	for v in slots[g]:
		if v != -1:
			cnt += 1
	var lb: Label3D = shelf_titles[g]
	lb.text = "%s (%s)   %d/%d" % [SET_NAMES[g], SET_LETTERS[g], cnt, NUMBERS_PER_SET]


func _build_player() -> void:
	player = CharacterBody3D.new()
	player.position = Vector3(0, 0.9, 4.6)
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
	player.add_child(cam)
	hand_root = Node3D.new()
	hand_root.position = Vector3(0.32, -0.3, -0.6)
	hand_root.rotation = Vector3(1.1, -0.3, 0)
	cam.add_child(hand_root)
	add_child(player)


# ---------------- Tasolar ----------------
func _spawn_tasos() -> void:
	var pairs: Array = []
	for g in SET_COUNT:
		for n in NUMBERS_PER_SET:
			pairs.append(Vector2i(g, n + 1))
	while pairs.size() < TASO_COUNT:
		pairs.append(Vector2i(randi() % SET_COUNT, randi() % NUMBERS_PER_SET + 1))
	pairs.shuffle()
	for i in pairs.size():
		var p: Vector2i = pairs[i]
		var holo := randf() < HOLO_CHANCE
		tasos.append({"grp": p.x, "num": p.y, "holo": holo})
		if holo:
			holo_list.append(i)
		var ang := randf() * TAU
		var rr := sqrt(randf()) * PILE_R
		var heap := PILE_HEIGHT * (1.0 - rr / PILE_R)
		var pos := Vector3(cos(ang) * rr, BASE_Y + randf() * heap, sin(ang) * rr)
		var b := Basis(Vector3.UP, randf() * TAU) * Basis(Vector3.RIGHT, randf_range(-0.45, 0.45))
		pile_xf.append(Transform3D(b, pos))
		in_pile.append(true)


func _build_pile() -> void:
	pile_mm = MultiMesh.new()
	pile_mm.transform_format = MultiMesh.TRANSFORM_3D
	pile_mm.use_colors = true
	pile_mm.mesh = taso_mesh
	pile_mm.instance_count = tasos.size()
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = pile_mm
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.6
	mmi.material_override = m
	add_child(mmi)
	for i in tasos.size():
		pile_mm.set_instance_transform(i, pile_xf[i])
	_recolor_pile()

	# Holo dedektörü halkaları: derinlik testi yok, yığının içinden görünür
	var torus := TorusMesh.new()
	torus.inner_radius = TASO_R + 0.01
	torus.outer_radius = TASO_R + 0.04
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


func _recolor_pile() -> void:
	var reveal: bool = skills["renk"]["level"] > 0
	for i in tasos.size():
		var c: Color = SET_COLORS[tasos[i]["grp"]] if reveal else PLAIN
		pile_mm.set_instance_color(i, c)


func _refresh_holo() -> void:
	for k in holo_list.size():
		var i := holo_list[k]
		holo_mm.set_instance_transform(k, pile_xf[i] if in_pile[i] else hidden_xf)


func _take(i: int) -> void:
	in_pile[i] = false
	pile_mm.set_instance_transform(i, hidden_xf)
	hand.append(i)


func _put_in_pile(i: int, xf: Transform3D) -> void:
	pile_xf[i] = xf
	in_pile[i] = true
	pile_mm.set_instance_transform(i, xf)


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
	var speed := MOVE_SPEED * (1.7 if Input.is_key_pressed(KEY_SHIFT) else 1.0)
	player.velocity.x = d.x * speed
	player.velocity.z = d.z * speed
	if not player.is_on_floor():
		player.velocity.y -= GRAVITY * delta
	player.move_and_slide()
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
		if event.button_index == MOUSE_BUTTON_LEFT:
			_on_use()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_drop_hand()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			KEY_Q:
				_drop_hand()
			KEY_R:
				get_tree().reload_current_scene()
			KEY_1:
				_try_buy("renk")
			KEY_2:
				_try_buy("oto")
			KEY_3:
				_try_buy("avuc")
			KEY_4:
				_try_buy("holo")


func _find_target() -> Dictionary:
	var o := cam.global_position
	var d := -cam.global_transform.basis.z
	var best_t := REACH
	var res := {"kind": ""}
	for i in tasos.size():
		if not in_pile[i]:
			continue
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
				_say("Elin dolu! Vitrine yerleştir ya da Q ile bırak")
				return
			_grab(target["idx"])
		"shelf":
			if hand.is_empty():
				_say("Elin boş")
				return
			_use_shelf(target["body"], target["point"])
		"copy":
			_use_copy()


func _grab(first: int) -> void:
	var cap := _cap()
	var center := pile_xf[first].origin
	_take(first)
	if hand.size() < cap:
		var near: Array = []
		for i in tasos.size():
			if in_pile[i] and pile_xf[i].origin.distance_to(center) <= GRAB_RADIUS:
				near.append(i)
		near.sort_custom(func(a, b): return pile_xf[a].origin.distance_to(center) < pile_xf[b].origin.distance_to(center))
		for i in near:
			if hand.size() >= cap:
				break
			_take(i)
	_refresh_holo()
	_rebuild_hand()


func _use_shelf(body: Node, hp: Vector3) -> void:
	var g: int = body.get_meta("grp")
	var shelf: Node3D = shelves[g]
	var slot := _nearest_slot(shelf.to_local(hp))
	var auto: bool = skills["oto"]["level"] > 0
	var keep: Array = []
	var cnt := 0
	for i in hand:
		var t: Dictionary = tasos[i]
		var n: int = t["num"] - 1
		if t["grp"] == g and slots[g][n] == -1 and (auto or n == slot):
			_place(i, g)
			cnt += 1
		else:
			keep.append(i)
	hand = keep
	if cnt == 0:
		_say("Elindekilerin hiçbiri bu vitrine ait değil" if auto else "Yanlış yer!")
	_rebuild_hand()


func _place(i: int, g: int) -> void:
	var t: Dictionary = tasos[i]
	var n: int = t["num"] - 1
	slots[g][n] = i
	placed += 1
	var mi := MeshInstance3D.new()
	mi.mesh = taso_mesh
	mi.material_override = holo_mats[g] if t["holo"] else set_mats[g]
	mi.position = _slot_local(n) + Vector3(0, 0, 0.009)
	mi.rotation.x = PI / 2
	var shelf: Node3D = shelves[g]
	shelf.add_child(mi)
	var lb: Label3D = slot_labels[g][n]
	lb.position.z = 0.07
	lb.modulate = Color(0.05, 0.05, 0.05, 1)
	coins += COIN_HOLO if t["holo"] else COIN_PLACE
	if t["holo"]:
		_say("HOLO! +%d jeton" % COIN_HOLO)
	_update_title(g)
	var full := true
	for v in slots[g]:
		if v == -1:
			full = false
			break
	if full:
		coins += COIN_ALBUM
		_say("%s vitrini tamam! +%d" % [SET_NAMES[g], COIN_ALBUM])
	if placed == SET_COUNT * NUMBERS_PER_SET:
		finished = true


func _use_copy() -> void:
	if hand.is_empty():
		_say("Kopyaları buraya at")
		return
	var keep: Array = []
	var cnt := 0
	for i in hand:
		var t: Dictionary = tasos[i]
		if slots[t["grp"]][t["num"] - 1] != -1:
			copies += 1
			cnt += 1
			coins += COIN_COPY
		else:
			keep.append(i)
	hand = keep
	if cnt > 0:
		_say("+%d kopya kutuya gitti" % cnt)
	if not keep.is_empty():
		_say("Bazılarının vitrinde yeri boş, kopya değil!")
	_rebuild_hand()


func _drop_hand() -> void:
	if hand.is_empty():
		return
	var pt := player.global_position - player.global_transform.basis.z * 1.0
	pt.y = 0.0
	var kind: String = target.get("kind", "")
	if kind == "taso" or kind == "floor":
		pt = target["point"]
	var spread := 0.12 * sqrt(float(hand.size()))
	for k in hand.size():
		var i: int = hand[k]
		var off := Vector3.ZERO if k == 0 else Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * spread
		var pos := pt + off
		pos.y = maxf(pt.y, 0.0) + BASE_Y + k * TASO_H * 0.5
		var b := Basis(Vector3.UP, randf() * TAU) * Basis(Vector3.RIGHT, randf_range(-0.25, 0.25))
		_put_in_pile(i, Transform3D(b, pos))
	hand.clear()
	_refresh_holo()
	_rebuild_hand()


func _rebuild_hand() -> void:
	for c in hand_root.get_children():
		c.queue_free()
	var reveal: bool = skills["renk"]["level"] > 0
	for k in hand.size():
		var t: Dictionary = tasos[hand[k]]
		var g: int = t["grp"]
		var mi := MeshInstance3D.new()
		mi.mesh = taso_mesh
		if reveal:
			mi.material_override = holo_mats[g] if t["holo"] else set_mats[g]
		else:
			mi.material_override = plain_holo_mat if t["holo"] else plain_mat
		mi.position = Vector3(k * 0.012, k * (TASO_H + 0.002), -k * 0.008)
		hand_root.add_child(mi)


func _try_buy(key: String) -> void:
	var sk: Dictionary = skills[key]
	var lvl: int = sk["level"]
	var costs: Array = sk["cost"]
	if lvl >= costs.size():
		_say("%s zaten en üst seviyede" % sk["name"])
		return
	if key == "avuc" and skills["oto"]["level"] == 0:
		_say("Önce Otomatik Numara gerekli")
		return
	var c: int = costs[lvl]
	if coins < c:
		_say("Yeterli jeton yok (%d gerekli)" % c)
		return
	coins -= c
	sk["level"] = lvl + 1
	_say("%s açıldı!" % sk["name"])
	if key == "renk":
		_recolor_pile()
		_rebuild_hand()


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
	hud_msg = _mk_label(layer, Vector2(400, 380), 24, Color(1, 0.95, 0.7))
	hud_msg.size = Vector2(800, 34)
	hud_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_center = _mk_label(layer, Vector2(300, 250), 40, Color("ffd36b"))
	hud_center.size = Vector2(1000, 120)
	hud_center.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_hand = _mk_label(layer, Vector2(20, 50), 18, Color(1, 1, 1, 0.85))
	hud_skills = _mk_label(layer, Vector2(20, 760), 17, Color(1, 1, 1, 0.9))
	var help := _mk_label(layer, Vector2(1060, 14), 14, Color(1, 1, 1, 0.6))
	help.text = "WASD yürü  •  Shift koş  •  Fare bak\nSol tık: taso al / vitrine yerleştir / kopya kutusuna at\nSağ tık veya Q: elindekileri baktığın yere bırak\n1-4: yetenek satın al  •  R: yeniden  •  Esc: fareyi bırak"


func _update_hud() -> void:
	var total := SET_COUNT * NUMBERS_PER_SET
	var on_floor := 0
	for b in in_pile:
		if b:
			on_floor += 1
	var s := int(elapsed)
	hud_stats.text = "Jeton: %d      Vitrinde: %d/%d      Yığında: %d      Kopya: %d      Süre: %02d:%02d" % [coins, placed, total, on_floor, copies, floori(s / 60.0), s % 60]

	var parts: Array = []
	for k in mini(hand.size(), 12):
		var t: Dictionary = tasos[hand[k]]
		parts.append("%s%d%s" % [SET_LETTERS[t["grp"]], t["num"], "*" if t["holo"] else ""])
	hud_hand.text = "Elde (%d/%d): %s" % [hand.size(), _cap(), ", ".join(parts)]

	var kind: String = target.get("kind", "")
	match kind:
		"taso":
			var t: Dictionary = tasos[target["idx"]]
			var g: int = t["grp"]
			var name_txt: String = SET_NAMES[g] if skills["renk"]["level"] > 0 else "?"
			hud_info.text = "%s %d   (%s)%s" % [SET_LETTERS[g], t["num"], name_txt, "   HOLO" if t["holo"] else ""]
		"shelf":
			var body: Node = target["body"]
			var g: int = body.get_meta("grp")
			var shelf: Node3D = shelves[g]
			var n := _nearest_slot(shelf.to_local(target["point"]))
			var slot_txt := "" if n == -1 else ("   yuva %d %s" % [n + 1, "(boş)" if slots[g][n] == -1 else "(dolu)"])
			hud_info.text = "%s vitrini%s" % [SET_NAMES[g], slot_txt]
		"copy":
			hud_info.text = "Kopya Kutusu  (+%d jeton/adet)" % COIN_COPY
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
