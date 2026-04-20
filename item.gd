extends Area2D

var type: int
var velocity = Vector2.ZERO
var speed = 400
var falling_gravity = 300
var can_fall = false
var is_launched = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_falling_timer()

# Called every frame. 'delta' is the elapsed time since the previous frame.
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
		queue_free()
		is_launched = false

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

func correct_animation():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.GREEN, 0.1)
	tween.tween_property(self, "position:x", position.x + 10, 0.05)
	tween.tween_property(self, "position:x", position.x - 10, 0.05)
	tween.tween_property(self, "position:x", position.x, 0.05)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

func error_animation():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.tween_property(self, "position:x", position.x + 10, 0.05)
	tween.tween_property(self, "position:x", position.x - 10, 0.05)
	tween.tween_property(self, "position:x", position.x, 0.05)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
