extends Node2D

var final_score = 0

@onready var label_score = $CanvasLayer/LabelGameOver
@onready var gameover_claps = $GameoverClaps

var actions = [
	"leftHand",
	"rightHand",
	"leftFoot",
	"rightFoot"
]

func _ready():
	gameover_claps.play()
	label_score.text = "Pontuação Final: " + str(final_score)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for action in actions:
		if Input.is_action_just_pressed(action):
			get_tree().change_scene_to_file("res://main_menu.tscn")
			queue_free()
