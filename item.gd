extends Area2D

var velocity = 0
var falling_gravity = 3
var can_fall = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().create_timer(1.0).timeout
	can_fall = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if can_fall:
		velocity += falling_gravity * delta
		position.y += velocity
	
	# Remove o item quando ele sair da tela
	if position.y > 1200:
		queue_free()
