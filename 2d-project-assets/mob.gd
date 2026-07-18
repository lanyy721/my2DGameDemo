extends CharacterBody2D

@onready var player=get_node("/root/Game/Player")

func _physics_process(_delta: float) -> void:
	var direction=global_position.direction_to(player.global_position)
	velocity=direction*300
	move_and_slide()
