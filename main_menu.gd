extends Node2D

@onready var menuSound = $MenuSound

var can_input = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$MenuSound.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("rightHand") \
	 or Input.is_action_just_pressed("rightFoot"):
		get_tree().change_scene_to_file("res://game.tscn")
	
	if Input.is_action_just_pressed("leftHand") \
	 or Input.is_action_just_pressed("leftFoot"):
		get_tree().change_scene_to_file("res://how_to_play.tscn")
