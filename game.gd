extends Node2D

enum Type { FRUIT, PET, CLOTH, ELETRONIC }

var state = "START"
var level = "EASY"
var can_interact = true;
var points = 0
var lifes = 5

var fall_speed = 200

# Labels and background
@onready var label_start = $LabelStart
@onready var panel_countdown = $'PanelContainer'
@onready var label_countdown = $'PanelContainer/LabelCountdown'
@onready var label_points = $LabelPoints
@onready var label_life = $LabelLife
@onready var label_level = $LabelLevel
@onready var color_rect = $ColorRect
@onready var color_rect_start = $ColorRectStart
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

# Sounds
@onready var error_sound = $ErrorSound
@onready var acc_sound = $AccSound
@onready var coundown_sound = $CountdownSound

func get_bancada_pos(type):
	var alvo = null
	match type:
		Type.FRUIT: alvo = bancada_frutas
		Type.PET: alvo = bancada_pets
		Type.CLOTH: alvo = bancada_roupas
		Type.ELETRONIC: alvo = bancada_eletronicos
	
	if is_instance_valid(alvo):
		# Se for um nó Control, o centro é a posição + metade do tamanho
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
	go_to_start()
	update_points()

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

func go_to_start():
	state = "START"
	start_countdown()
	level = "EASY"
	points = 0
	lifes = 5
	label_start.visible = false
	panel_countdown.visible = true
	label_countdown.visible = true
	color_rect_start.visible = false
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
	color_rect_start.visible = false
	label_start.visible = false
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

func set_levels():
	if (points <= 25):
		level = "EASY"
		fall_speed = 200
		spawn_timer.wait_time = 2.5
		$'LabelLevel'.text = "Level: Fácil" 
	elif (points <= 50):
		level = "MEDIUM"
		fall_speed = 350
		spawn_timer.wait_time = 1.75
		$'LabelLevel'.text = "Level: Médio"
	elif (points <= 100):
		level = "HARD"
		fall_speed = 500
		spawn_timer.wait_time = 1.25
		$'LabelLevel'.text = "Level: Difícil"
	elif (points > 100):
		level = "EXTREME"
		fall_speed = 700
		spawn_timer.wait_time = 1.0
		$'LabelLevel'.text = "Level: Muito difícil" 
	return

func handle_state_transition():
	for action in input_map.values():
		if state == "START" and Input.is_action_just_pressed(action):
			start_countdown()
			return true
		if state == "GAMEOVER" and Input.is_action_just_pressed(action):
			go_to_start()
			return true
	return false

func start_countdown():
	can_interact = false
	panel_countdown.visible = true
	label_countdown.visible = true
	color_rect_start.visible = false
	label_start.visible = false
	coundown_sound.play()
	
	await get_tree().create_timer(0.3).timeout
	
	label_countdown.text = '3'
	await get_tree().create_timer(1.0).timeout
	
	label_countdown.text = '2'
	await get_tree().create_timer(1.0).timeout
	
	label_countdown.text = '1'
	await get_tree().create_timer(1.0).timeout
	
	label_countdown.text = 'START'
	await get_tree().create_timer(1.0).timeout
	
	can_interact = true
	panel_countdown.visible = false
	label_countdown.visible = false
	go_to_playing()

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
	can_interact = false
	item.is_launched = true
	acc_sound.play()
	item.correct_animation()
	points += 10
	
	var alvo = get_bancada_pos(item.type)
	item.launch_to_target(alvo)
	
	update_points()
	await get_tree().create_timer(0.1).timeout 
	can_interact = true

func errou(item):
	if not can_interact or not is_instance_valid(item):
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
	if state == "PLAYING":
		spawn_item()

func spawn_item():
	var new_item = item_scene.instantiate()
	var type = randi() % Type.size()
	add_child(new_item)
	new_item.position = spawn_point.position
	new_item.setup(type, assets[type], fall_speed)

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
