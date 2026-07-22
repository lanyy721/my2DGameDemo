extends Area2D

func _physics_process(_delta: float) -> void:
	var enemies_in_range=get_overlapping_bodies()
	if enemies_in_range.size()>0:
		var target_enemy=enemies_in_range.front()
		look_at(target_enemy.global_position)

func shoot():
	const BULLET=preload("res://bullet.tscn")
	var new_bullet=BULLET.instantiate()
	new_bullet.global_position=$%ShootPoint.global_position
	new_bullet.global_rotation=$%ShootPoint.global_rotation

	$%ShootPoint.add_child(new_bullet)



func _on_timer_timeout() -> void:
	shoot()
