extends Entity

func _process(delta:float)->void:
	super._process(delta)
	$Node2D.scale.x = -1 if lookDirection.x < 0 else 1
