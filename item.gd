extends Area2D

var type: int
var velocity = Vector2.ZERO
var speed = 400
var falling_gravity = 200
var can_fall = false
var is_launched = false

@onready var main = get_tree().current_scene

func setup(item_type: int, assets_list: Array, level_speed: float):
	self.type = item_type
	self.falling_gravity = level_speed
	
	var texture = assets_list[randi() % assets_list.size()]
	$Sprite2D.texture = texture
	
	var path = texture.resource_path.to_lower()
	if "food-kit" in path or "pets" in path:
		scale = Vector2(3, 3)
	elif "clothes_package" in path:
		scale = Vector2(0.65, 0.65)
	else:
		scale = Vector2(1.5, 1.5)

func _ready() -> void:
	start_falling_timer()

func _process(delta: float) -> void:
	if is_launched:
		position += velocity * delta
		if position.y > 1300 or position.y < -200 or abs(position.x) > 2000:
			queue_free()
		return
	
	if can_fall:
		velocity.y += falling_gravity * delta
		position += velocity * delta
	
	if position.y > 1200:
		if main.has_method("lost_due_omission"):
			main.lost_due_omission()
		queue_free()

func start_falling_timer():
	await get_tree().create_timer(1.0).timeout
	can_fall = true

func launch(direction: String):
	can_fall = false
	is_launched = true
	match direction:
		"rightHand":
			velocity = Vector2(speed, -200)
		"leftHand":
			velocity = Vector2(-speed, -200)
		"rightFoot":
			velocity = Vector2(speed, 200)
		"leftFoot":
			velocity = Vector2(-speed, 200)

func launch_to_target(target_position: Vector2):
	can_fall = false
	is_launched = true
	
	var tween = create_tween()
	
	tween.tween_property(self, "global_position", target_position, 2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", Vector2.ZERO, 1.5)
	tween.finished.connect(queue_free)

func correct_animation():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.GREEN, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

func error_animation():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.tween_property(self, "position:x", position.x + 10, 0.05)
	tween.tween_property(self, "position:x", position.x - 10, 0.05)
	tween.tween_property(self, "position:x", position.x, 0.05)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
