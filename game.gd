extends Node2D

var textures = [
	# FRUTAS
	preload("res://kenney_food-kit/Previews/apple.png"),
	preload("res://kenney_food-kit/Previews/banana.png"),
	preload("res://kenney_food-kit/Previews/cherries.png"),
	preload("res://kenney_food-kit/Previews/orange.png"),
	preload("res://kenney_food-kit/Previews/pineapple.png"),
	preload("res://kenney_food-kit/Previews/strawberry.png"),
	
	# PETS
	preload("res://kenney_pets/Previews/animal-cat.png"),
	preload("res://kenney_pets/Previews/animal-chick.png"),
	preload("res://kenney_pets/Previews/animal-elephant.png"),
	preload("res://kenney_pets/Previews/animal-lion.png"),
	preload("res://kenney_pets/Previews/animal-monkey.png"),
	preload("res://kenney_pets/Previews/animal-panda.png"),
	
	# Tools
	preload("res://kenney_tools/PNG/Colored/genericItem_color_001.png"),
	preload("res://kenney_tools/PNG/Colored/genericItem_color_005.png"),
	preload("res://kenney_tools/PNG/Colored/genericItem_color_004.png"),
	preload("res://kenney_tools/PNG/Colored/genericItem_color_009.png"),
	preload("res://kenney_tools/PNG/Colored/genericItem_color_010.png"),
	preload("res://kenney_tools/PNG/Colored/genericItem_color_016.png"),
	
	# Eletronics
	preload("res://kenney_tools/PNG/Colored/genericItem_color_049.png"),
	preload("res://kenney_tools/PNG/Colored/genericItem_color_050.png"),
	preload("res://kenney_tools/PNG/Colored/genericItem_color_051.png"),
	preload("res://kenney_tools/PNG/Colored/genericItem_color_053.png"),
	preload("res://kenney_tools/PNG/Colored/genericItem_color_082.png"),
	preload("res://kenney_tools/PNG/Colored/genericItem_color_084.png"),
]

@onready var item_scene = preload("res://Item.tscn")
@onready var spawn_point = $Marker2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _on_timer_timeout():
	spawn_item()

func spawn_item():
	var new_item = item_scene.instantiate()
	var random_texture = textures[randi() % textures.size()]

	# Acessa o Sprite2D dentro do novo item e muda a imagem
	new_item.get_node("Sprite2D").texture = random_texture
	
	new_item.scale = calculate_scale(random_texture.resource_path)
	new_item.position = spawn_point.position
	
	add_child(new_item)

# Função auxiliar para redimencionar escala das imagens
func calculate_scale(path: String) -> Vector2:
	var path_lower = path.to_lower()
	
	if "food-kit" in path_lower or "pets" in path_lower:
		return Vector2(2.5, 2.5) # Frutas e animais maiores (Ajuste o 5 conforme necessário)
	
	if "tools" in path_lower:
		return Vector2(1, 1) # Ferramentas e eletrônicos no tamanho original
		
	return Vector2(1, 1) # Escala padrão caso não caia em nenhuma regra

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
