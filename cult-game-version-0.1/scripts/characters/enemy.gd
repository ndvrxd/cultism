extends Entity

func _process(delta: float) -> void:
	super._process(delta)
	$feet/eyes.position = Vector2(randf_range(-1.5, 1.5), 3+randf_range(-1.5, 1.5))
