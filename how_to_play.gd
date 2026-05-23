extends Node2D

@onready var rules_sound = $RulesSound

var actions = [
	"leftHand",
	"rightHand",
	"leftFoot",
	"rightFoot"
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rules_sound.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for action in actions:
		if Input.is_action_just_pressed(action):
			get_tree().change_scene_to_file("res://game.tscn")
