extends Control

const SAVE = "user://adventure.json"
const PARTY_ATLAS: Texture2D = preload("res://assets/party_atlas.png")
const GAME_COVER: Texture2D = preload("res://assets/game_cover.jpg")
const HEROES = ["Kazuma", "Aqua", "Darkness", "Megumin", "Chris", "Wiz"]
const RARITY = ["R", "SR", "SR", "SSR", "R", "SR"]
const POWER = [24, 18, 22, 42, 26, 34]
# Atlas order: Aqua, Kazuma, Megumin, Darkness
const SPRITE_INDEX = [1, 0, 3, 2, -1, -1]
const CHAPTERS = ["Um novo mundo", "Primeira aventura", "Arquimaga carmesim", "Equipe problemática", "Explosões diárias", "O general do Rei Demônio"]
const STORY = [
	"Após uma morte inesperada, Kazuma encontra Aqua e recebe uma segunda chance.",
	"Os dois chegam a Axel. Na guilda, a primeira missão os aguarda.",
	"Uma caçada a sapos gigantes coloca a dupla à prova.",
	"Com a missão concluída, uma misteriosa arquimaga se apresenta.",
	"Megumin demonstra sua magia de explosão. O grupo precisa sobreviver às consequências.",
	"Darkness, uma cruzada excêntrica, pede para entrar na equipe.",
	"A equipe aceita uma missão contra monstros na estrada.",
	"Uma nova caçada exige que todos cooperem.",
	"Megumin encontra um castelo aparentemente abandonado para treinar sua magia.",
	"Uma série de explosões provoca uma ameaça desconhecida.",
	"Os aventureiros de Axel sentem que algo perigoso está se aproximando.",
	"Um cavaleiro sem cabeça aparece diante da cidade. Beldia exige explicações. Continua..."
]

const INK = Color("#4a2c27")
const PAPER = Color("#f5e8c8")
const PAPER_DARK = Color("#e8d2a4")
const GOLD = Color("#b77b37")
const BLUE = Color("#315c91")
const DEEP_BLUE = Color("#1d2b4a")
const RED = Color("#8f3543")

var crystals = 3000
var progress = 0
var pity = 0
var owned = [0, 1]
var levels = [1, 1, 1, 1, 1, 1]
var team = [0, 1]
var coins = 100
var profile_name = "Aventureiro"
var profile_icon = 1
var profile_title = "Abençoado pela Deusa Aqua"
var unlocked_titles = ["Aventureiro de Axel", "Abençoado pela Deusa Aqua"]
var last_daily_claim = ""
var music_enabled = true
var bgm_player: AudioStreamPlayer
var current_music_path = ""
var battle_sprites: Dictionary = {}
var battle_enemy_panel: Control
var root: VBoxContainer
var battle_hp = 0
var battle_max = 0
var party_hp = 0
var mana = 0
var turn = 0
var stage = 0
var enemy = ""
var fighting = false
var busy = false
var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	load_game()
	start_background_music()
	show_splash()

func store():
	var f = FileAccess.open(SAVE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"crystals": crystals, "progress": progress, "pity": pity, "owned": owned, "levels": levels, "team": team, "coins": coins, "profile_name": profile_name, "profile_icon": profile_icon, "profile_title": profile_title, "unlocked_titles": unlocked_titles, "last_daily_claim": last_daily_claim, "music_enabled": music_enabled}))

func load_game():
	if not FileAccess.file_exists(SAVE):
		return
	var f = FileAccess.open(SAVE, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		crystals = int(d.get("crystals", 3000))
		progress = int(d.get("progress", 0))
		pity = int(d.get("pity", 0))
		coins = int(d.get("coins", 100))
		owned = d.get("owned", [0, 1])
		levels = d.get("levels", [1, 1, 1, 1, 1, 1])
		team = d.get("team", [0, 1])
		profile_name = str(d.get("profile_name", "Aventureiro"))
		profile_icon = int(d.get("profile_icon", 1))
		profile_title = str(d.get("profile_title", "Abençoado pela Deusa Aqua"))
		unlocked_titles = d.get("unlocked_titles", ["Aventureiro de Axel", "Abençoado pela Deusa Aqua"])
		last_daily_claim = str(d.get("last_daily_claim", ""))
		music_enabled = bool(d.get("music_enabled", true))
	if not unlocked_titles.has("Abençoado pela Deusa Aqua"):
		unlocked_titles.append("Abençoado pela Deusa Aqua")
	if not unlocked_titles.has(profile_title):
		profile_title = "Abençoado pela Deusa Aqua"
	if not owned.has(profile_icon):
		profile_icon = int(owned[0]) if not owned.is_empty() else 0

func panel_style(color: Color = PAPER, border_color: Color = GOLD) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border_color
	style.set_border_width_all(4)
	style.set_corner_radius_all(0)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func clear_screen(title: String, back: bool = true):
	for c in get_children():
		remove_child(c)
		c.queue_free()

	var bg = ColorRect.new()
	bg.color = DEEP_BLUE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var outer = MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for key in ["margin_top", "margin_bottom", "margin_left", "margin_right"]:
		outer.add_theme_constant_override(key, 18)
	add_child(outer)

	var frame = PanelContainer.new()
	frame.add_theme_stylebox_override("panel", panel_style(PAPER, Color("#7d4a2d")))
	outer.add_child(frame)

	var inner = MarginContainer.new()
	for key in ["margin_top", "margin_bottom", "margin_left", "margin_right"]:
		inner.add_theme_constant_override(key, 12)
	frame.add_child(inner)

	root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	inner.add_child(root)

	var head = HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	root.add_child(head)
	if back:
		add_button(head, "◀ VOLTAR", show_home, Vector2(138, 48))
	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_color_override("font_color", INK)
	title_label.add_theme_font_size_override("font_size", 30)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title_label)
	var cash = Label.new()
	cash.text = "◆ %d     ● %d" % [crystals, coins]
	cash.add_theme_color_override("font_color", Color("#75451f"))
	cash.add_theme_font_size_override("font_size", 20)
	head.add_child(cash)

func text(parent: Node, value: String, size: int = 25) -> Label:
	var l = Label.new()
	l.text = value
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", INK)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l

func add_button(parent: Node, label: String, callback: Callable, minimum: Vector2 = Vector2(0, 60)) -> Button:
	var b = Button.new()
	b.text = label
	b.custom_minimum_size = minimum
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", Color("#fff3d4"))
	b.add_theme_color_override("font_hover_color", Color("#ffffff"))
	b.add_theme_color_override("font_pressed_color", Color("#ffe08a"))
	var normal = panel_style(BLUE, Color("#182b4b"))
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hover = panel_style(Color("#477caf"), Color("#d49a4e"))
	var pressed = panel_style(Color("#263f69"), Color("#d49a4e"))
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func add_section(parent: Node, heading: String) -> VBoxContainer:
	var box = PanelContainer.new()
	box.add_theme_stylebox_override("panel", panel_style(PAPER_DARK, GOLD))
	parent.add_child(box)
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	box.add_child(col)
	text(col, heading, 23)
	return col

func character_texture(id: int) -> Texture2D:
	if id < 0 or id >= SPRITE_INDEX.size() or SPRITE_INDEX[id] < 0:
		return null
	var atlas = AtlasTexture.new()
	atlas.atlas = PARTY_ATLAS
	atlas.region = Rect2(SPRITE_INDEX[id] * 112, 0, 112, 128)
	return atlas

func add_character_sprite(parent: Node, id: int, size: Vector2 = Vector2(150, 190)):
	var frame = PanelContainer.new()
	frame.custom_minimum_size = size
	frame.add_theme_stylebox_override("panel", panel_style(Color("#ead9b2"), Color("#9a6336")))
	parent.add_child(frame)
	var tex = character_texture(id)
	if tex != null:
		var pic = TextureRect.new()
		pic.texture = tex
		pic.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pic.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pic.size_flags_vertical = Control.SIZE_EXPAND_FILL
		frame.add_child(pic)
	else:
		var placeholder = Label.new()
		placeholder.text = "✦\n" + HEROES[id]
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		placeholder.add_theme_font_size_override("font_size", 28)
		placeholder.add_theme_color_override("font_color", INK)
		frame.add_child(placeholder)
	return frame


func add_art_panel(parent: Node, art_path: String, height: float = 160.0, caption: String = "") -> Control:
	var frame = PanelContainer.new()
	frame.custom_minimum_size = Vector2(0, height)
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.add_theme_stylebox_override("panel", panel_style(Color("#1d2b4a"), GOLD))
	parent.add_child(frame)
	var surface = Control.new()
	surface.custom_minimum_size = Vector2(0, height)
	frame.add_child(surface)
	var picture = TextureRect.new()
	picture.texture = load(art_path)
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	surface.add_child(picture)
	var shade = ColorRect.new()
	shade.color = Color(0.02, 0.04, 0.12, 0.28)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.add_child(shade)
	if not caption.is_empty():
		var label = Label.new()
		label.text = caption
		label.position = Vector2(16, height - 42)
		label.add_theme_font_size_override("font_size", 23)
		label.add_theme_color_override("font_color", Color("#fff1d2"))
		label.add_theme_color_override("font_outline_color", Color("#17223b"))
		label.add_theme_constant_override("outline_size", 5)
		surface.add_child(label)
	return frame

func add_character_banner(parent: Node, heading: String, subtitle: String, hero_id: int, art_path: String, height: float = 142.0, action_label: String = "", callback: Callable = Callable()) -> Control:
	var banner = PanelContainer.new()
	banner.custom_minimum_size = Vector2(0, height)
	banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	banner.add_theme_stylebox_override("panel", panel_style(Color("#1d2b4a"), GOLD))
	parent.add_child(banner)
	var surface = Control.new()
	surface.custom_minimum_size = Vector2(0, height)
	banner.add_child(surface)
	var backdrop = TextureRect.new()
	backdrop.texture = load(art_path)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	surface.add_child(backdrop)
	var shade = ColorRect.new()
	shade.color = Color(0.02, 0.04, 0.12, 0.42)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.add_child(shade)
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for key in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(key, 8)
	surface.add_child(margin)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)
	add_character_sprite(row, hero_id, Vector2(96, height - 18))
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(info)
	var title_label = Label.new()
	title_label.text = heading
	title_label.add_theme_font_size_override("font_size", 23)
	title_label.add_theme_color_override("font_color", Color("#fff1d2"))
	title_label.add_theme_color_override("font_outline_color", Color("#17223b"))
	title_label.add_theme_constant_override("outline_size", 4)
	info.add_child(title_label)
	var detail = Label.new()
	detail.text = subtitle
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_font_size_override("font_size", 16)
	detail.add_theme_color_override("font_color", Color("#fff5df"))
	info.add_child(detail)
	if not action_label.is_empty() and callback.is_valid():
		add_button(info, action_label, callback, Vector2(0, 42))
	return banner
func show_profile():
	clear_screen("Perfil do aventureiro")
	var box = add_section(root, "IDENTIDADE DO AVENTUREIRO")
	var hero_row = HBoxContainer.new()
	hero_row.add_theme_constant_override("separation", 14)
	box.add_child(hero_row)
	add_character_sprite(hero_row, profile_icon, Vector2(116, 132))
	var identity = VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_row.add_child(identity)
	text(identity, profile_name, 25)
	text(identity, profile_title, 19)
	text(identity, "Progresso: %d / %d missões" % [progress, STORY.size()], 17)

	text(box, "NOME DO AVENTUREIRO", 18)
	var name_edit = LineEdit.new()
	name_edit.text = profile_name
	name_edit.placeholder_text = "Digite seu nome"
	name_edit.max_length = 20
	name_edit.custom_minimum_size = Vector2(0, 52)
	box.add_child(name_edit)

	text(box, "ÍCONE DE PERFIL", 18)
	var icon_select = OptionButton.new()
	icon_select.custom_minimum_size = Vector2(0, 52)
	for id in owned:
		icon_select.add_item(HEROES[int(id)], int(id))
		if int(id) == profile_icon:
			icon_select.select(icon_select.item_count - 1)
	box.add_child(icon_select)

	text(box, "TÍTULO EQUIPADO", 18)
	var title_select = OptionButton.new()
	title_select.custom_minimum_size = Vector2(0, 52)
	for title_name in unlocked_titles:
		title_select.add_item(str(title_name))
		if str(title_name) == profile_title:
			title_select.select(title_select.item_count - 1)
	box.add_child(title_select)

	add_button(box, "SALVAR PERFIL", func():
		var clean_name = name_edit.text.strip_edges()
		if clean_name.is_empty():
			clean_name = "Aventureiro"
		profile_name = clean_name
		if icon_select.item_count > 0 and icon_select.selected >= 0:
			profile_icon = icon_select.get_item_id(icon_select.selected)
		if title_select.item_count > 0 and title_select.selected >= 0:
			profile_title = title_select.get_item_text(title_select.selected)
		store()
		show_profile()
	, Vector2(0, 60))
	var title_box = add_section(root, "TÍTULOS DESBLOQUEÁVEIS")
	for title_name in ["Aventureiro de Axel", "Abençoado pela Deusa Aqua", "Herói de Outro Mundo", "Arquimago Carmesim", "Cruzado Inabalável"]:
		var state = "DESBLOQUEADO" if unlocked_titles.has(title_name) else "BLOQUEADO"
		text(title_box, "%s  •  %s" % [title_name, state], 17)

func show_team_setup():
	clear_screen("Escolha sua equipe", false)
	var box = add_section(root, "MONTE SEU GRUPO ANTES DA AVENTURA")
	add_character_banner(box, "KAZUMA • EQUIPE", "Escolha seus companheiros antes de partir para a missão.", 0, "res://assets/banner_team_kazuma.svg", 142)
	text(box, "Escolha até 3 personagens. Você pode mudar a equipe depois na guilda.", 19)
	var slots = HBoxContainer.new()
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	slots.add_theme_constant_override("separation", 8)
	box.add_child(slots)
	for slot in range(3):
		if slot < team.size():
			add_character_sprite(slots, int(team[slot]), Vector2(76, 86))
		else:
			var empty = PanelContainer.new()
			empty.custom_minimum_size = Vector2(76, 86)
			empty.add_theme_stylebox_override("panel", panel_style(Color("#dfd0ac"), Color("#9a805d")))
			slots.add_child(empty)
			var mark = Label.new()
			mark.text = "+"
			mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			mark.add_theme_font_size_override("font_size", 30)
			mark.add_theme_color_override("font_color", INK)
			empty.add_child(mark)
	for id in owned:
		var i = int(id)
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		box.add_child(row)
		add_character_sprite(row, i, Vector2(90, 104))
		var info = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		text(info, "%s • %s • Nv. %d" % [RARITY[i], HEROES[i], levels[i]], 19)
		var action = "REMOVER" if team.has(i) else "ADICIONAR À EQUIPE"
		add_button(info, action, toggle_team_setup.bind(i), Vector2(0, 44))
	text(box, "Equipe selecionada: %d / 3" % team.size(), 19)
	var begin = add_button(box, "CONFIRMAR E COMEÇAR", show_home, Vector2(0, 64))
	begin.disabled = team.is_empty()

func toggle_team_setup(i: int):
	if team.has(i):
		if team.size() > 1:
			team.erase(i)
	elif team.size() < 3:
		team.append(i)
	store()
	show_team_setup()

func show_splash():
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var bg = TextureRect.new()
	bg.texture = load("res://assets/axel_town.svg")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(bg)
	var shade = ColorRect.new()
	shade.color = Color(0.03, 0.05, 0.12, 0.32)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var layout = VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 8)
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(layout)
	var logo = Label.new()
	logo.text = "KONOSUBA: ANOTHER WORLD"
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_font_size_override("font_size", 42)
	logo.add_theme_color_override("font_color", Color("#fff1d2"))
	logo.add_theme_color_override("font_outline_color", Color("#35203a"))
	logo.add_theme_constant_override("outline_size", 7)
	layout.add_child(logo)
	var tagline = Label.new()
	tagline.text = "Uma aventura caótica começa agora"
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_size_override("font_size", 22)
	tagline.add_theme_color_override("font_color", Color("#fff4df"))
	layout.add_child(tagline)
	var gap = Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(gap)
	var heroes = HBoxContainer.new()
	heroes.alignment = BoxContainer.ALIGNMENT_CENTER
	heroes.add_theme_constant_override("separation", 14)
	layout.add_child(heroes)
	for id in [1, 0, 3, 2]:
		var frame = add_character_sprite(heroes, id, Vector2(104, 128))
		frame.pivot_offset = Vector2(52, 64)
		var idle = create_tween().set_loops()
		idle.tween_property(frame, "scale", Vector2(1.045, 1.045), 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		idle.tween_property(frame, "scale", Vector2(0.98, 0.98), 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var profile_line = Label.new()
	profile_line.text = "%s  •  %s" % [profile_name, profile_title]
	profile_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	profile_line.add_theme_font_size_override("font_size", 17)
	profile_line.add_theme_color_override("font_color", Color("#fff1d2"))
	layout.add_child(profile_line)
	var start = add_button(layout, "TOQUE NA TELA PARA COMEÇAR", start_from_splash, Vector2(0, 72))
	start.add_theme_font_size_override("font_size", 25)
	var foot = Label.new()
	foot.text = "Toque para ouvir o nome do jogo"
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.add_theme_font_size_override("font_size", 15)
	foot.add_theme_color_override("font_color", Color("#fff1d2"))
	layout.add_child(foot)

func start_from_splash():
	show_team_setup()

func start_background_music():
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "OriginalFantasyTheme"
	get_tree().root.add_child(bgm_player)
	play_music("res://assets/title_theme.wav")

func play_music(path: String):
	if bgm_player == null:
		return
	if current_music_path == path and bgm_player.playing:
		return
	var stream = load(path)
	if stream == null:
		return
	current_music_path = path
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	bgm_player.stream = stream
	bgm_player.volume_db = -13.0
	if music_enabled:
		bgm_player.play()

func toggle_music():
	music_enabled = not music_enabled
	if bgm_player != null:
		if music_enabled:
			bgm_player.play()
		else:
			bgm_player.stop()
	store()
	show_home()

func show_home():
	play_music("res://assets/axel_theme.wav")
	busy = false
	fighting = false
	clear_screen("KonoSuba: Another World", false)
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 9)
	scroll.add_child(content)
	var intro = add_section(content, "AXEL  •  GUILDA DOS AVENTUREIROS")
	add_art_panel(intro, "res://assets/axel_town.svg", 124, "AXEL • CIDADE DOS AVENTUREIROS")
	text(intro, "Bem-vindo, %s! Sua próxima aventura começa aqui." % profile_name, 19)
	var nav = add_section(content, "ESCOLHA SEU DESTINO")
	var row1 = HBoxContainer.new()
	row1.add_theme_constant_override("separation", 10)
	nav.add_child(row1)
	add_character_banner(row1, "SUMMON", "A deusa Aqua guia suas invocações", 1, "res://assets/banner_summon_aqua.svg", 136, "INVOCAR", show_banner)
	add_character_banner(row1, "HISTÓRIA", "Darkness apresenta as missões de Axel", 2, "res://assets/banner_story_darkness.svg", 136, "AVENTURAR-SE", show_story)
	var row2 = HBoxContainer.new()
	row2.add_theme_constant_override("separation", 10)
	nav.add_child(row2)
	add_character_banner(row2, "EQUIPE", "Escolha até três aventureiros", 0, "res://assets/banner_team_kazuma.svg", 136, "EDITAR EQUIPE", show_team_setup)
	add_character_banner(row2, "EVENTOS", "Desafios e explosões com Megumin", 3, "res://assets/banner_events_megumin.svg", 136, "VER EVENTOS", show_events)
	var utility = add_section(content, "ATALHOS DA GUILDA")
	var row3 = HBoxContainer.new()
	utility.add_child(row3)
	add_button(row3, "PERSONAGENS", show_characters, Vector2(0, 54))
	add_button(row3, "RECOMPENSA DIÁRIA", daily, Vector2(0, 54))
	var row4 = HBoxContainer.new()
	utility.add_child(row4)
	add_button(row4, "MEU PERFIL", show_profile, Vector2(0, 52))
	add_button(row4, "MÚSICA: LIGADA" if music_enabled else "MÚSICA: DESLIGADA", toggle_music, Vector2(0, 52))
	text(content, "História: %d / %d missões concluídas" % [progress, STORY.size()], 17)

func show_events():
	clear_screen("Eventos • Axel")
	var box = add_section(root, "EVENTO ESPECIAL DA GUILDA")
	add_character_banner(box, "MEGUMIN • FESTIVAL DE EXPLOSÕES", "Um desafio especial está sendo preparado em Axel.", 3, "res://assets/banner_events_megumin.svg", 174)
	text(box, "Participe das atividades diárias para receber cristais e eris.", 21)
	text(box, "O próximo desafio de combate será adicionado em uma atualização futura.", 17)
	add_button(box, "VER RECOMPENSA DIÁRIA", daily, Vector2(0, 58))
	add_button(box, "VOLTAR AO LOBBY", show_home, Vector2(0, 54))

func daily():
	clear_screen("Recompensas diárias")
	var box = add_section(root, "BÔNUS DA GUILDA")
	var today = Time.get_date_dict_from_system()
	var date_key = "%04d-%02d-%02d" % [today.year, today.month, today.day]
	if last_daily_claim == date_key:
		text(box, "Você já recebeu sua recompensa de hoje. Volte amanhã!", 24)
		text(box, "Próxima recompensa: 300 cristais + 80 eris.", 20)
	else:
		text(box, "A guilda preparou uma recompensa para sua visita de hoje!", 23)
		text(box, "Recompensa: 300 cristais e 80 eris.", 21)
		add_button(box, "RESGATAR RECOMPENSA", func():
			if last_daily_claim != date_key:
				crystals += 300
				coins += 80
				last_daily_claim = date_key
				store()
			daily()
		, Vector2(0, 64))
	text(box, "O resgate fica disponível novamente quando o dia mudar no seu celular.", 17)

func show_story():
	play_music("res://assets/story_theme.wav")
	clear_screen("História • Axel")
	var box = add_section(root, "MISSÕES DA GUILDA")
	add_character_banner(box, "DARKNESS • QUADRO DE MISSÕES", "A cruzada apresenta os trabalhos disponíveis em Axel.", 2, "res://assets/banner_story_darkness.svg", 154)
	text(box, "Acompanhe a aventura por cenas ilustradas originais e batalhas por turnos.", 17)
	var sc = ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(sc)
	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	for i in range(STORY.size()):
		if i % 2 == 0:
			text(list, "CAPÍTULO %d — %s" % [int(i / 2) + 1, CHAPTERS[int(i / 2)]], 22)
		var label = "%02d  •  %s" % [i + 1, "Concluída" if i < progress else ("Jogar" if i == progress else "Bloqueada")]
		var b = add_button(list, label, show_scene.bind(i), Vector2(0, 54))
		b.disabled = i > progress

func show_scene(i: int):
	play_music("res://assets/story_theme.wav")
	clear_screen(CHAPTERS[int(i / 2)])
	var box = add_section(root, "CENA ILUSTRADA • DIÁRIO DE AVENTURA")
	var scene_art = "res://assets/axel_town.svg"
	if i >= 2 and i < 5:
		scene_art = "res://assets/battle_field.svg"
	elif i >= 5 and i < 8:
		scene_art = "res://assets/battle_forest.svg"
	elif i >= 8 and i < 11:
		scene_art = "res://assets/battle_castle.svg"
	elif i >= 11:
		scene_art = "res://assets/battle_dullahan.svg"
	add_art_panel(box, scene_art, 158, "AXEL • CENA %02d" % (i + 1))
	var cast = [0, 1]
	if i >= 3:
		cast.append(3)
	if i >= 5:
		cast.append(2)
	var scene_row = HBoxContainer.new()
	scene_row.alignment = BoxContainer.ALIGNMENT_CENTER
	scene_row.add_theme_constant_override("separation", 12)
	box.add_child(scene_row)
	for hero_id in cast:
		var portrait = add_character_sprite(scene_row, hero_id, Vector2(104, 120))
		portrait.pivot_offset = Vector2(52, 60)
		var idle = create_tween().set_loops()
		idle.tween_property(portrait, "scale", Vector2(1.035, 1.035), 0.9).set_trans(Tween.TRANS_SINE)
		idle.tween_property(portrait, "scale", Vector2(0.99, 0.99), 0.9).set_trans(Tween.TRANS_SINE)
	text(box, STORY[i], 27)
	text(box, "Cenas ilustradas originais — sem reproduzir trechos do anime.", 16)
	if i == STORY.size() - 1:
		add_button(box, "Ver aparição de Beldia", func():
			progress = maxi(progress, i + 1)
			store()
			show_ending()
		)
	elif i == 0 or i == 1 or i == 3 or i == 5 or i == 8:
		add_button(box, "Continuar", func(): complete(i))
	else:
		add_button(box, "Iniciar batalha", start_battle.bind(i))

func show_ending():
	clear_screen("O Dullahan")
	var box = add_section(root, "BELDIA — GENERAL DO REI DEMÔNIO")
	text(box, "O cavaleiro sem cabeça chega aos portões de Axel. O grupo encara sua próxima ameaça.", 30)
	text(box, "CONTINUA NA PRÓXIMA ATUALIZAÇÃO", 24)
	add_button(box, "Voltar à guilda", show_home)

func complete(i: int):
	if i >= progress:
		progress = i + 1
		crystals += 300
		coins += 80
		if progress >= 6 and not owned.has(2):
			owned.append(2)
			if team.size() < 3:
				team.append(2)
		if progress >= 6 and not unlocked_titles.has("Herói de Outro Mundo"):
			unlocked_titles.append("Herói de Outro Mundo")
		if owned.has(3) and not unlocked_titles.has("Arquimago Carmesim"):
			unlocked_titles.append("Arquimago Carmesim")
		if owned.has(2) and not unlocked_titles.has("Cruzado Inabalável"):
			unlocked_titles.append("Cruzado Inabalável")
	store()
	clear_screen("Fase concluída")
	var box = add_section(root, "MISSÃO COMPLETADA!")
	text(box, "Recompensas: 300 cristais e 80 eris.", 24)
	add_button(box, "Próxima fase", show_story)

func show_characters():
	clear_screen("Personagens")
	var box = add_section(root, "SUA EQUIPE")
	var sc = ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(sc)
	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	for id in owned:
		var i = int(id)
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		list.add_child(row)
		add_character_sprite(row, i, Vector2(100, 116))
		var info = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		text(info, "%s • %s • Nv. %d" % [RARITY[i], HEROES[i], levels[i]], 21)
		add_button(info, "Evoluir • 60 eris", upgrade.bind(i), Vector2(0, 46))
		add_button(info, "Remover da equipe" if team.has(i) else "Adicionar à equipe", toggle_team.bind(i), Vector2(0, 46))
	text(box, "Equipe: %d / 3" % team.size(), 18)

func upgrade(i: int):
	if coins >= 60:
		coins -= 60
		levels[i] = int(levels[i]) + 1
	store()
	show_characters()

func toggle_team(i: int):
	if team.has(i):
		if team.size() > 1:
			team.erase(i)
	elif team.size() < 3:
		team.append(i)
	store()
	show_characters()

func start_battle(i: int):
	stage = i
	enemy = "Sapo gigante" if i < 6 else ("Lobo da floresta" if i < 9 else "Guardião das ruínas")
	battle_max = 110 + i * 18
	battle_hp = battle_max
	party_hp = 160 + team.size() * 55
	mana = 3
	turn = 0
	fighting = true
	battle_screen("Escolha uma habilidade.")

func battle_screen(message: String):
	play_music("res://assets/battle_theme.wav")
	busy = false
	battle_sprites.clear()
	battle_enemy_panel = null
	clear_screen("Batalha em Axel", false)
	var arena = add_section(root, "⚔  %s" % enemy.to_upper())
	var battle_art = "res://assets/battle_field.svg"
	if stage >= 5 and stage < 9:
		battle_art = "res://assets/battle_forest.svg"
	elif stage >= 9:
		battle_art = "res://assets/battle_castle.svg"
	add_art_panel(arena, battle_art, 142, "CAMPO DE BATALHA • AXEL")
	var stats = HBoxContainer.new()
	arena.add_child(stats)
	text(stats, "INIMIGO  HP %d / %d" % [battle_hp, battle_max], 20)
	var bar = ProgressBar.new()
	bar.max_value = battle_max
	bar.value = battle_hp
	bar.custom_minimum_size = Vector2(0, 22)
	arena.add_child(bar)
	var combatants = HBoxContainer.new()
	combatants.alignment = BoxContainer.ALIGNMENT_CENTER
	combatants.add_theme_constant_override("separation", 16)
	arena.add_child(combatants)
	for id in team:
		var col = VBoxContainer.new()
		combatants.add_child(col)
		var fighter_sprite = add_character_sprite(col, int(id), Vector2(128, 140))
		fighter_sprite.pivot_offset = Vector2(64, 70)
		battle_sprites[int(id)] = fighter_sprite
		var nm = text(col, HEROES[int(id)], 17)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var foe = PanelContainer.new()
	foe.custom_minimum_size = Vector2(160, 140)
	foe.add_theme_stylebox_override("panel", panel_style(Color("#d7bd8e"), RED))
	combatants.add_child(foe)
	battle_enemy_panel = foe
	var foe_label = Label.new()
	foe_label.text = "☠\n" + enemy
	foe_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foe_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	foe_label.add_theme_color_override("font_color", INK)
	foe_label.add_theme_font_size_override("font_size", 22)
	foe.add_child(foe_label)
	text(arena, "EQUIPE HP %d   •   ENERGIA %d   •   TURNO %d" % [party_hp, mana, turn + 1], 19)
	text(arena, message, 19)
	var row = HBoxContainer.new()
	arena.add_child(row)
	for id in team:
		var i = int(id)
		add_button(row, HEROES[i] + " • Ataque", attack.bind(i, false), Vector2(0, 62))
	var special = HBoxContainer.new()
	arena.add_child(special)
	for id in team:
		var i = int(id)
		var b = add_button(special, ("EXPLOSION!" if i == 3 else HEROES[i] + " • Técnica"), attack.bind(i, true), Vector2(0, 62))
		b.disabled = mana < 2
	add_button(arena, "Recuar", show_story, Vector2(0, 48))

func attack(i: int, special: bool):
	if not fighting or busy:
		return
	if special and mana < 2:
		return
	busy = true
	var attacker = battle_sprites.get(i)
	if attacker != null:
		var lunge = create_tween()
		lunge.tween_property(attacker, "scale", Vector2(1.22, 1.22), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		lunge.parallel().tween_property(attacker, "rotation", -0.08, 0.12)
		lunge.tween_property(attacker, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_SINE)
		lunge.parallel().tween_property(attacker, "rotation", 0.0, 0.16)
		await lunge.finished
	if not fighting:
		busy = false
		return
	if is_instance_valid(battle_enemy_panel):
		var impact = create_tween()
		impact.tween_property(battle_enemy_panel, "modulate", Color(1.0, 0.55, 0.48), 0.07)
		impact.tween_property(battle_enemy_panel, "modulate", Color.WHITE, 0.14)
		await impact.finished
	var damage = POWER[i] + int(levels[i]) * 4 + rng.randi_range(0, 8)
	if special:
		mana -= 2
		damage *= 3 if i == 3 else 2
	else:
		mana = mini(5, mana + 1)
	battle_hp = maxi(0, battle_hp - damage)
	turn += 1
	if battle_hp == 0:
		busy = false
		fighting = false
		complete(stage)
		return
	if special and i == 1:
		party_hp += 35
	party_hp -= 15 + stage * 2
	if party_hp <= 0:
		busy = false
		fighting = false
		clear_screen("Derrota")
		var box = add_section(root, "A EQUIPE FOI DERROTADA")
		text(box, "Tente novamente e ajuste sua equipe.", 23)
		add_button(box, "Tentar novamente", start_battle.bind(stage))
		return
	busy = false
	battle_screen("%s causou %d de dano. O inimigo contra-atacou." % [HEROES[i], damage])

func show_banner():
	play_music("res://assets/summon_theme.wav")
	clear_screen("Summon 3D • Banner especial")
	var box = add_section(root, "RITUAL DE INVOCAÇÃO")
	add_character_banner(box, "AQUA • BÊNÇÃO DA DEUSA", "A deusa Aqua acompanha sua invocação. Boa sorte, aventureiro!", 1, "res://assets/banner_summon_aqua.svg", 174)
	var featured = add_section(root, "PERSONAGEM EM DESTAQUE • SSR")
	var row = HBoxContainer.new()
	featured.add_child(row)
	add_character_sprite(row, 3, Vector2(170, 205))
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	text(info, "MEGUMIN  •  SSR", 25)
	text(info, "1% de chance • SR: 20% • R: 79%", 20)
	text(info, "Garantia de Megumin na 100ª invocação.", 18)
	text(info, "Piedade: %d / 100" % pity, 20)
	var actions = HBoxContainer.new()
	featured.add_child(actions)
	add_button(actions, "1 INVOCAÇÃO • 300 ◆", summon.bind(1), Vector2(0, 64))
	add_button(actions, "10 INVOCAÇÕES • 3000 ◆", summon.bind(10), Vector2(0, 64))
	add_button(featured, "Prévia gratuita da summon 3D", func(): cinematic([3], true), Vector2(0, 54))

func summon(n: int):
	if busy:
		return
	if crystals < n * 300:
		text(root, "Cristais insuficientes.")
		return
	crystals -= n * 300
	var results = []
	for j in range(n):
		pity += 1
		var r = rng.randf()
		var i = 3 if r < 0.01 or pity >= 100 else ([1, 2, 5][rng.randi_range(0, 2)] if r < 0.21 else [0, 4][rng.randi_range(0, 1)])
		if i == 3:
			pity = 0
		if owned.has(i):
			coins += 25
		else:
			owned.append(i)
			if i == 3 and not unlocked_titles.has("Arquimago Carmesim"):
				unlocked_titles.append("Arquimago Carmesim")
			if i == 2 and not unlocked_titles.has("Cruzado Inabalável"):
				unlocked_titles.append("Cruzado Inabalável")
		results.append(i)
	store()
	cinematic(results, false)

func build_summon_3d() -> SubViewportContainer:
	var container = SubViewportContainer.new()
	container.custom_minimum_size = Vector2(0, 310)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.stretch = true
	var viewport = SubViewport.new()
	viewport.size = Vector2i(1024, 360)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	container.add_child(viewport)

	var world = Node3D.new()
	viewport.add_child(world)
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#10142d")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#6688dd")
	var world_env = WorldEnvironment.new()
	world_env.environment = environment
	world.add_child(world_env)

	var camera = Camera3D.new()
	camera.position = Vector3(0, 0.25, 6.2)
	camera.look_at(Vector3(0, 0, 0))
	world.add_child(camera)
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-25, -25, 0)
	light.light_color = Color("#a9c8ff")
	light.light_energy = 1.8
	world.add_child(light)

	var glow = OmniLight3D.new()
	glow.position = Vector3(0, 0, 1.0)
	glow.light_color = Color("#3b9dff")
	glow.light_energy = 3.0
	glow.omni_range = 6.0
	world.add_child(glow)

	var disk = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 1.12
	cylinder.bottom_radius = 1.12
	cylinder.height = 0.035
	disk.mesh = cylinder
	disk.rotation_degrees.x = 90
	var disk_mat = StandardMaterial3D.new()
	disk_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	disk_mat.albedo_color = Color("#18245a")
	disk_mat.emission_enabled = true
	disk_mat.emission = Color("#263f9b")
	disk_mat.emission_energy_multiplier = 0.8
	disk.material_override = disk_mat
	world.add_child(disk)

	var rings = []
	for radius in [0.84, 1.02, 1.24]:
		var ring = MeshInstance3D.new()
		var mesh = TorusMesh.new()
		mesh.inner_radius = radius
		mesh.outer_radius = radius + 0.045
		ring.mesh = mesh
		ring.rotation_degrees.x = 90
		var mat = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color("#5bd7ff")
		mat.emission_enabled = true
		mat.emission = Color("#39aaff")
		mat.emission_energy_multiplier = 2.2
		ring.material_override = mat
		world.add_child(ring)
		rings.append(ring)
		var tw = create_tween().set_loops()
		tw.tween_property(ring, "rotation", ring.rotation + Vector3(0, 0, TAU), 5.0)

	for n in range(18):
		var orb = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.035
		sphere.height = 0.07
		orb.mesh = sphere
		var a = TAU * float(n) / 18.0
		var rad = rng.randf_range(1.25, 1.65)
		orb.position = Vector3(cos(a) * rad, sin(a) * rad, rng.randf_range(-0.2, 0.2))
		var orb_mat = StandardMaterial3D.new()
		orb_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		orb_mat.albedo_color = Color("#b9f7ff")
		orb_mat.emission_enabled = true
		orb_mat.emission = Color("#7adfff")
		orb_mat.emission_energy_multiplier = 2.5
		orb.material_override = orb_mat
		world.add_child(orb)
		var bob = create_tween().set_loops()
		bob.tween_property(orb, "position:y", orb.position.y + 0.18, rng.randf_range(0.7, 1.4))
		bob.tween_property(orb, "position:y", orb.position.y - 0.18, rng.randf_range(0.7, 1.4))
	return container

func cinematic(results: Array, preview: bool):
	play_music("res://assets/summon_theme.wav")
	busy = true
	clear_screen("Invocação • Ritual mágico", false)
	var title = text(root, "KAZUMA ESTÁ PREPARANDO O ROUBO...", 25)
	var viewport = build_summon_3d()
	root.add_child(viewport)
	var reveal_row = HBoxContainer.new()
	reveal_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(reveal_row)
	var reveal_sprite = TextureRect.new()
	reveal_sprite.custom_minimum_size = Vector2(100, 118)
	reveal_sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	reveal_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	reveal_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	reveal_sprite.modulate.a = 0.0
	reveal_row.add_child(reveal_sprite)
	var reveal_text = Label.new()
	reveal_text.text = "ROUBO!"
	reveal_text.add_theme_font_size_override("font_size", 42)
	reveal_text.add_theme_color_override("font_color", Color("#9c2942"))
	reveal_row.add_child(reveal_text)
	add_button(root, "PULAR ANIMAÇÃO", func():
		busy = false
		show_results(results, preview)
	, Vector2(0, 48))

	await get_tree().create_timer(1.5).timeout
	if not busy:
		return
	title.text = "KAZUMA CONSEGUIU! UMA LUZ SURGE DO PORTAL..."
	if results.has(3):
		await get_tree().create_timer(1.2).timeout
		if not busy:
			return
		title.text = "A MAGIA CARMESIM RESPONDE..."
		reveal_sprite.texture = character_texture(3)
		var fade = create_tween()
		fade.tween_property(reveal_sprite, "modulate:a", 1.0, 0.8)
		await get_tree().create_timer(1.0).timeout
		if not busy:
			return
		title.text = "MEGUMIN — EXPLOSION!"
		reveal_text.text = "EXPLOSION!"
		reveal_text.add_theme_color_override("font_color", Color("#e35b2f"))
		await get_tree().create_timer(1.6).timeout
		if not busy:
			return
	else:
		var first_id = int(results[0])
		reveal_sprite.texture = character_texture(first_id)
		create_tween().tween_property(reveal_sprite, "modulate:a", 1.0, 0.8)
		title.text = "O PORTAL REVELOU UM AVENTUREIRO!"
		await get_tree().create_timer(1.5).timeout
		if not busy:
			return
	busy = false
	show_results(results, preview)

func show_results(results: Array, preview: bool):
	play_music("res://assets/axel_theme.wav")
	clear_screen("Resultado da invocação")
	var box = add_section(root, "AVENTUREIROS OBTIDOS")
	if preview:
		text(box, "Prévia — nenhum cristal gasto e nenhuma recompensa recebida.", 18)
	for i in results:
		var row = HBoxContainer.new()
		box.add_child(row)
		add_character_sprite(row, int(i), Vector2(95, 112))
		var l = text(row, "%s  •  %s" % [RARITY[i], HEROES[i]], 25)
		if i == 3:
			l.add_theme_color_override("font_color", Color("#b13d35"))
	add_button(box, "VOLTAR AO BANNER", show_banner)
