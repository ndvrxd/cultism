extends Entity

func _process(delta):
	$upright_anchor.scale.x = -1 if lookDirection.x < 0 else 1
	super._process(delta)
