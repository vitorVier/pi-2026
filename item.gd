extends Area2D

var type: int

var is_tutorial = false
var tutorial_stop_y = 500
var highlight_triggered = false

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
	$BorderSprite.texture = texture
	$ShadowSprite.visible = false
	
	var border_color := Color("#FFD60A")
	match item_type:
		main.Type.FRUIT:
			border_color = Color("#FFD60A")
		main.Type.PET:
			border_color = Color("#2563EB")
		main.Type.CLOTH:
			border_color = Color("#EF4444")
		main.Type.ELETRONIC:
			border_color = Color("#22C55E")
	
	$BorderSprite.modulate = border_color
	$BorderSprite.z_index = -1
	
	var path = texture.resource_path.to_lower()
	if "food-kit" in path or "pets" in path:
		scale = Vector2(3, 3)
		$BorderSprite.scale = Vector2(1.20, 1.20)
	elif "clothes_package" in path:
		scale = Vector2(0.65, 0.65)
		$BorderSprite.scale = Vector2(1.08, 1.08)
	else:
		scale = Vector2(1.5, 1.5)
		$BorderSprite.scale = Vector2(1.12, 1.12)
	
	call_deferred("_start_border_glow", border_color)

func _start_border_glow(base_color: Color):
	var bright = Color(base_color.r, base_color.g, base_color.b, 1.0)
	var dim    = Color(base_color.r, base_color.g, base_color.b, 0.2)
	
	var tween = create_tween().set_loops()
	tween.tween_property($BorderSprite, "modulate", bright, 0.8)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property($BorderSprite, "modulate", dim, 0.8)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _ready() -> void:
	start_falling_timer()

func _process(delta: float) -> void:
	if is_launched:
		position += velocity * delta
		if position.y > 1300 or position.y < -200 or abs(position.x) > 2000:
			queue_free()
		return
	
	if can_fall:
		if is_tutorial and position.y >= tutorial_stop_y:
			can_fall = false
			velocity = Vector2.ZERO
			main.highlight_bancada(type)
			return
		
		if not is_tutorial and position.y >= tutorial_stop_y - 100 and not highlight_triggered:
			highlight_triggered = true
			main.highlight_bancada(type)
		
		velocity.y += falling_gravity * delta
		position += velocity * delta
	
	if position.y > 1200:
		if main.has_method("lost_due_omission"):
			main.lost_due_omission()
		main.stop_highlight()
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
