extends Control

const SAVE = "user://adventure.json"
const HEROES = ["Kazuma", "Aqua", "Darkness", "Megumin", "Chris", "Wiz"]
const RARITY = ["R", "SR", "SR", "SSR", "R", "SR"]
const POWER = [24, 18, 22, 42, 26, 34]
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
var crystals = 3000
var progress = 0
var pity = 0
var owned = [0,1]
var levels = [1,1,1,1,1,1]
var team = [0,1]
var coins = 100
var root: VBoxContainer
var status: Label
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
	show_home()

func store():
	var f = FileAccess.open(SAVE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"crystals":crystals,"progress":progress,"pity":pity,"owned":owned,"levels":levels,"team":team,"coins":coins}))

func load_game():
	if not FileAccess.file_exists(SAVE):
		return
	var f = FileAccess.open(SAVE, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		crystals = int(d.get("crystals",3000))
		progress = int(d.get("progress",0))
		pity = int(d.get("pity",0))
		coins = int(d.get("coins",100))
		owned = d.get("owned",[0,1])
		levels = d.get("levels",[1,1,1,1,1,1])
		team = d.get("team",[0,1])

func clear_screen(title: String, back: bool = true):
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var bg = ColorRect.new()
	bg.color = Color("#141e35")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margins = MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for key in ["margin_top","margin_bottom","margin_left","margin_right"]:
		margins.add_theme_constant_override(key, 24)
	add_child(margins)
	root = VBoxContainer.new()
	root.add_theme_constant_override("separation",12)
	margins.add_child(root)
	var head = HBoxContainer.new()
	root.add_child(head)
	if back:
		add_button(head,"Voltar",show_home,Vector2(130,52))
	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size",36)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title_label)
	var cash = Label.new()
	cash.text = "Cristais %d    Eris %d" % [crystals,coins]
	cash.add_theme_color_override("font_color",Color("#ffdb77"))
	cash.add_theme_font_size_override("font_size",22)
	head.add_child(cash)

func text(parent: Node, value: String, size: int = 25) -> Label:
	var l = Label.new()
	l.text = value
	l.add_theme_font_size_override("font_size",size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l

func add_button(parent: Node, label: String, callback: Callable, minimum: Vector2 = Vector2(0,65)) -> Button:
	var b = Button.new()
	b.text = label
	b.custom_minimum_size = minimum
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size",24)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#32456e")
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	b.add_theme_stylebox_override("normal",style)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func show_home():
	busy = false
	fighting = false
	clear_screen("KonoSuba: Another World",false)
	text(root,"AXEL  |  GUILDA DOS AVENTUREIROS",32)
	text(root,"Uma nova aventura começa aqui. Fan game não oficial — gráficos provisórios.",22)
	var row = HBoxContainer.new()
	root.add_child(row)
	add_button(row,"Modo história",show_story,Vector2(0,135))
	add_button(row,"Invocação",show_banner,Vector2(0,135))
	var row2 = HBoxContainer.new()
	root.add_child(row2)
	add_button(row2,"Personagens e equipe",show_characters,Vector2(0,135))
	add_button(row2,"Recompensa diária (teste)",daily,Vector2(0,135))
	text(root,"História: %d / %d fases concluídas" % [progress,STORY.size()],25)

func daily():
	clear_screen("Recompensas")
	text(root,"Recompensa de teste já disponível para experimentar as invocações.")
	add_button(root,"Receber 300 cristais",func(): crystals += 300; store(); show_home())

func show_story():
	clear_screen("História • Axel")
	var sc = ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(sc)
	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	for i in range(STORY.size()):
		if i % 2 == 0:
			text(list,"Capítulo %d — %s" % [i/2+1,CHAPTERS[i/2]],28)
		var b = add_button(list,"%02d  %s" % [i+1, "Concluída" if i < progress else ("Jogar" if i == progress else "Bloqueada")],show_scene.bind(i))
		b.disabled = i > progress

func show_scene(i: int):
	clear_screen(CHAPTERS[i/2])
	text(root,STORY[i],36)
	if i == STORY.size()-1:
		add_button(root,"Ver aparição de Beldia",func(): progress = maxi(progress,i+1); store(); show_ending())
	elif i == 0 or i == 1 or i == 3 or i == 5 or i == 8:
		add_button(root,"Continuar",func(): complete(i))
	else:
		add_button(root,"Iniciar batalha",start_battle.bind(i))

func show_ending():
	clear_screen("O Dullahan")
	text(root,"BELDIA — GENERAL DO REI DEMÔNIO",42)
	text(root,"O cavaleiro sem cabeça chega aos portões de Axel. O grupo encara sua próxima ameaça.",32)
	text(root,"CONTINUA NA PRÓXIMA ATUALIZAÇÃO",30)
	add_button(root,"Voltar à guilda",show_home)

func complete(i: int):
	if i >= progress:
		progress = i+1
		crystals += 300
		coins += 80
		if progress >= 6 and not owned.has(2):
			owned.append(2)
			if team.size() < 3:
				team.append(2)
	store()
	clear_screen("Fase concluída")
	text(root,"Missão concluída!",38)
	text(root,"Recompensas de primeira conclusão: 300 cristais e 80 eris.",24)
	add_button(root,"Próxima fase",show_story)

func show_characters():
	clear_screen("Personagens")
	var sc = ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(sc)
	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	for id in owned:
		var i = int(id)
		var row = HBoxContainer.new()
		list.add_child(row)
		text(row,"%s • %s • Nv. %d" % [RARITY[i],HEROES[i],levels[i]],24)
		add_button(row,"Evoluir 60 eris",upgrade.bind(i))
		add_button(row,"Remover" if team.has(i) else "Equipar",toggle_team.bind(i))
	text(root,"Equipe: %d / 3" % team.size())

func upgrade(i: int):
	if coins >= 60:
		coins -= 60
		levels[i] = int(levels[i])+1
	store()
	show_characters()

func toggle_team(i: int):
	if team.has(i):
		if team.size()>1: team.erase(i)
	elif team.size()<3:
		team.append(i)
	store()
	show_characters()

func start_battle(i: int):
	stage = i
	enemy = "Sapo gigante" if i < 6 else ("Lobo da floresta" if i < 9 else "Guardião das ruínas")
	battle_max = 110 + i*18
	battle_hp = battle_max
	party_hp = 160 + team.size()*55
	mana = 3
	turn = 0
	fighting = true
	battle_screen("Escolha uma habilidade.")

func battle_screen(message: String):
	clear_screen("Batalha",false)
	text(root,"%s  •  HP %d / %d" % [enemy,battle_hp,battle_max],36)
	var bar = ProgressBar.new()
	bar.max_value = battle_max
	bar.value = battle_hp
	bar.custom_minimum_size.y = 24
	root.add_child(bar)
	text(root,"Equipe: HP %d  |  Energia %d  |  Turno %d" % [party_hp,mana,turn+1],25)
	text(root,message,24)
	var row = HBoxContainer.new()
	root.add_child(row)
	for id in team:
		var i = int(id)
		add_button(row,HEROES[i]+" • Ataque",attack.bind(i,false),Vector2(0,88))
	var special = HBoxContainer.new()
	root.add_child(special)
	for id in team:
		var i = int(id)
		var b = add_button(special,("Explosion!" if i==3 else HEROES[i]+" • Técnica"),attack.bind(i,true),Vector2(0,88))
		b.disabled = mana<2
	add_button(root,"Recuar",show_story)

func attack(i: int, special: bool):
	if not fighting: return
	if special and mana < 2: return
	var damage = POWER[i] + int(levels[i])*4 + rng.randi_range(0,8)
	if special:
		mana -= 2
		damage *= 3 if i==3 else 2
	else:
		mana = mini(5,mana+1)
	battle_hp = maxi(0,battle_hp-damage)
	turn += 1
	if battle_hp == 0:
		fighting = false
		complete(stage)
		return
	if special and i==1:
		party_hp += 35
	party_hp -= 15+stage*2
	if party_hp<=0:
		fighting = false
		clear_screen("Derrota")
		text(root,"Sua equipe foi derrotada.")
		add_button(root,"Tentar novamente",start_battle.bind(stage))
		return
	battle_screen("%s causou %d de dano. O inimigo contra-atacou." % [HEROES[i],damage])

func show_banner():
	clear_screen("Invocação • Magia da Explosão")
	text(root,"★★★★★ MEGUMIN — ARQUIMAGA CARMESIM",42)
	text(root,"Megumin: 1% • SR: 20% • R: 79% • Garantia de Megumin na 100ª invocação.",24)
	text(root,"Garantia: %d / 100" % pity,27)
	var row = HBoxContainer.new()
	root.add_child(row)
	add_button(row,"1 invocação • 300",summon.bind(1),Vector2(0,130))
	add_button(row,"10 invocações • 3000",summon.bind(10),Vector2(0,130))
	add_button(root,"Prévia gratuita de Explosion",func(): cinematic([3],true))

func summon(n: int):
	if busy: return
	if crystals < n*300:
		text(root,"Cristais insuficientes.")
		return
	crystals -= n*300
	var results = []
	for j in range(n):
		pity += 1
		var r = rng.randf()
		var i = 3 if r < 0.01 or pity >= 100 else ([1,2,5][rng.randi_range(0,2)] if r < 0.21 else [0,4][rng.randi_range(0,1)])
		if i==3: pity=0
		if owned.has(i):
			coins += 25
		else:
			owned.append(i)
		results.append(i)
	store()
	cinematic(results,false)

func cinematic(results: Array, preview: bool):
	busy = true
	clear_screen("Invocação",false)
	var label = text(root,"Kazuma se prepara...",42)
	var effect = ColorRect.new()
	effect.color = Color("#3a294c")
	effect.custom_minimum_size.y = 290
	root.add_child(effect)
	var fx = Label.new()
	fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fx.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fx.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fx.add_theme_font_size_override("font_size",70)
	fx.text = "ROUBO!"
	effect.add_child(fx)
	var skip = add_button(root,"Pular",func(): busy=false; show_results(results,preview))
	await get_tree().create_timer(2).timeout
	if not busy: return
	label.text = "Kazuma conseguiu roubar! Um personagem apareceu!"
	fx.text = "✦"
	if results.has(3):
		await get_tree().create_timer(2).timeout
		if not busy: return
		label.text = "Megumin aparece. A magia carmesim começa..."
		fx.text = "◎"
		effect.color = Color("#7d123b")
		var tw = create_tween()
		tw.tween_property(fx,"modulate",Color("#ffcc66"),1.4)
		await get_tree().create_timer(3).timeout
		if not busy: return
		label.text = "EXPLOSION!"
		fx.text = "✴"
		effect.color = Color("#f4a43b")
		await get_tree().create_timer(1.5).timeout
		if not busy: return
	busy = false
	show_results(results,preview)

func show_results(results: Array, preview: bool):
	clear_screen("Resultado da invocação")
	if preview: text(root,"Prévia — nenhum cristal gasto e nenhuma recompensa recebida.",23)
	for i in results:
		var l = text(root,"%s  •  %s" % [RARITY[i],HEROES[i]],30)
		if i==3:
			l.add_theme_color_override("font_color",Color("#ffd36c"))
	add_button(root,"Voltar ao banner",show_banner)
