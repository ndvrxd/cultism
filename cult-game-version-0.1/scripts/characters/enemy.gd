extends Entity

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	$upright_anchor.scale.x = 1 if lookDirection.x > 0 else -1
	$upright_anchor/eyes.position = Vector2(randf_range(-1.5, 1.5), 3+randf_range(-1.5, 1.5))
