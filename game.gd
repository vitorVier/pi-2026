extends Node2D

enum Type {FRUIT, PET, TOOL, ELETRONIC}

var state = "START"
var can_interact = true;
var points = 0
var lifes = 5

@onready var label_start = $LabelStart
@onready var label_gameover = $LabelGameOver
@onready var label_points = $LabelPoints
@onready var label_life = $LabelLife
@onready var item_scene = preload("res://Item.tscn")
@onready var spawn_point = $Marker2D

# Mapeamento de inputs por tipo
var input_map = {
	Type.FRUIT: "rightHand",
	Type.PET: "leftHand",
	Type.TOOL: "rightFoot",
	Type.ELETRONIC: "leftFoot"
}

# Agrupamento de assets por tipo
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
	Type.TOOL: [
		preload("res://kenney_tools/PNG/Colored/genericItem_color_001.png"),
		preload("res://kenney_tools/PNG/Colored/genericItem_color_005.png"),
		preload("res://kenney_tools/PNG/Colored/genericItem_color_004.png"),
		preload("res://kenney_tools/PNG/Colored/genericItem_color_009.png"),
		preload("res://kenney_tools/PNG/Colored/genericItem_color_010.png"),
		preload("res://kenney_tools/PNG/Colored/genericItem_color_016.png"),
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
	if handle_state_transition():
		return
	if state == "PLAYING":
		verify_input()

func go_to_start():
	state = "START"
	points = 0
	lifes = 5
	
	label_start.visible = true
	label_points.visible = false
	label_life.visible = false
	label_gameover.visible = false
	
	update_points()
	label_life.text = "Vidas: " + str(lifes)

func go_to_playing():
	state = "PLAYING"
	label_start.visible = false
	label_points.visible = true
	label_life.visible = true

func go_to_gameOver():
	state = "GAMEOVER"
	label_gameover.text = "GAME OVER\n\nPontuação final: " + str(points) + "\n\nAperta um botão para voltar ao inicio"
	label_gameover.visible = true
	label_points.visible = false
	label_life.visible = false
	
	stop_items()
	clear_items()
	

func handle_state_transition():
	for action in input_map.values():
		if state == "START" and Input.is_action_just_pressed(action):
			go_to_playing()
			return true
			
		if state == "GAMEOVER" and Input.is_action_just_pressed(action):
			go_to_start()
			return true
	return false

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
		print("Nenhum item na tela")
		return
	
	if acertou_tecla(item.type, tecla):
		acertou(item)
	else:
		errou(item)

func acertou_tecla(type, tecla):
	return input_map.get(type) == tecla

# Aumenta pontuação ao acertar
func acertou(item):
	can_interact = false
	item.is_launched = true
	item.correct_animation()
	points += 10
	item.launch(input_map.get(item.type))
	update_points()

# Reduz pontuação ao errar botão
func errou(item):
	if not can_interact or not is_instance_valid(item):
		return
	
	can_interact = false
	item.is_launched = true
	
	item.error_animation()
	lost_life()
	
	# Aguarda 1s e remove item
	await get_tree().create_timer(1).timeout
	if is_instance_valid(item):
		item.queue_free()

func lost_due_omission():
	lost_life()

func lost_life():
	lifes -= 1
	$LabelLife.text = "Vidas: " + str(lifes)
	
	if lifes < 1:
		go_to_gameOver()
	else:
		# Se foi um erro de clique, permite interagir novamente após um tempo
		await get_tree().create_timer(0.5).timeout
		can_interact = true

# Atualiza pontuação
func update_points():
	label_points.text = "Pontos: " + str(points)

func _on_timer_timeout():
	if state == "PLAYING":
		spawn_item()

# Função para spawnar itens aleatoriamente
func spawn_item():
	can_interact = true
	var new_item = item_scene.instantiate()
	var type = randi() % Type.size()

	var texture = get_random_texture(type)

	new_item.get_node("Sprite2D").texture = texture
	new_item.scale = calculate_scale(texture.resource_path)
	new_item.position = spawn_point.position
	new_item.type = type
	
	new_item.tree_exited.connect(func():
		if state == "PLAYING" and is_instance_valid(new_item) and not new_item.is_launched:
			lost_due_omission()
	)
	
	add_child(new_item)

func get_random_texture(type):
	var list = assets[type]
	return list[randi() % list.size()]

# Função auxiliar para calcular tamanho dos itens
func calculate_scale(path: String) -> Vector2:
	var path_lower = path.to_lower()

	if "food-kit" in path_lower or "pets" in path_lower:
		return Vector2(2.5, 2.5)

	if "tools" in path_lower:
		return Vector2(1, 1)

	return Vector2(1, 1)

func get_first_item():
	for node in get_children():
		if node is Area2D and node.has_method("get") and "type" in node and "is_launched" in node:
			if not node.is_launched:
				return node
	return null

func stop_items():
	for node in get_children():
		if node is Area2D and "can_fall" in node:
			node.can_fall = false

# Limpa todos items da tela
func clear_items():
	for node in get_children():
		if node is Area2D:
			node.queue_free()
