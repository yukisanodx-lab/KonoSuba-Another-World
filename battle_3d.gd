extends Control

const HERO_NAMES = ["Kazuma", "Aqua", "Darkness", "Megumin"]
const HERO_BODY = [Color("#47734f"), Color("#e6edf4"), Color("#d6ad54"), Color("#512b3d")]
const HERO_HAIR = [Color("#8a5939"), Color("#45b4e8"), Color("#f0cf72"), Color("#241d2d")]
const HERO_TRIM = [Color("#d0a15d"), Color("#2c7bb9"), Color("#9d773c"), Color("#c94b43")]

var viewport: SubViewport
var world: Node3D
var hero_nodes: Dictionary = {}
var enemy_node: Node3D
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	rng.randomize()
	_build_viewport()

func _build_viewport() -> void:
	var container := SubViewportContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)

	viewport = SubViewport.new()
	viewport.size = Vector2i(1280, 500)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.own_world_3d = true
	container.add_child(viewport)

	world = Node3D.new()
	world.name = "BattleWorld3D"
	viewport.add_child(world)

	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#8abbd3")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#c6d7e5")
	environment.ambient_light_energy = 0.75
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	world.add_child(world_environment)

	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 5.8, 11.5)
	camera.fov = 43.0
	camera.look_at(Vector3(0.0, 1.0, -0.2), Vector3.UP)
	camera.current = true
	world.add_child(camera)

	var sunlight := DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	sunlight.light_color = Color("#fff0d5")
	sunlight.light_energy = 1.45
	sunlight.shadow_enabled = true
	world.add_child(sunlight)

	var fill := OmniLight3D.new()
	fill.position = Vector3(-3.5, 4.0, 4.0)
	fill.light_color = Color("#9ccfff")
	fill.light_energy = 1.1
	fill.omni_range = 12.0
	world.add_child(fill)

func setup(party_ids: Array, stage_id: int, enemy_name: String) -> void:
	if world == null:
		return
	for child in world.get_children():
		if child is Node3D and child.name != "BattleCamera" and child.name != "DirectionalLight3D":
			if child is WorldEnvironment or child is Camera3D or child is DirectionalLight3D or child is OmniLight3D:
				continue
			child.queue_free()
	hero_nodes.clear()
	enemy_node = null
	_build_arena(stage_id)
	for index in range(party_ids.size()):
		var hero_id := int(party_ids[index])
		var hero := _make_hero(hero_id)
		var x_positions := [-3.25, -2.05, -0.85]
		hero.position = Vector3(x_positions[min(index, 2)], 0.0, 1.25 + (0.18 if index == 1 else 0.0))
		hero.rotation.y = -0.22
		world.add_child(hero)
		hero_nodes[hero_id] = hero
	enemy_node = _make_enemy(enemy_name, stage_id)
	enemy_node.position = Vector3(3.0, 0.0, -1.15)
	enemy_node.rotation.y = PI
	world.add_child(enemy_node)

func _build_arena(stage_id: int) -> void:
	var night := stage_id >= 11
	var forest := stage_id >= 5 and stage_id < 9
	var ruins := stage_id >= 9
	var ground_color := Color("#6d9657")
	if forest:
		ground_color = Color("#456d49")
	elif ruins:
		ground_color = Color("#777080")
	if night:
		ground_color = Color("#34374f")

	var ground := PlaneMesh.new()
	ground.size = Vector2(24.0, 19.0)
	_add_mesh(world, ground, ground_color, Vector3(0.0, -0.18, 0.0))

	var platform := CylinderMesh.new()
	platform.top_radius = 5.9
	platform.bottom_radius = 6.1
	platform.height = 0.18
	_add_mesh(world, platform, Color("#a48d69") if not ruins else Color("#625d6d"), Vector3(0.0, -0.09, 0.0))

	var path := BoxMesh.new()
	path.size = Vector3(8.5, 0.035, 2.8)
	_add_mesh(world, path, Color("#c0a47a") if not ruins else Color("#81778a"), Vector3(0.0, 0.015, 0.0))

	var ring := TorusMesh.new()
	ring.inner_radius = 4.4
	ring.outer_radius = 4.48
	var ring_mat := _material(Color("#e2c58a"), Color("#b88a49"))
	var ring_instance := MeshInstance3D.new()
	ring_instance.mesh = ring
	ring_instance.material_override = ring_mat
	ring_instance.rotation.x = PI / 2.0
	ring_instance.position.y = 0.025
	world.add_child(ring_instance)

	for side in [-1.0, 1.0]:
		for index in range(3):
			var x: float = side * (6.3 + float(index % 2) * 0.5)
			var z: float = -3.2 + float(index) * 2.6
			if forest or night:
				_make_tree(Vector3(x, 0.0, z), Color("#355a43") if not night else Color("#252c42"))
			elif ruins:
				_make_column(Vector3(x, 0.0, z))
			else:
				_make_rock(Vector3(x, 0.0, z), Color("#71866c"))

	for index in range(5):
		var hill := SphereMesh.new()
		hill.radius = 1.0
		hill.height = 2.0
		var hill_color := Color("#779b8d") if not night else Color("#343c58")
		_add_mesh(world, hill, hill_color, Vector3(-8.0 + index * 4.0, -0.2, -7.0), Vector3(2.2, 1.1, 1.2))

	if ruins:
		for x in [-4.8, 4.8]:
			_make_column(Vector3(x, 0.0, -5.2), true)

func _make_tree(pos: Vector3, leaf_color: Color) -> void:
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.13
	trunk.bottom_radius = 0.2
	trunk.height = 1.5
	_add_mesh(world, trunk, Color("#76533b"), pos + Vector3(0.0, 0.72, 0.0))
	var leaves := SphereMesh.new()
	leaves.radius = 0.9
	leaves.height = 1.7
	_add_mesh(world, leaves, leaf_color, pos + Vector3(0.0, 1.85, 0.0), Vector3(1.0, 1.0, 0.9))

func _make_column(pos: Vector3, tall: bool = false) -> void:
	var column := CylinderMesh.new()
	column.top_radius = 0.34
	column.bottom_radius = 0.42
	column.height = 3.3 if tall else 2.3
	_add_mesh(world, column, Color("#aaa1a0"), pos + Vector3(0.0, column.height * 0.5, 0.0))
	var cap := BoxMesh.new()
	cap.size = Vector3(0.95, 0.18, 0.95)
	_add_mesh(world, cap, Color("#d2c0a1"), pos + Vector3(0.0, column.height, 0.0))

func _make_rock(pos: Vector3, color: Color) -> void:
	var rock := SphereMesh.new()
	rock.radius = 0.65
	rock.height = 1.0
	_add_mesh(world, rock, color, pos + Vector3(0.0, 0.35, 0.0), Vector3(1.2, 0.8, 1.0))

func _material(color: Color, glow: Color = Color.BLACK) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.78
	if glow != Color.BLACK:
		mat.emission_enabled = true
		mat.emission = glow
		mat.emission_energy_multiplier = 1.2
	return mat

func _add_mesh(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3, scale_value: Vector3 = Vector3.ONE, glow: Color = Color.BLACK) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _material(color, glow)
	instance.position = pos
	instance.scale = scale_value
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(instance)
	return instance

func _add_capsule(parent: Node3D, radius: float, height: float, color: Color, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	var instance := _add_mesh(parent, mesh, color, pos)
	instance.rotation = rot
	return instance

func _make_hero(hero_id: int) -> Node3D:
	var root := Node3D.new()
	root.name = HERO_NAMES[hero_id] + "_3D"
	var body_color: Color = HERO_BODY[hero_id]
	var hair_color: Color = HERO_HAIR[hero_id]
	var trim_color: Color = HERO_TRIM[hero_id]
	var skin := Color("#f0c8a8")
	var dark := Color("#302a37")

	_add_capsule(root, 0.34, 0.9, body_color, Vector3(0.0, 1.22, 0.0))
	_add_mesh(root, SphereMesh.new(), skin, Vector3(0.0, 1.98, 0.0), Vector3(0.31, 0.34, 0.29))
	_add_mesh(root, SphereMesh.new(), hair_color, Vector3(0.0, 2.18, -0.015), Vector3(0.36, 0.23, 0.34))
	_add_mesh(root, SphereMesh.new(), hair_color, Vector3(-0.25, 1.92, 0.02), Vector3(0.13, 0.36, 0.15))
	_add_mesh(root, SphereMesh.new(), hair_color, Vector3(0.25, 1.92, 0.02), Vector3(0.13, 0.36, 0.15))

	for side in [-1.0, 1.0]:
		_add_capsule(root, 0.12, 0.62, body_color, Vector3(side * 0.43, 1.28, 0.0), Vector3(0.0, 0.0, side * -0.28))
		_add_capsule(root, 0.145, 0.66, dark, Vector3(side * 0.18, 0.48, 0.0))
		_add_mesh(root, SphereMesh.new(), skin, Vector3(side * 0.43, 0.91, 0.0), Vector3(0.13, 0.13, 0.13))
		_add_mesh(root, SphereMesh.new(), Color("#332c35"), Vector3(side * 0.11, 1.99, 0.265), Vector3(0.035, 0.045, 0.025))

	_add_mesh(root, BoxMesh.new(), trim_color, Vector3(0.0, 0.83, 0.025), Vector3(0.55, 0.16, 0.39))

	if hero_id == 0:
		_add_mesh(root, BoxMesh.new(), Color("#6d9157"), Vector3(0.0, 1.32, -0.22), Vector3(0.72, 0.78, 0.12))
		_add_capsule(root, 0.045, 1.25, Color("#8c6542"), Vector3(0.55, 1.25, 0.08), Vector3(0.0, 0.0, -0.9))
	elif hero_id == 1:
		_add_mesh(root, SphereMesh.new(), hair_color, Vector3(0.0, 1.42, -0.34), Vector3(0.23, 0.72, 0.16))
		_add_mesh(root, SphereMesh.new(), trim_color, Vector3(0.0, 1.55, 0.23), Vector3(0.42, 0.2, 0.08))
		_add_mesh(root, SphereMesh.new(), Color("#d7bd62"), Vector3(0.0, 1.55, 0.31), Vector3(0.06, 0.06, 0.035))
	elif hero_id == 2:
		for side in [-1.0, 1.0]:
			_add_mesh(root, SphereMesh.new(), Color("#e3c16c"), Vector3(side * 0.37, 1.57, 0.0), Vector3(0.22, 0.18, 0.25))
		_add_mesh(root, BoxMesh.new(), Color("#d4b36c"), Vector3(0.0, 1.15, 0.28), Vector3(0.66, 0.42, 0.12))
	elif hero_id == 3:
		var hat := CylinderMesh.new()
		hat.top_radius = 0.0
		hat.bottom_radius = 0.48
		hat.height = 0.72
		_add_mesh(root, hat, Color("#2c2436"), Vector3(0.0, 2.48, 0.0), Vector3(1.0, 1.0, 1.0))
		_add_mesh(root, CylinderMesh.new(), Color("#c83d3d"), Vector3(0.0, 2.25, 0.0), Vector3(1.0, 0.09, 1.0))
		_add_mesh(root, SphereMesh.new(), Color("#b92f35"), Vector3(0.0, 1.42, -0.22), Vector3(0.48, 0.63, 0.16))
		_add_capsule(root, 0.04, 1.3, Color("#8a633a"), Vector3(0.62, 1.3, 0.0), Vector3(0.0, 0.0, -0.15))
		_add_mesh(root, SphereMesh.new(), Color("#d84b37"), Vector3(0.62, 1.98, 0.0), Vector3(0.14, 0.14, 0.14))

	return root

func _cone_mesh(radius: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	return mesh

func _make_enemy(enemy_name: String, stage_id: int) -> Node3D:
	var root := Node3D.new()
	root.name = "Enemy_" + enemy_name
	var lower := enemy_name.to_lower()
	if lower.contains("sapo"):
		var green := Color("#659a4c")
		_add_mesh(root, SphereMesh.new(), green, Vector3(0.0, 0.9, 0.0), Vector3(1.05, 0.7, 0.9))
		_add_mesh(root, SphereMesh.new(), Color("#7db95b"), Vector3(0.0, 1.25, 0.25), Vector3(0.72, 0.48, 0.72))
		for side in [-1.0, 1.0]:
			_add_mesh(root, SphereMesh.new(), Color("#f0e8b4"), Vector3(side * 0.34, 1.62, 0.48), Vector3(0.17, 0.18, 0.16))
			_add_mesh(root, SphereMesh.new(), Color("#25262b"), Vector3(side * 0.34, 1.63, 0.62), Vector3(0.055, 0.07, 0.045))
			_add_capsule(root, 0.19, 0.68, green, Vector3(side * 0.72, 0.48, 0.12), Vector3(0.0, 0.0, side * 0.5))
	elif lower.contains("lobo"):
		_add_mesh(root, SphereMesh.new(), Color("#777b86"), Vector3(0.0, 1.0, 0.0), Vector3(1.1, 0.52, 0.48))
		_add_mesh(root, SphereMesh.new(), Color("#858b98"), Vector3(0.0, 1.25, 0.5), Vector3(0.48, 0.42, 0.5))
		_add_mesh(root, _cone_mesh(0.38, 0.72), Color("#626873"), Vector3(-0.28, 1.65, 0.45), Vector3(0.55, 0.75, 0.55))
		_add_mesh(root, _cone_mesh(0.38, 0.72), Color("#626873"), Vector3(0.28, 1.65, 0.45), Vector3(0.55, 0.75, 0.55))
		for side in [-1.0, 1.0]:
			_add_capsule(root, 0.12, 0.72, Color("#5e6571"), Vector3(side * 0.62, 0.42, 0.0))
			_add_mesh(root, SphereMesh.new(), Color("#d8c3a0"), Vector3(side * 0.13, 1.3, 0.88), Vector3(0.045, 0.045, 0.035))
	elif lower.contains("beldia") or stage_id >= 11:
		_add_capsule(root, 0.43, 1.25, Color("#343342"), Vector3(0.0, 1.25, 0.0))
		_add_mesh(root, BoxMesh.new(), Color("#5a5366"), Vector3(0.0, 1.3, 0.0), Vector3(1.1, 0.55, 0.6))
		_add_mesh(root, SphereMesh.new(), Color("#171824"), Vector3(0.0, 2.1, 0.0), Vector3(0.34, 0.34, 0.34), Color("#8d334d"))
		for side in [-1.0, 1.0]:
			_add_capsule(root, 0.15, 0.78, Color("#464253"), Vector3(side * 0.55, 1.25, 0.0))
			_add_capsule(root, 0.18, 0.82, Color("#292a3a"), Vector3(side * 0.2, 0.45, 0.0))
		_add_capsule(root, 0.055, 1.55, Color("#75624e"), Vector3(0.78, 1.2, 0.0), Vector3(0.0, 0.0, -0.2))
		_add_mesh(root, _cone_mesh(0.25, 0.5), Color("#a4a0a5"), Vector3(0.78, 2.05, 0.0), Vector3(0.55, 0.8, 0.55))
	else:
		_add_mesh(root, BoxMesh.new(), Color("#777b83"), Vector3(0.0, 1.0, 0.0), Vector3(1.25, 1.35, 0.85))
		_add_mesh(root, SphereMesh.new(), Color("#92969e"), Vector3(0.0, 1.95, 0.0), Vector3(0.48, 0.48, 0.48))
		for side in [-1.0, 1.0]:
			_add_capsule(root, 0.18, 0.9, Color("#666b74"), Vector3(side * 0.82, 0.52, 0.0))
	return root

func play_attack(hero_id: int, special: bool) -> void:
	if not hero_nodes.has(hero_id) or not is_instance_valid(enemy_node):
		return
	var hero: Node3D = hero_nodes[hero_id]
	var home := hero.position
	var lunge := create_tween()
	lunge.tween_property(hero, "position", home + Vector3(1.15, 0.16, -0.48), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	lunge.parallel().tween_property(hero, "rotation:y", -0.68, 0.2)
	lunge.tween_property(hero, "position", home, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	lunge.parallel().tween_property(hero, "rotation:y", -0.22, 0.2)
	await lunge.finished
	if special:
		await _play_special(hero_id)
	else:
		await _play_slash(hero_id)
	await _hit_enemy()

func _play_slash(hero_id: int) -> void:
	var color: Color = HERO_TRIM[hero_id]
	var slash := TorusMesh.new()
	slash.inner_radius = 0.34
	slash.outer_radius = 0.43
	var effect := _add_mesh(world, slash, color, enemy_node.position + Vector3(0.0, 1.25, 0.5), Vector3(0.15, 0.15, 0.15), color)
	effect.rotation.y = PI * 0.5
	var tween := create_tween()
	tween.tween_property(effect, "scale", Vector3(2.6, 2.6, 2.6), 0.22)
	tween.parallel().tween_property(effect, "rotation:z", PI, 0.22)
	await tween.finished
	effect.queue_free()

func _play_special(hero_id: int) -> void:
	var color: Color = HERO_TRIM[hero_id]
	if hero_id == 3:
		color = Color("#ff623b")
	var center := enemy_node.position + Vector3(0.0, 1.2, 0.3)
	var orb := _add_mesh(world, SphereMesh.new(), color, center, Vector3(0.12, 0.12, 0.12), color)
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.72
	ring_mesh.outer_radius = 0.82
	var ring := _add_mesh(world, ring_mesh, Color("#ffe6a4"), center, Vector3(0.12, 0.12, 0.12), color)
	ring.rotation.x = PI * 0.5
	var light := OmniLight3D.new()
	light.position = center
	light.light_color = color
	light.light_energy = 2.5
	light.omni_range = 7.0
	world.add_child(light)
	var tween := create_tween()
	tween.tween_property(orb, "scale", Vector3(3.2, 3.2, 3.2) if hero_id == 3 else Vector3(1.9, 1.9, 1.9), 0.42)
	tween.parallel().tween_property(ring, "scale", Vector3(3.6, 3.6, 3.6), 0.48)
	tween.parallel().tween_property(light, "light_energy", 0.0, 0.5)
	await tween.finished
	orb.queue_free()
	ring.queue_free()
	light.queue_free()

func _hit_enemy() -> void:
	if not is_instance_valid(enemy_node):
		return
	var tween := create_tween()
	tween.tween_property(enemy_node, "position:x", enemy_node.position.x + 0.22, 0.06)
	tween.tween_property(enemy_node, "position:x", enemy_node.position.x - 0.18, 0.06)
	tween.tween_property(enemy_node, "position:x", enemy_node.position.x, 0.08)
	tween.parallel().tween_property(enemy_node, "scale", Vector3(0.88, 0.88, 0.88), 0.1)
	tween.tween_property(enemy_node, "scale", Vector3.ONE, 0.14)
	await tween.finished

func play_enemy_attack(target_id: int) -> void:
	if not hero_nodes.has(target_id) or not is_instance_valid(enemy_node):
		return
	var target: Node3D = hero_nodes[target_id]
	var enemy_home := enemy_node.position
	var target_home := target.position
	var tween := create_tween()
	tween.tween_property(enemy_node, "position", target_home + Vector3(0.8, 0.0, -0.3), 0.2)
	tween.tween_property(enemy_node, "position", enemy_home, 0.2)
	tween.parallel().tween_property(target, "position:x", target_home.x - 0.18, 0.08)
	tween.tween_property(target, "position:x", target_home.x + 0.16, 0.08)
	tween.tween_property(target, "position", target_home, 0.1)
	await tween.finished

func play_victory() -> void:
	for hero in hero_nodes.values():
		if is_instance_valid(hero):
			var tween := create_tween()
			tween.tween_property(hero, "position:y", 0.45, 0.25).set_trans(Tween.TRANS_BACK)
			tween.tween_property(hero, "position:y", 0.0, 0.22)
