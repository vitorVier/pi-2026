extends Node2D

enum Type { FRUIT, PET, CLOTH, ELETRONIC }

# Tutorial variables
var tutorial_mode = true;
var tutorial_items = 0;
var tutorial_score_enabled = false
var countdown_target = "TUTORIAL"

var state = "START"
var level = "TUTORIAL"
var can_interact = true;
var points = 0
var lifes = 5

var fall_speed = 200

# Labels and background
@onready var panel_countdown = $'PanelContainer'
@onready var label_countdown = $'PanelContainer/LabelCountdown'
@onready var label_points = $LabelPoints
@onready var label_life = $LabelLife
@onready var label_level = $LabelLevel
@onready var color_rect = $ColorRect
@onready var conveyor = $Background/Conveyor
@onready var item_scene = preload("res://Item.tscn")

# Spawn
@onready var spawn_point = $Marker2D
@onready var spawn_timer = $Timer

# Bancadas
@onready var bancada_frutas = $'Interfaces/Control/TopRight_Fruits'
@onready var bancada_pets = $'Interfaces/Control/TopLeft_Pets'
@onready var bancada_roupas = $'Interfaces/Control/BottomRight_Clothes'
@onready var bancada_eletronicos = $'Interfaces/Control/BottomLeft_Eletronics'
var tutorial_tween: Tween
var glow_tween: Tween
var border_tween: Tween

# Sounds
@onready var error_sound = $ErrorSound
@onready var acc_sound = $AccSound
@onready var coundown_sound = $CountdownSound

var bancada_colors = {
	Type.FRUIT: Color("#FFD54A"),
	Type.PET: Color("#42A5F5"),
	Type.CLOTH: Color("#EF4444"),
	Type.ELETRONIC: Color("4CAF50")
}

func get_bancada_pos(type):
	var alvo = null
	match type:
		Type.FRUIT: alvo = bancada_frutas
		Type.PET: alvo = bancada_pets
		Type.CLOTH: alvo = bancada_roupas
		Type.ELETRONIC: alvo = bancada_eletronicos
	if is_instance_valid(alvo):
		if alvo is Control:
			return alvo.global_position + (alvo.size * alvo.get_global_transform().get_scale() / 2)
		else:
			return alvo.global_position
	return Vector2.ZERO

var input_map = {
	Type.FRUIT: "rightHand",
	Type.PET: "leftHand",
	Type.CLOTH: "rightFoot",
	Type.ELETRONIC: "leftFoot"
}

var assets = {
	Type.FRUIT: [
		preload("res://kenney_food-kit/Previews/apple.png"),
		preload("res://kenney_food-kit/Previews/banana.png"),
		preload("res://kenney_food-kit/Previews/cherries.png"),
		preload("res://kenney_food-kit/Previews/orange.png"),
		preload("res://kenney_food-kit/Previews/pineapple.png"),
		preload("res://kenney_food-kit/Previews/strawberry.png"),
	],
	Type.PET: [
		preload("res://kenney_pets/Previews/animal-cat.png"),
		preload("res://kenney_pets/Previews/animal-chick.png"),
		preload("res://kenney_pets/Previews/animal-elephant.png"),
		preload("res://kenney_pets/Previews/animal-lion.png"),
		preload("res://kenney_pets/Previews/animal-monkey.png"),
		preload("res://kenney_pets/Previews/animal-panda.png"),
	],
	Type.CLOTH: [
		preload("res://clothes_package/calca.png"),
		preload("res://clothes_package/casaco.png"),
		preload("res://clothes_package/meias.png"),
		preload("res://clothes_package/terno.png"),
		preload("res://clothes_package/toca.png"),
		preload("res://clothes_package/vestido.png"),
	],
	Type.ELETRONIC: [
		preload("res://kenney_tools/PNG/Colored/genericItem_color_049.png"),
		preload("res://kenney_tools/PNG/Colored/genericItem_color_050.png"),
		preload("res://kenney_tools/PNG/Colored/genericItem_color_051.png"),
		preload("res://kenney_tools/PNG/Colored/genericItem_color_053.png"),
		preload("res://kenney_tools/PNG/Colored/genericItem_color_082.png"),
		preload("res://kenney_tools/PNG/Colored/genericItem_color_084.png"),
	]
}

func _ready():
	_setup_bancada_borders()
	label_points.modulate = Color.YELLOW
	label_life.modulate = Color.RED
	go_to_start()
	update_points()

func _setup_bancada_borders():
	var border_map = {
		bancada_frutas:      Color("#FFD60A"),
		bancada_pets:        Color("#2563EB"),
		bancada_roupas:      Color("#EF4444"),
		bancada_eletronicos: Color("#22C55E")
	}
	for bancada in border_map:
		if bancada.get_node_or_null("BorderGlow"):
			continue
		var panel = Panel.new()
		panel.name = "BorderGlow"
		panel.size = bancada.size + Vector2(16, 16)
		panel.position = Vector2(-8, -8)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.z_index = -1
		var style = StyleBoxFlat.new()
		style.draw_center = false
		style.border_width_left   = 6
		style.border_width_right  = 6
		style.border_width_top    = 6
		style.border_width_bottom = 6
		style.corner_radius_top_left     = 8
		style.corner_radius_top_right    = 8
		style.corner_radius_bottom_left  = 8
		style.corner_radius_bottom_right = 8
		style.border_color = Color(border_map[bancada].r, border_map[bancada].g, border_map[bancada].b, 0.0)
		panel.add_theme_stylebox_override("panel", style)
		bancada.add_child(panel)

func _process(_delta):
	if state == "GAMEOVER":
		handle_gameover_input()
		return
	if handle_state_transition():
		return
	if state == "PLAYING":
		verify_input()
		set_levels()

func handle_gameover_input():
	for action in input_map.values():
		if Input.is_action_just_pressed(action):
			get_tree().change_scene_to_file("res://main_menu.tscn")
			return

func go_to_tutorial():
	state = "PLAYING"
	fall_speed = 100
	spawn_timer.wait_time = 3
	tutorial_mode = true
	tutorial_score_enabled = false
	tutorial_items = 0
	level = "TUTORIAL"
	can_interact = true
	label_points.visible = true
	label_life.visible = true
	label_level.visible = true
	conveyor.visible = true
	color_rect.visible = true
	bancada_pets.visible = true
	bancada_frutas.visible = true
	bancada_eletronicos.visible = true
	bancada_roupas.visible = true
	label_level.text = "Tutorial"
	label_points.text = "⭐ 0/4"
	label_life.text = "❤️ " + str(lifes)
	label_level.add_theme_color_override("font_color", Color.GREEN)
	label_points.add_theme_color_override("font_color", Color.YELLOW)
	label_life.add_theme_color_override("font_color", Color.RED)
	spawn_timer.wait_time = 2.5
	spawn_timer.start()

func update_tutorial_progress():
	label_points.text = "⭐ %d/4" % tutorial_items

func go_to_start():
	state = "START"
	countdown_target = "TUTORIAL"
	start_countdown()
	level = "EASY"
	points = 0
	lifes = 5
	panel_countdown.visible = true
	label_countdown.visible = true
	label_points.visible = false
	label_life.visible = false
	label_level.visible = false
	conveyor.visible = false
	color_rect.visible = false
	bancada_pets.visible = false
	bancada_frutas.visible = false
	bancada_eletronicos.visible = false
	bancada_roupas.visible = false
	update_points()
	label_life.text = "❤️ " + str(lifes)

func go_to_playing():
	state = "PLAYING"
	can_interact = true
	label_points.visible = true
	label_life.visible = true
	label_level.visible = true
	conveyor.visible = true
	color_rect.visible = true
	bancada_pets.visible = true
	bancada_frutas.visible = true
	bancada_eletronicos.visible = true
	bancada_roupas.visible = true

func go_to_gameOver():
	state = "GAMEOVER"
	label_points.visible = false
	label_life.visible = false
	label_level.visible = false
	conveyor.visible = false
	color_rect.visible = false
	bancada_pets.visible = false
	bancada_frutas.visible = false
	bancada_eletronicos.visible = false
	bancada_roupas.visible = false
	stop_items()
	clear_items()
	var game_over_scene = preload("res://game_over.tscn").instantiate()
	game_over_scene.final_score = points
	get_tree().root.add_child(game_over_scene)
	queue_free()

func has_tutorial_item():
	for node in get_children():
		if node is Area2D:
			if "is_tutorial" in node and node.is_tutorial:
				if not node.is_queued_for_deletion():
					return true
	return false

func highlight_bancada(type):
	stop_highlight()
	var highlight_color = bancada_colors[type]
	var bancada_correta = null
	match type:
		Type.FRUIT:     bancada_correta = bancada_frutas
		Type.PET:       bancada_correta = bancada_pets
		Type.CLOTH:     bancada_correta = bancada_roupas
		Type.ELETRONIC: bancada_correta = bancada_eletronicos
	if bancada_correta == null:
		return
	
	var border_glow = bancada_correta.get_node_or_null("BorderGlow")
	
	for bancada in [bancada_frutas, bancada_pets, bancada_roupas, bancada_eletronicos]:
		if bancada != bancada_correta:
			var t = create_tween()
			t.tween_property(bancada, "modulate:a", 0.4, 0.4)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	bancada_correta.modulate = Color.WHITE
	bancada_correta.scale = Vector2.ONE
	
	var overlay = _get_or_create_glow_overlay(bancada_correta, highlight_color)
	
	# Borda pulsante
	if border_glow:
		var style = border_glow.get_theme_stylebox("panel") as StyleBoxFlat
		style.border_color.a = 0.0
		border_tween = create_tween().set_loops()
		border_tween.tween_method(func(a: float): style.border_color.a = a, 0.0, 1.0, 0.8)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		border_tween.tween_method(func(a: float): style.border_color.a = a, 1.0, 0.15, 0.8)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Escala pulsante
	tutorial_tween = create_tween()
	tutorial_tween.tween_property(bancada_correta, "scale", Vector2(1.06, 1.06), 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tutorial_tween.tween_callback(func():
		tutorial_tween = create_tween().set_loops()
		tutorial_tween.tween_property(bancada_correta, "scale", Vector2(1.08, 1.08), 0.6)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tutorial_tween.tween_property(bancada_correta, "scale", Vector2(1.04, 1.04), 0.6)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	)
	
	# Overlay pulsante
	glow_tween = create_tween()
	glow_tween.tween_property(overlay, "modulate:a", 0.35, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	glow_tween.tween_callback(func():
		glow_tween = create_tween().set_loops()
		glow_tween.tween_property(overlay, "modulate:a", 0.35, 0.7)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		glow_tween.tween_property(overlay, "modulate:a", 0.1, 0.7)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	)

func _get_or_create_glow_overlay(bancada: Control, color: Color) -> ColorRect:
	var existing = bancada.get_node_or_null("GlowOverlay")
	if existing:
		existing.color = Color(color.r, color.g, color.b, 0.0)
		return existing
	var overlay = ColorRect.new()
	overlay.name = "GlowOverlay"
	overlay.color = Color(color.r, color.g, color.b, 0.0)
	overlay.size = bancada.size
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 10
	bancada.add_child(overlay)
	return overlay

func stop_highlight():
	if tutorial_tween:
		tutorial_tween.kill()
	if glow_tween:
		glow_tween.kill()
	if border_tween:
		border_tween.kill()

	for bancada in [bancada_frutas, bancada_pets, bancada_roupas, bancada_eletronicos]:
		var t = create_tween()
		t.tween_property(bancada, "scale", Vector2.ONE, 0.3)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(bancada, "modulate", Color.WHITE, 0.3)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		var overlay = bancada.get_node_or_null("GlowOverlay")
		if overlay:
			var ot = create_tween()
			ot.tween_property(overlay, "modulate:a", 0.0, 0.3)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		var border_glow = bancada.get_node_or_null("BorderGlow")
		if border_glow:
			var style = border_glow.get_theme_stylebox("panel") as StyleBoxFlat
			var bt = create_tween()
			bt.tween_method(func(a: float): style.border_color.a = a, style.border_color.a, 0.0, 0.3)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func start_game():
	state = "PLAYING"
	tutorial_mode = false
	tutorial_score_enabled = true
	can_interact = true
	label_points.visible = true
	label_life.visible = true
	label_level.visible = true
	conveyor.visible = true
	color_rect.visible = true
	bancada_pets.visible = true
	bancada_frutas.visible = true
	bancada_eletronicos.visible = true
	bancada_roupas.visible = true
	points = 0
	update_points()
	level = "EASY"
	set_levels()
	spawn_timer.start()

func set_levels():
	if not tutorial_mode and points <= 25:
		level = "EASY"
		fall_speed = 50
		spawn_timer.wait_time = 4
		$'LabelLevel'.text = "Level: Fácil"
		label_level.label_settings.font_color = "#4CAF50"
	elif not tutorial_mode and points <= 50:
		level = "MEDIUM"
		fall_speed = 75
		spawn_timer.wait_time = 3.75
		$'LabelLevel'.text = "Level: Médio"
		label_level.label_settings.font_color = "#2196F3"
	elif not tutorial_mode and points <= 100:
		level = "HARD"
		fall_speed = 100
		spawn_timer.wait_time = 3.5
		$'LabelLevel'.text = "Level: Difícil"
		label_level.label_settings.font_color = "#FF9800"
	elif not tutorial_mode and points > 100:
		level = "EXTREME"
		fall_speed = 125
		spawn_timer.wait_time = 2.5
		$'LabelLevel'.text = "Level: Muito difícil"
		label_level.label_settings.font_color = "#F44336"
	else:
		$'LabelLevel'.text = "Level: Tutorial"
	return

func handle_state_transition():
	for action in input_map.values():
		if state == "START" and Input.is_action_just_pressed(action):
			return true
		if state == "GAMEOVER" and Input.is_action_just_pressed(action):
			go_to_start()
			return true
	return false

func start_countdown():
	can_interact = false
	color_rect.visible = false
	panel_countdown.visible = true
	label_countdown.visible = true
	set_countdown_text(countdown_target)
	await get_tree().create_timer(2.0).timeout
	coundown_sound.play()
	set_countdown_text("3")
	await get_tree().create_timer(1.0).timeout
	set_countdown_text("2")
	await get_tree().create_timer(1.0).timeout
	set_countdown_text("1")
	await get_tree().create_timer(1.0).timeout
	set_countdown_text("START")
	await get_tree().create_timer(1.0).timeout
	panel_countdown.visible = false
	label_countdown.visible = false
	if countdown_target == "TUTORIAL":
		go_to_tutorial()
	elif countdown_target == "Agora vamos começar!":
		start_game()

func set_countdown_text(value: String):
	label_countdown.text = value
	if value == "TUTORIAL":
		label_countdown.label_settings.font_size = 350
	elif value == "PERFEITO!":
		label_countdown.label_settings.font_size = 330
	elif value == "Agora vamos começar!":
		label_countdown.label_settings.font_size = 170
	else:
		label_countdown.label_settings.font_size = 500

func verify_input():
	if not can_interact:
		return
	for action in input_map.values():
		if Input.is_action_just_pressed(action):
			process_direction(action)
			return

func process_direction(tecla):
	var item = get_first_item()
	if item == null:
		return
	if acertou_tecla(item.type, tecla):
		acertou(item)
	else:
		errou(item)

func acertou_tecla(type, tecla):
	return input_map.get(type) == tecla

func acertou(item):
	stop_highlight()
	can_interact = false
	item.is_launched = true
	acc_sound.play()
	item.correct_animation()
	if tutorial_mode:
		update_tutorial_progress()
	elif tutorial_score_enabled:
		points += 5
		update_points()
	var alvo = get_bancada_pos(item.type)
	item.launch_to_target(alvo)
	await get_tree().create_timer(0.1).timeout
	can_interact = true
	if tutorial_mode:
		spawn_item()

func errou(item):
	if not item.is_tutorial:
		stop_highlight()
	if not can_interact or not is_instance_valid(item):
		return
	if tutorial_mode:
		item.error_animation()
		error_sound.play()
		return
	can_interact = false
	item.is_launched = true
	item.error_animation()
	lost_life()
	if state == "GAMEOVER":
		return
	await get_tree().create_timer(0.5).timeout
	can_interact = true
	if is_instance_valid(item):
		item.queue_free()

func lost_due_omission():
	lost_life()

func lost_life():
	error_sound.play()
	lifes -= 1
	$LabelLife.text = "❤️ " + str(lifes)
	if lifes < 1:
		go_to_gameOver()
	await get_tree().create_timer(0.5).timeout
	can_interact = true

func update_points():
	label_points.text = "⭐ " + str(points)

func _on_timer_timeout():
	if state != "PLAYING":
		return
	if tutorial_mode and has_tutorial_item():
		return
	spawn_item()

func spawn_item():
	var new_item = item_scene.instantiate()
	var type
	if tutorial_mode:
		if tutorial_items >= 4:
			can_interact = false
			state = "START"
			stop_highlight()
			clear_items()
			spawn_timer.stop()
			label_points.visible = false
			label_life.visible = false
			label_level.visible = false
			bancada_pets.visible = false
			bancada_frutas.visible = false
			bancada_eletronicos.visible = false
			bancada_roupas.visible = false
			conveyor.visible = false
			set_countdown_text("PERFEITO!")
			can_interact = false
			color_rect.visible = false
			panel_countdown.visible = true
			label_countdown.visible = true
			await get_tree().create_timer(1.0).timeout
			countdown_target = "Agora vamos começar!"
			await get_tree().create_timer(1.0).timeout
			start_countdown()
			return
		else:
			type = tutorial_items
			tutorial_items += 1
	else:
		type = randi() % Type.size()
	add_child(new_item)
	new_item.position = spawn_point.position
	new_item.setup(type, assets[type], fall_speed)
	if tutorial_mode:
		new_item.is_tutorial = true

func get_first_item():
	var closest_item = null
	var max_y = -1
	for node in get_children():
		if node is Area2D and not node.is_queued_for_deletion():
			if node.has_method("launch") and "is_launched" in node:
				if not node.is_launched:
					if node.position.y > max_y:
						max_y = node.position.y
						closest_item = node
	return closest_item

func stop_items():
	for node in get_children():
		if node is Area2D and "can_fall" in node:
			node.can_fall = false

func clear_items():
	for node in get_children():
		if node is Area2D:
			node.queue_free()
