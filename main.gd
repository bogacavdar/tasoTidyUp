extends Node2D
## Taso Kaosu — Aşama 1 "çirkin prototip".
## Amaç: binlerce tasoyu kaostan albümlere dizmek eğlenceli mi, onu test etmek.
## Her şey tek script'te ve _draw() ile çiziliyor; çizim/varlık yok.

# ---------------- Ayarlar ----------------
const SET_COUNT := 4
const NUMBERS_PER_SET := 40
const TASO_COUNT := 500
const HOLO_CHANCE := 0.05

const FLOOR_RECT := Rect2(20, 70, 960, 810)
const TASO_R := 18.0
const SLOT_R := 13.0
const SLOT_GAP := 30.0
const ALBUM_ORIGIN := Vector2(1010, 70)
const ALBUM_COLS := 10
const ALBUM_H := 155.0
const GRAB_RADIUS := 45.0

const SKILL_ORIGIN := Vector2(1330, 70)
const SKILL_SIZE := Vector2(250, 72)
const SKILL_GAP := 80.0
const COPY_RECT := Rect2(1330, 420, 250, 110)

const SET_NAMES := ["Kor Vadisi", "Derin Su", "Taş Kök", "Gece Rüzgârı"]
const SET_LETTERS := ["K", "D", "T", "G"]
const SET_COLORS := [Color("e0603a"), Color("3a8fe0"), Color("7bb04a"), Color("9a6ae6")]
const PLAIN := Color("d9cfb8")

const SKILL_ORDER := ["renk", "oto", "avuc", "holo"]
const AVUC_CAP := [1, 3, 6, 12]

# Ödüller
const COIN_PLACE := 2
const COIN_HOLO := 10
const COIN_COPY := 1
const COIN_ALBUM := 50

# ---------------- Durum ----------------
var tasos: Array = []        # her taso bir Dictionary: grp, num, holo, pos, state
var floor_order: Array = []  # yerdeki taso indeksleri; sonuncusu en üstte
var hand: Array = []         # eldeki taso indeksleri
var albums: Array = []       # albums[grp][num-1] = taso indeksi ya da -1
var coins := 0
var placed := 0
var copies := 0
var elapsed := 0.0
var anim := 0.0
var finished := false
var message := ""
var message_time := 0.0
var skills := {}


func _ready() -> void:
	randomize()
	_setup()


func _setup() -> void:
	skills = {
		"renk": {"name": "Renk Gözü", "desc": "Tasolar setinin rengini gösterir", "cost": [20], "level": 0},
		"oto": {"name": "Otomatik Numara", "desc": "Albüme bırakınca kendi yuvasına oturur", "cost": [40], "level": 0},
		"avuc": {"name": "Avuç", "desc": "Tek seferde daha çok taso al (1 / 3 / 6 / 12)", "cost": [60, 150, 400], "level": 0},
		"holo": {"name": "Holo Dedektörü", "desc": "Gömülü holo tasolar bile parlar", "cost": [80], "level": 0},
	}
	tasos.clear()
	floor_order.clear()
	hand.clear()
	albums.clear()
	coins = 0
	placed = 0
	copies = 0
	elapsed = 0.0
	finished = false

	for g in SET_COUNT:
		var row: Array = []
		row.resize(NUMBERS_PER_SET)
		row.fill(-1)
		albums.append(row)

	# Her (set, numara) en az bir kez olsun; gerisi kopya.
	var pairs: Array = []
	for g in SET_COUNT:
		for n in NUMBERS_PER_SET:
			pairs.append(Vector2i(g, n + 1))
	while pairs.size() < TASO_COUNT:
		pairs.append(Vector2i(randi() % SET_COUNT, randi() % NUMBERS_PER_SET + 1))
	pairs.shuffle()

	var inner := FLOOR_RECT.grow(-TASO_R)
	for i in pairs.size():
		var p: Vector2i = pairs[i]
		tasos.append({
			"grp": p.x,
			"num": p.y,
			"holo": randf() < HOLO_CHANCE,
			"pos": Vector2(randf_range(inner.position.x, inner.end.x), randf_range(inner.position.y, inner.end.y)),
			"state": "floor",
		})
		floor_order.append(i)
	_say("Kaos seni bekliyor. İlk tasoyu al!")


# ---------------- Döngü ----------------
func _process(delta: float) -> void:
	anim += delta
	if not finished:
		elapsed += delta
	if message_time > 0.0:
		message_time -= delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_setup()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var p := get_global_mouse_position()
		if event.pressed:
			_on_press(p)
		else:
			_on_release(p)


func _on_press(p: Vector2) -> void:
	# Yetenek butonları
	for i in SKILL_ORDER.size():
		if _skill_rect(i).has_point(p):
			_try_buy(SKILL_ORDER[i])
			return
	if not hand.is_empty():
		return
	var top := _floor_taso_at(p)
	if top == -1:
		return
	_take(top)
	var cap: int = AVUC_CAP[skills["avuc"]["level"]]
	if cap > 1:
		var center: Vector2 = tasos[top]["pos"]
		var idx := floor_order.size() - 1
		while idx >= 0 and hand.size() < cap:
			var ti: int = floor_order[idx]
			var tp: Vector2 = tasos[ti]["pos"]
			if tp.distance_to(center) <= GRAB_RADIUS:
				_take(ti)
			idx -= 1


func _take(ti: int) -> void:
	floor_order.erase(ti)
	tasos[ti]["state"] = "hand"
	hand.append(ti)


func _on_release(p: Vector2) -> void:
	if hand.is_empty():
		return
	var leftover: Array = []
	var placed_now := 0

	if COPY_RECT.has_point(p):
		var copied := 0
		for ti in hand:
			var t: Dictionary = tasos[ti]
			if albums[t["grp"]][t["num"] - 1] != -1:
				t["state"] = "copy"
				copies += 1
				copied += 1
				coins += COIN_COPY
			else:
				leftover.append(ti)
		if copied > 0:
			_say("+%d kopya kutuya gitti" % copied)
		if not leftover.is_empty():
			_say("Bunların albümde yeri boş, kopya değil!")
		_return_to_floor(leftover)
		hand.clear()
		return

	var g := _album_at(p)
	if g != -1:
		var slot := _slot_at(g, p)
		var auto: bool = skills["oto"]["level"] > 0
		for ti in hand:
			var t: Dictionary = tasos[ti]
			var fits: bool = t["grp"] == g and albums[g][t["num"] - 1] == -1
			if fits and (auto or slot == t["num"] - 1):
				_place(ti)
				placed_now += 1
			else:
				leftover.append(ti)
		if placed_now == 0:
			_say("Yanlış yer!")
		_return_to_floor(leftover)
		hand.clear()
		return

	if FLOOR_RECT.has_point(p):
		# Yere bırak: oyuncu kendi ara yığınlarını yapabilir.
		var inner := FLOOR_RECT.grow(-TASO_R)
		for i in hand.size():
			var ti: int = hand[i]
			var spread := 0.0 if i == 0 else 10.0 * sqrt(float(hand.size()))
			var np := p + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * spread
			np.x = clampf(np.x, inner.position.x, inner.end.x)
			np.y = clampf(np.y, inner.position.y, inner.end.y)
			tasos[ti]["pos"] = np
		_return_to_floor(hand)
		hand.clear()
		return

	_return_to_floor(hand)
	hand.clear()


func _return_to_floor(list: Array) -> void:
	for ti in list:
		tasos[ti]["state"] = "floor"
		floor_order.append(ti)


func _place(ti: int) -> void:
	var t: Dictionary = tasos[ti]
	var g: int = t["grp"]
	albums[g][t["num"] - 1] = ti
	t["state"] = "album"
	placed += 1
	coins += COIN_HOLO if t["holo"] else COIN_PLACE
	if t["holo"]:
		_say("HOLO! +%d" % COIN_HOLO)
	if _album_count(g) == NUMBERS_PER_SET:
		coins += COIN_ALBUM
		_say("%s albümü tamam! +%d" % [SET_NAMES[g], COIN_ALBUM])
	if placed == SET_COUNT * NUMBERS_PER_SET:
		finished = true


func _try_buy(key: String) -> void:
	var sk: Dictionary = skills[key]
	var lvl: int = sk["level"]
	var costs: Array = sk["cost"]
	if lvl >= costs.size():
		_say("Zaten en üst seviye")
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


func _say(s: String) -> void:
	message = s
	message_time = 2.5


# ---------------- Yardımcılar ----------------
func _floor_taso_at(p: Vector2) -> int:
	var i := floor_order.size() - 1
	while i >= 0:
		var ti: int = floor_order[i]
		var tp: Vector2 = tasos[ti]["pos"]
		if tp.distance_to(p) <= TASO_R:
			return ti
		i -= 1
	return -1


func _album_rect(g: int) -> Rect2:
	return Rect2(ALBUM_ORIGIN + Vector2(0, g * ALBUM_H), Vector2(ALBUM_COLS * SLOT_GAP, ALBUM_H - 6))


func _album_at(p: Vector2) -> int:
	for g in SET_COUNT:
		if _album_rect(g).has_point(p):
			return g
	return -1


func _slot_center(g: int, n: int) -> Vector2:
	var c := n % ALBUM_COLS
	var r := floori(float(n) / ALBUM_COLS)
	return ALBUM_ORIGIN + Vector2(15 + c * SLOT_GAP, g * ALBUM_H + 43 + r * SLOT_GAP)


func _slot_at(g: int, p: Vector2) -> int:
	for n in NUMBERS_PER_SET:
		if _slot_center(g, n).distance_to(p) <= SLOT_R + 2:
			return n
	return -1


func _album_count(g: int) -> int:
	var c := 0
	for v in albums[g]:
		if v != -1:
			c += 1
	return c


func _skill_rect(i: int) -> Rect2:
	return Rect2(SKILL_ORIGIN + Vector2(0, i * SKILL_GAP), SKILL_SIZE)


# ---------------- Çizim ----------------
func _draw() -> void:
	draw_rect(Rect2(0, 0, 1600, 900), Color("1d1a18"))
	draw_rect(FLOOR_RECT, Color("3b2f26"))
	draw_rect(FLOOR_RECT, Color("5a4636"), false, 3.0)

	var reveal: bool = skills["renk"]["level"] > 0
	for ti in floor_order:
		_draw_taso(ti, tasos[ti]["pos"], TASO_R, reveal, false)

	# Holo dedektörü: gömülü olsalar bile üstte parlasınlar.
	if skills["holo"]["level"] > 0:
		var pulse := 0.5 + 0.5 * sin(anim * 5.0)
		for ti in floor_order:
			if tasos[ti]["holo"]:
				var c: Vector2 = tasos[ti]["pos"]
				draw_arc(c, TASO_R + 4 + pulse * 3, 0, TAU, 28, Color(1, 1, 0.6, 0.5 + 0.5 * pulse), 3.0)

	_draw_albums()
	_draw_skills()
	_draw_copy_box()
	_draw_hud()

	# Eldeki tasolar en üstte
	if not hand.is_empty():
		var m := get_global_mouse_position()
		for i in hand.size():
			_draw_taso(hand[i], m + Vector2(i * 5, -i * 5), TASO_R + 2, reveal, true)

	if finished:
		draw_rect(Rect2(0, 0, 1600, 900), Color(0, 0, 0, 0.6))
		_text(Vector2(800, 400), "TÜM ALBÜMLER TAMAM!", 48, Color("ffd36b"), 1200)
		_text(Vector2(800, 460), "Süre: %s   Jeton: %d   Kopya: %d" % [_time_str(), coins, copies], 24, Color.WHITE, 1200)
		_text(Vector2(800, 510), "R ile yeniden başla", 20, Color(1, 1, 1, 0.7), 1200)


func _draw_taso(ti: int, center: Vector2, r: float, reveal: bool, strong_holo: bool) -> void:
	var t: Dictionary = tasos[ti]
	var g: int = t["grp"]
	var base: Color = SET_COLORS[g] if reveal else PLAIN
	draw_circle(center + Vector2(1.5, 2.5), r, Color(0, 0, 0, 0.3))
	draw_circle(center, r, base)
	draw_arc(center, r, 0, TAU, 24, base.darkened(0.5), 2.0)
	if t["holo"]:
		var hue := fmod(anim * 0.4 + ti * 0.137, 1.0)
		var hc := Color.from_hsv(hue, 0.8, 1.0, 1.0 if strong_holo else 0.45)
		draw_arc(center, r - 3, 0, TAU, 24, hc, 3.0 if strong_holo else 1.5)
	_text(center + Vector2(0, -r * 0.08), str(t["num"]), int(r * 0.85), Color(0.08, 0.08, 0.08))
	if r >= 15:
		_text(center + Vector2(0, r * 0.62), SET_LETTERS[g], int(r * 0.5), Color(0.1, 0.1, 0.1, 0.8))


func _draw_albums() -> void:
	var m := get_global_mouse_position()
	var holding := not hand.is_empty()
	var auto: bool = skills["oto"]["level"] > 0
	for g in SET_COUNT:
		var rect := _album_rect(g)
		var col: Color = SET_COLORS[g]
		var hover := holding and rect.has_point(m)
		draw_rect(rect, Color("2a2522") if not hover else Color("3a332e"))
		draw_rect(rect, col.darkened(0.2) if not hover else col.lightened(0.3), false, 2.0)
		_label(rect.position + Vector2(8, 20), "%s (%s)   %d/%d" % [SET_NAMES[g], SET_LETTERS[g], _album_count(g), NUMBERS_PER_SET], 14, col.lightened(0.3))
		var hover_slot := _slot_at(g, m) if (hover and not auto) else -1
		for n in NUMBERS_PER_SET:
			var c := _slot_center(g, n)
			var ti: int = albums[g][n]
			if ti == -1:
				draw_circle(c, SLOT_R, Color(1, 1, 1, 0.14 if n == hover_slot else 0.05))
				draw_arc(c, SLOT_R, 0, TAU, 20, Color(1, 1, 1, 0.18), 1.0)
				_text(c, str(n + 1), 10, Color(1, 1, 1, 0.3))
			else:
				_draw_taso(ti, c, SLOT_R, true, true)


func _draw_skills() -> void:
	_label(SKILL_ORIGIN + Vector2(0, -8), "YETENEKLER", 14, Color(1, 1, 1, 0.6))
	for i in SKILL_ORDER.size():
		var sk: Dictionary = skills[SKILL_ORDER[i]]
		var rect := _skill_rect(i)
		var costs: Array = sk["cost"]
		var lvl: int = sk["level"]
		var maxed := lvl >= costs.size()
		var cost: int = 0 if maxed else costs[lvl]
		var bg := Color("2f3a2c") if maxed else (Color("2c3b4a") if coins >= cost else Color("2a2522"))
		draw_rect(rect, bg)
		draw_rect(rect, Color(1, 1, 1, 0.2), false, 1.0)
		var lvl_txt := "" if costs.size() == 1 else "  Sv %d/%d" % [lvl, costs.size()]
		_label(rect.position + Vector2(8, 20), sk["name"] + lvl_txt, 15, Color.WHITE)
		_label(rect.position + Vector2(8, 40), sk["desc"], 11, Color(1, 1, 1, 0.65))
		var price := "AÇIK" if maxed else "%d jeton" % cost
		_label(rect.position + Vector2(8, 62), price, 13, Color("ffd36b") if not maxed else Color("9be07a"))


func _draw_copy_box() -> void:
	var hover := not hand.is_empty() and COPY_RECT.has_point(get_global_mouse_position())
	draw_rect(COPY_RECT, Color("3a2f3f") if hover else Color("2a2522"))
	draw_rect(COPY_RECT, Color("b08ad6"), false, 2.0)
	_text(COPY_RECT.get_center() + Vector2(0, -14), "KOPYA KUTUSU", 16, Color("d9c2f0"), 240)
	_text(COPY_RECT.get_center() + Vector2(0, 14), "%d kopya  (+%d jeton/adet)" % [copies, COIN_COPY], 13, Color(1, 1, 1, 0.7), 240)


func _draw_hud() -> void:
	var cap: int = AVUC_CAP[skills["avuc"]["level"]]
	var total := SET_COUNT * NUMBERS_PER_SET
	_label(Vector2(24, 40), "Jeton: %d" % coins, 22, Color("ffd36b"))
	_label(Vector2(200, 40), "Albümde: %d/%d" % [placed, total], 18, Color.WHITE)
	_label(Vector2(400, 40), "Yerde: %d" % floor_order.size(), 18, Color(1, 1, 1, 0.8))
	_label(Vector2(540, 40), "Avuç: %d" % cap, 18, Color(1, 1, 1, 0.8))
	_label(Vector2(660, 40), "Süre: %s" % _time_str(), 18, Color(1, 1, 1, 0.8))
	if message_time > 0.0:
		var a := clampf(message_time, 0.0, 1.0)
		_text(Vector2(1180, 34), message, 18, Color(1, 0.95, 0.7, a), 700)
	var help := [
		"Sol tık basılı tut: taso al, albümdeki doğru yuvaya bırak",
		"Yere bırakarak kendi ara yığınlarını yapabilirsin",
		"Albümde yeri dolu olanlar kopyadır: Kopya Kutusu'na at",
		"R: yeniden başla",
	]
	for i in help.size():
		_label(Vector2(1330, 560 + i * 20), help[i], 12, Color(1, 1, 1, 0.5))


func _time_str() -> String:
	var s := int(elapsed)
	return "%02d:%02d" % [floori(s / 60.0), s % 60]


func _text(center: Vector2, s: String, size: int, col: Color, width: float = 200.0) -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(center.x - width / 2.0, center.y + size * 0.35), s, HORIZONTAL_ALIGNMENT_CENTER, width, size, col)


func _label(pos: Vector2, s: String, size: int, col: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
