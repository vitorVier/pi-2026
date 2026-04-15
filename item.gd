extends Area2D

var type: int
var velocity = 0
var falling_gravity = 300
var can_fall = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_falling_timer()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if can_fall:
		velocity += falling_gravity * delta
		position.y += velocity * delta
	
	if position.y > 1200:
		queue_free()

func start_falling_timer():
	await get_tree().create_timer(1.0).timeout
	can_fall = true
