extends CharacterBody2D

var health=3

@onready var player := get_node_or_null("/root/Game/Player") as CharacterBody2D

func _ready() -> void:
	$Slime.play_walk()

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		return

	var direction=global_position.direction_to(player.global_position)
	velocity=direction*200
	move_and_slide()

func take_damage():
	health-=1
	$Slime.play_hurt()
	if health==0:
		queue_free()
		const SMOKE_SENCE=preload("res://smoke_explosion/smoke_explosion.tscn")
		var smoke=SMOKE_SENCE.instantiate()
		get_parent().add_child(smoke)
		smoke.global_position=global_position
