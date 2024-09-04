extends EntityController

var direction:Vector2

func _physics_process(_delta: float) -> void:
	direction = Input.get_vector("left", "right", "up", "down");
	ent.setMoveIntent(direction)